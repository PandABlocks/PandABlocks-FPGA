--------------------------------------------------------------------------------
--  File:       panda_pcap_dma.vhd
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

entity panda_pcap_dma is
generic (
    AXI_BURST_LEN       : integer := 16;
    AXI_ADDR_WIDTH      : integer := 32;
    AXI_DATA_WIDTH      : integer := 32
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;

    -- Block Input and Outputs
    pcap_enabled_i      : in  std_logic;
    pcap_status_i       : in  std_logic_vector(2 downto 0);
    dma_fifo_reset_i    : in  std_logic;
    dma_fifo_ready_o    : out std_logic;
    pcap_dat_i          : in  std_logic_vector(31 downto 0);
    pcap_wstb_i         : in  std_logic;
    irq_o               : out std_logic;

    -- Block Registers
    DMA_RESET           : in  std_logic;
    DMA_INIT            : in  std_logic;
    DMA_ADDR            : in  std_logic_vector(31 downto 0);
    DMA_ADDR_WSTB       : in  std_logic;
    TIMEOUT             : in  std_logic_vector(31 downto 0);
    IRQ_STATUS          : out std_logic_vector(31 downto 0);
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
end panda_pcap_dma;

architecture rtl of panda_pcap_dma is

-- Number of byte per AXI3 burst
constant BURST_LEN          : integer := AXI_BURST_LEN * AXI_ADDR_WIDTH/8;

-- IRQ Status encoding
constant IRQ_IDLE           : std_logic_vector(3 downto 0) := "0000";

component pcap_dma_fifo
port (
    clk                 : in std_logic;
    rst                 : in std_logic;
    din                 : in std_logic_vector(31 DOWNTO 0);
    wr_en               : in std_logic;
    rd_en               : in std_logic;
    dout                : out std_logic_vector(31 DOWNTO 0);
    full                : out std_logic;
    empty               : out std_logic;
    data_count          : out std_logic_vector(10 downto 0)
);
end component;

signal BLOCK_TLP_SIZE       : std_logic_vector(31 downto 0);
signal m_axi_burst_len      : std_logic_vector(4 downto 0) := TO_SVECTOR(16, 5);
signal reset                : std_logic;

type pcap_fsm_t is (INIT, IDLE, ACTV, DO_DMA, IS_FINISHED, IRQ, ABORTED);
signal pcap_fsm             : pcap_fsm_t;

signal timeout_counter      : unsigned(31 downto 0);
signal pcap_timeout         : std_logic;

signal dma_start            : std_logic;
signal dma_done             : std_logic;
signal dma_irq              : std_logic;
signal dma_error            : std_logic;
signal tlp_count            : unsigned(31 downto 0);
signal last_tlp             : std_logic;
signal axi_awaddr_val       : unsigned(31 downto 0);
signal axi_wdata_val        : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
signal next_dmaaddr_valid   : std_logic;
signal next_dmaaddr_clear   : std_logic;
signal switch_block         : std_logic;

signal fifo_data_count      : std_logic_vector(10 downto 0);
signal fifo_rd_en           : std_logic;
signal fifo_dout            : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
signal fifo_count           : integer range 0 to 2047;
signal fifo_full            : std_logic;

signal irq_flags            : std_logic_vector(7 downto 0);
signal irq_flags_latch      : std_logic_vector(7 downto 0);
signal sample_count         : unsigned(15 downto 0);
signal sample_count_latch   : unsigned(15 downto 0);

begin

-- Assign outputs.
irq_o <= dma_irq;

dma_fifo_ready_o <= not fifo_full;

IRQ_STATUS <= std_logic_vector(sample_count_latch) &
              X"00" & irq_flags_latch;

-- DMA engine reset
reset <= reset_i or DMA_RESET;

--
-- Convert BLOCK_SIZE [in Bytes] to TLP_Count. Each TLP has 16 beats of DWORDS.
-- TLP_COUNT = BLOCK_SIZE/64
--
BLOCK_TLP_SIZE <= "000000" & BLOCK_SIZE(31 downto 6);

--
-- 32bit-to-64-bit FIFO with 1K sample depth
--
dma_fifo_inst : pcap_dma_fifo
port map (
    rst             => dma_fifo_reset_i,
    clk             => clk_i,
    din             => pcap_dat_i,
    wr_en           => pcap_wstb_i,
    rd_en           => fifo_rd_en,
    dout            => fifo_dout,
    full            => fifo_full,
    empty           => open,
    data_count      => fifo_data_count
);

fifo_count <= to_integer(unsigned(fifo_data_count));

--
-- PCAP Main State Machine
--
-- Order of actions are as follows for Initialisation, and IRQ handling
--
--
--                INIT         IRQ
--              ----------- ----------
-- RESET       | 1.w       |          |
-- ENABLE      | 3.w       |          |
-- ADDR        | 2.w, 4.w  | 3.w      |
-- IRQ_FLAGS   |           | 1.r      |
-- SMPL_COUNT  |           | 2.r      |
--

switch_block <= '1' when (tlp_count = unsigned(BLOCK_TLP_SIZE)) else  '0';

PCAP_STATE : process(clk_i)
begin
if rising_edge(clk_i) then
    if (reset = '1') then
        pcap_fsm <= INIT;
        dma_irq <= '0';
        last_tlp <= '0';
        pcap_timeout <= '0';
        dma_start <= '0';
        irq_flags <= (others => '0');
        irq_flags_latch <= (others => '0');
        axi_awaddr_val <= (others => '0');
        next_dmaaddr_valid <= '0';
        next_dmaaddr_clear <= '0';
        timeout_counter <= (others => '0');
        m_axi_burst_len <= TO_SVECTOR(16, 5);
        tlp_count <= (others => '0');
        sample_count <= (others => '0');
        sample_count_latch <= (others => '0');
    else
        -- DMA_ADDR_WSTB strobe is used as a handshake between PS and
        -- PL logic. If PS can not keep up with the DMA rate by setting
        -- next DMA address on irq, DMA will be aborted.
        if (DMA_ADDR_WSTB = '1') then
            next_dmaaddr_valid <= '1';
        -- Clear flag once DMA Block is consumed
        elsif (next_dmaaddr_clear = '1') then
            next_dmaaddr_valid <= '0';
        end if;

        --
        -- Timeout Counter.
        -- TIMEOUT = 0 disables the counter, otherwise counter is
        -- active only in ACTV state.
        if (unsigned(TIMEOUT) = 0) then
            pcap_timeout <= '0';
        elsif (pcap_fsm = ACTV and timeout_counter = unsigned(TIMEOUT) - 1) then
            pcap_timeout <= '1';
        elsif (pcap_fsm = IRQ) then
            pcap_timeout <= '0';
        else
            pcap_timeout <= pcap_timeout;
        end if;

        if (pcap_fsm /= ACTV) then
            timeout_counter <= (others => '0');
        else
            timeout_counter <= timeout_counter + 1;
        end if;

        --
        -- Main State Machine
        --
        -- tlp_count       : # of TLPs DMAed per IRQ.
        -- sample_count    : # of samples (DWORDs) DMAed per IRQ.
        -- m_axi_burst_len : # of beats in individual AXI3 write.
        case pcap_fsm is
            -- Wait Initialistion by kernel driver
            when INIT =>
                last_tlp <= '0';
                tlp_count <= (others => '0');
                sample_count <= (others => '0');
                dma_start <= '0';
                axi_awaddr_val <= unsigned(DMA_ADDR);
                if (DMA_INIT = '1') then
                    pcap_fsm <= IDLE;
                end if;

            -- Once armed, logic waits for enable input.
            when IDLE =>
                last_tlp <= '0';
                tlp_count <= (others => '0');
                sample_count <= (others => '0');
                dma_start <= '0';
                if (pcap_enabled_i = '1') then
                    pcap_fsm <= ACTV;
                end if;

            -- Wait until FIFO has enough data worth for a AXI3 burst
            -- (16 beats).
            when ACTV =>
                last_tlp <= '0';

                -- Timeout occured, transfer all data in the buffer before
                -- raising IRQ.
                if (pcap_timeout = '1') then
                    if (fifo_count = 0) then
                        pcap_fsm <= IS_FINISHED;
                    else
                        dma_start <= '1';
                        sample_count <= sample_count + fifo_count;
                        m_axi_burst_len <= fifo_data_count(4 downto 0);
                        pcap_fsm <= DO_DMA;
                    end if;
                -- More than 1 TLP in the queue. ???
                elsif (fifo_count > 16) then
                    dma_start <= '1';
                    sample_count <= sample_count + AXI_BURST_LEN;
                    m_axi_burst_len <= TO_SVECTOR(AXI_BURST_LEN, 5);
                    pcap_fsm <= DO_DMA;
                -- If enable flag is de-asserted while DMAing the last
                -- TLP, no need to do a 0 byte DMA
                elsif (pcap_enabled_i = '0' and fifo_count = 0) then
                    last_tlp <= '1';
                    pcap_fsm <= IS_FINISHED;
                -- Enable de-asserted, and there is less than 1 TLP worth
                -- data, empty the queue.
                elsif (pcap_enabled_i = '0' and fifo_count <= 16) then
                    last_tlp <= '1';
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
                if (last_tlp = '1') then
                    -- PCAP completed
                    irq_flags(0) <= '1';
                    -- Completion reason (0 = Successful)
                    irq_flags(3 downto 1) <= pcap_status_i;
                end if;

                if (pcap_timeout = '1') then
                    irq_flags(5) <= '1';
                end if;

                if (switch_block = '1') then
                    irq_flags(6) <= '1';
                end if;

                if (next_dmaaddr_valid = '0') then
                    irq_flags(0) <= '1';
                    irq_flags(4) <= '1';
                end if;

                -- Switch buffers conditionally.
                if (last_tlp = '1') then
                    -- A completion can come immediately following a Timeout, or
                    -- buffer_switch since a block is disabled. This may issue
                    -- two interrupts very close together which may be missed.
                    -- Therefore, the final Nth interrupt is delayed until the
                    --(N-1) interrupt is acknowledged through next_dmaaddr_valid
                    -- flag.
                    -- Make sure that next dma address is written which also acks
                    -- the previous interrupt.
                    if (next_dmaaddr_valid = '1') then
                        dma_irq <= '1';
                        tlp_count <= (others => '0');

                        -- Switch to next buffer when Timeout happens or current
                        -- buffer is finished.
                        axi_awaddr_val <= unsigned(DMA_ADDR);
                        next_dmaaddr_clear <= '1';
                        pcap_fsm <= IRQ;
                    end if;
                elsif(pcap_timeout = '1' or switch_block = '1') then
                    dma_irq <= '1';
                    tlp_count <= (others => '0');

                    -- Switch to next buffer when Timeout happens or current
                    -- buffer is finished.
                    axi_awaddr_val <= unsigned(DMA_ADDR);
                    next_dmaaddr_clear <= '1';

                    -- Make sure that next dma address is valid.
                    if (next_dmaaddr_valid = '0') then
                        pcap_fsm <= ABORTED;
                    else
                        pcap_fsm <= IRQ;
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
                irq_flags_latch <= irq_flags;
                sample_count_latch <= sample_count;
                irq_flags <= (others => '0');
                sample_count <= (others => '0');
                next_dmaaddr_clear <= '0';
                -- PCap finished and last TLP DMAed.
                if (last_tlp = '1') then
                    pcap_fsm <= IDLE;
                else
                    pcap_fsm <= ACTV;
                end if;

            -- Clear flag and wait for user DISARM.
            when ABORTED =>
                dma_irq <= '0';
                if (pcap_enabled_i = '0') then
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
    reset_i             => reset,

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

