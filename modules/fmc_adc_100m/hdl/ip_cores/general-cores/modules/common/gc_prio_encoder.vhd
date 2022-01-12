library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gc_prio_encoder is
  
  generic (
    g_width : integer
    );
  port (
    d_i     : in  std_logic_vector(g_width-1 downto 0);
    therm_o : out std_logic_vector(g_width-1 downto 0)
    );

end gc_prio_encoder;


architecture rtl of gc_prio_encoder is

  function f_count_stages(width : integer) return integer is
  begin
    if(width <= 2) then
      return 2;
    elsif(width <= 4) then
      return 3;
    elsif(width <= 8) then
      return 4;
    elsif(width <= 16) then
      return 5;
    elsif(width <= 32) then
      return 6;
    elsif(width <= 64) then
      return 7;
    elsif(width <= 128) then
      return 8;
    else
      return 0;
    end if;
  end f_count_stages;

  constant c_n_stages : integer := f_count_stages(g_width);

  type t_stage_array is array(0 to c_n_stages) of std_logic_vector(g_width-1 downto 0);
  signal stages : t_stage_array;
begin  -- rtl

  stages(0) <= d_i;
  
  gen1 : for i in 1 to c_n_stages generate
    gen2 : for j in 0 to g_width-1 generate
      gen3 : if(j mod (2 ** i) >= (2 ** (i-1))) generate
        stages(i)(j) <= stages(i-1)(j) or stages(i-1) (j - (j mod (2**i)) + (2**(i-1)) - 1);
      end generate gen3;
      gen4 : if not (j mod (2 ** i) >= (2 ** (i-1))) generate
        stages(i)(j) <= stages(i-1)(j);
      end generate gen4;
    end generate gen2;
  end generate gen1;

  therm_o <= stages(c_n_stages);
end rtl;
