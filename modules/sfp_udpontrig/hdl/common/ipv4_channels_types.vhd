--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : PandABox FPGA
-- Design name    : sfp_udpontrig
-- Module name    : ipv4_channels_types.vhd
-- Purpose        : this package defines types for use in IPv4
-- Author         : Thierry GARREL (ELSYS-Design)
--
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
  use IEEE.math_real.all; -- use to compute log2(c_max_channels)

library work;
  use work.axi_types.all;
  use work.ipv4_types.all;


--==============================================================================
-- Package Declaration
--==============================================================================
package ipv4_channels_types is

    -----------------------
    -- IPv4 TX channels  --
    -----------------------
    -- ip_tx_start           : in  std_logic;
    -- ip_tx                 : in  ipv4_tx_type;                   -- IP tx cxns
    -- ip_tx_result          : out std_logic_vector(1 downto 0);  -- tx status (changes during transmission)
    -- ip_tx_data_out_ready  : out std_logic;                      -- indicates IP TX is ready to take data

    type ip_tx_start_array          is array (natural range <>) of std_logic;
    type ip_tx_bus_array            is array (natural range <>) of ipv4_tx_type;
    type ip_tx_result_array         is array (natural range <>) of ip_tx_result_type; -- defined in ipv4_types package
    type ip_tx_dout_ready_array     is array (natural range <>) of std_logic;


    --------------------------------------
    -- Maximum number of IP TX channels --
    --------------------------------------
    constant C_MAX_CHANNELS       : natural := 8;
    constant C_LOG2_MAX_CHANNELS  : natural := natural(ceil(log2(real(C_MAX_CHANNELS))));



end ipv4_channels_types;
--==============================================================================
-- Package End
--==============================================================================
