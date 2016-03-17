library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package slow_defines is

-- Number of Status Registers
constant REGS_NUM           : natural := 4;

--
-- Write Only Registers
--
constant WRITE_RESET        : natural := 0;
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
constant TTLIN7_TERM        : natural := 15;
constant TTLIN8_TERM        : natural := 16;
constant TTL_LEDS           : natural := 17;
constant STATUS_LEDS        : natural := 18;


--
-- Read Only Registers
--
constant FPGA_VERSION       : natural := 0;
constant ENC_CONN           : natural := 1;

end slow_defines;

package body slow_defines is


end slow_defines;
