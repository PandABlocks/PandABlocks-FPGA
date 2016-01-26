--------------------------------------------------------------------------------
--  File:       panda_pcap.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_pcap is
generic (
    AXI_BURST_LEN       : integer := 16;
    AXI_ADDR_WIDTH      : integer := 32;
    AXI_DATA_WIDTH      : integer := 32
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;

    enabled_i           : in  std_logic;
    disarmed_i          : in  std_logic_vector(1 downto 0);
    pcap_frst_i         : in  std_logic;
    pcap_dat_i          : in  std_logic_vector(31 downto 0);
    pcap_wstb_i         : in  std_logic;

    irq_o               : out std_logic;

    TIMEOUT_VAL         : in  std_logic_vector(31 downto 0);
    DMAADDR_WSTB        : in  std_logic;
    DMAADDR             : in  std_logic_vector(31 downto 0);
    IRQ_STATUS          : out std_logic_vector(3 downto 0);
    SMPL_COUNT          : out std_logic_vector(31 downto 0);
    BLOCK_SIZE          : in  std_logic_vector(31 downto 0);

    -- AXI3 HP Bus Write Only Interface
    m_axi_awready       : in  std_logic;
    m_axi_awaddr        : out std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    m_axi_awvalid       : out std_logic;
    m_axi_awburst       : out std_logic_vector(1 downto 0);
    m_axi_awcache       : out std_logic_vector(3 downto 0);
    m_axi_awid          : out std_logic_vector(5 downto 0);
    m_axi_awlen         : out std_logic_vector(3 downto 0);
    m_axi_awlock        : out std_logic_vector(1 downto 0);
    m_axi_awprot        : out std_logic_vector(2 downto 0);
    m_axi_awqos         : out std_logic_vector(3 downto 0);
    m_axi_awsize        : out std_logic_vector(2 downto 0);
    m_axi_bid           : in  std_logic_vector(5 downto 0);
    m_axi_bready        : out std_logic;
    m_axi_bresp         : in  std_logic_vector(1 downto 0);
    m_axi_bvalid        : in  std_logic;
    m_axi_wready        : in  std_logic;
    m_axi_wdata         : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    m_axi_wvalid        : out std_logic;
    m_axi_wlast         : out std_logic;
    m_axi_wstrb         : out std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
    m_axi_wid           : out std_logic_vector(5 downto 0)
);
end panda_pcap;

architecture rtl of panda_pcap is

-- Number of byte per AXI3 burst
constant BURST_LEN          : integer := AXI_BURST_LEN * AXI_ADDR_WIDTH/8;

-- IRQ Status encoding
constant IRQ_IDLE           : std_logic_vector(3 downto 0) := "0000";
constant IRQ_BUFFER_FINISHED: std_logic_vector(3 downto 0) := "0001";
constant IRQ_CAPT_FINISHED  : std_logic_vector(3 downto 0) := "0010";
constant IRQ_TIMEOUT        : std_logic_vector(3 downto 0) := "0011";
constant IRQ_DISARMED       : std_logic_vector(3 downto 0) := "0100";
constant IRQ_ADDR_ERROR     : std_logic_vector(3 downto 0) := "0101";
constant IRQ_INT_DISARMED   : std_logic_vector(3 downto 0) := "0110";

type pcap_fsm_t is (IDLE, ACTV, DO_DMA, IS_FINISHED, IRQ, ABORTED);
signal pcap_fsm             : pcap_fsm_t;

signal BLOCK_TLP_SIZE       : std_logic_vector(31 downto 0);

signal m_axi_burst_len      : std_logic_vector(4 downto 0) := TO_SVECTOR(16, 5);

signal dma_start            : std_logic;
signal dma_done             : std_logic;
signal dma_irq              : std_logic;
signal dma_error            : std_logic;
signal tlp_count            : unsigned(31 downto 0);
signal last_tlp_flag        : std_logic;
signal pcap_timeout_flag    : std_logic;
signal axi_awaddr_val       : unsigned(31 downto 0);
signal axi_wdata_val        : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
signal next_dmaaddr_valid   : std_logic;
signal next_dmaaddr_clear   : std_logic;

signal fifo_data_count      : std_logic_vector(10 downto 0);
signal fifo_rd_en           : std_logic;
signal fifo_dout            : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
signal fifo_count           : integer range 0 to 2047;

signal sample_count         : unsigned(31 downto 0);

begin

-- Assign outputs.
irq_o <= dma_irq;

--
-- Convert BLOCK_SIZE [in Bytes] to TLP_Count. Each TLP has 16 beats of DWORDS.
-- TLP_COUNT = BLOCK_SIZE/64
--
BLOCK_TLP_SIZE <= "000000" & BLOCK_SIZE(31 downto 6);

--
-- 32bit-to-64-bit FIFO with 1K sample depth
--
pcap_dma_fifo_inst : entity work.pcap_dma_fifo
port map (
    rst             => pcap_frst_i,
    clk             => clk_i,
    din             => pcap_dat_i,
    wr_en           => pcap_wstb_i,
    rd_en           => fifo_rd_en,
    dout            => fifo_dout,
    full            => open,
    empty           => open,
    data_count      => fifo_data_count
);

fifo_count <= to_integer(unsigned(fifo_data_count));


--
-- PCAP Main State Machine
--
PCAP_STATE : process(clk_i)
    variable timeout_counter        : unsigned(31 downto 0);
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            pcap_fsm <= IDLE;
            dma_irq <= '0';
            last_tlp_flag <= '0';
            pcap_timeout_flag <= '0';
            dma_start <= '0';
            IRQ_STATUS <= IRQ_IDLE;
            axi_awaddr_val <= (others => '0');
            next_dmaaddr_valid <= '0';
            next_dmaaddr_clear <= '0';
            timeout_counter := (others => '0');
            m_axi_burst_len <= TO_SVECTOR(16, 5);
            tlp_count <= (others => '0');
            sample_count <= (others => '0');
            SMPL_COUNT <= (others => '0');
        else
            -- DMAADDR_WSTB strobe is used as a handshake between PS and
            -- PL logic. If PS can not keep up with the DMA rate by setting
            -- next DMA address on irq, DMA will be aborted.
            if (DMAADDR_WSTB = '1') then
                next_dmaaddr_valid <= '1';
            -- Clear flag once DMA Block is consumed
            elsif (next_dmaaddr_clear = '1') then
                next_dmaaddr_valid <= '0';
            end if;

            --
            -- Timeout Counter.
            -- TIMEOUT_VAL = 0 disables the counter, otherwise counter is
            -- active only in ACTV state.
            if (unsigned(TIMEOUT_VAL) = 0 or pcap_fsm /= ACTV) then
                timeout_counter := (others => '0');
            else
                if (timeout_counter = unsigned(TIMEOUT_VAL) - 1) then
                    timeout_counter := (others => '0');
                else
                    timeout_counter := timeout_counter + 1;
                end if;
            end if;

            --
            -- Main State Machine
            --
            -- tlp_count       : # of TLPs DMAed per IRQ.
            -- sample_count    : # of samples (DWORDs) DMAed per IRQ.
            -- m_axi_burst_len : # of beats in individual AXI3 write.
            case pcap_fsm is
                -- Once armed, logic waits for enable input.
                when IDLE =>
                    last_tlp_flag <= '0';
                    pcap_timeout_flag <= '0';
                    tlp_count <= (others => '0');
                    sample_count <= (others => '0');
                    dma_start <= '0';
                    axi_awaddr_val <= unsigned(DMAADDR);
                    if (enabled_i = '1') then
                        pcap_fsm <= ACTV;
                    end if;

                -- Wait until FIFO has enough data worth for a AXI3 burst
                -- (16 beats).
                when ACTV =>
                    pcap_timeout_flag <= '0';
                    last_tlp_flag <= '0';

                    -- Timeout occured, transfer all data in the buffer before
                    -- raising IRQ.
                    if (timeout_counter = unsigned(TIMEOUT_VAL) - 1) then
                        pcap_timeout_flag <= '1';
                        if (fifo_count = 0) then
                            pcap_fsm <= IS_FINISHED;
                        else
                            dma_start <= '1';
                            sample_count <= sample_count + fifo_count;
                            m_axi_burst_len <= fifo_data_count(4 downto 0);
                            pcap_fsm <= DO_DMA;
                        end if;
                    -- More than 1 TLP still in the queue.
                    elsif (fifo_count > 16) then
                        dma_start <= '1';
                        sample_count <= sample_count + AXI_BURST_LEN;
                        m_axi_burst_len <= TO_SVECTOR(AXI_BURST_LEN, 5);
                        pcap_fsm <= DO_DMA;
                    -- If enable flag is de-asserted while DMAing the last
                    -- TLP, no need to do a 0 byte DMA
                    elsif (enabled_i = '0' and fifo_count = 0) then
                        last_tlp_flag <= '1';
                        pcap_fsm <= IS_FINISHED;
                    -- Enable de-asserted, and there is less than 1 TLP worth
                    -- data, empty the queue.
                    elsif (enabled_i = '0' and fifo_count <= 16) then
                        last_tlp_flag <= '1';
                        dma_start <= '1';
                        sample_count <= sample_count + fifo_count;
                        m_axi_burst_len <= fifo_data_count(4 downto 0);
                        pcap_fsm <= DO_DMA;
                    end if;

                -- Waits until DMA Engine completes. Also keeps tracks of TLPs
                -- for Buffer switching.
                when DO_DMA =>
                    dma_start <= '0';
                    if (dma_done = '1') then
                        tlp_count <= tlp_count + 1;
                        pcap_fsm <= IS_FINISHED;
                    end if;

                -- Decide what to do next.
                -- Sets IRQ status and latch Sample Counts accordingly.
                when IS_FINISHED =>
                    -- Last TLP happens on either scan capture finish, or
                    -- graceful finish on DISARM.
                    if (last_tlp_flag = '1') then
                        if (disarmed_i(0) = '1') then
                            IRQ_STATUS <= IRQ_DISARMED;
                        elsif (disarmed_i(1) = '1') then
                            IRQ_STATUS <= IRQ_INT_DISARMED;
                        else
                            IRQ_STATUS <= IRQ_CAPT_FINISHED;
                        end if;
                        pcap_fsm <= IRQ;
                        dma_irq <= '1';
                        SMPL_COUNT <= std_logic_vector(sample_count);
                    -- Switch to next buffer when Timeout happens or current
                    -- buffer is finished.
                    -- Make sure that next dma address is valid.
                    elsif (pcap_timeout_flag = '1' or
                                tlp_count = unsigned(BLOCK_TLP_SIZE)) then
                        tlp_count <= (others => '0');
                        dma_irq <= '1';
                        SMPL_COUNT <= std_logic_vector(sample_count);
                        if (next_dmaaddr_valid = '1') then
                            pcap_fsm <= IRQ;
                            -- Set IRQ status flag.
                            if (pcap_timeout_flag = '1') then
                                IRQ_STATUS <= IRQ_TIMEOUT;
                            else
                                IRQ_STATUS <= IRQ_BUFFER_FINISHED;
                            end if;
                            axi_awaddr_val <= unsigned(DMAADDR);
                            next_dmaaddr_clear <= '1';
                        else
                            pcap_fsm <= ABORTED;
                            IRQ_STATUS <= IRQ_ADDR_ERROR;
                        end if;
                    -- Block buffer is not consumed and Pcap is still active,
                    -- increment address in the current buffer and continue
                    -- DMAing.
                    else
                        pcap_fsm <= ACTV;
                        axi_awaddr_val <= axi_awaddr_val + BURST_LEN;
                    end if;

                -- Set IRQ flag, and either continue or stop operation
                when IRQ =>
                    dma_irq <= '0';
                    sample_count <= (others => '0');
                    next_dmaaddr_clear <= '0';
                    -- PCap finished and last TLP DMAed.
                    if (last_tlp_flag = '1') then
                        pcap_fsm <= IDLE;
                    else
                        pcap_fsm <= ACTV;
                    end if;

                -- Clear flag and wait for user DISARM.
                when ABORTED =>
                    dma_irq <= '0';
                    if (enabled_i = '0') then
                        pcap_fsm <= IDLE;
                    end if;

                when others =>

            end case;
        end if;
    end if;
end process;

--
-- AXI DMA Master Engine
--
WORD_SWAP_32 : if (AXI_DATA_WIDTH = 32) generate
    axi_wdata_val(31 downto 0) <= fifo_dout(31 downto 0);
end generate;

WORD_SWAP_64 : if (AXI_DATA_WIDTH = 64) generate
    axi_wdata_val(63 downto 32) <= fifo_dout(31 downto 0);
    axi_wdata_val(31 downto 0) <= fifo_dout(63 downto 32);
end generate;

dma_write_master : entity work.panda_axi3_write_master
generic map (
    AXI_ADDR_WIDTH      => AXI_ADDR_WIDTH,
    AXI_DATA_WIDTH      => AXI_DATA_WIDTH
)
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    m_axi_burst_len     => m_axi_burst_len,

    m_axi_awready       => m_axi_awready,
    m_axi_awaddr        => m_axi_awaddr,
    m_axi_awvalid       => m_axi_awvalid,
    m_axi_awburst       => m_axi_awburst,
    m_axi_awcache       => m_axi_awcache,
    m_axi_awid          => m_axi_awid,
    m_axi_awlen         => m_axi_awlen,
    m_axi_awlock        => m_axi_awlock,
    m_axi_awprot        => m_axi_awprot,
    m_axi_awqos         => m_axi_awqos,
    m_axi_awsize        => m_axi_awsize,
    m_axi_bid           => m_axi_bid,
    m_axi_bready        => m_axi_bready,
    m_axi_bresp         => m_axi_bresp,
    m_axi_bvalid        => m_axi_bvalid,
    m_axi_wready        => m_axi_wready,
    m_axi_wdata         => m_axi_wdata,
    m_axi_wvalid        => m_axi_wvalid,
    m_axi_wlast         => m_axi_wlast,
    m_axi_wstrb         => m_axi_wstrb,
    m_axi_wid           => m_axi_wid,

    dma_addr            => std_logic_vector(axi_awaddr_val),
    dma_data            => axi_wdata_val,
    dma_read            => fifo_rd_en,
    dma_start           => dma_start,
    dma_done            => dma_done,
    dma_error           => dma_error
);

end rtl;

