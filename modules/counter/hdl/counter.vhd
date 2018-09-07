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
    trig_i           : in  std_logic;
    dir_i               : in  std_logic;
    carry_o             : out std_logic;
    -- Block Parameters
    START               : in  std_logic_vector(31 downto 0);
    START_WSTB          : in  std_logic;
    STEP                : in  std_logic_vector(31 downto 0);
    STEP_WSTB           : in  std_logic;
    -- Block Status
    out_o               : out std_logic_vector(31 downto 0)
);
end counter;

architecture rtl of counter is

constant c_step_size_one : std_logic_vector(31 downto 0) := x"00000001";

signal step_enable      : std_logic;
signal trigger_prev     : std_logic;
signal trigger_rise     : std_logic;
signal enable_prev      : std_logic;
signal enable_rise      : std_logic;
signal enable_fall      : std_logic;
signal counter          : signed(32 downto 0) := (others => '0');
signal STEP_default     : std_logic_vector(31 downto 0);

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

trigger_rise <= trig_i and not trigger_prev;
enable_rise <= enable_i and not enable_prev;
enable_fall <= not enable_i and enable_prev;

--------------------------------------------------------------------------
-- Default counter STEP to 1
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if STEP_WSTB = '1' then
            step_enable <= '1';
        elsif (enable_fall = '1') then
            step_enable <= '0';
        end if;    
    end if;
end process;

STEP_default <= STEP when step_enable = '1' else c_step_size_one;

--------------------------------------------------------------------------
-- Up/Down Counter
-- Counter keeps its last value when it is disabled and it is re-loaded
-- on the rising edge of enable input.
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Load the counter
        if (START_WSTB = '1' and enable_i = '1') then
                counter <= resize(signed(START), counter'length);
        -- Re-load on enable rising edge
        elsif (enable_rise = '1') then
                counter <= resize(signed(START), counter'length);
        -- Count up/down on trigger
        elsif (enable_i = '1' and trigger_rise = '1') then
            if (dir_i = '0') then
                counter <= counter + signed(STEP_default);
            else
                counter <= counter - signed(STEP_default);
            end if;
        end if;
    end if;
end process;

out_o <= std_logic_vector(counter(31 downto 0));

carry_o <= counter(32) xor counter (31) when trigger_prev = '1' else
           '0';


end rtl;
