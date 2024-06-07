library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity iobuf_tb is
end entity;

architecture rtl of iobuf_tb is


signal clock    : std_logic := '0';
signal I        : std_logic;
signal O        : std_logic;
signal T        : std_logic;
signal IO       : std_logic;


begin

clock <= not clock after 8 ns;

--I <= '0';
T <= '0'; 

process 
begin
    I <= '0';
--    IO <= '1';
    wait for 100 ns; 
    I <= '1';
--    IO <= '0';
    wait for 100 ns;
    I <= '0';
--    IO <= '1';
    wait for 100 ns;
    I <= '1';
--    IO <= '0';
    wait for 100 ns;
    I <= '0';
--    IO <= '1';
    wait;
end process;    

-- Physical IOBUF instantiations controlled with PROTOCOL
iobuf_inst: entity work.iobuf_registered 
    port map (
        clock   => clock,
        I       => I,
        O       => O,
        T       => T,
        IO      => IO
       );


end rtl;
