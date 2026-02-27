library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity pll_autoreset is
port (
    clk_i : in std_logic;
    pll_locked_i : in std_logic;
    pll_reset_o : out std_logic
);
end;

architecture rtl of pll_autoreset is
    constant C_WAIT_RESET : natural := 1000;
    signal pll_reset_cnt : unsigned(9 downto 0) := (others => '0');
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if pll_locked_i = '1' then
                pll_reset_cnt <= (others => '0');
            elsif pll_reset_cnt = C_WAIT_RESET then
                pll_reset_o <= '0';
            else
                pll_reset_o <= '1';
                pll_reset_cnt <= pll_reset_cnt + 1;
            end if;
        end if;
    end process;
end;
