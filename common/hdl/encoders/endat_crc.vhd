--------------------------------------------------------------------------------
--  PandA Motion Project
--      Diamond Light Source, Oxford, UK
--------------------------------------------------------------------------------
--
--  Description : Serial EnDat CRC-5 generator.
--                Polynomial x^5 + x^3 + x + 1, preset to all ones, the
--                remainder is complemented. Covers the error bits and the
--                position value, not the start bit. The received CRC is
--                transmitted MSB first.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity endat_crc is
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;

    bitval_i        : in  std_logic;
    bitstrb_i       : in  std_logic;
    crc_o           : out std_logic_vector(4 downto 0)
);
end;

architecture rtl of endat_crc is

-- x^5 + x^3 + x + 1, the x^5 term is the feedback
constant c_POLY     : std_logic_vector(4 downto 0) := "01011";

signal inv          : std_logic;
signal crc          : std_logic_vector(4 downto 0);

begin

inv <= bitval_i xor crc(4);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i then
            crc <= (others => '1');
        elsif bitstrb_i then
            crc <= (crc(3 downto 0) & '0') xor (c_POLY and inv);
        end if;
    end if;
end process;

crc_o <= not crc;

end;
