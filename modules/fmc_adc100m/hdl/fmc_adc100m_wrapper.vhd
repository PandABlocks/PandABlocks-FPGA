--------------------------------------------------------------------------------
--  NAMC-ZYNQ-FMC - 2022
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Description   : Wrapper file of the FMC 14bits 100MSPS 4-channel ADC module
--
--  Author        : Thierry Garrel (ELSYS-Design)
--  Synthesizable : Yes
--  Language      : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2022 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.fmc_adc_types.all;

--------------------------------------------------------------------------------
-- Entity declaration
--------------------------------------------------------------------------------
entity fmc_adc100m_wrapper is
port (
    -- Clock and Reset from PS core (125 mhz)
    clk_i               : in  std_logic; -- FCLK_CLK0_PS
    reset_i             : in  std_logic; -- FCLK_RESET0
    -- On Board clocks
    clk_app0_i          : in  std_logic;

    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Outputs to Bit_Bus from FMC
    EXT_TRIG_o          : out std_logic_vector(0 downto 0);
    -- Outputs to Pos_Bus from FMC
    VAL1_o              : out std32_array(0 downto 0);
    VAL2_o              : out std32_array(0 downto 0);
    VAL3_o              : out std32_array(0 downto 0);
    VAL4_o              : out std32_array(0 downto 0);

    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic := '1';
    FMC_i               : in    fmc_input_interface;
    FMC_io              : inout fmc_inout_interface
);
end fmc_adc100m_wrapper;

--------------------------------------------------------------------------------
-- Architecture declaration
--------------------------------------------------------------------------------
architecture rtl of fmc_adc100m_wrapper is

------------------------------------------------------------------------------
-- Types declaration
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- Signals declaration
------------------------------------------------------------------------------
signal sys_clk_125            : std_logic;
signal sys_reset              : std_logic;

-- ADC interface (LTC2174)
signal adc_dco_n_i            : std_logic; -- ADC Clock data out
signal adc_dco_p_i            : std_logic;
signal adc_fr_n_i             : std_logic; -- ADC Frame start
signal adc_fr_p_i             : std_logic;
signal adc_outa_n_i           : std_logic_vector(3 downto 0); -- ADC serial data in (odd bits)
signal adc_outa_p_i           : std_logic_vector(3 downto 0);
signal adc_outb_n_i           : std_logic_vector(3 downto 0); -- ADC serial data in (even bits)
signal adc_outb_p_i           : std_logic_vector(3 downto 0);

signal gpio_si570_oe_o        : std_logic;                     -- Si570 programmable oscillator output enable (active high)
signal gpio_dac_clr_n_o       : std_logic;                     -- offset DACs clear (active low)
signal gpio_led_acq_o         : std_logic;                     -- Mezzanine front panel power LED (PWR)
signal gpio_led_trig_o        : std_logic;                     -- Mezzanine front panel trigger LED (TRIG)
signal gpio_ssr_ch1_o         : std_logic_vector(6 downto 0);  -- Channel 1 solid state relays control
signal gpio_ssr_ch2_o         : std_logic_vector(6 downto 0);  -- Channel 2 solid state relays control
signal gpio_ssr_ch3_o         : std_logic_vector(6 downto 0);  -- Channel 3 solid state relays control
signal gpio_ssr_ch4_o         : std_logic_vector(6 downto 0);  -- Channel 4 solid state relays control
signal spi_din_i              : std_logic;    -- SPI data from FMC
signal spi_dout_o             : std_logic;    -- SPI data to FMC
signal spi_sck_o              : std_logic;    -- SPI clock
signal spi_cs_adc_n_o         : std_logic;    -- SPI ADC chip select (active low)
signal spi_cs_dac1_n_o        : std_logic;    -- SPI channel 1 offset DAC chip select (active low)
signal spi_cs_dac2_n_o        : std_logic;    -- SPI channel 2 offset DAC chip select (active low)
signal spi_cs_dac3_n_o        : std_logic;    -- SPI channel 3 offset DAC chip select (active low)
signal spi_cs_dac4_n_o        : std_logic;    -- SPI channel 4 offset DAC chip select (active low)
signal si570_scl_b            : std_logic;    -- I2C bus clock (Si570)
signal si570_sda_b            : std_logic;    -- I2C bus data (Si570)
signal mezz_one_wire_b        : std_logic;    -- Mezzanine 1-wire interface (DS18B20 thermometer + unique
signal ext_trigger_p_i        : std_logic;    -- External trigger
signal ext_trigger_n_i        : std_logic;    -- External trigger


-- ************************
-- *** FMC_adc100m_ctrl ***
-- ************************
-- ADC registers (LTC2174)
signal ADC_RESET              : std_logic_vector(31 downto 0);
signal ADC_RESET_wstb         : std_logic;
signal ADC_TWOSCOMP           : std_logic_vector(31 downto 0);
signal ADC_TWOSCOMP_wstb      : std_logic;
signal ADC_MODE               : std_logic_vector(31 downto 0);
signal ADC_MODE_wstb          : std_logic;
signal ADC_TEST_MSB           : std_logic_vector(31 downto 0);
signal ADC_TEST_MSB_wstb      : std_logic;
signal ADC_TEST_LSB           : std_logic_vector(31 downto 0);
signal ADC_TEST_LSB_wstb      : std_logic;
signal ADC_SPI_READ_ADDR      : std_logic_vector(31 downto 0);
signal ADC_SPI_READ_ADDR_wstb : std_logic;
signal ADC_SPI_READ_VALUE     : std_logic_vector(31 downto 0);
-- DAC registers MAX5442 (x4)
signal DAC_1_OFFSET           : std_logic_vector(31 downto 0);
signal DAC_2_OFFSET           : std_logic_vector(31 downto 0);
signal DAC_3_OFFSET           : std_logic_vector(31 downto 0);
signal DAC_4_OFFSET           : std_logic_vector(31 downto 0);
signal DAC_1_OFFSET_wstb      : std_logic;
signal DAC_2_OFFSET_wstb      : std_logic;
signal DAC_3_OFFSET_wstb      : std_logic;
signal DAC_4_OFFSET_wstb      : std_logic;
signal DAC_OFFSET_ENABLE      : std_logic_vector(31 downto 0);
-- BITSLIP monitor
signal BITSLIP_MONITOR_EN     : std_logic; -- BITSLIP_MONITOR_from_bus
-- Pattern Generator
signal PATGEN_ENABLE          : std_logic_vector(31 downto 0);
signal PATGEN_RESET           : std_logic_vector(31 downto 0);
signal PATGEN_PERIOD          : std_logic_vector(31 downto 0);
signal PATGEN_PERIOD_wstb     : std_logic;
-- FIFO input selection
signal FIFO_INPUT_SEL         : std_logic_vector(31 downto 0); -- "00" serdes "01" offse_ gain "10" pattern_generator
-- SERDES Control and Status
signal serdes_reset           : std_logic_vector(31 downto 0);
signal refclk_locked_sta      : std_logic_vector(31 downto 0);
signal idelay_locked_sta      : std_logic_vector(31 downto 0);
signal serdes_synced_sta      : std_logic_vector(31 downto 0);
signal bitslip_error_sta      : std_logic_vector(31 downto 0);
-- Gain/Offset/Saturation registers
signal FMC_GAIN1              : std_logic_vector(31 downto 0);
signal FMC_GAIN2              : std_logic_vector(31 downto 0);
signal FMC_GAIN3              : std_logic_vector(31 downto 0);
signal FMC_GAIN4              : std_logic_vector(31 downto 0);
signal FMC_OFFSET1            : std_logic_vector(31 downto 0);
signal FMC_OFFSET2            : std_logic_vector(31 downto 0);
signal FMC_OFFSET3            : std_logic_vector(31 downto 0);
signal FMC_OFFSET4            : std_logic_vector(31 downto 0);
signal FMC_SAT1               : std_logic_vector(31 downto 0);
signal FMC_SAT2               : std_logic_vector(31 downto 0);
signal FMC_SAT3               : std_logic_vector(31 downto 0);
signal FMC_SAT4               : std_logic_vector(31 downto 0);
-- SSR control registers (except Bit 3). Controls input voltage range and DC offset error calibration.
signal CH1_RANGE              : std_logic_vector(31 downto 0);
signal CH2_RANGE              : std_logic_vector(31 downto 0);
signal CH3_RANGE              : std_logic_vector(31 downto 0);
signal CH4_RANGE              : std_logic_vector(31 downto 0);
-- SSR Input Termination. Controls Bit 3 of SSR control register.
signal CH1_TERM               : std_logic_vector(31 downto 0);
signal CH2_TERM               : std_logic_vector(31 downto 0);
signal CH3_TERM               : std_logic_vector(31 downto 0);
signal CH4_TERM               : std_logic_vector(31 downto 0);

-- 4ch SERDES output (sys_clk clock domain). Sign extension from 16-bit to 32-bit.
-- For debug purpose ONLY (simple 2FF Synchronizer between adc_clk and sys_clk)
signal RAW_VAL1_reg           : std_logic_vector(31 downto 0);
signal RAW_VAL2_reg           : std_logic_vector(31 downto 0);
signal RAW_VAL3_reg           : std_logic_vector(31 downto 0);
signal RAW_VAL4_reg           : std_logic_vector(31 downto 0);
-- FIFO data output (fmc_adc100m_core output). Sign extension from 16-bit to 32-bit.
signal VAL1_reg               : std_logic_vector(31 downto 0);
signal VAL2_reg               : std_logic_vector(31 downto 0);
signal VAL3_reg               : std_logic_vector(31 downto 0);
signal VAL4_reg               : std_logic_vector(31 downto 0);
-- Si570 clock enable (active high)
signal FMC_CLK_OE             : std_logic_vector(31 downto 0);


-- Begin of code
begin
--------------------------------------------------------------------------------
-- Translate the FMC pin names into fmc_adc_mezzanine names
--------------------------------------------------------------------------------
---------------
-- ADC
---------------
adc_dco_n_i         <= FMC_io.FMC_LA_N(0);  -- ADC_DCO+ data clock (inverted on board)
adc_dco_p_i         <= FMC_io.FMC_LA_P(0);  -- ADC_DCO-
adc_fr_n_i          <= FMC_io.FMC_LA_N(1);  -- ADC_FR+  frame start (inverted on board)
adc_fr_p_i          <= FMC_io.FMC_LA_P(1);  -- ADC_FR-
adc_outa_n_i(0)     <= FMC_io.FMC_LA_N(14); -- ADC_OUT1A serial data (odd  bits channel 1)
adc_outa_p_i(0)     <= FMC_io.FMC_LA_P(14);
adc_outb_n_i(0)     <= FMC_io.FMC_LA_N(15); -- ADC_OUT1B serial data (even bits channel 1)
adc_outb_p_i(0)     <= FMC_io.FMC_LA_P(15);
adc_outa_n_i(1)     <= FMC_io.FMC_LA_N(16); -- ADC_OUT2A serial data (odd  bits channel 2)
adc_outa_p_i(1)     <= FMC_io.FMC_LA_P(16);
adc_outb_n_i(1)     <= FMC_io.FMC_LA_N(13); -- ADC_OUT2B serial data (even bits channel 2)
adc_outb_p_i(1)     <= FMC_io.FMC_LA_P(13);
adc_outa_n_i(2)     <= FMC_io.FMC_LA_N(10); -- ADC_OUT3A serial data (odd  bits channel 3)
adc_outa_p_i(2)     <= FMC_io.FMC_LA_P(10);
adc_outb_n_i(2)     <= FMC_io.FMC_LA_N(9);  -- ADC_OUT3B serial data (even bits channel 3)
adc_outb_p_i(2)     <= FMC_io.FMC_LA_P(9);
adc_outa_n_i(3)     <= FMC_io.FMC_LA_N(7);  -- ADC_OUT4A serial data (odd  bits channel 4)
adc_outa_p_i(3)     <= FMC_io.FMC_LA_P(7);
adc_outb_n_i(3)     <= FMC_io.FMC_LA_N(5);  -- ADC_OUT4B serial data (even bits channel 4)
adc_outb_p_i(3)     <= FMC_io.FMC_LA_P(5);
---------------
-- SPI
---------------
spi_din_i           <= FMC_io.FMC_LA_P(25); -- SPI data from FMC (SPI_ADC_SDO)
FMC_io.FMC_LA_N(31) <= spi_dout_o     ; -- SPI_DIN FMC-ADC-100M
FMC_io.FMC_LA_P(31) <= spi_sck_o      ; -- SPI_SCK
FMC_io.FMC_LA_P(30) <= spi_cs_adc_n_o ; -- ADC_CS_N
FMC_io.FMC_LA_P(32) <= spi_cs_dac1_n_o; -- DAC1_CS_N
FMC_io.FMC_LA_N(32) <= spi_cs_dac2_n_o; -- DAC2_CS_N
FMC_io.FMC_LA_P(33) <= spi_cs_dac3_n_o; -- DAC3_CS_N
FMC_io.FMC_LA_N(33) <= spi_cs_dac4_n_o; -- DAC4_CS_N
---------------
-- GPIO
---------------
FMC_io.FMC_LA_N(30) <= gpio_dac_clr_n_o ; -- asynchronously clear DAC outputs to code 32768 (active low)
FMC_io.FMC_LA_N(28) <= gpio_led_acq_o   ;
FMC_io.FMC_LA_P(28) <= gpio_led_trig_o  ;
FMC_io.FMC_LA_P(26) <= gpio_ssr_ch1_o(0);
FMC_io.FMC_LA_N(26) <= gpio_ssr_ch1_o(1);
FMC_io.FMC_LA_N(27) <= gpio_ssr_ch1_o(2);
FMC_io.FMC_LA_N(25) <= gpio_ssr_ch1_o(3);
FMC_io.FMC_LA_P(24) <= gpio_ssr_ch1_o(4);
FMC_io.FMC_LA_N(24) <= gpio_ssr_ch1_o(5);
FMC_io.FMC_LA_P(29) <= gpio_ssr_ch1_o(6);
FMC_io.FMC_LA_P(20) <= gpio_ssr_ch2_o(0);
FMC_io.FMC_LA_N(19) <= gpio_ssr_ch2_o(1);
FMC_io.FMC_LA_P(22) <= gpio_ssr_ch2_o(2);
FMC_io.FMC_LA_N(22) <= gpio_ssr_ch2_o(3);
FMC_io.FMC_LA_P(21) <= gpio_ssr_ch2_o(4);
FMC_io.FMC_LA_P(27) <= gpio_ssr_ch2_o(5);
FMC_io.FMC_LA_N(21) <= gpio_ssr_ch2_o(6);
FMC_io.FMC_LA_P(8)  <= gpio_ssr_ch3_o(0);
FMC_io.FMC_LA_N(8)  <= gpio_ssr_ch3_o(1);
FMC_io.FMC_LA_P(12) <= gpio_ssr_ch3_o(2);
FMC_io.FMC_LA_N(12) <= gpio_ssr_ch3_o(3);
FMC_io.FMC_LA_P(11) <= gpio_ssr_ch3_o(4);
FMC_io.FMC_LA_N(11) <= gpio_ssr_ch3_o(5);
FMC_io.FMC_LA_N(20) <= gpio_ssr_ch3_o(6);
FMC_io.FMC_LA_P(2)  <= gpio_ssr_ch4_o(0);
FMC_io.FMC_LA_N(2)  <= gpio_ssr_ch4_o(1);
FMC_io.FMC_LA_P(3)  <= gpio_ssr_ch4_o(2);
FMC_io.FMC_LA_N(3)  <= gpio_ssr_ch4_o(3);
FMC_io.FMC_LA_P(4)  <= gpio_ssr_ch4_o(4);
FMC_io.FMC_LA_P(6)  <= gpio_ssr_ch4_o(5);
FMC_io.FMC_LA_N(4)  <= gpio_ssr_ch4_o(6);
FMC_io.FMC_LA_N(6)  <= gpio_si570_oe_o  ;

si570_scl_b         <= FMC_io.FMC_LA_N(18);
si570_sda_b         <= FMC_io.FMC_LA_P(18);
mezz_one_wire_b     <= FMC_io.FMC_LA_N(29);

ext_trigger_p_i     <= FMC_io.FMC_LA_P(17);
ext_trigger_n_i     <= FMC_io.FMC_LA_N(17);

sys_clk_125         <= clk_i;
sys_reset           <= reset_i;


--------------------------------------------------------
-- fmc_adc_mezzanine instanciation
--------------------------------------------------------
cmp_fmc_adc_mezzanine : entity work.fmc_adc_mezzanine
  generic map (
    g_multishot_ram_size  => 128,   --512,--1024,--2048,
    g_DEBUG_ILA           => TRUE
  )
  port map (
    -- System clock and reset from PS core (125 mhz)
    sys_clk_i             => sys_clk_125,
    sys_reset_i           => sys_reset,

    -- On board clock (100 mhz)
    clk_100_i             => clk_app0_i,

    -- **********************
    -- *** FMC interface  ***
    -- **********************
    -- ADC interface (LTC2174)
    adc_dco_p_i           => adc_dco_p_i,
    adc_dco_n_i           => adc_dco_n_i,
    adc_fr_p_i            => adc_fr_p_i,
    adc_fr_n_i            => adc_fr_n_i,
    adc_outa_p_i          => adc_outa_p_i,
    adc_outa_n_i          => adc_outa_n_i,
    adc_outb_p_i          => adc_outb_p_i,
    adc_outb_n_i          => adc_outb_n_i,

    --gpio_dac_clr_n_o    => gpio_dac_clr_n_o,
    gpio_led_acq_o        => gpio_led_acq_o,
    gpio_led_trig_o       => gpio_led_trig_o,
    --gpio_si570_oe_o     => gpio_si570_oe_o,

    -- Mezzanine SPI
    spi_din_i             => spi_din_i,
    spi_dout_o            => spi_dout_o,
    spi_sck_o             => spi_sck_o,
    spi_cs_adc_n_o        => spi_cs_adc_n_o,
    spi_cs_dac1_n_o       => spi_cs_dac1_n_o,
    spi_cs_dac2_n_o       => spi_cs_dac2_n_o,
    spi_cs_dac3_n_o       => spi_cs_dac3_n_o,
    spi_cs_dac4_n_o       => spi_cs_dac4_n_o,
    -- Mezzanine I2C (Si570)
    si570_scl_b           => si570_scl_b,
    si570_sda_b           => si570_sda_b,
    -- Mezzanine 1-wire (DS18B20)
    mezz_one_wire_b       => mezz_one_wire_b,
    -- Mezzanine system I2C (EEPROM)
    --sys_scl_b           => open,
    --sys_sda_b           => open,

    -- External trigger
    ext_trigger_p_i       => ext_trigger_p_i,
    ext_trigger_n_i       => ext_trigger_n_i,

    -- ************************
    -- *** FMC_ADC100M_CTRL ***
    -- ************************
    -- ADC registers (LTC2174)
    ADC_RESET               => ADC_RESET(0),
    ADC_RESET_wstb          => ADC_RESET_wstb,
    ADC_TWOSCOMP            => ADC_TWOSCOMP(0),
    ADC_TWOSCOMP_wstb       => ADC_TWOSCOMP_wstb,
    ADC_MODE                => ADC_MODE(7 downto 0),
    ADC_MODE_wstb           => ADC_MODE_wstb,
    ADC_TEST_MSB            => ADC_TEST_MSB(7 downto 0),
    ADC_TEST_MSB_wstb       => ADC_TEST_MSB_wstb,
    ADC_TEST_LSB            => ADC_TEST_LSB(7 downto 0),
    ADC_TEST_LSB_wstb       => ADC_TEST_LSB_wstb,
    ADC_SPI_READ_ADDR       => ADC_SPI_READ_ADDR(2 downto 0),
    ADC_SPI_READ_ADDR_wstb  => ADC_SPI_READ_ADDR_wstb,
    ADC_SPI_READ_VALUE      => ADC_SPI_READ_VALUE,
    -- DAC registers MAX5442 (x4)
    DAC_1_OFFSET            => DAC_1_OFFSET,
    DAC_2_OFFSET            => DAC_2_OFFSET,
    DAC_3_OFFSET            => DAC_3_OFFSET,
    DAC_4_OFFSET            => DAC_4_OFFSET,
    DAC_1_OFFSET_wstb       => DAC_1_OFFSET_wstb,
    DAC_2_OFFSET_wstb       => DAC_2_OFFSET_wstb,
    DAC_3_OFFSET_wstb       => DAC_3_OFFSET_wstb,
    DAC_4_OFFSET_wstb       => DAC_4_OFFSET_wstb,
    -- BITSLIP Monitor
    BITSLIP_MONITOR_EN      => BITSLIP_MONITOR_EN,
    -- Pattern Generator
    PATGEN_ENABLE           => PATGEN_ENABLE(0),
    PATGEN_RESET            => PATGEN_RESET(0),
    PATGEN_PERIOD           => PATGEN_PERIOD,
    PATGEN_PERIOD_wstb      => PATGEN_PERIOD_wstb,
    -- FIFO input selection
    FIFO_INPUT_SEL          => FIFO_INPUT_SEL(1 downto 0),
    -- Gain/offset calibration parameters
    FMC_GAIN1               => FMC_GAIN1(15 downto 0),
    FMC_GAIN2               => FMC_GAIN2(15 downto 0),
    FMC_GAIN3               => FMC_GAIN3(15 downto 0),
    FMC_GAIN4               => FMC_GAIN4(15 downto 0),
    FMC_OFFSET1             => FMC_OFFSET1(15 downto 0),
    FMC_OFFSET2             => FMC_OFFSET2(15 downto 0),
    FMC_OFFSET3             => FMC_OFFSET3(15 downto 0),
    FMC_OFFSET4             => FMC_OFFSET4(15 downto 0),
    FMC_SAT1                => FMC_SAT1(14 downto 0),
    FMC_SAT2                => FMC_SAT2(14 downto 0),
    FMC_SAT3                => FMC_SAT3(14 downto 0),
    FMC_SAT4                => FMC_SAT4(14 downto 0),
    -- SERDES Ctrl and Status (sys_clk domain)
    serdes_arst_i           => serdes_reset(0),
    refclk_locked_o         => refclk_locked_sta(0),
    idelay_locked_o         => idelay_locked_sta(0),
    serdes_synced_o         => serdes_synced_sta(0),
    bitslip_error_o         => bitslip_error_sta(0),

    -- ************************
    -- ** Outputs to Bit_Bus **
    -- ************************
    EXT_TRIG_o             => EXT_TRIG_o(0),

    -- ************************
    -- ** Outputs to Pos_Bus **
    -- ************************

    -- 4ch SERDES output (sys_clk clock domain).
    -- Simple 2FF synchronizer between adc_clk and sys_clk
    RAW_VAL1_o            => RAW_VAL1_reg,      -- out (31:0)
    RAW_VAL2_o            => RAW_VAL2_reg,      -- out (31:0)
    RAW_VAL3_o            => RAW_VAL3_reg,      -- out (31:0)
    RAW_VAL4_o            => RAW_VAL4_reg,      -- out (31:0)

    -- 4ch FIFO output (sys_clk clock domain).
    -- for connection to Position Bus (pos_bus).
    FIFO_CH1_o            => VAL1_reg,          -- out (31:0)
    FIFO_CH2_o            => VAL2_reg,          -- out (31:0)
    FIFO_CH3_o            => VAL3_reg,          -- out (31:0)
    FIFO_CH4_o            => VAL4_reg,          -- out (31:0)
    FIFO_Valid_o          => open               -- out

); -- cmp_fmc_adc_mezzanine


-- ************************
-- ** Outputs to Pos_Bus **
-- ************************
VAL1_o(0)     <= VAL1_reg;
VAL2_o(0)     <= VAL2_reg;
VAL3_o(0)     <= VAL3_reg;
VAL4_o(0)     <= VAL4_reg;


-- SSR control registers. Controls input voltage range and DC offset error calibration.
gpio_ssr_ch1_o <= CH1_RANGE(6 downto 4) & CH1_TERM(0) & CH1_RANGE(2 downto 0);
gpio_ssr_ch2_o <= CH2_RANGE(6 downto 4) & CH2_TERM(0) & CH2_RANGE(2 downto 0);
gpio_ssr_ch3_o <= CH3_RANGE(6 downto 4) & CH3_TERM(0) & CH3_RANGE(2 downto 0);
gpio_ssr_ch4_o <= CH4_RANGE(6 downto 4) & CH4_TERM(0) & CH4_RANGE(2 downto 0);

--
gpio_si570_oe_o  <= FMC_CLK_OE(0);            -- Si570 programmable oscillator output enable (active high)
gpio_dac_clr_n_o <= DAC_OFFSET_ENABLE(0);     -- asynchronously clear DAC outputs to code 32768 (active low)




--------------------------------------------------------
-- fmc_adc100m_ctrl instanciation
--------------------------------------------------------
cmp_fmc_adc100m_ctrl : entity work.fmc_adc100m_ctrl
port map (
    -- Clock and Reset
    clk_i                   => sys_clk_125,           --  in
    reset_i                 => sys_reset,             --  in
    bit_bus_i               => bit_bus_i,             --  in  bit_bus_t
    pos_bus_i               => pos_bus_i,             --  in  pos_bus_t
    -- Block Parameters
    -- Current ADC raw value (SerDes output) signed 14 bits
    RAW_VAL1                => RAW_VAL1_reg,          -- in (31:0)
    RAW_VAL2                => RAW_VAL2_reg,          -- in (31:0)
    RAW_VAL3                => RAW_VAL3_reg,          -- in (31:0)
    RAW_VAL4                => RAW_VAL4_reg,          -- in (31:0)
    -- SSR control registers (except bit 3). Controls input voltage range and DC offset error calibration.
    CH1_INPUT_RANGE         => CH1_RANGE,             -- out (31:0)
    CH2_INPUT_RANGE         => CH2_RANGE,             -- out (31:0)
    CH3_INPUT_RANGE         => CH3_RANGE,             -- out (31:0)
    CH4_INPUT_RANGE         => CH4_RANGE,             -- out (31:0)
    CH1_INPUT_RANGE_wstb    => open,                  -- out
    CH2_INPUT_RANGE_wstb    => open,                  -- out
    CH3_INPUT_RANGE_wstb    => open,                  -- out
    CH4_INPUT_RANGE_wstb    => open,                  -- out
    -- Input Termination control register. Controls bit 3 of Channel SSR register.
    CH1_TERM                => CH1_TERM,                -- out (31:0)
    CH2_TERM                => CH2_TERM,                -- out (31:0)
    CH3_TERM                => CH3_TERM,                -- out (31:0)
    CH4_TERM                => CH4_TERM,                -- out (31:0)
    CH1_TERM_wstb           => open,                    -- out
    CH2_TERM_wstb           => open,                    -- out
    CH3_TERM_wstb           => open,                    -- out
    CH4_TERM_wstb           => open,                    -- out
    -- Programmable OSC (Si570)
    OSC_ENABLE              => FMC_CLK_OE,              -- out (31:0)
    OSC_ENABLE_wstb         => open,                    -- out
    -- LTC2174 registers
    ADC_RESET               => open,                    -- out (31:0)
    ADC_RESET_wstb          => ADC_RESET_wstb,          -- out
    ADC_TWOSCOMP            => ADC_TWOSCOMP,            -- out (31:0)
    ADC_TWOSCOMP_wstb       => ADC_TWOSCOMP_wstb,       -- out
    ADC_MODE                => open,                    -- out (31:0)
    ADC_MODE_wstb           => ADC_MODE_wstb,           -- out
    ADC_TEST_MSB            => ADC_TEST_MSB,            -- out (31:0)
    ADC_TEST_MSB_wstb       => ADC_TEST_MSB_wstb,       -- out
    ADC_TEST_LSB            => ADC_TEST_LSB,            -- out (31:0)
    ADC_TEST_LSB_wstb       => ADC_TEST_LSB_wstb,       -- out
    ADC_SPI_READ_ADDR       => ADC_SPI_READ_ADDR,       -- out (31:0)
    ADC_SPI_READ_ADDR_wstb  => ADC_SPI_READ_ADDR_wstb,  -- out
    ADC_SPI_READ_VALUE      => ADC_SPI_READ_VALUE,      -- in (31:0)
    -- DAC registers MAX5442 (x4)
    DAC_OFFSET_ENABLE       => DAC_OFFSET_ENABLE,       -- out (31:0)
    DAC_OFFSET_ENABLE_wstb  => open,                    -- out
    DAC_1_OFFSET            => DAC_1_OFFSET,            -- out (31:0)
    DAC_1_OFFSET_wstb       => DAC_1_OFFSET_wstb,       -- out
    DAC_2_OFFSET            => DAC_2_OFFSET,            -- out (31:0)
    DAC_2_OFFSET_wstb       => DAC_2_OFFSET_wstb,       -- out
    DAC_3_OFFSET            => DAC_3_OFFSET,            -- out (31:0)
    DAC_3_OFFSET_wstb       => DAC_3_OFFSET_wstb,       -- out
    DAC_4_OFFSET            => DAC_4_OFFSET,            -- out (31:0)
    DAC_4_OFFSET_wstb       => DAC_4_OFFSET_wstb,       -- out
    -- SERDES Control and Status
    SERDES_RESET            => SERDES_RESET,            -- out (31:0)
    SERDES_RESET_wstb       => open,                    -- out
    REFCLK_LOCKED           => refclk_locked_sta,       -- in (31:0)
    IDELAY_LOCKED           => idelay_locked_sta,       -- in (31:0)
    SERDES_SYNCED           => serdes_synced_sta,       -- in (31:0)
    -- BITSLIP monitor
    BITSLIP_MONITOR_from_bus  => BITSLIP_MONITOR_EN,    -- out
    BITSLIP_ERROR             => bitslip_error_sta,     -- in (31:0)
    -- Pattern Generator
    PATGEN_ENABLE           => PATGEN_ENABLE,           -- out (31:0)
    PATGEN_ENABLE_wstb      => open,                    -- out    :
    PATGEN_RESET            => PATGEN_RESET,            -- out (31:0)
    PATGEN_RESET_wstb       => open,                    -- out    :
    PATGEN_PERIOD           => PATGEN_PERIOD,           -- out (31:0)
    PATGEN_PERIOD_wstb      => PATGEN_PERIOD_wstb,      -- out
    -- FIFO input selection
    FIFO_INPUT_SEL          => FIFO_INPUT_SEL,          -- out (31:0)
    FIFO_INPUT_SEL_wstb     => open,                    -- out
    -- Gain Offset Saturation
    GAIN1                   => FMC_GAIN1,               -- out (31:0)
    GAIN2                   => FMC_GAIN2,               -- out (31:0)
    GAIN3                   => FMC_GAIN3,               -- out (31:0)
    GAIN4                   => FMC_GAIN4,               -- out (31:0)
    OFFSET1                 => FMC_OFFSET1,             -- out (31:0)
    OFFSET2                 => FMC_OFFSET2,             -- out (31:0)
    OFFSET3                 => FMC_OFFSET3,             -- out (31:0)
    OFFSET4                 => FMC_OFFSET4,             -- out (31:0)
    SAT1                    => FMC_SAT1,                -- out (31:0)
    SAT2                    => FMC_SAT2,                -- out (31:0)
    SAT3                    => FMC_SAT3,                -- out (31:0)
    SAT4                    => FMC_SAT4,                -- out (31:0)
    -- Memory Bus Interface
    read_strobe_i           => read_strobe_i,
    read_address_i          => read_address_i(BLK_AW-1 downto 0),
    read_data_o             => read_data_o,
    read_ack_o              => read_ack_o,

    write_strobe_i          => write_strobe_i,
    write_address_i         => write_address_i(BLK_AW-1 downto 0),
    write_data_i            => write_data_i,
    write_ack_o             => open

); -- cmp_fmc_adc100m_ctrl



end rtl;
-- End of code

