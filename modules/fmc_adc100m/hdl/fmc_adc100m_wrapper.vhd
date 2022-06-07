--------------------------------------------------------------------------------
--  NAMC - 2021
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Arthur Mariano
--------------------------------------------------------------------------------
--
--  Description : Wrapper file of the FMC 14bits 100MSPS 4-channel ADC module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

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
    -- Outputs to PosBus from FMC
    in_data_ch1_o       : out std32_array(0 downto 0);
    in_data_ch2_o       : out std32_array(0 downto 0);
    in_data_ch3_o       : out std32_array(0 downto 0);
    in_data_ch4_o       : out std32_array(0 downto 0);

    val1_o              : out std32_array(0 downto 0);
    val2_o              : out std32_array(0 downto 0);
    val3_o              : out std32_array(0 downto 0);
    val4_o              : out std32_array(0 downto 0);

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
signal sys_clk_125          : std_logic;
signal sys_reset            : std_logic;

-- ADC interface (LTC2174)
signal adc_dco_n_i          : std_logic; -- ADC Clock data out
signal adc_dco_p_i          : std_logic;
signal adc_fr_n_i           : std_logic; -- ADC Frame start
signal adc_fr_p_i           : std_logic;
signal adc_outa_n_i         : std_logic_vector(3 downto 0); -- ADC serial data in (odd bits)
signal adc_outa_p_i         : std_logic_vector(3 downto 0);
signal adc_outb_n_i         : std_logic_vector(3 downto 0); -- ADC serial data in (even bits)
signal adc_outb_p_i         : std_logic_vector(3 downto 0);

signal gpio_si570_oe_o      : std_logic;                     -- Si570 programmable oscillator output enable (active high)
signal gpio_dac_clr_n_o     : std_logic;                     -- offset DACs clear (active low)
signal gpio_led_acq_o       : std_logic;                     -- Mezzanine front panel power LED (PWR)
signal gpio_led_trig_o      : std_logic;                     -- Mezzanine front panel trigger LED (TRIG)
signal gpio_ssr_ch1_o       : std_logic_vector(6 downto 0);  -- Channel 1 solid state relays control
signal gpio_ssr_ch2_o       : std_logic_vector(6 downto 0);  -- Channel 2 solid state relays control
signal gpio_ssr_ch3_o       : std_logic_vector(6 downto 0);  -- Channel 3 solid state relays control
signal gpio_ssr_ch4_o       : std_logic_vector(6 downto 0);  -- Channel 4 solid state relays control
signal spi_din_i            : std_logic;    -- SPI data from FMC
signal spi_dout_o           : std_logic;    -- SPI data to FMC
signal spi_sck_o            : std_logic;    -- SPI clock
signal spi_cs_adc_n_o       : std_logic;    -- SPI ADC chip select (active low)
signal spi_cs_dac1_n_o      : std_logic;    -- SPI channel 1 offset DAC chip select (active low)
signal spi_cs_dac2_n_o      : std_logic;    -- SPI channel 2 offset DAC chip select (active low)
signal spi_cs_dac3_n_o      : std_logic;    -- SPI channel 3 offset DAC chip select (active low)
signal spi_cs_dac4_n_o      : std_logic;    -- SPI channel 4 offset DAC chip select (active low)
signal si570_scl_b          : std_logic;    -- I2C bus clock (Si570)
signal si570_sda_b          : std_logic;    -- I2C bus data (Si570)
signal mezz_one_wire_b      : std_logic;    -- Mezzanine 1-wire interface (DS18B20 thermometer + unique
signal ext_trigger_p_i      : std_logic;    -- External trigger
signal ext_trigger_n_i      : std_logic;    -- External trigger


-- ************************
-- *** FMC_adc100m_ctrl ***
-- ************************
-- ADC registers (LTC2174)
signal ADC_RESET            : std_logic_vector(31 downto 0);
signal ADC_RESET_wstb       : std_logic;
signal ADC_TWOSCOMP         : std_logic_vector(31 downto 0);
signal ADC_TWOSCOMP_wstb    : std_logic;
signal ADC_MODE             : std_logic_vector(31 downto 0);
signal ADC_MODE_wstb        : std_logic;
signal ADC_TEST_MSB         : std_logic_vector(31 downto 0);
signal ADC_TEST_MSB_wstb    : std_logic;
signal ADC_TEST_LSB         : std_logic_vector(31 downto 0);
signal ADC_TEST_LSB_wstb    : std_logic;
signal ADC_SPI_READ         : std_logic_vector(31 downto 0);
signal ADC_SPI_READ_wstb    : std_logic;
signal ADC_SPI_READ_VALUE   : std_logic_vector(31 downto 0);
-- DAC registers MAX5442 (x4)
signal DAC_1_OFFSET         : std_logic_vector(31 downto 0);
signal DAC_2_OFFSET         : std_logic_vector(31 downto 0);
signal DAC_3_OFFSET         : std_logic_vector(31 downto 0);
signal DAC_4_OFFSET         : std_logic_vector(31 downto 0);
signal DAC_1_OFFSET_wstb    : std_logic;
signal DAC_2_OFFSET_wstb    : std_logic;
signal DAC_3_OFFSET_wstb    : std_logic;
signal DAC_4_OFFSET_wstb    : std_logic;
signal DAC_OFFSET_CLR       : std_logic_vector(31 downto 0);
-- Pattern Generator Register
signal PATGEN_REG           : std_logic_vector(31 downto 0); -- bit 0 : enable, bit 1 : reset
signal PATGEN_REG_wstb      : std_logic;
-- FIFO input selection
signal FIFO_INPUT_REG       : std_logic_vector(31 downto 0); -- "00" serdes "01" offse_ gain "10" pattern_generator
signal FIFO_INPUT_wstb      : std_logic;
-- SERDES Control and Status
signal serdes_reset         : std_logic_vector(31 downto 0);
signal refclk_locked_sta    : std_logic_vector(31 downto 0);
signal idelay_locked_sta    : std_logic_vector(31 downto 0);
signal serdes_synced_sta    : std_logic_vector(31 downto 0);
-- Gain/Offset/Saturation parameters
signal fmc_gain1            : std_logic_vector(31 downto 0);
signal fmc_gain2            : std_logic_vector(31 downto 0);
signal fmc_gain3            : std_logic_vector(31 downto 0);
signal fmc_gain4            : std_logic_vector(31 downto 0);
signal fmc_offset1          : std_logic_vector(31 downto 0);
signal fmc_offset2          : std_logic_vector(31 downto 0);
signal fmc_offset3          : std_logic_vector(31 downto 0);
signal fmc_offset4          : std_logic_vector(31 downto 0);
signal fmc_sat1             : std_logic_vector(31 downto 0);
signal fmc_sat2             : std_logic_vector(31 downto 0);
signal fmc_sat3             : std_logic_vector(31 downto 0);
signal fmc_sat4             : std_logic_vector(31 downto 0);
signal fmc_ssr1             : std_logic_vector(31 downto 0);
signal fmc_ssr2             : std_logic_vector(31 downto 0);
signal fmc_ssr3             : std_logic_vector(31 downto 0);
signal fmc_ssr4             : std_logic_vector(31 downto 0);
-- Soft Reset
signal SOFT_RESET           : std_logic_vector(31 downto 0);
signal SOFT_RESET_wstb      : std_logic;

-- Control and Status register
signal fsm_cmd_i            : std_logic_vector(31 downto 0);
signal fsm_cmd_wstb         : std_logic;
signal fmc_clk_oe           : std_logic_vector(31 downto 0);
signal test_data_en         : std_logic_vector(31 downto 0);

signal fsm_status           : std_logic_vector(31 downto 0);
signal fs_freq              : std_logic_vector(31 downto 0);

signal acq_cfg_sta          : std_logic_vector(31 downto 0);
signal pre_trig             : std_logic_vector(31 downto 0);
signal pos_trig             : std_logic_vector(31 downto 0);
signal shots_nb             : std_logic_vector(31 downto 0);
signal single_shot          : std_logic_vector(31 downto 0);
signal shots_cnt            : std_logic_vector(31 downto 0);
signal fmc_fifo_empty       : std_logic_vector(31 downto 0);
signal sw_trig              : std_logic;
signal sw_trig_en           : std_logic_vector(31 downto 0);
signal trig_delay           : std_logic_vector(31 downto 0);
signal hw_trig_sel          : std_logic_vector(31 downto 0);
signal hw_trig_pol          : std_logic_vector(31 downto 0);
signal hw_trig_en           : std_logic_vector(31 downto 0);
signal int_trig_sel         : std_logic_vector(31 downto 0);
signal int_trig_test        : std_logic_vector(31 downto 0);
signal int_trig_thres_filt  : std_logic_vector(31 downto 0);
signal int_trig_thres       : std_logic_vector(31 downto 0);
signal samples_cnt          : std_logic_vector(31 downto 0);
signal fifo_wr_cnt          : std_logic_vector(31 downto 0);
signal wait_cnt             : std_logic_vector(31 downto 0);
signal pre_trig_cnt         : std_logic_vector(31 downto 0);
signal sample_rate          : std_logic_vector(31 downto 0);




-- ADC parallel data out from SERDES in the sys_clk domain (2ff synchronizer)
signal fmc_val1             : std_logic_vector(15 downto 0);
signal fmc_val2             : std_logic_vector(15 downto 0);
signal fmc_val3             : std_logic_vector(15 downto 0);
signal fmc_val4             : std_logic_vector(15 downto 0);
-- FMC data output : 4 Channels of ADC Dataout for connection to Position Bus
signal fmc_dataout          : fmc_dataout_array(1 to 4);
signal fmc_dataout_valid    : std1_array(1 to 4);


--signal THERMOMETER_UID      : std_logic_vector(31 downto 0);


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
    g_multishot_ram_size => 128,   --512,--1024,--2048,
    g_DEBUG_ILA          => TRUE
  )
  port map (
      -- System clock and reset from PS core (125 mhz)
      sys_clk_i         => sys_clk_125,
      sys_reset_i       => sys_reset,

      -- On board clock (100 mhz)
      clk_100_i         => clk_app0_i,

      -- **********************
      -- *** FMC interface  ***
      -- **********************
      -- ADC interface (LTC2174)
      adc_dco_p_i       => adc_dco_p_i,
      adc_dco_n_i       => adc_dco_n_i,
      adc_fr_p_i        => adc_fr_p_i,
      adc_fr_n_i        => adc_fr_n_i,
      adc_outa_p_i      => adc_outa_p_i,
      adc_outa_n_i      => adc_outa_n_i,
      adc_outb_p_i      => adc_outb_p_i,
      adc_outb_n_i      => adc_outb_n_i,

      --gpio_dac_clr_n_o  => gpio_dac_clr_n_o,
      gpio_led_acq_o    => gpio_led_acq_o,
      gpio_led_trig_o   => gpio_led_trig_o,
      --gpio_si570_oe_o   => gpio_si570_oe_o,

      -- Mezzanine SPI
      spi_din_i         => spi_din_i,
      spi_dout_o        => spi_dout_o,
      spi_sck_o         => spi_sck_o,
      spi_cs_adc_n_o    => spi_cs_adc_n_o,
      spi_cs_dac1_n_o   => spi_cs_dac1_n_o,
      spi_cs_dac2_n_o   => spi_cs_dac2_n_o,
      spi_cs_dac3_n_o   => spi_cs_dac3_n_o,
      spi_cs_dac4_n_o   => spi_cs_dac4_n_o,
      -- Mezzanine I2C (Si570)
      si570_scl_b       => si570_scl_b,
      si570_sda_b       => si570_sda_b,
      -- Mezzanine 1-wire (DS18B20)
      mezz_one_wire_b   => mezz_one_wire_b,
      -- Mezzanine system I2C (EEPROM)
      --sys_scl_b         => open,
      --sys_sda_b         => open,

      -- External trigger
      ext_trigger_p_i   => ext_trigger_p_i,
      ext_trigger_n_i   => ext_trigger_n_i,


      -- ************************
      -- *** FMC_ADC100M_CTRL ***
      -- ************************
      -- ADC registers (LTC2174)
      ADC_RESET           => ADC_RESET(0),
      ADC_RESET_wstb      => ADC_RESET_wstb,
      ADC_TWOSCOMP        => ADC_TWOSCOMP(0),
      ADC_TWOSCOMP_wstb   => ADC_TWOSCOMP_wstb,
      ADC_MODE            => ADC_MODE(7 downto 0),
      ADC_MODE_wstb       => ADC_MODE_wstb,
      ADC_TEST_MSB        => ADC_TEST_MSB(7 downto 0),
      ADC_TEST_MSB_wstb   => ADC_TEST_MSB_wstb,
      ADC_TEST_LSB        => ADC_TEST_LSB(7 downto 0),
      ADC_TEST_LSB_wstb   => ADC_TEST_LSB_wstb,
      ADC_SPI_READ        => ADC_SPI_READ(2 downto 0),
      ADC_SPI_READ_wstb   => ADC_SPI_READ_wstb,
      ADC_SPI_READ_VALUE  => ADC_SPI_READ_VALUE,
      -- DAC registers MAX5442 (x4)
      DAC_1_OFFSET        => DAC_1_OFFSET,
      DAC_2_OFFSET        => DAC_2_OFFSET,
      DAC_3_OFFSET        => DAC_3_OFFSET,
      DAC_4_OFFSET        => DAC_4_OFFSET,
      DAC_1_OFFSET_wstb   => DAC_1_OFFSET_wstb,
      DAC_2_OFFSET_wstb   => DAC_2_OFFSET_wstb,
      DAC_3_OFFSET_wstb   => DAC_3_OFFSET_wstb,
      DAC_4_OFFSET_wstb   => DAC_4_OFFSET_wstb,
      -- Pattern Generator Register
      PATGEN_REG          => PATGEN_REG(1 downto 0),
      PATGEN_REG_wstb     => PATGEN_REG_wstb,
      -- FIFO input selection
      FIFO_INPUT_REG      => FIFO_INPUT_REG(1 downto 0),
      FIFO_INPUT_wstb     => FIFO_INPUT_wstb,
      -- Gain/offset calibration parameters
      fmc_gain1           => fmc_gain1(15 downto 0),
      fmc_gain2           => fmc_gain2(15 downto 0),
      fmc_gain3           => fmc_gain3(15 downto 0),
      fmc_gain4           => fmc_gain4(15 downto 0),
      fmc_offset1         => fmc_offset1(15 downto 0),
      fmc_offset2         => fmc_offset2(15 downto 0),
      fmc_offset3         => fmc_offset3(15 downto 0),
      fmc_offset4         => fmc_offset4(15 downto 0),
      fmc_sat1            => fmc_sat1(14 downto 0),
      fmc_sat2            => fmc_sat2(14 downto 0),
      fmc_sat3            => fmc_sat3(14 downto 0),
      fmc_sat4            => fmc_sat4(14 downto 0),
      -- SERDES Ctrl and Statuts
      serdes_arst_i       => serdes_reset(0),
      refclk_locked_o     => refclk_locked_sta(0),
      idelay_locked_o     => idelay_locked_sta(0),
      serdes_synced_o     => serdes_synced_sta(0),
      -- Soft Reset
      SOFT_RESET          => SOFT_RESET(0),
      SOFT_RESET_wstb     => SOFT_RESET_wstb,


      -- Control and Status Register
      fsm_cmd_i           => fsm_cmd_i(1 downto 0),
      fsm_cmd_wstb        => fsm_cmd_wstb,
      --fmc_clk_oe          => fmc_clk_oe(0),
      --offset_dac_clr      => offset_dac_clr(0),
      test_data_en        => test_data_en(0),
      fsm_status          => fsm_status(2 downto 0),
      fs_freq             => fs_freq,
      acq_cfg_sta         => acq_cfg_sta(0),
      pre_trig            => pre_trig,
      pos_trig            => pos_trig,
      shots_nb            => shots_nb(15 downto 0),
      sw_trig             => sw_trig,
      sw_trig_en          => sw_trig_en(0),
      trig_delay          => trig_delay,
      hw_trig_sel         => hw_trig_sel(0),
      hw_trig_pol         => hw_trig_pol(0),
      hw_trig_en          => hw_trig_en(0),
      int_trig_sel        => int_trig_sel(1 downto 0),
      int_trig_test       => int_trig_test(0),
      int_trig_thres_filt => int_trig_thres_filt(7 downto 0),
      int_trig_thres      => int_trig_thres(15 downto 0),
      single_shot         => single_shot(0),
      shots_cnt           => shots_cnt(15 downto 0),
      fmc_fifo_empty      => fmc_fifo_empty(0),
      samples_cnt         => samples_cnt,
      fifo_wr_cnt         => fifo_wr_cnt,
      wait_cnt            => wait_cnt,
      pre_trig_cnt        => pre_trig_cnt,
      sample_rate         => sample_rate,

    -- ***********************************************************
    -- ADC parallel data out from SERDES in the sys_clk domain ***
    -- ***********************************************************
      fmc_val1_o          => fmc_val1,  -- (15 downto 0),
      fmc_val2_o          => fmc_val2,  -- (15 downto 0),
      fmc_val3_o          => fmc_val3,  -- (15 downto 0),
      fmc_val4_o          => fmc_val4,  -- (15 downto 0)

      -- *****************************************
      -- FMC data output (sys_clk domain) to PCAP
      -- *****************************************
    -- 4 Channels of ADC Dataout for connection to Position Bus
      fmc_dataout_o         => fmc_dataout,           -- out fmc_dataout_array(1 to 4);
      fmc_dataout_valid_o   => fmc_dataout_valid      -- out  std1_array(1 to 4);


    ); -- fmc_adc_mezzanine


-- Analog Front-End
gpio_ssr_ch1_o   <= fmc_ssr1(6 downto 0);
gpio_ssr_ch2_o   <= fmc_ssr2(6 downto 0);
gpio_ssr_ch3_o   <= fmc_ssr3(6 downto 0);
gpio_ssr_ch4_o   <= fmc_ssr4(6 downto 0);
--
gpio_si570_oe_o  <= fmc_clk_oe(0);          -- Si570 programmable oscillator output enable (active high)
gpio_dac_clr_n_o <= not DAC_OFFSET_CLR(0);  -- asynchronously clear DAC outputs to code 32768 (active low)


val1_o(0) <= ZEROS(16) & fmc_val1; -- (15 downto 0);
val2_o(0) <= ZEROS(16) & fmc_val2; -- (15 downto 0);
val3_o(0) <= ZEROS(16) & fmc_val3; -- (15 downto 0);
val4_o(0) <= ZEROS(16) & fmc_val4; -- (15 downto 0);


in_data_ch1_o(0) <= ZEROS(16) & fmc_dataout(1);
in_data_ch2_o(0) <= ZEROS(16) & fmc_dataout(2);
in_data_ch3_o(0) <= ZEROS(16) & fmc_dataout(3);
in_data_ch4_o(0) <= ZEROS(16) & fmc_dataout(4);

--------------------------------------------------------
-- fmc_adc100m_ctrl instanciation
--------------------------------------------------------
cmp_fmc_adc100m_ctrl : entity work.fmc_adc100m_ctrl
port map (
    -- Clock and Reset
    clk_i               => sys_clk_125,
    reset_i             => sys_reset,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    -- Block Parameters
    -- Analog Front-End
    SSR1                => fmc_ssr1,
    SSR2                => fmc_ssr2,
    SSR3                => fmc_ssr3,
    SSR4                => fmc_ssr4,
    -- Programmable Osc Si570
    OSC_ENABLE          => fmc_clk_oe,
    OSC_ENABLE_wstb     => open,
    -- LTC2174 registers
    ADC_RESET           => open,
    ADC_RESET_wstb      => ADC_RESET_wstb,
    ADC_TWOSCOMP        => ADC_TWOSCOMP,
    ADC_TWOSCOMP_wstb   => ADC_TWOSCOMP_wstb,
    ADC_MODE            => open,
    ADC_MODE_wstb       => ADC_MODE_wstb,
    ADC_TEST_MSB        => ADC_TEST_MSB,
    ADC_TEST_MSB_wstb   => ADC_TEST_MSB_wstb,
    ADC_TEST_LSB        => ADC_TEST_LSB,
    ADC_TEST_LSB_wstb   => ADC_TEST_LSB_wstb,
    ADC_SPI_READ        => ADC_SPI_READ,
    ADC_SPI_READ_wstb   => ADC_SPI_READ_wstb,
    ADC_SPI_READ_VALUE  => ADC_SPI_READ_VALUE,
    -- DAC registers MAX5442 (x4)
    DAC_1_OFFSET        => DAC_1_OFFSET,
    DAC_1_OFFSET_wstb   => DAC_1_OFFSET_wstb,
    DAC_2_OFFSET        => DAC_2_OFFSET,
    DAC_2_OFFSET_wstb   => DAC_2_OFFSET_wstb,
    DAC_3_OFFSET        => DAC_3_OFFSET,
    DAC_3_OFFSET_wstb   => DAC_3_OFFSET_wstb,
    DAC_4_OFFSET        => DAC_4_OFFSET,
    DAC_4_OFFSET_wstb   => DAC_4_OFFSET_wstb,
    DAC_OFFSET_CLR      => DAC_OFFSET_CLR,
    DAC_OFFSET_CLR_wstb => open,
    -- SERDES Control and Status
    SERDES_RESET        => SERDES_RESET,
    SERDES_RESET_wstb   => open,
    REFCLK_LOCKED       => refclk_locked_sta,
    IDELAY_LOCKED       => idelay_locked_sta,
    SERDES_SYNCED       => serdes_synced_sta,
    -- Pattern Generator
    PATGEN_REG          => PATGEN_REG,
    PATGEN_REG_wstb     => PATGEN_REG_wstb,
    -- FIFO input register
    FIFO_INPUT          => FIFO_INPUT_REG,
    FIFO_INPUT_wstb     => FIFO_INPUT_wstb,
    -- Gain Offset Saturation
    GAIN1               => fmc_gain1,
    GAIN2               => fmc_gain2,
    GAIN3               => fmc_gain3,
    GAIN4               => fmc_gain4,
    OFFSET1             => fmc_offset1,
    OFFSET2             => fmc_offset2,
    OFFSET3             => fmc_offset3,
    OFFSET4             => fmc_offset4,
    SAT1                => fmc_sat1,
    SAT2                => fmc_sat2,
    SAT3                => fmc_sat3,
    SAT4                => fmc_sat4,
    -- Acquisition Control
    FSM_CMD             => fsm_cmd_i,
    FSM_CMD_WSTB        => fsm_cmd_wstb,
    SHOTS_NB            => shots_nb,
    PRE_TRIG            => pre_trig,
    POS_TRIG            => pos_trig,
    TRIG_DELAY          => trig_delay,
    INT_TRIG_SEL        => int_trig_sel,
    INT_TRIG_TEST       => int_trig_test,
    INT_TRIG_THRES_FILT => int_trig_thres_filt,
    INT_TRIG_THRES      => int_trig_thres,
    HW_TRIG_EN          => hw_trig_en,
    HW_TRIG_SEL         => hw_trig_sel,
    HW_TRIG_POL         => hw_trig_pol,
    SW_TRIG_from_bus    => sw_trig,
    SW_TRIG_EN          => sw_trig_en,
    -- Status
    FSM_STATUS          => fsm_status,
    ACQ_FREQ            => fs_freq,
    SAMPLE_RATE         => sample_rate,
    ACQ_CFG_STA         => acq_cfg_sta,
    SINGLE_SHOT         => single_shot,
    FIFO_EMPTY          => fmc_fifo_empty,
    SHOTS_CNT           => shots_cnt,
    SAMPLES_CNT         => samples_cnt,
    PRE_TRIG_CNT        => pre_trig_cnt,
    FIFO_WR_CNT         => fifo_wr_cnt,
    WAIT_CNT            => wait_cnt,
    -- Soft Reset
    SOFT_RESET          => SOFT_RESET,
    SOFT_RESET_wstb     => SOFT_RESET_wstb,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open
);

end rtl;
-- End of code

