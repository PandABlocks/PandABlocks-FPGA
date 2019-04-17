--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : System Bus multiplexer with delay line.
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

entity bitmux is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    bit_bus_i           : in  bit_bus_t;
    bit_o               : out std_logic;
    -- Block Parameters
    BITMUX_SEL_i        : in  std_logic_vector(31 downto 0);
    BIT_DLY_i           : in  std_logic_vector(31 downto 0)
);

  attribute keep_hierarchy            : string;
  attribute keep_hierarchy of bitmux  : entity is "yes";

end bitmux;

architecture rtl of bitmux is

signal bit_in           : std_logic_vector(0 downto 0);
signal bit_out          : std_logic_vector(0 downto 0);

begin

process(BITMUX_SEL_i,bit_bus_i)
begin
    if BITMUX_SEL_i(BBUSBW) = '0' then
        -- Select bit on the system bus
        bit_in(0) <= SBIT(bit_bus_i, BITMUX_SEL_i(BBUSBW-1 downto 0));
    else
        bit_in(0) <= BITMUX_SEL_i(0);
    end if;
end process;

-- Feed selected bit through the delay line
delay_line_inst : entity work.delay_line
generic map (
    DW          => 1
)
port map (
    clk_i       => clk_i,
    data_i      => bit_in,
    data_o      => bit_out,
    DELAY_i     => BIT_DLY_i(4 downto 0)
);

bit_o <= bit_out(0);

end rtl;


