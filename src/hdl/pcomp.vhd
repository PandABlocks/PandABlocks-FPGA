--------------------------------------------------------------------------------
--  File:       pcomp.vhd
--  Desc:       Position compare output pulse generator
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

begin

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
--
--
table_start <= signed(table_posn_i(31 downto 0));
table_width <= signed(table_posn_i(63 downto 32));
table_dir <= '0' when (table_start < table_width) else '0';

--
-- Sign conversion for calculations based on encoder direction
--
puls_width <= signed(WIDTH);
puls_step <= signed(STEP);
puls_start <= signed(START);
puls_deltap <= signed(unsigned(not DELTAP) + 1);

--
-- Latch position on the rising edge of enable_i input, and calculate live
-- Pulse Start position based on RELATIVE flag and encoder direction signal.
--
posn_relative <= signed(posn_i) - posn_latched;
posn_input <= signed(posn_i) when (RELATIVE = '0') else posn_relative;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn <= (others => '0');
            posn_latched <= (others => '0');
        else
            -- Keep latched value for RELATIVE mode
            if (enable_rise = '1') then
                posn_latched <= signed(posn_i);
            end if;

            -- Absolute posn input is used for Table mode.
            if (USE_TABLE = '1') then
                posn <= posn_input;
            -- Normal mode calculates the position relative to Start.
            else
                if (DIR = '0') then
                    posn <= posn_input - signed(START);
                else
                    posn <= signed(START)  - posn_input;
                end if;
            end if;
        end if;
    end if;
end process;

--
-- Pulse generator state machine
--
error_detect <= '1' when (pcomp_fsm = WAIT_START or pcomp_fsm = WAIT_WIDTH) else '0';
posn_error <= '1' when (error_detect = '1' and posn > next_crossing) else '0';

outp_gen : process(clk_i)
begin
if rising_edge(clk_i) then
    if (reset_i = '1' or enable_fall = '1') then
        pulse <= '0';
        puls_counter <= (others => '0');
        act_o <= '0';
        err_o <= (others => '0');
        pcomp_fsm <= WAIT_ENABLE;
    -- On error stuck is ERROR state until re-enabled.
    elsif (posn_error = '1') then
        err_o(0) <= '1';
        pulse <= '0';
        puls_counter <= (others => '0');
        act_o <= '0';
        pcomp_fsm <= WAIT_IN_ERROR;
    else
        case pcomp_fsm is
            -- Wait for enable rise to cur_start operation.
            when WAIT_ENABLE =>
                pulse <= '0';
                puls_counter <= (others => '0');
                act_o <= '0';

                if (enable_rise = '1') then
                    current_crossing <= puls_deltap;
                    next_crossing <= to_signed(0, next_crossing'length);
                    act_o <= '1';
                    pcomp_fsm <= WAIT_DELTAP;
                end if;

            -- Wait for cur_start crossing to assert the output pulse.
            when WAIT_DELTAP =>
                if (posn < current_crossing) then
                    current_crossing <= to_signed(0, next_crossing'length);
                    next_crossing <= puls_step;
                    pcomp_fsm <= WAIT_START;
                end if;

            when WAIT_START =>
                if (posn >= current_crossing) then
                    pulse <= not pulse;
                    puls_counter <= puls_counter + 1;
                    current_crossing <= current_crossing + puls_width;
                    next_crossing <= next_crossing;
                    pcomp_fsm <= WAIT_WIDTH;
                end if;

            -- Wait for cur_width crossing to de-assert the output pulse.
            when WAIT_WIDTH =>
                if (posn >= current_crossing) then
                    pulse <= not pulse;
                    current_crossing <= next_crossing;
                    next_crossing <= next_crossing + puls_step;

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
                    else
                        if (puls_step = 0) then
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

-- Assign output pulse when module is enabled.
pulse_o <= pulse;

end rtl;

