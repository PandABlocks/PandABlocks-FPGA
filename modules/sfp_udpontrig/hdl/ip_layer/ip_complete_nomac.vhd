--==============================================================================
-- Company:
-- Engineer:
--
-- Create Date:    12:43:16 06/04/2011
-- Design Name:
-- Module Name:    ip_complete_nomac - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description: Implements complete IP stack with ARP (but no MAC)
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - separated RX and TX clocks
-- Revision 0.03 - Added mac_tx_tfirst
-- Additional Comments:
--
--==============================================================================


--==============================================================================
-- Libraries Declaration
--==============================================================================
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.axi_types.all;
  use work.ipv4_types.all;
  use work.arp_types.all;
  use work.ip_layer_component_pkg.all;

--  Instance                    : component             : description
--  ------------------------------------------------------------------------------------------------
--  ip_layer                    : ipv4                  : IP layer
--- single_entry_arp\arp_layer  : arp                   : ARP with single entry           (use_arpv2 = FALSE)
--  multi_entry_arp\arp_layer   : arp_v2                : ARP ARP with multipule entries  (use_arpv2 = TRUE)
--  mac_tx_arbitrer             : mac_tx_arbitrator     : MAC TX Arbitrator
--  ------------------------------------------------------------------------------------------------


--==============================================================================
-- Entity Declaration
--==============================================================================
entity ip_complete_nomac is
  generic (
    use_arpv2             : boolean := FALSE      ;   -- use ARP with multipule entries.
                                                      -- for single entry, set to FALSE
    no_default_gateway    : boolean := FALSE      ;   -- set to FALSE if communicating with devices accessed
                                                      -- through a "default gateway or router"
    CLOCK_FREQ            : integer := 125000000  ;   -- freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT           : integer := 60         ;   -- ARP response timeout (s)
    ARP_MAX_PKT_TMO       : integer := 5          ;   -- # wrong nwk pkts received before set error
    MAX_ARP_ENTRIES       : integer := 255            -- max entries in the ARP store
    );
  port (
    -- IP Layer TX signals (in)
    ip_tx_start           : in  std_logic;
    ip_tx                 : in  ipv4_tx_type;                   -- IP tx cxns
    ip_tx_result          : out std_logic_vector (1 downto 0);  -- tx status (changes during transmission)
    ip_tx_data_out_ready  : out std_logic;                      -- indicates IP TX is ready to take data
    -- IP layer RX signals (out)
    ip_rx_start           : out std_logic;                      -- indicates receipt of ip frame.
    ip_rx                 : out ipv4_rx_type;
    -- system signals
    rx_clk                : in  std_logic;
    tx_clk                : in  std_logic;
    reset                 : in  std_logic;
    our_ip_address        : in  std_logic_vector (31 downto 0);
    our_mac_address       : in  std_logic_vector (47 downto 0);
    control               : in  ip_control_type;
    -- status signals
    arp_pkt_count         : out std_logic_vector(7 downto 0);   -- count of arp pkts received
    ip_pkt_count          : out std_logic_vector(7 downto 0);   -- number of IP pkts received for us
    -- MAC Transmitter
    mac_tx_tdata          : out std_logic_vector(7 downto 0);   -- data byte to tx
    mac_tx_tvalid         : out std_logic;                      -- tdata is valid
    mac_tx_tready         : in  std_logic;                      -- mac is ready to accept data
    mac_tx_tfirst         : out std_logic;                      -- indicates first byte of frame
    mac_tx_tlast          : out std_logic;                      -- indicates last byte of frame
    -- MAC Receiver
    mac_rx_tdata          : in  std_logic_vector(7 downto 0);   -- data byte received
    mac_rx_tvalid         : in  std_logic;                      -- indicates tdata is valid
    mac_rx_tready         : out std_logic;                      -- tells mac that we are ready to take data
    mac_rx_tlast          : in  std_logic                       -- indicates last byte of the trame
    );
end ip_complete_nomac;


--==============================================================================
-- Architecture Declaration
--==============================================================================
architecture structural of ip_complete_nomac is

  -------------------------------
  -- Components declarations
  -------------------------------
  -- see ip_layer_component_pkg.vhd


  -------------------
  -- Configuration
  --
  -- Enable one of the following to specify which
  -- implementation of the ARP layer to use
  -------------------

--  for arp_layer : arp use entity work.arp;    -- single slot arbitrator
--  for arp_layer : arp use entity work.arpv2;  -- multislot arbitrator


  ---------------------------
  -- Signals
  ---------------------------

  -- ARP REQUEST
  signal arp_req_req_int    : arp_req_req_type;
  signal arp_req_rslt_int   : arp_req_rslt_type;
  -- MAC arbitration busses
  signal ip_mac_req         : std_logic;
  signal ip_mac_grant       : std_logic;
  signal ip_mac_data_out    : std_logic_vector (7 downto 0);
  signal ip_mac_valid       : std_logic;
  signal ip_mac_first       : std_logic;
  signal ip_mac_last        : std_logic;
  signal arp_mac_req        : std_logic;
  signal arp_mac_grant      : std_logic;
  signal arp_mac_data_out   : std_logic_vector (7 downto 0);
  signal arp_mac_valid      : std_logic;
  signal arp_mac_first      : std_logic;
  signal arp_mac_last       : std_logic;
  -- MAC RX bus
  signal mac_rx_tready_int  : std_logic;
  -- MAC TX bus
  signal mac_tx_tdata_int   : std_logic_vector (7 downto 0);
  signal mac_tx_tvalid_int  : std_logic;
  signal mac_tx_tfirst_int  : std_logic;
  signal mac_tx_tlast_int   : std_logic;
  -- control signals
  signal mac_tx_granted_int : std_logic;


--==============================================================================
-- Beginning of CODE
--==============================================================================
begin

  mac_rx_tready_int <= '1';             -- enable the mac receiver

  -- set followers
  mac_tx_tdata  <= mac_tx_tdata_int;
  mac_tx_tvalid <= mac_tx_tvalid_int;
  mac_tx_tfirst <= mac_tx_tfirst_int;
  mac_tx_tlast  <= mac_tx_tlast_int;

  mac_rx_tready <= mac_rx_tready_int;

  ------------------------------------------------------------------------------
  -- Instantiate the IP layer
  ------------------------------------------------------------------------------
  ip_layer : ipv4
    port map (
      -- IP Layer signals
      ip_tx_start          => ip_tx_start,
      ip_tx                => ip_tx,
      ip_tx_result         => ip_tx_result,
      ip_tx_data_out_ready => ip_tx_data_out_ready,
      ip_rx_start          => ip_rx_start,
      ip_rx                => ip_rx,
      -- system control signals
      rx_clk               => rx_clk,
      tx_clk               => tx_clk,
      reset                => reset,
      our_ip_address       => our_ip_address,
      our_mac_address      => our_mac_address,
      -- system status signals
      rx_pkt_count         => ip_pkt_count,
      -- ARP lookup signals
      arp_req_req          => arp_req_req_int,
      arp_req_rslt         => arp_req_rslt_int,
      -- MAC layer RX signals
      mac_data_in          => mac_rx_tdata,
      mac_data_in_valid    => mac_rx_tvalid,
      mac_data_in_last     => mac_rx_tlast,
      -- MAC layer TX signals
      mac_tx_req           => ip_mac_req,
      mac_tx_granted       => ip_mac_grant,
      mac_data_out_ready   => mac_tx_tready,
      mac_data_out_valid   => ip_mac_valid,
      mac_data_out_first   => ip_mac_first,
      mac_data_out_last    => ip_mac_last,
      mac_data_out         => ip_mac_data_out
    );


  ------------------------------------------------------------------------------
  -- Instantiate the ARP layer
  ------------------------------------------------------------------------------
  -- use_arpv2 TRUE  : use work.arp
  --           FALSE : use work.arp_v2

  single_entry_arp: if (not use_arpv2) generate
    --arp_layer : entity work.arp
    arp_layer : arp
      generic map (
        CLOCK_FREQ      => CLOCK_FREQ,
        ARP_TIMEOUT     => ARP_TIMEOUT,
        ARP_MAX_PKT_TMO => ARP_MAX_PKT_TMO,
        MAX_ARP_ENTRIES => MAX_ARP_ENTRIES
      )
      port map (
        -- request signals
        arp_req_req     => arp_req_req_int,
        arp_req_rslt    => arp_req_rslt_int,
        -- rx signals
        data_in_clk     => rx_clk,
        reset           => reset,
        data_in         => mac_rx_tdata,
        data_in_valid   => mac_rx_tvalid,
        data_in_last    => mac_rx_tlast,
        -- tx signals
        mac_tx_req      => arp_mac_req,
        mac_tx_granted  => arp_mac_grant,
        data_out_clk    => tx_clk,
        data_out_ready  => mac_tx_tready,
        data_out_valid  => arp_mac_valid,
        data_out_first  => arp_mac_first,
        data_out_last   => arp_mac_last,
        data_out        => arp_mac_data_out,
        -- system signals
        our_mac_address => our_mac_address,
        our_ip_address  => our_ip_address,
        control         => control.arp_controls,
        req_count       => arp_pkt_count
      );

  end generate single_entry_arp;

  multi_entry_arp: if (use_arpv2) generate
    --arp_layer : entity work.arpv2
    arp_layer : arp_v2
      generic map (
        no_default_gateway => no_default_gateway,
        CLOCK_FREQ      => CLOCK_FREQ,
        ARP_TIMEOUT     => ARP_TIMEOUT,
        ARP_MAX_PKT_TMO => ARP_MAX_PKT_TMO,
        MAX_ARP_ENTRIES => MAX_ARP_ENTRIES
        )
      port map (
        -- request signals
        arp_req_req     => arp_req_req_int,
        arp_req_rslt    => arp_req_rslt_int,
        -- rx signals
        data_in_clk     => rx_clk,
        reset           => reset,
        data_in         => mac_rx_tdata,
        data_in_valid   => mac_rx_tvalid,
        data_in_last    => mac_rx_tlast,
        -- tx signals
        mac_tx_req      => arp_mac_req,
        mac_tx_granted  => arp_mac_grant,
        data_out_clk    => tx_clk,
        data_out_ready  => mac_tx_tready,
        data_out_valid  => arp_mac_valid,
        data_out_first  => arp_mac_first,
        data_out_last   => arp_mac_last,
        data_out        => arp_mac_data_out,
        -- system signals
        our_mac_address => our_mac_address,
        our_ip_address  => our_ip_address,
        control         => control.arp_controls,
        req_count       => arp_pkt_count
        );
  end generate multi_entry_arp;

  ------------------------------------------------------------------------------
  -- Instantiate the MAC TX Arbitrator
  ------------------------------------------------------------------------------
  mac_tx_arbitrer : mac_tx_arbitrator
    port map (
      clk   => tx_clk,
      reset => reset,

      req_1   => ip_mac_req,
      grant_1 => ip_mac_grant,
      data_1  => ip_mac_data_out,
      valid_1 => ip_mac_valid,
      first_1 => ip_mac_first,
      last_1  => ip_mac_last,

      req_2   => arp_mac_req,
      grant_2 => arp_mac_grant,
      data_2  => arp_mac_data_out,
      valid_2 => arp_mac_valid,
      first_2 => arp_mac_first,
      last_2  => arp_mac_last,

      data  => mac_tx_tdata_int,
      valid => mac_tx_tvalid_int,
      first => mac_tx_tfirst_int,
      last  => mac_tx_tlast_int
      );

end structural;
--==============================================================================
-- End of Code
--==============================================================================

