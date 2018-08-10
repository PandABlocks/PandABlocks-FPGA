--------------------------------------------------------------------------------
-- File       : tri_mode_ethernet_mac_0_basic_pat_gen.vhd
-- Author     : Xilinx Inc.
-- -----------------------------------------------------------------------------
-- (c) Copyright 2010 Xilinx, Inc. All rights reserved.
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
-- Description:  This module allows either a user side loopback, with address swapping,
-- OR the generation of simple packets.  The selection being controlled by a top level input
-- which can be sourced fdrom a DIP switch in hardware.
-- The packet generation is controlled by simple parameters giving the ability to set the DA,
-- SA amd max/min size packets.  The data portion of each packet is always a simple
-- incrementing pattern.
-- When configured to loopback the first 12 bytes of the packet are accepted and then the
-- packet is output with/without address swapping.  Currently, this is hard wired in the address
-- swap logic.
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;


entity tri_mode_ethernet_mac_0_basic_pat_gen is
   generic (
      DEST_ADDR                  : bit_vector(47 downto 0) := X"da0102030405";
      SRC_ADDR                   : bit_vector(47 downto 0) := X"5a0102030405";
      MAX_SIZE                   : unsigned(11 downto 0) := X"1f4";
      MIN_SIZE                   : unsigned(11 downto 0) := X"040";
      ENABLE_VLAN                : boolean := false;
      VLAN_ID                    : bit_vector(11 downto 0) := X"002";
      VLAN_PRIORITY              : bit_vector(2 downto 0) := "010"
   );
   port (
    axi_tclk                     : in  std_logic;
    axi_tresetn                  : in  std_logic;
    check_resetn                 : in  std_logic;

    enable_pat_gen               : in  std_logic;
    enable_pat_chk               : in  std_logic;
    
    enable_address_swap          : in  std_logic;
    
    speed                        : in  std_logic_vector(1 downto 0);

    -- data from the RX data path
    rx_axis_tdata                : in  std_logic_vector(7 downto 0);
    rx_axis_tvalid               : in  std_logic;
    rx_axis_tlast                : in  std_logic;
    rx_axis_tuser                : in  std_logic;
    rx_axis_tready               : out std_logic;
    -- data TO the TX data path
    tx_axis_tdata                : out std_logic_vector(7 downto 0);
    tx_axis_tvalid               : out std_logic;
    tx_axis_tlast                : out std_logic;
    tx_axis_tready               : in  std_logic;

    frame_error                  : out std_logic;
    activity_flash               : out std_logic
   );
end tri_mode_ethernet_mac_0_basic_pat_gen;

architecture rtl of tri_mode_ethernet_mac_0_basic_pat_gen is

   attribute DowngradeIPIdentifiedWarnings: string;
   attribute DowngradeIPIdentifiedWarnings of rtl : architecture is "yes";

   ------------------------------------------------------------------------------
   -- Component Declaration for the tri_mode_ethernet_mac_0_axi_pipe
   ------------------------------------------------------------------------------
   component tri_mode_ethernet_mac_0_axi_pipe
   port (
      axi_tclk                         : in  std_logic;
      axi_tresetn                      : in  std_logic;

      rx_axis_fifo_tdata_in            : in  std_logic_vector(7 downto 0);
      rx_axis_fifo_tvalid_in           : in  std_logic;
      rx_axis_fifo_tlast_in            : in  std_logic;
      rx_axis_fifo_tready_in           : out std_logic;

      rx_axis_fifo_tdata_out           : out std_logic_vector(7 downto 0);
      rx_axis_fifo_tvalid_out          : out std_logic;
      rx_axis_fifo_tlast_out           : out std_logic;
      rx_axis_fifo_tready_out          : in  std_logic
   );
   end component;

   ------------------------------------------------------------------------------
   -- Component Declaration for the tri_mode_ethernet_mac_0_axi_mux
   ------------------------------------------------------------------------------
   component tri_mode_ethernet_mac_0_axi_mux
   port (
      mux_select                 : in  std_logic;

      -- mux inputs
      tdata0                     : in  std_logic_vector(7 downto 0);
      tvalid0                    : in  std_logic;
      tlast0                     : in  std_logic;
      tready0                    : out std_logic;

      tdata1                     : in  std_logic_vector(7 downto 0);
      tvalid1                    : in  std_logic;
      tlast1                     : in  std_logic;
      tready1                    : out std_logic;

      -- mux outputs
      tdata                      : out std_logic_vector(7 downto 0);
      tvalid                     : out std_logic;
      tlast                      : out std_logic;
      tready                     : in  std_logic
   );
   end component;

   ------------------------------------------------------------------------------
   -- Component Declaration for the tri_mode_ethernet_mac_0_axi_pat_gen
   ------------------------------------------------------------------------------
   component tri_mode_ethernet_mac_0_axi_pat_gen
   generic (
      DEST_ADDR                  : bit_vector(47 downto 0) := X"da0102030405";
      SRC_ADDR                   : bit_vector(47 downto 0) := X"5a0102030405";
      MAX_SIZE                   : unsigned(11 downto 0) := X"1f4";
      MIN_SIZE                   : unsigned(11 downto 0) := X"040";
      ENABLE_VLAN                : boolean := false;
      VLAN_ID                    : bit_vector(11 downto 0) := X"002";
      VLAN_PRIORITY              : bit_vector(2 downto 0) := "010"
   );
   port (
      axi_tclk                   : in  std_logic;
      axi_tresetn                : in  std_logic;

      enable_pat_gen             : in  std_logic;
      speed                      : in  std_logic_vector(1 downto 0);

      tdata                      : out std_logic_vector(7 downto 0);
      tvalid                     : out std_logic;
      tlast                      : out std_logic;
      tready                     : in  std_logic
   );
   end component;

   ------------------------------------------------------------------------------
   -- Component Declaration for the tri_mode_ethernet_mac_0_axi_pat_check
   ------------------------------------------------------------------------------
   component tri_mode_ethernet_mac_0_axi_pat_check
   generic (
      DEST_ADDR                  : bit_vector(47 downto 0) := X"da0102030405";
      SRC_ADDR                   : bit_vector(47 downto 0) := X"5a0102030405";
      MAX_SIZE                   : unsigned(11 downto 0) := X"1f4";
      MIN_SIZE                   : unsigned(11 downto 0) := X"040";
      ENABLE_VLAN                : boolean := false;
      VLAN_ID                    : bit_vector(11 downto 0) := X"002";
      VLAN_PRIORITY              : bit_vector(2 downto 0) := "010"
   );
   port (
      axi_tclk                   : in  std_logic;
      axi_tresetn                : in  std_logic;

      enable_pat_chk             : in  std_logic;
      speed                      : in  std_logic_vector(1 downto 0);

      tdata                      : in  std_logic_vector(7 downto 0);
      tvalid                     : in  std_logic;
      tlast                      : in  std_logic;
      tready                     : in  std_logic;
      tuser                      : in  std_logic;

      frame_error                : out std_logic;
      activity_flash             : out std_logic
   );
   end component;

   ------------------------------------------------------------------------------
   -- Component Declaration for the tri_mode_ethernet_mac_0_address_swap
   ------------------------------------------------------------------------------
   component tri_mode_ethernet_mac_0_address_swap
   port (
    axi_tclk                        : in  std_logic;
    axi_tresetn                     : in  std_logic;

    enable_address_swap             : in  std_logic;

    -- data from the RX FIFO
    rx_axis_fifo_tdata              : in  std_logic_vector(7 downto 0);
    rx_axis_fifo_tvalid             : in  std_logic;
    rx_axis_fifo_tlast              : in  std_logic;
    rx_axis_fifo_tready             : out std_logic;
    -- data TO the tx fifo
    tx_axis_fifo_tdata              : out std_logic_vector(7 downto 0);
    tx_axis_fifo_tvalid             : out std_logic;
    tx_axis_fifo_tlast              : out std_logic;
    tx_axis_fifo_tready             : in std_logic

  );
  end component;


   signal rx_axis_fifo_tdata_int  : std_logic_vector(7 downto 0);
   signal rx_axis_fifo_tvalid_int : std_logic;
   signal rx_axis_fifo_tlast_int  : std_logic;
   signal rx_axis_fifo_tready_int : std_logic;
   
   signal rx_axis_tready_lcl      : std_logic;
   

   signal pat_gen_tdata          : std_logic_vector(7 downto 0);
   signal pat_gen_tvalid         : std_logic;
   signal pat_gen_tlast          : std_logic;
   signal pat_gen_tready         : std_logic;
   signal pat_gen_tready_int     : std_logic;

   signal mux_tdata              : std_logic_vector(7 downto 0);
   signal mux_tvalid             : std_logic;
   signal mux_tlast              : std_logic;
   signal mux_tready             : std_logic;

   signal tx_axis_as_tdata       : std_logic_vector(7 downto 0);
   signal tx_axis_as_tvalid      : std_logic;
   signal tx_axis_as_tlast       : std_logic;
   signal tx_axis_as_tready      : std_logic;


begin

   
   rx_axis_tready <= rx_axis_tready_lcl;
   


   tx_axis_tdata  <= tx_axis_as_tdata;
   tx_axis_tvalid <= tx_axis_as_tvalid;
   tx_axis_tlast  <= tx_axis_as_tlast;
   tx_axis_as_tready <= tx_axis_tready;
   pat_gen_tready <= pat_gen_tready_int;

   -- basic packet generator - this has parametisable
   -- DA and SA fields but the LT and data will be auto-generated
   -- based on the min/max size parameters - these can be set
   -- to the same value to obtain a specific packet size or will
   -- increment from the lower packet size to the upper
   axi_pat_gen_inst : tri_mode_ethernet_mac_0_axi_pat_gen
   generic map (
      DEST_ADDR                 => DEST_ADDR,
      SRC_ADDR                  => SRC_ADDR,
      MAX_SIZE                  => MAX_SIZE,
      MIN_SIZE                  => MIN_SIZE,
      ENABLE_VLAN               => ENABLE_VLAN,
      VLAN_ID                   => VLAN_ID,
      VLAN_PRIORITY             => VLAN_PRIORITY
   )
   port map (
      axi_tclk                  => axi_tclk,
      axi_tresetn               => axi_tresetn,

      enable_pat_gen            => enable_pat_gen,
      speed                     => speed,

      tdata                     => pat_gen_tdata,
      tvalid                    => pat_gen_tvalid,
      tlast                     => pat_gen_tlast,
      tready                    => pat_gen_tready
   );

   axi_pat_check_inst: tri_mode_ethernet_mac_0_axi_pat_check
   generic map (
      DEST_ADDR                 => DEST_ADDR,
      SRC_ADDR                  => SRC_ADDR,
      MAX_SIZE                  => MAX_SIZE,
      MIN_SIZE                  => MIN_SIZE,
      ENABLE_VLAN               => ENABLE_VLAN,
      VLAN_ID                   => VLAN_ID,
      VLAN_PRIORITY             => VLAN_PRIORITY
   )
   port map (
      axi_tclk                  => axi_tclk,
      axi_tresetn               => check_resetn,

      enable_pat_chk            => enable_pat_chk,
      speed                     => speed,

      tdata                     => rx_axis_tdata,
      tvalid                    => rx_axis_tvalid,
      tlast                     => rx_axis_tlast,
   
      tready                    => rx_axis_tready_lcl,
      
      tuser                     => rx_axis_tuser,

      frame_error               => frame_error,
      activity_flash            => activity_flash
   );


   
   -- simple mux between the rx_fifo AXI interface and the pat gen output
   -- this is not registered as it is passed through a pipeline stage to limit the impact
   axi_mux_inst : tri_mode_ethernet_mac_0_axi_mux
   port map (
      mux_select                => enable_pat_gen,
      tdata0                    => rx_axis_tdata,
      tvalid0                   => rx_axis_tvalid,
      tlast0                    => rx_axis_tlast,
      tready0                   => rx_axis_tready_lcl,

      tdata1                    => pat_gen_tdata,
      tvalid1                   => pat_gen_tvalid,
      tlast1                    => pat_gen_tlast,
      tready1                   => pat_gen_tready_int,

      tdata                     => mux_tdata,
      tvalid                    => mux_tvalid,
      tlast                     => mux_tlast,
      tready                    => mux_tready
   );



   -- a pipeline stage has been added to reduce timing issues and allow
   -- a pattern generator to be muxed into the path
   axi_pipe_inst : tri_mode_ethernet_mac_0_axi_pipe
   port map (
      axi_tclk                  => axi_tclk,
      axi_tresetn               => axi_tresetn,

      rx_axis_fifo_tdata_in     => mux_tdata,
      rx_axis_fifo_tvalid_in    => mux_tvalid,
      rx_axis_fifo_tlast_in     => mux_tlast,
      rx_axis_fifo_tready_in    => mux_tready,

      rx_axis_fifo_tdata_out    => rx_axis_fifo_tdata_int,
      rx_axis_fifo_tvalid_out   => rx_axis_fifo_tvalid_int,
      rx_axis_fifo_tlast_out    => rx_axis_fifo_tlast_int,
      rx_axis_fifo_tready_out   => rx_axis_fifo_tready_int

   );

   -- address swap module: based around a Dual port distributed ram
   -- data is written in and the read only starts once the da/sa have been
   -- stored.  Can cope with a gap of one cycle between packets.
   address_swap_inst : tri_mode_ethernet_mac_0_address_swap
   port map (
      axi_tclk                  => axi_tclk,
      axi_tresetn               => axi_tresetn,

      enable_address_swap       => enable_address_swap,

      rx_axis_fifo_tdata        => rx_axis_fifo_tdata_int,
      rx_axis_fifo_tvalid       => rx_axis_fifo_tvalid_int,
      rx_axis_fifo_tlast        => rx_axis_fifo_tlast_int,
      rx_axis_fifo_tready       => rx_axis_fifo_tready_int,

      tx_axis_fifo_tdata        => tx_axis_as_tdata,
      tx_axis_fifo_tvalid       => tx_axis_as_tvalid,
      tx_axis_fifo_tlast        => tx_axis_as_tlast,
      tx_axis_fifo_tready       => tx_axis_as_tready
   );


end rtl;
