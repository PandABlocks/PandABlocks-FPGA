LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

library work;
use work.test_interface.all;

use std.textio.all;

entity incr_encoder_model is
port (
    CLK         : in  std_logic;
    A_OUT       : out std_logic;
    B_OUT       : out std_logic
);
end incr_encoder_model;

architecture behavior of incr_encoder_model is

procedure Turn (
    N                   : integer;
    signal clk          : in  std_logic;
    signal A            : out std_logic;
    signal B            : out std_logic
) is
    type Phase_t is array (0 to 3) of std_logic_vector(0 to 1);
    constant Phase_Table    : Phase_t := ("00", "10", "11", "01");
    variable Phase          : integer := 0;
    variable J              : integer := N;
begin
    while J /= 0 loop
        if J < 0 then
            J := J+1;
            Phase := Phase - 1;
        else
            J := J-1;
            Phase := Phase + 1;
        end if;
        (A,B) <= Phase_Table(Phase mod 4);
        PROC_CLK_EAT(125, clk);
    end loop;
end procedure Turn;

signal posn         : integer;

file sine           : text open read_mode is "sine.dat";

begin

process
    variable inputline  : line;
    variable data       : integer;

begin
    posn <= 0;
    -- Wait for 10us for things to settle
    PROC_CLK_EAT(1250, CLK);

    while (not(endfile(sine))) loop
        readline(sine, inputline);
        read(inputline, data);
        Turn(data-posn, CLK, A_OUT, B_OUT);
        posn <= data;
    end loop;

    wait;

end process;

end;
