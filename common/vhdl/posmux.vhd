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
    posbus_i            : in  posbus_t;
    posn_o              : out std_logic_vector(31 downto 0);
    -- Block Parameters
    POSMUX_SEL          : in  std_logic_vector(31 downto 0);
    POS_DLY             : in  std_logic_vector(31 downto 0)
);

  attribute keep_hierarchy            : string;
  attribute keep_hierarchy of posmux  : entity is "yes";

end posmux;

architecture rtl of posmux is

signal posn             : std_logic_vector(31 downto 0);

begin

process(POSMUX_SEL)
begin
    if POSMUX_SEL(PBUSBW) = '0' then
        -- Select position field from the position array
        posn <= PFIELD(posbus_i, POSMUX_SEL(PBUSBW-1 downto 0));
    else
        posn <= (others => '0');
    end if;
end process;
    

-- Feed selected fiedd through the delay line
delay_line_inst : entity work.delay_line
port map (
    clk_i       => clk_i,
    data_i      => posn,
    data_o      => posn_o,
    DELAY       => POS_DLY(4 downto 0)
);

end rtl;
