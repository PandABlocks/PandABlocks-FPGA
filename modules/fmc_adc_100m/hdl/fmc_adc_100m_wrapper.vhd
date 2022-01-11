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
use work.wishbone_pkg.all;

entity fmc_adc_100m_wrapper is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Outputs to PosBus from FMC
    in_data_ch1_o        : out std32_array(0 downto 0);
    in_data_ch2_o        : out std32_array(0 downto 0);
    in_data_ch3_o        : out std32_array(0 downto 0);
    in_data_ch4_o        : out std32_array(0 downto 0);
    
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
end fmc_adc_100m_wrapper;

architecture rtl of fmc_adc_100m_wrapper is

---------------------------------------------------------------------------------------
-- FMC pin name translation signals.
---------------------------------------------------------------------------------------
signal sys_clk_125      : std_logic;
signal fmc0_rst_n       : std_logic;
signal adc_dco_n_i      : std_logic;
signal adc_dco_p_i      : std_logic;
signal adc_fr_n_i       : std_logic;
signal adc_fr_p_i       : std_logic;
signal adc_outa_n_i     : std_logic_vector(3 downto 0);
signal adc_outa_p_i     : std_logic_vector(3 downto 0);
signal adc_outb_n_i     : std_logic_vector(3 downto 0);
signal adc_outb_p_i     : std_logic_vector(3 downto 0);

signal gpio_dac_clr_n_o : std_logic;                     -- offset DACs clear (active low)
signal gpio_led_acq_o   : std_logic;                     -- Mezzanine front panel power LED (PWR)
signal gpio_led_trig_o  : std_logic;                     -- Mezzanine front panel trigger LED (TRIG)
signal gpio_ssr_ch1_o   : std_logic_vector(6 downto 0);  -- Channel 1 solid state relays control
signal gpio_ssr_ch2_o   : std_logic_vector(6 downto 0);  -- Channel 2 solid state relays control
signal gpio_ssr_ch3_o   : std_logic_vector(6 downto 0);  -- Channel 3 solid state relays control
signal gpio_ssr_ch4_o   : std_logic_vector(6 downto 0);  -- Channel 4 solid state relays control
signal gpio_si570_oe_o  : std_logic;
signal spi_din_i        : std_logic;    -- SPI data from FMC
signal spi_dout_o       : std_logic;    -- SPI data to FMC
signal spi_sck_o        : std_logic;    -- SPI clock
signal spi_cs_adc_n_o   : std_logic;    -- SPI ADC chip select (active low)
signal spi_cs_dac1_n_o  : std_logic;    -- SPI channel 1 offset DAC chip select (active low)
signal spi_cs_dac2_n_o  : std_logic;    -- SPI channel 2 offset DAC chip select (active low)
signal spi_cs_dac3_n_o  : std_logic;    -- SPI channel 3 offset DAC chip select (active low)
signal spi_cs_dac4_n_o  : std_logic;    -- SPI channel 4 offset DAC chip select (active low)
signal si570_scl_b      : std_logic;    -- I2C bus clock (Si570)
signal si570_sda_b      : std_logic;    -- I2C bus data (Si570)
signal mezz_one_wire_b  : std_logic;    -- Mezzanine 1-wire interface (DS18B20 thermometer + unique
signal ext_trigger_p_i  : std_logic;    -- External trigger
signal ext_trigger_n_i  : std_logic;    -- External trigger

signal fmc_data_o          : std_logic_vector(63 downto 0);
signal fmc_data_addr_o     : std_logic_vector(31 downto 0);
signal fmc_data_hi         : std_logic_vector(31 downto 0);
signal fmc_data_lo         : std_logic_vector(31 downto 0);
-- Control and Status register
signal fsm_cmd_i           : std_logic_vector(31 downto 0);
signal fsm_cmd_wstb        : std_logic;
signal fmc_clk_oe          : std_logic_vector(31 downto 0);
signal test_data_en        : std_logic_vector(31 downto 0);
signal man_bitslip         : std_logic_vector(31 downto 0);
signal offset_dac_clr      : std_logic_vector(31 downto 0);
signal fsm_status          : std_logic_vector(31 downto 0);
signal serdes_pll_sta      : std_logic_vector(31 downto 0);
signal fs_freq             : std_logic_vector(31 downto 0);
signal serdes_synced_sta   : std_logic_vector(31 downto 0);
signal acq_cfg_sta         : std_logic_vector(31 downto 0);
signal pre_trig            : std_logic_vector(31 downto 0);
signal pos_trig            : std_logic_vector(31 downto 0);
signal shots_nb            : std_logic_vector(31 downto 0);
signal single_shot         : std_logic_vector(31 downto 0);
signal shots_cnt           : std_logic_vector(31 downto 0);
signal fmc_fifo_empty      : std_logic_vector(31 downto 0);
signal sw_trig             : std_logic;
signal sw_trig_en          : std_logic_vector(31 downto 0);
signal trig_delay          : std_logic_vector(31 downto 0);
signal hw_trig_sel         : std_logic_vector(31 downto 0);
signal hw_trig_pol         : std_logic_vector(31 downto 0);
signal hw_trig_en          : std_logic_vector(31 downto 0);
signal int_trig_sel        : std_logic_vector(31 downto 0);
signal int_trig_test       : std_logic_vector(31 downto 0);
signal int_trig_thres_filt : std_logic_vector(31 downto 0);
signal int_trig_thres      : std_logic_vector(31 downto 0);
signal samples_cnt         : std_logic_vector(31 downto 0);
signal fifo_wr_cnt         : std_logic_vector(31 downto 0);
signal wait_cnt            : std_logic_vector(31 downto 0);
signal pre_trig_cnt        : std_logic_vector(31 downto 0);
signal sample_rate         : std_logic_vector(31 downto 0);
signal type_code           : std_logic_vector(31 downto 0);
signal type_code_wstb      : std_logic;
signal spi_reg_2           : std_logic;
signal spi_offset_1        : std_logic_vector(31 downto 0);
signal spi_offset_2        : std_logic_vector(31 downto 0);
signal spi_offset_3        : std_logic_vector(31 downto 0);
signal spi_offset_4        : std_logic_vector(31 downto 0);
signal spi_offset_1_wstb   : std_logic;
signal spi_offset_2_wstb   : std_logic;
signal spi_offset_3_wstb   : std_logic;
signal spi_offset_4_wstb   : std_logic;
signal fmc_gain1           : std_logic_vector(31 downto 0);
signal fmc_gain2           : std_logic_vector(31 downto 0);
signal fmc_gain3           : std_logic_vector(31 downto 0);
signal fmc_gain4           : std_logic_vector(31 downto 0);
signal fmc_offset1         : std_logic_vector(31 downto 0);
signal fmc_offset2         : std_logic_vector(31 downto 0);
signal fmc_offset3         : std_logic_vector(31 downto 0);
signal fmc_offset4         : std_logic_vector(31 downto 0);
signal fmc_sat1            : std_logic_vector(31 downto 0);
signal fmc_sat2            : std_logic_vector(31 downto 0);
signal fmc_sat3            : std_logic_vector(31 downto 0);
signal fmc_sat4            : std_logic_vector(31 downto 0);
signal fmc_ssr1            : std_logic_vector(31 downto 0);
signal fmc_ssr2            : std_logic_vector(31 downto 0);
signal fmc_ssr3            : std_logic_vector(31 downto 0);
signal fmc_ssr4            : std_logic_vector(31 downto 0);
signal fmc_val1            : std_logic_vector(31 downto 0);
signal fmc_val2            : std_logic_vector(31 downto 0);
signal fmc_val3            : std_logic_vector(31 downto 0);
signal fmc_val4            : std_logic_vector(31 downto 0);
signal THERMOMETER_UID     : std_logic_vector(31 downto 0);
signal SOFT_RESET          : std_logic;

-- FMC ADC core to DDR wishbone bus
signal wb_ddr_dat_o : std_logic_vector(63 downto 0);



begin
---------------------------------------------------------------------------------------
-- Translate the FMC pin names into fmc_adc_mezzanine names
---------------------------------------------------------------------------------------
---------------
-- ADC         
---------------
 adc_dco_p_i         <= FMC_io.FMC_LA_P(0);  -- ADC data clock
 adc_dco_n_i         <= FMC_io.FMC_LA_N(0);
 adc_fr_n_i          <= FMC_io.FMC_LA_N(1);  -- ADC frame start
 adc_fr_p_i          <= FMC_io.FMC_LA_P(1);
 adc_outa_n_i(0)     <= FMC_io.FMC_LA_N(14); -- ADC serial data (odd bits)
 adc_outa_p_i(0)     <= FMC_io.FMC_LA_P(14);
 adc_outb_n_i(0)     <= FMC_io.FMC_LA_N(15); -- ADC serial data (even bits)
 adc_outb_p_i(0)     <= FMC_io.FMC_LA_P(15);
 adc_outa_n_i(1)     <= FMC_io.FMC_LA_N(16);
 adc_outa_p_i(1)     <= FMC_io.FMC_LA_P(16);
 adc_outb_n_i(1)     <= FMC_io.FMC_LA_N(13);
 adc_outb_p_i(1)     <= FMC_io.FMC_LA_P(13);
 adc_outa_n_i(2)     <= FMC_io.FMC_LA_N(10);
 adc_outa_p_i(2)     <= FMC_io.FMC_LA_P(10);
 adc_outb_n_i(2)     <= FMC_io.FMC_LA_N(9);
 adc_outb_p_i(2)     <= FMC_io.FMC_LA_P(9);
 adc_outa_n_i(3)     <= FMC_io.FMC_LA_N(7);
 adc_outa_p_i(3)     <= FMC_io.FMC_LA_P(7);
 adc_outb_n_i(3)     <= FMC_io.FMC_LA_N(5);
 adc_outb_p_i(3)     <= FMC_io.FMC_LA_P(5);
---------------        
-- SPI                 
---------------        
spi_din_i           <= FMC_io.FMC_LA_P(25); -- SPI data from FMC    
FMC_io.FMC_LA_N(31) <= spi_dout_o     ;
FMC_io.FMC_LA_P(31) <= spi_sck_o      ;
FMC_io.FMC_LA_P(30) <= spi_cs_adc_n_o ;
FMC_io.FMC_LA_P(32) <= spi_cs_dac1_n_o;
FMC_io.FMC_LA_N(32) <= spi_cs_dac2_n_o;
FMC_io.FMC_LA_P(33) <= spi_cs_dac3_n_o;
FMC_io.FMC_LA_N(33) <= spi_cs_dac4_n_o;
---------------        
-- GPIO                
---------------        
FMC_io.FMC_LA_N(30) <= gpio_dac_clr_n_o ;
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

sys_clk_125 <= clk_i;
fmc0_rst_n  <= not(SOFT_RESET); --reset_i;



fmc_adc_mezzanine : entity work.fmc_adc_mezzanine
generic map(
      g_multishot_ram_size => 128 --512,--1024,--2048,
      )
    port map(
      sys_clk_i   => sys_clk_125,
      sys_rst_n_i => fmc0_rst_n,

      wb_ddr_clk_i   => sys_clk_125,
      wb_ddr_dat_o   => fmc_data_o,

      ext_trigger_p_i => ext_trigger_p_i,
      ext_trigger_n_i => ext_trigger_n_i,

      adc_dco_p_i  => adc_dco_p_i,
      adc_dco_n_i  => adc_dco_n_i,
      adc_fr_p_i   => adc_fr_p_i,
      adc_fr_n_i   => adc_fr_n_i,
      adc_outa_p_i => adc_outa_p_i,
      adc_outa_n_i => adc_outa_n_i,
      adc_outb_p_i => adc_outb_p_i,
      adc_outb_n_i => adc_outb_n_i,
      
      gpio_dac_clr_n_o => gpio_dac_clr_n_o,
      gpio_led_acq_o   => gpio_led_acq_o,
      gpio_led_trig_o  => gpio_led_trig_o,
      gpio_si570_oe_o  => gpio_si570_oe_o,
      
      spi_din_i       => spi_din_i,
      spi_dout_o      => spi_dout_o,
      spi_sck_o       => spi_sck_o,
      spi_cs_adc_n_o  => spi_cs_adc_n_o,
      spi_cs_dac1_n_o => spi_cs_dac1_n_o,
      spi_cs_dac2_n_o => spi_cs_dac2_n_o,
      spi_cs_dac3_n_o => spi_cs_dac3_n_o,
      spi_cs_dac4_n_o => spi_cs_dac4_n_o,
      
      si570_scl_b => si570_scl_b,
      si570_sda_b => si570_sda_b,
      
      mezz_one_wire_b => mezz_one_wire_b,
      
      sys_scl_b => open,
      sys_sda_b => open,
      
      fsm_cmd_i           => fsm_cmd_i(1 downto 0),
      fsm_cmd_wstb        => fsm_cmd_wstb,
      fmc_clk_oe          => fmc_clk_oe(0),
      offset_dac_clr      => offset_dac_clr(0),
      test_data_en        => test_data_en(0),
      man_bitslip         => man_bitslip(0),
      fsm_status          => fsm_status(2 downto 0),
      serdes_pll_sta      => serdes_pll_sta(0),
      fs_freq             => fs_freq,
      serdes_synced_sta   => serdes_synced_sta(0),
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
      type_code           => type_code(0),
      type_code_wstb      => type_code_wstb,
      spi_reg_2           => spi_reg_2,
      spi_offset_1        => spi_offset_1,
      spi_offset_2        => spi_offset_2,
      spi_offset_3        => spi_offset_3,
      spi_offset_4        => spi_offset_4,
      spi_offset_1_wstb   => spi_offset_1_wstb,
      spi_offset_2_wstb   => spi_offset_2_wstb,
      spi_offset_3_wstb   => spi_offset_3_wstb,
      spi_offset_4_wstb   => spi_offset_4_wstb,
      
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
      fmc_val1            => fmc_val1(15 downto 0),
      fmc_val2            => fmc_val2(15 downto 0),
      fmc_val3            => fmc_val3(15 downto 0),
      fmc_val4            => fmc_val4(15 downto 0)
      );

gpio_ssr_ch1_o   <= fmc_ssr1(6 downto 0);
gpio_ssr_ch2_o   <= fmc_ssr2(6 downto 0);
gpio_ssr_ch3_o   <= fmc_ssr3(6 downto 0);
gpio_ssr_ch4_o   <= fmc_ssr4(6 downto 0);


in_data_ch1_o(0) <= ZEROS(16) & fmc_data_o(15 downto 0);
in_data_ch2_o(0) <= ZEROS(16) & fmc_data_o(31 downto 16);
in_data_ch3_o(0) <= ZEROS(16) & fmc_data_o(47 downto 32);
in_data_ch4_o(0) <= ZEROS(16) & fmc_data_o(63 downto 48);

val1_o(0) <= ZEROS(16) & fmc_val1(15 downto 0);
val2_o(0) <= ZEROS(16) & fmc_val2(15 downto 0);
val3_o(0) <= ZEROS(16) & fmc_val3(15 downto 0);
val4_o(0) <= ZEROS(16) & fmc_val4(15 downto 0);


fmc_ctrl : entity work.fmc_adc_100m_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    -- Block Parameters
    FSM_CMD             => fsm_cmd_i,
    FSM_CMD_WSTB        => fsm_cmd_wstb,
    CLK_ENABLE          => fmc_clk_oe,
    DAC_OFFSET_CLR      => offset_dac_clr,
    TEST_DATA           => test_data_en,
    MAN_BITSLIP         => man_bitslip,
    FSM_STATUS          => fsm_status,
    SERDES_PLL_STA      => serdes_pll_sta,
    ACQ_FREQ            => fs_freq,
    SAMPLE_RATE         => sample_rate,
    TYPE_CODE           => type_code,
    TYPE_CODE_WSTB      => type_code_wstb,
    SPI_REG_2           => open,
    SPI_REG_2_WSTB      => spi_reg_2,
    SPI_OFFSET_1        => spi_offset_1,
    SPI_OFFSET_1_WSTB   => spi_offset_1_wstb,
    SPI_OFFSET_2        => spi_offset_2,
    SPI_OFFSET_2_WSTB   => spi_offset_2_wstb,
    SPI_OFFSET_3        => spi_offset_3,
    SPI_OFFSET_3_WSTB   => spi_offset_3_wstb,
    SPI_OFFSET_4        => spi_offset_4,
    SPI_OFFSET_4_WSTB   => spi_offset_4_wstb,
    SERDES_SYNCED_STA   => serdes_synced_sta,
    ACQ_CFG_STA         => acq_cfg_sta,
    PRE_TRIG            => pre_trig,
    POS_TRIG            => pos_trig,
    SHOTS_NB            => shots_nb,
    SW_TRIG_from_bus    => sw_trig,
    SW_TRIG_EN          => sw_trig_en,
    TRIG_DELAY          => trig_delay,
    HW_TRIG_SEL         => hw_trig_sel,
    HW_TRIG_POL         => hw_trig_pol,
    HW_TRIG_EN          => hw_trig_en,
    INT_TRIG_SEL        => int_trig_sel,
    INT_TRIG_TEST       => int_trig_test,
    INT_TRIG_THRES_FILT => int_trig_thres_filt,
    INT_TRIG_THRES      => int_trig_thres,
    SINGLE_SHOT         => single_shot,
    SHOTS_CNT           => shots_cnt,
    FIFO_EMPTY          => fmc_fifo_empty,
    SAMPLES_CNT         => samples_cnt,
    FIFO_WR_CNT         => fifo_wr_cnt,
    WAIT_CNT            => wait_cnt,
    PRE_TRIG_CNT        => pre_trig_cnt,
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
    SSR1                => fmc_ssr1,
    SSR2                => fmc_ssr2,
    SSR3                => fmc_ssr3,
    SSR4                => fmc_ssr4,
    SOFT_RESET          => open,
    SOFT_RESET_WSTB     => SOFT_RESET,
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

