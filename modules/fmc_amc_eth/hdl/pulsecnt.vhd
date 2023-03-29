--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : 
--------------------------------------------------------------------------------
--
--  Description : 32-bit pulse counter
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulsecnt is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    SOFT_RESET_i        : in  std_logic;
    trig_i              : in  std_logic;
    carry_o             : out std_logic;
    cnt_o               : out std_logic_vector(31 downto 0)
);
end pulsecnt;

architecture rtl of pulsecnt is

signal trigger_prev     : std_logic;
signal trigger_rise     : std_logic;
signal counter          : unsigned(31 downto 0) := (others => '0');
signal MAX_VAL          : unsigned(31 downto 0) := (others => '1');
--signal MIN_VAL          : unsigned(31 downto 0) := c_min_val;
signal counter_carry    : std_logic;

begin
--------------------------------------------------------------------------
-- Input registering
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i='1') then
			trigger_prev <= '0';
		else
			-- Reset the counter
			if (SOFT_RESET_i = '1') then
				trigger_prev <= '0';
			else 
				trigger_prev <= trig_i;
			end if;
		end if;
    end if;
end process;
trigger_rise <= trig_i and not trigger_prev;
--------------------------------------------------------------------------
-- Up Counter
-- Counter keeps its last value when it is disabled and it is re-loaded
-- on the rising edge of enable input.
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
		if (reset_i='1') then
			counter <= (others => '0');
			counter_carry <= '0';
        else
			-- Reset the counter
			if (SOFT_RESET_i = '1') then
				counter <= (others => '0');
				counter_carry <= '0';
			elsif (trigger_rise = '1') then
				if (counter = MAX_VAL)then
					counter_carry <= '1';
					-- Crossing boundary when going positive
					counter <= counter + 1;
				else
					counter_carry <= '0';
					-- Increment the counter
					counter <= counter + 1;
				end if;
			end if;
		end if;
    end if;
end process;

cnt_o <= std_logic_vector(counter);
carry_o <= counter_carry;

end rtl;

