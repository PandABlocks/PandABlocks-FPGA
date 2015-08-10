library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package type_defines is

subtype iobuf_ctrl_t is std_logic_vector(2 downto 0);
type iobuf_ctrl_array is array(natural range <>) of iobuf_ctrl_t;

subtype encmode_t is std_logic_vector(2 downto 0);
type encmode_array is array(natural range <>) of encmode_t;

subtype seq_puls_t is std_logic_vector(5 downto 0);
type seq_puls_array is array(natural range <>) of seq_puls_t;

subtype posn_t is std_logic_vector(31 downto 0);
type std32_array is array(natural range <>) of posn_t;

--
-- Functions
--
function TO_INTEGER(arg : std_logic_vector) return integer;
function TO_STD_VECTOR(arg : integer; size: natural) return std_logic_vector;

end type_defines;

package body type_defines is

-- Converts integer to std_logic_vector
function TO_INTEGER(arg : std_logic_vector) return integer is
begin
    return to_integer(unsigned(arg));
end TO_INTEGER;

-- Converts integer to std_logic_vector
function TO_STD_VECTOR(arg : integer; size: natural) return std_logic_vector is
begin
    return std_logic_vector(to_signed(arg, size));
end TO_STD_VECTOR;

end type_defines;
