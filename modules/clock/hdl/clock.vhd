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
    out_o             : out std_logic;
    -- Block Parameters
    PERIOD            : in  std_logic_vector(31 downto 0);
    PERIOD_wstb       : in  std_logic
);
end clock;

architecture rtl of clock is

signal reset            : std_logic;
signal counter32        : unsigned(31 downto 0);
signal DIV              : unsigned(31 downto 0);

------------------------------------------------
signal half_period      : unsigned(31 downto 0);
------------------------------------------------

begin

reset <= PERIOD_wstb;


DIV <= unsigned(PERIOD) + 1;

------------------------------------------------
half_period <= unsigned('0' & DIV(31 downto 1));
------------------------------------------------

process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Reset counter on parameter change.
        if (reset = '1') then
            if (unsigned(PERIOD) > 0) then              ----
                counter32 <= unsigned(PERIOD) - 1;
            else                                        ----
                counter32 <= (others => '0');           ----
            end if;                                     ----
--            OUT_o <= '0';
            OUT_o <= '1';            
        else
            if (ENABLE_i = '1') then            
                -- Free running down counter.
                if (counter32 = 0) then
                    counter32 <= unsigned(PERIOD) - 1;
                else
                    counter32 <= counter32 - 1;
                end if;

                -- Half div reached
                if (counter32 = unsigned('0' & DIV(31 downto 1))) or (unsigned(PERIOD) = 0) then
---                if (counter32 = unsigned('0' & DIV(31 downto 1))) then
--                  OUT_o <= '1';
                    OUT_o <= '0';
                -- Reload when reach Zero and assert clock output.
                elsif (counter32 = 0) then
--                  OUT_o <= '0';
                    OUT_o <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

end rtl;


