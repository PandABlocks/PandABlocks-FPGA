--------------------------------------------------------------------------------
-- Company:
-- Engineer:            Peter Fall
--
-- Create Date:    16:20:42 06/01/2011
-- Design Name:
-- Module Name:    IPv4 - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--              handle simple IP RX and TX
--              doesnt handle seg & reass
--              dest MAC addr resolution through ARP layer
--              Handle IPv4 protocol
--              Respond to ARP requests and replies
--              Ignore pkts that are not IP
--              Ignore pkts that are not addressed to us--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - separated RX and TX clocks
-- Revision 0.03 - Added mac_data_out_first
-- Additional Comments:
--
--------------------------------------------------------------------------------
-- Instances    : component
-- ============================
-- ipv4_tx_i    : ipv4_tx
-- ipv4_rx_i    : ipv4_rx



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



--==============================================================================
-- Entity Declaration
--==============================================================================
entity ipv4 is
  port (
    -- IP Layer signals
    ip_tx_start               : in  std_logic;
    ip_tx                     : in  ipv4_tx_type;                     -- IP tx cxns
    ip_tx_result              : out std_logic_vector(1 downto 0);     -- tx status (changes during transmission)
    ip_tx_data_out_ready      : out std_logic;                        -- indicates IP TX is ready to take data
    ip_rx_start               : out std_logic;                        -- indicates receipt of ip frame.
    ip_rx                     : out ipv4_rx_type;
    -- System control signals
    rx_clk                    : in  std_logic;
    tx_clk                    : in  std_logic;
    reset                     : in  std_logic;
    our_ip_address            : in  std_logic_vector(31 downto 0);
    our_mac_address           : in  std_logic_vector(47 downto 0);
    -- system status signals
    rx_pkt_count              : out std_logic_vector(7 downto 0);     -- number of IP pkts received for us
    -- ARP lookup signals
    arp_req_req               : out arp_req_req_type;
    arp_req_rslt              : in arp_req_rslt_type;
    -- MAC layer RX signals
    mac_data_in               : in  std_logic_vector(7 downto 0);     -- ethernet frame (from dst mac addr through to last byte of frame)
    mac_data_in_valid         : in  std_logic;                        -- indicates data_in valid on clock
    mac_data_in_last          : in  std_logic;                        -- indicates last data in frame
    -- MAC layer TX signals
    mac_tx_req                : out std_logic;                        -- indicates that ip wants access to channel (stays up for as long as tx)
    mac_tx_granted            : in  std_logic;                        -- indicates that access to channel has been granted
    mac_data_out_ready        : in  std_logic;                        -- indicates system ready to consume data
    mac_data_out_valid        : out std_logic;                        -- indicates data out is valid
    mac_data_out_first        : out std_logic;                        -- with data out valid indicates the first byte of a frame
    mac_data_out_last         : out std_logic;                        -- with data out valid indicates the last byte of a frame
    mac_data_out              : out std_logic_vector(7 downto 0)      -- ethernet frame (from dst mac addr through to last byte of frame)
    );
end ipv4;


--==============================================================================
-- Architcture Declaration
--==============================================================================
architecture structural of ipv4 is

  component ipv4_tx
  port (
    -- system signals (in)
    clk                   : in  std_logic;                      -- same clock used to clock mac data and ip data
    reset                 : in  std_logic;
    our_ip_address        : in  std_logic_vector(31 downto 0);
    our_mac_address       : in  std_logic_vector(47 downto 0);
    -- IP Layer signals
    ip_tx_start           : in  std_logic;
    ip_tx                 : in  ipv4_tx_type;                   -- IP tx cxns
    ip_tx_result          : out std_logic_vector(1 downto 0);  -- tx status (changes during transmission)
    ip_tx_data_out_ready  : out std_logic;                      -- indicates IP TX is ready to take data
    -- ARP lookup signals
    arp_req_req           : out arp_req_req_type;
    arp_req_rslt          : in  arp_req_rslt_type;
    -- MAC layer TX signals
    mac_tx_req            : out std_logic;                      -- indicates that ip wants access to channel (stays up for as long as tx)
    mac_tx_granted        : in  std_logic;                      -- indicates that access to channel has been granted
    mac_data_out_ready    : in  std_logic;                      -- indicates system ready to consume data
    mac_data_out_valid    : out std_logic;                      -- indicates data out is valid
    mac_data_out_first    : out std_logic;                      -- with data out valid indicates the first byte of a frame
    mac_data_out_last     : out std_logic;                      -- with data out valid indicates the last byte of a frame
    mac_data_out          : out std_logic_vector(7 downto 0)    -- ethernet frame (from dst mac addr through to last byte of frame)
    );
  end component;

  component ipv4_rx
  port (
    -- system signals (in)
    clk               : in  std_logic;                      -- same clock used to clock mac data and ip data
    reset             : in  std_logic;
    our_ip_address    : in  std_logic_vector(31 downto 0);
    -- status signals (out)
    rx_pkt_count      : out std_logic_vector( 7 downto 0);  -- number of IP pkts received for us
    -- IP Layer signals
    ip_rx             : out ipv4_rx_type;
    ip_rx_start       : out std_logic;                      -- indicates receipt of ip frame.
    -- MAC layer RX signals
    mac_data_in       : in  std_logic_vector( 7 downto 0);  -- ethernet frame (from dst mac addr through to last byte of frame)
    mac_data_in_valid : in  std_logic;                      -- indicates data_in valid on clock
    mac_data_in_last  : in  std_logic                       -- indicates last data in frame
    );
  end component;



--==============================================================================
-- Beginning of Code
--==============================================================================
begin

  ----------------------
  -- IPV4_TX instance
  ----------------------
  ipv4_tx_i : ipv4_tx
  port map (
    -- system signals (in)
    clk                   => tx_clk,
    reset                 => reset,
    our_ip_address        => our_ip_address,
    our_mac_address       => our_mac_address,
    -- IP Layer signals
    ip_tx_start           => ip_tx_start,
    ip_tx                 => ip_tx,
    ip_tx_result          => ip_tx_result,
    ip_tx_data_out_ready  => ip_tx_data_out_ready,
    -- ARP lookup signals
    arp_req_req           => arp_req_req,
    arp_req_rslt          => arp_req_rslt,
    -- MAC layer TX signals
    mac_tx_req            => mac_tx_req,
    mac_tx_granted        => mac_tx_granted,
    mac_data_out_ready    => mac_data_out_ready,
    mac_data_out_valid    => mac_data_out_valid,
    mac_data_out_first    => mac_data_out_first,
    mac_data_out_last     => mac_data_out_last,
    mac_data_out          => mac_data_out
  );

  ----------------------
  -- IPV4_RX instance
  ----------------------
  ipv4_rx_i : ipv4_rx
  port map (
    -- system signals (in)
    clk                   => rx_clk,
    reset                 => reset,
    our_ip_address        => our_ip_address,
    -- status signals (out)
    rx_pkt_count          => rx_pkt_count,
    -- IP Layer signals
    ip_rx                 => ip_rx,
    ip_rx_start           => ip_rx_start,
    -- MAC layer RX signals
    mac_data_in           => mac_data_in,
    mac_data_in_valid     => mac_data_in_valid,
    mac_data_in_last      => mac_data_in_last
  );



end structural;
--==============================================================================
-- End of Code
--==============================================================================

