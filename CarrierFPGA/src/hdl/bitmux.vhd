--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : BITS block provides 4 user configurable soft inputs.
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

entity bitmux is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    sysbus_i            : in  sysbus_t;
    bit_o               : out std_logic;
    -- Block Parameters
    BITMUX_SEL          : in  std_logic_vector(31 downto 0);
    BIT_DLY             : in  std_logic_vector(31 downto 0)
);
end bitmux;

architecture rtl of bitmux is

signal pulse            : std_logic;

begin

-- Select bit on the system bus.
pulse <= SBIT(sysbus_i, BITMUX_SEL(SBUSBW-1 downto 0));

-- Apply delay. BIT_DLY = 0 1 clock delay which is absorbed as
-- system_bus delay.
SRLC32E_inst : SRLC32E
port map (
    Q       => bit_o,
    Q31     => open,
    A       => BIT_DLY(4 downto 0),
    CE      => '1',
    CLK     => clk_i,
    D       => pulse
);

end rtl;


