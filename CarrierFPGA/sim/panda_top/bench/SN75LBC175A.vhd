LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity SN75LBC175A is
port (
    Y1      : inout std_logic;
    Y2      : inout std_logic;
    Y3      : inout std_logic;
    Y4      : inout std_logic;

    A1      : in    std_logic;
    A2      : in    std_logic;
    A3      : in    std_logic;
    A4      : in    std_logic;

    EN12    : in    std_logic;
    EN34    : in    std_logic
);
end SN75LBC175A;

architecture behavior of SN75LBC175A is

begin

Y1 <= A1 when (EN12 = '1') else 'Z';
Y2 <= A2 when (EN12 = '1') else 'Z';

Y3 <= A3 when (EN34 = '1') else 'Z';
Y4 <= A4 when (EN34 = '1') else 'Z';

end;
