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
use work.top_defines.all;

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
    out_o               : out std_logic_vector(DW-1 downto 0) := (others => '0');
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

constant N_ENTRIES : positive := 4096;
type state_t is (UNREADY, WAIT_ENABLE, RUNNING);
signal pgen_fsm : state_t;
signal trig : std_logic;
signal enable : std_logic;
signal trig_pulse : std_logic;
signal enable_fall : std_logic;
signal enable_rise : std_logic;
signal error_event : std_logic := '0';
signal overrun_event : std_logic := '0';
signal underrun_event : std_logic := '0';
signal transfer_busy : std_logic := '0';
signal resetting_dma : std_logic := '0';
signal abort_dma : std_logic := '0';
signal active : std_logic := '0';
signal room : std_logic_vector(11 downto 0);
signal data_last : std_logic;
signal last : std_logic;
signal data_valid : std_logic;
signal wrapping_mode : std_logic;
signal wrapping_mode_reset : std_logic := '0';
signal streaming_mode : std_logic;
signal one_buffer_mode : std_logic;
signal last_line : std_logic;
signal last_repeat : std_logic;
signal line_count : unsigned(31 downto 0) := (others => '0');
signal repeats_count : unsigned(31 downto 0) := (others => '0');
signal data : std_logic_vector(31 downto 0);

begin

STATE(1 downto 0) <= "00" when pgen_fsm = UNREADY else
                     "01" when pgen_fsm = WAIT_ENABLE else
                     "10";

pgen_ring_table : entity work.pgen_ring_table generic map (
    LEN => N_ENTRIES
) port map (
    clk_i => clk_i,
    reset_i => resetting_dma or wrapping_mode_reset,
    -- Block Input and Outputs
    rdata_o => data,
    rdata_valid_o => data_valid,
    rdata_ready_i => trig_pulse,
    rdata_last_o => data_last,
    available_o => room,
    wrapping_mode_i => wrapping_mode,
    -- input data
    wdata_i => dma_data_i,
    wdata_valid_i => dma_valid_i,
    -- we always have room because we push based on available space
    wdata_ready_o => open,
    wdata_last_i => last,
    ndatas_o => open
);

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
underrun_event <= trig_pulse and not data_valid;
wrapping_mode <= to_std_logic(
    unsigned(TABLE_LENGTH) < N_ENTRIES and one_buffer_mode = '1' and
    resetting_dma = '0');

tre_client: entity work.table_read_engine_client port map (
    clk_i => clk_i,
    abort_i => abort_dma,
    address_i => TABLE_ADDRESS,
    length_i => TABLE_LENGTH,
    length_wstb_i => TABLE_LENGTH_WSTB,
    completed_o => open,
    available_i => x"00000" & room,
    overflow_error_o => overrun_event,
    busy_o => transfer_busy,
    resetting_o => resetting_dma,
    last_o => last,
    streaming_mode_o => streaming_mode,
    one_buffer_mode_o => one_buffer_mode,
    loop_one_buffer_i => not wrapping_mode,
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
        wrapping_mode_reset <= '0';
        if enable_fall or error_event then
            active <= '0';
            line_count <= (others => '0');
            repeats_count <= (others => '0');
            if pgen_fsm /= UNREADY and pgen_fsm /= WAIT_ENABLE then
                if wrapping_mode and not error_event then
                    pgen_fsm <= WAIT_ENABLE;
                    wrapping_mode_reset <= '1';
                else
                    pgen_fsm <= UNREADY;
                    abort_dma <= '1';
                end if;
            end if;
        else
            case pgen_fsm is
                when UNREADY =>
                    if data_valid and not resetting_dma then
                        pgen_fsm <= WAIT_ENABLE;
                    end if;

                when WAIT_ENABLE =>
                    if not data_valid then
                        pgen_fsm <= UNREADY;
                    elsif enable_rise then
                        pgen_fsm <= RUNNING;
                        line_count <= to_unsigned(1, 32);
                        repeats_count <= to_unsigned(1, 32);
                        active <= '1';
                    end if;

                when RUNNING =>
                    if trig_pulse then
                        out_o <= data;
                        if last_repeat then
                            pgen_fsm <= UNREADY when streaming_mode else
                                        WAIT_ENABLE;
                            active <= '0';
                        elsif last_line then
                            line_count <= to_unsigned(1, 32);
                            if one_buffer_mode then
                                repeats_count <= repeats_count + 1;
                            end if;
                        else
                            line_count <= line_count + 1;
                        end if;
                    end if;

                when others =>
                    pgen_fsm <= UNREADY;
            end case;
        end if;
    end if;
end process;

last_line <=
    to_std_logic((one_buffer_mode = '1' and line_count = unsigned(TABLE_LENGTH)) or
        data_last = '1');
last_repeat <= last_line when
    (streaming_mode = '0' and REPEATS /= X"0000_0000" and
    repeats_count = unsigned(REPEATS)) or streaming_mode = '1' else '0';
ACTIVE_o <= active;
end rtl;
