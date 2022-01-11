library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_baud_gen is
  
  generic (
    g_baud_acc_width : integer := 16);

  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    baudrate_i : in std_logic_vector(g_baud_acc_width  downto 0);

    baud_tick_o  : out std_logic;
    baud8_tick_o : out std_logic);

end uart_baud_gen;

architecture behavioral of uart_baud_gen is

  signal Baud8GeneratorInc : unsigned(g_baud_acc_width downto 0);
  signal Baud8GeneratorAcc : unsigned(g_baud_acc_width downto 0);
  signal Baud8Tick         : std_logic;
  signal Baud_sreg         : std_logic_vector(7 downto 0) := "10000000";
  
  
begin  -- behavioral

  Baud8GeneratorInc <= unsigned(baudrate_i);

  process(clk_sys_i, rst_n_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        Baud8GeneratorAcc <= (others => '0');
      else
        Baud8GeneratorAcc <= ('0' & Baud8GeneratorAcc(Baud8GeneratorAcc'high-1 downto 0)) + Baud8GeneratorInc;
      end if;
    end if;
  end process;

  Baud8Tick <= std_logic(Baud8GeneratorAcc(g_baud_acc_width));

  process(clk_sys_i, rst_n_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        Baud_sreg <= "10000000";
      elsif Baud8Tick = '1' then
        Baud_sreg <= Baud_sreg(0) & Baud_sreg(7 downto 1);
      end if;
    end if;
  end process;

  baud_tick_o  <= Baud_sreg(0) and Baud8Tick;
  baud8_tick_o <= Baud8Tick;

end behavioral;
