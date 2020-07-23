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
//------------------------------------------------------------------------------------------
// Title      : Frame generation wrapper
// Project    : 10G Gigabit Ethernet
//------------------------------------------------------------------------------------------
// File       : axi_10g_eth_gen_check_wrapper.v
// Author     : Xilinx Inc.
// -----------------------------------------------------------------------------------------
// Description: This module allows either a user side loopback, with address swapping,
//              OR the generation of simple packets.  The selection being controlled by a top level input
//              which can be sourced fdrom a DIP switch in hardware.
//              The packet generation is controlled by simple parameters giving the ability to set the DA,
//              SA amd max/min size packets.  The data portion of each packet is always a simple
//              incrementing pattern.
//              When configured to loopback the first two columns of the packet are accepted and then the
//              packet is output with/without address swapping. Currently, this is hard wired in the address
//              swap logic.
//-------------------------------------------------------------------------------------------

`timescale 1ps/1ps

(* dont_touch = "yes" *)


module axi_10g_eth_gen_check_wrapper (
   input wire  [47:0]                  dest_addr,
   input wire  [47:0]                  src_addr,
   input wire  [14:0]                  max_size,
   input wire  [14:0]                  min_size,
   input wire                          enable_vlan,
   input wire  [11:0]                  vlan_id,
   input wire  [2:0]                   vlan_priority,
   input wire  [55:0]                  preamble_data,
   input wire                          enable_custom_preamble,

   input wire                          aclk,
   input wire                          aresetn,
   input wire                          reset_error,
   input wire                          insert_error,
   input wire                          enable_pat_gen,
   input wire                          enable_pat_check,
   input wire                          enable_loopback,
   input wire                          address_swap_enable,

   // data from the RX data path
   input       [63:0]                  rx_axis_tdata,
   input       [7:0]                   rx_axis_tkeep,
   input                               rx_axis_tvalid,
   input                               rx_axis_tlast,
   output                              rx_axis_tready,

   // data to the TX data path
   output      [63:0]                  tx_axis_tdata,
   output      [7:0]                   tx_axis_tkeep,
   output                              tx_axis_tvalid,
   output                              tx_axis_tlast,
   input                               tx_axis_tready,

   output wire                         gen_active,
   output wire                         check_active,
   output wire                         frame_error,
   output wire  [7:0]                  errored_data,
   output wire  [7:0]                  errored_addr,
   output wire  [7:0]                  errored_preamble
);

   wire                                areset;
   wire        [63:0]                  rx_axis_tdata_int;
   wire        [7:0]                   rx_axis_tkeep_int;
   wire                                rx_axis_tvalid_int;
   wire                                rx_axis_tlast_int;
   wire                                rx_axis_tready_int;

   wire        [63:0]                  pat_gen_tdata;
   wire        [7:0]                   pat_gen_tkeep;
   wire                                pat_gen_tvalid;
   wire                                pat_gen_tlast;
   wire                                pat_gen_tready;

   wire        [63:0]                  mux_tdata;
   wire        [7:0]                   mux_tkeep;
   wire                                mux_tvalid;
   wire                                mux_tlast;
   wire                                mux_tready;

   wire        [63:0]                  tx_axis_as_tdata;
   wire        [7:0]                   tx_axis_as_tkeep;
   wire                                tx_axis_as_tvalid;
   wire                                tx_axis_as_tlast;
   wire                                tx_axis_as_tready;

   wire                                enable_pat_gen_sync;
   wire                                enable_pat_check_sync;
   wire                                enable_loopback_sync;
   wire                                address_swap_enable_sync;
   
   assign tx_axis_tdata                = tx_axis_as_tdata;
   assign tx_axis_tkeep                = tx_axis_as_tkeep;
   assign tx_axis_tvalid               = tx_axis_as_tvalid;
   assign tx_axis_tlast                = tx_axis_as_tlast;
   assign tx_axis_as_tready            = tx_axis_tready;
   assign rx_axis_tready               = rx_axis_tready_int;

   axi_10g_eth_sync_reset areset_gen (
      .clk                             (aclk),
      .reset_in                        (~aresetn),
      .reset_out                       (areset)
      );

   axi_10g_eth_sync_block sync_pat_gen (
      .data_in                         (enable_pat_gen),
      .clk                             (aclk),
      .data_out                        (enable_pat_gen_sync)
   );

   axi_10g_eth_sync_block sync_pat_chk (
      .data_in                         (enable_pat_check),
      .clk                             (aclk),
      .data_out                        (enable_pat_check_sync)
   );

   axi_10g_eth_sync_block sync_loopback_enable (
      .clk                             (aclk),
      .data_in                         (enable_loopback),
      .data_out                        (enable_loopback_sync)
   );
   
   axi_10g_eth_sync_block sync_address_swap_enable (
      .clk                             (aclk),
      .data_in                         (address_swap_enable),
      .data_out                        (address_swap_enable_sync)
   );

   axi_10g_eth_axi_pat_gen generator (
      .dest_addr                       (dest_addr),
      .src_addr                        (src_addr),
      .max_size                        (max_size),
      .min_size                        (min_size),
      .enable_vlan                     (enable_vlan),
      .vlan_id                         (vlan_id),
      .vlan_priority                   (vlan_priority),
      .preamble_data                   (preamble_data),
      .enable_custom_preamble          (enable_custom_preamble),

      .aclk                            (aclk),
      .areset                          (areset),
      .insert_error                    (insert_error),
      .enable_pat_gen                  (enable_pat_gen_sync),

      .tdata                           (pat_gen_tdata),
      .tkeep                           (pat_gen_tkeep),
      .tvalid                          (pat_gen_tvalid),
      .tlast                           (pat_gen_tlast),
      .tready                          (pat_gen_tready),
      .gen_active                      (gen_active)
   );

   // simple mux between the rx_fifo AXI interface and the pat gen output
   axi_10g_eth_axi_mux axi_mux_inst (
      .mux_select                      (enable_loopback_sync),

      .tdata0                          (pat_gen_tdata),
      .tkeep0                          (pat_gen_tkeep),
      .tvalid0                         (pat_gen_tvalid),
      .tlast0                          (pat_gen_tlast),
      .tready0                         (pat_gen_tready),

      .tdata1                          (rx_axis_tdata),
      .tkeep1                          (rx_axis_tkeep),
      .tvalid1                         (rx_axis_tvalid),
      .tlast1                          (rx_axis_tlast),
      .tready1                         (rx_axis_tready_int),

      .tdata                           (mux_tdata),
      .tkeep                           (mux_tkeep),
      .tvalid                          (mux_tvalid),
      .tlast                           (mux_tlast),
      .tready                          (mux_tready)
   );


   // address swap module: based around a Dual port distributed ram
   // data is written in and the read only starts once the da/sa have been
   // stored.

   axi_10g_eth_address_swap address_swap (
      .aclk                            (aclk),
      .areset                          (areset),
      .enable_custom_preamble          (enable_custom_preamble),
      .address_swap_enable             (address_swap_enable_sync),  // do the address swap when in loopback

      .rx_axis_tdata                   (mux_tdata),
      .rx_axis_tkeep                   (mux_tkeep),
      .rx_axis_tvalid                  (mux_tvalid),
      .rx_axis_tlast                   (mux_tlast),
      .rx_axis_tready                  (mux_tready),
      .tx_axis_tdata                   (tx_axis_as_tdata),
      .tx_axis_tkeep                   (tx_axis_as_tkeep),
      .tx_axis_tvalid                  (tx_axis_as_tvalid),
      .tx_axis_tlast                   (tx_axis_as_tlast),
      .tx_axis_tready                  (tx_axis_as_tready)
   );



   axi_10g_eth_axi_pat_check checker(
      .dest_addr                       (dest_addr),
      .src_addr                        (src_addr),
      .max_size                        (max_size),
      .min_size                        (min_size),
      .enable_vlan                     (enable_vlan),
      .vlan_id                         (vlan_id),
      .vlan_priority                   (vlan_priority),
      .preamble_data                   (preamble_data),
      .enable_custom_preamble          (enable_custom_preamble),

      .aclk                            (aclk),
      .areset                          (areset),
      .reset_error                     (reset_error),
      .enable_pat_check                (enable_pat_check_sync),

      .tdata                           (rx_axis_tdata),
      .tkeep                           (rx_axis_tkeep),
      .tvalid                          (rx_axis_tvalid),
      .tlast                           (rx_axis_tlast),
      .tready                          (rx_axis_tready_int),
      .tuser                           (1'b1),
      .frame_error                     (frame_error),
      .errored_data                    (errored_data),
      .errored_addr                    (errored_addr),
      .errored_preamble                (errored_preamble),
      .check_active                    (check_active)
   );

endmodule

