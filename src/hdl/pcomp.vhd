--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Position compare output pulse generator.
--                Supports regular and table-based comparison.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity pcomp is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block inputs
    enable_i            : in  std_logic;
    posn_i              : in  std_logic_vector(31 downto 0);
    table_posn_i        : in  std_logic_vector(63 downto 0);
    table_read_o        : out std_logic;
    -- Block inputs
    START               : in  std_logic_vector(31 downto 0);
    STEP                : in  std_logic_vector(31 downto 0);
    WIDTH               : in  std_logic_vector(31 downto 0);
    NUM                 : in  std_logic_vector(31 downto 0);
    RELATIVE            : in  std_logic;
    DIR                 : in  std_logic;
    DELTAP              : in  std_logic_vector(31 downto 0);
    USE_TABLE           : in  std_logic;
    -- Output pulse
    act_o               : out std_logic;
    pulse_o             : out std_logic;
    err_o               : out std_logic_vector(31 downto 0)
);
end pcomp;

architecture rtl of pcomp is

type fsm_t is (WAIT_ENABLE, WAIT_DELTAP, WAIT_START, WAIT_WIDTH, WAIT_IN_ERROR);
signal pcomp_fsm        : fsm_t;

signal enable_prev      : std_logic;
signal enable_rise      : std_logic;
signal enable_fall      : std_logic;
signal posn_input       : signed(31 downto 0);
signal posn_latched     : signed(31 downto 0);
signal posn_relative    : signed(31 downto 0);
signal posn             : signed(31 downto 0);
signal puls_start       : signed(31 downto 0);
signal puls_width       : signed(31 downto 0);
signal puls_step        : signed(31 downto 0);
signal puls_deltap      : signed(31 downto 0);
signal puls_counter     : unsigned(31 downto 0);
signal current_crossing : signed(31 downto 0);
signal next_crossing    : signed(31 downto 0);
signal error_detect     : std_logic;
signal posn_error       : std_logic;
signal pulse            : std_logic;

signal table_start      : signed(31 downto 0);
signal table_width      : signed(31 downto 0);
signal table_dir        : std_logic;
signal table_read       : std_logic;

signal puls_dir         : std_logic;
signal pos_cross        : std_logic;
signal neg_cross        : std_logic;

begin

-- Assign outputs.
pulse_o <= pulse;

--
-- Register inputs and detect rise/fall edges required
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_i;
    end if;
end process;

enable_rise <= enable_i and not enable_prev;
enable_fall <= not enable_i and enable_prev;

--
-- Sign conversion for parameters based on encoder direction.
--
puls_start <= signed(START);
puls_width <= signed(WIDTH) when (DIR = '0') else
                    signed(not unsigned(WIDTH) + 1);
puls_step <= signed(STEP) when (DIR = '0') else
                    signed(not unsigned(STEP) + 1);
puls_deltap <= signed(DELTAP) when (DIR = '0') else
                    signed(not unsigned(DELTAP) + 1);

puls_dir <= DIR when (USE_TABLE = '0') else table_dir;

-- Separate 64-bit table data input.
table_start <= signed(table_posn_i(63 downto 32));
table_width <= signed(table_posn_i(31 downto 0));

--
-- Latch position on the rising edge of enable_i input, and calculate live
-- Pulse Start position based on RELATIVE flag and encoder direction signal.
--
posn_relative <= signed(posn_i) - posn_latched;
posn_input <= signed(posn_i) when (RELATIVE = '0') else posn_relative;
posn <= posn_input;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_latched <= (others => '0');
        else
            -- Keep latched value for RELATIVE mode
            if (enable_rise = '1') then
                posn_latched <= signed(posn_i);
            end if;
        end if;
    end if;
end process;

-- Error detection is currently only available in normal mode.
error_detect <= not USE_TABLE when (pcomp_fsm = WAIT_START or pcomp_fsm = WAIT_WIDTH) else '0';

-- Flag an error when encoder position skips two comparison points in one go.
posn_error <= '1' when (error_detect = '1') and
                ((puls_dir = '0' and posn > next_crossing) or
                    (puls_dir = '1' and posn < next_crossing))
                else '0';

pos_cross <= '1' when (puls_dir = '0' and posn >= current_crossing) else '0';
neg_cross <= '1' when (puls_dir = '1' and posn <= current_crossing) else '0';

table_read_o <= enable_rise or table_read when (USE_TABLE = '1') else '0';

--
-- Pulse generator state machine
--
outp_gen : process(clk_i)
begin
if rising_edge(clk_i) then
    if (reset_i = '1' or enable_fall = '1') then
        pulse <= '0';
        puls_counter <= (others => '0');
        act_o <= '0';
        err_o <= (others => '0');
        pcomp_fsm <= WAIT_ENABLE;
        table_dir <= '0';
        table_read <= '0';
    -- On error stuck is ERROR state until re-enabled.
    elsif (posn_error = '1') then
        err_o(0) <= '1';
        pulse <= '0';
        puls_counter <= (others => '0');
        act_o <= '0';
        pcomp_fsm <= WAIT_IN_ERROR;
    else
        -- Extract table direction from Delta_P, first entry on the
        -- table.
        if (pcomp_fsm = WAIT_ENABLE and enable_rise = '1') then
            if (table_start < table_width) then
                table_dir <= '0';
            else
                table_dir <= '1';
            end if;
        end if;

        -- Read strobe for the next value in the table.
        table_read <= '0';

        case pcomp_fsm is
            -- Wait for enable rise to cur_start operation.
            when WAIT_ENABLE =>
                pulse <= '0';
                puls_counter <= (others => '0');
                act_o <= '0';

                if (enable_rise = '1') then
                    -- Read first sample as absolute DeltaP.
                    if (USE_TABLE = '1') then
                        current_crossing <= table_start;
                    -- Get DeltaP absolute position.
                    else
                        current_crossing <= puls_start - puls_deltap;
                    end if;
                    act_o <= '1';
                    pcomp_fsm <= WAIT_DELTAP;
                end if;

            -- Wait for DeltaP to start pulse generation.
            when WAIT_DELTAP =>
                if (puls_dir = '0' and posn <= current_crossing)
                    or (puls_dir = '1' and posn >= current_crossing) then
                    pcomp_fsm <= WAIT_START;
                    if (USE_TABLE = '1') then
                        current_crossing <= table_start;
                        next_crossing <= table_start + table_width;
                    else
                        current_crossing <= puls_start;
                        next_crossing <= puls_start + puls_step;
                    end if;
                end if;

            -- Wait for pulse start position, and assert pulse output.
            when WAIT_START =>
                if (pos_cross = '1' or neg_cross = '1') then
                    pulse <= not pulse;
                    puls_counter <= puls_counter + 1;
                    pcomp_fsm <= WAIT_WIDTH;
                    table_read <= '1';
                    if (USE_TABLE = '1') then
                        current_crossing <= table_width;
                        next_crossing <= table_start + table_width;
                    else
                        current_crossing <= current_crossing + puls_width;
                        next_crossing <= next_crossing;
                    end if;
                end if;

            -- Wait for pulse width position, and de-assert pulse output.
            when WAIT_WIDTH =>
                if (pos_cross = '1' or neg_cross = '1') then
                    pulse <= not pulse;
                    if (USE_TABLE = '1') then
                        current_crossing <= table_start;
                    else
                        current_crossing <= next_crossing;
                        next_crossing <= next_crossing + puls_step;
                    end if;

                    -- Make End-Of-Operation Decision:
                    -- Run forever until disabled.
                    if (unsigned(NUM) = 0) then
                        if (puls_step = 0) then
                            pcomp_fsm <= WAIT_DELTAP;
                        else
                            pcomp_fsm <= WAIT_START;
                        end if;
                    -- Run for NPulses and stop.
                    elsif (puls_counter = unsigned(NUM)) then
                        pcomp_fsm <= WAIT_ENABLE;
                        act_o <= '0';
                    -- Ongoing PNUM, so go back.
                    else
                        -- Step=0 is a special condition used to gate 
                        -- positive and negative cycles.
                        if (puls_step = 0 and USE_TABLE = '0') then
                            pcomp_fsm <= WAIT_DELTAP;
                        else
                            pcomp_fsm <= WAIT_START;
                        end if;
                    end if;
                end if;

            when WAIT_IN_ERROR =>

            when others =>
        end case;
    end if;
end if;
end process;

end rtl;

