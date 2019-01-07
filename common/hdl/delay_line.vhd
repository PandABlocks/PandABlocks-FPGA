--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Implement delay line with NO reset so that it can be mapped
--                onto a Slice LUT.
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity delay_line is
generic (
    DW                  : positive := 32;
    TAPS                : positive := 32
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    data_i              : in  std_logic_vector(DW-1 downto 0);
    data_o              : out std_logic_vector(DW-1 downto 0);
    -- Block registers
    DELAY               : in  std_logic_vector(LOG2(TAPS)-1 downto 0)
);
end delay_line;

architecture rtl of delay_line is

subtype data_t is std_logic_vector(DW-1 downto 0);
type data_array is array(natural range <>) of data_t;

signal taps_line        : data_array(TAPS-1 downto 0) := (others =>
                                        (others => '0'));

begin

-- Implement delay line with NO reset so that it can be mapped onto
-- a Slice LUT.
process(clk_i) begin
    if rising_edge(clk_i) then
        taps_line <= taps_line(TAPS-2 downto 0) & data_i;
        -- Output register
        data_o <= taps_line(to_integer(unsigned(DELAY)));
    end if;
end process;


end rtl;

