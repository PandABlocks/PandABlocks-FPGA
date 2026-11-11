--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- WEBSITE: https://github.com/jakubcabal/uart-for-fpga
--------------------------------------------------------------------------------
-- The MIT License (MIT)
--
-- Copyright (c) 2015 Jakub Cabal
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity UART_CLK_DIV is
    Generic (
        DIV_MAX_VAL  : integer := 16;
        DIV_MARK_POS : integer := 1
    );
    Port (
        CLK      : in  std_logic; -- system clock
        RST      : in  std_logic; -- high active synchronous reset
        -- USER INTERFACE
        CLEAR    : in  std_logic; -- clock divider counter clear
        ENABLE   : in  std_logic; -- clock divider counter enable
        DIV_MARK : out std_logic  -- output divider mark (divided clock enable)
    );
end entity;

architecture RTL of UART_CLK_DIV is

    constant CLK_DIV_WIDTH  : integer := integer(ceil(log2(real(DIV_MAX_VAL))));

    signal clk_div_cnt      : unsigned(CLK_DIV_WIDTH-1 downto 0);
    signal clk_div_cnt_mark : std_logic;

begin

    clk_div_cnt_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (CLEAR = '1') then
                clk_div_cnt <= (others => '0');
            elsif (ENABLE = '1') then
                if (clk_div_cnt = DIV_MAX_VAL-1) then
                    clk_div_cnt <= (others => '0');
                else
                    clk_div_cnt <= clk_div_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    clk_div_cnt_mark <= '1' when (clk_div_cnt = DIV_MARK_POS) else '0';

    div_mark_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            DIV_MARK <= ENABLE and clk_div_cnt_mark;
        end if;
    end process;

end architecture;