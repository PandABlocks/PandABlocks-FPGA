--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : PandABox FPGA
-- Design name    : sfp_udpontrig
-- Module name    : axi_types.vhd
-- Purpose:       : This package defines data types for AXI transfers
-- Author         : Thierry GARREL (ELSYS-Design)
--                  from Opencores udp_ip_stack project tag v2.6 (axi.vhd)
-- Synthesizable  : YES
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2021 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------



--==============================================================================
-- Libraries Declaration
--==============================================================================
library IEEE;
  use IEEE.std_logic_1164.all;


--==============================================================================
-- Package Declaration
--==============================================================================
package axi_types is

  ------------
  -- AXI in --
  ------------
  type axi_in_type is record
    data_in             : std_logic_vector(7 downto 0);
    data_in_valid       : std_logic;                      -- indicates data_in valid on clock
    data_in_last        : std_logic;                      -- indicates last data in frame
  end record;

  -------------
  -- AXI out --
  -------------
  type axi_out_type is record
    data_out_valid      : std_logic;                      -- indicates data out is valid
    data_out_last       : std_logic;                      -- with data out valid indicates the last byte of a frame
    data_out            : std_logic_vector(7 downto 0);   -- ethernet frame (from dst mac addr through to last byte of frame)
  end record;


end axi_types;
--==============================================================================
-- Package End
--==============================================================================

