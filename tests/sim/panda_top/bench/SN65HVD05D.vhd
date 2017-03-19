LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

library unisim;
use unisim.vcomponents.all;

entity SN65HVD05D is
port (
    A       : inout  std_logic;

    R       : inout  std_logic;
    D       : inout  std_logic;
    DE      : in     std_logic;
    REn     : in     std_logic
);
end SN65HVD05D;

architecture behavior of SN65HVD05D is

signal Ai, Ao   : std_logic;
signal DEn      : std_logic;

begin

DEn <= not DE;

IOBUF_A : IOBUF
port map (
    I   => Ai,
    O   => Ao,
    T   => DEn,
    IO  => A
);

IOBUF_R : IOBUF
port map (
    I   => Ao,
    O   => open,
    T   => REn,
    IO  => R
);

IOBUF_D : IOBUF
port map (
    I   => '0',
    O   => Ai,
    T   => '1',
    IO  => D
);

end;
