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
    OUTA_o              : out std_logic;
    OUTB_o              : out std_logic;
    OUTC_o              : out std_logic;
    OUTD_o              : out std_logic;
    -- Block Parameters
    A                   : in  std_logic;
    B                   : in  std_logic;
    C                   : in  std_logic;
    D                   : in  std_logic
);
end bits;

architecture rtl of bits is

begin


process(clk_i)
begin
    if rising_edge(clk_i) then
        OUTA_o <= A;
        OUTb_o <= B;
        OUTc_o <= C;
        OUTd_o <= D;
    end if;
end process;

end rtl;


