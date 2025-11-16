--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : 4-Channel calc block with sign inversion option and output
--                scaling
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    inpa_i              : in  std_logic_vector(31 downto 0);
    inpb_i              : in  std_logic_vector(31 downto 0);
    inpc_i              : in  std_logic_vector(31 downto 0);
    inpd_i              : in  std_logic_vector(31 downto 0);
    out_o               : out std_logic_vector(31 downto 0) := (others => '0');
    -- Block Parameters and Status
    TYPEA               : in  std_logic_vector(31 downto 0);
    TYPEB               : in  std_logic_vector(31 downto 0);
    TYPEC               : in  std_logic_vector(31 downto 0);
    TYPED               : in  std_logic_vector(31 downto 0);
    SHIFT               : in  std_logic_vector(31 downto 0)
);
end calc;

architecture rtl of calc is
    -- Resize and sign-invert as required with based on flag
    function convert(data : std_logic_vector; negate : std_logic) return signed
    is
        variable resized : signed(33 downto 0);
    begin
        resized := resize(signed(data), 34);
        if negate = '1' then
            resized := -resized;
        end if;
        return resized;
    end;

    signal inpa_in : signed(33 downto 0) := (others => '0');
    signal inpb_in : signed(33 downto 0) := (others => '0');
    signal inpc_in : signed(33 downto 0) := (others => '0');
    signal inpd_in : signed(33 downto 0) := (others => '0');
    signal calculation : std_logic_vector(33 downto 0) := (others => '0');

begin
    -- Add 2 extra bits to each input to allow for growth during addition and
    -- take account of sign flag.
    inpa_in <= convert(inpa_i, TYPEA(0));
    inpb_in <= convert(inpb_i, TYPEB(0));
    inpc_in <= convert(inpc_i, TYPEC(0));
    inpd_in <= convert(inpd_i, TYPED(0));
    calculation <= std_logic_vector(inpa_in + inpb_in + inpc_in + inpd_in);

    process (clk_i) begin
        if rising_edge(clk_i) then
            -- Shift result as required, this is limited to range 0-2 to reduce
            -- FPGA resources
            case SHIFT(1 downto 0) is
                when "00" => out_o <= calculation(31 downto 0);
                when "01" => out_o <= calculation(32 downto 1);
                when others => out_o <= calculation(33 downto 2);
            end case;
        end if;
    end process;
end;
