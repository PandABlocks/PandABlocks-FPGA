// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.1 (lin64) Build 1215546 Mon Apr 27 19:07:21 MDT 2015
// Date        : Tue Sep 25 09:02:48 2018
// Host        : pc0030.cs.diamond.ac.uk running 64-bit Red Hat Enterprise Linux Workstation release 6.10 (Santiago)
// Command     : write_verilog -force -mode synth_stub
//               /home/ysx26594/Documents/PandABlocks-FPGA2/common/ip_repo/pulse_queue/pulse_queue_stub.v
// Design      : pulse_queue
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z030sbg485-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v12_0,Vivado 2015.1" *)
module pulse_queue(clk, srst, din, wr_en, rd_en, dout, full, empty, data_count)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[48:0],wr_en,rd_en,dout[48:0],full,empty,data_count[10:0]" */;
  input clk;
  input srst;
  input [48:0]din;
  input wr_en;
  input rd_en;
  output [48:0]dout;
  output full;
  output empty;
  output [10:0]data_count;
endmodule
