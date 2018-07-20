library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.top_defines.all;


entity filter_block_top_tb is
end filter_block_top_tb;

architecture rtl of filter_block_top_tb is                   


procedure write_data (
   address              : in  std_logic_vector;
   sysbus_num           : in  integer;
   write_data_en        : in  std_logic; 
   mode_en              : in  std_logic;
   mode                 : in  std_logic_vector(1 downto 0); 
   signal write_address : out std_logic_vector(9 downto 0);
   signal write_data    : out std_logic_vector(31 downto 0);
   signal sysbus        : out std_logic_vector(127 downto 0)) is   
begin
  write_address <= address;
  if write_data_en = '1' and mode_en = '0' then
    write_data(9 downto 0) <= address;
    write_data(31 downto 10) <= (others => '0'); 
  elsif write_data_en = '1' and mode_en = '1' then 
    write_data(1 downto 0) <= mode;
    write_data(31 downto 2) <= (others => '0'); 
  else
    write_data <= (others => '0');
  end if;  
  if mode_en = '0' then
    sysbus <= (others => '0');
    sysbus(sysbus_num) <= '1';
  else
    sysbus <= (others => '0');
  end if;       
end procedure write_data;  
     
   
constant c_mode_address1   : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(0,10));  -- OK
constant c_trig_address1   : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(1,10));  -- OK
constant c_enable_address1 : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(4,10));  -- OK 


signal clk_i             : std_logic := '0';
signal write_strobe_i    : std_logic;
signal write_address_i   : std_logic_vector(PAGE_AW-1 downto 0);
signal write_data_i      : std_logic_vector(31 downto 0);
signal write_ack_o       : std_logic;
signal sysbus_i          : std_logic_vector(SBUSW-1 downto 0);       
signal posbus_i          : posbus_t;                                 
signal out_o             : std32_array(FILTER_NUM-1 downto 0);  
signal ready_o           : std_logic_vector(FILTER_NUM-1 downto 0);
signal err_o             : std_logic_vector(FILTER_NUM-1 downto 0);              

signal enable            : std_logic; 
signal data_cnt1         : unsigned(31 downto 0) := (others => '0');
signal data_cnt2         : unsigned(31 downto 0) := (others => '0'); 
signal write_address_cnt : unsigned(9 downto 0) := (others => '0'); 

signal cnt               : integer; 
signal clks_cnt          : integer;     


begin


clk_i <= not clk_i after 4ns;

--  0 first filter  1 to 
-- 64 second filter 

  

-- MODE   = 0
-- TRIG   = 1 2
-- INP    = 3
-- ENABLE = 4 5
ps_write: process
begin
    cnt <= 0;
    sysbus_i <= (others => '0');
    write_strobe_i <= '0';
    write_address_i <= (others => '0');
    write_data_i <= (others => '0');    
  wait for 64 ns;  
  
  -- Mode = "00" DIFFERENCE
  wait until clk_i'event and clk_i = '1';
    write_data(c_mode_address1, to_integer(unsigned(c_mode_address1)), '1', '1', "00", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';  
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0';   
  
  -- Enable = '1'
  wait until clk_i'event and clk_i = '1';    
    write_data(c_enable_address1, to_integer(unsigned(c_enable_address1)), '1', '0', "00", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';  
  wait until clk_i'event and clk_i = '1';  
    write_data(c_enable_address1, to_integer(unsigned(c_enable_address1)), '0', '0', "00", write_address_i, write_data_i, sysbus_i);
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0'; 
    
  -- Trig = '1'  
  wait for 128 ns;
  wait until clk_i'event and clk_i = '1';
    write_data(c_trig_address1, to_integer(unsigned(c_trig_address1)), '1', '0', "00", write_address_i, write_data_i, sysbus_i);    
    write_strobe_i <= '1';
  wait until clk_i'event and clk_i = '1';
    write_data(c_trig_address1, to_integer(unsigned(c_trig_address1)), '0', '0', "00", write_address_i, write_data_i, sysbus_i);  
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0';    
          
  -- Mode = "01" DIVIDER
  wait until clk_i'event and clk_i = '1';
    write_data(c_mode_address1, to_integer(unsigned(c_mode_address1)), '1', '1', "01", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';  
  wait until  clk_i'event and clk_i = '1';
    write_strobe_i <= '0'; 
  
  -- Enable = '1'
  wait until clk_i'event and clk_i = '1';
    write_data(c_enable_address1, to_integer(unsigned(c_enable_address1)), '1', '0', "00", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0';    
  wait for 640 ns;
  wait until clk_i'event and clk_i = '1';
    write_data(c_enable_address1, to_integer(unsigned(c_enable_address1)), '0', '0', "00", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';    
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0';
  
  -- Trig = '1'   
  wait until clk_i'event and clk_i = '1';
    write_data(c_trig_address1, to_integer(unsigned(c_trig_address1)), '1', '0', "00", write_address_i, write_data_i, sysbus_i);    
    write_strobe_i <= '1';
  wait until clk_i'event and clk_i = '1';      
    write_data(c_trig_address1, to_integer(unsigned(c_trig_address1)), '0', '0', "00", write_address_i, write_data_i, sysbus_i);
  wait until clk_i'event and clk_i = '1';    
    write_strobe_i <= '0';
  wait until clk_i'event and clk_i = '1';
  
  
  wait for 328 ns;
  -- Mode = "00" DIFFERENCE
  wait until clk_i'event and clk_i = '1';
    write_data(c_mode_address1, to_integer(unsigned(c_mode_address1)), '1', '1', "00", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';  
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0';   
  
  -- Enable = '1'
  wait until clk_i'event and clk_i = '1';    
    write_data(c_enable_address1, to_integer(unsigned(c_enable_address1)), '1', '0', "00", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';  
  wait until clk_i'event and clk_i = '1';  
    write_data(c_enable_address1, to_integer(unsigned(c_enable_address1)), '0', '0', "00", write_address_i, write_data_i, sysbus_i);
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0'; 
    
  -- Trig = '1'  
  wait for 512 ns;
  wait until clk_i'event and clk_i = '1';
    write_data(c_trig_address1, to_integer(unsigned(c_trig_address1)), '1', '0', "00", write_address_i, write_data_i, sysbus_i);    
    write_strobe_i <= '1';
  wait until clk_i'event and clk_i = '1';
    write_data(c_trig_address1, to_integer(unsigned(c_trig_address1)), '0', '0', "00", write_address_i, write_data_i, sysbus_i);  
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0';    
  
  wait for 64 ns;  
  -- Mode = "01" DIVIDER
  wait until clk_i'event and clk_i = '1';
    write_data(c_mode_address1, to_integer(unsigned(c_mode_address1)), '1', '1', "01", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';  
  wait until  clk_i'event and clk_i = '1';
    write_strobe_i <= '0'; 
  
  -- Enable = '1'
  wait until clk_i'event and clk_i = '1';
    write_data(c_enable_address1, to_integer(unsigned(c_enable_address1)), '1', '0', "00", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0';    
  wait for 64000 ns;
  wait until clk_i'event and clk_i = '1';
    write_data(c_enable_address1, to_integer(unsigned(c_enable_address1)), '0', '0', "00", write_address_i, write_data_i, sysbus_i);
    write_strobe_i <= '1';    
  wait until clk_i'event and clk_i = '1';
    write_strobe_i <= '0';
  
  -- Trig = '1'   
  wait until clk_i'event and clk_i = '1';
    write_data(c_trig_address1, to_integer(unsigned(c_trig_address1)), '1', '0', "00", write_address_i, write_data_i, sysbus_i);    
    write_strobe_i <= '1';
  wait until clk_i'event and clk_i = '1';      
    write_data(c_trig_address1, to_integer(unsigned(c_trig_address1)), '0', '0', "00", write_address_i, write_data_i, sysbus_i);
  wait until clk_i'event and clk_i = '1';    
    write_strobe_i <= '0';
  wait until clk_i'event and clk_i = '1';

  
  
  wait;
end process;  

  

ps_posbus: process(clk_i)
begin
  if rising_edge(clk_i)then
    enable <= '0';
    if enable = '1' then    
      posbus_i <= (others => (others => '0'));
    else
      data_cnt1 <= data_cnt1 +1;
      data_cnt2 <= data_cnt2 +1; 
      posbus_i(0) <= std_logic_vector(data_cnt1); 
      posbus_i(1) <= std_logic_vector(data_cnt2);  
      posbus_i(31 downto 2) <= (others => (others => '0'));    
    end if;
  end if;
end process ps_posbus;        

  

inst_filter_top : entity work.filter_top
port map(clk_i               => clk_i,
         reset_i             => '0',
         read_strobe_i       => '0', 
         read_address_i      => (others => '0'),
         read_data_o         => open,
         read_ack_o          => open,
         write_strobe_i      => write_strobe_i,
         write_address_i     => write_address_i,
         write_data_i        => write_data_i,
         write_ack_o         => write_ack_o,
         sysbus_i            => sysbus_i,
         posbus_i            => posbus_i,
         out_o               => out_o, 
         ready_o             => ready_o,
         err_o               => err_o            
 );
 
 
end architecture rtl; 
