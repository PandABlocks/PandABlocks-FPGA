--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : 4-Channel adder block with sign inversion option and output
--                scaling
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    inpa_i              : in  std_logic_vector(31 downto 0);
    inpb_i              : in  std_logic_vector(31 downto 0);
    inpc_i              : in  std_logic_vector(31 downto 0);
    inpd_i              : in  std_logic_vector(31 downto 0);
    out_o               : out std_logic_vector(31 downto 0);
    -- Block Parameters and Status
    INPA_INVERT         : in  std_logic;
    INPB_INVERT         : in  std_logic;
    INPC_INVERT         : in  std_logic;
    INPD_INVERT         : in  std_logic;
    SCALE               : in  std_logic_vector(1 downto 0)
);
end adder;

architecture rtl of adder is

-- Resize and sign-invert to required with based on flag
function posn_data(data : std_logic_vector; flag : std_logic; width : natural)
    return signed
is
    variable resized    : unsigned(width-1 downto 0);
    variable converted  : signed(width-1 downto 0);
begin
    resized := unsigned(resize(signed(data), width));
    converted := signed(not(resized) + 1);
    if (flag = '0') then
        return signed(resized);
    else
        return converted;
    end if;
end;

signal acc_ab           : signed(33 downto 0) := (others => '0');
signal acc_cd           : signed(33 downto 0) := (others => '0');
signal acc_abcd         : signed(33 downto 0) := (others => '0');

begin

-- Synchronised adder tree
process(clk_i)
begin
    if rising_edge(clk_i) then
        acc_ab <= posn_data(inpa_i, INPA_INVERT, acc_abcd'length) +
                    posn_data(inpb_i, INPB_INVERT, acc_abcd'length);

        acc_cd <= posn_data(inpc_i, INPC_INVERT, acc_abcd'length) +
                    posn_data(inpd_i, INPD_INVERT, acc_abcd'length);

        acc_abcd <= acc_ab + acc_cd;
    end if;
end process;

-- Scaled output (take care of sign bit)
process(clk_i) begin
    if rising_edge(clk_i) then
        case SCALE is
            when "00" =>
                out_o <= std_logic_vector(resize(acc_abcd, 32));
            when "01" => 
                out_o <= std_logic_vector(resize(shift_right(acc_abcd,1), 32));
            when "10" =>
                out_o <= std_logic_vector(resize(shift_right(acc_abcd,2), 32));
            when "11" =>
                out_o <= std_logic_vector(resize(shift_right(acc_abcd,3), 32));
            when others =>
                out_o <= std_logic_vector(resize(acc_abcd, 32));
        end case;
    end if;
end process;

end rtl;
