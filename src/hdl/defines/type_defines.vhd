library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package type_defines is

subtype iobuf_ctrl_t is std_logic_vector(2 downto 0);
type iobuf_ctrl_array is array(natural range <>) of iobuf_ctrl_t;

subtype encmode_t is std_logic_vector(2 downto 0);
type encmode_array is array(natural range <>) of encmode_t;

subtype seq_out_t is std_logic_vector(5 downto 0);
type seq_out_array is array(natural range <>) of seq_out_t;

subtype posn_t is std_logic_vector(31 downto 0);
type std32_array is array(natural range <>) of posn_t;

--
-- Functions
--
function TO_INTEGER(arg : std_logic_vector) return integer;
function TO_SVECTOR(arg : natural; size: natural) return std_logic_vector;
function LOG2(arg : integer) return integer;

end type_defines;

package body type_defines is

-- Converts integer to std_logic_vector
function TO_INTEGER(arg : std_logic_vector) return integer is
begin
    return to_integer(unsigned(arg));
end TO_INTEGER;

-- Converts integer to std_logic_vector
function TO_SVECTOR(arg : natural; size: natural) return std_logic_vector is
begin
    return std_logic_vector(to_unsigned(arg, size));
end TO_SVECTOR;

function LOG2(arg: integer) return integer is
        variable t : natural := arg;
        variable n : natural := 0;
    begin
        while t > 0 loop
            t := t / 2;
            n := n + 1;
        end loop;
        return n-1;
    end function;

end type_defines;
