--------------------------------------------------------------------------------
--  File:       panda_bits.vhd
--  Desc:       Position user bits.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_bits is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    zero_o              : out std_logic;
    one_o               : out std_logic;
    softa_o             : out std_logic;
    softb_o             : out std_logic;
    softc_o             : out std_logic;
    softd_o             : out std_logic;
    -- Block Parameters
    SOFTA_SET           : in  std_logic;
    SOFTB_SET           : in  std_logic;
    SOFTC_SET           : in  std_logic;
    SOFTD_SET           : in  std_logic
);
end panda_bits;

architecture rtl of panda_bits is

component panda_clockgen is
port (
    clk_i               : in  std_logic;
    clock_o             : out std_logic;
    DIV                 : in  std_logic_vector(31 downto 0)
);
end component;

begin

-- Assign block outputs
zero_o <= '0';
one_o <= '1';
softa_o <= SOFTA_SET;
softb_o <= SOFTB_SET;
softc_o <= SOFTC_SET;
softd_o <= SOFTD_SET;

end rtl;


