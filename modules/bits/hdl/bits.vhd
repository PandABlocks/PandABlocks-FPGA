--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : BITS block provides 4 user configurable soft inputs.
--                Soft inputs are controlled through register interface.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bits is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    softa_o             : out std_logic;
    softb_o             : out std_logic;
    softc_o             : out std_logic;
    softd_o             : out std_logic;
    -- Block Parameters
    SOFTA_SET           : in  std_logic;
    SOFTB_SET           : in  std_logic;
    SOFTC_SET           : in  std_logic;
    SOFTD_SET           : in  std_logic
);
end bits;

architecture rtl of bits is

begin


process(clk_i)
begin
    if rising_edge(clk_i) then
        softa_o <= SOFTA_SET;
        softb_o <= SOFTB_SET;
        softc_o <= SOFTC_SET;
        softd_o <= SOFTD_SET;
    end if;
end process;

end rtl;


