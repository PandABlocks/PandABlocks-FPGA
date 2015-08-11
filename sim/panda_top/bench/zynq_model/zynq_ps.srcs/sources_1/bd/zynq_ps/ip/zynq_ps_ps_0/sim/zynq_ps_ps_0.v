// (c) Copyright 1995-2015 Xilinx, Inc. All rights reserved.
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
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:ip:processing_system7_bfm:2.0
// IP Revision: 3

`timescale 1ns/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module zynq_ps_ps_0 (
  M_AXI_GP0_ARVALID,
  M_AXI_GP0_AWVALID,
  M_AXI_GP0_BREADY,
  M_AXI_GP0_RREADY,
  M_AXI_GP0_WLAST,
  M_AXI_GP0_WVALID,
  M_AXI_GP0_ARID,
  M_AXI_GP0_AWID,
  M_AXI_GP0_WID,
  M_AXI_GP0_ARBURST,
  M_AXI_GP0_ARLOCK,
  M_AXI_GP0_ARSIZE,
  M_AXI_GP0_AWBURST,
  M_AXI_GP0_AWLOCK,
  M_AXI_GP0_AWSIZE,
  M_AXI_GP0_ARPROT,
  M_AXI_GP0_AWPROT,
  M_AXI_GP0_ARADDR,
  M_AXI_GP0_AWADDR,
  M_AXI_GP0_WDATA,
  M_AXI_GP0_ARCACHE,
  M_AXI_GP0_ARLEN,
  M_AXI_GP0_ARQOS,
  M_AXI_GP0_AWCACHE,
  M_AXI_GP0_AWLEN,
  M_AXI_GP0_AWQOS,
  M_AXI_GP0_WSTRB,
  M_AXI_GP0_ACLK,
  M_AXI_GP0_ARREADY,
  M_AXI_GP0_AWREADY,
  M_AXI_GP0_BVALID,
  M_AXI_GP0_RLAST,
  M_AXI_GP0_RVALID,
  M_AXI_GP0_WREADY,
  M_AXI_GP0_BID,
  M_AXI_GP0_RID,
  M_AXI_GP0_BRESP,
  M_AXI_GP0_RRESP,
  M_AXI_GP0_RDATA,
  S_AXI_HP0_ARREADY,
  S_AXI_HP0_AWREADY,
  S_AXI_HP0_BVALID,
  S_AXI_HP0_RLAST,
  S_AXI_HP0_RVALID,
  S_AXI_HP0_WREADY,
  S_AXI_HP0_BRESP,
  S_AXI_HP0_RRESP,
  S_AXI_HP0_BID,
  S_AXI_HP0_RID,
  S_AXI_HP0_RDATA,
  S_AXI_HP0_ACLK,
  S_AXI_HP0_ARVALID,
  S_AXI_HP0_AWVALID,
  S_AXI_HP0_BREADY,
  S_AXI_HP0_RREADY,
  S_AXI_HP0_WLAST,
  S_AXI_HP0_WVALID,
  S_AXI_HP0_ARBURST,
  S_AXI_HP0_ARLOCK,
  S_AXI_HP0_ARSIZE,
  S_AXI_HP0_AWBURST,
  S_AXI_HP0_AWLOCK,
  S_AXI_HP0_AWSIZE,
  S_AXI_HP0_ARPROT,
  S_AXI_HP0_AWPROT,
  S_AXI_HP0_ARADDR,
  S_AXI_HP0_AWADDR,
  S_AXI_HP0_ARCACHE,
  S_AXI_HP0_ARLEN,
  S_AXI_HP0_ARQOS,
  S_AXI_HP0_AWCACHE,
  S_AXI_HP0_AWLEN,
  S_AXI_HP0_AWQOS,
  S_AXI_HP0_ARID,
  S_AXI_HP0_AWID,
  S_AXI_HP0_WID,
  S_AXI_HP0_WDATA,
  S_AXI_HP0_WSTRB,
  S_AXI_HP1_ARREADY,
  S_AXI_HP1_AWREADY,
  S_AXI_HP1_BVALID,
  S_AXI_HP1_RLAST,
  S_AXI_HP1_RVALID,
  S_AXI_HP1_WREADY,
  S_AXI_HP1_BRESP,
  S_AXI_HP1_RRESP,
  S_AXI_HP1_BID,
  S_AXI_HP1_RID,
  S_AXI_HP1_RDATA,
  S_AXI_HP1_ACLK,
  S_AXI_HP1_ARVALID,
  S_AXI_HP1_AWVALID,
  S_AXI_HP1_BREADY,
  S_AXI_HP1_RREADY,
  S_AXI_HP1_WLAST,
  S_AXI_HP1_WVALID,
  S_AXI_HP1_ARBURST,
  S_AXI_HP1_ARLOCK,
  S_AXI_HP1_ARSIZE,
  S_AXI_HP1_AWBURST,
  S_AXI_HP1_AWLOCK,
  S_AXI_HP1_AWSIZE,
  S_AXI_HP1_ARPROT,
  S_AXI_HP1_AWPROT,
  S_AXI_HP1_ARADDR,
  S_AXI_HP1_AWADDR,
  S_AXI_HP1_ARCACHE,
  S_AXI_HP1_ARLEN,
  S_AXI_HP1_ARQOS,
  S_AXI_HP1_AWCACHE,
  S_AXI_HP1_AWLEN,
  S_AXI_HP1_AWQOS,
  S_AXI_HP1_ARID,
  S_AXI_HP1_AWID,
  S_AXI_HP1_WID,
  S_AXI_HP1_WDATA,
  S_AXI_HP1_WSTRB,
  FCLK_CLK0,
  FCLK_CLK1,
  FCLK_CLK2,
  FCLK_CLK3,
  FCLK_RESET0_N,
  FCLK_RESET1_N,
  FCLK_RESET2_N,
  FCLK_RESET3_N,
  PS_SRSTB,
  PS_CLK,
  PS_PORB,
  IRQ_F2P
);

(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARVALID" *)
output wire M_AXI_GP0_ARVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWVALID" *)
output wire M_AXI_GP0_AWVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 BREADY" *)
output wire M_AXI_GP0_BREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 RREADY" *)
output wire M_AXI_GP0_RREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 WLAST" *)
output wire M_AXI_GP0_WLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 WVALID" *)
output wire M_AXI_GP0_WVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARID" *)
output wire [11 : 0] M_AXI_GP0_ARID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWID" *)
output wire [11 : 0] M_AXI_GP0_AWID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 WID" *)
output wire [11 : 0] M_AXI_GP0_WID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARBURST" *)
output wire [1 : 0] M_AXI_GP0_ARBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARLOCK" *)
output wire [1 : 0] M_AXI_GP0_ARLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARSIZE" *)
output wire [2 : 0] M_AXI_GP0_ARSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWBURST" *)
output wire [1 : 0] M_AXI_GP0_AWBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWLOCK" *)
output wire [1 : 0] M_AXI_GP0_AWLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWSIZE" *)
output wire [2 : 0] M_AXI_GP0_AWSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARPROT" *)
output wire [2 : 0] M_AXI_GP0_ARPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWPROT" *)
output wire [2 : 0] M_AXI_GP0_AWPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARADDR" *)
output wire [31 : 0] M_AXI_GP0_ARADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWADDR" *)
output wire [31 : 0] M_AXI_GP0_AWADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 WDATA" *)
output wire [31 : 0] M_AXI_GP0_WDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARCACHE" *)
output wire [3 : 0] M_AXI_GP0_ARCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARLEN" *)
output wire [3 : 0] M_AXI_GP0_ARLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARQOS" *)
output wire [3 : 0] M_AXI_GP0_ARQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWCACHE" *)
output wire [3 : 0] M_AXI_GP0_AWCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWLEN" *)
output wire [3 : 0] M_AXI_GP0_AWLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWQOS" *)
output wire [3 : 0] M_AXI_GP0_AWQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 WSTRB" *)
output wire [3 : 0] M_AXI_GP0_WSTRB;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_GP0_ACLK CLK" *)
input wire M_AXI_GP0_ACLK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 ARREADY" *)
input wire M_AXI_GP0_ARREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 AWREADY" *)
input wire M_AXI_GP0_AWREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 BVALID" *)
input wire M_AXI_GP0_BVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 RLAST" *)
input wire M_AXI_GP0_RLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 RVALID" *)
input wire M_AXI_GP0_RVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 WREADY" *)
input wire M_AXI_GP0_WREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 BID" *)
input wire [11 : 0] M_AXI_GP0_BID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 RID" *)
input wire [11 : 0] M_AXI_GP0_RID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 BRESP" *)
input wire [1 : 0] M_AXI_GP0_BRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 RRESP" *)
input wire [1 : 0] M_AXI_GP0_RRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_GP0 RDATA" *)
input wire [31 : 0] M_AXI_GP0_RDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARREADY" *)
output wire S_AXI_HP0_ARREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWREADY" *)
output wire S_AXI_HP0_AWREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 BVALID" *)
output wire S_AXI_HP0_BVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 RLAST" *)
output wire S_AXI_HP0_RLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 RVALID" *)
output wire S_AXI_HP0_RVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 WREADY" *)
output wire S_AXI_HP0_WREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 BRESP" *)
output wire [1 : 0] S_AXI_HP0_BRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 RRESP" *)
output wire [1 : 0] S_AXI_HP0_RRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 BID" *)
output wire [5 : 0] S_AXI_HP0_BID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 RID" *)
output wire [5 : 0] S_AXI_HP0_RID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 RDATA" *)
output wire [63 : 0] S_AXI_HP0_RDATA;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S_AXI_HP0_ACLK CLK" *)
input wire S_AXI_HP0_ACLK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARVALID" *)
input wire S_AXI_HP0_ARVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWVALID" *)
input wire S_AXI_HP0_AWVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 BREADY" *)
input wire S_AXI_HP0_BREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 RREADY" *)
input wire S_AXI_HP0_RREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 WLAST" *)
input wire S_AXI_HP0_WLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 WVALID" *)
input wire S_AXI_HP0_WVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARBURST" *)
input wire [1 : 0] S_AXI_HP0_ARBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARLOCK" *)
input wire [1 : 0] S_AXI_HP0_ARLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARSIZE" *)
input wire [2 : 0] S_AXI_HP0_ARSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWBURST" *)
input wire [1 : 0] S_AXI_HP0_AWBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWLOCK" *)
input wire [1 : 0] S_AXI_HP0_AWLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWSIZE" *)
input wire [2 : 0] S_AXI_HP0_AWSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARPROT" *)
input wire [2 : 0] S_AXI_HP0_ARPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWPROT" *)
input wire [2 : 0] S_AXI_HP0_AWPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARADDR" *)
input wire [31 : 0] S_AXI_HP0_ARADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWADDR" *)
input wire [31 : 0] S_AXI_HP0_AWADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARCACHE" *)
input wire [3 : 0] S_AXI_HP0_ARCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARLEN" *)
input wire [3 : 0] S_AXI_HP0_ARLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARQOS" *)
input wire [3 : 0] S_AXI_HP0_ARQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWCACHE" *)
input wire [3 : 0] S_AXI_HP0_AWCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWLEN" *)
input wire [3 : 0] S_AXI_HP0_AWLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWQOS" *)
input wire [3 : 0] S_AXI_HP0_AWQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 ARID" *)
input wire [5 : 0] S_AXI_HP0_ARID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 AWID" *)
input wire [5 : 0] S_AXI_HP0_AWID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 WID" *)
input wire [5 : 0] S_AXI_HP0_WID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 WDATA" *)
input wire [63 : 0] S_AXI_HP0_WDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP0 WSTRB" *)
input wire [7 : 0] S_AXI_HP0_WSTRB;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARREADY" *)
output wire S_AXI_HP1_ARREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWREADY" *)
output wire S_AXI_HP1_AWREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 BVALID" *)
output wire S_AXI_HP1_BVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 RLAST" *)
output wire S_AXI_HP1_RLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 RVALID" *)
output wire S_AXI_HP1_RVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 WREADY" *)
output wire S_AXI_HP1_WREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 BRESP" *)
output wire [1 : 0] S_AXI_HP1_BRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 RRESP" *)
output wire [1 : 0] S_AXI_HP1_RRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 BID" *)
output wire [5 : 0] S_AXI_HP1_BID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 RID" *)
output wire [5 : 0] S_AXI_HP1_RID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 RDATA" *)
output wire [31 : 0] S_AXI_HP1_RDATA;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S_AXI_HP1_ACLK CLK" *)
input wire S_AXI_HP1_ACLK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARVALID" *)
input wire S_AXI_HP1_ARVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWVALID" *)
input wire S_AXI_HP1_AWVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 BREADY" *)
input wire S_AXI_HP1_BREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 RREADY" *)
input wire S_AXI_HP1_RREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 WLAST" *)
input wire S_AXI_HP1_WLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 WVALID" *)
input wire S_AXI_HP1_WVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARBURST" *)
input wire [1 : 0] S_AXI_HP1_ARBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARLOCK" *)
input wire [1 : 0] S_AXI_HP1_ARLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARSIZE" *)
input wire [2 : 0] S_AXI_HP1_ARSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWBURST" *)
input wire [1 : 0] S_AXI_HP1_AWBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWLOCK" *)
input wire [1 : 0] S_AXI_HP1_AWLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWSIZE" *)
input wire [2 : 0] S_AXI_HP1_AWSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARPROT" *)
input wire [2 : 0] S_AXI_HP1_ARPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWPROT" *)
input wire [2 : 0] S_AXI_HP1_AWPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARADDR" *)
input wire [31 : 0] S_AXI_HP1_ARADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWADDR" *)
input wire [31 : 0] S_AXI_HP1_AWADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARCACHE" *)
input wire [3 : 0] S_AXI_HP1_ARCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARLEN" *)
input wire [3 : 0] S_AXI_HP1_ARLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARQOS" *)
input wire [3 : 0] S_AXI_HP1_ARQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWCACHE" *)
input wire [3 : 0] S_AXI_HP1_AWCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWLEN" *)
input wire [3 : 0] S_AXI_HP1_AWLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWQOS" *)
input wire [3 : 0] S_AXI_HP1_AWQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 ARID" *)
input wire [5 : 0] S_AXI_HP1_ARID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 AWID" *)
input wire [5 : 0] S_AXI_HP1_AWID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 WID" *)
input wire [5 : 0] S_AXI_HP1_WID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 WDATA" *)
input wire [31 : 0] S_AXI_HP1_WDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_HP1 WSTRB" *)
input wire [3 : 0] S_AXI_HP1_WSTRB;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 FCLK_CLK0 CLK" *)
output wire FCLK_CLK0;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 FCLK_CLK1 CLK" *)
output wire FCLK_CLK1;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 FCLK_CLK2 CLK" *)
output wire FCLK_CLK2;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 FCLK_CLK3 CLK" *)
output wire FCLK_CLK3;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 FCLK_RESET0_N RST" *)
output wire FCLK_RESET0_N;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 FCLK_RESET1_N RST" *)
output wire FCLK_RESET1_N;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 FCLK_RESET2_N RST" *)
output wire FCLK_RESET2_N;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 FCLK_RESET3_N RST" *)
output wire FCLK_RESET3_N;
input wire PS_SRSTB;
input wire PS_CLK;
input wire PS_PORB;
(* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 IRQ_F2P INTERRUPT" *)
input wire [3 : 0] IRQ_F2P;

  processing_system7_bfm_v2_0_processing_system7_bfm #(
    .C_USE_M_AXI_GP0(1),
    .C_M_AXI_GP0_ENABLE_STATIC_REMAP(0),
    .C_M_AXI_GP0_THREAD_ID_WIDTH(12),
    .C_USE_M_AXI_GP1(0),
    .C_M_AXI_GP1_ENABLE_STATIC_REMAP(0),
    .C_M_AXI_GP1_THREAD_ID_WIDTH(12),
    .C_USE_S_AXI_ACP(0),
    .C_USE_S_AXI_GP0(0),
    .C_USE_S_AXI_GP1(0),
    .C_USE_S_AXI_HP0(1),
    .C_USE_S_AXI_HP1(1),
    .C_USE_S_AXI_HP2(0),
    .C_USE_S_AXI_HP3(0),
    .C_S_AXI_HP0_DATA_WIDTH(64),
    .C_S_AXI_HP1_DATA_WIDTH(32),
    .C_S_AXI_HP2_DATA_WIDTH(32),
    .C_S_AXI_HP3_DATA_WIDTH(32),
    .C_HIGH_OCM_EN(0),
    .C_FCLK_CLK0_FREQ(125),
    .C_FCLK_CLK1_FREQ(50),
    .C_FCLK_CLK2_FREQ(50),
    .C_FCLK_CLK3_FREQ(50)
  ) inst (
    .M_AXI_GP0_ARVALID(M_AXI_GP0_ARVALID),
    .M_AXI_GP0_AWVALID(M_AXI_GP0_AWVALID),
    .M_AXI_GP0_BREADY(M_AXI_GP0_BREADY),
    .M_AXI_GP0_RREADY(M_AXI_GP0_RREADY),
    .M_AXI_GP0_WLAST(M_AXI_GP0_WLAST),
    .M_AXI_GP0_WVALID(M_AXI_GP0_WVALID),
    .M_AXI_GP0_ARID(M_AXI_GP0_ARID),
    .M_AXI_GP0_AWID(M_AXI_GP0_AWID),
    .M_AXI_GP0_WID(M_AXI_GP0_WID),
    .M_AXI_GP0_ARBURST(M_AXI_GP0_ARBURST),
    .M_AXI_GP0_ARLOCK(M_AXI_GP0_ARLOCK),
    .M_AXI_GP0_ARSIZE(M_AXI_GP0_ARSIZE),
    .M_AXI_GP0_AWBURST(M_AXI_GP0_AWBURST),
    .M_AXI_GP0_AWLOCK(M_AXI_GP0_AWLOCK),
    .M_AXI_GP0_AWSIZE(M_AXI_GP0_AWSIZE),
    .M_AXI_GP0_ARPROT(M_AXI_GP0_ARPROT),
    .M_AXI_GP0_AWPROT(M_AXI_GP0_AWPROT),
    .M_AXI_GP0_ARADDR(M_AXI_GP0_ARADDR),
    .M_AXI_GP0_AWADDR(M_AXI_GP0_AWADDR),
    .M_AXI_GP0_WDATA(M_AXI_GP0_WDATA),
    .M_AXI_GP0_ARCACHE(M_AXI_GP0_ARCACHE),
    .M_AXI_GP0_ARLEN(M_AXI_GP0_ARLEN),
    .M_AXI_GP0_ARQOS(M_AXI_GP0_ARQOS),
    .M_AXI_GP0_AWCACHE(M_AXI_GP0_AWCACHE),
    .M_AXI_GP0_AWLEN(M_AXI_GP0_AWLEN),
    .M_AXI_GP0_AWQOS(M_AXI_GP0_AWQOS),
    .M_AXI_GP0_WSTRB(M_AXI_GP0_WSTRB),
    .M_AXI_GP0_ACLK(M_AXI_GP0_ACLK),
    .M_AXI_GP0_ARREADY(M_AXI_GP0_ARREADY),
    .M_AXI_GP0_AWREADY(M_AXI_GP0_AWREADY),
    .M_AXI_GP0_BVALID(M_AXI_GP0_BVALID),
    .M_AXI_GP0_RLAST(M_AXI_GP0_RLAST),
    .M_AXI_GP0_RVALID(M_AXI_GP0_RVALID),
    .M_AXI_GP0_WREADY(M_AXI_GP0_WREADY),
    .M_AXI_GP0_BID(M_AXI_GP0_BID),
    .M_AXI_GP0_RID(M_AXI_GP0_RID),
    .M_AXI_GP0_BRESP(M_AXI_GP0_BRESP),
    .M_AXI_GP0_RRESP(M_AXI_GP0_RRESP),
    .M_AXI_GP0_RDATA(M_AXI_GP0_RDATA),
    .M_AXI_GP1_ARVALID(),
    .M_AXI_GP1_AWVALID(),
    .M_AXI_GP1_BREADY(),
    .M_AXI_GP1_RREADY(),
    .M_AXI_GP1_WLAST(),
    .M_AXI_GP1_WVALID(),
    .M_AXI_GP1_ARID(),
    .M_AXI_GP1_AWID(),
    .M_AXI_GP1_WID(),
    .M_AXI_GP1_ARBURST(),
    .M_AXI_GP1_ARLOCK(),
    .M_AXI_GP1_ARSIZE(),
    .M_AXI_GP1_AWBURST(),
    .M_AXI_GP1_AWLOCK(),
    .M_AXI_GP1_AWSIZE(),
    .M_AXI_GP1_ARPROT(),
    .M_AXI_GP1_AWPROT(),
    .M_AXI_GP1_ARADDR(),
    .M_AXI_GP1_AWADDR(),
    .M_AXI_GP1_WDATA(),
    .M_AXI_GP1_ARCACHE(),
    .M_AXI_GP1_ARLEN(),
    .M_AXI_GP1_ARQOS(),
    .M_AXI_GP1_AWCACHE(),
    .M_AXI_GP1_AWLEN(),
    .M_AXI_GP1_AWQOS(),
    .M_AXI_GP1_WSTRB(),
    .M_AXI_GP1_ACLK(1'B0),
    .M_AXI_GP1_ARREADY(1'B0),
    .M_AXI_GP1_AWREADY(1'B0),
    .M_AXI_GP1_BVALID(1'B0),
    .M_AXI_GP1_RLAST(1'B0),
    .M_AXI_GP1_RVALID(1'B0),
    .M_AXI_GP1_WREADY(1'B0),
    .M_AXI_GP1_BID(12'B0),
    .M_AXI_GP1_RID(12'B0),
    .M_AXI_GP1_BRESP(2'B0),
    .M_AXI_GP1_RRESP(2'B0),
    .M_AXI_GP1_RDATA(32'B0),
    .S_AXI_GP0_ARREADY(),
    .S_AXI_GP0_AWREADY(),
    .S_AXI_GP0_BVALID(),
    .S_AXI_GP0_RLAST(),
    .S_AXI_GP0_RVALID(),
    .S_AXI_GP0_WREADY(),
    .S_AXI_GP0_BRESP(),
    .S_AXI_GP0_RRESP(),
    .S_AXI_GP0_RDATA(),
    .S_AXI_GP0_BID(),
    .S_AXI_GP0_RID(),
    .S_AXI_GP0_ACLK(1'B0),
    .S_AXI_GP0_ARVALID(1'B0),
    .S_AXI_GP0_AWVALID(1'B0),
    .S_AXI_GP0_BREADY(1'B0),
    .S_AXI_GP0_RREADY(1'B0),
    .S_AXI_GP0_WLAST(1'B0),
    .S_AXI_GP0_WVALID(1'B0),
    .S_AXI_GP0_ARBURST(2'B0),
    .S_AXI_GP0_ARLOCK(2'B0),
    .S_AXI_GP0_ARSIZE(3'B0),
    .S_AXI_GP0_AWBURST(2'B0),
    .S_AXI_GP0_AWLOCK(2'B0),
    .S_AXI_GP0_AWSIZE(3'B0),
    .S_AXI_GP0_ARPROT(3'B0),
    .S_AXI_GP0_AWPROT(3'B0),
    .S_AXI_GP0_ARADDR(32'B0),
    .S_AXI_GP0_AWADDR(32'B0),
    .S_AXI_GP0_WDATA(32'B0),
    .S_AXI_GP0_ARCACHE(4'B0),
    .S_AXI_GP0_ARLEN(4'B0),
    .S_AXI_GP0_ARQOS(4'B0),
    .S_AXI_GP0_AWCACHE(4'B0),
    .S_AXI_GP0_AWLEN(4'B0),
    .S_AXI_GP0_AWQOS(4'B0),
    .S_AXI_GP0_WSTRB(4'B0),
    .S_AXI_GP0_ARID(6'B0),
    .S_AXI_GP0_AWID(6'B0),
    .S_AXI_GP0_WID(6'B0),
    .S_AXI_GP1_ARREADY(),
    .S_AXI_GP1_AWREADY(),
    .S_AXI_GP1_BVALID(),
    .S_AXI_GP1_RLAST(),
    .S_AXI_GP1_RVALID(),
    .S_AXI_GP1_WREADY(),
    .S_AXI_GP1_BRESP(),
    .S_AXI_GP1_RRESP(),
    .S_AXI_GP1_RDATA(),
    .S_AXI_GP1_BID(),
    .S_AXI_GP1_RID(),
    .S_AXI_GP1_ACLK(1'B0),
    .S_AXI_GP1_ARVALID(1'B0),
    .S_AXI_GP1_AWVALID(1'B0),
    .S_AXI_GP1_BREADY(1'B0),
    .S_AXI_GP1_RREADY(1'B0),
    .S_AXI_GP1_WLAST(1'B0),
    .S_AXI_GP1_WVALID(1'B0),
    .S_AXI_GP1_ARBURST(2'B0),
    .S_AXI_GP1_ARLOCK(2'B0),
    .S_AXI_GP1_ARSIZE(3'B0),
    .S_AXI_GP1_AWBURST(2'B0),
    .S_AXI_GP1_AWLOCK(2'B0),
    .S_AXI_GP1_AWSIZE(3'B0),
    .S_AXI_GP1_ARPROT(3'B0),
    .S_AXI_GP1_AWPROT(3'B0),
    .S_AXI_GP1_ARADDR(32'B0),
    .S_AXI_GP1_AWADDR(32'B0),
    .S_AXI_GP1_WDATA(32'B0),
    .S_AXI_GP1_ARCACHE(4'B0),
    .S_AXI_GP1_ARLEN(4'B0),
    .S_AXI_GP1_ARQOS(4'B0),
    .S_AXI_GP1_AWCACHE(4'B0),
    .S_AXI_GP1_AWLEN(4'B0),
    .S_AXI_GP1_AWQOS(4'B0),
    .S_AXI_GP1_WSTRB(4'B0),
    .S_AXI_GP1_ARID(6'B0),
    .S_AXI_GP1_AWID(6'B0),
    .S_AXI_GP1_WID(6'B0),
    .S_AXI_ACP_ARREADY(),
    .S_AXI_ACP_AWREADY(),
    .S_AXI_ACP_BVALID(),
    .S_AXI_ACP_RLAST(),
    .S_AXI_ACP_RVALID(),
    .S_AXI_ACP_WREADY(),
    .S_AXI_ACP_BRESP(),
    .S_AXI_ACP_RRESP(),
    .S_AXI_ACP_BID(),
    .S_AXI_ACP_RID(),
    .S_AXI_ACP_RDATA(),
    .S_AXI_ACP_ACLK(1'B0),
    .S_AXI_ACP_ARVALID(1'B0),
    .S_AXI_ACP_AWVALID(1'B0),
    .S_AXI_ACP_BREADY(1'B0),
    .S_AXI_ACP_RREADY(1'B0),
    .S_AXI_ACP_WLAST(1'B0),
    .S_AXI_ACP_WVALID(1'B0),
    .S_AXI_ACP_ARID(3'B0),
    .S_AXI_ACP_ARPROT(3'B0),
    .S_AXI_ACP_AWID(3'B0),
    .S_AXI_ACP_AWPROT(3'B0),
    .S_AXI_ACP_WID(3'B0),
    .S_AXI_ACP_ARADDR(32'B0),
    .S_AXI_ACP_AWADDR(32'B0),
    .S_AXI_ACP_ARCACHE(4'B0),
    .S_AXI_ACP_ARLEN(4'B0),
    .S_AXI_ACP_ARQOS(4'B0),
    .S_AXI_ACP_AWCACHE(4'B0),
    .S_AXI_ACP_AWLEN(4'B0),
    .S_AXI_ACP_AWQOS(4'B0),
    .S_AXI_ACP_ARBURST(2'B0),
    .S_AXI_ACP_ARLOCK(2'B0),
    .S_AXI_ACP_ARSIZE(3'B0),
    .S_AXI_ACP_AWBURST(2'B0),
    .S_AXI_ACP_AWLOCK(2'B0),
    .S_AXI_ACP_AWSIZE(3'B0),
    .S_AXI_ACP_ARUSER(5'B0),
    .S_AXI_ACP_AWUSER(5'B0),
    .S_AXI_ACP_WDATA(64'B0),
    .S_AXI_ACP_WSTRB(8'B0),
    .S_AXI_HP0_ARREADY(S_AXI_HP0_ARREADY),
    .S_AXI_HP0_AWREADY(S_AXI_HP0_AWREADY),
    .S_AXI_HP0_BVALID(S_AXI_HP0_BVALID),
    .S_AXI_HP0_RLAST(S_AXI_HP0_RLAST),
    .S_AXI_HP0_RVALID(S_AXI_HP0_RVALID),
    .S_AXI_HP0_WREADY(S_AXI_HP0_WREADY),
    .S_AXI_HP0_BRESP(S_AXI_HP0_BRESP),
    .S_AXI_HP0_RRESP(S_AXI_HP0_RRESP),
    .S_AXI_HP0_BID(S_AXI_HP0_BID),
    .S_AXI_HP0_RID(S_AXI_HP0_RID),
    .S_AXI_HP0_RDATA(S_AXI_HP0_RDATA),
    .S_AXI_HP0_ACLK(S_AXI_HP0_ACLK),
    .S_AXI_HP0_ARVALID(S_AXI_HP0_ARVALID),
    .S_AXI_HP0_AWVALID(S_AXI_HP0_AWVALID),
    .S_AXI_HP0_BREADY(S_AXI_HP0_BREADY),
    .S_AXI_HP0_RREADY(S_AXI_HP0_RREADY),
    .S_AXI_HP0_WLAST(S_AXI_HP0_WLAST),
    .S_AXI_HP0_WVALID(S_AXI_HP0_WVALID),
    .S_AXI_HP0_ARBURST(S_AXI_HP0_ARBURST),
    .S_AXI_HP0_ARLOCK(S_AXI_HP0_ARLOCK),
    .S_AXI_HP0_ARSIZE(S_AXI_HP0_ARSIZE),
    .S_AXI_HP0_AWBURST(S_AXI_HP0_AWBURST),
    .S_AXI_HP0_AWLOCK(S_AXI_HP0_AWLOCK),
    .S_AXI_HP0_AWSIZE(S_AXI_HP0_AWSIZE),
    .S_AXI_HP0_ARPROT(S_AXI_HP0_ARPROT),
    .S_AXI_HP0_AWPROT(S_AXI_HP0_AWPROT),
    .S_AXI_HP0_ARADDR(S_AXI_HP0_ARADDR),
    .S_AXI_HP0_AWADDR(S_AXI_HP0_AWADDR),
    .S_AXI_HP0_ARCACHE(S_AXI_HP0_ARCACHE),
    .S_AXI_HP0_ARLEN(S_AXI_HP0_ARLEN),
    .S_AXI_HP0_ARQOS(S_AXI_HP0_ARQOS),
    .S_AXI_HP0_AWCACHE(S_AXI_HP0_AWCACHE),
    .S_AXI_HP0_AWLEN(S_AXI_HP0_AWLEN),
    .S_AXI_HP0_AWQOS(S_AXI_HP0_AWQOS),
    .S_AXI_HP0_ARID(S_AXI_HP0_ARID),
    .S_AXI_HP0_AWID(S_AXI_HP0_AWID),
    .S_AXI_HP0_WID(S_AXI_HP0_WID),
    .S_AXI_HP0_WDATA(S_AXI_HP0_WDATA),
    .S_AXI_HP0_WSTRB(S_AXI_HP0_WSTRB),
    .S_AXI_HP1_ARREADY(S_AXI_HP1_ARREADY),
    .S_AXI_HP1_AWREADY(S_AXI_HP1_AWREADY),
    .S_AXI_HP1_BVALID(S_AXI_HP1_BVALID),
    .S_AXI_HP1_RLAST(S_AXI_HP1_RLAST),
    .S_AXI_HP1_RVALID(S_AXI_HP1_RVALID),
    .S_AXI_HP1_WREADY(S_AXI_HP1_WREADY),
    .S_AXI_HP1_BRESP(S_AXI_HP1_BRESP),
    .S_AXI_HP1_RRESP(S_AXI_HP1_RRESP),
    .S_AXI_HP1_BID(S_AXI_HP1_BID),
    .S_AXI_HP1_RID(S_AXI_HP1_RID),
    .S_AXI_HP1_RDATA(S_AXI_HP1_RDATA),
    .S_AXI_HP1_ACLK(S_AXI_HP1_ACLK),
    .S_AXI_HP1_ARVALID(S_AXI_HP1_ARVALID),
    .S_AXI_HP1_AWVALID(S_AXI_HP1_AWVALID),
    .S_AXI_HP1_BREADY(S_AXI_HP1_BREADY),
    .S_AXI_HP1_RREADY(S_AXI_HP1_RREADY),
    .S_AXI_HP1_WLAST(S_AXI_HP1_WLAST),
    .S_AXI_HP1_WVALID(S_AXI_HP1_WVALID),
    .S_AXI_HP1_ARBURST(S_AXI_HP1_ARBURST),
    .S_AXI_HP1_ARLOCK(S_AXI_HP1_ARLOCK),
    .S_AXI_HP1_ARSIZE(S_AXI_HP1_ARSIZE),
    .S_AXI_HP1_AWBURST(S_AXI_HP1_AWBURST),
    .S_AXI_HP1_AWLOCK(S_AXI_HP1_AWLOCK),
    .S_AXI_HP1_AWSIZE(S_AXI_HP1_AWSIZE),
    .S_AXI_HP1_ARPROT(S_AXI_HP1_ARPROT),
    .S_AXI_HP1_AWPROT(S_AXI_HP1_AWPROT),
    .S_AXI_HP1_ARADDR(S_AXI_HP1_ARADDR),
    .S_AXI_HP1_AWADDR(S_AXI_HP1_AWADDR),
    .S_AXI_HP1_ARCACHE(S_AXI_HP1_ARCACHE),
    .S_AXI_HP1_ARLEN(S_AXI_HP1_ARLEN),
    .S_AXI_HP1_ARQOS(S_AXI_HP1_ARQOS),
    .S_AXI_HP1_AWCACHE(S_AXI_HP1_AWCACHE),
    .S_AXI_HP1_AWLEN(S_AXI_HP1_AWLEN),
    .S_AXI_HP1_AWQOS(S_AXI_HP1_AWQOS),
    .S_AXI_HP1_ARID(S_AXI_HP1_ARID),
    .S_AXI_HP1_AWID(S_AXI_HP1_AWID),
    .S_AXI_HP1_WID(S_AXI_HP1_WID),
    .S_AXI_HP1_WDATA(S_AXI_HP1_WDATA),
    .S_AXI_HP1_WSTRB(S_AXI_HP1_WSTRB),
    .S_AXI_HP2_ARREADY(),
    .S_AXI_HP2_AWREADY(),
    .S_AXI_HP2_BVALID(),
    .S_AXI_HP2_RLAST(),
    .S_AXI_HP2_RVALID(),
    .S_AXI_HP2_WREADY(),
    .S_AXI_HP2_BRESP(),
    .S_AXI_HP2_RRESP(),
    .S_AXI_HP2_BID(),
    .S_AXI_HP2_RID(),
    .S_AXI_HP2_RDATA(),
    .S_AXI_HP2_ACLK(1'B0),
    .S_AXI_HP2_ARVALID(1'B0),
    .S_AXI_HP2_AWVALID(1'B0),
    .S_AXI_HP2_BREADY(1'B0),
    .S_AXI_HP2_RREADY(1'B0),
    .S_AXI_HP2_WLAST(1'B0),
    .S_AXI_HP2_WVALID(1'B0),
    .S_AXI_HP2_ARBURST(2'B0),
    .S_AXI_HP2_ARLOCK(2'B0),
    .S_AXI_HP2_ARSIZE(3'B0),
    .S_AXI_HP2_AWBURST(2'B0),
    .S_AXI_HP2_AWLOCK(2'B0),
    .S_AXI_HP2_AWSIZE(3'B0),
    .S_AXI_HP2_ARPROT(3'B0),
    .S_AXI_HP2_AWPROT(3'B0),
    .S_AXI_HP2_ARADDR(32'B0),
    .S_AXI_HP2_AWADDR(32'B0),
    .S_AXI_HP2_ARCACHE(4'B0),
    .S_AXI_HP2_ARLEN(4'B0),
    .S_AXI_HP2_ARQOS(4'B0),
    .S_AXI_HP2_AWCACHE(4'B0),
    .S_AXI_HP2_AWLEN(4'B0),
    .S_AXI_HP2_AWQOS(4'B0),
    .S_AXI_HP2_ARID(6'B0),
    .S_AXI_HP2_AWID(6'B0),
    .S_AXI_HP2_WID(6'B0),
    .S_AXI_HP2_WDATA(32'B0),
    .S_AXI_HP2_WSTRB(4'B0),
    .S_AXI_HP3_ARREADY(),
    .S_AXI_HP3_AWREADY(),
    .S_AXI_HP3_BVALID(),
    .S_AXI_HP3_RLAST(),
    .S_AXI_HP3_RVALID(),
    .S_AXI_HP3_WREADY(),
    .S_AXI_HP3_BRESP(),
    .S_AXI_HP3_RRESP(),
    .S_AXI_HP3_BID(),
    .S_AXI_HP3_RID(),
    .S_AXI_HP3_RDATA(),
    .S_AXI_HP3_ACLK(1'B0),
    .S_AXI_HP3_ARVALID(1'B0),
    .S_AXI_HP3_AWVALID(1'B0),
    .S_AXI_HP3_BREADY(1'B0),
    .S_AXI_HP3_RREADY(1'B0),
    .S_AXI_HP3_WLAST(1'B0),
    .S_AXI_HP3_WVALID(1'B0),
    .S_AXI_HP3_ARBURST(2'B0),
    .S_AXI_HP3_ARLOCK(2'B0),
    .S_AXI_HP3_ARSIZE(3'B0),
    .S_AXI_HP3_AWBURST(2'B0),
    .S_AXI_HP3_AWLOCK(2'B0),
    .S_AXI_HP3_AWSIZE(3'B0),
    .S_AXI_HP3_ARPROT(3'B0),
    .S_AXI_HP3_AWPROT(3'B0),
    .S_AXI_HP3_ARADDR(32'B0),
    .S_AXI_HP3_AWADDR(32'B0),
    .S_AXI_HP3_ARCACHE(4'B0),
    .S_AXI_HP3_ARLEN(4'B0),
    .S_AXI_HP3_ARQOS(4'B0),
    .S_AXI_HP3_AWCACHE(4'B0),
    .S_AXI_HP3_AWLEN(4'B0),
    .S_AXI_HP3_AWQOS(4'B0),
    .S_AXI_HP3_ARID(6'B0),
    .S_AXI_HP3_AWID(6'B0),
    .S_AXI_HP3_WID(6'B0),
    .S_AXI_HP3_WDATA(32'B0),
    .S_AXI_HP3_WSTRB(4'B0),
    .FCLK_CLK0(FCLK_CLK0),
    .FCLK_CLK1(FCLK_CLK1),
    .FCLK_CLK2(FCLK_CLK2),
    .FCLK_CLK3(FCLK_CLK3),
    .FCLK_RESET0_N(FCLK_RESET0_N),
    .FCLK_RESET1_N(FCLK_RESET1_N),
    .FCLK_RESET2_N(FCLK_RESET2_N),
    .FCLK_RESET3_N(FCLK_RESET3_N),
    .PS_SRSTB(PS_SRSTB),
    .PS_CLK(PS_CLK),
    .PS_PORB(PS_PORB),
    .IRQ_F2P(IRQ_F2P)
  );
endmodule
