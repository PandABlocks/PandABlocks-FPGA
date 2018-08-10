--------------------------------------------------------------------------------
-- File       : tri_mode_ethernet_mac_0_fifo_block.v
-- Author     : Xilinx Inc.
-- -----------------------------------------------------------------------------
-- (c) Copyright 2004-2013 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES. 
-- -----------------------------------------------------------------------------
-- Description: This is the FIFO Block level vhdl wrapper for the Tri-Mode
--              Ethernet MAC core.  This wrapper enhances the standard MAC core
--              with an example FIFO.  The interface to this FIFO is
--              designed to the AXI-S specification.
--              Please refer to core documentation for
--              additional FIFO and AXI-S information.
--
--         _________________________________________________________
--        |                                                         |
--        |                 FIFO BLOCK LEVEL WRAPPER                |
--        |                                                         |
--        |   _____________________       ______________________    |
--        |  |  _________________  |     |                      |   |
--        |  | |                 | |     |                      |   |
--  -------->| |   TX AXI FIFO   | |---->| Tx               Tx  |--------->
--        |  | |                 | |     | AXI-S            PHY |   |
--        |  | |_________________| |     | I/F              I/F |   |
--        |  |                     |     |                      |   |
--  AXI   |  |     10/100/1G       |     |  TRI-MODE ETHERNET   |   |
-- Stream |  |    ETHERNET FIFO    |     |          MAC         |   | PHY I/F
--        |  |                     |     |         CORE         |   |
--        |  |  _________________  |     |                      |   |
--        |  | |                 | |     |                      |   |
--  <--------| |   RX AXI FIFO   | |<----| Rx               Rx  |<---------
--        |  | |                 | |     | AXI-S            PHY |   |
--        |  | |_________________| |     | I/F              I/F |   |
--        |  |_____________________|     |______________________|   |
--        |                                                         |
--        |_________________________________________________________|
--


library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--------------------------------------------------------------------------------
-- The module declaration for the fifo block level wrapper.
--------------------------------------------------------------------------------

entity tri_mode_ethernet_mac_0_fifo_block is
   port(
      gtx_clk                    : in  std_logic;

      -- asynchronous reset
      glbl_rstn                  : in  std_logic;
      rx_axi_rstn                : in  std_logic;
      tx_axi_rstn                : in  std_logic;

      -- Reference clock for IDELAYCTRL's
      --refclk                     : in  std_logic;

      -- Receiver Statistics Interface
      -----------------------------------------
      rx_mac_aclk                : out std_logic;
      rx_reset                   : out std_logic;
      rx_statistics_vector       : out std_logic_vector(27 downto 0);
      rx_statistics_valid        : out std_logic;

      -- Receiver (AXI-S) Interface
      ------------------------------------------
      rx_fifo_clock              : in  std_logic;
      rx_fifo_resetn             : in  std_logic;
      rx_axis_fifo_tdata         : out std_logic_vector(7 downto 0);
      rx_axis_fifo_tvalid        : out std_logic;
      rx_axis_fifo_tready        : in  std_logic;
      rx_axis_fifo_tlast         : out std_logic;


      -- Transmitter Statistics Interface
      --------------------------------------------
      tx_mac_aclk                : out std_logic;
      tx_reset                   : out std_logic;
      tx_ifg_delay               : in  std_logic_vector(7 downto 0);
      tx_statistics_vector       : out std_logic_vector(31 downto 0);
      tx_statistics_valid        : out std_logic;

      -- Transmitter (AXI-S) Interface
      ---------------------------------------------
      tx_fifo_clock              : in  std_logic;
      tx_fifo_resetn             : in  std_logic;
      tx_axis_fifo_tdata         : in  std_logic_vector(7 downto 0);
      tx_axis_fifo_tvalid        : in  std_logic;
      tx_axis_fifo_tready        : out std_logic;
      tx_axis_fifo_tlast         : in  std_logic;
      tx_fifo_overflow           : out std_logic;
      tx_fifo_status             : out std_logic_vector(3 downto 0);

      -- MAC Control Interface
      --------------------------
      pause_req                  : in  std_logic;
      pause_val                  : in  std_logic_vector(15 downto 0);

      -- GMII Interface
      -------------------
      gmii_txd                  : out std_logic_vector(7 downto 0);
      gmii_tx_en                : out std_logic;
      gmii_tx_er                : out std_logic;
      gmii_tx_clk               : out std_logic;
      gmii_rxd                  : in  std_logic_vector(7 downto 0);
      gmii_rx_dv                : in  std_logic;
      gmii_rx_er                : in  std_logic;
      gmii_rx_clk               : in  std_logic;
      -- Configuration Vector
      -------------------------
      rx_configuration_vector   : in  std_logic_vector(79 downto 0);
      tx_configuration_vector   : in  std_logic_vector(79 downto 0)
   );
end tri_mode_ethernet_mac_0_fifo_block;


architecture wrapper of tri_mode_ethernet_mac_0_fifo_block is

  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of wrapper : architecture is "yes";

  ------------------------------------------------------------------------------
  -- Component declaration for the Tri-Mode Ethernet MAC core
  ------------------------------------------------------------------------------


COMPONENT eth_mac
  PORT (
    gtx_clk : IN STD_LOGIC;
    glbl_rstn : IN STD_LOGIC;
    rx_axi_rstn : IN STD_LOGIC;
    tx_axi_rstn : IN STD_LOGIC;
    rx_statistics_vector : OUT STD_LOGIC_VECTOR(27 DOWNTO 0);
    rx_statistics_valid : OUT STD_LOGIC;
    rx_mac_aclk : OUT STD_LOGIC;
    rx_reset : OUT STD_LOGIC;
    rx_axis_mac_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rx_axis_mac_tvalid : OUT STD_LOGIC;
    rx_axis_mac_tlast : OUT STD_LOGIC;
    rx_axis_mac_tuser : OUT STD_LOGIC;
    tx_ifg_delay : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    tx_statistics_vector : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    tx_statistics_valid : OUT STD_LOGIC;
    tx_mac_aclk : OUT STD_LOGIC;
    tx_reset : OUT STD_LOGIC;
    tx_axis_mac_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    tx_axis_mac_tvalid : IN STD_LOGIC;
    tx_axis_mac_tlast : IN STD_LOGIC;
    tx_axis_mac_tuser : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    tx_axis_mac_tready : OUT STD_LOGIC;
    pause_req : IN STD_LOGIC;
    pause_val : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    --refclk : IN STD_LOGIC;
    speedis100 : OUT STD_LOGIC;
    speedis10100 : OUT STD_LOGIC;
    gmii_txd : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    gmii_tx_en : OUT STD_LOGIC;
    gmii_tx_er : OUT STD_LOGIC;
    --gmii_tx_clk : OUT STD_LOGIC;
    gmii_rxd : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    gmii_rx_dv : IN STD_LOGIC;
    gmii_rx_er : IN STD_LOGIC;
    --gmii_rx_clk : IN STD_LOGIC;
    rx_configuration_vector : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
    tx_configuration_vector : IN STD_LOGIC_VECTOR(79 DOWNTO 0)
  );
END COMPONENT;
  ------------------------------------------------------------------------------
  -- Component declaration for the fifo
  ------------------------------------------------------------------------------
   component tri_mode_ethernet_mac_0_ten_100_1g_eth_fifo
   generic (
        FULL_DUPLEX_ONLY    : boolean := true);      -- If fifo is to be used only in full
                                              -- duplex set to true for optimised implementation
   port (
        tx_fifo_aclk             : in  std_logic;
        tx_fifo_resetn           : in  std_logic;
        tx_axis_fifo_tdata       : in  std_logic_vector(7 downto 0);
        tx_axis_fifo_tvalid      : in  std_logic;
        tx_axis_fifo_tlast       : in  std_logic;
        tx_axis_fifo_tready      : out std_logic;

        tx_mac_aclk              : in  std_logic;
        tx_mac_resetn            : in  std_logic;
        tx_axis_mac_tdata        : out std_logic_vector(7 downto 0);
        tx_axis_mac_tvalid       : out std_logic;
        tx_axis_mac_tlast        : out std_logic;
        tx_axis_mac_tready       : in  std_logic;
        tx_axis_mac_tuser        : out std_logic;
        tx_fifo_overflow         : out std_logic;
        tx_fifo_status           : out std_logic_vector(3 downto 0);
        tx_collision             : in  std_logic;
        tx_retransmit            : in  std_logic;

        rx_fifo_aclk             : in  std_logic;
        rx_fifo_resetn           : in  std_logic;
        rx_axis_fifo_tdata       : out std_logic_vector(7 downto 0);
        rx_axis_fifo_tvalid      : out std_logic;
        rx_axis_fifo_tlast       : out std_logic;
        rx_axis_fifo_tready      : in  std_logic;

        rx_mac_aclk              : in  std_logic;
        rx_mac_resetn            : in  std_logic;
        rx_axis_mac_tdata        : in  std_logic_vector(7 downto 0);
        rx_axis_mac_tvalid       : in  std_logic;
        rx_axis_mac_tlast        : in  std_logic;
        rx_axis_mac_tuser        : in  std_logic;
        rx_fifo_status           : out std_logic_vector(3 downto 0);
        rx_fifo_overflow         : out std_logic
  );
  end component;

  ------------------------------------------------------------------------------
  -- Component declaration for the reset synchroniser
  ------------------------------------------------------------------------------
  component tri_mode_ethernet_mac_0_reset_sync
  port (
     reset_in                    : in  std_logic;    -- Active high asynchronous reset
     enable                      : in  std_logic;
     clk                         : in  std_logic;    -- clock to be sync'ed to
     reset_out                   : out std_logic     -- "Synchronised" reset signal
  );
  end component;

  ------------------------------------------------------------------------------
  -- Internal signals used in this fifo block level wrapper.
  ------------------------------------------------------------------------------

  signal rx_mac_aclk_int         : std_logic;   -- MAC Rx clock
  signal tx_mac_aclk_int         : std_logic;   -- MAC Tx clock
  signal rx_reset_int            : std_logic;   -- MAC Rx reset
  signal tx_reset_int            : std_logic;   -- MAC Tx reset
  signal tx_mac_resetn           : std_logic;
  signal rx_mac_resetn           : std_logic;
  signal tx_mac_reset            : std_logic;
  signal rx_mac_reset            : std_logic;

  -- MAC receiver client I/F
  signal rx_axis_mac_tdata       : std_logic_vector(7 downto 0);
  signal rx_axis_mac_tvalid      : std_logic;
  signal rx_axis_mac_tlast       : std_logic;
  signal rx_axis_mac_tuser       : std_logic;

  -- MAC transmitter client I/F
  signal tx_axis_mac_tdata       : std_logic_vector(7 downto 0);
  signal tx_axis_mac_tvalid      : std_logic;
  signal tx_axis_mac_tready      : std_logic;
  signal tx_axis_mac_tlast       : std_logic;
  signal tx_axis_mac_tuser       : std_logic_vector(0 downto 0);
  signal rx_configuration_vector_int : std_logic_vector(79 downto 0);
  signal tx_configuration_vector_int : std_logic_vector(79 downto 0);


begin

  ------------------------------------------------------------------------------
  -- Connect the output clock signals
  ------------------------------------------------------------------------------

   rx_mac_aclk          <= rx_mac_aclk_int;
   tx_mac_aclk          <= tx_mac_aclk_int;
   rx_reset             <= rx_reset_int;
   tx_reset             <= tx_reset_int;

   rx_configuration_vector_int <= rx_configuration_vector;
   tx_configuration_vector_int <= tx_configuration_vector;
   ------------------------------------------------------------------------------
   -- Instantiate the Tri-Mode Ethernet MAC core
   ------------------------------------------------------------------------------

eth_mac_i : eth_mac

   port map(
      gtx_clk               => gtx_clk,
      -- asynchronous reset
      glbl_rstn             => glbl_rstn,
      rx_axi_rstn           => rx_axi_rstn,
      tx_axi_rstn           => tx_axi_rstn,

      -- Client Receiver Interface
      rx_statistics_vector  => rx_statistics_vector,
      rx_statistics_valid   => rx_statistics_valid,

      rx_mac_aclk           => rx_mac_aclk_int,
      rx_reset              => rx_reset_int,
      rx_axis_mac_tdata     => rx_axis_mac_tdata,
      rx_axis_mac_tvalid    => rx_axis_mac_tvalid,
      rx_axis_mac_tlast     => rx_axis_mac_tlast,
      rx_axis_mac_tuser     => rx_axis_mac_tuser,

      -- Client Transmitter Interface
      tx_ifg_delay          => tx_ifg_delay,
      tx_statistics_vector  => tx_statistics_vector,
      tx_statistics_valid   => tx_statistics_valid,

      tx_mac_aclk           => tx_mac_aclk_int,
      tx_reset              => tx_reset_int,
      tx_axis_mac_tdata     => tx_axis_mac_tdata ,
      tx_axis_mac_tvalid    => tx_axis_mac_tvalid,
      tx_axis_mac_tlast     => tx_axis_mac_tlast,
      tx_axis_mac_tuser     => tx_axis_mac_tuser,
      tx_axis_mac_tready    => tx_axis_mac_tready,

      -- Flow Control
      pause_req             => pause_req,
      pause_val             => pause_val,

      -- Reference clock for IDELAYCTRL's
      --refclk                => refclk,

      -- speed control
      speedis100            => open,
      speedis10100          => open,

      -- GMII Interface
      gmii_txd              => gmii_txd,
      gmii_tx_en            => gmii_tx_en,
      gmii_tx_er            => gmii_tx_er,
      --gmii_tx_clk           => gmii_tx_clk,
      gmii_rxd              => gmii_rxd,
      gmii_rx_dv            => gmii_rx_dv,
      gmii_rx_er            => gmii_rx_er,
      --gmii_rx_clk           => gmii_rx_clk,

      -- Configuration Vector
      rx_configuration_vector  => rx_configuration_vector_int,
      tx_configuration_vector  => tx_configuration_vector_int
   );


   ------------------------------------------------------------------------------
   -- Instantiate the user side FIFO
   ------------------------------------------------------------------------------

   -- locally reset sync the mac generated resets - the resets are already fully sync
   -- so adding a reset sync shouldn't change that
   rx_mac_reset_gen : tri_mode_ethernet_mac_0_reset_sync
   port map (
       clk                  => rx_mac_aclk_int,
       enable               => '1',
       reset_in             => rx_reset_int,
       reset_out            => rx_mac_reset
   );

   tx_mac_reset_gen : tri_mode_ethernet_mac_0_reset_sync
   port map (
       clk                  => tx_mac_aclk_int,
       enable               => '1',
       reset_in             => tx_reset_int,
       reset_out            => tx_mac_reset
   );

   -- create inverted mac resets as the FIFO expects AXI compliant resets
   tx_mac_resetn <= not tx_mac_reset;
   rx_mac_resetn <= not rx_mac_reset;


   user_side_FIFO : tri_mode_ethernet_mac_0_ten_100_1g_eth_fifo
   generic map(
      FULL_DUPLEX_ONLY        => true
   )
   port map(
      -- Transmit FIFO MAC TX Interface
      tx_fifo_aclk          => tx_fifo_clock,
      tx_fifo_resetn        => tx_fifo_resetn,
      tx_axis_fifo_tdata    => tx_axis_fifo_tdata,
      tx_axis_fifo_tvalid   => tx_axis_fifo_tvalid,
      tx_axis_fifo_tlast    => tx_axis_fifo_tlast,
      tx_axis_fifo_tready   => tx_axis_fifo_tready,

      tx_mac_aclk           => tx_mac_aclk_int,
      tx_mac_resetn         => tx_mac_resetn,
      tx_axis_mac_tdata     => tx_axis_mac_tdata,
      tx_axis_mac_tvalid    => tx_axis_mac_tvalid,
      tx_axis_mac_tlast     => tx_axis_mac_tlast,
      tx_axis_mac_tready    => tx_axis_mac_tready,
      tx_axis_mac_tuser     => tx_axis_mac_tuser(0),
      tx_fifo_overflow      => tx_fifo_overflow,
      tx_fifo_status        => tx_fifo_status,
      tx_collision          => '0',
      tx_retransmit         => '0',

      rx_fifo_aclk          => rx_fifo_clock,
      rx_fifo_resetn        => rx_fifo_resetn,
      rx_axis_fifo_tdata    => rx_axis_fifo_tdata,
      rx_axis_fifo_tvalid   => rx_axis_fifo_tvalid,
      rx_axis_fifo_tlast    => rx_axis_fifo_tlast,
      rx_axis_fifo_tready   => rx_axis_fifo_tready,

      rx_mac_aclk           => rx_mac_aclk_int,
      rx_mac_resetn         => rx_mac_resetn,
      rx_axis_mac_tdata     => rx_axis_mac_tdata,
      rx_axis_mac_tvalid    => rx_axis_mac_tvalid,
      rx_axis_mac_tlast     => rx_axis_mac_tlast,
      rx_axis_mac_tuser     => rx_axis_mac_tuser,

      rx_fifo_status        => open,
      rx_fifo_overflow      => open
  );


end wrapper;

