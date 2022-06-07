--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : FMC-ADC-100M-14b4Cha on NAMC-ZYNQ-FMC board
-- Design name    : fmc_adc_types.vhd
-- Description    : Local Types for the FMC_ADC100M
--
-- Author         : Thierry GARREL (ELSYS-Design)
-- Synthesizable  : Yes
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2022 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package fmc_adc_types is

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  constant C_ADC_CHANNELS   : natural := 4; -- Number of ADC channels

  ------------------------------------------------------------------------------
  -- Types declaration
  ------------------------------------------------------------------------------
  type fmc_gain_array   is array(natural range <>) of std_logic_vector(15 downto 0);
  type fmc_offset_array is array(natural range <>) of std_logic_vector(15 downto 0);
  type fmc_sat_array    is array(natural range <>) of std_logic_vector(14 downto 0);

  type std1_array       is  array(natural range <>) of std_logic;--_vector(0 downto 0);
  type std8_array       is  array(natural range <>) of std_logic_vector(7 downto 0);
  type std15_array      is  array(natural range <>) of std_logic_vector(14 downto 0);
  type std16_array      is  array(natural range <>) of std_logic_vector(15 downto 0);

  type adc_data_ch_array is array(natural range <>) of std_logic_vector(15 downto 0);
  type fmc_dataout_array is array(natural range <>) of std_logic_vector(15 downto 0);

  type uns12_array      is  array(natural range <>) of unsigned(11 downto 0);
  type uns16_array      is  array(natural range <>) of unsigned(15 downto 0);


end package fmc_adc_types;



