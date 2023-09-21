--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : PandABox FPGA
-- Design name    : sfp_udpontrig
-- Module name    : ipv4_types.vhd
-- Purpose        : this package defines types for use in IPv4
-- Author         : Thierry GARREL (ELSYS-Design)
--                  from Opencores udp_ip_stack project tag v2.6
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

library work;
  use work.axi_types.all;
  use work.arp_types.all;


--==============================================================================
-- Package Declaration
--==============================================================================
package ipv4_types is

  -- IP and MAC broadcast addresses
  constant IP_BC_ADDR           : std_logic_vector(31 downto 0) := x"FFFFFFFF";
  constant MAC_BC_ADDR          : std_logic_vector(47 downto 0) := x"FFFFFFFFFFFF";


    --------------
    -- IPv4 RX  --
    --------------
  subtype ip_rx_error_type is std_logic_vector(3 downto 0); -- TGA

  -- coding for last_error_code in rx hdr
  constant RX_EC_NONE           : std_logic_vector(3 downto 0) := x"0";
  constant RX_EC_ET_ETH         : std_logic_vector(3 downto 0) := x"1"; -- early termination in ETH hdr phase
  constant RX_EC_ET_IP          : std_logic_vector(3 downto 0) := x"2"; -- early termination in IP hdr phase
  constant RX_EC_ET_USER        : std_logic_vector(3 downto 0) := x"3"; -- early termination in USER DATA phase

  type ipv4_rx_header_type is record
    is_valid                    : std_logic;
    protocol                    : std_logic_vector( 7 downto 0);
    data_length                 : std_logic_vector(15 downto 0);  -- user data size, bytes
    src_ip_addr                 : std_logic_vector(31 downto 0);
    num_frame_errors            : std_logic_vector( 7 downto 0);
    last_error_code             : std_logic_vector( 3 downto 0);  -- see RX_EC_xxx constants
    is_broadcast                : std_logic;                      -- set if the msg received is a broadcast
  end record;

  type ipv4_rx_type is record
    hdr                         : ipv4_rx_header_type;    -- header received
    data                        : axi_in_type;            -- rx axi bus
  end record;

  type ip_control_type is record
    arp_controls                : arp_control_type;
  end record;

  -- TGA
  constant C_IPV4_RX_HEADER_NULL  : ipv4_rx_header_type := (
    is_valid                      => '0',
    protocol                      => (others=>'0'),
    data_length                   => (others=>'0'),
    src_ip_addr                   => (others=>'0'),
    num_frame_errors              => (others=>'0'),
    last_error_code               => (others=>'0'),
    is_broadcast                  => '0'
  );

  -- TGA
  constant C_AXI_IN_DATA_NULL  : axi_in_type := (
    data_in                     => (others=>'0'),
    data_in_valid               => '0',
    data_in_last                => '0'
  );


  --------------
  -- IPv4 TX  --
  --------------
  subtype ip_tx_result_type is std_logic_vector(1 downto 0); -- TGA

  -- coding for result in tx
  constant IPTX_RESULT_NONE     : std_logic_vector(1 downto 0) := "00"; -- 0
  constant IPTX_RESULT_SENDING  : std_logic_vector(1 downto 0) := "01"; -- 1 sending
  constant IPTX_RESULT_ERR      : std_logic_vector(1 downto 0) := "10"; -- 2
  constant IPTX_RESULT_SENT     : std_logic_vector(1 downto 0) := "11"; -- 3 sent


  type ipv4_tx_header_type is record
    protocol                    : std_logic_vector( 7 downto 0);
    data_length                 : std_logic_vector(15 downto 0);  -- user data size, bytes
    dst_ip_addr                 : std_logic_vector(31 downto 0);
  end record;

  type ipv4_tx_type is record
    hdr                         : ipv4_tx_header_type;      -- header to tx
    data                        : axi_out_type;             -- tx axi bus
  end record;

  -- TGA
  constant C_IPV4_TX_HEADER_NULL  : ipv4_tx_header_type := (
    protocol                      => (others=>'0'),
    data_length                   => (others=>'0'),
    dst_ip_addr                   => (others=>'0')
  );

  -- TGA
  constant C_AXI_OUT_DATA_NULL  : axi_out_type := (
    data_out                    => (others=>'0'),
    data_out_valid              => '0',
    data_out_last               => '0'
  );


  ------------
  -- UDP TX --
  ------------
  subtype udp_tx_result_type is std_logic_vector(1 downto 0); -- TGA

  -- coding for result in tx
  constant UDPTX_RESULT_NONE    : std_logic_vector(1 downto 0) := "00";
  constant UDPTX_RESULT_SENDING : std_logic_vector(1 downto 0) := "01"; -- 1 sending
  constant UDPTX_RESULT_ERR     : std_logic_vector(1 downto 0) := "10";
  constant UDPTX_RESULT_SENT    : std_logic_vector(1 downto 0) := "11"; -- 3 sent

  type udp_tx_header_type is record
    dst_ip_addr                 : std_logic_vector(31 downto 0);
    dst_port                    : std_logic_vector(15 downto 0);
    src_port                    : std_logic_vector(15 downto 0);
    data_length                 : std_logic_vector(15 downto 0); -- user data size, bytes
    checksum                    : std_logic_vector(15 downto 0);
  end record;


  type udp_tx_type is record
    hdr                         : udp_tx_header_type;   -- header received
    data                        : axi_out_type;         -- tx axi bus
  end record;

  -- TGA
  constant C_UDP_TX_HEADER_NULL : udp_tx_header_type := (
    dst_ip_addr               => (others=>'0'),
    dst_port                  => (others=>'0'),
    src_port                  => (others=>'0'),
    data_length               => (others=>'0'),
    checksum                  => (others=>'0')
  );

  -- TGA
  constant C_UDP_TX_DATA_NULL : axi_out_type := (
    data_out                => (others=>'0'),
    data_out_valid          => '0',
    data_out_last           => '0'
  );


  ------------
  -- UDP RX --
  ------------

  type udp_rx_header_type is record
    is_valid                    : std_logic;
    src_ip_addr                 : std_logic_vector(31 downto 0);
    src_port                    : std_logic_vector(15 downto 0);
    dst_port                    : std_logic_vector(15 downto 0);
    data_length                 : std_logic_vector(15 downto 0);  -- user data size, bytes
  end record;


  type udp_rx_type is record
    hdr                         : udp_rx_header_type;   -- header received
    data                        : axi_in_type;          -- rx axi bus
  end record;

  type udp_addr_type is record
    ip_addr                     : std_logic_vector(31 downto 0);
    port_num                    : std_logic_vector(15 downto 0);
  end record;

  type udp_control_type is record
    ip_controls                 : ip_control_type;
  end record;



  end ipv4_types;
  --==============================================================================
  -- Package End
  --==============================================================================

