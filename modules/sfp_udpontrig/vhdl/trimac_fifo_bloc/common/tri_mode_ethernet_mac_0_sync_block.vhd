--------------------------------------------------------------------------------
-- Title      : CDC Sync Block
-- Project    : Tri-Mode Ethernet MAC
--------------------------------------------------------------------------------
-- File       : tri_mode_ethernet_mac_0_sync_block.vhd
-- Author     : Xilinx Inc.
--------------------------------------------------------------------------------
-- Description: Used on signals crossing from one clock domain to another, this
--              is a multiple flip-flop pipeline, with all flops placed together
--              into the same slice.  Thus the routing delay between the two is
--              minimum to safe-guard against metastability issues.
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


library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity tri_mode_ethernet_mac_0_sync_block is
  generic (
    INITIALISE : bit := '0';
    DEPTH      : integer := 5
  );
  port (
    clk         : in  std_logic;          -- clock to be sync'ed to
    data_in     : in  std_logic;          -- Data to be 'synced'
    data_out    : out std_logic           -- synced data
    );

  attribute dont_touch : string;
  attribute dont_touch    of  tri_mode_ethernet_mac_0_sync_block : entity is "yes";

end tri_mode_ethernet_mac_0_sync_block;


architecture structural of tri_mode_ethernet_mac_0_sync_block is


  -- Internal Signals
  signal data_sync0 : std_logic;
  signal data_sync1 : std_logic;
  signal data_sync2 : std_logic;
  signal data_sync3 : std_logic;
  signal data_sync4 : std_logic;

  -- These attributes will stop timing errors being reported in back annotated
  -- SDF simulation.
  attribute async_reg                   : string;
  attribute async_reg of data_sync_reg0 : label is "true";
  attribute async_reg of data_sync_reg1 : label is "true";
  attribute async_reg of data_sync_reg2 : label is "true";
  attribute async_reg of data_sync_reg3 : label is "true";
  attribute async_reg of data_sync_reg4 : label is "true";

  attribute shreg_extract                   : string;
  attribute shreg_extract of data_sync_reg0 : label is "no";
  attribute shreg_extract of data_sync_reg1 : label is "no";
  attribute shreg_extract of data_sync_reg2 : label is "no";
  attribute shreg_extract of data_sync_reg3 : label is "no";
  attribute shreg_extract of data_sync_reg4 : label is "no";


begin

  data_sync_reg0 : FDRE
  generic map (
    INIT => INITIALISE
  )
  port map (
    C    => clk,
    D    => data_in,
    Q    => data_sync0,
	CE   => '1',
    R    => '0'
  );


  data_sync_reg1 : FDRE
  generic map (
    INIT => INITIALISE
  )
  port map (
    C    => clk,
    D    => data_sync0,
    Q    => data_sync1,
	CE   => '1',
    R    => '0'
  );

  data_sync_reg2 : FDRE
  generic map (
    INIT => INITIALISE
  )
  port map (
    C    => clk,
    D    => data_sync1,
    Q    => data_sync2,
	CE   => '1',
    R    => '0'
  );

  data_sync_reg3 : FDRE
  generic map (
    INIT => INITIALISE
  )
  port map (
    C    => clk,
    D    => data_sync2,
    Q    => data_sync3,
	CE   => '1',
    R    => '0'
  );

  data_sync_reg4 : FDRE
  generic map (
    INIT => INITIALISE
  )
  port map (
    C    => clk,
    D    => data_sync3,
    Q    => data_sync4,
	CE   => '1',
    R    => '0'
  );

  data_out <= data_sync4;


end structural;


