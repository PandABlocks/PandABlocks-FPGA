library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity pll_autoreset is
port (
    clk_i        : in std_logic;
    pll_locked_i : in std_logic;
    pll_reset_o  : out std_logic
);
end pll_autoreset;


architecture rtl of pll_autoreset is
constant c_wait_reset : natural := 1000;

signal pll_reset_cnt  : unsigned(9 downto 0) := (others => '0');
begin

process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Enable the PLL reset
        if pll_reset_cnt /= c_wait_reset and pll_locked_i = '0' then
            pll_reset_cnt <= pll_reset_cnt + 1;
        -- Reset the PLL reset when it goes out of lock
        elsif pll_locked_i = '1' then
            pll_reset_cnt <= (others => '0');
        end if;
        if pll_locked_i = '0' then
            if pll_reset_cnt = c_wait_reset then
                pll_reset_o <= '0';
            else
                pll_reset_o <= '1';
            end if;
        end if;
    end if;
end process;

end architecture rtl;
