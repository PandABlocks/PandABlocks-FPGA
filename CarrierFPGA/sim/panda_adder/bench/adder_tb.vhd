LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

ENTITY adder_tb IS
END adder_tb;

ARCHITECTURE behavior OF adder_tb IS

--Inputs
signal clk_i        : std_logic := '0';
signal reset_i      : std_logic := '1';
signal inpa_i       : std_logic_vector(31 downto 0) := (others => '0');
signal inpb_i       : std_logic_vector(31 downto 0) := (others => '0');
signal inpc_i       : std_logic_vector(31 downto 0) := (others => '0');
signal inpd_i       : std_logic_vector(31 downto 0) := (others => '0');
signal INPA_INVERT  : std_logic := '0';
signal INPB_INVERT  : std_logic := '0';
signal INPC_INVERT  : std_logic := '0';
signal INPD_INVERT  : std_logic := '0';
signal SCALE        : std_logic_vector(1 downto 0) := (others => '0');

signal a,b,c,d      : integer;

--Outputs
signal out_o : std_logic_vector(31 downto 0);

BEGIN

clk_i <= not clk_i after 4 ns;
reset_i <= '0' after 100 us;

inpa_i <= std_logic_vector(to_signed(a,32));
inpb_i <= std_logic_vector(to_signed(b,32));
inpc_i <= std_logic_vector(to_signed(c,32));
inpd_i <= std_logic_vector(to_signed(d,32));

uut: entity work.adder
PORT MAP (
    clk_i           => clk_i,
    reset_i         => reset_i,
    inpa_i          => inpa_i,
    inpb_i          => inpb_i,
    inpc_i          => inpc_i,
    inpd_i          => inpd_i,
    out_o           => out_o,
    INPA_INVERT     => INPA_INVERT,
    INPB_INVERT     => INPB_INVERT,
    INPC_INVERT     => INPC_INVERT,
    INPD_INVERT     => INPD_INVERT,
    SCALE           => SCALE
);

-- Stimulus process
stim_proc: process
begin
    SCALE <= "00";
    a <= 0; b <= 0; c <= 0; d <= 0;
    -- hold reset state for 100 ns.
    wait for 1000 ns;
    a <= 100; b <= 100; c <= 100; d <= 0;
    wait for 1000 ns;
    a <= 100; b <= 100; c <= 100; d <= -300;
    wait for 1000 ns;
    a <= -1000; b <= 100; c <= 100; d <= -300;
    wait for 1000 ns;
    SCALE <= "01";
    wait for 1000 ns;
    SCALE <= "10";
    wait for 1000 ns;
    SCALE <= "11";
    wait for 1000 ns;
    a <= 1000; b <= 200; c <= 0; d <= 0;
    INPB_INVERT <= '1';
    wait for 10000 ns;
    SCALE <= "01";
    wait for 1000 ns;
    SCALE <= "10";
    wait for 1000 ns;
    SCALE <= "11";
    wait;
end process;

END;
