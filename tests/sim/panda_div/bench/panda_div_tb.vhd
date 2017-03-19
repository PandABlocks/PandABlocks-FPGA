LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY panda_div_tb IS
END panda_div_tb;

ARCHITECTURE behavior OF panda_div_tb IS 

signal clk_i : std_logic := '1';
signal inp_i : std_logic := '0';
signal rst_i : std_logic := '1';
signal FIRST_PULSE : std_logic := '0';
signal DIVISOR : std_logic_vector(31 downto 0) := (others => '0');
signal FORCE_RST : std_logic := '0';

signal outd_o : std_logic;
signal outn_o : std_logic;
signal COUNT : std_logic_vector(31 downto 0);


BEGIN

clk_i <= not clk_i after 4 ns;

uut: entity work.panda_div
PORT MAP (
    clk_i       => clk_i,
    inp_i       => inp_i,
    rst_i       => rst_i,
    outd_o      => outd_o,
    outn_o      => outn_o,
    FIRST_PULSE => FIRST_PULSE,
    DIVISOR     => DIVISOR,
    FORCE_RST   => FORCE_RST,
    COUNT       => COUNT
);


-- Stimulus process
stim_proc: process
begin
    FIRST_PULSE <= '1';
    FORCE_RST <= '0';
    DIVISOR <= X"00000004";
    inp_i <= '0';
    rst_i <= '1';
    -- hold reset state
    wait for 40 ns;
    rst_i <= '0';
    wait for 400 ns;

    L1: loop
        inp_i <= '1';
        wait for 40 ns;
        inp_i <= '0';
        wait for 400 ns;
    end loop;

    wait;
end process;

end;
