--------------------------------------------------------------------------------
--  File:       prescaler.vhd
--  Desc:       A simple 32-bit prescaler.
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prescaler is
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    PERIOD          : in  std_logic_vector(31 downto 0);
    pulse_o         : out std_logic
);
end prescaler;

architecture rtl of prescaler is

signal clk_cnt      : unsigned(31 downto 0) := (others => '0');

begin

--
-- 32-bit up counter rolling over PERIOD
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            pulse_o <= '0';
            clk_cnt <= (others => '0');
        else
            if (clk_cnt =  unsigned(PERIOD)-1) then
                pulse_o <= '1';
                clk_cnt <= (others => '0');
            else
                pulse_o <= '0';
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end if;
end process;

end rtl;
