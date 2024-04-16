library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity pandaSync_tx_TB is
end pandaSync_tx_TB;

architecture rtl of pandaSync_tx_TB is

-- clks in anti-phase
signal clk : std_logic := '0';
signal txoutclk : std_logic := '0';

signal txcharisk : std_logic_vector(3 downto 0);
signal txdata    : std_logic_vector(31 downto 0);

signal POSOUT1   : std_logic_vector(31 downto 0);
signal POSOUT2   : std_logic_vector(31 downto 0);
signal POSOUT3   : std_logic_vector(31 downto 0);
signal POSOUT4   : std_logic_vector(31 downto 0);
signal BITOUT    : std_logic_vector(7 downto 0);

signal count : natural;
signal rst : std_logic;
signal stop : boolean := false;

begin

uut : entity work.sfp_panda_sync_transmit

    port map (
        sysclk_i          => clk,
        txoutclk_i        => txoutclk,
        txcharisk_o       => txcharisk,
        txdata_o          => txdata,
        POSOUT1_i         => POSOUT1,
        POSOUT2_i         => POSOUT2,
        POSOUT3_i         => POSOUT3,
        POSOUT4_i         => POSOUT4,
        BITOUT_i          => BITOUT
        );

clk_gen: process
begin
    while not stop loop
        clk <= not clk;
        --txoutclk <= not txoutclk after 1 ns;
        wait for 4 ns;
    end loop;
    wait;
end process;

txclk_gen: process
begin
  while not stop loop
    txoutclk <= not txoutclk after 1 ns;
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
        --wait for 8 ns;
        wait until rising_edge(clk);
        if count = 200 then   
          --<<signal .uut.wren_low : std_logic>> <= force '1';  -- if only this were supported for simulation
        elsif count = 400 then
          --<<signal .uut.wren_low : std_logic>> <= release;
        end if;
        count <= count + 1;    
    end loop;
    stop <= true;
    wait;
end process;

/*
fifo_rst : process
begin
  rst <= '1';
  for i in 0 to 5 loop
    wait until rising_edge(clk);
  end loop;
  rst <= '0';
  wait;
end process;
*/

end rtl;

