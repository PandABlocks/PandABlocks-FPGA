--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : CLOCKS block provides 4 user configurable clock sources.
--                Clock period is controlled by user register in clock ticks.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock is
port (
    -- Clock and Reset
    clk_i             : in  std_logic;
    ENABLE_i          : in  std_logic;                
    -- Block Input and Outputs
    out_o             : out std_logic := '0';
    -- Block Parameters
    PERIOD            : in  std_logic_vector(31 downto 0);
    PERIOD_wstb       : in  std_logic;
    WIDTH             : in  std_logic_vector(31 downto 0);
    WIDTH_wstb        : in  std_logic
);
end;

architecture rtl of clock is
    signal enable : std_logic;
    signal reload : unsigned(31 downto 0);
    signal valid_period : std_logic := '0';
    signal low_period : unsigned(31 downto 0);
begin

process(clk_i)
    variable reset : std_logic;
    variable full_period : unsigned(31 downto 0);
    variable high_period : unsigned(31 downto 0);
begin
    if rising_edge(clk_i) then
        reset := PERIOD_wstb or WIDTH_wstb;
        enable <= enable_i and (not reset) and valid_period;

        if (unsigned(PERIOD) = 0 and unsigned(WIDTH) = 0) then
            reload <= to_unsigned(0, 32);
            valid_period <= '0';
        -- if PERIOD <= WIDTH, set period to (WIDTH+1)
        elsif (unsigned(PERIOD) <= unsigned(WIDTH)) then
            reload <= unsigned(WIDTH);
            valid_period <= '1';
        -- if WIDTH=0 and PERIOD < 2, set period to 2
        elsif unsigned(PERIOD) = 1 then
            reload <= to_unsigned(1, 32);
            valid_period <= '1';
        -- if (PERIOD > WIDTH) and (PERIOD > 1), set period to PERIOD
        else
            reload <= unsigned(PERIOD) - 1;
            valid_period <= '1';
        end if;
        full_period := reload + 1;
        -- if WIDTH=0 then set OUT high time to half period
        if (unsigned(WIDTH) = 0) then
            high_period := '0' & full_period(31 downto 1);
        else
            high_period := unsigned(WIDTH);
        end if;
       low_period <= full_period - high_period;
    end if;
end process;

timer_inst: entity work.timer_for_clock port map (
    clk_i => clk_i,
    enable_i => enable,
    low_i => std_logic_vector(low_period),
    auto_reload_i => std_logic_vector(reload),
    out_o => out_o
);

end;
