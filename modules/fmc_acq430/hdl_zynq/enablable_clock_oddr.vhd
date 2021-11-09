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
cmp_ADC_SPI_CLK_ODDR : ODDR
generic map(
    DDR_CLK_EDGE    => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
    INIT         => '0', -- Initial value for Q port ('1' or '0')
    SRTYPE       => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
    Q           => clock_o, -- 1-bit DDR output
    C           => clock_i, -- 1-bit clock input
    CE          => enable_i, -- 1-bit clock enable_i input
    D1          => '1', -- 1-bit data input (positive edge)
    D2          => '0', -- 1-bit data input (negative edge)
    R           => '0', -- 1-bit reset input
    S           => '0' -- 1-bit set input
);

end rtl;
