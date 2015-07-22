LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.type_defines.all;
use work.addr_defines.all;
use work.test_interface.all;

use std.textio.all;

ENTITY panda_pcomp_tb IS
END panda_pcomp_tb;

ARCHITECTURE behavior OF panda_pcomp_tb IS 

--Inputs
signal clk          : std_logic := '0';
signal reset        : std_logic := '1';
signal mem_cs       : std_logic := '0';
signal mem_wstb     : std_logic := '0';
signal mem_addr     : std_logic_vector(3 downto 0) := (others => '0');
signal mem_dat      : std_logic_vector(31 downto 0) := (others => '0');
signal position     : integer;
signal sysbus       : sysbus_t := (others => '0');
signal posbus       : posbus_t := (others => (others => '0'));
signal enable       : std_logic := '0';

--Outputs
signal pulse        : std_logic;

file saw                : text open read_mode is "saw.dat";

constant RELATIVE       : integer := 1;
constant DIRECTION      : integer := 0;

BEGIN

clk <= not clk after 4 ns;
reset <= '0' after 1 us;

uut: entity work.panda_pcomp
PORT MAP (
    clk_i           => clk,
    reset_i         => reset,
    sysbus_i        => sysbus,
    posbus_i        => posbus,
    mem_cs_i        => mem_cs,
    mem_wstb_i      => mem_wstb,
    mem_addr_i      => mem_addr,
    mem_dat_i       => mem_dat,
    mem_dat_o       => open,
    pulse_o         => pulse
);

-- Assign to first field of Position Bus
posbus(0) <= TO_STD_VECTOR(position, 32);
sysbus(0) <= enable;

-- Stimulus process
stim_proc: process
begin
    PROC_CLK_EAT(1250, clk);

    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_ENABLE_VAL_ADDR, 0);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_POSN_VAL_ADDR, 0);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_START_ADDR, -500);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_STEP_ADDR,  100);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_WIDTH_ADDR, 10);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_COUNT_ADDR, 10);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_RELATIVE_ADDR, RELATIVE);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_DIR_ADDR, DIRECTION);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_FLTR_DELTAT_ADDR, 1250);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCOMP_FLTR_THOLD_ADDR, 3);
    wait;
end process;


process
    variable inputline  : line;
    variable data       : integer;
begin
    position <= 0;
    -- Wait for 10us for things to settle
    PROC_CLK_EAT(1250, CLK);

    while (not(endfile(saw))) loop
        readline(saw, inputline);
        read(inputline, data);
        position <= data;
        PROC_CLK_EAT(125, clk);
    end loop;

    wait;
end process;

-- Assert enable flag
process
begin
    wait for 5 ms;
    enable <= '1';
end process;

end;
