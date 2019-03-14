LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

ENTITY panda_status_tb IS
END panda_status_tb;

ARCHITECTURE behavior OF panda_status_tb IS

signal clk_i            : std_logic := '0';
signal reset_i          : std_logic := '0';
signal mem_addr_i       : std_logic_vector(9 downto 0) := (others => '0');
signal mem_cs_i         : std_logic := '0';
signal mem_wstb_i       : std_logic := '0';
signal mem_rstb_i       : std_logic := '0';
signal mem_dat_i        : std_logic_vector(31 downto 0);
signal bit_bus_i        : std_logic_vector(127 downto 0);

signal mem_dat_o        : std_logic_vector(31 downto 0);

BEGIN

clk_i <= not clk_i after 4 ns;

uut: entity work.panda_status
PORT MAP (
    clk_i           => clk_i,
    reset_i         => reset_i,
    mem_addr_i      => mem_addr_i,
    mem_cs_i        => mem_cs_i,
    mem_wstb_i      => mem_wstb_i,
    mem_rstb_i      => mem_rstb_i,
    mem_dat_i       => mem_dat_i,
    mem_dat_o       => mem_dat_o,
    bit_bus_i       => bit_bus_i
);

proc: process
    variable counter    : unsigned(15 downto 0);
begin
    bit_bus_i <= (others => '0');
    counter := (others => '0');
    wait until rising_edge(clk_i);
    wait for 80 ns;

    L : loop
        bit_bus_i(15 downto 0) <= std_logic_vector(counter);
        counter := counter + 1;
        wait for 8 ns;
    end loop;

    wait;
end process;

-- Memory Stimulus process
stim_proc: process
begin
    mem_addr_i <= (others => '0');
    mem_dat_i <= (others => '0');

    wait until rising_edge(clk_i);
    wait for 800 ns;
    mem_cs_i <= '1'; mem_wstb_i <= '1'; mem_addr_i <= "00" & X"00";
    wait for 8 ns;
    mem_cs_i <= '0'; mem_wstb_i <= '0';

    wait for 1000 ns;

    for I in 0 to 15 loop
        wait for 800 ns;
        mem_cs_i <= '1'; mem_rstb_i <= '1'; mem_addr_i <= "00" & X"01";
        wait for 8 ns;
        mem_cs_i <= '0'; mem_rstb_i <= '0'; mem_addr_i <= "00" & X"00";
    end loop;

    wait;
end process;

END;
