library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is

  generic (g_divider_size  : integer := 64;
           g_divisor_size  : integer := 32);
           
  port (clk_i      : in  std_logic;
        enable_i   : in  std_logic; 
        divisor_i  : in  std_logic_vector(g_divisor_size-1 downto 0);
        divider_i  : in  std_logic_vector(g_divider_size-1 downto 0);
        quot_rdy_o : out std_logic;
        quot_o     : out std_logic_vector((g_divider_size-g_divisor_size)-1  downto 0));

end divider;   

architecture rtl of divider is

-- Log 2 function
function log2 (x : positive) return natural is
  variable i : natural;
begin
  i := 0;
  while (2**i < x) and i < 31 loop
    i := i +1;
  end loop;
  return i;
end function;
      

signal stop     : std_logic;
signal enable   : std_logic; 
signal index    : unsigned(log2(g_divisor_size-1) downto 0); 
signal divider  : unsigned(g_divider_size-1 downto 0); 
signal result   : unsigned(g_divisor_size-1 downto 0); 

signal divider_comp : unsigned(31 downto 0);

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

    if index = to_unsigned(g_divisor_size-1,index'length) then
      stop <= '1';
    else
      stop <= '0';
    end if;   
           
    -- Enable the divider
    if enable = '1' then         
          
      -- Shift compare and subtract
      ----------if divider((g_divider_size-to_integer(index))-1 downto (g_divisor_size-to_integer(index))-1) >= unsigned(divisor_i) then
      if divider((g_divider_size-to_integer(index))-2 downto (g_divisor_size-to_integer(index))-1) >= unsigned(divisor_i) then
      
        divider_comp <= divider((g_divider_size-to_integer(index))-2 downto (g_divisor_size-to_integer(index))-1);
      
        -- Number of divide 
        result(g_divisor_size-to_integer(index)-1) <= '1';
        -- Subtract 
        ----------divider((g_divider_size-to_integer(index))-1 downto (g_divisor_size-to_integer(index))-1) <= 
        ----------        divider((g_divider_size-to_integer(index))-1 downto (g_divisor_size-to_integer(index))-1) - unsigned(divisor_i);                
        divider((g_divider_size-to_integer(index))-2 downto (g_divisor_size-to_integer(index))-1) <= 
                divider((g_divider_size-to_integer(index))-2 downto (g_divisor_size-to_integer(index))-1) - unsigned(divisor_i);                
      end if;     

      -- index count has reach its terminal value 
      if index /= g_divisor_size-1 then    
        index <= index +1;
      end if; 

    else 
      index <= (others => '0');
      result <= (others => '0');
    end if;      

  end if;
end process ps_divider;


end architecture rtl;      
