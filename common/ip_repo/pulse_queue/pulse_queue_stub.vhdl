-- Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2015.1 (lin64) Build 1215546 Mon Apr 27 19:07:21 MDT 2015
-- Date        : Mon Aug 13 15:03:26 2018
-- Host        : ws282.diamond.ac.uk running 64-bit Red Hat Enterprise Linux Workstation release 6.10 (Santiago)
-- Command     : write_vhdl -force -mode synth_stub
--               /home/zhz92437/code_panda/PandaFPGA/build/PandABox/ip_repo/pulse_queue/pulse_queue_stub.vhdl
-- Design      : pulse_queue
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z030sbg485-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pulse_queue is
  Port ( 
    clk : in STD_LOGIC;
    srst : in STD_LOGIC;
    din : in STD_LOGIC_VECTOR ( 48 downto 0 );
    wr_en : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    dout : out STD_LOGIC_VECTOR ( 48 downto 0 );
    full : out STD_LOGIC;
    empty : out STD_LOGIC;
    data_count : out STD_LOGIC_VECTOR ( 10 downto 0 )
  );

end pulse_queue;

architecture stub of pulse_queue is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,srst,din[48:0],wr_en,rd_en,dout[48:0],full,empty,data_count[10:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fifo_generator_v12_0,Vivado 2015.1";
begin
end;
