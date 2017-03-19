LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

library unisim;
use unisim.vcomponents.all;

entity SN75LBC174A is
port (
    Y1     : out std_logic;
    Y2     : out std_logic;
    Y3     : out std_logic;
    Y4     : out std_logic;

    A1     : inout std_logic;
    A2     : inout std_logic;
    A3     : inout std_logic;
    A4     : inout std_logic;

    EN12    : in  std_logic;
    EN34    : in  std_logic
);
end SN75LBC174A;

architecture behavior of SN75LBC174A is

begin

Y1<= A1;
Y2<= A2;
Y3<= A3;
Y4<= A4;

A1 <= 'Z';
A2 <= 'Z';
A3 <= 'Z';
A4 <= 'Z';

end;
