library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity pandaSync_rx_TB is
end pandaSync_rx_TB;

architecture rtl of pandaSync_rx_TB is

constant c_k28_5            : std_logic_vector(7 downto 0) := x"BC";

-- clks in anti-phase
signal clk : std_logic := '0';
signal rxoutclk : std_logic := '0';

signal rxcharisk : std_logic_vector(3 downto 0);
signal rxdata    : std_logic_vector(31 downto 0);

signal POSIN1   : std_logic_vector(31 downto 0);
signal POSIN2   : std_logic_vector(31 downto 0);
signal POSIN3   : std_logic_vector(31 downto 0);
signal POSIN4   : std_logic_vector(31 downto 0);
signal BITIN    : std_logic_vector(7 downto 0);

signal POSOUT1   : std_logic_vector(31 downto 0);
signal POSOUT2   : std_logic_vector(31 downto 0);
signal POSOUT3   : std_logic_vector(31 downto 0);
signal POSOUT4   : std_logic_vector(31 downto 0);
signal BITOUT    : std_logic_vector(7 downto 0);

signal count : natural;
signal rst : std_logic;
signal stop : boolean := false;

begin

uut : entity work.sfp_panda_sync_receiver
    port map(
          sysclk_i          => clk,
          reset_i           => '0',
          rxoutclk_i        => rxoutclk,   
          rxdisperr_i       => (others => '0'),
          rxcharisk_i       => rxcharisk,
          rxdata_i          => rxdata,
          rxnotintable_i    => (others => '0'),
          rx_link_ok_o      => open,
          rx_error_o        => open,
          BITIN_o           => BITIN,   
          POSIN1_o          => POSIN1,
          POSIN2_o          => POSIN2,
          POSIN3_o          => POSIN3,
          POSIN4_o          => POSIN4
          );

clk_gen: process
begin
    while not stop loop
        clk <= not clk;
        --rxoutclk <= not rxoutclk after 1 ns;
        wait for 4 ns;
    end loop;
    wait;
end process;

rxclk_gen: process
begin
  while not stop loop
    rxoutclk <= not rxoutclk after 0 ns;
    wait for 4 ns;
  end loop;
  wait;
end process;

BITOUT <= std_logic_vector(to_unsigned(count,8));
POSOUT1 <= X"00000" & "00" & std_logic_vector(to_unsigned(count,10));
POSOUT2 <= X"00000" & "01" & std_logic_vector(to_unsigned(count,10));
POSOUT3 <= X"00000" & "10" & std_logic_vector(to_unsigned(count,10));
POSOUT4 <= X"00000" & "11" & std_logic_vector(to_unsigned(count,10));
 
stim : process
begin
    count <= 0;
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;
    wait until rising_edge(clk);
    rst <= '0';
    count <= 100;
    while count < 1024 loop
        rxdata <= BITOUT & POSOUT1(31 downto 16) & c_k28_5;
        rxcharisk <= x"1";
        wait until rising_edge(clk);
        count <= count + 1; 
        rxdata <= BITOUT & POSOUT1(15 downto 0) & POSOUT2(31 downto 24);
        rxcharisk <= x"0";
        wait until rising_edge(clk);
        count <= count + 1;
        rxdata <= BITOUT & POSOUT2(23 downto 0);
        wait until rising_edge(clk);
        count <= count + 1;
        rxdata <= BITOUT & POSOUT3(31 downto 8);
        wait until rising_edge(clk);
        count <= count + 1;
        rxdata <= BITOUT & POSOUT3(7 downto 0) & POSOUT4(31 downto 16);
        wait until rising_edge(clk);
        count <= count + 1;
        rxdata <= BITOUT & POSOUT4(15 downto 0) & x"00";
        wait until rising_edge(clk);
        count <= count + 1;
    end loop;
    stop <= true;
    wait;
end process;

end rtl;

