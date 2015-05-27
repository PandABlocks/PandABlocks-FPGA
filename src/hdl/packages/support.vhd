library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package support is

function TO_INTEGER(arg : std_logic_vector) return integer;
function TO_STD_VECTOR(arg : integer; size: natural) return std_logic_vector;

end support;

package body support is

function TO_INTEGER(arg : std_logic_vector) return integer is
begin
    return to_integer(unsigned(arg));
end TO_INTEGER;

function TO_STD_VECTOR(arg : integer; size: natural) return std_logic_vector is
begin
    return std_logic_vector(TO_UNSIGNED(arg, size));
end TO_STD_VECTOR;

end support;

