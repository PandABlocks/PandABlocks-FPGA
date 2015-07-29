LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.type_defines.all;
use work.addr_defines.all;
use work.test_interface.all;

use std.textio.all;

ENTITY panda_sequencer_tb IS
END panda_sequencer_tb;

ARCHITECTURE behavior OF panda_sequencer_tb IS

--Inputs
signal clk          : std_logic := '0';
signal reset        : std_logic := '1';
signal mem_cs       : std_logic := '0';
signal mem_wstb     : std_logic := '0';
signal mem_addr     : std_logic_vector(3 downto 0) := (others => '0');
signal mem_dat      : std_logic_vector(31 downto 0) := (others => '0');
signal position     : integer;
signal sysbus       : sysbus_t := (others => '0');
signal enable       : std_logic := '0';

--Outputs
signal pulse        : std_logic_vector(5 downto 0);
signal act          : std_logic;
signal length       : integer;

file table          : text open read_mode is "table.dat";

BEGIN

clk <= not clk after 4 ns;
reset <= '0' after 1 us;

uut: entity work.panda_sequencer
PORT MAP (
    clk_i           => clk,
    reset_i         => reset,
    sysbus_i        => sysbus,
    mem_cs_i        => mem_cs,
    mem_wstb_i      => mem_wstb,
    mem_addr_i      => mem_addr,
    mem_dat_i       => mem_dat,
    mem_dat_o       => open,
    pulse_o         => pulse,
    act_o           => act
);

-- Assign to first field of Position Bus
sysbus(0) <= not sysbus(0) after 1 us;
sysbus(1) <= not sysbus(1) after 2 us;
sysbus(2) <= not sysbus(2) after 4 us;
sysbus(3) <= not sysbus(2) after 8 us;
sysbus(5) <= enable;

-- Stimulus process
stim_proc: process
    variable inputline  : line;
    variable data       : integer;
begin
    length <= 0;
    PROC_CLK_EAT(1250, clk);

    -- Fill in Sequencer Table
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_MEM_START_ADDR, 1);

    while (not(endfile(table))) loop
        readline(table, inputline);
        read(inputline, data);
        BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_MEM_WSTB_ADDR, data);
        length <= length + 1;
    end loop;

    -- Write Configutation Registers
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_ENABLE_VAL_ADDR, 5);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_INP0_VAL_ADDR, 0);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_INP1_VAL_ADDR, 1);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_INP2_VAL_ADDR, 2);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_INP3_VAL_ADDR, 3);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_CLK_PRESC_ADDR, 10);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_TABLE_WORDS_ADDR, length/2);
    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, SEQ_TABLE_REPEAT_ADDR, 2);
    wait;
end process;

-- Stimulus process
process
begin
    enable <= '0';
    wait for 100 us;
    enable <= '1';
    wait;
end process;


end;
