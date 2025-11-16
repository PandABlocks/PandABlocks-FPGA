--------------------------------------------------------------------------------
--  File:       pcap_dma.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity pcap_dma is
generic (
    AXI_BURST_LEN       : natural := 16;        -- AXI3 standard
    AXI_ADDR_WIDTH      : natural := 32;
    AXI_DATA_WIDTH      : natural := 32
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;

    -- Block Input and Outputs
    pcap_start_event_i  : in  std_logic;
    pcap_dat_i          : in  std_logic_vector(31 downto 0);
    pcap_wstb_i         : in  std_logic;
    pcap_done_i         : in  std_logic;
    pcap_status_i       : in  std_logic_vector(2 downto 0);
    dma_error_o         : out std_logic;
    irq_o               : out std_logic;

    -- Block Registers
    DMA_RESET           : in  std_logic;
    DMA_INIT            : in  std_logic;
    DMA_ADDR            : in  std_logic_vector(31 downto 0);
    DMA_ADDR_WSTB       : in  std_logic;
    TIMEOUT             : in  std_logic_vector(31 downto 0);
    TIMEOUT_WSTB        : in  std_logic;
    IRQ_STATUS          : out std_logic_vector(31 downto 0);
    BLOCK_SIZE          : in  std_logic_vector(31 downto 0);

    -- AXI3 HP Bus Write Only Interface
    m_axi_awready       : in  std_logic;
    m_axi_awregion      : out std_logic_vector(3 downto 0);
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
    m_axi_wstrb         : out std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0)
);
end;

architecture rtl of pcap_dma is

-- Bit-width required to represent maximum burst length (5)
constant AXI_BURST_WIDTH    : integer := LOG2(AXI_BURST_LEN) + 1;
-- Number of byte per AXI burst
constant BURST_LEN          : integer := AXI_BURST_LEN * AXI_DATA_WIDTH/8;

signal BLOCK_TLP_SIZE       : unsigned(31 downto 0);
signal M_AXI_BURST_LEN      : std_logic_vector(AXI_BURST_WIDTH-1 downto 0) :=
    (others => '0');
signal reset                : std_logic;

type pcap_fsm_t is (INIT, ACTV, DO_DMA, IS_FINISHED, IRQ, COMPLETED);
signal pcap_fsm             : pcap_fsm_t;

signal IRQ_STATUS_T         : std_logic_vector(31 downto 0) := (others => '0');
signal first_data           : std_logic;
signal timeout_counter      : unsigned(31 downto 0);
signal pcap_timeout         : std_logic;
signal pcap_timeout_latch   : std_logic := '0';

signal dma_start            : std_logic := '0';
signal dma_done             : std_logic;
signal dma_irq              : std_logic := '0';
signal dma_error            : std_logic;
signal tlp_count            : unsigned(31 downto 0) := (others => '0');
signal last_tlp             : std_logic := '0';
signal axi_awaddr_val       : unsigned(31 downto 0);
signal axi_wdata_val        : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
signal next_dmaaddr_valid   : std_logic := '0';
signal buffer_full          : std_logic;
signal pcap_wstb            : std_logic;
signal writing_sample       : std_logic;

signal fifo_count           : unsigned(10 downto 0);
signal transfer_size        : unsigned(AXI_BURST_WIDTH-1 downto 0);
signal fifo_rd_en           : std_logic;
signal fifo_dout            : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
signal fifo_write_ready     : std_logic;
signal fifo_full            : std_logic;

signal irq_flags            : std_logic_vector(8 downto 0);
signal sample_count         : unsigned(22 downto 0) := (others => '0');
signal pcap_completed       : std_logic := '0';

signal pcap_error           : std_logic;
signal start_event_detected : std_logic := '0';
signal switch_buffer        : std_logic;

begin

-- Design just won't work properly with 64-bit AXI bus.
assert AXI_DATA_WIDTH = 32 severity failure;

-- Assign outputs.
irq_o <= dma_irq;

-- DMA engine reset
reset <= DMA_RESET;

-- DMA error occurs when fifo is full or AXI transaction error
-- This flag is used to abort ongoing pcap operation along with other flags
dma_error_o <= fifo_full or dma_error;

-- TLP_COUNT = BLOCK_SIZE/BURST_LEN
BLOCK_TLP_SIZE <= to_unsigned((to_integer(unsigned(BLOCK_SIZE)) / BURST_LEN),32);

-- Pcap status information
--  pcap_status_i[0] : user disarmed
--  pcap_status_i[1] : framing error
--  pcap_status_i[2] : dma error
pcap_error <= pcap_status_i(2) or pcap_status_i(1);

dma_fifo_inst : entity work.fifo generic map (
    FIFO_BITS => 10,
    DATA_WIDTH => 32
) port map (
    clk_i => clk_i,
    write_valid_i => pcap_wstb_i,
    write_ready_o => fifo_write_ready,
    write_data_i => pcap_dat_i,
    read_valid_o => open,
    read_ready_i => fifo_rd_en,
    read_data_o => fifo_dout,
    reset_fifo_i => reset,
    fifo_depth_o => fifo_count
);
fifo_full <= not fifo_write_ready;

transfer_size <= to_unsigned(AXI_BURST_LEN, AXI_BURST_WIDTH)
                     when fifo_count > AXI_BURST_LEN else
                         fifo_count(AXI_BURST_WIDTH-1 downto 0);


process (clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            start_event_detected <= '0';
        elsif pcap_start_event_i = '1' then
            start_event_detected <= '1';
        elsif pcap_fsm = IRQ then
            start_event_detected <= '0';
        end if;
    end if;
end process;

--------------------------------------------------------------------------
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

-- DMA_ADDR_WSTB strobe is used as a handshake between PS and
-- PL logic. If PS can not keep up with the DMA rate by setting
-- next DMA address on irq, DMA will be aborted.
--------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            next_dmaaddr_valid <= '0';
        else
            if (DMA_ADDR_WSTB = '1') then
                next_dmaaddr_valid <= '1';
            -- Clear flag on every IRQ
            elsif pcap_fsm = IRQ and switch_buffer = '1' then
                next_dmaaddr_valid <= '0';
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Timeout Counter is used to issue an interrupt @ TIMEOUT rate for very
-- slow acquisition.
-- TIMEOUT = 0 disables the counter, otherwise counter is active only in
-- ACTV state.
--------------------------------------------------------------------------
writing_sample <= pcap_wstb_i or pcap_wstb;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            first_data <= '0';
            pcap_timeout <= '0';
            timeout_counter <= (others => '0');
            pcap_timeout_latch <= '0';
            pcap_wstb <= '0';
        else
            pcap_wstb <= pcap_wstb_i;
            -- Wait until first data received to prevent empty timeout IRQs
            if (pcap_fsm = INIT) then
                first_data <= '0';
            elsif (pcap_wstb_i = '1') then
                first_data <= '1';
            end if;

            -- Reset timeout on start-up and interrupts, and synchronise to
            -- first incoming sample
            if (pcap_fsm = INIT or pcap_fsm = IRQ or first_data = '0') then
                pcap_timeout <= '0';
                timeout_counter <= (others => '0');
            else
                timeout_counter <= timeout_counter + 1;
                if (unsigned(TIMEOUT) = 0) then
                    pcap_timeout <= '0';
                elsif (timeout_counter = unsigned(TIMEOUT) - 1) then
                    pcap_timeout <= '1';
                end if;
            end if;

            -- Latch timeout flag for interrupt status
            if (pcap_fsm = ACTV and pcap_timeout = '1') then
                pcap_timeout_latch <= '1';
            elsif (pcap_fsm = IRQ) then
                pcap_timeout_latch <= '0';
            end if;
        end if;
    end if;
end process;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            pcap_completed <= '0';
        elsif (pcap_done_i = '1') then
            pcap_completed <= '1';
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Main State Machine
--
-- tlp_count       : # of TLPs DMAed per IRQ.
-- sample_count    : # of samples (DWORDs) DMAed per IRQ.
-- M_AXI_BURST_LEN : # of beats in individual AXI3 write.
--------------------------------------------------------------------------

buffer_full <= '1' when (tlp_count = BLOCK_TLP_SIZE) else  '0';
switch_buffer <= pcap_timeout_latch or buffer_full or last_tlp;

PCAP_STATE : process(clk_i)
    procedure goto_do_dma is
    begin
        dma_start <= '1';
        sample_count <= sample_count + transfer_size;
        M_AXI_BURST_LEN <= std_logic_vector(transfer_size);
        pcap_fsm <= DO_DMA;
    end procedure;

begin
if rising_edge(clk_i) then
    if (reset = '1') then
        pcap_fsm <= INIT;
        IRQ_STATUS_T <= (others => '0');
        dma_irq <= '0';
        last_tlp <= '0';
        dma_start <= '0';
        axi_awaddr_val <= (others => '0');
        M_AXI_BURST_LEN <= (others => '0');
        tlp_count <= (others => '0');
        sample_count <= (others => '0');
    else
        case pcap_fsm is
            -- Wait Initialistion by kernel driver
            when INIT =>
                axi_awaddr_val <= unsigned(DMA_ADDR);
                if (DMA_INIT = '1' and next_dmaaddr_valid = '1') then
                    pcap_fsm <= ACTV;
                end if;

            -- Wait until FIFO has enough data worth for a AXI burst
            -- (AXI_BURST_LEN beats).
            when ACTV =>
                dma_irq <= '0';
                -- An unrecoverable error occured, no need to continue
                -- finishing off the buffer
                if (pcap_completed = '1' and pcap_error = '1') then
                    last_tlp <= '1';
                    pcap_fsm <= IRQ;
                -- Timeout occured, transfer all data in the buffer before
                -- raising IRQ.
                elsif (pcap_timeout = '1' and writing_sample = '0') then
                    if (fifo_count = 0) then
                        pcap_fsm <= IRQ;
                    else
                        goto_do_dma;
                    end if;
                -- At least 1 TLP in available the queue
                elsif (fifo_count >= AXI_BURST_LEN) then
                    goto_do_dma;
                -- Position compare completed
                elsif (pcap_completed = '1' and writing_sample = '0') then
                    last_tlp <= '1';
                    if (fifo_count = 0) then 
                        -- if last_tlp, wait for next buffer address assigned by PS
                        if (next_dmaaddr_valid = '1') then
                            pcap_fsm <= IRQ;
                        end if;
                    else
                        goto_do_dma;
                    end if;
                -- trigger an interrupt to capture the start timestamp
                elsif (start_event_detected = '1') then
                    pcap_fsm <= IRQ;
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
            when IS_FINISHED =>
                -- Timeout or buffer full, should switch buffers
                if pcap_timeout_latch = '1' or buffer_full = '1' then
                    pcap_fsm <= IRQ;
                -- Block buffer is not consumed and Pcap is still active
                else
                    pcap_fsm <= ACTV;
                    axi_awaddr_val <= axi_awaddr_val + BURST_LEN;
                end if;

            -- Set IRQ flag, and either continue or stop operation
            when IRQ =>
                -- Raise the interrupt to PS
                dma_irq <= '1';

                -- Latch IRQ status flags
                IRQ_STATUS_T(31 downto 9) <= std_logic_vector(sample_count);
                IRQ_STATUS_T(8 downto 0) <= irq_flags;

                if switch_buffer = '1' then
                    -- Switch to next given buffer and reset sample counter
                    axi_awaddr_val <= unsigned(DMA_ADDR);
                    sample_count <= (others => '0');
                    tlp_count <= (others => '0');
                end if;

                -- Next state
                if (last_tlp = '1' or next_dmaaddr_valid = '0') then
                    pcap_fsm <= COMPLETED;
                else
                    pcap_fsm <= ACTV;
                end if;

            -- Either End-Of-Experiment or Abort-on-Error happened.
            -- Requires full DMA reset-init cycle.
            when COMPLETED =>
                dma_irq <= '0';

            when others =>

        end case;
    end if;
end if;
end process;

--------------------------------------------------------------------------
-- Keep track of system status
--------------------------------------------------------------------------
-- PCAP completed or next buffer is not ready on interrupt
irq_flags(0) <= last_tlp or not next_dmaaddr_valid;
-- Completion reason (0 = Successful)
irq_flags(3 downto 1) <= pcap_status_i;
irq_flags(4) <= not next_dmaaddr_valid;
irq_flags(5) <= pcap_timeout_latch;
irq_flags(6) <= buffer_full;
irq_flags(7) <= '0';
irq_flags(8) <= start_event_detected;

--
-- AXI DMA Master Engine
--
axi_wdata_val(31 downto 0) <= fifo_dout(31 downto 0);

dma_write_master : entity work.axi_write_master
generic map (
    AXI_BURST_WIDTH     => AXI_BURST_WIDTH,
    AXI_ADDR_WIDTH      => AXI_ADDR_WIDTH,
    AXI_DATA_WIDTH      => AXI_DATA_WIDTH
)
port map (
    clk_i               => clk_i,
    reset_i             => reset,

    m_axi_burst_len     => M_AXI_BURST_LEN,

    m_axi_awready       => m_axi_awready,
    m_axi_awregion      => m_axi_awregion,
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

    dma_addr            => std_logic_vector(axi_awaddr_val),
    dma_data            => axi_wdata_val,
    dma_read            => fifo_rd_en,
    dma_start           => dma_start,
    dma_done            => dma_done,
    dma_error           => dma_error
);

IRQ_STATUS <= IRQ_STATUS_T;

end;
