library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity filter is
  port (clk_i    : in  std_logic;
        mode_i   : in  std_logic_vector(1 downto 0);
        trig_i   : in  std_logic;
        inp_i    : in  std_logic_vector(31 downto 0);
        enable_i : in  std_logic;
        out_o    : out std_logic_vector(31 downto 0);
        ready_o  : out std_logic;
        err_o    : out std_logic);
 
end filter;


architecture rtl of filter is

-- Not sure what library this is compiled into 
-- would like to remove this once I know 
component divider is

  port (clk_i      : in  std_logic;
        enable_i   : in  std_logic;
        divisor_i  : in  std_logic_vector(31 downto 0);
        divider_i  : in  std_logic_vector(63 downto 0); 
        quot_rdy_o : out std_logic;
        quot_o     : out std_logic_vector(31 downto 0));

end component; 


constant difference : std_logic_vector(1 downto 0) := "00";
constant average    : std_logic_vector(1 downto 0) := "01";   

signal stop         : std_logic := '0';
signal quot_rdy_o   : std_logic;
signal enable_i_dly : std_logic;
signal trig_div_i   : std_logic; 
signal latch        : signed(31 downto 0); 
signal sum_di       : signed(63 downto 0);
signal sum_num      : unsigned(31 downto 0); 
signal quot_o       : std_logic_vector(31 downto 0);
signal inp_i_dly    : signed(31 downto 0); 
signal divisor_i    : std_logic_vector(31 downto 0);
signal divider_i    : std_logic_vector(63 downto 0);  


begin
 
ps_filter_func: process(clk_i)
begin
  if rising_edge(clk_i)then

    enable_i_dly <= enable_i;
    inp_i_dly <= signed(inp_i);     

    -- Difference mode enabled 
    if mode_i = difference then
      -- Capture the data
      if enable_i = '1' and enable_i_dly = '0' then
        latch <= signed(inp_i);   
      -- Trigger event has happened so out_o = inp_do - latch  
      elsif trig_i = '1' then
        latch <= signed(inp_i);
        ready_o <= '1';
        out_o <= std_logic_vector(signed(inp_i) - latch);     
      else
        ready_o <= '0';
      end if;
              
    -- Average mode enabled 
    elsif mode_i = average then
        -- Output the divider result
        ready_o <= quot_rdy_o;
        out_o <= quot_o; 
      -- Reset the data and number accumulators
      if enable_i = '1' and enable_i_dly = '0' then
        sum_di <= (others => '0');
        sum_num <= (others => '0');
      -- Start accumulating 
      elsif enable_i_dly = '1' then
        sum_di <= sum_di + inp_i_dly;
        sum_num <= sum_num +1; 
      end if;
      -- Trigger the divider  
      if trig_i = '1' and stop = '0' then
        trig_div_i <= '1'; 
        divisor_i <= std_logic_vector(sum_num);
        divider_i <= std_logic_vector(sum_di);  
      else
        trig_div_i <= '0'; 
      end if; 
    else
      ready_o <= '0';
      out_o <= (others => '0'); 
    end if;
  end if;
end process ps_filter_func;


ps_err: process(clk_i)
begin
  if rising_edge(clk_i)then
    -- If sum overflows then generate an error and stop processing
    -- its a signed accumulator so XOR the top two bits
    if sum_di(63) xor sum_di(62) = '1' then
      stop <= '1';
      err_o <= '1';
    end if;
  end if;
end process ps_err;


inst_divider: divider
  port map (clk_i      => clk_i,
            enable_i   => trig_div_i,
            divisor_i  => divisor_i,
            divider_i  => divider_i, 
            quot_rdy_o => quot_rdy_o,
            quot_o     => quot_o);

 

end architecture rtl;    
