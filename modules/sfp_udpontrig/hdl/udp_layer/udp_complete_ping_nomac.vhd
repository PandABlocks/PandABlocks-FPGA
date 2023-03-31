--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : PandABox FPGA
-- Design name    : sfp_udpontrig
-- Module name    : udp_complete_ping_nomac.vhd
-- Purpose        : UDP_complete_nomac layer with udp_ping
--                  = udp_complete_nomac.vhd + udp_ping + ip_tx_arbitrator
--                   origin: Opencores udp_ip_stack project tag v2.6
-- Author         : Thierry GARREL (ELSYS-Design)
-- Synthesizable  : YES
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2021 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Design Architecture
-- ===================
--                                                          +---------------------+
--  UDP RX bus  +----------+                         ip_rx  |  +---------+        |  MAC Receive
--  <-----------|  udp_rx  |<--------------+-----<-------------| ipv4_rx |<---------------
--              +----------+               |                |  +---------+        |
--                                   ip_rx |                |                     |
--                                  +------v-----+          |                     |
--                                  |  udp_ping  |          |  ip_complete_nomac  |
--                                  +------+-----+          |                     |
--                                ip_tx(1) |                |                     |
--                                         |                |                     |
--                           ip_tx(0)      |                |                     |
--  UDP TX bus  +----------+     +---------v--------+ ip_tx |  +---------+        |  MAC Transmit
--  ----------->|  udp_tx  |---->| ip_tx_arbitrator |--------->| ipv4_tx |-------------->
--              +----------+     +------------------+       |  +---------+        |
--                                                          +---------------------+
--
-- Instances (component)
-- ===========================================================
--  udp_tx_inst             : udp_tx                UDP layer
--  udp_rx_inst             : udp_rx                UDP layer
--  udp_ping_inst           : udp_ping              UDP layer
--  ip_complete_inst        : ip_complete_nomac     IP layer
--  ip_tx_arbitrator_inst   : ip_tx_arbitrator      IP layer
--
--------------------------------------------------------------------------------



--==============================================================================
-- Libraries Declaration
--==============================================================================
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.axi_types.all;
  use work.arp_types.all;
  use work.ipv4_types.all;
  use work.ipv4_channels_types.all;
  use work.udp_layer_component_pkg.all;


--==============================================================================
-- Entity Declaration
--==============================================================================
entity udp_complete_ping_nomac is
  generic (
    -- ARP layer
    CLOCK_FREQ            : integer := 125000000  ; -- freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT           : integer := 60         ; -- ARP response timeout (s)
    ARP_MAX_PKT_TMO       : integer := 5          ; -- # wrong nwk pkts received before set error
    MAX_ARP_ENTRIES       : integer := 255        ; -- max entries in the ARP store
    -- ICMP layer
    MAX_PING_SIZE         : natural := 256        ; -- max ICMP pkt size in bytes (32 to 1472 bytes)
    -- ip_tx_arbiratror
    NB_TX_CHANNELS        : natural := 2            -- number of ip_tx channels (2 to C_MAX_CHANNELS)
  );
  port (
    -- System signals (in)
    rx_clk                  : in  std_logic;
    tx_clk                  : in  std_logic;
    reset                   : in  std_logic;
    our_ip_address          : in  std_logic_vector(31 downto 0);
    our_mac_address         : in  std_logic_vector(47 downto 0);
    control                 : in  udp_control_type;
    -- Status signals (out)
    arp_pkt_count           : out std_logic_vector(7 downto 0);   -- count of arp pkts received
    ip_pkt_count            : out std_logic_vector(7 downto 0);   -- number of IP pkts received for us
    icmp_pkt_count          : out std_logic_vector(7 downto 0);   -- number of ICMP pkts received for us
    icmp_pkt_err            : out std_logic;                      -- indicate an errored ICMP pkt (type <> x"0800" or pkt greater than 1472 bytes)
    icmp_pkt_err_count      : out std_logic_vector(7 downto 0);   -- number of ICMP pkts received for us
    -- UDP TX signals (in)
    udp_tx_start            : in  std_logic;                      -- indicates req to tx UDP
    udp_txi                 : in  udp_tx_type;                    -- UDP tx cxns
    udp_tx_result           : out std_logic_vector(1 downto 0);   -- tx status (changes during transmission)
    udp_tx_data_out_ready   : out std_logic;                      -- indicates udp_tx is ready to take data
    -- UDP RX signals (out)
    udp_rx_start            : out std_logic;                      -- indicates receipt of udp header
    udp_rxo                 : out udp_rx_type;
    -- IP RX signals (out) // DEBUG
    ip_rx_start_o           : out std_logic;        -- DEBUG
    ip_rx_hdr_o             : out ipv4_rx_header_type;
    ip_rx_data_o            : out axi_in_type;     -- DEBUG
    -- IP TX status (out) // DEBUG
    ip_tx_start_o           : out std_logic;
    ip_tx_result_o          : out ip_tx_result_type; -- slv(1:0)
    -- MAC Receiver (in)
    mac_rx_tdata            : in  std_logic_vector(7 downto 0);   -- data byte received
    mac_rx_tvalid           : in  std_logic;                      -- indicates tdata is valid
    mac_rx_tready           : out std_logic;                      -- tells mac that we are ready to take data
    mac_rx_tlast            : in  std_logic;                      -- indicates last byte of the trame
    -- MAC Transmitter (out)
    mac_tx_tdata            : out std_logic_vector(7 downto 0);   -- data byte to tx
    mac_tx_tvalid           : out std_logic;                      -- tdata is valid
    mac_tx_tready           : in  std_logic;                      -- mac is ready to accept data
    mac_tx_tfirst           : out std_logic;                      -- indicates first byte of frame
    mac_tx_tlast            : out std_logic                       -- indicates last byte of frame
  );
end udp_complete_ping_nomac;



--==============================================================================
-- Architcture Declaration
--==============================================================================
architecture structural of udp_complete_ping_nomac is

  ------------------------------------------------------------------------------
  -- Component Declaration for UDP TX / UDP RX / IP layer
  ------------------------------------------------------------------------------
  -- see udp_layer_component_pkg.vhd

  ------------------------
  -- Internal Signals
  ------------------------
  -- IP RX connectivity
  signal ip_rx_start_int            : std_logic;
  signal ip_rx_int                  : ipv4_rx_type;


  -- IP TX arbitrator connectivity
  -- channel 1 : udp_tx
  -- channel 2 : udp_ping

  signal ip_tx_start_bus            : ip_tx_start_array(0 to NB_TX_CHANNELS-1);
  signal ip_tx_bus                  : ip_tx_bus_array(0 to NB_TX_CHANNELS-1);
  signal ip_tx_result_bus           : ip_tx_result_array(0 to NB_TX_CHANNELS-1);
  signal ip_tx_dout_ready_bus       : ip_tx_dout_ready_array(0 to NB_TX_CHANNELS-1);

  -- IP TX connectivity
  signal ip_tx_start_int            : std_logic;
  signal ip_tx_int                  : ipv4_tx_type;
  signal ip_tx_result_int           : ip_tx_result_type; --- std_logic_vector(1 downto 0);
  signal ip_tx_data_out_ready_int   : std_logic;


--==============================================================================
-- Beginning of Code
--==============================================================================
begin


  -- ***************************************************************************
  --                  Instantiate the UDP layer
  -- ***************************************************************************

  ----------------------------------
  -- Instantiate the UDP_RX block --
  ----------------------------------
  udp_rx_inst: udp_rx
  port map (
    -- system signals
    clk                         => rx_clk,
    reset                       => reset,
    -- IP layer RX signals (in)
    ip_rx_start                 => ip_rx_start_int,
    ip_rx                       => ip_rx_int,
    -- UDP Layer signals (out)
    udp_rxo                     => udp_rxo,
    udp_rx_start                => udp_rx_start
    );

  ----------------------------------
  -- Instantiate the UDP_TX block --
  ----------------------------------
  udp_tx_inst: udp_tx
  port map (
    -- system signals (in)
    clk                         => tx_clk,
    reset                       => reset,
  -- UDP Layer signals (in)
    udp_tx_start                => udp_tx_start,                -- in
    udp_txi                     => udp_txi,                     -- in
    udp_tx_result               => udp_tx_result,               -- out
    udp_tx_data_out_ready       => udp_tx_data_out_ready,       -- out
  -- IP layer TX signals (out)
    ip_tx_start                 => ip_tx_start_bus(0),          --  out to ip_tx_arbitrator
    ip_tx                       => ip_tx_bus(0),                --  out to ip_tx_arbitrator
    ip_tx_result                => ip_tx_result_bus(0),         --  in
    ip_tx_data_out_ready        => ip_tx_dout_ready_bus(0)      --  in
  );

  ------------------------------------
  -- Instantiate the UDP_PING block --
  ------------------------------------
  udp_ping_inst : udp_ping
  generic map (
    MAX_PING_SIZE               => MAX_PING_SIZE
  )
  port map (
    -- system signals (in)
    clk                         => rx_clk,
    reset                       => reset,
    -- IP layer RX signals (in)
    ip_rx_start                 => ip_rx_start_int,
    ip_rx                       => ip_rx_int,
    -- status signals (out)
    icmp_pkt_count              => icmp_pkt_count,
    icmp_pkt_err                => icmp_pkt_err,
    icmp_pkt_err_count          => icmp_pkt_err_count,
    -- IP layer TX signals (out)
    ip_tx_start                 => ip_tx_start_bus(1),          -- out to ip_tx_arbitrator
    ip_tx                       => ip_tx_bus(1),                -- out to ip_tx_arbitrator
    ip_tx_result                => ip_tx_result_bus(1),         -- in
    ip_tx_data_out_ready        => ip_tx_dout_ready_bus(1)      -- in
  );


  -- ***************************************************************************
  --                  Instantiate the IP layer
  -- ***************************************************************************

  ----------------------------------------
  -- Instantiate ip_tx_arbitrator block --
  ----------------------------------------
  ip_tx_arbitrator_inst : ip_tx_arbitrator
  generic map (
    NB_CHANNELS                 => NB_TX_CHANNELS
  )
  port map (
    -- System signals (in)
    clk                         => tx_clk,
    reset                       => reset,
    -- IP layer TX input channels (in)
    ip_tx_start_bus             => ip_tx_start_bus,             -- in
    ip_tx_bus                   => ip_tx_bus,                   -- in
    ip_tx_result_bus            => ip_tx_result_bus,            -- out
    ip_tx_dout_ready_bus        => ip_tx_dout_ready_bus,        -- out
   -- IP layer TX signals (out)
    ip_tx_start                 => ip_tx_start_int,             -- out
    ip_tx                       => ip_tx_int,                   -- out
    ip_tx_result                => ip_tx_result_int,            -- in
    ip_tx_data_out_ready        => ip_tx_data_out_ready_int     -- in
  );


  -----------------------------------------
  -- Instantiate ip_complete_nomac block --
  -----------------------------------------
  ip_complete_inst : ip_complete_nomac
    generic map (
      use_arpv2                 => TRUE,         -- use ARP with multipule entries. for signel entry, set to FALSE
      CLOCK_FREQ                => CLOCK_FREQ,
      ARP_TIMEOUT               => ARP_TIMEOUT,
      ARP_MAX_PKT_TMO           => ARP_MAX_PKT_TMO,
      MAX_ARP_ENTRIES           => MAX_ARP_ENTRIES
    )
    port map (
      -- IP Layer TX signals (in)
      ip_tx_start               => ip_tx_start_int,             -- in
      ip_tx                     => ip_tx_int,                   -- in
      ip_tx_result              => ip_tx_result_int,            -- out to ip_tx_arbitrator
      ip_tx_data_out_ready      => ip_tx_data_out_ready_int,    -- out to ip_tx_arbitrator
      -- IP layer RX signals (out)
      ip_rx_start               => ip_rx_start_int,             -- out to udp_rx and udp_ping
      ip_rx                     => ip_rx_int,                   -- out to udp_rx and udp_ping
      -- System interface
      rx_clk                    => rx_clk,
      tx_clk                    => tx_clk,
      reset                     => reset,
      our_ip_address            => our_ip_address,
      our_mac_address           => our_mac_address,
      control                   => control.ip_controls,
      -- status signals
      arp_pkt_count             => arp_pkt_count,
      ip_pkt_count              => ip_pkt_count,
      -- MAC Transmitter
      mac_tx_tdata              => mac_tx_tdata,         -- out std_logic_vector(7 downto 0);   -- data byte to tx
      mac_tx_tvalid             => mac_tx_tvalid,       -- out std_logic;                      -- tdata is valid
      mac_tx_tready             => mac_tx_tready,       -- in  std_logic;                      -- mac is ready to accept data
      mac_tx_tfirst             => mac_tx_tfirst,       -- out std_logic;                      -- indicates first byte of frame
      mac_tx_tlast              => mac_tx_tlast,        -- out std_logic;                      -- indicates last byte of frame
      -- MAC Receiver
      mac_rx_tdata              => mac_rx_tdata,        -- in  std_logic_vector(7 downto 0);   -- data byte received
      mac_rx_tvalid             => mac_rx_tvalid,       -- in  std_logic;                      -- indicates tdata is valid
      mac_rx_tready             => mac_rx_tready,       -- out std_logic;                      -- tells mac that we are ready to take data
      mac_rx_tlast              => mac_rx_tlast         -- in  std_logic                       -- indicates last byte of the trame
  );


  ------------------------------
  -- outputs followers
  ------------------------------
  ip_rx_start_o   <= ip_rx_start_int;
  ip_rx_hdr_o     <= ip_rx_int.hdr;
  ip_rx_data_o    <= ip_rx_int.data;

  ip_tx_start_o   <= ip_tx_start_int;
  ip_tx_result_o  <= ip_tx_result_int;

end structural;
--==============================================================================
-- End of Code
--==============================================================================


