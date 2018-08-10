library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;


entity filter_top_tb is

  generic (g_test_err_case     : integer := 0; -- Test divider being triggered twice
           g_test_div_not_dif  : integer := 2; -- Test both = 2, divider = 1, difference = 0 
           g_test_div_zero     : integer := 0; -- Test  1 = zero data, 0 = signed or unsigned data
           g_test_accum_data   : integer := 0  -- Test 0 = normal case, 1 = unsigned data overflow, 2 = signed data overflow 
                                               -- To run this test you need to change the code in the filter block by setting
                                               -- the accumulator to overflow either positive or negative       
          ); 
end filter_top_tb;


architecture rtl of filter_top_tb is

constant c_mode_difference : std_logic_vector(1 downto 0) := "00";
constant c_mode_divider    : std_logic_vector(1 downto 0) := "01"; 

type t_filter_state is (state_idle, state_en_div_accum, state_trig_div, state_trig_div_off, state_final_trig_div, 
                        state_wait_for_output, state_en_diff, state_tri_diff); 

signal filter_state   : t_filter_state;

signal clk_i          : std_logic := '0';
signal mode_i         : std_logic_vector(1 downto 0);
signal trig_i         : std_logic;
signal inp_i          : std_logic_vector(31 downto 0);
signal enable_i       : std_logic;
signal out_o          : std_logic_vector(31 downto 0);
signal ready_o        : std_logic;
signal health_o       : std_logic_vector(1 downto 0);  

signal enable_tb      : std_logic;
signal enable_tb_dly  : std_logic;
signal trig_tb        : std_logic;  
signal uns_data       : std_logic_vector(31 downto 0); 
signal s_data         : std_logic_vector(31 downto 0); 
signal num            : unsigned(31 downto 0); 
signal num_to_accum   : unsigned(31 downto 0);
signal accum_num_tb   : unsigned(31 downto 0);  

signal s_not_uns_data : std_logic := '0';
signal mode_tb        : std_logic_vector(1 downto 0); 
signal accum_tb       : signed(63 downto 0);  
signal quot_tb        : signed(63 downto 0); 
signal mode_select    : std_logic_vector(1 downto 0);

signal divisor_tb     : unsigned(31 downto 0);
signal divider_tb     : signed(63 downto 0); 
signal diff_cnt       : unsigned(31 downto 0);
signal latch_tb       : signed(31 downto 0);
signal diff_tb        : signed(31 downto 0); 
 
signal divider_error    : std_logic;
signal difference_error : std_logic;

signal a              : std_logic_vector(15 downto 0) := "1010110011100001";
signal b,c,d          : std_logic := '0'; 

begin

-- Random signed and unsigned data generator
ps_rand :process
  variable seed1    : positive;
  variable seed2    : positive;
  variable rand     : real;
  variable int_rand : integer;
begin
  uniform(seed1, seed2, rand);
  int_rand := integer(trunc(rand*4294967295.0));
  -- Unsigned data 
  uns_data <= std_logic_vector(to_unsigned(int_rand,uns_data'length));  ------------------ HERE CODE COMMENTED OUT
  -- Signed data
  s_data <= std_logic_vector((not(signed(uns_data)))+1);
  wait for 4 ns;
end process ps_rand; 


-- Doing this was the only way to test the accumulator overflow 
--uns_data <= x"7fffffff";
--s_data <= x"80000001";


-- Random number of samples generator
ps_rand_num: process
    variable seed1    : positive; 
    variable seed2    : positive;               
    variable rand     : real;     
    variable int_rand : integer;
begin
    uniform(seed1, seed2, rand);   
    int_rand := integer(trunc(rand*61251.0));
    -- Number of samples
    num <= to_unsigned(int_rand,num'length);
    wait for 4 ns;
end process ps_rand_num;


ps_bit_gen: process(clk_i)
begin
  if rising_edge(clk_i)then
    b <= a(13) xor a(15); 
    c <= a(12) xor b;
    d <= a(10) xor c;
    a <= a(14 downto 0) & d;
  end if;
end process ps_bit_gen;  
  

clk_i <= not clk_i after 4ns; 


mode_select <= c_mode_divider when g_test_div_not_dif = 2 and a(0) = '1' else
               c_mode_difference when g_test_div_not_dif = 2 and a(0) = '0' else
               c_mode_divider when g_test_div_not_dif = 1 else
               c_mode_difference when g_test_div_not_dif = 0;


ps_div_cntrl: process(clk_i)
begin
  if rising_edge(clk_i)then
    case filter_state is 
      
      -- Idle state reset very thing
      when state_idle =>
        trig_i <= '0';
        trig_tb <= '0';
        enable_i <= '0';
        enable_tb <= '0';
        num_to_accum <= num;                                            
        diff_cnt <= (others => '0');
        -- Capture the mode select here as could change on the next clock pulse  
        if mode_select = c_mode_divider then
          mode_i <= c_mode_divider;
          mode_tb <= c_mode_divider;
          filter_state <= state_en_div_accum;
        -- Capture the mode select here as could change on the next clock pulse  
        elsif mode_select = c_mode_difference then
          mode_i <= c_mode_difference;
          mode_tb <= c_mode_difference;
          filter_state <= state_en_diff; 
        end if;
      
      -- Enable the divider and testbench divider        
      when state_en_div_accum =>
        trig_i <= '0';
        trig_tb <= '0';
        enable_i <= '1';
        enable_tb <= '1';
        -- Final trigger
        -- Intermediate triggers
        if accum_num_tb(3 downto 0) = "1111" then ---------------- HERE  
          filter_state <= state_trig_div;
        elsif accum_num_tb = num_to_accum then
          filter_state <= state_final_trig_div;
        -- ERROR case 1. accumulator overlfow 2. divider triggered twice  
        elsif health_o(0) = '1' or health_o(1) = '1' then
          filter_state <= state_idle;           
        end if;   
      
      -- Intermediate triggers
      when state_trig_div =>
        if accum_num_tb >= (num_to_accum+4) then
          filter_state <= state_final_trig_div;
        else          
          trig_i <= '1';
          trig_tb <= '1';
          filter_state <= state_trig_div_off;
        end if;  
      
      -- Turn off the intermediate triggers
      when state_trig_div_off =>
        trig_i <= '0';
        trig_tb <= '0';
        if ready_o = '1' then
          filter_state <= state_en_div_accum;
        end if;  
          
      -- Final trigger the divider           
      when state_final_trig_div =>
        enable_i <= '0';
        enable_tb <= '0';
        trig_i <= '1';
        trig_tb <= '1';
        filter_state <= state_wait_for_output;
      
      -- Trigger finished    
      when state_wait_for_output => 
        trig_i <= '0';
        trig_tb <= '0';
        if g_test_err_case = 1 then
          filter_state <= state_idle;
        elsif ready_o = '1' then
          filter_state <= state_idle;
        end if;    
      
      -- Difference mode enabled 
      when state_en_diff =>
        trig_i <= '0';
        trig_tb <= '0';
        diff_cnt <= diff_cnt +1; 
        if diff_cnt(3 downto 0) = "1111" then ---------------- HERE   
          filter_state <= state_tri_diff;
        elsif num_to_accum = diff_cnt then
          filter_state <= state_idle;
        end if;
      
      -- Difference mode trigger enabled        
      when state_tri_diff =>
        trig_i <= '1';
        trig_tb <= '1';  
        filter_state <= state_en_diff;
          
      when others =>
        filter_state <= state_idle; 
      
    end case;
  end if;
end process ps_div_cntrl;


ps_accum: process(clk_i)
begin  
  if rising_edge(clk_i)then
    
    -- Unsigned data selection
    if g_test_accum_data = 1 then
      s_not_uns_data <= '0';
    -- Signed data selection  
    elsif g_test_accum_data = 2 then    
      s_not_uns_data <= '1';
    -- Signed and Unsigned data 
    else
      s_not_uns_data <= not s_not_uns_data;
    end if;
    
    enable_tb_dly <= enable_tb;
    
    -- Divider 
    if mode_tb = c_mode_divider then
      if enable_tb_dly = '0' and enable_tb = '1' then
        accum_num_tb <= (others => '0');
        accum_tb <= (others => '0');
      elsif enable_tb_dly = '1' then
        accum_num_tb <= accum_num_tb +1;
        if s_not_uns_data = '0' then
          accum_tb <= accum_tb + signed(uns_data);   
        else
          accum_tb <= accum_tb + signed(s_data);
        end if;
      end if;
      if trig_tb = '1' then
        -- Push zero data into the divider to see if it handles the result being zero
        if g_test_div_zero = 1 then
          divider_tb <= (others => '0');  
        else
          divider_tb <= accum_tb; 
        end if;
        divisor_tb <= accum_num_tb;
      end if;
      
    -- Difference  
    elsif mode_tb = c_mode_difference then
      if enable_tb_dly = '0' and enable_tb = '1' then
        if s_not_uns_data = '0' then
          latch_tb <= signed(uns_data);
        else
          latch_tb <= signed(s_data);
        end if;     
      end if;
      if trig_tb = '1' then
        if s_not_uns_data = '0' then
          latch_tb <= signed(uns_data);
          diff_tb <= signed(uns_data) - latch_tb;
        else
          latch_tb <= signed(s_data);
          diff_tb <= signed(s_data) - latch_tb; 
        end if;    
      end if;      
    end if;    
    quot_tb <= divider_tb / signed(divisor_tb); 
  end if;
end process ps_accum;
    

-- Put zero data into the divider to see if it handles the result being zero
gen_zero_data : if g_test_div_zero = 1 generate
  inp_i <= (others => '0');  
end generate gen_zero_data;

-- Normal data Signed not Unsigned data
gen_data: if g_test_div_zero = 0 generate
  inp_i <= uns_data when s_not_uns_data = '0' else s_data;
end generate gen_data;  
          

-- Output checker
ps_check_output: process(clk_i)
begin
  if rising_edge(clk_i)then
    -- Divider result checker
    if ready_o = '1' and mode_tb = c_mode_divider then
      if signed(out_o) /= quot_tb(31 downto 0) then
        report "Expected result is " & integer'image(to_integer(quot_tb(31 downto 0))) & " and the Result is " 
                                     & integer'image(to_integer(signed(out_o))) severity error;   
        divider_error <= '1';
      else
        divider_error <= '0';  
      end if;
    -- Difference result checker  
    elsif ready_o = '1' and mode_tb = c_mode_difference then
      if signed(out_o) /= diff_tb then
        report "Expected result is " & integer'image(to_integer(diff_tb)) & " and the Result is " 
                                     & integer'image(to_integer(signed(out_o))) severity error;
        difference_error <= '1';
      else
        difference_error <= '0';  
      end if;
    end if;
    if health_o(0) = '1' then
      report " ERROR accumulator overflow has occured " severity note; 
    end if;
    if health_o(1) = '1' then
      report " ERROR divider has been enabled and has not finished its current operation " severity note;   
    end if;
  end if;
end process ps_check_output;
  

inst_filter: entity work.filter

  port map(clk_i     => clk_i,
           mode_i    => mode_i,
           trig_i    => trig_i,
           inp_i     => inp_i,
           enable_i  => enable_i,
           out_o     => out_o,
           ready_o   => ready_o,
           health_o  => health_o);
 
 
end rtl; 

