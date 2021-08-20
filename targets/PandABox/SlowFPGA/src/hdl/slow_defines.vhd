library ieee;
use ieee.std_logic_1164.all;

package slow_defines is

subtype std3_t is std_logic_vector(2 downto 0);
type std3_array is array(natural range <>) of std3_t;

subtype std4_t is std_logic_vector(3 downto 0);
type std4_array is array(natural range <>) of std4_t;

subtype std8_t is std_logic_vector(7 downto 0);
type std8_array is array(natural range <>) of std8_t;

subtype std32_t is std_logic_vector(31 downto 0);
type std32_array is array(natural range <>) of std32_t;

constant DCARD_MONITOR      : std_logic_vector(2 downto 0) := "011";

--
-- WRITE ONLY Registers
--
--constant WRITE_RESET        : natural := 0; --unused
constant INENC1_PROTOCOL    : natural := 1;
constant INENC2_PROTOCOL    : natural := 2;
constant INENC3_PROTOCOL    : natural := 3;
constant INENC4_PROTOCOL    : natural := 4;
constant OUTENC1_PROTOCOL   : natural := 5;
constant OUTENC2_PROTOCOL   : natural := 6;
constant OUTENC3_PROTOCOL   : natural := 7;
constant OUTENC4_PROTOCOL   : natural := 8;
constant TTLIN1_TERM        : natural := 9;
constant TTLIN2_TERM        : natural := 10;
constant TTLIN3_TERM        : natural := 11;
constant TTLIN4_TERM        : natural := 12;
constant TTLIN5_TERM        : natural := 13;
constant TTLIN6_TERM        : natural := 14;
constant TTL_LEDS           : natural := 15;

--
-- READ ONLY Registers
--
constant SLOW_VERSION       : natural := 0;
constant DCARD1_MODE        : natural := 1;
constant DCARD2_MODE        : natural := 2;
constant DCARD3_MODE        : natural := 3;
constant DCARD4_MODE        : natural := 4;
constant TEMP_PSU           : natural := 5;
constant TEMP_SFP           : natural := 6;
constant TEMP_ENC_L         : natural := 7;
constant TEMP_PICO          : natural := 8;
constant TEMP_ENC_R         : natural := 9;
constant ALIM_12V0          : natural := 10;
constant PICO_5V0           : natural := 11;
constant IO_5V0             : natural := 12;
constant SFP_3V3            : natural := 13;
constant FMC_15VN           : natural := 14;
constant FMC_15VP           : natural := 15;
constant ENC_24V            : natural := 16;
constant FMC_12V            : natural := 17;

end slow_defines;

package body slow_defines is


end slow_defines;

