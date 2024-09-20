-- Generic helper and operator functions for writing VHDL.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package operator is
    -- Returns the number of bits required to represent the value x.  Note that,
    -- for example, bits(x) is 4 for x in the range 4 to 7.
    function bits(x : natural) return natural;


    -- These overloaded functions truncate data to in_width by erasing
    -- the bottom data'length-in_width bits, but with rounding.  Rounding is
    -- simply by adding the highest erased bit to avoid a half-bit bias to
    -- -infinity that would otherwise arise.  If extra_width is specified it
    -- it added to the result size, otherwise the result width is in_width.
    --
    --          |--------- data ---------|  input data
    --      |sss|<----- in_width --->|xxx|  sign extended, truncated, rounded
    --      ==============================
    --      |<------ out_width------>|      result after rounding and extension
    --          = in_width+extra_width
    --
    function round(
        data : unsigned;
        in_width : natural;
        extra_width : natural
    ) return unsigned;
    function round(data : unsigned; in_width : natural) return unsigned;

    function round(
        data : signed;
        in_width : natural;
        extra_width : natural
    ) return signed;
    function round(data : signed; in_width : natural) return signed;


    -- Assigns input to output and overflow after discarding the rightmost
    -- offset bits and sets overflow if an overflow occurred during the
    -- assignment to output.  Requires output + offset to be no longer than
    -- input.
    --
    --      |------------------ input ---------------|  input data
    --      |vvvvvvvvs|---------------|<-- offset -->|  extracting result
    --      ==========================================
    --               |---- output ----|                 truncated result
    --      ^^^^^^^^^^
    --       overflow                                   overflow detection
    --
    procedure truncate_result(
        signal output : out signed;
        signal overflow : out std_logic;
        input : signed; offset : natural);
    -- Allow offset to default to zero.
    procedure truncate_result(
        signal output : out signed;
        signal overflow : out std_logic;
        input : signed);

    -- Same for unsigned.  In this case of course overflow detection is simpler.
    procedure truncate_result(
        signal output : out unsigned;
        signal overflow : out std_logic;
        input : unsigned; offset : natural);
    -- Allow offset to default to zero.
    procedure truncate_result(
        signal output : out unsigned;
        signal overflow : out std_logic;
        input : unsigned);


    -- Checks data for consistency, returns '1' if all bits are not the same, ie
    -- '0' is returned if data is all zeros or all ones.
    function overflow_detect(data : signed) return std_logic;


    -- Taking overflow into account returns saturated value if necessar.
    function saturate(
        data : signed; overflow : std_logic; sign : std_logic) return signed;
    function saturate(data : unsigned; overflow : std_logic) return unsigned;

    -- Helper function for extracting sign bit for data
    function sign_bit(data : signed) return std_logic;

    -- Sign extend a std_logic_vector
    function sign_extend(data : std_logic_vector; width : natural)
        return std_logic_vector;


    -- Vectorised functions for mapping logic operations over bit arrays
    function vector_and(data : std_logic_vector) return std_logic;
    function vector_or(data : std_logic_vector) return std_logic;
    function vector_xor(data : std_logic_vector) return std_logic;
    -- Overloads for arithmetic types
    function vector_and(data : signed) return std_logic;
    function vector_or(data : signed) return std_logic;
    function vector_xor(data : signed) return std_logic;
    function vector_and(data : unsigned) return std_logic;
    function vector_or(data : unsigned) return std_logic;
    function vector_xor(data : unsigned) return std_logic;


    -- Simple type conversions
    function to_integer(data : std_logic) return natural;
    function to_boolean(data : std_logic) return boolean;


    -- Helpers for reading and writing bit fields.

    -- Returns field of specified width starting at offset start in data
    function read_field(
        data : std_logic_vector;
        width : natural; start : natural) return std_logic_vector;

    -- Treats data as an array of fields of width bits and returns the field
    -- selected by index.
    function read_field_ix(
        data : std_logic_vector;
        width : natural; index : natural) return std_logic_vector;


    -- Functions for signed max and min int values.  For unsigned we don't need
    -- these as we can just write (others => '1') and (others => '0').
    function max_int(size : natural) return signed;
    function min_int(size : natural) return signed;


    -- Returns array of length bits with the indexed bit set
    function compute_strobe(index : natural; length : natural)
        return std_logic_vector;


    -- Compute min and max of numbers
    function min(a, b : natural) return natural;
    function max(a, b : natural) return natural;

end package;


package body operator is
    function bits(x: natural) return natural is
        variable t : natural := x;
        variable n : natural := 0;
    begin
        while t > 0 loop
            t := t / 2;
            n := n + 1;
        end loop;
        return n;
    end function;

    function round(
        data : unsigned;
        in_width : natural;
        extra_width : natural
    ) return unsigned is
        constant right : natural := data'left - in_width + 1;
        constant out_width : natural := in_width + extra_width;
    begin
        return
            resize(data(data'left downto right), out_width) +
            resize(data(right-1 downto right-1), out_width);
    end function;

    function round(data : unsigned; in_width : natural) return unsigned is
    begin
        return round(data, in_width, 0);
    end function;

    function round(
        data : signed;
        in_width : natural;
        extra_width : natural
    ) return signed is
        constant right : natural := data'left - in_width + 1;
        constant out_width : natural := in_width + extra_width;
    begin
        return
            resize(data(data'left downto right), out_width) +
            resize('0' & data(right-1 downto right-1), out_width);
    end function;

    function round(data : signed; in_width : natural) return signed is
    begin
        return round(data, in_width, 0);
    end function;


    function overflow_detect(data : signed) return std_logic is
    begin
        -- Detect overflow unless all the bits in top_bits are identical.
        -- If not all ones or not all zeros then we have an overflow.
        return not vector_and(data) and vector_or(data);
    end function;

    procedure truncate_result(
        signal output : out signed;
        signal overflow : out std_logic;
        input : signed; offset : natural)
    is
        constant output_left : natural := output'length - 1 + offset;
    begin
        output <= input(output_left downto offset);
        overflow <= overflow_detect(input(input'left downto output_left));
    end;

    procedure truncate_result(
        signal output : out signed;
        signal overflow : out std_logic;
        input : signed) is
    begin
        truncate_result(output, overflow, input, 0);
    end;

    procedure truncate_result(
        signal output : out unsigned;
        signal overflow : out std_logic;
        input : unsigned; offset : natural)
    is
        constant output_left : natural := output'length - 1 + offset;
    begin
        output <= input(output_left downto offset);
        overflow <= vector_or(input(input'left downto output_left+1));
    end;

    procedure truncate_result(
        signal output : out unsigned;
        signal overflow : out std_logic;
        input : unsigned) is
    begin
        truncate_result(output, overflow, input, 0);
    end;


    function saturate(
        data : signed; overflow : std_logic; sign : std_logic) return signed is
    begin
        if overflow = '1' then
            if sign = '1' then
                return min_int(data'length);
            else
                return max_int(data'length);
            end if;
        else
            return data;
        end if;
    end;

    function saturate(data : unsigned; overflow : std_logic) return unsigned
    is
        constant max_val : unsigned(data'range) := (others => '1');
    begin
        if overflow = '1' then
            return max_val;
        else
            return data;
        end if;
    end;

    function sign_bit(data : signed) return std_logic is
    begin
        return data(data'left);
    end;

    function sign_extend(data : std_logic_vector; width : natural)
        return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(data), width));
    end;

    function vector_and(data : std_logic_vector) return std_logic is
        variable result : std_logic := '1';
    begin
        for i in data'range loop
            result := result and data(i);
        end loop;
        return result;
    end function;

    function vector_or(data : std_logic_vector) return std_logic is
        variable result : std_logic := '0';
    begin
        for i in data'range loop
            result := result or data(i);
        end loop;
        return result;
    end function;

    function vector_xor(data : std_logic_vector) return std_logic is
        variable result : std_logic := '0';
    begin
        for i in data'range loop
            result := result xor data(i);
        end loop;
        return result;
    end function;

    function vector_and(data : signed) return std_logic is begin
        return vector_and(std_logic_vector(data));
    end;
    function vector_or(data : signed) return std_logic is begin
        return vector_or(std_logic_vector(data));
    end;
    function vector_xor(data : signed) return std_logic is begin
        return vector_xor(std_logic_vector(data));
    end;
    function vector_and(data : unsigned) return std_logic is begin
        return vector_and(std_logic_vector(data));
    end;
    function vector_or(data : unsigned) return std_logic is begin
        return vector_or(std_logic_vector(data));
    end;
    function vector_xor(data : unsigned) return std_logic is begin
        return vector_xor(std_logic_vector(data));
    end;


    function to_integer(data : std_logic) return natural is begin
        if data = '1' then
            return 1;
        else
            return 0;
        end if;
    end;

    function to_boolean(data : std_logic) return boolean is begin
        return data = '1';
    end;


    function read_field(
        data : std_logic_vector;
        width : natural; start : natural) return std_logic_vector
    is
        variable result : std_logic_vector(width-1 downto 0);
    begin
        result := data(start + width - 1 downto start);
        return result;
    end;

    function read_field_ix(
        data : std_logic_vector;
        width : natural; index : natural) return std_logic_vector is
    begin
        return read_field(data, width, index * width);
    end;


    function max_int(size : natural) return signed is
        variable result : std_logic_vector(size-1 downto 0) := (others => '1');
    begin
        result(size-1) := '0';
        return signed(result);
    end;

    function min_int(size : natural) return signed is
        variable result : std_logic_vector(size-1 downto 0) := (others => '0');
    begin
        result(size-1) := '1';
        return signed(result);
    end;


    function compute_strobe(index : natural; length : natural)
        return std_logic_vector
    is
        variable result : std_logic_vector(0 to length-1) := (others => '0');
    begin
        result(index) := '1';
        return result;
    end;

    -- Compute min and max of numbers
    function min(a, b : natural) return natural is
    begin
        if a <= b then
            return a;
        else
            return b;
        end if;
    end;

    function max(a, b : natural) return natural is
    begin
        if a >= b then
            return a;
        else
            return b;
        end if;
    end;


end package body;
