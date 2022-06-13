--------------------------------------------------------------------------------
--  PandA Motion Project - 2022
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
-- Unit name  : fmc_adc_mezzanine (fmc_adc_mezzanine.vhd)
--
-- Author     : Thierry GARREL (ELSYS-Design)
--
-- description: The FMC ADC mezzanine is wrapper around the fmc-adc-100ms core
--              and the other wishbone slaves connected to a FMC ADC mezzanine.
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.fmc_adc_types.all;

--------------------------------------------------------------------------------
-- Entity declaration
--------------------------------------------------------------------------------
entity fmc_adc_mezzanine is
  generic(
    g_multishot_ram_size  : natural := 2048 ;
    g_DEBUG_ILA           : boolean := FALSE
    );
  port (
    -- System clock and reset from PS core (125 mhz)
    sys_clk_i           : in  std_logic;
    sys_reset_i         : in  std_logic;

    -- On board clock (100 mhz)
    clk_100_i           : in  std_logic;

    -- **********************
    -- *** FMC interface  ***
    -- **********************
    -- ADC interface (LTC2174)
    adc_dco_p_i         : in  std_logic;                     -- ADC serial bit clock
    adc_dco_n_i         : in  std_logic;
    adc_fr_p_i          : in  std_logic;                     -- ADC frame start
    adc_fr_n_i          : in  std_logic;
    adc_outa_p_i        : in  std_logic_vector(3 downto 0);  -- ADC serial data (odd bits)
    adc_outa_n_i        : in  std_logic_vector(3 downto 0);
    adc_outb_p_i        : in  std_logic_vector(3 downto 0);  -- ADC serial data (even bits)
    adc_outb_n_i        : in  std_logic_vector(3 downto 0);


    --gpio_dac_clr_n_o    : out std_logic;                     -- offset DACs clear (active low)
    gpio_led_acq_o      : out std_logic;                     -- Mezzanine front panel power LED (PWR)
    gpio_led_trig_o     : out std_logic;                     -- Mezzanine front panel trigger LED (TRIG)
    --gpio_si570_oe_o     : out std_logic;                     -- Si570 (programmable oscillator) output enable

    -- Mezzanine SPI
    spi_din_i           : in  std_logic;    -- SPI data from FMC
    spi_dout_o          : out std_logic;    -- SPI data to FMC
    spi_sck_o           : out std_logic;    -- SPI clock
    spi_cs_adc_n_o      : out std_logic;    -- SPI ADC chip select (active low)
    spi_cs_dac1_n_o     : out std_logic;    -- SPI channel 1 offset DAC chip select (active low)
    spi_cs_dac2_n_o     : out std_logic;    -- SPI channel 2 offset DAC chip select (active low)
    spi_cs_dac3_n_o     : out std_logic;    -- SPI channel 3 offset DAC chip select (active low)
    spi_cs_dac4_n_o     : out std_logic;    -- SPI channel 4 offset DAC chip select (active low)

    -- Mezzanine I2C (Si570)
    si570_scl_b         : inout std_logic;      -- I2C bus clock (Si570)
    si570_sda_b         : inout std_logic;      -- I2C bus data (Si570)
    -- Mezzanine 1-wire (DS18B20)
    mezz_one_wire_b     : inout std_logic;      -- Mezzanine 1-wire interface (DS18B20 thermometer + unique ID)
    -- Mezzanine system I2C (EEPROM)
    --sys_scl_b           : inout std_logic;    -- Mezzanine system I2C clock (EEPROM)
    --sys_sda_b           : inout std_logic;    -- Mezzanine system I2C data (EEPROM)

    -- External trigger
    ext_trigger_p_i     : in  std_logic;
    ext_trigger_n_i     : in  std_logic;


    -- ************************
    -- *** FMC_ADC100M_CTRL ***
    -- ************************
    -- ADC registers (LTC2174)
    ADC_RESET           : in  std_logic;
    ADC_RESET_wstb      : in  std_logic;
    ADC_TWOSCOMP        : in  std_logic;
    ADC_TWOSCOMP_wstb   : in  std_logic;
    ADC_MODE            : in  std_logic_vector(7 downto 0);
    ADC_MODE_wstb       : in  std_logic;
    ADC_TEST_MSB        : in  std_logic_vector(7 downto 0);
    ADC_TEST_MSB_wstb   : in  std_logic;
    ADC_TEST_LSB        : in  std_logic_vector(7 downto 0);
    ADC_TEST_LSB_wstb   : in  std_logic;
    ADC_SPI_READ        : in  std_logic_vector(2 downto 0);
    ADC_SPI_READ_wstb   : in  std_logic;
    ADC_SPI_READ_VALUE  : out std_logic_vector(31 downto 0);
    -- DAC registers (MAX5442 x4)
    DAC_1_OFFSET        : in  std_logic_vector(31 downto 0);
    DAC_2_OFFSET        : in  std_logic_vector(31 downto 0);
    DAC_3_OFFSET        : in  std_logic_vector(31 downto 0);
    DAC_4_OFFSET        : in  std_logic_vector(31 downto 0);
    DAC_1_OFFSET_wstb   : in  std_logic;
    DAC_2_OFFSET_wstb   : in  std_logic;
    DAC_3_OFFSET_wstb   : in  std_logic;
    DAC_4_OFFSET_wstb   : in  std_logic;
    -- Pattern Generator Register
    PATGEN_ENABLE       : in  std_logic;
    PATGEN_RESET        : in  std_logic;
    PATGEN_PERIOD       : in  std_logic_vector(31 downto 0);
    PATGEN_PERIOD_wstb  : in  std_logic;
    -- FIFO input selection
    FIFO_INPUT_SEL      : in  std_logic_vector(1 downto 0); -- "00" serdes "01" offse_ gain "10" pattern_generator

    -- Gain/offset calibration parameters
    fmc_gain1           : in  std_logic_vector(15 downto 0);
    fmc_gain2           : in  std_logic_vector(15 downto 0);
    fmc_gain3           : in  std_logic_vector(15 downto 0);
    fmc_gain4           : in  std_logic_vector(15 downto 0);
    fmc_offset1         : in  std_logic_vector(15 downto 0);
    fmc_offset2         : in  std_logic_vector(15 downto 0);
    fmc_offset3         : in  std_logic_vector(15 downto 0);
    fmc_offset4         : in  std_logic_vector(15 downto 0);
    fmc_sat1            : in  std_logic_vector(14 downto 0);
    fmc_sat2            : in  std_logic_vector(14 downto 0);
    fmc_sat3            : in  std_logic_vector(14 downto 0);
    fmc_sat4            : in  std_logic_vector(14 downto 0);
    -- SERDES Ctrl and Statuts
    serdes_arst_i       : in  std_logic;
    refclk_locked_o     : out std_logic;
    idelay_locked_o     : out std_logic;
    serdes_synced_o     : out std_logic;
    -- Soft Reset
    SOFT_RESET          : in  std_logic;
    SOFT_RESET_wstb     : in  std_logic;


    -- Control and Status Register
    fsm_cmd_i           : in  std_logic_vector(1 downto 0);
    fsm_cmd_wstb        : in  std_logic;
    --fmc_clk_oe          : in  std_logic;
    --offset_dac_clr      : in  std_logic;
    test_data_en        : in  std_logic;
    --man_bitslip         : in  std_logic;
    pre_trig            : in  std_logic_vector(31 downto 0);
    pos_trig            : in  std_logic_vector(31 downto 0);
    shots_nb            : in  std_logic_vector(15 downto 0);
    sw_trig             : in  std_logic;
    sw_trig_en          : in  std_logic;
    trig_delay          : in  std_logic_vector(31 downto 0);
    hw_trig_sel         : in  std_logic;
    hw_trig_pol         : in  std_logic;
    hw_trig_en          : in  std_logic;
    int_trig_sel        : in  std_logic_vector(1  downto 0);
    int_trig_test       : in  std_logic;
    int_trig_thres_filt : in  std_logic_vector(7  downto 0);
    int_trig_thres      : in  std_logic_vector(15 downto 0);
    sample_rate         : in  std_logic_vector(31 downto 0);
    --
    fsm_status          : out std_logic_vector(2  downto 0);
    serdes_pll_sta      : out std_logic;
    fs_freq             : out std_logic_vector(31 downto 0);
    acq_cfg_sta         : out std_logic;
    single_shot         : out std_logic;
    shots_cnt           : out std_logic_vector(15 downto 0);
    fmc_fifo_empty      : out std_logic;
    samples_cnt         : out std_logic_vector(31 downto 0);
    fifo_wr_cnt         : out std_logic_vector(31 downto 0);
    wait_cnt            : out std_logic_vector(31 downto 0);
    pre_trig_cnt        : out std_logic_vector(31 downto 0);

    -- ***********************************************************
    -- ADC parallel data out from SERDES in the sys_clk domain ***
    -- ***********************************************************
    fmc_val1_o          : out std_logic_vector(15 downto 0);
    fmc_val2_o          : out std_logic_vector(15 downto 0);
    fmc_val3_o          : out std_logic_vector(15 downto 0);
    fmc_val4_o          : out std_logic_vector(15 downto 0);


    -- *****************************************
    -- FMC data output (sys_clk domain) to PCAP
    -- *****************************************
    -- 4 Channels of ADC Dataout for connection to Position Bus
    fmc_dataout_o       : out fmc_dataout_array(1 to 4);
    fmc_dataout_valid_o : out std1_array(1 to 4)

    );
end fmc_adc_mezzanine;


--------------------------------------------------------------------------------
-- Architecture declaration
--------------------------------------------------------------------------------
architecture rtl of fmc_adc_mezzanine is

  ------------------------------------------------------------------------------
  -- Attributes used for Vivado tool flow
  ------------------------------------------------------------------------------
  attribute async_reg   : string; -- synchronizing register within a synchronization chain
  attribute keep        : string; -- keep name for ila probes


  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  -- System Clock period (is ns)
  constant SYS_PERIOD       : natural := 8; -- 125 MHz (8 ns)
  -- SPI clock and dead periods (in ns)
  constant SPI_CLK_PERIOD   : natural := 1008; -- [ns] : 1   us           126 ->  63 -> 1.008 us
  constant SPI_DEAD_PERIOD  : natural := 2000; -- [ns] : 2.0 us           250 -> 125 -> 2.000 us

  -- SPI ADC registers addresses (A6 downto A0)
  subtype spi_adc_adr_t is  std_logic_vector(6 downto 0);
  constant C_ADC_REG_A0_ADR  : spi_adc_adr_t := "0000000";
  constant C_ADC_REG_A1_ADR  : spi_adc_adr_t := "0000001";
  constant C_ADC_REG_A2_ADR  : spi_adc_adr_t := "0000010";
  constant C_ADC_REG_A3_ADR  : spi_adc_adr_t := "0000011";
  constant C_ADC_REG_A4_ADR  : spi_adc_adr_t := "0000100";

  -- register SPI commands
   -- 1 to 5   : write ADC A0 to A4 registers
   -- 6 to 9   : read  ADC A1 to A4 registers
   -- 10 to 13 : write DAC_1 to DAC_4 input register
  subtype spi_cmd_t is std_logic_vector(3 downto 0);
  constant C_SPI_CMD_WR_ADC_A0  : spi_cmd_t := x"1";  -- ADC REGISTER A0 : RESET REGISTER                 (Address 00h) ** write only **
  constant C_SPI_CMD_WR_ADC_A1  : spi_cmd_t := x"2";  -- ADC REGISTER A1 : FORMAT AND POWER DOWN REGISTER (Address 01h)
  constant C_SPI_CMD_WR_ADC_A2  : spi_cmd_t := x"3";  -- ADC REGISTER A2 : OUTPUT MODE REGISTER           (Address 02h)
  constant C_SPI_CMD_WR_ADC_A3  : spi_cmd_t := x"4";  -- ADC REGISTER A3 : TEST PATTERN MSB REGISTER      (Address 03h)
  constant C_SPI_CMD_WR_ADC_A4  : spi_cmd_t := x"5";  -- ADC REGISTER A4 : TEST PATTERN LSB REGISTER      (Address 04h)
  constant C_SPI_CMD_RD_ADC_A1  : spi_cmd_t := x"6";
  constant C_SPI_CMD_RD_ADC_A2  : spi_cmd_t := x"7";
  constant C_SPI_CMD_RD_ADC_A3  : spi_cmd_t := x"8";
  constant C_SPI_CMD_RD_ADC_A4  : spi_cmd_t := x"9";
  constant C_SPI_CMD_WR_DAC_1   : spi_cmd_t := x"A";  -- DAC_1 input register (16 bits) ** write only **
  constant C_SPI_CMD_WR_DAC_2   : spi_cmd_t := x"B";  -- DAC_2 input register (16 bits) ** write only **
  constant C_SPI_CMD_WR_DAC_3   : spi_cmd_t := x"C";  -- DAC_3 input register (16 bits) ** write only **
  constant C_SPI_CMD_WR_DAC_4   : spi_cmd_t := x"D";  -- DAC_4 input register (16 bits) ** write only **

  ------------------------------------------------------------------------------
  -- Types declaration
  ------------------------------------------------------------------------------


  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------
  signal sys_reset_n_i  : std_logic; -- not(sys_reset_i)

  -- Mezzanine SPI
  signal wr_req         : std_logic;
  signal wr_dat         : std_logic_vector(15 downto 0);
  signal wr_adr         : std_logic_vector( 6 downto 0);
  signal rd_req         : std_logic;
  signal rd_adr         : std_logic_vector(6 downto 0);
  signal rd_data        : std_logic_vector(7 downto 0);
  signal rd_valid       : std_logic;
  signal spi_cmd        : spi_cmd_t; --register spi commands
  signal busy_ltc       : std_logic;
  signal busy_max       : std_logic;
  signal spi_dout_ltc   : std_logic;
  signal spi_dout_max   : std_logic;
  signal spi_sck_ltc    : std_logic;
  signal spi_sck_max    : std_logic;
  -- debug to read outputs
  signal spi_dout       : std_logic;    -- SPI data to FMC
  signal spi_sck        : std_logic;    -- SPI clock
  signal spi_cs_adc_n   : std_logic;    -- SPI ADC  chip select (active low)
  signal spi_cs_dac1_n  : std_logic;    -- SPI DAC1 chip select (active low)
  signal spi_cs_dac2_n  : std_logic;    -- SPI DAC2 chip select (active low)
  signal spi_cs_dac3_n  : std_logic;    -- SPI DAC3 chip select (active low)
  signal spi_cs_dac4_n  : std_logic;    -- SPI DAC4 chip select (active low)

  -- spi debug signals +++
  signal spi_shift_counter    : std_logic_vector(3 downto 0);
  signal spi_shift_enable     : std_logic;

  -- Mezzanine I2C for Si570
  signal si570_scl_in   : std_logic;
  signal si570_scl_out  : std_logic;
  signal si570_scl_oe_n : std_logic;
  signal si570_sda_in   : std_logic;
  signal si570_sda_out  : std_logic;
  signal si570_sda_oe_n : std_logic;

  -- Mezzanine system I2C for EEPROM
  --signal sys_scl_in     : std_logic;
  --signal sys_scl_out    : std_logic;
  --signal sys_scl_oe_n   : std_logic;
  --signal sys_sda_in     : std_logic;
  --signal sys_sda_out    : std_logic;
  --signal sys_sda_oe_n   : std_logic;

  -- Mezzanine 1-wire
  --signal mezz_owr_en : std_logic_vector(0 downto 0);
  --signal mezz_owr_i  : std_logic_vector(0 downto 0);

  -- Refclk 200 mhz

  --signal spi_ss_t       : std_logic_vector(7 downto 0);


  -- REFCLK clock generator
  signal refclk_200m          : std_logic;    -- REFCLK input of IDELAYCTRL (must be 200 Mhz).
  signal refclk_reset         : std_logic;    -- Min 50 ns
  signal refclk_locked        : std_logic;

  -- IDELAYCTRL is needed for calibration
  -- When IDELAYCTRL REFCLK is 200 MHz, IDELAY delay chain consist of 64 taps of 78 ps
  signal idelay_refclock_i    : std_logic;    -- REFCLK input of IDELAYCTRL (must be 200 Mhz).
  signal idelay_rst_i         : std_logic;    -- RST input of IDELAYCTRL. Minimum pulse width 52.0 ns
  signal idelay_locked        : std_logic;    -- indicate that IDELAYE2 modules are calibrated

  -- SERDES status
  signal serdes_bslip_i       : std_logic := '0';
  signal serdes_synced        : std_logic; -- Indication that SERDES is ok and locked to frame start pattern


  -- ADC parallel data out
  --  (15:0)  = CH1, (31:16) = CH2, (47:32) = CH3, (63:48) = CH4
  --  The two LSBs of each channel are always '0'
  signal adc_ch1_o            : std_logic_vector(15 downto 0);
  signal adc_ch2_o            : std_logic_vector(15 downto 0);
  signal adc_ch3_o            : std_logic_vector(15 downto 0);
  signal adc_ch4_o            : std_logic_vector(15 downto 0);
  -- all channels as an array
  signal adc_data_ch          : std16_array(1 to 4);

  -- ADC divided clock, for FPGA logic
  signal adc_clk              : std_logic;

  -- Synchronization chains (from sys_clk to adc_clk)
  signal adc_reset_meta           : std_logic;
  signal adc_reset_sync           : std_logic;
  signal adc_clk_reset            : std_logic; -- adc_reset_sync
  signal adc_clk_reset_n          : std_logic; -- not(adc_reset_sync)

  signal PATGEN_ENABLE_meta       : std_logic;
  signal PATGEN_ENABLE_sync       : std_logic;
  signal PATGEN_RESET_meta        : std_logic;
  signal PATGEN_RESET_sync        : std_logic;
  signal PATGEN_PERIOD_meta       : std_logic_vector(31 downto 0);
  signal PATGEN_PERIOD_sync       : std_logic_vector(31 downto 0);
  signal PATGEN_PERIOD_wstb_sync  : std_logic;

  signal FIFO_INPUT_SEL_meta      : std_logic_vector(1 downto 0);
  signal FIFO_INPUT_SEL_sync      : std_logic_vector(1 downto 0);

  signal fmc_gain_meta        : fmc_gain_array(1 to 4);
  signal fmc_gain_sync        : fmc_gain_array(1 to 4);
  signal fmc_offset_meta      : fmc_offset_array(1 to 4);
  signal fmc_offset_sync      : fmc_offset_array(1 to 4);
  signal fmc_sat_meta         : fmc_sat_array(1 to 4);
  signal fmc_sat_sync         : fmc_sat_array(1 to 4);

  -- Synchronization chains (from adc_clk to sys_clk)
  signal fmc_val1_meta        : std_logic_vector(15 downto 0);
  signal fmc_val2_meta        : std_logic_vector(15 downto 0);
  signal fmc_val3_meta        : std_logic_vector(15 downto 0);
  signal fmc_val4_meta        : std_logic_vector(15 downto 0);
  signal fmc_val1_sync        : std_logic_vector(15 downto 0);
  signal fmc_val2_sync        : std_logic_vector(15 downto 0);
  signal fmc_val3_sync        : std_logic_vector(15 downto 0);
  signal fmc_val4_sync        : std_logic_vector(15 downto 0);

  signal refclk_locked_meta   : std_logic;
  signal refclk_locked_sync   : std_logic;
  signal idelay_locked_meta   : std_logic;
  signal idelay_locked_sync   : std_logic;
  signal serdes_synced_meta   : std_logic;
  signal serdes_synced_sync   : std_logic;

  -- Time-tagging core
  signal trigger_p   : std_logic;
  signal acq_start_p : std_logic;
  signal acq_stop_p  : std_logic;
  signal acq_end_p   : std_logic;


  -- Attributes for synchronisation chains
  attribute async_reg of refclk_locked_meta   : signal is "true";
  attribute async_reg of refclk_locked_sync   : signal is "true";
  attribute async_reg of serdes_synced_meta   : signal is "true";
  attribute async_reg of serdes_synced_sync   : signal is "true";
  attribute async_reg of idelay_locked_meta   : signal is "true";
  attribute async_reg of idelay_locked_sync   : signal is "true";

  attribute async_reg of adc_reset_meta       : signal is "true";
  attribute async_reg of adc_reset_sync       : signal is "true";

  attribute async_reg of PATGEN_ENABLE_meta   : signal is "true";
  attribute async_reg of PATGEN_ENABLE_sync   : signal is "true";
  attribute async_reg of PATGEN_RESET_meta    : signal is "true";
  attribute async_reg of PATGEN_RESET_sync    : signal is "true";
  attribute async_reg of PATGEN_PERIOD_meta   : signal is "true";
  attribute async_reg of PATGEN_PERIOD_sync   : signal is "true";

  attribute async_reg of FIFO_INPUT_SEL_meta  : signal is "true";
  attribute async_reg of FIFO_INPUT_SEL_sync  : signal is "true";

  attribute async_reg of fmc_gain_meta        : signal is "true";
  attribute async_reg of fmc_gain_sync        : signal is "true";
  attribute async_reg of fmc_offset_meta      : signal is "true";
  attribute async_reg of fmc_offset_sync      : signal is "true";
  attribute async_reg of fmc_sat_meta         : signal is "true";
  attribute async_reg of fmc_sat_sync         : signal is "true";

  attribute async_reg of fmc_val1_meta        : signal is "true";
  attribute async_reg of fmc_val2_meta        : signal is "true";
  attribute async_reg of fmc_val3_meta        : signal is "true";
  attribute async_reg of fmc_val4_meta        : signal is "true";
  attribute async_reg of fmc_val1_sync        : signal is "true";
  attribute async_reg of fmc_val2_sync        : signal is "true";
  attribute async_reg of fmc_val3_sync        : signal is "true";
  attribute async_reg of fmc_val4_sync        : signal is "true";


  -- Attributes for ILA

  attribute keep of ADC_RESET_wstb      : signal is "true";
  attribute keep of ADC_TWOSCOMP_wstb   : signal is "true";
  attribute keep of ADC_MODE_wstb       : signal is "true";
  attribute keep of ADC_TEST_MSB_wstb   : signal is "true";
  attribute keep of ADC_TEST_LSB_wstb   : signal is "true";
  attribute keep of ADC_SPI_READ_wstb   : signal is "true";
  attribute keep of ADC_SPI_READ        : signal is "true";

  attribute keep of wr_adr              : signal is "true";
  attribute keep of wr_dat              : signal is "true";
  attribute keep of wr_req              : signal is "true";
  attribute keep of rd_adr              : signal is "true";
  attribute keep of rd_req              : signal is "true";
  attribute keep of spi_cmd             : signal is "true";
  attribute keep of busy_ltc            : signal is "true";

  attribute keep of spi_cs_adc_n        : signal is "true";
  attribute keep of spi_cs_dac1_n       : signal is "true";
  attribute keep of spi_cs_dac2_n       : signal is "true";
  attribute keep of spi_cs_dac3_n       : signal is "true";
  attribute keep of spi_cs_dac4_n       : signal is "true";
  attribute keep of spi_sck             : signal is "true";
  attribute keep of spi_dout            : signal is "true";
  attribute keep of spi_din_i           : signal is "true";

  attribute keep of spi_shift_counter   : signal is "true";
  attribute keep of spi_shift_enable    : signal is "true";


-- Begin of code
begin

  sys_reset_n_i     <= not(sys_reset_i);

  ------------------------------------------------------------------------------
  -- Mezzanine system managment I2C master
  --    Access to mezzanine EEPROM
  ------------------------------------------------------------------------------
  --cmp_fmc_sys_i2c : xwb_i2c_master
    --generic map(
      --g_interface_mode      => CLASSIC,
      --g_address_granularity => BYTE
      --)
    --port map (
      --clk_sys_i => sys_clk_i,
      --rst_n_i   => '1',--sys_rst_n_i,

      --slave_i => cnx_master_out(c_WB_SLAVE_FMC_SYS_I2C),
      --slave_o => cnx_master_in(c_WB_SLAVE_FMC_SYS_I2C),
      --desc_o  => open,

      --scl_pad_i    => sys_scl_in,
      --scl_pad_o    => sys_scl_out,
      --scl_padoen_o => sys_scl_oe_n,
      --sda_pad_i    => sys_sda_in,
      --sda_pad_o    => sys_sda_out,
      --sda_padoen_o => sys_sda_oe_n
      --);

  ---- Tri-state buffer for SDA and SCL
  --sys_scl_b  <= sys_scl_out when sys_scl_oe_n = '0' else 'Z';
  --sys_scl_in <= sys_scl_b;

  --sys_sda_b  <= sys_sda_out when sys_sda_oe_n = '0' else 'Z';
  --sys_sda_in <= sys_sda_b;

  ------------------------------------------------------------------------------
  -- Mezzanine SPI master
  --    ADC control         (TX and RX)
  --    Offset DACs control (TX only)
  ------------------------------------------------------------------------------
  cmp_spi_ltc2174_tx_rx : entity work.spi_ltc2174_tx_rx
    generic map (
        CLK_PERIOD  => (SPI_CLK_PERIOD/SYS_PERIOD),     -- 1.0 us
        DEAD_PERIOD => (SPI_DEAD_PERIOD/SYS_PERIOD)     -- 2.0 us
    )
    port map (
        clk_i             => sys_clk_i,
        reset_i           => sys_reset_i,
        -- Write transaction interface
        wr_req_i          => wr_req,
        wr_adr_i          => wr_adr,
        wr_dat_i          => wr_dat(7 downto 0),
        -- Read transaction interface
        rd_req_i          => rd_req,
        rd_adr_i          => rd_adr,
        rd_dat_o          => rd_data,
        rd_val_o          => rd_valid,
        -- Status flags
        busy_o            => busy_ltc,
        -- Serial Physical interface
        spi_sclk_o        => spi_sck_ltc,
        spi_dat_o         => spi_dout_ltc,
        spi_dat_i         => spi_din_i,
        -- debug outputs
        shift_counter_o   => spi_shift_counter,
        shift_enable_o    => spi_shift_enable
    );

  cmp_spi_max5442_tx : entity work.spi_max5442_tx
    generic map (
        CLK_PERIOD  => (SPI_CLK_PERIOD/SYS_PERIOD),     -- 1.0 us
        DEAD_PERIOD => (SPI_DEAD_PERIOD/SYS_PERIOD)     -- 2.0 us
    )
    port map (
        clk_i       => sys_clk_i,
        reset_i     => sys_reset_i,
        -- Transaction interface
        wr_req_i    => wr_req,
        wr_dat_i    => wr_dat(15 downto 0),
        -- Status flags
        busy_o      => busy_max,
        -- Serial Physical interface
        spi_sclk_o  => spi_sck_max,
        spi_dat_o   => spi_dout_max
    );


  -- LTC2174 registers
  --
  -- REGISTER A0 : RESET REGISTER (Address 00h) ** Write Only **
  -- D[7:0] = RESET & dont_care_bits[6:0]
  -- RESET :
  --   0 = not used
  --   1 = Software Reset : All Mode Control Registers are Reset to 00h.
  --                        The ADC is Momentarily Placed in SLEEP Mode.
  --   This Bit is Automatically Set Back to Zero at the End of the SPI Write Command.
  --
  -- REGISTER A1 : FORMAT AND POWER DOWN REGISTER (Address 01h)
  -- D[7:0] = DCSOFF & RAND & TWOSCOMP & SLEEP & NAP[4:1]
  --
  -- TWOSCOMP : 0 = Offset Binary Data Format      ** This is the default at power up **
  --            1 = Two's Complement Data Format
  --
  -- REGISTER A2 : OUTPUT MODE REGISTER (Address 02h)
  -- D[7:0] = ILVDS[2:0] & TERMON & OUTOFF & OUTMODE[2:0]
  --                                         \ 000 = 2-Lanes, 16-Bit Serialization
  --
  -- REGISTER A3 : TEST PATTERN MSB REGISTER (Address 03h) : D[7:0] = OUTTEST & X & TP[13:8]
  -- REGISTER A4 : TEST PATTERN LSB REGISTER (Address 04h) : D[7:0] = TP[7:0]
  --
  -- OUTTEST  : 0 = Digital Output Test Pattern Off
  --            1 = Digital Output Test Pattern ON
  -- TP[13:8] : Test Pattern for Data Bits [13:8]
  -- TP[7:0]  : Test Pattern for Data bits [7:0]
  --

  p_fmc_spi : process(sys_clk_i)
    begin
    if rising_edge(sys_clk_i) then
        if (sys_reset_i = '1') then
            -- init spi write
            wr_req    <= '0';
            wr_adr    <= (others => '0');
            wr_dat    <= (others => '0');
            spi_cmd   <= (others => '0');
            spi_sck   <= '0';
            spi_dout  <= '0';
            -- init spi read
            rd_req    <= '0';
            rd_adr    <= (others => '0');

        else
            -- Cycle through registers contiuously.
            if (busy_ltc = '0' and busy_max = '0') then
                wr_req  <= '0';
                rd_req <= '0';
                spi_cs_adc_n  <= '1';
                spi_cs_dac1_n <= '1';
                spi_cs_dac2_n <= '1';
                spi_cs_dac3_n <= '1';
                spi_cs_dac4_n <= '1';
                --
                -- SPI write ADC A0 to A4 registers
                -- spi_cmd = 1,2,3,4,5
                if (ADC_RESET_wstb = '1') then
                    wr_req  <= '1';
                    wr_adr <= C_ADC_REG_A0_ADR; -- ADC REGISTER A0 : RESET REGISTER (Address 00h)
                    wr_dat( 7 downto 0) <= "10000000"; -- Bit 7 = Software Reset bit  0x80
                    wr_dat(15 downto 8) <= (others => '0');
                    spi_cmd <= C_SPI_CMD_WR_ADC_A0;
                end if;
                if (ADC_TWOSCOMP_wstb = '1') then
                    wr_req  <= '1';
                    wr_adr <= C_ADC_REG_A1_ADR; -- ADC REGISTER A1 : FORMAT AND POWER DOWN REGISTER (Address 01h)
                    wr_dat( 7 downto 0) <= "00" & ADC_TWOSCOMP & "00000"; -- Bit 5 =  Two's Complement Mode Control Bit
                    wr_dat(15 downto 8) <= (others => '0');
                    spi_cmd <= C_SPI_CMD_WR_ADC_A1;
                end if;
                if (ADC_MODE_wstb = '1') then
                    wr_req  <= '1';
                    wr_adr <= C_ADC_REG_A2_ADR; -- ADC REGISTER A2 : OUTPUT MODE REGISTER (Address 02h)
                    wr_dat  <= (others => '0');
                    spi_cmd <= C_SPI_CMD_WR_ADC_A2;
                end if;
                if (ADC_TEST_MSB_wstb = '1') then
                    wr_req  <= '1';
                    wr_adr <= C_ADC_REG_A3_ADR; -- ADC REGISTER A3 : TEST PATTERN MSB REGISTER (Address 03h)
                    wr_dat( 7 downto 0) <= ADC_TEST_MSB;
                    wr_dat(15 downto 8) <= (others => '0');
                    spi_cmd <= C_SPI_CMD_WR_ADC_A3;
                end if;
                if (ADC_TEST_LSB_wstb = '1') then
                    wr_req  <= '1';
                    wr_adr <= C_ADC_REG_A4_ADR; -- ADC REGISTER A4 : : TEST PATTERN LSB REGISTER (Address 04h)
                    wr_dat( 7 downto 0) <= ADC_TEST_LSB;
                    wr_dat(15 downto 8) <= (others => '0');
                    spi_cmd <= C_SPI_CMD_WR_ADC_A4;
                end if;
                -- SPI write DAC_1 to DAC_4 input register (16 bits)
                -- spi_cmd = 10,11,12,13
                if (DAC_1_OFFSET_wstb = '1') then
                    wr_req  <= '1';
                    wr_dat  <= DAC_1_OFFSET(15 downto 0);
                    spi_cmd <= C_SPI_CMD_WR_DAC_1;
                end if;
                if (DAC_2_OFFSET_wstb = '1') then
                    wr_req  <= '1';
                    wr_dat  <= DAC_2_OFFSET(15 downto 0);
                    spi_cmd <= C_SPI_CMD_WR_DAC_2;
                end if;
                if (DAC_3_OFFSET_wstb = '1') then
                    wr_req  <= '1';
                    wr_dat  <= DAC_3_OFFSET(15 downto 0);
                    spi_cmd <= C_SPI_CMD_WR_DAC_3;
                end if;
                if (DAC_4_OFFSET_wstb = '1') then
                    wr_req  <= '1';
                    wr_dat  <= DAC_4_OFFSET(15 downto 0);
                    spi_cmd <= C_SPI_CMD_WR_DAC_4;
                end if;
                -- read ADC A1 to A4 registers
                if (ADC_SPI_READ_wstb = '1') then
                    case ADC_SPI_READ is
                        when "001" => rd_req <= '1'; rd_adr <= C_ADC_REG_A1_ADR; spi_cmd <= C_SPI_CMD_RD_ADC_A1;
                        when "010" => rd_req <= '1'; rd_adr <= C_ADC_REG_A2_ADR; spi_cmd <= C_SPI_CMD_RD_ADC_A2;
                        when "011" => rd_req <= '1'; rd_adr <= C_ADC_REG_A3_ADR; spi_cmd <= C_SPI_CMD_RD_ADC_A3;
                        when "100" => rd_req <= '1'; rd_adr <= C_ADC_REG_A4_ADR; spi_cmd <= C_SPI_CMD_RD_ADC_A4;
                        when others =>
                    end case;
                end if;
            -- if busy = 1, continue to write
            else
                case spi_cmd is
                    -- write ADC A0 to A4 registers
                    when C_SPI_CMD_WR_ADC_A0 => spi_cs_adc_n  <= '0'; spi_dout <= spi_dout_ltc; spi_sck <= spi_sck_ltc;
                    when C_SPI_CMD_WR_ADC_A1 => spi_cs_adc_n  <= '0'; spi_dout <= spi_dout_ltc; spi_sck <= spi_sck_ltc;
                    when C_SPI_CMD_WR_ADC_A2 => spi_cs_adc_n  <= '0'; spi_dout <= spi_dout_ltc; spi_sck <= spi_sck_ltc;
                    when C_SPI_CMD_WR_ADC_A3 => spi_cs_adc_n  <= '0'; spi_dout <= spi_dout_ltc; spi_sck <= spi_sck_ltc;
                    when C_SPI_CMD_WR_ADC_A4 => spi_cs_adc_n  <= '0'; spi_dout <= spi_dout_ltc; spi_sck <= spi_sck_ltc;
                    -- read ADC A1 to A4 registers
                    when C_SPI_CMD_RD_ADC_A1 => spi_cs_adc_n  <= '0'; spi_dout <= spi_dout_ltc; spi_sck <= spi_sck_ltc;
                    when C_SPI_CMD_RD_ADC_A2 => spi_cs_adc_n  <= '0'; spi_dout <= spi_dout_ltc; spi_sck <= spi_sck_ltc;
                    when C_SPI_CMD_RD_ADC_A3 => spi_cs_adc_n  <= '0'; spi_dout <= spi_dout_ltc; spi_sck <= spi_sck_ltc;
                    when C_SPI_CMD_RD_ADC_A4 => spi_cs_adc_n  <= '0'; spi_dout <= spi_dout_ltc; spi_sck <= spi_sck_ltc;
                    -- write DAC_1 to DAC_4 input register
                    when C_SPI_CMD_WR_DAC_1  => spi_cs_dac1_n <= '0'; spi_dout <= spi_dout_max; spi_sck <= spi_sck_max;
                    when C_SPI_CMD_WR_DAC_2  => spi_cs_dac2_n <= '0'; spi_dout <= spi_dout_max; spi_sck <= spi_sck_max;
                    when C_SPI_CMD_WR_DAC_3  => spi_cs_dac3_n <= '0'; spi_dout <= spi_dout_max; spi_sck <= spi_sck_max;
                    when C_SPI_CMD_WR_DAC_4  => spi_cs_dac4_n <= '0'; spi_dout <= spi_dout_max; spi_sck <= spi_sck_max;
                    when others =>
                end case;
            end if;
        end if;
    end if;
  end process p_fmc_spi;

  p_fmc_spi_rdval : process(sys_clk_i)
    begin
    if rising_edge(sys_clk_i) then
        if (sys_reset_i = '1') then
            ADC_SPI_READ_VALUE <= (others=>'0');
        else
            if (busy_ltc = '0') then
                if (ADC_RESET_wstb = '1') then
                    ADC_SPI_READ_VALUE <= (others=>'0');
                end if;
              -- if busy = 1 and spi_cmd is a read to ADC registers, wait for rd_valid to latch rd_data
              else
                if (spi_cmd = C_SPI_CMD_RD_ADC_A1 or spi_cmd = C_SPI_CMD_RD_ADC_A2 or
                    spi_cmd = C_SPI_CMD_RD_ADC_A3 or spi_cmd = C_SPI_CMD_RD_ADC_A4) then
                    if (rd_valid = '1') then
                        ADC_SPI_READ_VALUE <= x"000000" & rd_data;
                    end if;
                end if;
            end if;
        end if;
    end if;
  end process p_fmc_spi_rdval;

  -- Connect SPI outputs
  spi_cs_adc_n_o    <= spi_cs_adc_n;
  spi_cs_dac1_n_o   <= spi_cs_dac1_n;
  spi_cs_dac2_n_o   <= spi_cs_dac2_n;
  spi_cs_dac3_n_o   <= spi_cs_dac3_n;
  spi_cs_dac4_n_o   <= spi_cs_dac4_n;
  spi_sck_o         <= spi_sck;
  spi_dout_o        <= spi_dout;



  ---------------------------------------------------------
  -- Generation of 200 MHe REFCLK for IDELAYCTRL
  -- using a PLL2_BASE component
  ---------------------------------------------------------
  cmp_refclk_200mhz : entity work.gen_refclk_200mhz
  generic map (
    g_CLK_IN_PERIOD    => 10.0,           -- 100 Mhz
    g_CLK_IN_MULT      => 8,              -- 800 MHz (min VCO Frequency)
    g_REFCLK_DIVIDE    => 4,              -- 200 MHz
    g_RESET_CYCLES     => 12              -- 60 ns
  )
  port map (
    clock_i         => clk_100_i,
    refclk_o        => refclk_200m,       -- REFCLK input of IDELAYCTRL (must be 200 Mhz).
    refclk_locked_o => refclk_locked,     -- PLL locked
    refclk_reset_o  => refclk_reset       -- Reset output. Deactivate 'RESET_CYCLES' after pll_locked rise
  );


  ---------------------------------------------------------------------
  -- Synchronization chains (from sys_clk to adc_clk)
  ---------------------------------------------------------------------
  p_sync_adc_clk : process(adc_clk)
  begin
    if rising_edge(adc_clk) then
        -- sys_reset
        adc_reset_meta        <= sys_reset_i;
        adc_reset_sync        <= adc_reset_meta;
        -- pattern generator register
        PATGEN_ENABLE_meta    <= PATGEN_ENABLE;
        PATGEN_RESET_meta     <= PATGEN_RESET;
        PATGEN_PERIOD_meta    <= PATGEN_PERIOD;

        PATGEN_ENABLE_sync    <= PATGEN_ENABLE_meta;
        PATGEN_RESET_sync     <= PATGEN_RESET_meta;
        PATGEN_PERIOD_sync    <= PATGEN_PERIOD_meta;

        -- FIFO input select
        FIFO_INPUT_SEL_meta   <= FIFO_INPUT_SEL;
        FIFO_INPUT_SEL_sync   <= FIFO_INPUT_SEL_meta;

        -- fmc_gain
        fmc_gain_meta(1)    <= fmc_gain1;
        fmc_gain_meta(2)    <= fmc_gain2;
        fmc_gain_meta(3)    <= fmc_gain3;
        fmc_gain_meta(4)    <= fmc_gain4;
        fmc_gain_sync       <= fmc_gain_meta;
        -- fmc_offset
        fmc_offset_meta(1)  <= fmc_offset1;
        fmc_offset_meta(2)  <= fmc_offset2;
        fmc_offset_meta(3)  <= fmc_offset3;
        fmc_offset_meta(4)  <= fmc_offset4;
        fmc_offset_sync     <= fmc_offset_meta;
        -- fmc_saturation
        fmc_sat_meta(1)     <= fmc_sat1;
        fmc_sat_meta(2)     <= fmc_sat2;
        fmc_sat_meta(3)     <= fmc_sat3;
        fmc_sat_meta(4)     <= fmc_sat4;
        fmc_sat_sync        <= fmc_sat_meta;

    end if;
  end process p_sync_adc_clk;

  adc_clk_reset     <= adc_reset_sync;
  adc_clk_reset_n   <= not(adc_reset_sync);

  ----------------------------------------------------
  -- Pulse synchronizer (from sys_clk to adc_clk)
  ----------------------------------------------------
  cmp_gc_pulse_sync : entity work.gc_pulse_synchronizer2
  port map (
    -- pulse input clock
    clk_in_i      => sys_clk_i,
    rst_in_n_i    => sys_reset_n_i,
    -- pulse output clock
    clk_out_i     => adc_clk,
    rst_out_n_i   => adc_clk_reset_n,
    -- pulse input ready (clk_in_i domain). When HI, a pulse coming to d_p_i will be correctly transferred to q_p_o.
    d_ready_o     => open,
    d_p_i         => PATGEN_PERIOD_wstb,        -- pulse input (clk_in_i domain)
    q_p_o         => PATGEN_PERIOD_wstb_sync    -- pulse output (clk_out_i domain)
  );



  --------------------------------------------------------------------------------
  -- LTC3274 2-lane, 16-bit serialization mode receiver
  --    DDR reception scheme
  --    Serial and Parallel clock buffers based for clock generation (no PLL nor MMCM)
  --------------------------------------------------------------------------------
  idelay_refclock_i   <= refclk_200m;
  idelay_rst_i        <= refclk_reset;


  cmp_ltc2174_receiver : entity work.ltc2174_2lanes_ddr_receiver
  generic map (
    g_DEBUG_ILA         => TRUE,      -- Generate ILA for debugging
    g_SERIAL_CLK_BUF    => "BUFIO",   -- Buffer type for SERDES serial clock : BUFIO or BUFG or BUFR or BUFH
    G_DCO_IDELAY_VALUE  => 0,         -- Delay Tap setting for IDELAYE2 on adc_clk (0-31)
    G_DATA_IDELAY_VALUE => 0          -- Delay Tap setting for IDELAYE2 on adc_fr,adc_outa,adc_outb (0-31)
  )
  port map (
    -- IDELAYCTRL is needed for calibration
    -- When IDELAYCTRL REFCLK is 200 MHz, IDELAY delay chain consist of 64 taps of 78 ps
    idelay_refclock_i   => idelay_refclock_i,     -- REFCLK input of IDELAYCTRL (must be 200 Mhz).
    idelay_rst_i        => idelay_rst_i,          -- RST input of IDELAYCTRL. Minimum pulse width 52.0 ns
    idelay_locked_o     => idelay_locked,

    -- ADC serial interface
    adc_dco_p_i         => adc_dco_p_i,
    adc_dco_n_i         => adc_dco_n_i,
    adc_fr_p_i          => adc_fr_p_i,
    adc_fr_n_i          => adc_fr_n_i,
    adc_outa_p_i        => adc_outa_p_i,
    adc_outa_n_i        => adc_outa_n_i,
    adc_outb_p_i        => adc_outb_p_i,
    adc_outb_n_i        => adc_outb_n_i,

    -- SERDES status
    serdes_arst_i       => serdes_arst_i,       -- Async reset input (active high) for iserdes
    serdes_bslip_i      => serdes_bslip_i,      -- Manual bitslip command (optional)
    serdes_synced_o     => serdes_synced,       -- Indication that SERDES is ok and locked to frame start pattern

    -- ADC parallel data out (clk_div clock domain)
    adc_data_o          => open,
    --  (15:0)  = CH1, (31:16) = CH2, (47:32) = CH3, (63:48) = CH4
    adc_ch1_o           => adc_ch1_o,
    adc_ch2_o           => adc_ch2_o,
    adc_ch3_o           => adc_ch3_o,
    adc_ch4_o           => adc_ch4_o,
    -- ADC divided clock, for FPGA logic (clk_div)
    adc_clk_o           => adc_clk
  );


  -- adc  parallel data out as an array
  -- Leaves the two LSBs of each channel that are always '0'
  adc_data_ch(1) <= adc_ch1_o; -- "00" & adc_ch1_o(15 downto 2);
  adc_data_ch(2) <= adc_ch2_o; -- "00" & adc_ch2_o(15 downto 2);
  adc_data_ch(3) <= adc_ch3_o; -- "00" & adc_ch3_o(15 downto 2);
  adc_data_ch(4) <= adc_ch4_o; -- "00" & adc_ch4_o(15 downto 2);


  ---------------------------------------------------------------------
  -- Synchronization chains (from adc_clk to sys_clk)
  ---------------------------------------------------------------------
  p_sync_sys_clk : process(sys_clk_i)
  begin
    if rising_edge(sys_clk_i) then
        if (sys_reset_i = '1') then
            -- clear the output of the first flip-flop
            fmc_val1_meta       <= (others=>'0');
            fmc_val2_meta       <= (others=>'0');
            fmc_val3_meta       <= (others=>'0');
            fmc_val4_meta       <= (others=>'0');
            refclk_locked_meta  <= '0';
            idelay_locked_meta  <= '0';
            serdes_synced_meta  <= '0';
            -- clear the output of the second and final flip-flop
            fmc_val1_sync       <= (others=>'0');
            fmc_val2_sync       <= (others=>'0');
            fmc_val3_sync       <= (others=>'0');
            fmc_val4_sync       <= (others=>'0');
            refclk_locked_sync  <= '0';
            idelay_locked_sync  <= '0';
            serdes_synced_sync  <= '0';
        else
            -- capture the arriving signal - higher probability of being meta-stable
            -- Leaves the two LSBs of each channel that are always '0'
            fmc_val1_meta       <= adc_ch1_o;  --    "00" & adc_ch1_o(15 downto 2);
            fmc_val2_meta       <= adc_ch2_o;  --    "00" & adc_ch2_o(15 downto 2);
            fmc_val3_meta       <= adc_ch3_o;  --    "00" & adc_ch3_o(15 downto 2);
            fmc_val4_meta       <= adc_ch4_o;  --    "00" & adc_ch4_o(15 downto 2);
            refclk_locked_meta  <= refclk_locked;
            idelay_locked_meta  <= idelay_locked;
            serdes_synced_meta  <= serdes_synced;
            -- resample the potentially meta-stable signal, lowering the probability of meta-stability
            fmc_val1_sync       <= fmc_val1_meta;
            fmc_val2_sync       <= fmc_val2_meta;
            fmc_val3_sync       <= fmc_val3_meta;
            fmc_val4_sync       <= fmc_val4_meta;
            refclk_locked_sync  <= refclk_locked_meta;
            idelay_locked_sync  <= idelay_locked_meta;
            serdes_synced_sync  <= serdes_synced_meta;
        end if; -- reset
    end if; -- clock
  end process p_sync_sys_clk;

  -- Connect outputs
  gpio_led_trig_o <= refclk_locked;
  gpio_led_acq_o  <= serdes_synced_sync;

  refclk_locked_o <= refclk_locked;
  serdes_synced_o <= serdes_synced_sync;
  idelay_locked_o <= idelay_locked_sync;

  fmc_val1_o      <= fmc_val1_sync;
  fmc_val2_o      <= fmc_val2_sync;
  fmc_val3_o      <= fmc_val3_sync;
  fmc_val4_o      <= fmc_val4_sync;


  ------------------------------------------------------------------------------
  -- Mezzanine I2C
  --    Si570 control
  --
  -- Note: I2C registers are 8-bit wide, but accessed as 32-bit registers
  ------------------------------------------------------------------------------
  --cmp_fmc_i2c : xwb_i2c_master
    --generic map(
      --g_interface_mode      => CLASSIC,
      --g_address_granularity => BYTE
      --)
    --port map (
      --clk_sys_i => sys_clk_i,
      --rst_n_i   => '1',--sys_rst_n_i,

      --slave_i => cnx_master_out(c_WB_SLAVE_FMC_I2C),
      --slave_o => cnx_master_in(c_WB_SLAVE_FMC_I2C),
      --desc_o  => open,

      --scl_pad_i    => si570_scl_in,
      --scl_pad_o    => si570_scl_out,
      --scl_padoen_o => si570_scl_oe_n,
      --sda_pad_i    => si570_sda_in,
      --sda_pad_o    => si570_sda_out,
      --sda_padoen_o => si570_sda_oe_n
      --);

  ---- Tri-state buffer for SDA and SCL
  --si570_scl_b  <= si570_scl_out when si570_scl_oe_n = '0' else 'Z';
  --si570_scl_in <= si570_scl_b;

  --si570_sda_b  <= si570_sda_out when si570_sda_oe_n = '0' else 'Z';
  --si570_sda_in <= si570_sda_b;




  ------------------------------------------------------------------------------
  -- ADC core
  --    Solid State Relays control
  --    Si570 output enable
  --    Offset DACs control (CLR_N)
  --    ADC core control and status
  ------------------------------------------------------------------------------
  cmp_fmc_adc100m_core :  entity work.fmc_adc100m_core
  generic map (
    g_DEBUG_ILA         => TRUE
  )
  port map (
    -- **********************************
    -- *** ADC clock domain (clk_div) ***
    -- **********************************
    adc_clk_i           => adc_clk,
    adc_reset_i         => adc_clk_reset,
    -- ADC parallel data from SERDES (by channel array)
    adc_data_ch         => adc_data_ch,       -- in  adc_data_ch_array(1 to 4);

    -- IDELAYCTRL and SERDES statuts
    idelay_locked_i     => idelay_locked,
    serdes_synced_i     => serdes_synced,

    -- Configuration registers coming from fmc_adc100m_ctrl in the sys_clk domain
    -- are synchronized to the adc_clk domain using chains synchronizers.

    -- Gain/offset calibration parameters
    fmc_gain_ch         => fmc_gain_sync,       -- in  fmc_gain_array(1 to 4);
    fmc_offset_ch       => fmc_offset_sync,     -- in  fmc_offset_array(1 to 4);
    fmc_sat_ch          => fmc_sat_sync,        -- in  fmc_sat_array(1 to 4);
    -- Pattern Generator register
    PATGEN_ENABLE       => PATGEN_ENABLE_sync,
    PATGEN_RESET        => PATGEN_RESET_sync,
    PATGEN_PERIOD       => PATGEN_PERIOD_sync,
    PATGEN_PERIOD_wstb  => PATGEN_PERIOD_wstb_sync,
    -- FIFO input selection
    FIFO_INPUT_SEL      => FIFO_INPUT_SEL_sync, -- "00" serdes "01" offse_ gain "10" pattern_generator

    -- ************************
    -- *** SYS clock domain ***
    -- ************************
    -- System clock and reset from PS core (125 mhz)
    sys_clk_i           => sys_clk_i,
    sys_reset_i         => sys_reset_i,

    -- FIFO status

    -- FMC data output (sys_clk domain)
    -- 4 Channels of ADC Dataout for connection to Position Bus
    fmc_dataout_o       => fmc_dataout_o,
    fmc_dataout_valid_o => fmc_dataout_valid_o

  );



--+++  cmp_fmc_adc100Ms_core : entity work.fmc_adc100Ms_core
--+++    generic map (
--+++        g_multishot_ram_size => g_multishot_ram_size,
--+++        g_DEBUG_ILA          => FALSE
--+++    )
--+++    port map (
--+++      -- Clock, reset
--+++      sys_clk_i         => sys_clk_i,
--+++      sys_rst_n_i       => sys_rst_n_i,
--+++
--+++      -- On board clock
--+++      clk_100_i         => clk_100_i
--+++
--+++      -- DDR wishbone interface
--+++      wb_ddr_clk_i   => sys_clk_i,
--+++      wb_ddr_dat_o   => wb_ddr_dat_o,
--+++
--+++      trigger_p_o   => trigger_p,
--+++      acq_start_p_o => acq_start_p,
--+++      acq_stop_p_o  => acq_stop_p,
--+++      acq_end_p_o   => acq_end_p,
--+++
--+++      --trigger_tag_i => trigger_tag,
--+++
--+++
--+++      -- **********************
--+++      -- *** FMC interface  ***
--+++      -- **********************
--+++      -- ADC interface (LTC2174)
--+++      adc_dco_p_i  => adc_dco_p_i,
--+++      adc_dco_n_i  => adc_dco_n_i,
--+++      adc_fr_p_i   => adc_fr_p_i,
--+++      adc_fr_n_i   => adc_fr_n_i,
--+++      adc_outa_p_i => adc_outa_p_i,
--+++      adc_outa_n_i => adc_outa_n_i,
--+++      adc_outb_p_i => adc_outb_p_i,
--+++      adc_outb_n_i => adc_outb_n_i,
--+++
--+++      --gpio_dac_clr_n_o => open, --- gpio_dac_clr_n_o,
--+++      gpio_led_acq_o   => gpio_led_acq_o,
--+++      gpio_led_trig_o  => gpio_led_trig_o,
--+++      --gpio_si570_oe_o  => gpio_si570_oe_o,
--+++
--+++      -- External trigger
--+++      ext_trigger_p_i => ext_trigger_p_i,
--+++      ext_trigger_n_i => ext_trigger_n_i,
--+++
--+++
--+++    -- Control and Status Register
--+++      fsm_cmd_i      => fsm_cmd_i,
--+++      fsm_cmd_wstb   => fsm_cmd_wstb,
--+++      --fmc_clk_oe     => fmc_clk_oe,
--+++      --fmc_adc_core_ctl_offset_dac_clr_n_o      => offset_dac_clr,
--+++
--+++
--+++      fmc_adc_core_ctl_test_data_en_o          => test_data_en,
--+++      fmc_adc_core_ctl_man_bitslip_o           => man_bitslip,
--+++
--+++      fmc_adc_core_sta_fsm_i                      => fsm_status,
--+++      fmc_adc_core_sta_serdes_pll_i               => serdes_pll_sta,
--+++      fmc_adc_core_fs_freq_i                      => fs_freq,
--+++      fmc_adc_core_sta_serdes_synced_i            => serdes_synced_sta,
--+++      fmc_adc_core_sta_acq_cfg_i                  => acq_cfg_sta,
--+++      fmc_adc_core_pre_samples_o                  => pre_trig,
--+++      fmc_adc_core_post_samples_o                 => pos_trig,
--+++      fmc_adc_core_shots_nb_o                     => shots_nb,
--+++      fmc_adc_core_sw_trig_wr_o                   => sw_trig,
--+++      fmc_adc_core_trig_cfg_sw_trig_en_o          => sw_trig_en,
--+++      fmc_adc_core_trig_dly_o                     => trig_delay,
--+++      fmc_adc_core_trig_cfg_hw_trig_sel_o         => hw_trig_sel,
--+++      fmc_adc_core_trig_cfg_hw_trig_pol_o         => hw_trig_pol,
--+++      fmc_adc_core_trig_cfg_hw_trig_en_o          => hw_trig_en,
--+++      fmc_adc_core_trig_cfg_int_trig_sel_o        => int_trig_sel,
--+++      fmc_adc_core_trig_cfg_int_trig_test_en_o    => int_trig_test,
--+++      fmc_adc_core_trig_cfg_int_trig_thres_filt_o => int_trig_thres_filt,
--+++      fmc_adc_core_trig_cfg_int_trig_thres_o      => int_trig_thres,
--+++      fmc_adc_core_sr_deci_o                      => sample_rate,
--+++
--+++      fmc_single_shot               => single_shot,
--+++      fmc_adc_core_shots_cnt_val_i  => shots_cnt,
--+++      fmc_fifo_empty                => fmc_fifo_empty,
--+++      fmc_adc_core_samples_cnt_i    => samples_cnt,
--+++      fifo_wr_cnt                   => fifo_wr_cnt,
--+++      wait_cnt                      => wait_cnt,
--+++      pre_trig_count                => pre_trig_cnt,
--+++
--+++      fmc_adc_core_ch1_gain_val_o   => fmc_gain1,
--+++      fmc_adc_core_ch2_gain_val_o   => fmc_gain2,
--+++      fmc_adc_core_ch3_gain_val_o   => fmc_gain3,
--+++      fmc_adc_core_ch4_gain_val_o   => fmc_gain4,
--+++      fmc_adc_core_ch1_offset_val_o => fmc_offset1,
--+++      fmc_adc_core_ch2_offset_val_o => fmc_offset2,
--+++      fmc_adc_core_ch3_offset_val_o => fmc_offset3,
--+++      fmc_adc_core_ch4_offset_val_o => fmc_offset4,
--+++      fmc_adc_core_ch1_sat_val_o    => fmc_sat1,
--+++      fmc_adc_core_ch2_sat_val_o    => fmc_sat2,
--+++      fmc_adc_core_ch3_sat_val_o    => fmc_sat3,
--+++      fmc_adc_core_ch4_sat_val_o    => fmc_sat4,
--+++
--+++      fmc_adc_core_ch1_sta_val_i    => fmc_val1,
--+++      fmc_adc_core_ch2_sta_val_i    => fmc_val2,
--+++      fmc_adc_core_ch3_sta_val_i    => fmc_val3,
--+++      fmc_adc_core_ch4_sta_val_i    => fmc_val4
--+++      );


  ------------------------------------------------------------------------------
  -- Mezzanine 1-wire master
  --    DS18B20 (thermometer + unique ID)
  ------------------------------------------------------------------------------
  --cmp_fmc_onewire : xwb_onewire_master
    --generic map(
      --g_interface_mode      => CLASSIC,
      --g_address_granularity => BYTE,
      --g_num_ports           => 1,
      --g_ow_btp_normal       => "5.0",
      --g_ow_btp_overdrive    => "1.0"
      --)
    --port map (
      --clk_sys_i => sys_clk_i,
      --rst_n_i   => '1',--sys_rst_n_i,

      --slave_i => cnx_master_out(c_WB_SLAVE_FMC_ONEWIRE),
      --slave_o => cnx_master_in(c_WB_SLAVE_FMC_ONEWIRE),
      --desc_o  => open,

      --owr_pwren_o => open,
      --owr_en_o    => mezz_owr_en,
      --owr_i       => mezz_owr_i
      --);

  --mezz_one_wire_b <= '0' when mezz_owr_en(0) = '1' else 'Z';
  --mezz_owr_i(0)   <= mezz_one_wire_b;


-----------------------------------------------------------------------------
-- Chipscope ILA Debug purpose
-----------------------------------------------------------------------------
ILA_GEN : if g_DEBUG_ILA generate

  -- CHIPSCOPE ILA probes
  signal probe0       : std_logic_vector(31 downto 0);
  signal probe1       : std_logic_vector(31 downto 0);
  signal probe3       : std_logic_vector(31 downto 0);


-- Begin of ILA code
begin

    ILA_0 : entity work.ila_32x8K   -- ILA IP (32-bit wide with 8K Depth)
    port map ( clk => sys_clk_i, probe0 => probe0 );

    --                                                 bits       index
    probe0(31 downto 0) <=  ADC_RESET_wstb          -- 1          31
                          & ADC_TWOSCOMP_wstb       -- 1          30
                          & ADC_MODE_wstb           -- 1          29
                          & ADC_TEST_MSB_wstb       -- 1          28
                          & ADC_TEST_LSB_wstb       -- 1          27
                          & spi_cmd                 -- 4    9     26:23
                          & wr_adr(6 downto 0)      -- 7    16    22:16
                          & wr_dat(7 downto 0)      -- 8          15:8
                          & wr_req                  -- 1          7
                          & spi_cs_adc_n            -- 1          6
                          & spi_cs_dac1_n           -- 1          5
                          & spi_cs_dac2_n           -- 1          4
                          & spi_cs_dac3_n           -- 1          3
                          & spi_cs_dac4_n           -- 1          2
                          & spi_sck                 -- 1          1
                          & spi_dout;               -- 1          0


    ILA_1 : entity work.ila_32x8K   -- ILA IP (32-bit wide with 8K Depth)
    port map ( clk => sys_clk_i, probe0 => probe1 );

    --                                                 bits       index
    probe1(31 downto 0) <=  ADC_RESET_wstb          -- 1          31
                          & ADC_SPI_READ_wstb       -- 1          30
                          & ADC_SPI_READ            -- 3          29:27
                          & rd_adr(6 downto 0)      -- 7          26:20
                          & rd_req                  -- 1          19
                          & busy_ltc                -- 1          18                            --
                          & spi_cs_adc_n            -- 1          17
                          & spi_sck                 -- 1          16
                          & spi_dout                -- 1          15
                          & spi_din_i               -- 1          14
                          & spi_shift_counter       -- 4          13:10
                          & spi_shift_enable        -- 1          9
                          & rd_valid                -- 1          8
                          & rd_data(7 downto 0);    -- 8          7:0


end generate;
-- End of ILA code


end rtl;
-- End of code

