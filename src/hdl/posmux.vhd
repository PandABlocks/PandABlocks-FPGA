--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : POSS block provides 4 user configurable soft inputs.
--                Soft inputs are controlled through register interface.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;

entity posmux is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    posbus_i            : in  posbus_t;
    posn_o              : out std_logic_vector(31 downto 0);
    -- Block Parameters
    POSMUX_SEL          : in  std_logic_vector(31 downto 0);
    POS_DLY             : in  std_logic_vector(31 downto 0)
);
end posmux;

architecture rtl of posmux is

signal posn             : std_logic_vector(31 downto 0);

begin

-- Select bit on the system bus.
posn <= PFIELD(posbus_i, POSMUX_SEL(PBUSBW-1 downto 0));

-- Apply delay. POS_DLY = 0 1 clock delay which is absorbed as
-- system_bus delay.

DLY_GEN : for I in 0 to 31 generate
    SRLC32E_inst : SRLC32E
    port map (
        Q       => posn_o(I),
        Q31     => open,
        A       => POS_DLY(4 downto 0),
        CE      => '1',
        CLK     => clk_i,
        D       => posn(I)
    );
end generate;

end rtl;


