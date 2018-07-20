LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

ENTITY adder_tb IS
END adder_tb;

ARCHITECTURE behavior OF adder_tb IS

-- Resize and sign-invert to required with based on flag
function posn_data(data : std_logic_vector; flag : std_logic; width : natural)
    return signed
is
    variable resized    : unsigned(width-1 downto 0);
    variable converted  : signed(width-1 downto 0);
begin
    resized := unsigned(resize(signed(data), width));
    converted := signed(not(resized) + 1);
    if (flag = '0') then
        return signed(resized);
    else
        return converted;
    end if;
end;

--constant num_cycles : integer := 2000;

--Inputs
signal clk_i           : std_logic := '0';
--signal reset_i         : std_logic := '1';
signal inpa_i          : std_logic_vector(31 downto 0) := (others => '0');
signal inpb_i          : std_logic_vector(31 downto 0) := (others => '0');
signal inpc_i          : std_logic_vector(31 downto 0) := (others => '0');
signal inpd_i          : std_logic_vector(31 downto 0) := (others => '0');
signal inpa_tb         : std_logic_vector(31 downto 0) := (others => '0');
signal inpb_tb         : std_logic_vector(31 downto 0) := (others => '0');
signal inpc_tb         : std_logic_vector(31 downto 0) := (others => '0');
signal inpd_tb         : std_logic_vector(31 downto 0) := (others => '0');
signal INPA_INVERT     : std_logic := '0';
signal INPB_INVERT     : std_logic := '0';
signal INPC_INVERT     : std_logic := '0';
signal INPD_INVERT     : std_logic := '0';
signal INPA_INVERT_TB  : std_logic := '0';
signal INPB_INVERT_TB  : std_logic := '0';
signal INPC_INVERT_TB  : std_logic := '0';
signal INPD_INVERT_TB  : std_logic := '0';
signal SCALE           : std_logic_vector(1 downto 0) := (others => '0');
signal SCALE_TB        : std_logic_vector(1 downto 0) := (others => '0');   

signal acc_ab_tb       : signed(33 downto 0) := (others => '0');
signal acc_cd_tb       : signed(33 downto 0) := (others => '0');
signal acc_abcd_tb     : signed(33 downto 0) := (others => '0');

signal a,b,c,d         : integer;

--Outputs
signal out_o  : std_logic_vector(31 downto 0);
signal out_tb : std_logic_vector(31 downto 0);

signal stop   : std_logic;
signal err    : std_logic;

signal test_result : std_logic := '0';

BEGIN

--clk_i <= not clk_i after 4 ns;
--reset_i <= '0' after 100 us;


process
begin
  while stop = '0' loop
    clk_i <= not clk_i;
    wait for 4 ns;
    clk_i <= not clk_i;
    wait for 4 ns;
  end loop;
  wait;
end process;        


inpa_i <= std_logic_vector(to_signed(a,32));
inpb_i <= std_logic_vector(to_signed(b,32));
inpc_i <= std_logic_vector(to_signed(c,32));
inpd_i <= std_logic_vector(to_signed(d,32));

inpa_tb <= std_logic_vector(to_signed(a,32));
inpb_tb <= std_logic_vector(to_signed(b,32));
inpc_tb <= std_logic_vector(to_signed(c,32));
inpd_tb <= std_logic_vector(to_signed(d,32));


-- Testbench checker
ps_tb_check: process(clk_i)
begin
  if rising_edge(clk_i)then
    acc_ab_tb <= posn_data(inpa_tb, INPA_INVERT_tb, acc_abcd_tb'length) +
              posn_data(inpb_tb, INPB_INVERT_tb, acc_abcd_tb'length);

    acc_cd_tb <= posn_data(inpc_tb, INPC_INVERT_tb, acc_abcd_tb'length) +
              posn_data(inpd_tb, INPD_INVERT_tb, acc_abcd_tb'length);    

    acc_abcd_tb <= acc_ab_tb + acc_cd_tb; 

    case SCALE_TB is
      when "00" =>
        out_tb <= std_logic_vector(resize(acc_abcd_tb, 32));
      when "01" => 
        out_tb <= std_logic_vector(resize(shift_right(acc_abcd_tb,1), 32));
      when "10" =>
        out_tb <= std_logic_vector(resize(shift_right(acc_abcd_tb,2), 32));
      when "11" =>
        out_tb <= std_logic_vector(resize(shift_right(acc_abcd_tb,3), 32));
      when others =>
        out_tb <= std_logic_vector(resize(acc_abcd_tb, 32));
    end case;    

  end if;
end process ps_tb_check;  


ps_cap_err: process(clk_i)
begin
  if rising_edge(clk_i)then
    if (out_o /= out_tb) then
      report "Output don't match expected is " & integer'image(to_integer(signed(out_tb))) & 
             " and received is " & integer'image(to_integer(signed(out_o))) severity error;
      err <= '1';     
      test_result <= '1';  
    end if;
  end if;
end process ps_cap_err;   


uut: entity work.adder
PORT MAP (
    clk_i           => clk_i,
    --reset_i         => reset_i,
    inpa_i          => inpa_i,
    inpb_i          => inpb_i,
    inpc_i          => inpc_i,
    inpd_i          => inpd_i,
    out_o           => out_o,
    INPA_INVERT     => INPA_INVERT,
    INPB_INVERT     => INPB_INVERT,
    INPC_INVERT     => INPC_INVERT,
    INPD_INVERT     => INPD_INVERT,
    SCALE           => SCALE
);

-- Stimulus process
stim_proc: process
begin
    stop <= '0';
    SCALE <= "00";
    a <= 0; b <= 0; c <= 0; d <= 0;
    -- hold reset state for 100 ns.
    wait for 1000 ns;
    a <= 100; b <= 100; c <= 100; d <= 0;
    wait for 1000 ns;
    a <= 100; b <= 100; c <= 100; d <= -300;
    wait for 1000 ns;
    a <= -1000; b <= 100; c <= 100; d <= -300;
    wait for 1000 ns;
    SCALE <= "01";
    SCALE_TB <= "01";
    wait for 1000 ns;
    SCALE <= "10";
    SCALE_TB <= "10";
    wait for 1000 ns;
    SCALE <= "11";
    SCALE_TB <= "11";
    wait for 1000 ns;
    a <= 1000; b <= 200; c <= 0; d <= 0;
    INPB_INVERT <= '1';
    INPB_INVERT_TB <= '1';
    wait for 10000 ns;
    SCALE <= "01";
    SCALE_TB <= "01";
    wait for 1000 ns;
    SCALE <= "10";
    SCALE_TB <= "10";
    wait for 1000 ns;
    SCALE <= "11";
    SCALE_TB <= "11";
    wait for 1000 ns;
    stop <= '1';
    wait;
end process;

END;
