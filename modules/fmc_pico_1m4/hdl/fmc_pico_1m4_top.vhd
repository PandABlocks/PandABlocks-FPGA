-- Interface to CAENels FMC-Pico-1M4 Four Channel ADC

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

entity fmc_pico_1m4_top is
    generic (
        CLOCK_DIVISOR : natural := 5;
        DATA_BITS : natural := 20
    );
    port (
        clk_i               : in std_ulogic;

        -- Capture control
        start_i             : in std_ulogic;
        busy_o              : out std_ulogic;
        -- Data returned
        valid_o             : out std_ulogic;       -- Strobed on data ready out
        data_o              : out signed_array(0 to 3)(DATA_BITS-1 downto 0);
        -- Range selection
        range_i             : in std_ulogic_vector(0 to 3);

        -- FMC
        FMC                 : view FMC_Module
    );
end;

architecture arch of fmc_pico_1m4_top is
    signal cnv : std_ulogic;
    signal sck : std_ulogic;
    signal sck_rtrn : std_ulogic;
    signal sdo : std_ulogic_vector(0 to 3);
    signal busy_cmn : std_ulogic;

begin
    io : entity work.fmc_pico_1m4_io port map (
        FMC_LA_P => FMC.FMC_LA_P,
        FMC_LA_N => FMC.FMC_LA_N,

        cnv_i => cnv,
        sck_i => sck,
        sck_rtrn_o => sck_rtrn,
        sdo_o => sdo,
        busy_cmn_o => busy_cmn,

        r_i => range_i,

        -- The LEDs are futile as they're not on the front panel
        led_i => "00",

        -- I2C interface currently unused
        a_scl_i => '1',
        a_scl_o => open,
        a_sda_i => '1',
        a_sda_o => open
    );


    capture : entity work.fmc_pico_1m4_capture generic map (
        CLOCK_DIVISOR => CLOCK_DIVISOR,
        DATA_BITS => DATA_BITS
    ) port map (
        clk_i => clk_i,

        cnv_o => cnv,
        sck_o => sck,
        sck_rtrn_i => sck_rtrn,
        sdo_i => sdo,
        busy_cmn_i => busy_cmn,

        start_i => start_i,
        busy_o => busy_o,
        valid_o => valid_o,
        data_o => data_o
    );
end;
