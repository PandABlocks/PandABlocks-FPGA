LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY panda_pulse_tb IS
END panda_pulse_tb;

ARCHITECTURE behavior OF panda_pulse_tb IS

signal clk_i        : std_logic := '1';
signal inp_i        : std_logic := '0';
signal rst_i        : std_logic := '1';
signal out_o        : std_logic;
signal perr_o       : std_logic;

signal DELAY        : std_logic_vector(47 downto 0):= X"0000_0000_0004";
signal WIDTH        : std_logic_vector(47 downto 0):= X"0000_0000_000A";
signal STATE        : std_logic_vector(31 downto 0);
signal MISSED_CNT   : std_logic_vector(31 downto 0);
signal FORCE_RST    : std_logic := '0';

BEGIN

clk_i <= not clk_i after 4 ns;

uut: entity work.panda_pulse
PORT MAP (
    clk_i       => clk_i,
    inp_i       => inp_i,
    rst_i       => rst_i,
    out_o       => out_o,
    perr_o      => perr_o,
    DELAY       => DELAY,
    WIDTH       => WIDTH,
    STATE       => STATE,
    MISSED_CNT  => MISSED_CNT,
    FORCE_RST   => FORCE_RST
);

-- Stimulus process
stim_proc: process
begin
    inp_i <= '0';
    rst_i <= '1';

    -- hold reset state
    wait for 40 ns;
    rst_i <= '0';
    wait for 4000 ns;

    L1: loop
        inp_i <= '1';
        wait for 100 ns;
        inp_i <= '0';
        wait for 900 ns;
    end loop;

    wait;
end process;

measure_proc: process
    variable rise_time  : time;
    variable difference : time;
begin
    L2: loop
        wait until rising_edge(inp_i);
        rise_time := now;
        wait until rising_edge(out_o);
        difference := now - rise_time;
        report "A-to-B time = " & time'image(difference);
    end loop;
end process;

end;
