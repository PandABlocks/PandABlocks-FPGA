--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Position Bus multiplexer with delay line.
--                DLY = 0 corresponds to 1 clock cycle delay providing a
--                registered output
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;

entity posmux is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    pos_bus_i           : in  pos_bus_t;
    posn_o              : out std_logic_vector(31 downto 0);
    -- Block Parameters
    POSMUX_SEL_i        : in  std_logic_vector(31 downto 0)
);

  attribute keep_hierarchy            : string;
  attribute keep_hierarchy of posmux  : entity is "yes";

end posmux;

architecture rtl of posmux is

begin

-- process(POSMUX_SEL_i,pos_bus_i)
process (clk_i) begin
if rising_edge(clk_i) then
    if POSMUX_SEL_i(PBUSBW) = '0' then
        -- Select position field from the position array
        posn_o <= PFIELD(pos_bus_i, POSMUX_SEL_i(PBUSBW-1 downto 0));
    else
        posn_o <= (others => '0');
    end if;
end if;
end process;

end rtl;
