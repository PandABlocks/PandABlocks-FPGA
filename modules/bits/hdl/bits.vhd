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
    A                   : in  std_logic_vector(31 downto 0);
    B                   : in  std_logic_vector(31 downto 0);
    C                   : in  std_logic_vector(31 downto 0);
    D                   : in  std_logic_vector(31 downto 0)
);
end bits;

architecture rtl of bits is

begin


process(clk_i)
begin
    if rising_edge(clk_i) then
        OUTA_o <= A(0);
        OUTb_o <= B(0);
        OUTc_o <= C(0);
        OUTd_o <= D(0);
    end if;
end process;

end rtl;


