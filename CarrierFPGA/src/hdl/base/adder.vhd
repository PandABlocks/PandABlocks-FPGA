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
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    inpa_i              : in  std_logic_vector(31 downto 0);
    inpb_i              : in  std_logic_vector(31 downto 0);
    inpc_i              : in  std_logic_vector(31 downto 0);
    inpd_i              : in  std_logic_vector(31 downto 0);
    out_o               : out std_logic_vector(31 downto 0);
    -- Block Parameters and Status
--    INPA_INVERT         : in  std_logic;
--    INPB_INVERT         : in  std_logic;
--    INPC_INVERT         : in  std_logic;
--    INPD_INVERT         : in  std_logic;
    SCALE               : in  std_logic_vector(1 downto 0)
--    STATUS              : out std_logic_vector(1 downto 0)
);
end adder;

architecture rtl of adder is

signal posn_adder       : signed(33 downto 0);

begin

-- Sign extension and inversion of input data
posn_adder <= resize(signed(inpa_i), posn_adder'length) +
              resize(signed(inpb_i), posn_adder'length) +
              resize(signed(inpc_i), posn_adder'length) +
              resize(signed(inpd_i), posn_adder'length);

process(clk_i) begin
    if (reset_i = '1') then
        out_o <= (others => '0');
    else
        case SCALE is
            when "00" =>
                out_o <= std_logic_vector(posn_adder(31 downto 0));
            when "01" => 
                out_o <= std_logic_vector(posn_adder(32 downto 1));
            when "10" =>
                out_o <= std_logic_vector(posn_adder(33 downto 2));
            when others =>
                out_o <= std_logic_vector(posn_adder(31 downto 0));
        end case;
    end if;
end process;

end rtl;
