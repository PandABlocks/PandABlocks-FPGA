--------------------------------------------------------------------------------
--  File:       lut.vhd
--  Desc:       5-Input LUT.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lut is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    inpa_i              : in  std_logic;
    inpb_i              : in  std_logic;
    inpc_i              : in  std_logic;
    inpd_i              : in  std_logic;
    inpe_i              : in  std_logic;
    out_o               : out std_logic;
    -- Block Parameters
    A                   : in  std_logic_vector(1 downto 0);
    B                   : in  std_logic_vector(1 downto 0);
    C                   : in  std_logic_vector(1 downto 0);
    D                   : in  std_logic_vector(1 downto 0);
    E                   : in  std_logic_vector(1 downto 0);
    FUNC                : in  std_logic_vector(31 downto 0)
);
end lut;

architecture rtl of lut is

signal index            : unsigned(4 downto 0);

begin

-- Assembe index to function
index <= inpa_i & inpb_i & inpc_i & inpd_i & inpe_i;

-- Assign output
process(clk_i)
begin
    if rising_edge(clk_i) then
        out_o <= FUNC(to_integer(index));
    end if;
end process;

end rtl;

