--------------------------------------------------------------------------------
-- CERN (BE-CO-HT)
-- FMC ADC mezzanine
-- http://www.ohwr.org/projects/fmc-adc-100m14b4cha
--------------------------------------------------------------------------------
--
-- unit name: fmc_adc_mezzanine (fmc_adc_mezzanine.vhd)
--
-- author: Matthieu Cattin (matthieu.cattin@cern.ch)
--
-- date: 07-05-2013
--
-- description: The FMC ADC mezzanine is wrapper around the fmc-adc-100ms core and
--              the other wishbone slaves connected to a FMC ADC mezzanine.
--
-- dependencies:
--
-- references:
--
--------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--------------------------------------------------------------------------------
-- This source file is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Lesser General Public License as published by the
-- Free Software Foundation; either version 2.1 of the License, or (at your
-- option) any later version. This source is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
-- of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU Lesser General Public License for more details. You should have
-- received a copy of the GNU Lesser General Public License along with this
-- source; if not, download it from http://www.gnu.org/licenses/lgpl-2.1.html
--------------------------------------------------------------------------------
-- last changes: see git log.
--------------------------------------------------------------------------------
-- TODO: - 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.fmc_adc_100Ms_core_pkg.all;


entity fmc_adc_mezzanine is
  generic(
    g_multishot_ram_size : natural := 2048
    );
  port (
    -- Clock, reset
    sys_clk_i   : in std_logic;
    sys_rst_n_i : in std_logic;

    -- DDR wishbone interface
    wb_ddr_clk_i   : in  std_logic;
    wb_ddr_dat_o   : out std_logic_vector(63 downto 0);

    -- FMC interface
    ext_trigger_p_i : in std_logic;     -- External trigger
    ext_trigger_n_i : in std_logic;

    adc_dco_p_i  : in std_logic;                     -- ADC data clock
    adc_dco_n_i  : in std_logic;
    adc_fr_p_i   : in std_logic;                     -- ADC frame start
    adc_fr_n_i   : in std_logic;
    adc_outa_p_i : in std_logic_vector(3 downto 0);  -- ADC serial data (odd bits)
    adc_outa_n_i : in std_logic_vector(3 downto 0);
    adc_outb_p_i : in std_logic_vector(3 downto 0);  -- ADC serial data (even bits)
    adc_outb_n_i : in std_logic_vector(3 downto 0);

    gpio_dac_clr_n_o : out std_logic;                     -- offset DACs clear (active low)
    gpio_led_acq_o   : out std_logic;                     -- Mezzanine front panel power LED (PWR)
    gpio_led_trig_o  : out std_logic;                     -- Mezzanine front panel trigger LED (TRIG)
    gpio_si570_oe_o  : out std_logic;                     -- Si570 (programmable oscillator) output enable

    spi_din_i       : in  std_logic;    -- SPI data from FMC
    spi_dout_o      : out std_logic;    -- SPI data to FMC
    spi_sck_o       : out std_logic;    -- SPI clock
    spi_cs_adc_n_o  : inout std_logic;    -- SPI ADC chip select (active low)
    spi_cs_dac1_n_o : out std_logic;    -- SPI channel 1 offset DAC chip select (active low)
    spi_cs_dac2_n_o : out std_logic;    -- SPI channel 2 offset DAC chip select (active low)
    spi_cs_dac3_n_o : out std_logic;    -- SPI channel 3 offset DAC chip select (active low)
    spi_cs_dac4_n_o : out std_logic;    -- SPI channel 4 offset DAC chip select (active low)

    si570_scl_b : inout std_logic;      -- I2C bus clock (Si570)
    si570_sda_b : inout std_logic;      -- I2C bus data (Si570)

    mezz_one_wire_b : inout std_logic;  -- Mezzanine 1-wire interface (DS18B20 thermometer + unique ID)

    sys_scl_b : inout std_logic;        -- Mezzanine system I2C clock (EEPROM)
    sys_sda_b : inout std_logic;        -- Mezzanine system I2C data (EEPROM)
    
    -- Control and Status Register
    fsm_cmd_i           : in  std_logic_vector(1 downto 0);
    fsm_cmd_wstb        : in  std_logic;
    fmc_clk_oe          : in  std_logic;
    offset_dac_clr      : in  std_logic;
    test_data_en        : in  std_logic;
    man_bitslip         : in  std_logic;
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
    type_code           : in  std_logic;
    type_code_wstb      : in  std_logic;
    spi_reg_2           : in  std_logic;
    spi_offset_1        : in  std_logic_vector(31 downto 0);
    spi_offset_2        : in  std_logic_vector(31 downto 0);
    spi_offset_3        : in  std_logic_vector(31 downto 0);
    spi_offset_4        : in  std_logic_vector(31 downto 0);
    spi_offset_1_wstb   : in  std_logic;
    spi_offset_2_wstb   : in  std_logic;
    spi_offset_3_wstb   : in  std_logic;
    spi_offset_4_wstb   : in  std_logic;
    
    fsm_status          : out std_logic_vector(2  downto 0);
    serdes_pll_sta      : out std_logic;
    fs_freq             : out std_logic_vector(31 downto 0);
    serdes_synced_sta   : out std_logic;
    acq_cfg_sta         : out std_logic;
    single_shot         : out std_logic;
    shots_cnt           : out std_logic_vector(15 downto 0);
    fmc_fifo_empty      : out std_logic;
    samples_cnt         : out std_logic_vector(31 downto 0);
    fifo_wr_cnt         : out std_logic_vector(31 downto 0);
    wait_cnt            : out std_logic_vector(31 downto 0);
    pre_trig_cnt        : out std_logic_vector(31 downto 0);
    
    -- Gain/offset calibration
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
    fmc_val1            : out std_logic_vector(15 downto 0);
    fmc_val2            : out std_logic_vector(15 downto 0);
    fmc_val3            : out std_logic_vector(15 downto 0);
    fmc_val4            : out std_logic_vector(15 downto 0)
    );
end fmc_adc_mezzanine;


architecture rtl of fmc_adc_mezzanine is

  constant DEBUG_ILA     : string  := "TRUE";


  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------

  -- Mezzanine system I2C for EEPROM
  signal sys_scl_in   : std_logic;
  signal sys_scl_out  : std_logic;
  signal sys_scl_oe_n : std_logic;
  signal sys_sda_in   : std_logic;
  signal sys_sda_out  : std_logic;
  signal sys_sda_oe_n : std_logic;

  -- Mezzanine SPI
  signal spi_din_t      : std_logic_vector(3 downto 0);
  signal spi_ss_t       : std_logic_vector(7 downto 0);
  signal wr_req         : std_logic;
  signal wr_dat         : std_logic_vector(15 downto 0);
  signal wr_adr         : std_logic_vector( 6 downto 0);
  signal spi_cs         : std_logic_vector( 2 downto 0);
  signal busy_ltc       : std_logic;
  signal busy_max       : std_logic;
  signal spi_dout_o_ltc : std_logic;
  signal spi_dout_o_max : std_logic;
  signal spi_sck_o_ltc  : std_logic;
  signal spi_sck_o_max  : std_logic;

  -- Mezzanine I2C for Si570
  signal si570_scl_in   : std_logic;
  signal si570_scl_out  : std_logic;
  signal si570_scl_oe_n : std_logic;
  signal si570_sda_in   : std_logic;
  signal si570_sda_out  : std_logic;
  signal si570_sda_oe_n : std_logic;

  -- Mezzanine 1-wire
  signal mezz_owr_en : std_logic_vector(0 downto 0);
  signal mezz_owr_i  : std_logic_vector(0 downto 0);

  -- Time-tagging core
  signal trigger_p   : std_logic;
  signal acq_start_p : std_logic;
  signal acq_stop_p  : std_logic;
  signal acq_end_p   : std_logic;

    -- CHIPSCOPE ILA probes
  signal probe0               : std_logic_vector(31 downto 0);
  -- signal probe1               : std_logic_vector(31 downto 0);
  -- signal probe2               : std_logic_vector(31 downto 0);
  -- signal probe3               : std_logic_vector(31 downto 0);

  attribute keep : string;--keep name for ila probes
  attribute keep of spi_din_t      : signal is "true";
  attribute keep of spi_ss_t       : signal is "true";
  attribute keep of spi_din_i      : signal is "true";
  attribute keep of wr_adr         : signal is "true";
  attribute keep of wr_dat         : signal is "true";
  attribute keep of wr_req         : signal is "true";
  attribute keep of spi_cs_adc_n_o : signal is "true";
  attribute keep of type_code_wstb : signal is "true";

begin
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
  --    ADC control
  --    Offset DACs control
  ------------------------------------------------------------------------------
  cmp_spi_ltc2174 : entity work.spi_ltc2174
    generic map(
        SYS_PERIOD  => 8,    -- Sys clock [ns]
        CLK_PERIOD  => 1612, -- [n] : 1.6us
        DEAD_PERIOD => 30000 -- [n] : 30us
    )
    port map(
        clk_i      => sys_clk_i,
        reset_i    => not(sys_rst_n_i),
        -- Transaction interface
        wr_rst_i   => '0',
        wr_req_i   => wr_req,
        wr_adr_i   => wr_adr,
        wr_dat_i   => wr_dat(7 downto 0),
        busy_o     => busy_ltc,
        -- Serial Physical interface
        spi_sclk_o => spi_sck_o_ltc,
        spi_dat_o  => spi_dout_o_ltc,
        spi_sclk_i => sys_clk_i,
        spi_dat_i  => spi_din_i
        );
    
  cmp_spi_max5442 : entity work.spi_max5442
    generic map(
        SYS_PERIOD  => 8,    -- Sys clock [ns]
        CLK_PERIOD  => 1612, -- [n] : 1.6us
        DEAD_PERIOD => 30000 -- [n] : 30us
    )
    port map(
        clk_i      => sys_clk_i,
        reset_i    => not(sys_rst_n_i),
        -- Transaction interface
        wr_rst_i   => '0',
        wr_req_i   => wr_req,
        wr_dat_i   => wr_dat(15 downto 0),
        busy_o     => busy_max,
        -- Serial Physical interface
        spi_sclk_o => spi_sck_o_max,
        spi_dat_o  => spi_dout_o_max,
        spi_sclk_i => sys_clk_i,
        spi_dat_i  => spi_din_i
        );
    
    
  p_fmc_spi : process(sys_clk_i)
    begin
    if rising_edge(sys_clk_i) then
        if (sys_rst_n_i = '0') then
            wr_req <= '0';
            wr_adr <= (others => '0');
            wr_dat <= (others => '0');
        else
            -- Cycle through registers contiuously.
            if (busy_ltc = '0'and busy_max = '0') then
              wr_req <= '0';
              spi_cs_adc_n_o  <= '1';
              spi_cs_dac1_n_o <= '1';
              spi_cs_dac2_n_o <= '1';
              spi_cs_dac3_n_o <= '1';
              spi_cs_dac4_n_o <= '1';
              if (type_code_wstb = '1') then
                wr_req <= '1';
                wr_adr <= "0000001"; -- format and power down register
                wr_dat( 7 downto 0) <= "00" & type_code & "00000"; -- bit 5 correspond to the type code
                wr_dat(15 downto 8) <= (others => '0');
                spi_cs_adc_n_o <= '0';
                spi_cs <= "000";
                spi_dout_o <= spi_dout_o_ltc;
                spi_sck_o  <= spi_sck_o_ltc;
              end if;
              if (spi_reg_2 = '1') then
                wr_req <= '1';
                wr_adr <= "0000010"; -- output mode register
                wr_dat <= (others => '0');
                spi_cs_adc_n_o <= '0';
                spi_cs <= "001";
                spi_dout_o <= spi_dout_o_ltc;
                spi_sck_o  <= spi_sck_o_ltc;
              end if;
              if (spi_offset_1_wstb = '1') then
                wr_req <= '1';
                wr_dat <= spi_offset_1(15 downto 0);
                spi_cs_dac1_n_o <= '0';
                spi_cs <= "010";
                spi_dout_o <= spi_dout_o_max;
                spi_sck_o  <= spi_sck_o_max;
              end if;
              if (spi_offset_2_wstb = '1') then
                wr_req <= '1';
                wr_dat <= spi_offset_2(15 downto 0);
                spi_cs_dac2_n_o <= '0';
                spi_cs <= "011";
                spi_dout_o <= spi_dout_o_max;
                spi_sck_o  <= spi_sck_o_max;
              end if;
              if (spi_offset_3_wstb = '1') then
                wr_req <= '1';
                wr_dat <= spi_offset_3(15 downto 0);
                spi_cs_dac3_n_o <= '0';
                spi_cs <= "100";
                spi_dout_o <= spi_dout_o_max;
                spi_sck_o  <= spi_sck_o_max;
              end if;
              if (spi_offset_4_wstb = '1') then
                wr_req <= '1';
                wr_dat <= spi_offset_4(15 downto 0);
                spi_cs_dac4_n_o <= '0';
                spi_cs <= "101";
                spi_dout_o <= spi_dout_o_max;
                spi_sck_o  <= spi_sck_o_max;
              end if;
            -- if busy = 1, continue to write
            elsif(spi_cs = "000") then
              spi_cs_adc_n_o  <= '0';
              spi_dout_o      <= spi_dout_o_ltc;
              spi_sck_o       <= spi_sck_o_ltc;
            elsif(spi_cs = "001") then
              spi_cs_adc_n_o  <= '0';
              spi_dout_o      <= spi_dout_o_ltc;
              spi_sck_o       <= spi_sck_o_ltc;
            elsif(spi_cs = "010") then
              spi_cs_dac1_n_o <= '0';
              spi_dout_o      <= spi_dout_o_max;
              spi_sck_o       <= spi_sck_o_max;
            elsif(spi_cs = "011") then
              spi_cs_dac2_n_o <= '0';
              spi_dout_o      <= spi_dout_o_max;
              spi_sck_o       <= spi_sck_o_max;
            elsif(spi_cs = "100") then
              spi_cs_dac3_n_o <= '0';
              spi_dout_o      <= spi_dout_o_max;
              spi_sck_o       <= spi_sck_o_max;
            elsif(spi_cs = "101") then
              spi_cs_dac4_n_o <= '0';
              spi_dout_o      <= spi_dout_o_max;
              spi_sck_o       <= spi_sck_o_max;
            end if;
        end if;
    end if;
  end process p_fmc_spi;

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
  cmp_fmc_adc_100Ms_core : fmc_adc_100Ms_core
    generic map (
      g_multishot_ram_size => g_multishot_ram_size
      )
    port map(
      sys_clk_i   => sys_clk_i,
      sys_rst_n_i => sys_rst_n_i,

      wb_ddr_clk_i   => sys_clk_i,
      wb_ddr_dat_o   => wb_ddr_dat_o,

      trigger_p_o   => trigger_p,
      acq_start_p_o => acq_start_p,
      acq_stop_p_o  => acq_stop_p,
      acq_end_p_o   => acq_end_p,

      --trigger_tag_i => trigger_tag,

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

      fsm_cmd_i      => fsm_cmd_i,
      fsm_cmd_wstb   => fsm_cmd_wstb,
      fmc_clk_oe     => fmc_clk_oe,
      fmc_adc_core_ctl_offset_dac_clr_n_o      => offset_dac_clr,
      fmc_adc_core_ctl_test_data_en_o          => test_data_en,
      fmc_adc_core_ctl_man_bitslip_o           => man_bitslip,
      
      fmc_adc_core_sta_fsm_i                      => fsm_status,
      fmc_adc_core_sta_serdes_pll_i               => serdes_pll_sta,
      fmc_adc_core_fs_freq_i                      => fs_freq,
      fmc_adc_core_sta_serdes_synced_i            => serdes_synced_sta,
      fmc_adc_core_sta_acq_cfg_i                  => acq_cfg_sta,
      fmc_adc_core_pre_samples_o                  => pre_trig,
      fmc_adc_core_post_samples_o                 => pos_trig,
      fmc_adc_core_shots_nb_o                     => shots_nb,
      fmc_adc_core_sw_trig_wr_o                   => sw_trig,
      fmc_adc_core_trig_cfg_sw_trig_en_o          => sw_trig_en,
      fmc_adc_core_trig_dly_o                     => trig_delay,
      fmc_adc_core_trig_cfg_hw_trig_sel_o         => hw_trig_sel,
      fmc_adc_core_trig_cfg_hw_trig_pol_o         => hw_trig_pol,
      fmc_adc_core_trig_cfg_hw_trig_en_o          => hw_trig_en,
      fmc_adc_core_trig_cfg_int_trig_sel_o        => int_trig_sel,
      fmc_adc_core_trig_cfg_int_trig_test_en_o    => int_trig_test,
      fmc_adc_core_trig_cfg_int_trig_thres_filt_o => int_trig_thres_filt,
      fmc_adc_core_trig_cfg_int_trig_thres_o      => int_trig_thres,
      fmc_adc_core_sr_deci_o                      => sample_rate,
      
      fmc_single_shot               => single_shot,
      fmc_adc_core_shots_cnt_val_i  => shots_cnt,
      fmc_fifo_empty                => fmc_fifo_empty,
      fmc_adc_core_samples_cnt_i    => samples_cnt,
      fifo_wr_cnt                   => fifo_wr_cnt,
      wait_cnt                      => wait_cnt,
      pre_trig_count                => pre_trig_cnt,
      
      fmc_adc_core_ch1_gain_val_o   => fmc_gain1,
      fmc_adc_core_ch2_gain_val_o   => fmc_gain2,
      fmc_adc_core_ch3_gain_val_o   => fmc_gain3,
      fmc_adc_core_ch4_gain_val_o   => fmc_gain4,
      fmc_adc_core_ch1_offset_val_o => fmc_offset1,
      fmc_adc_core_ch2_offset_val_o => fmc_offset2,
      fmc_adc_core_ch3_offset_val_o => fmc_offset3,
      fmc_adc_core_ch4_offset_val_o => fmc_offset4,
      fmc_adc_core_ch1_sat_val_o    => fmc_sat1,
      fmc_adc_core_ch2_sat_val_o    => fmc_sat2,
      fmc_adc_core_ch3_sat_val_o    => fmc_sat3,
      fmc_adc_core_ch4_sat_val_o    => fmc_sat4,
      
      fmc_adc_core_ch1_sta_val_i    => fmc_val1,
      fmc_adc_core_ch2_sta_val_i    => fmc_val2,
      fmc_adc_core_ch3_sta_val_i    => fmc_val3,
      fmc_adc_core_ch4_sta_val_i    => fmc_val4
      );

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
    --port map(
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

  ---------------------------------------------------------------------------
-- Chipscope ILA Debug purpose
-----------------------------------------------------------------------------
--ILA_GEN : IF (DEBUG_ILA= "TRUE") GENERATE--false GENERATE--
   --My_chipscope_ila_probe_0 : entity work.ila_32x8K
     --PORT MAP(
       --clk    => sys_clk_i,
       --probe0 => probe0
       --);

   --probe0(26 downto 0) <= wr_adr&         -- 7  bit
                          --wr_dat&         -- 16 bit
                          --wr_req&         -- 1  bit
                          --spi_cs_adc_n_o& -- 1  bit
                          --type_code_wstb& -- 1  bit
                          --spi_din_i;      -- 1  bit --> SUM = 28 bits

   --probe0(31 downto 27) <= (others=>'0');

--END GENERATE;

end rtl;
