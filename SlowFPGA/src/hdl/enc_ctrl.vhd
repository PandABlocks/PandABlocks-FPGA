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

library unisim;
use unisim.vcomponents.all;

entity enc_ctrl is
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
    enc_ctrl1_o     : out std_logic_vector(11 downto 0);
    enc_ctrl2_o     : out std_logic_vector(11 downto 0);
    enc_ctrl3_o     : out std_logic_vector(11 downto 0);
    enc_ctrl4_o     : out std_logic_vector(11 downto 0)
);
end enc_ctrl;

architecture rtl of enc_ctrl is

signal rx_addr    : natural range 0 to (2**AW - 1);

begin

rx_addr <= to_integer(unsigned(rx_addr_i));

--
-- Read Register Interface
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            enc_ctrl1_o(11 downto 0) <= (others => '0');
            enc_ctrl2_o(11 downto 0) <= (others => '0');
            enc_ctrl3_o(11 downto 0) <= (others => '0');
            enc_ctrl4_o(11 downto 0) <= (others => '0');
        else
            -- INENC_PROTOCOL = DCard Input Channel Buffer Ctrl
            -- Inc   : 0x03
            -- SSI   : 0x0C
            -- Endat : 0x14
            -- BiSS  : 0x1C
            if (rx_valid_i = '1' and rx_addr = INENC1_PROTOCOL) then
                enc_ctrl1_o(1 downto 0) <= rx_data_i(1 downto 0);
                enc_ctrl1_o(4) <= rx_data_i(2);
                enc_ctrl1_o(7 downto 6) <= rx_data_i(4 downto 3);
                enc_ctrl1_o(10) <= rx_data_i(5);
            end if;

            if (rx_valid_i = '1' and rx_addr = INENC2_PROTOCOL) then
                enc_ctrl2_o(1 downto 0) <= rx_data_i(1 downto 0);
                enc_ctrl2_o(4) <= rx_data_i(2);
                enc_ctrl2_o(7 downto 6) <= rx_data_i(4 downto 3);
                enc_ctrl2_o(10) <= rx_data_i(5);
            end if;

            if (rx_valid_i = '1' and rx_addr = INENC3_PROTOCOL) then
                enc_ctrl3_o(1 downto 0) <= rx_data_i(1 downto 0);
                enc_ctrl3_o(4) <= rx_data_i(2);
                enc_ctrl3_o(7 downto 6) <= rx_data_i(4 downto 3);
                enc_ctrl3_o(10) <= rx_data_i(5);
            end if;

            if (rx_valid_i = '1' and rx_addr = INENC4_PROTOCOL) then
                enc_ctrl4_o(1 downto 0) <= rx_data_i(1 downto 0);
                enc_ctrl4_o(4) <= rx_data_i(2);
                enc_ctrl4_o(7 downto 6) <= rx_data_i(4 downto 3);
                enc_ctrl4_o(10) <= rx_data_i(5);
            end if;

            -- OUTENC_PROTOCOL : DCard Output Channel Buffer Ctrl
            -- Inc   : 0x07
            -- SSI   : 0x28
            -- Endat : 0x10
            -- BiSS  : 0x18
            -- Pass  : 0x07
            if (rx_valid_i = '1' and rx_addr = OUTENC1_PROTOCOL) then
                enc_ctrl1_o(3 downto 2) <= rx_data_i(1 downto 0);
                enc_ctrl1_o(5) <= rx_data_i(2);
                enc_ctrl1_o(9 downto 8) <= rx_data_i(4 downto 3);
                enc_ctrl1_o(11) <= rx_data_i(5);
            end if;

            if (rx_valid_i = '1' and rx_addr = OUTENC2_PROTOCOL) then
                enc_ctrl2_o(3 downto 2) <= rx_data_i(1 downto 0);
                enc_ctrl2_o(5) <= rx_data_i(2);
                enc_ctrl2_o(9 downto 8) <= rx_data_i(4 downto 3);
                enc_ctrl2_o(11) <= rx_data_i(5);
            end if;

            if (rx_valid_i = '1' and rx_addr = OUTENC3_PROTOCOL) then
                enc_ctrl3_o(3 downto 2) <= rx_data_i(1 downto 0);
                enc_ctrl3_o(5) <= rx_data_i(2);
                enc_ctrl3_o(9 downto 8) <= rx_data_i(4 downto 3);
                enc_ctrl3_o(11) <= rx_data_i(5);
            end if;

            if (rx_valid_i = '1' and rx_addr = OUTENC4_PROTOCOL) then
                enc_ctrl4_o(3 downto 2) <= rx_data_i(1 downto 0);
                enc_ctrl4_o(5) <= rx_data_i(2);
                enc_ctrl4_o(9 downto 8) <= rx_data_i(4 downto 3);
                enc_ctrl4_o(11) <= rx_data_i(5);
            end if;
        end if;
    end if;
end process;

end rtl;
