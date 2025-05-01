--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Long table based position generation module.
--                32-bit data in and out interface.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity pgen is
generic (
    AXI_BURST_LEN       : integer := 256;
    DW                  : natural := 32     -- Output Data Width
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    enable_i            : in  std_logic;
    trig_i              : in  std_logic;
    out_o               : out std_logic_vector(DW-1 downto 0);
    -- Block Parameters
    REPEATS             : in  std_logic_vector(31 downto 0);
    ACTIVE_o            : out std_logic;
    STATE               : out std_logic_vector(31 downto 0) := (others => '0');
    TABLE_ADDRESS       : in  std_logic_vector(31 downto 0);
    TABLE_ADDRESS_WSTB  : in  std_logic;
    TABLE_LENGTH        : in  std_logic_vector(31 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic;
    health              : out std_logic_vector(31 downto 0) := (others => '0');
    -- DMA Engine Interface
    dma_req_o           : out std_logic;
    dma_ack_i           : in  std_logic;
    dma_done_i          : in  std_logic;
    dma_addr_o          : out std_logic_vector(31 downto 0);
    dma_len_o           : out std_logic_vector(7 downto 0);
    dma_data_i          : in  std_logic_vector(31 downto 0);
    dma_valid_i         : in  std_logic;
    dma_irq_o           : out std_logic := '0';
    dma_done_irq_o      : out std_logic := '0'
);
end pgen;

architecture rtl of pgen is

component fifo_1K32
port (
    clk                 : in std_logic;
    srst                : in std_logic;
    din                 : in std_logic_vector(31 DOWNTO 0);
    wr_en               : in std_logic;
    rd_en               : in std_logic;
    dout                : out std_logic_vector(31 DOWNTO 0);
    full                : out std_logic;
    empty               : out std_logic;
    data_count          : out std_logic_vector(9 downto 0)
);
end component;

type state_t is (UNREADY, WAIT_ENABLE, RUNNING);
signal pgen_fsm         : state_t;

signal fifo_rd_en       : std_logic;
signal fifo_dout        : std_logic_vector(DW-1 downto 0);
signal fifo_count       : integer range 0 to 1023;
signal fifo_full        : std_logic;
signal fifo_empty       : std_logic;
signal fifo_data_count  : std_logic_vector(9 downto 0);
signal fifo_available   : std_logic;

signal trig             : std_logic;
signal enable           : std_logic;
signal trig_pulse       : std_logic;
signal enable_fall      : std_logic;

signal enable_rise : std_logic;
signal error_event : std_logic := '0';
signal overrun_event : std_logic := '0';
signal underrun_event : std_logic := '0';
signal all_transfers_completed : std_logic := '0';
signal transfer_busy : std_logic := '0';
signal reset_table : std_logic := '0';
signal abort_dma : std_logic := '0';
signal active : std_logic := '0';

begin

-- Assign outputs
out_o <= fifo_dout;
STATE(1 downto 0) <= "00" when pgen_fsm = UNREADY else
                     "01" when pgen_fsm = WAIT_ENABLE else
                     "10";

--
-- 32bit FIFO with 1K sample depth
--
dma_fifo_inst : fifo_1K32
port map (
    srst            => reset_table,
    clk             => clk_i,
    din             => dma_data_i,
    wr_en           => dma_valid_i,
    rd_en           => fifo_rd_en,
    dout            => fifo_dout,
    full            => fifo_full,
    empty           => fifo_empty,
    data_count      => fifo_data_count
);
fifo_rd_en <= trig_pulse;
fifo_count <= to_integer(unsigned(fifo_data_count));

--
-- Input registers
--
process(clk_i) begin
    if rising_edge(clk_i) then
        trig <= trig_i;
        enable <= enable_i;
    end if;
end process;

-- Trigger pulse pops data from fifo and tick data counter when block
-- is enabled and table is ready.
trig_pulse <= (trig_i and not trig) and active;
enable_fall <= not enable_i and enable;
enable_rise <= enable_i and not enable;
--

error_event <= underrun_event or overrun_event;
underrun_event <= fifo_rd_en and fifo_empty;

tre_client: entity work.table_read_engine_client port map (
    clk_i => clk_i,
    abort_i => abort_dma,
    address_i => TABLE_ADDRESS,
    length_i => TABLE_LENGTH,
    length_wstb_i => TABLE_LENGTH_WSTB,
    length_o => open,
    more_o => open,
    length_taken_i => '1',
    completed_o => all_transfers_completed,
    available_beats_i => x"00000" & "00" & (not fifo_data_count),
    overflow_error_o => overrun_event,
    repeat_i => REPEATS,
    busy_o => transfer_busy,
    resetting_o => reset_table,
    -- DMA Engine Interface
    dma_req_o => dma_req_o,
    dma_ack_i => dma_ack_i,
    dma_done_i => dma_done_i,
    dma_addr_o => dma_addr_o,
    dma_len_o => dma_len_o,
    dma_data_i => dma_data_i,
    dma_valid_i => dma_valid_i,
    dma_irq_o => dma_irq_o,
    dma_done_irq_o => dma_done_irq_o
);

process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Assign HEALTH output as Enum.
        if health(1 downto 0) = "00" then
            if underrun_event then
                health(1 downto 0) <= TO_SVECTOR(1,2);
            elsif overrun_event then
                health(1 downto 0) <= TO_SVECTOR(2,2);
            end if;
        end if;
        if enable_rise then
            health(1 downto 0) <= (others => '0');
        end if;
    end if;
end process;

process (clk_i)
begin
    if rising_edge(clk_i) then
        abort_dma <= '0';
        if enable_fall or error_event then
            active <= '0';
            pgen_fsm <= UNREADY;
            if pgen_fsm /= UNREADY and pgen_fsm /= WAIT_ENABLE then
                pgen_fsm <= UNREADY;
                abort_dma <= '1';
            end if;
        else
            case pgen_fsm is
                when UNREADY =>
                    if not fifo_empty then
                        pgen_fsm <= WAIT_ENABLE;
                    end if;

                when WAIT_ENABLE =>
                    if fifo_empty then
                        pgen_fsm <= UNREADY;
                    elsif enable_rise then
                        pgen_fsm <= RUNNING;
                        active <= '1';
                    end if;

                when RUNNING =>
                    if all_transfers_completed and fifo_empty then
                        pgen_fsm <= UNREADY;
                        active <= '0';
                    end if;

                when others =>
                    pgen_fsm <= UNREADY;
            end case;
        end if;
    end if;
end process;

ACTIVE_o <= active;
end rtl;
