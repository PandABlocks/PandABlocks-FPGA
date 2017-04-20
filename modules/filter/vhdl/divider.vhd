library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is
  port (clk_i      : in  std_logic;
        enable_i   : in  std_logic; 
        divisor_i  : in  std_logic_vector(31 downto 0);
        divider_i  : in  std_logic_vector(63 downto 0);
        quot_rdy_o : out std_logic;
        quot_o     : out std_logic_vector(31 downto 0));

end divider;   

architecture rtl of divider is

constant c_divid_msb    : integer := 63;
constant c_divid_lsb    : integer := 31;

signal stop     : std_logic;
signal enable   : std_logic; 
signal index    : unsigned(5 downto 0);
signal divider  : unsigned(63 downto 0); 
signal result   : unsigned(31 downto 0); 

begin

ps_divider: process(clk_i)
begin
  if rising_edge(clk_i)then
    -- Turn the Divider on
    if enable_i = '1' then 
      enable <= '1';
      divider <= unsigned(divider_i);
    -- When the divided has been done send out the result
    elsif stop = '1' and enable = '1' then      
      enable <= '0';
      quot_rdy_o <= '1';
      quot_o <= std_logic_vector(result);
    else
      quot_rdy_o <= '0';
    end if; 

    if index = to_unsigned(c_divid_lsb,index'length) and enable = '1' then
      stop <= '1';
    else
      stop <= '0';
    end if;      

    if enable = '1' then  
      -- Shift compare and subtract
      if divider((c_divid_msb-to_integer(index)) downto (c_divid_lsb-to_integer(index))) >= unsigned(divisor_i) then
        -- Number of divides 
        result(c_divid_lsb-to_integer(index)) <= '1';
        -- Subtract 
        divider((c_divid_msb-to_integer(index)) downto (c_divid_lsb-to_integer(index))) <= 
                divider((c_divid_msb-to_integer(index)) downto (c_divid_lsb-to_integer(index))) - unsigned(divisor_i);                
      end if;     

      -- index count has reach its terminal value 
      if index /= c_divid_lsb then    
        index <= index +1;
      end if; 


    else 
      index <= (others => '0');
      result <= (others => '0');
    end if;      

  end if;
end process ps_divider;


end architecture rtl;      
