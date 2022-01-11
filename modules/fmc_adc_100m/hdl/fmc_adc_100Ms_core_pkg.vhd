--------------------------------------------------------------------------------
-- CERN (BE-CO-HT)
-- FMC ADC 100Ms/s core package
-- http://www.ohwr.org/projects/fmc-adc-100m14b4cha
--------------------------------------------------------------------------------
--
-- unit name: fmc_adc_100Ms_core_pkg (fmc_adc_100Ms_core_pkg.vhd)
--
-- author: Matthieu Cattin (matthieu.cattin@cern.ch)
--
-- date: 16-11-2012
--
-- version: 1.0
--
-- description: Package for FMC ADC 100Ms/s core
--
-- dependencies:
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
-- last changes: see svn log.
--------------------------------------------------------------------------------
-- TODO: - 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
--use work.timetag_core_pkg.all;


package fmc_adc_100Ms_core_pkg is

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------


  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------
  component fmc_adc_100Ms_core
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

      -- Events output pulses
      trigger_p_o   : out std_logic;
      acq_start_p_o : out std_logic;
      acq_stop_p_o  : out std_logic;
      acq_end_p_o   : out std_logic;

      -- FMC interface
      ext_trigger_p_i : in std_logic;   -- External trigger
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
      gpio_si570_oe_o  : out std_logic;                      -- Si570 (programmable oscillator) output enable
      
      -- Control and status register
      fsm_cmd_i      : in std_logic_vector(1 downto 0);
      fsm_cmd_wstb   : in std_logic;
      fmc_clk_oe     : in std_logic;
      fmc_adc_core_ctl_offset_dac_clr_n_o         : in std_logic;
      fmc_adc_core_ctl_test_data_en_o             : in std_logic;
      fmc_adc_core_ctl_man_bitslip_o              : in std_logic;
      fmc_adc_core_sta_fsm_i                      : out std_logic_vector(2 downto 0);
      fmc_adc_core_sta_serdes_pll_i               : out std_logic;
      fmc_adc_core_fs_freq_i                      : out std_logic_vector(31 downto 0);
      fmc_adc_core_sta_serdes_synced_i            : out std_logic;
      fmc_adc_core_sta_acq_cfg_i                  : out std_logic;
      fmc_adc_core_pre_samples_o                  : in  std_logic_vector(31 downto 0);
      fmc_adc_core_post_samples_o                 : in  std_logic_vector(31 downto 0);
      fmc_adc_core_shots_nb_o                     : in  std_logic_vector(15 downto 0);
      fmc_adc_core_sw_trig_wr_o                   : in  std_logic;
      fmc_adc_core_trig_cfg_sw_trig_en_o          : in  std_logic;
      fmc_adc_core_trig_dly_o                     : in  std_logic_vector(31 downto 0);
      fmc_adc_core_trig_cfg_hw_trig_sel_o         : in  std_logic;
      fmc_adc_core_trig_cfg_hw_trig_pol_o         : in  std_logic;
      fmc_adc_core_trig_cfg_hw_trig_en_o          : in  std_logic;
      fmc_adc_core_trig_cfg_int_trig_sel_o        : in  std_logic_vector(1  downto 0);
      fmc_adc_core_trig_cfg_int_trig_test_en_o    : in  std_logic;
      fmc_adc_core_trig_cfg_int_trig_thres_filt_o : in  std_logic_vector(7 downto 0);
      fmc_adc_core_trig_cfg_int_trig_thres_o      : in  std_logic_vector(15 downto 0);
      fmc_adc_core_sr_deci_o                      : in  std_logic_vector(31 downto 0);
      
      fmc_single_shot               : out std_logic;
      fmc_adc_core_shots_cnt_val_i  : out std_logic_vector(15 downto 0);
      fmc_fifo_empty                : out std_logic;
      fmc_adc_core_samples_cnt_i    : out std_logic_vector(31 downto 0);
      fifo_wr_cnt                   : out std_logic_vector(31 downto 0);
      wait_cnt                      : out std_logic_vector(31 downto 0);
      pre_trig_count                : out std_logic_vector(31 downto 0);

         -- Channel1 register
      fmc_adc_core_ch1_sta_val_i    : out std_logic_vector(15 downto 0);
      fmc_adc_core_ch1_gain_val_o   : in  std_logic_vector(15 downto 0);
      fmc_adc_core_ch1_offset_val_o : in  std_logic_vector(15 downto 0);
      fmc_adc_core_ch1_sat_val_o    : in  std_logic_vector(14 downto 0);
          -- Channel2 register
      fmc_adc_core_ch2_sta_val_i    : out std_logic_vector(15 downto 0);
      fmc_adc_core_ch2_gain_val_o   : in  std_logic_vector(15 downto 0);
      fmc_adc_core_ch2_offset_val_o : in  std_logic_vector(15 downto 0);
      fmc_adc_core_ch2_sat_val_o    : in  std_logic_vector(14 downto 0);
          -- Channel3 register
      fmc_adc_core_ch3_sta_val_i    : out std_logic_vector(15 downto 0);
      fmc_adc_core_ch3_gain_val_o   : in  std_logic_vector(15 downto 0);
      fmc_adc_core_ch3_offset_val_o : in  std_logic_vector(15 downto 0);
      fmc_adc_core_ch3_sat_val_o    : in  std_logic_vector(14 downto 0);
          -- Channel4 register
      fmc_adc_core_ch4_sta_val_i    : out std_logic_vector(15 downto 0);
      fmc_adc_core_ch4_gain_val_o   : in  std_logic_vector(15 downto 0);
      fmc_adc_core_ch4_offset_val_o : in  std_logic_vector(15 downto 0);
      fmc_adc_core_ch4_sat_val_o    : in  std_logic_vector(14 downto 0)
      );
  end component fmc_adc_100Ms_core;

end fmc_adc_100Ms_core_pkg;

package body fmc_adc_100Ms_core_pkg is



end fmc_adc_100Ms_core_pkg;
