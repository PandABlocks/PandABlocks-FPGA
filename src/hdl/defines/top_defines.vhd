library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;

package top_defines is

--
--  CONSTANTs :
--

-- Block instantiation numbers
constant TTLIN_NUM          : positive := 6;
constant TTLOUT_NUM         : positive := 10;
constant LVDSIN_NUM         : positive := 2;
constant LVDSOUT_NUM        : positive := 2;
constant LUT_NUM            : positive := 8;
constant SRGATE_NUM         : positive := 4;
constant DIV_NUM            : positive := 4;
constant PULSE_NUM          : positive := 4;

constant COUNTER_NUM        : positive := 8;

constant ENC_NUM            : positive := 4;
constant PCOMP_NUM          : positive := 4;
constant SEQ_NUM            : positive := 4;
constant BITS_NUM           : positive := 1;

-- Bit Bus Width, Multiplexer Select Width.
constant SBUSW              : positive := 128;
constant SBUSBW             : positive := 7;

-- Position Bus Width, Multiplexer Select Width.
constant PBUSW              : positive := 32;
constant PBUSBW             : positive := 5;

-- Extended Position Bus Width.
constant EBUSW              : positive := 12;

--
-- TYPEs :
--
subtype sysbus_t is std_logic_vector(SBUSW-1 downto 0);
subtype posbus_t is std32_array(PBUSW-1 downto 0);
subtype extbus_t is std32_array(EBUSW-1 downto 0);

-- System Bus Multiplexer Select array type
subtype sbus_muxsel_t is std_logic_vector(SBUSBW-1 downto 0);
type sbus_muxsel_array is array (natural range <>) of sbus_muxsel_t;

subtype pbus_muxsel_t is std_logic_vector(PBUSBW-1 downto 0);

--
-- FUNCTIONs :
--

-- Return selected System Bus bit
function SBIT(sbus : std_logic_vector; sel : sbus_muxsel_t) return std_logic;
function PFIELD(pbus : std32_array; sel : pbus_muxsel_t) return std_logic_vector;
function ZEROS(num : positive) return std_logic_vector;

end top_defines;

package body top_defines is

-- Return selected System Bus bit
function SBIT(sbus : std_logic_vector; sel : sbus_muxsel_t) return std_logic is
begin
    return sbus(to_integer(unsigned(sel)));
end SBIT;

-- Return selected Position Bus field
function PFIELD(pbus : std32_array; sel : pbus_muxsel_t) return std_logic_vector is
begin
    return pbus(to_integer(unsigned(sel)));
end PFIELD;

-- Return a std_logic_vector filled with zeros
function ZEROS(num : positive) return std_logic_vector is
    variable vector : std_logic_vector(num-1 downto 0) := (others => '0');
begin
    return (vector);
end ZEROS;

end top_defines;

