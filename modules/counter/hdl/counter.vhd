--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : 32-bit programmable counter
--
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    enable_i            : in  std_logic;
    trig_i              : in  std_logic;
    dir_i               : in  std_logic;
    carry_o             : out std_logic;
    -- Block Parameters
    TRIG_EDGE           : in  std_logic_vector(31 downto 0) := (others => '0');
    TRIG_EDGE_WSTB      : in  std_logic;
    OUT_MODE            : in  std_logic_vector(31 downto 0);
    START               : in  std_logic_vector(31 downto 0);
    START_WSTB          : in  std_logic;
    STEP                : in  std_logic_vector(31 downto 0);
    STEP_WSTB           : in  std_logic;
    MAX                 : in  std_logic_vector(31 downto 0);
    MAX_WSTB            : in  std_logic;
    MIN                 : in  std_logic_vector(31 downto 0);
    MIN_WSTB            : in  std_logic;
    -- Block Status
    out_o               : out std_logic_vector(31 downto 0)
);
end counter;

architecture rtl of counter is

-- Maximum value = 17FFFFFFF ( 2**31-1 =  2147483647 dec, 7FFFFFFF)
constant c_max_val       : signed(31 downto 0) := x"7fffffff";
-- Minimum value = 080000000 (-2**31   = -2147483648 dec, 80000000)
constant c_min_val       : signed(31 downto 0) := x"80000000";

constant out_on_change   : std_logic_vector(31 downto 0) := x"00000000";
constant out_on_disable  : std_logic_vector(31 downto 0) := x"00000001";

constant c_step_size_one : signed(31 downto 0) := x"00000001";

signal trig_edge_i      : std_logic_vector(1 downto 0) := "00";
signal trigger_prev     : std_logic;
signal trigger_rise     : std_logic;
signal trigger_fall     : std_logic;
signal trigger_edge     : std_logic;
signal got_trigger      : std_logic;
signal enable_prev      : std_logic;
signal enable_rise      : std_logic;
signal enable_fall      : std_logic;
signal counter          : signed(31 downto 0) := (others => '0');
signal counter_end      : signed(31 downto 0) := (others => '0');
signal STEP_default     : signed(31 downto 0) := (others => '0');
signal MAX_VAL          : signed(31 downto 0) := c_max_val;
signal MIN_VAL          : signed(31 downto 0) := c_min_val;
signal counter_carry    : std_logic;
signal carry_latch      : std_logic;
signal carry_end        : std_logic;

begin


--------------------------------------------------------------------------
-- Input registering
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        trigger_prev <= trig_i;
        enable_prev <= enable_i;
    end if;
end process;

-- Trigger edges detection
trig_edge_i <= TRIG_EDGE(1 downto 0);
trigger_rise <= trig_i and not trigger_prev;
trigger_fall <= not trig_i and trigger_prev;
-- Enable rising edge detection
enable_rise <= enable_i and not enable_prev;
enable_fall <= not enable_i and enable_prev;
trigger_edge <= trigger_rise or trigger_fall;
-- Calculation of
got_trigger <=
    trigger_edge when trig_edge_i = "10" else
    trigger_fall when trig_edge_i = "01" else
    trigger_rise when trig_edge_i = "00" else '0';

--------------------------------------------------------------------------
-- Default counter STEP to 1
--------------------------------------------------------------------------

STEP_default <= c_step_size_one when signed(STEP) = to_signed(0,32) else signed(STEP);

--------------------------------------------------------------------------
-- Up/Down Counter
-- Counter keeps its last value when it is disabled and it is re-loaded
-- on the rising edge of enable input.
--------------------------------------------------------------------------
process(clk_i)

variable next_counter : signed(32 downto 0);

begin
    if rising_edge(clk_i) then
        if ((MAX_WSTB = '1' or MIN_WSTB = '1') and signed(MAX) = to_signed(0,32) and signed(MIN) = to_signed(0,32)) then
            MAX_VAL <= c_max_val;
            MIN_VAL <= c_min_val;
        elsif (MAX_WSTB = '1' or MIN_WSTB = '1') then
         -- The default value is used until Maximum or Minimum value is written
         -- to and either one does not equal 0
            MAX_VAL <= signed(MAX);
            MIN_VAL <= signed(MIN);
        end if;

        -- Re-load on enable rising edge
        if (enable_rise = '1') then
            counter <= signed(START);
            carry_latch <= '0';
        -- Drop the carry signal on falling enable
        elsif (enable_fall = '1') then
            counter_carry <= '0';
            counter_end <= next_counter(31 downto 0);
            carry_end <= carry_latch;
        elsif (enable_i = '1' and trigger_edge = '1') then
            if (counter_carry = '1') then
                -- Need to stop the counter_carry on next trigger edge
                counter_carry <= '0';
            end if;
            if (got_trigger = '1') then
                -- Count up/down on trigger
                -- Initialise next_counter with current value
                next_counter := resize(counter, next_counter'length);
                -- Direction
                if (dir_i = '0') then
                    next_counter := next_counter + STEP_default;
                else
                    next_counter := next_counter - STEP_default;
                end if;
                -- Check to see if we are crossing from the positive to negative or
                -- negative to positive boundaries if we do set the carry bit
                if (next_counter > MAX_VAL) then
                    -- Crossing boundary positive
                    counter_carry <= '1';
                    carry_latch <= '1';
                    next_counter := next_counter - (MAX_VAL - MIN_VAL + 1);
                elsif (next_counter < MIN_VAL) then
                    -- Crossing boundary negative
                    counter_carry <= '1';
                    carry_latch <= '1';
                    next_counter := next_counter + (MAX_VAL - MIN_VAL + 1);
                end if;
                -- Increment the counter
                -- This might overflow if MAX - MIN < STEP, but we don't care
                -- about that use case
                counter <= next_counter(31 downto 0);
            end if;
        end if;
    end if;
end process;

out_o <= std_logic_vector(counter_end) when OUT_MODE = out_on_disable else
         std_logic_vector(counter);
carry_o <= carry_end when OUT_MODE = out_on_disable else
           counter_carry;

end rtl;
