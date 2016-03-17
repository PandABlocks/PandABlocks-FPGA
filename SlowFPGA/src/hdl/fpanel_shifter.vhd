--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Shifts data onto the front panel shift registers (SN74HC595PW)
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.slow_defines.all;
use work.type_defines.all;

library unisim;
use unisim.vcomponents.all;

entity fpanel_shifter is
port (
    -- 50MHz system clock.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Front-Panel Control Values.
    ttlin_term_o        : out std_logic_vector(5 downto 0);
    ttl_leds_o          : out std_logic_vector(15 downto 0);
    status_leds_o       : out std_logic_vector(3 downto 0);
    -- Shift Register Interface.
    shift_reg_sdata_o   : out std_logic;
    shift_reg_sclk_o    : out std_logic;
    shift_reg_latch_o   : out std_logic;
    shift_reg_oe_n_o    : out std_logic
);
end fpanel_shifter;

architecture rtl of fpanel_shifter is

-- Number of bits to shifth
constant SHIFT_LEN      : integer := ttlin_term_o'length + ttl_leds_o'length +
                                        status_leds_o'length;
signal shift_start      : std_logic;
signal shift_clock      : std_logic;

begin

--
-- Shift data every 10msec.
--
shift_frame: entity work.prescaler
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    PERIOD          => TO_SVECTOR(500000, 32),
    pulse_o         => shift_start
);

--
-- Shift register clock rate is 1usec.
--
shift_frame: entity work.prescaler
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    PERIOD          => TO_SVECTOR(50, 32),
    pulse_o         => shift_start
);

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            shift_reg_oe_n_o <= '1';
            shift_reg_sclk_o <= '0';
            shift_reg_sdata_o <= '0';
            shift_reg_latch_o <= '0';

        else

        end if;

    end if;
end process;


end rtl;
