// ----------------------------------------------------------------------------
// (c) Copyright 2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// ----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Title      : Support level for 10G Gigabit Ethernet
// Project    : 10G Gigabit Ethernet
//-----------------------------------------------------------------------------
// File       : axi_10g_eth_support.v
// Author     : Xilinx Inc.
//-----------------------------------------------------------------------------
// Description: This is the Support level code for 10G Gigabit Ethernet.
//              It contains the block level instance and shareable clocking and
//              reset circuitry.
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module axi_10g_eth_support (
   // Port declarations
   input                               refclk,
   input                               dclk,
   output                              coreclk_out,
   input                               reset,
   output                              qplloutclk_out,
   output                              qplloutrefclk_out,
   output                              qplllock_out,
   output                              resetdone_out,
   output                              txusrclk_out,
   output                              txusrclk2_out,
   output                              gttxreset_out,
   output                              gtrxreset_out,
   output                              txuserrdy_out,
   output                              reset_counter_done_out,

      // AXI Lite config I/F
   input                               s_axi_aclk,
   input                               s_axi_aresetn,
   input       [10:0]                  s_axi_awaddr,
   input                               s_axi_awvalid,
   output                              s_axi_awready,
   input       [31:0]                  s_axi_wdata,
   input                               s_axi_wvalid,
   output                              s_axi_wready,
   output      [1:0]                   s_axi_bresp,
   output                              s_axi_bvalid,
   input                               s_axi_bready,
   input       [10:0]                  s_axi_araddr,
   input                               s_axi_arvalid,
   output                              s_axi_arready,

   output      [31:0]                  s_axi_rdata,
   output      [1:0]                   s_axi_rresp,
   output                              s_axi_rvalid,
   input                               s_axi_rready,

   output                              xgmacint,

   input       [7:0]                   tx_ifg_delay,

   output      [25:0]                  tx_statistics_vector,
   output      [29:0]                  rx_statistics_vector,
   output                              tx_statistics_valid,
   output                              rx_statistics_valid,

   input                               tx_axis_aresetn,
   input       [63:0]                  s_axis_tx_tdata,
   input       [7:0]                   s_axis_tx_tkeep,
   input                               s_axis_tx_tvalid,
   input                               s_axis_tx_tlast,
   input                               s_axis_tx_tuser,
   output                              s_axis_tx_tready,

   input                               rx_axis_aresetn,
   output      [63:0]                  m_axis_rx_tdata,
   output      [7:0]                   m_axis_rx_tkeep,
   output                              m_axis_rx_tvalid,
   output                              m_axis_rx_tuser,
   output                              m_axis_rx_tlast,



   //Pause axis
   input      [15:0]                   s_axis_pause_tdata,
   input                               s_axis_pause_tvalid,

   output                              txp,
   output                              txn,
   input                               rxp,
   input                               rxn,

   output                              tx_disable,
   output wire                         rxrecclk_out,
   input                               signal_detect,
   input                               sim_speedup_control,
   input                               tx_fault,
   output      [7:0]                   pcspma_status
   );

/*-------------------------------------------------------------------------*/

  // Signal declarations

  wire coreclk;
  wire txoutclk;
  wire qplloutclk;
  wire qplloutrefclk;
  wire qplllock;
  wire tx_resetdone_int;
  wire rx_resetdone_int;
  wire areset_coreclk;
  wire gttxreset;
  wire gtrxreset;
  wire txuserrdy;
  wire reset_counter_done;
  wire txusrclk;
  wire txusrclk2;
  wire txoutclk_in;

  assign coreclk_out            = coreclk;

  assign resetdone_out          = tx_resetdone_int && rx_resetdone_int;

  assign qplloutclk_out         = qplloutclk;
  assign qplloutrefclk_out      = qplloutrefclk;
  assign qplllock_out           = qplllock;
  assign txusrclk_out           = txusrclk;
  assign txusrclk2_out          = txusrclk2;
  assign gttxreset_out          = gttxreset;
  assign gtrxreset_out          = gtrxreset;
  assign txuserrdy_out          = txuserrdy;
  assign reset_counter_done_out = reset_counter_done;

  //---------------------------------------------------------------------------
  // Instantiate the shared clock/reset block that also contains the gt_common
  //---------------------------------------------------------------------------

  axi_10g_eth_shared_clocking_wrapper shared_clocking_wrapper_i
    (
     .reset                            (reset),
     .refclk                           (refclk),
     .dclk                             (dclk),
     .coreclk                          (coreclk),
     .txoutclk                         (txoutclk),
     .txoutclk_out                     (txoutclk_in),
     .areset_coreclk                   (areset_coreclk),
     .gttxreset                        (gttxreset),
     .gtrxreset                        (gtrxreset),
     .txuserrdy                        (txuserrdy),
     .txusrclk                         (txusrclk),
     .txusrclk2                        (txusrclk2),
     .qplllock_out                     (qplllock),
     .qplloutclk                       (qplloutclk),
     .qplloutrefclk                    (qplloutrefclk),
     .reset_counter_done               (reset_counter_done)
    );

  //---------------------------------------------------------------------------
  // Instantiate the AXI 10G Ethernet core
  //---------------------------------------------------------------------------
  axi_10g_eth ethernet_core_i (
      .dclk                            (dclk),
      .coreclk                         (coreclk),
      .txoutclk                        (txoutclk),
      .txusrclk                        (txusrclk),
      .txusrclk2                       (txusrclk2),
      .areset_coreclk                  (areset_coreclk),
      .txuserrdy                       (txuserrdy),
      .rxrecclk_out                    (rxrecclk_out),
      .areset                          (reset),
      .tx_resetdone                    (tx_resetdone_int),
      .rx_resetdone                    (rx_resetdone_int),
      .reset_counter_done              (reset_counter_done),
      .gttxreset                       (gttxreset),
      .gtrxreset                       (gtrxreset),
      .qplllock                        (qplllock),
      .qplloutclk                      (qplloutclk),
      .qplloutrefclk                   (qplloutrefclk),
      .tx_ifg_delay                    (tx_ifg_delay),
      .tx_statistics_vector            (tx_statistics_vector),
      .tx_statistics_valid             (tx_statistics_valid),
      .rx_statistics_vector            (rx_statistics_vector),
      .rx_statistics_valid             (rx_statistics_valid),
      .s_axis_pause_tdata              (s_axis_pause_tdata),
      .s_axis_pause_tvalid             (s_axis_pause_tvalid),

      .tx_axis_aresetn                 (tx_axis_aresetn),
      .s_axis_tx_tdata                 (s_axis_tx_tdata),
      .s_axis_tx_tvalid                (s_axis_tx_tvalid),
      .s_axis_tx_tlast                 (s_axis_tx_tlast),
      .s_axis_tx_tuser                 (s_axis_tx_tuser),
      .s_axis_tx_tkeep                 (s_axis_tx_tkeep),
      .s_axis_tx_tready                (s_axis_tx_tready),

      .rx_axis_aresetn                 (rx_axis_aresetn),
      .m_axis_rx_tdata                 (m_axis_rx_tdata),
      .m_axis_rx_tkeep                 (m_axis_rx_tkeep),
      .m_axis_rx_tvalid                (m_axis_rx_tvalid),
      .m_axis_rx_tuser                 (m_axis_rx_tuser),
      .m_axis_rx_tlast                 (m_axis_rx_tlast),
      .s_axi_aclk                      (s_axi_aclk),
      .s_axi_aresetn                   (s_axi_aresetn),
      .s_axi_awaddr                    (s_axi_awaddr),
      .s_axi_awvalid                   (s_axi_awvalid),
      .s_axi_awready                   (s_axi_awready),
      .s_axi_wdata                     (s_axi_wdata),
      .s_axi_wvalid                    (s_axi_wvalid),
      .s_axi_wready                    (s_axi_wready),
      .s_axi_bresp                     (s_axi_bresp),
      .s_axi_bvalid                    (s_axi_bvalid),
      .s_axi_bready                    (s_axi_bready),
      .s_axi_araddr                    (s_axi_araddr),
      .s_axi_arvalid                   (s_axi_arvalid),
      .s_axi_arready                   (s_axi_arready),
      .s_axi_rdata                     (s_axi_rdata),
      .s_axi_rresp                     (s_axi_rresp),
      .s_axi_rvalid                    (s_axi_rvalid),
      .s_axi_rready                    (s_axi_rready),

      .xgmacint                        (xgmacint),

      // Serial links
      .txp                             (txp),
      .txn                             (txn),
      .rxp                             (rxp),
      .rxn                             (rxn),

      .sim_speedup_control             (sim_speedup_control),
      .signal_detect                   (signal_detect),
      .tx_fault                        (tx_fault),
      .tx_disable                      (tx_disable),
      .pcspma_status                   (pcspma_status)
   );


endmodule
