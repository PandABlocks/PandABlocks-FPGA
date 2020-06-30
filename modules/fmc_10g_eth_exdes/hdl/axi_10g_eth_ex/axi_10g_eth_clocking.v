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
// Title      : Example Design clocking module
// Project    : 10G Gigabit Ethernet
//-----------------------------------------------------------------------------
// File       : axi_10g_eth_clocking.v
// Author     : Xilinx Inc.
//-----------------------------------------------------------------------------
// Description:  This is the clocking module for the example design logic of
//               the 10G Gigabit Ethernet core
//-----------------------------------------------------------------------------


`timescale 1ps / 1ps
(* dont_touch = "yes" *)
module axi_10g_eth_clocking
  (
   // Inputs
   input clk_in,
   input tx_mmcm_reset,

   // Clock outputs
   output s_axi_aclk,

   // Status outputs
   output tx_mmcm_locked);

  // Signal declarations
  wire s_axi_dcm_aclk0;
  wire clkfbout;
  wire clkin1;


//  IBUFDS clkin1_buf
//   (.O  (clkin1),
//    .I  (clk_in_p),
//    .IB (clk_in_n)
//    );
    
assign clkin1 = clk_in;

   MMCME2_BASE
  #(.DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (8),
    .CLKIN1_PERIOD        (8.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE_F     (8.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.5),
    .CLKOUT1_DIVIDE       (8.000),  //125MHz
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.5),
    .REF_JITTER1          (0.050))
  tx_mmcm
    // Output clocks
   (.CLKFBOUT            (clkfbout),
    .CLKOUT0             (s_axi_dcm_aclk0),
    .CLKOUT1             (),
     // Input clock control
    .CLKFBIN             (clkfbout),
    .CLKIN1              (clkin1),
    // Other control and status signals
    .LOCKED              (tx_mmcm_locked),
    .PWRDWN              (1'b0),
    // .RST                 (tx_mmcm_reset),
    .RST                 (1'b0),
    .CLKFBOUTB           (),
    .CLKOUT0B            (),
    .CLKOUT1B            (),
    .CLKOUT2             (),
    .CLKOUT2B            (),
    .CLKOUT3             (),
    .CLKOUT3B            (),
    .CLKOUT4             (),
    .CLKOUT5             (),
    .CLKOUT6             ());

//   MMCME2_BASE
//  #(.DIVCLK_DIVIDE        (1),
//    .CLKFBOUT_MULT_F      (5),
//    .CLKIN1_PERIOD        (5.000),
//    .CLKFBOUT_PHASE       (0.000),
//    .CLKOUT0_DIVIDE_F     (8.000),
//    .CLKOUT0_PHASE        (0.000),
//    .CLKOUT0_DUTY_CYCLE   (0.5),
//    .CLKOUT1_DIVIDE       (8.000),  //125MHz
//    .CLKOUT1_PHASE        (0.000),
//    .CLKOUT1_DUTY_CYCLE   (0.5),
//    .REF_JITTER1          (0.050))
//  tx_mmcm
//    // Output clocks
//   (.CLKFBOUT            (clkfbout),
//    .CLKOUT0             (s_axi_dcm_aclk0),
//    .CLKOUT1             (),
//     // Input clock control
//    .CLKFBIN             (clkfbout),
//    .CLKIN1              (clkin1),
//    // Other control and status signals
//    .LOCKED              (tx_mmcm_locked),
//    .PWRDWN              (1'b0),
//    // .RST                 (tx_mmcm_reset),
//    .RST                 (1'b0),
//    .CLKFBOUTB           (),
//    .CLKOUT0B            (),
//    .CLKOUT1B            (),
//    .CLKOUT2             (),
//    .CLKOUT2B            (),
//    .CLKOUT3             (),
//    .CLKOUT3B            (),
//    .CLKOUT4             (),
//    .CLKOUT5             (),
//    .CLKOUT6             ());

   BUFG s_axi_aclk_bufg0 (
     .I(s_axi_dcm_aclk0),
     .O(s_axi_aclk));

endmodule
