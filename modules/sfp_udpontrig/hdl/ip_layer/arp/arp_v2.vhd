--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : PandABox FPGA
-- Design name    : sfp_udpontrig
-- Module name    : arp_v2.vhd
-- Purpose        : top-level of ARP v2 layer
--                  origin: arpv2.vhd Opencores udp_ip_stack tag v2.6
-- Author         : Thierry GARREL (ELSYS-Design)
--                  indentation of code (tab 2, use spaces)
--                  add a package of components arp_v2_coponent_pkg.vhd
--                  move system signals on top of entities and port maps
-- Synthesizable  : YES
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2021 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Company:
-- Engineer:            Peter Fall
--
-- Create Date:    12:00:04 05/31/2011
-- Design Name:
-- Module Name:    arpv2 - Structural
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--              handle simple IP lookup in 1-deep cache and arp store
--              request cache fill through ARP protocol if required
--              Handle ARP protocol
--              Respond to ARP requests and replies
--              Ignore pkts that are not ARP
--              Ignore pkts that are not addressed to us
--
--              structural decomposition includes
--                      arp TX block            - encoding of ARP protocol
--                      arp RX block            - decoding of ARP protocol
--                      arp REQ block           - sequencing requests for resolution
--                      arp STORE block - storing address resolution entries (indexed by IP addr)
--                      arp sync block          - sync between master RX clock and TX clock domains
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
--------------------------------------------------------------------------------


--==============================================================================
-- Libraries Declaration
--==============================================================================
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.arp_types.all;
  use work.arp_layer_component_pkg.all; -- package of components declarations


--==============================================================================
-- Entity Declaration
--==============================================================================
entity arp_v2 is
  generic (
    no_default_gateway  : boolean := true       ;   -- set to FALSE if communicating with devices accessed
                                                    -- though a "default gateway or router"
    CLOCK_FREQ          : integer := 125000000  ;   -- Freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT         : integer := 60         ;   -- ARP response timeout (s)
    ARP_MAX_PKT_TMO     : integer := 5          ;   -- # wrong nwk pkts received before set error
    MAX_ARP_ENTRIES     : integer := 255            -- Max entries in the arp store
    );
  port (
    -- system signals (in)
    our_mac_address     : in  std_logic_vector (47 downto 0);
    our_ip_address      : in  std_logic_vector (31 downto 0);
    nwk_gateway         : in  std_logic_vector (31 downto 0) := (others => '0');  -- IP address of default gateway
    nwk_mask            : in  std_logic_vector (31 downto 0) := (others => '0');  -- Net mask
    control             : in  arp_control_type;
    -- status signals (out)
    req_count           : out std_logic_vector(7 downto 0);     -- count of arp pkts received
    -- lookup request signals
    arp_req_req         : in  arp_req_req_type;
    arp_req_rslt        : out arp_req_rslt_type;
    -- MAC layer RX signals (in)
    data_in_clk         : in  std_logic;
    reset               : in  std_logic;
    data_in             : in  std_logic_vector (7 downto 0);    -- Ethernet frame (from dst mac addr through to last byte of frame)
    data_in_valid       : in  std_logic;                        -- indicates data_in valid on clock
    data_in_last        : in  std_logic;                        -- indicates last data in frame
    -- MAC layer TX signals (out)
    mac_tx_req          : out std_logic;                        -- indicates that ip wants access to channel (stays up for as long as tx)
    mac_tx_granted      : in  std_logic;                        -- indicates that access to channel has been granted
    data_out_clk        : in  std_logic;
    data_out_ready      : in  std_logic;                        -- indicates system ready to consume data
    data_out_valid      : out std_logic;                        -- indicates data out is valid
    data_out_first      : out std_logic;                        -- with data out valid indicates the first byte of a frame
    data_out_last       : out std_logic;                        -- with data out valid indicates the last byte of a frame
    data_out            : out std_logic_vector (7 downto 0)     -- ethernet frame (from dst mac addr through to last byte of frame)
    );
end arp_v2;


--==============================================================================
-- Architecture Declaration
--==============================================================================
architecture structural of arp_v2 is

  ---------------------------------
  -- Components declarations
  ---------------------------------
  -- see arp_v2_components_pkg.vhd

  ---------------------------------
  -- Internal signals
  ---------------------------------

  -- interconnect REQ -> ARP_TX
  signal arp_nwk_req_int            : arp_nwk_request_t;  -- tx req from REQ

  signal send_I_have_int            : std_logic;
  signal arp_entry_int              : arp_entry_t;
  signal send_who_has_int           : std_logic;
  signal ip_entry_int               : std_logic_vector (31 downto 0);

  -- interconnect REQ <-> ARP_STORE
  signal arp_store_req_int          : arp_store_rdrequest_t;  -- lookup request
  signal arp_store_result_int       : arp_store_result_t;     -- lookup result

  -- interconnect ARP_RX -> REQ
  signal nwk_result_status_int      : arp_nwk_rslt_t;         -- response from a TX req

  -- interconnect ARP_RX -> ARP_STORE
  signal recv_I_have_int            : std_logic;              -- path to store new arp entry
  signal arp_entry_for_I_have_int   : arp_entry_t;

  -- interconnect ARP_RX -> ARP_TX
  signal recv_who_has_int           : std_logic;              -- path for reply when we can anser
  signal arp_entry_for_who_has_int  : arp_entry_t;            -- target for who_has msg (ie, who to reply to)


--==============================================================================
-- Beginning of Code
--==============================================================================
begin


  req : arp_req
  generic map (
    no_default_gateway    => no_default_gateway,
    CLOCK_FREQ            => CLOCK_FREQ,
    ARP_TIMEOUT           => ARP_TIMEOUT,
    ARP_MAX_PKT_TMO       => ARP_MAX_PKT_TMO
  )
  port map (
    -- system signals
    clk                   => data_in_clk,
    reset                 => reset,
    clear_cache           => control.clear_cache,
    nwk_gateway           => nwk_gateway,
    nwk_mask              => nwk_mask,
    -- lookup request signals
    arp_req_req           => arp_req_req,
    arp_req_rslt          => arp_req_rslt,
    -- external arp store signals
    arp_store_req         => arp_store_req_int,
    arp_store_result      => arp_store_result_int,
    -- network request signals
    arp_nwk_req           => arp_nwk_req_int,
    arp_nwk_result.status => nwk_result_status_int,
    arp_nwk_result.entry  => arp_entry_for_I_have_int
  );

  sync : arp_sync
  port map (
    -- system
    rx_clk                  => data_in_clk,
    tx_clk                  => data_out_clk,
    reset                   => reset,
    -- REQ to TX
    arp_nwk_req             => arp_nwk_req_int,
    send_who_has            => send_who_has_int,
    ip_entry                => ip_entry_int,
    -- RX to TX
    recv_who_has            => recv_who_has_int,
    arp_entry_for_who_has   => arp_entry_for_who_has_int,
    send_I_have             => send_I_have_int,
    arp_entry               => arp_entry_int,
    -- RX to REQ
    I_have_received         => recv_I_have_int,
    nwk_result_status       => nwk_result_status_int
    );

  tx : arp_tx
  port map (
    -- system signals
    tx_clk                  => data_out_clk,
    reset                   => reset,
    our_ip_address          => our_ip_address,
    our_mac_address         => our_mac_address,
    -- control signals
    send_I_have             => send_I_have_int,
    arp_entry               => arp_entry_int,
    send_who_has            => send_who_has_int,
    ip_entry                => ip_entry_int,
    -- MAC layer TX signals
    mac_tx_req              => mac_tx_req,
    mac_tx_granted          => mac_tx_granted,
    data_out_ready          => data_out_ready,
    data_out_valid          => data_out_valid,
    data_out_first          => data_out_first,
    data_out_last           => data_out_last,
    data_out                => data_out
  );

  rx : arp_rx
  port map (
    -- system signals
    our_ip_address        => our_ip_address,
    rx_clk                => data_in_clk,
    reset                 => reset,
    -- control and status signals
    req_count             => req_count,
    -- MAC layer RX signals
    data_in               => data_in,
    data_in_valid         => data_in_valid,
    data_in_last          => data_in_last,
    -- ARP output signals
    recv_who_has          => recv_who_has_int,
    arp_entry_for_who_has => arp_entry_for_who_has_int,
    recv_I_have           => recv_I_have_int,
    arp_entry_for_I_have  => arp_entry_for_I_have_int
  );

  store : arp_store_br
  generic map (
    MAX_ARP_ENTRIES       => MAX_ARP_ENTRIES
  )
  port map (
    -- system signals
    clk                   => data_in_clk,
    reset                 => reset,
    -- read signals
    read_req              => arp_store_req_int,
    read_result           => arp_store_result_int,
    -- write signals
    write_req.req         => recv_I_have_int,
    write_req.entry       => arp_entry_for_I_have_int,
    -- control and status signals
    clear_store           => control.clear_cache,
    entry_count           => open
  );


end structural;
--==============================================================================
-- End of Code
--==============================================================================
