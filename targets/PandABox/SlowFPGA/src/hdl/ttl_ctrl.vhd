--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Encoder Daugther Card receive interface.
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.slow_defines.all;

entity ttl_ctrl is
generic (
    AW              : natural := 10;
    DW              : natural := 32
);
port (
    -- 50MHz system clock
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Serial Receive Interface
    rx_addr_i       : in  std_logic_vector(AW-1 downto 0);
    rx_valid_i      : in  std_logic;
    rx_data_i       : in  std_logic_vector(DW-1 downto 0);
    -- Encoder Daughter Card Control interface
    ttlin_term_o    : out std_logic_vector(5 downto 0)
);
end ttl_ctrl;

architecture rtl of ttl_ctrl is

signal rx_addr    : natural range 0 to (2**AW - 1);

begin

rx_addr <= to_integer(unsigned(rx_addr_i));

--
-- Read Register Interface
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ttlin_term_o <= (others => '0');
        else
            if (rx_valid_i = '1' and rx_addr = TTLIN1_TERM) then
                ttlin_term_o(0) <= rx_data_i(0);
            end if;

            if (rx_valid_i = '1' and rx_addr = TTLIN2_TERM) then
                ttlin_term_o(1) <= rx_data_i(0);
            end if;

            if (rx_valid_i = '1' and rx_addr = TTLIN3_TERM) then
                ttlin_term_o(2) <= rx_data_i(0);
            end if;

            if (rx_valid_i = '1' and rx_addr = TTLIN4_TERM) then
                ttlin_term_o(3) <= rx_data_i(0);
            end if;

            if (rx_valid_i = '1' and rx_addr = TTLIN5_TERM) then
                ttlin_term_o(4) <= rx_data_i(0);
            end if;

            if (rx_valid_i = '1' and rx_addr = TTLIN6_TERM) then
                ttlin_term_o(5) <= rx_data_i(0);
            end if;
        end if;
    end if;
end process;

end rtl;
