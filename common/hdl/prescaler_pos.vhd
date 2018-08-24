--------------------------------------------------------------------------------
--  File:       prescaler.vhd
--  Desc:       A simple 32-bit prescaler.
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prescaler_pos is
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    PERIOD          : in  std_logic_vector(31 downto 0);
    pulse_o         : out std_logic
);
end prescaler_pos;

architecture rtl of prescaler_pos is

constant c_zeros       : unsigned(31 downto 0) := X"00000000";

signal clk_cnt         : unsigned(31 downto 0) := (others => '0');
signal period_rollover : unsigned(31 downto 0);

begin

period_rollover <= c_zeros when (unsigned(PERIOD) < 1) else unsigned(PERIOD) - 1;

pulse_o <= '1' when (clk_cnt = period_rollover) else '0';

--
-- Generate QENC clk defined by the prescaler
--
qenc_clk_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            clk_cnt <= (others => '0');
        else
            if (clk_cnt = period_rollover) then
                clk_cnt <= (others => '0');
            else
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end if;
end process;

end rtl;
