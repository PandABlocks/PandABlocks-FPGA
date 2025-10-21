-- Interface to CAENels FMC-Pico-1M4 Low Current ADC

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

entity fmc_pico_1m4_io is
    port (
        -- FMC -----------------------------------------------------------------
        FMC_LA_P : inout std_logic_vector(0 to 33);
        FMC_LA_N : inout std_logic_vector(0 to 33);

        -- ADC Interface
        cnv_i : in std_ulogic;                  -- Start conversion on edge
        sck_i : in std_ulogic;                  -- Serial clock for result
        sck_rtrn_o : out std_ulogic;            -- Return clock data aligned
        sdo_o : out std_ulogic_vector(0 to 3);  -- Data output from ADCs
        busy_cmn_o : out std_ulogic;            -- Busy during conversion
        -- Range Selection
        r_i : in std_ulogic_vector(0 to 3);     -- Range selection per ADC
        -- LEDs
        led_i : in std_ulogic_vector(1 downto 0);
        -- I2C interface to Application EEPROM
        a_scl_i : in std_ulogic;                -- I2C clock
        a_scl_o : out std_ulogic;               -- I2C return
        a_sda_i : in std_ulogic;                -- Data out (open collector)
        a_sda_o : out std_ulogic                -- Data in from I2C
    );
end;

architecture arch of fmc_pico_1m4_io is
    -- The following rather strange selection of pins are assigned, we'll need
    -- to set all the rest to high impedance.
    constant USED_IOS : boolean_array(0 to 33) := (
        2 to 5 | 7 to 8 | 11 | 23 => true,
        others => false);

    signal sdo_out : std_ulogic_vector(3 downto 0);

begin
    -- Ensure inputs don't get flagged as 'U' in simulation
    -- pragma translate_off
    FMC_LA_P <= (others => 'Z');
    FMC_LA_N <= (others => 'Z');
    -- pragma translate_on


    -- Set all unused pins to high impedance.
    gen_unused : for n in USED_IOS'RANGE generate
        test_used : if not USED_IOS(n) generate
            FMC_LA_P(n) <= 'Z';
            FMC_LA_N(n) <= 'Z';
        end generate;
    end generate;


    -- Clock and conversion request
    -- cnv_sck : entity work.obuf_array generic map (
    --     COUNT => 2,
    --     IOSTANDARD => "LVCMOS18"
    -- ) port map (
    --     i_i(0) => cnv_i,
    --     i_i(1) => sck_i,
    --     o_o(0) => FMC_LA_P(4),
    --     o_o(1) => FMC_LA_N(4)
    -- );
    
    -- Clock and conversion request
    cnv_buf: OBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map(
        I => cnv_i,
        O => FMC_LA_P(4)
    )

    sck_buf : OBUF generip map(
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => sck_i,
        O => FMC_LA_N(4)
    )


    -- Conversion status and data clock
    -- busy_sck : entity work.ibuf_array generic map (
    --     COUNT => 2,
    --     IOSTANDARD => "LVCMOS18"
    -- ) port map (
    --     i_i(0) => FMC_LA_N(8),
    --     i_i(1) => FMC_LA_P(8),
    --     o_o(0) => busy_cmn_o,
    --     o_o(1) => sck_rtrn_o
    -- );

    -- Conversion status and data clock
    busy_buf_array : IBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => FMC_LA_N(8),
        O => busy_cmn_o
    )

    sck_buf_array : IBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => FMC_LA_P(8),
        O => sck_rtrn_o
    )

    -- Converted data
    -- adc_data : entity work.ibuf_array generic map (
    --     COUNT => 4,
    --     IOSTANDARD => "LVCMOS18"
    -- ) port map (
    --     i_i(0) => FMC_LA_N(11),
    --     i_i(1) => FMC_LA_P(11),
    --     i_i(2) => FMC_LA_N(7),
    --     i_i(3) => FMC_LA_P(7),
    --     o_o => sdo_out
    -- );
    -- sdo_o <= reverse(sdo_out);

    -- Converted data
    conv_array_1 : IBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => FMC_LA_N(11),
        0 => sdo_out(0)
    )

    conv_array_2 : IBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => FMC_LA_P(11),
        0 => sdo_out(1)
    )

    conv_array_3 : IBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => FMC_LA_N(7),
        0 => sdo_out(2)
    )

    conv_array_4 : IBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => FMC_LA_P(7),
        O => sdo_out(3)
    )
    
    sdo_o <= reverse(sdo_out);

    -- ADC range selection
    -- adc_range : entity work.obuf_array generic map (
    --     COUNT => 4,
    --     IOSTANDARD => "LVCMOS18"
    -- ) port map (
    --     i_i => reverse(r_i),
    --     o_o(0) => FMC_LA_N(3),
    --     o_o(1) => FMC_LA_P(3),
    --     o_o(2) => FMC_LA_N(2),
    --     o_o(3) => FMC_LA_P(2)
    -- );
    
    adc_range_1: OBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => r_i(3),
        O => FMC_LA_N(3)
    )

    adc_range_2: OBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => r_i(2),
        O => FMC_LA_P(3)
    )

    adc_range_3: OBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => r_i(1),
        O => FMC_LA_N(2)
    )

    adc_range_4: OBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => r_i(0),
        O => FMC_LA_P(2)
    )

    -- LEDs (somewhat futile as they're placed where they are invisible)
    -- leds : entity work.obuf_array generic map (
    --     COUNT => 2,
    --     IOSTANDARD => "LVCMOS18"
    -- ) port map (
    --     i_i => led_i,
    --     o_o(0) => FMC_LA_P(5),
    --     o_o(1) => FMC_LA_N(5)
    -- );

    -- I2C interface, configured to operate in open collector mode
    -- i2c : entity work.iobuf_array generic map (
    --     COUNT => 2,
    --     IOSTANDARD => "LVCMOS18"
    -- ) port map (
    --     i_i => "00",
    --     o_o(0) => a_scl_o,
    --     o_o(1) => a_sda_o,
    --     t_i(0) => a_scl_i,
    --     t_i(1) => a_sda_i,
    --     io_io(0) => FMC_LA_P(23),
    --     io_io(1) => FMC_LA_N(23)
    -- );

    i2c_buf_scl: IOBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => "0",
        O => a_scl_o,
        T => a_scl_i,
        IO => FMC_LA_P(23)
    )

    i2c_buf_sda: IOBUF generic map (
        IOSTANDARD => "LVCMOS18"
    ) port map (
        I => "0",
        O => a_sda_o,
        T => a_sda_i,
        IO => FMC_LA_N(23)
    )
end;
