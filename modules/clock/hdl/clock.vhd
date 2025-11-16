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
end clock;

architecture rtl of clock is

signal reset            : std_logic;
signal enable            : std_logic;
signal counter32        : unsigned(31 downto 0);
signal full_period      : unsigned(31 downto 0);
signal low_period       : unsigned(31 downto 0);

begin

process(clk_i)
variable high_period      : unsigned(31 downto 0);

begin
    if rising_edge(clk_i) then
        reset <= PERIOD_wstb or WIDTH_wstb;
        enable <= ENABLE_i;
        if (unsigned(PERIOD) = 0 and unsigned(WIDTH) = 0) then
            full_period <= to_unsigned(0, 32);
        -- if PERIOD <= WIDTH, set period to (WIDTH+1)
        elsif (unsigned(PERIOD) <= unsigned(WIDTH)) then
            full_period <= unsigned(WIDTH) + 1;
        -- if WIDTH=0 and PERIOD < 2, set period to 2
        elsif unsigned(PERIOD) = 1 then
            full_period <= to_unsigned(2, 32);
        -- if (PERIOD > WIDTH) and (PERIOD > 1), set period to PERIOD
        else
            full_period <= unsigned(PERIOD);
        end if;
        -- if WIDTH=0 then set OUT high time to half period
        if (unsigned(WIDTH) = 0) then
            high_period := '0' & full_period(31 downto 1);
        else
            high_period := unsigned(WIDTH);
        end if;
        low_period <= full_period - high_period;

        -- If not enabled, or no period set stop the clocks
        if (enable = '0') or (full_period = 0) then
            OUT_o <= '0';
            counter32 <= (others => '0');
        -- Reset counter on parameter change.
        elsif (reset = '1') then
            OUT_o <= '1';
            counter32 <= full_period - 1;
        else
            -- Reload when reach Zero and assert clock output.
            if (counter32 = 0) then
                OUT_o <= '1';
            -- High period reached
            elsif (counter32 = low_period) then
                OUT_o <= '0';
            end if;

            -- Free running down counter.
            if (counter32 = 0) then
                counter32 <= full_period - 1;
            else
                counter32 <= counter32 - 1;
            end if;
        end if;
    end if;
end process;

end rtl;


