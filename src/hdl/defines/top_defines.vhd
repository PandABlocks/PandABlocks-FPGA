library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package top_defines is

-- System Bus Width, Multiplexer Select Width
constant SBUSW      : positive := 128;
constant SBUSBW     : positive := 7;

-- Block Instantiation
constant INENC_NUM  : positive := 1;


-- System Bus Multiplexer Select array type
subtype sbus_muxsel_t is std_logic_vector(SBUSBW-1 downto 0);
type sbus_muxsel_array is array (natural range <>) of sbus_muxsel_t;

-- Return selected System Bus bit
function SBIT(sbus : std_logic_vector; sel : sbus_muxsel_t) return std_logic;

end top_defines;


package body top_defines is

-- Return selected System Bus bit
function SBIT(sbus : std_logic_vector; sel : sbus_muxsel_t) return std_logic is
begin
    return sbus(to_integer(unsigned(sel)));
end SBIT;


end top_defines;

