--------------------------------------------------------------------------------
--  File:       panda_lut.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_lut is
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
    FUNC                : in  std_logic_vector(31 downto 0)
);
end panda_lut;

architecture rtl of panda_lut is

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

