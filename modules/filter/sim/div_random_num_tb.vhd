library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity div_random_num_tb is
end div_random_num_tb;

architecture rtl of div_random_num_tb is 

type t_div_state is (state_idle, state_run, state_load_data, state_enable_div, state_div_run);   

constant c_divider_size : integer := 64;
constant c_divisor_size : integer := 32;

signal div_state       : t_div_state; 

signal clk_i           : std_logic := '0';  
signal enable_i        : std_logic; 
signal divisor_i       : std_logic_vector(31 downto 0); 
signal divider_i       : std_logic_vector(63 downto 0);
signal quot_rdy_o      : std_logic;
signal quot_o          : std_logic_vector(31 downto 0);

signal quot            : unsigned(63 downto 0);  
signal divider_tb      : unsigned(63 downto 0);
signal divisor_tb      : unsigned(31 downto 0);  

signal stim            : unsigned(31 downto 0); 
signal num             : unsigned(31 downto 0); 

signal enable_accum    : std_logic;
signal load_accum_data : std_logic;
signal accum_data      : signed(63 downto 0) := (others => '0');
signal accum_num       : unsigned(31 downto 0);  
signal num_to_accum    : unsigned(31 downto 0); 


begin

clk_i <= not clk_i after 4ns;


process
    variable seed1    : positive; 
    variable seed2    : positive;               
    variable rand     : real;     
    variable int_rand : integer;
begin
    uniform(seed1, seed2, rand);   
    int_rand := integer(trunc(rand*61251.0));
    num <= to_unsigned(int_rand,num'length);
    wait for 4 ns;
end process;


ps_rand :process
  variable seed1    : positive;
  variable seed2    : positive;
  variable rand     : real;
  variable int_rand : integer;
begin
  uniform(seed1, seed2, rand);
  int_rand := integer(trunc(rand*4294967295.0));
  stim <= to_unsigned(int_rand,stim'length);
  wait for 4 ns;
end process ps_rand;    


ps_enable_div: process(clk_i)
begin
  if rising_edge(clk_i) then
  
    case div_state is
      when state_idle =>
        enable_accum <= '0';
        load_accum_data <= '0';
        num_to_accum <= num;
        div_state <= state_run;
      
      when state_run =>
        enable_accum <= '1';
        if num_to_accum = accum_num then
          div_state <= state_load_data;
        end if;
        
      when state_load_data => 
        enable_accum <= '0';
        load_accum_data <= '1';
        div_state <= state_enable_div;
     
      when state_enable_div =>
        load_accum_data <= '0';
        enable_i <= '1';
        div_state <= state_div_run;    
        
      when state_div_run => 
        enable_i <= '0';
        if quot_rdy_o = '1' then
          div_state <= state_idle;
        end if;
     
      when others =>
        div_state <= state_idle;                
    end case;         
    
  end if;
end process ps_enable_div;
      
     

ps_accum: process(clk_i)
begin
  if rising_edge(clk_i) then
    if enable_accum = '1' then
      accum_num <= accum_num +1;
      accum_data <= accum_data + signed(stim); 
    else
      accum_num <= (others => '0');
      accum_data <= (others => '0'); 
    end if;
    if load_accum_data = '1' then
      enable_i <= '1';
      divider_tb <= unsigned(accum_data);
      divisor_tb <= unsigned(accum_num);
      divider_i <= std_logic_vector(accum_data);
      divisor_i <= std_logic_vector(accum_num);
    else
      enable_i <= '0';
    end if;
  end if;
end process ps_accum;  


quot <= divider_tb / divisor_tb; 


ps_check: process(clk_i)
begin
  if rising_edge(clk_i)then
    if quot_rdy_o = '1' then
      if x"00000000" & quot_o /= std_logic_vector(quot) then
        report "Received data is " & integer'image(to_integer(signed(quot_o))) & " Expect data is " & integer'image(to_integer(quot)) 
        severity error;   
      end if;
    end if;    
  end if;
end process ps_check;  



inst_divider : entity work.divider

  generic map(
    g_divider_size  => c_divider_size, -- integer := 64;
    g_divisor_size  => c_divisor_size  -- integer := 32);
           )
  port map(
    clk_i      => clk_i,
    enable_i   => enable_i, 
    divisor_i  => divisor_i,
    divider_i  => divider_i, 
    quot_rdy_o => quot_rdy_o,
    quot_o     => quot_o);


end rtl;


