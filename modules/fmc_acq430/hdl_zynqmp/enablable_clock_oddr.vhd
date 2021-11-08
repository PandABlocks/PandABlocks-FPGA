library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity enablable_clock_oddr is
port (
    clock_i  : in std_logic;
    clock_o : out std_logic;
    enable_i : in std_logic
);
end enablable_clock_oddr;

architecture rtl of enablable_clock_oddr is
begin

-- Signals to the physical ADCs
cmp_ADC_SPI_CLK_ODDR : ODDRE1
port map (
    SR          => '0', -- Active High Asynchronous Reset
    C           => clock_i, -- 1-bit clock input
    Q           => clock_o, -- 1-bit DDR output
    D1          => enable_i, -- 1-bit data input (positive edge)
    D2          => '0' -- 1-bit data input (negative edge)
);

end rtl;
