library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package support is

constant c_BINARY_ENCODING  : std_logic_vector(0 downto 0) := "0";
constant c_GRAY_ENCODING    : std_logic_vector(0 downto 0) := "1";

--
-- Functions
--
function TO_INTEGER(arg : std_logic_vector) return integer;
function TO_SVECTOR(arg: natural; size: natural) return std_logic_vector;
function TO_STDV1(arg : std_logic) return std_logic_vector;
function LOG2(arg : natural) return natural;
function ZEROS(num : positive) return std_logic_vector;
function COMP(a : std_logic_vector; b: std_logic_vector) return std_logic;
function BITREV(A : std_logic_vector) return std_logic_vector;

end support;

package body support is

-- Converts integer to std_logic_vector
function TO_INTEGER(arg : std_logic_vector) return integer is
begin
    return to_integer(unsigned(arg));
end TO_INTEGER;

-- Converts integer to std_logic_vector
function TO_SVECTOR(arg: natural; size: natural) return std_logic_vector is
begin
    return std_logic_vector(to_unsigned(arg, size));
end TO_SVECTOR;

function LOG2(arg: natural) return natural is
    variable t : natural := arg;
    variable n : natural := 0;
begin
    while t > 0 loop
        t := t / 2;
        n := n + 1;
    end loop;
    return n-1;
end function;

-- Return a std_logic_vector filled with zeros
function ZEROS(num : positive) return std_logic_vector is
    variable vector : std_logic_vector(num-1 downto 0) := (others => '0');
begin
    return (vector);
end ZEROS;

-- Converts std_logic to std_logic_vector(0:0)
function TO_STDV1(arg : std_logic) return std_logic_vector is
    variable temp   : std_logic_vector(0 downto 0);
begin
    temp(0) := arg;
    return temp;
end TO_STDV1;

-- Compare two vectors
function COMP (a : std_logic_vector; b: std_logic_vector) return std_logic is
begin
    if (a/= b) then
        return '1';
    else
        return '0';
    end if;
end COMP;

-- Bit reversal
function BITREV(A : std_logic_vector) return std_logic_vector is
    variable B : std_logic_vector(A'length-1 downto 0);
begin
    for i in A'range loop
        B(B'left - i) := A(i);
    end loop;

    return B;
end BITREV;

end support;
