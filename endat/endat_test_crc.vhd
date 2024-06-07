--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface Synchronous Recevier core.
--                Manages link status, and receives incoming SPI transaction,
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity endat_test_crc is
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;

    bitval_i        : in  std_logic;
    bitstrb_i       : in  std_logic;
    crc_o           : out std_logic_vector(4 downto 0)
);
end endat_test_crc;

architecture rtl of endat_test_crc is

signal inv          : std_logic;
signal crc          : std_logic_vector(4 downto 0);

begin

inv <= bitval_i xor crc(4);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            crc <= (others => '0');
        else
            if (bitstrb_i = '1') then
----------------                CRC(5) <= CRC(4);
                CRC(4) <= CRC(3);
                CRC(3) <= CRC(2);
                CRC(2) <= CRC(1);
-----                CRC(1) <= CRC(0) xor inv;
                CRC(1) <= CRC(0);
                CRC(0) <= inv;
            end if;
        end if;
    end if;
end process;

crc_o <= not crc;

end rtl;
