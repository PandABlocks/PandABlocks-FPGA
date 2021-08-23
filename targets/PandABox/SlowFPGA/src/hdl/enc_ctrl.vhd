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

entity enc_ctrl is
generic (
    AW                  : natural := 10;
    DW                  : natural := 32
);
port (
    -- 50MHz system clock
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Serial Receive Interface
    rx_addr_i           : in  std_logic_vector(AW-1 downto 0);
    rx_valid_i          : in  std_logic;
    rx_data_i           : in  std_logic_vector(DW-1 downto 0);
    -- Encoder Daughter Card Control interface
    INENC_PROTOCOL      : out std3_array(3 downto 0);
    OUTENC_PROTOCOL     : out std3_array(3 downto 0)
);
end enc_ctrl;

architecture rtl of enc_ctrl is

signal rx_addr          : natural range 0 to (2**AW - 1);

begin

rx_addr <= to_integer(unsigned(rx_addr_i));

--
-- Read Register Interface
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            INENC_PROTOCOL <= (others => (others => '0'));
            OUTENC_PROTOCOL <= (others => (others => '0'));
        else
            if (rx_valid_i = '1' and rx_addr = INENC1_PROTOCOL) then
                INENC_PROTOCOL(0) <= rx_data_i(2 downto 0);
            end if;

            if (rx_valid_i = '1' and rx_addr = INENC2_PROTOCOL) then
                INENC_PROTOCOL(1) <= rx_data_i(2 downto 0);
            end if;

            if (rx_valid_i = '1' and rx_addr = INENC3_PROTOCOL) then
                INENC_PROTOCOL(2) <= rx_data_i(2 downto 0);
            end if;

            if (rx_valid_i = '1' and rx_addr = INENC4_PROTOCOL) then
                INENC_PROTOCOL(3) <= rx_data_i(2 downto 0);
            end if;

            if (rx_valid_i = '1' and rx_addr = OUTENC1_PROTOCOL) then
                OUTENC_PROTOCOL(0) <= rx_data_i(2 downto 0);
            end if;

            if (rx_valid_i = '1' and rx_addr = OUTENC2_PROTOCOL) then
                OUTENC_PROTOCOL(1) <= rx_data_i(2 downto 0);
            end if;

            if (rx_valid_i = '1' and rx_addr = OUTENC3_PROTOCOL) then
                OUTENC_PROTOCOL(2) <= rx_data_i(2 downto 0);
            end if;

            if (rx_valid_i = '1' and rx_addr = OUTENC4_PROTOCOL) then
                OUTENC_PROTOCOL(3) <= rx_data_i(2 downto 0);
            end if;

        end if;
    end if;
end process;

end rtl;
