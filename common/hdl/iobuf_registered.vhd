--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : An IOBUF macro with registered I and O with IOB packing
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity iobuf_registered is
port (
    clock   : in    std_logic;
    I       : in    std_logic;
    O       : out   std_logic;
    T       : in    std_logic;
    IO      : inout std_logic
);
end iobuf_registered;

architecture rtl of iobuf_registered is

signal ipad     : std_logic;
signal opad     : std_logic;

begin

--------------------------------------------------------------------------
-- Register and pack into IOBs
--------------------------------------------------------------------------
process(clock) begin
    if rising_edge(clock) then
        O <= opad;
        ipad <= I;
    end if;
end process;

-- Physical IOBUF instantiations controlled with PROTOCOL
IOBUF_inst : IOBUF
port map (
    I   => ipad,
    O   => opad,
    T   => T,
    IO  => IO
);

end rtl;

