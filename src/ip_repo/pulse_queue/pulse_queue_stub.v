// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.1 (lin64) Build 1215546 Mon Apr 27 19:07:21 MDT 2015
// Date        : Fri Nov 20 13:26:21 2015
// Host        : pc0071.cs.diamond.ac.uk running 64-bit Red Hat Enterprise Linux Workstation release 6.7 (Santiago)
// Command     : write_verilog -force -mode synth_stub
//               /home/iu42/hardware/trunk/FPGA/PandA-Motion-Project/PandaFPGA/src/ip_repo/pulse_queue/pulse_queue_stub.v
// Design      : pulse_queue
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z030sbg485-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v12_0,Vivado 2015.1" *)
module pulse_queue(clk, rst, din, wr_en, rd_en, dout, full, empty)
/* synthesis syn_black_box black_box_pad_pin="clk,rst,din[47:0],wr_en,rd_en,dout[47:0],full,empty" */;
  input clk;
  input rst;
  input [47:0]din;
  input wr_en;
  input rd_en;
  output [47:0]dout;
  output full;
  output empty;
endmodule
