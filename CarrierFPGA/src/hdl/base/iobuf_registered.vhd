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

component FDRE is
port (
    Q   : out std_logic;
    C   : in  std_logic;
    CE  : in  std_logic;
    R   : in  std_logic;
    D   : in  std_logic
);
end component;

-- Pack registers into IOB
attribute iob               : string;
attribute iob of FDRE       : component is "TRUE";

signal ipad     : std_logic;
signal opad     : std_logic;

begin

ofd_inst : FDRE
port map (
    Q   => O,
    C   => clock,
    CE  => '1',
    R   => '0',
    D   => opad
);

ifd_inst : FDRE
port map (
    Q   => ipad,
    C   => clock,
    CE  => '1',
    R   => '0',
    D   => I
);

-- Physical IOBUF instantiations controlled with PROTOCOL
IOBUF_inst : IOBUF
port map (
    I   => ipad,
    O   => opad,
    T   => T,
    IO  => IO
);

end rtl;

