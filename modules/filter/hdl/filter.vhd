library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity filter is
  port (clk_i    : in  std_logic;
        mode     : in  std_logic_vector(31 downto 0);
        trig_i   : in  std_logic;
        inp_i    : in  std_logic_vector(31 downto 0);
        enable_i : in  std_logic;
        out_o    : out std_logic_vector(31 downto 0) := (others => '0');
        ready_o  : out std_logic;
        health   : out std_logic_vector(31 downto 0) := (others => '0')
);
end filter;


architecture rtl of filter is


constant difference    : std_logic_vector(0 downto 0) := "0";
constant average       : std_logic_vector(0 downto 0) := "1";

signal stop            : std_logic := '0';
signal trig_dly        : std_logic;
signal result_neg      : std_logic := '0';
signal trig_div_dly    : std_logic := '0';
signal div_enabled     : std_logic := '0';
signal quot_rdy_o      : std_logic;
signal enable_i_dly    : std_logic;
signal trig_div_i      : std_logic := '0';
signal accum_of_err    : std_logic := '0';
signal div_enabled_err : std_logic := '0';
signal latch           : signed(31 downto 0) := (others => '0');
signal sum_i           : signed(63 downto 0) := (others => '0');
signal sum_num         : unsigned(31 downto 0) := (others => '0');
signal quot_o          : std_logic_vector(31 downto 0);
signal divisor_i       : std_logic_vector(31 downto 0) := (others => '0');
signal divider_i       : std_logic_vector(63 downto 0) := (others => '0');


begin

ps_filter_func: process(clk_i)
begin
  if rising_edge(clk_i)then

    enable_i_dly <= enable_i;
    trig_dly <= trig_i;

    -- Difference mode enabled
    if mode(0 downto 0) = difference then
      -- Capture the data
      if enable_i = '1' and enable_i_dly = '0' then
        latch <= signed(inp_i);
      -- Trigger event has happened so out_o = inp_do - latch
      elsif trig_i = '1' and trig_dly = '0' then
        latch <= signed(inp_i);
        -- Output the difference result only if we aren't in error
        if stop = '0' then
          ready_o <= '1';
          out_o <= std_logic_vector(signed(inp_i) - latch);
        end if;
      else
        ready_o <= '0';
      end if;

    -- Average mode enabled
    elsif mode(0 downto 0) = average then
        -- Output the divider result if we aren't in error
        if stop = '0' then
          ready_o <= quot_rdy_o;
          -- Complement if the accumulator goes negative
          if quot_rdy_o = '1' then
            if result_neg = '1' then
              out_o <= std_logic_vector((not(signed(quot_o)))+1);
            else
              out_o <= quot_o;

            end if;
          end if;
        end if;
      -- Reset the data and number accumulators
      if enable_i = '1' and enable_i_dly = '0' then
        sum_i <= (others => '0');
        ----sum_i <= x"3fffffff00000000"; -- positive
        ----sum_i <= x"c000000100000000"; -- negative
        sum_num <= (others => '0');
      -- Start accumulating
      elsif enable_i_dly = '1' then
        sum_i <= sum_i + signed(inp_i);
        sum_num <= sum_num +1;
      end if;
      -- Trigger the divider
      if trig_i = '1' and enable_i_dly = '1' then
        trig_div_i <= '1';
        divisor_i <= std_logic_vector(sum_num);
        -- Complement if the accumulator goes negative
        if sum_i(63) = '1' then
         result_neg <= '1';
         divider_i <= std_logic_vector((not(sum_i))+1);
         else
         result_neg <= '0';
         divider_i <= std_logic_vector(sum_i);
        end if;
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

    trig_div_dly <= trig_div_i;

    -- Divider has been enabled
    if trig_div_i = '1' and trig_div_dly = '0' then
      div_enabled <= '1';
      if div_enabled = '1' then
        div_enabled_err <= '1';
      end if;
    elsif div_enabled = '1' and enable_i = '1' and enable_i_dly = '0' then
      div_enabled_err <= '1';
    -- Divider has finished
    elsif quot_rdy_o = '1' then
      div_enabled <= '0';
      div_enabled_err <= '0';
    end if;

    -- 1. If sum overflows then generate an error and stop processing
    --    its a signed accumulator so XOR the top two bits
    -- 2. If divider block is active and it gets enabled again whilst
    --    process a result then an error is generated
    accum_of_err <= (sum_i(63) xor sum_i(62));
    if enable_i = '1' and  enable_i_dly = '0' then
      stop <= '0';
      health <= (others => '0');
    elsif (accum_of_err or div_enabled_err) = '1' then
      stop <= '1';
      health(0) <= (sum_i(63) xor sum_i(62));
      health(1) <= div_enabled_err;
    end if;
  end if;
end process ps_err;


inst_divider: entity work.divider
  port map (clk_i      => clk_i,
            enable_i   => trig_div_i,
            divisor_i  => divisor_i,
            divider_i  => divider_i,
            quot_rdy_o => quot_rdy_o,
            quot_o     => quot_o);



end architecture rtl;
