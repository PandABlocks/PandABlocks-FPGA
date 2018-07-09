--------------------------------------------------------------------------------
-- File       : tri_mode_ethernet_mac_0_example_design_clocks.vhd
-- Author     : Xilinx Inc.
-- -----------------------------------------------------------------------------
-- (c) Copyright 2012 Xilinx, Inc. All rights reserved.
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
-- Description:  This block generates the clocking logic required for the
--               example design.

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity tri_mode_ethernet_mac_0_example_design_clocks is
   port (
   -- clocks
   clk_in_p                   : in std_logic;
   clk_in_n                   : in std_logic;

   -- asynchronous resets
   glbl_rst                   : in std_logic;
   dcm_locked                 : out std_logic;

   -- clock outputs
   gtx_clk_bufg               : out std_logic;
   refclk_bufg                : out std_logic;
   s_axi_aclk                 : out std_logic
   );
end tri_mode_ethernet_mac_0_example_design_clocks;

architecture RTL of tri_mode_ethernet_mac_0_example_design_clocks is

  ------------------------------------------------------------------------------
  -- Component declaration for the clock generator
  ------------------------------------------------------------------------------
  component tri_mode_ethernet_mac_0_clk_wiz
  port
   ( -- Clock in ports
     CLK_IN1                    : in     std_logic;
     -- Clock out ports
     CLK_OUT1                   : out    std_logic;
     CLK_OUT2                   : out    std_logic;
     CLK_OUT3                   : out    std_logic;
     -- Status and control signals
     RESET                      : in     std_logic;
     LOCKED                     : out    std_logic
   );
  end component;

  ------------------------------------------------------------------------------
  -- Component declaration for the reset synchroniser
  ------------------------------------------------------------------------------
  component tri_mode_ethernet_mac_0_reset_sync
  port (
    clk                    : in  std_logic;    -- clock to be sync'ed to
    enable                 : in  std_logic;
    reset_in               : in  std_logic;    -- Active high asynchronous reset
    reset_out              : out std_logic     -- "Synchronised" reset signal
    );
  end component;

  ------------------------------------------------------------------------------
  -- Component declaration for the synchroniser
  ------------------------------------------------------------------------------
  component tri_mode_ethernet_mac_0_sync_block
  port (
     clk                        : in  std_logic;
     data_in                    : in  std_logic;
     data_out                   : out std_logic
  );
  end component;

  signal clkin1            : std_logic;
  signal clkin1_bufg       : std_logic;
  signal mmcm_rst          : std_logic;
  signal dcm_locked_int    : std_logic;
  signal dcm_locked_sync   : std_logic;
  signal dcm_locked_reg    : std_logic := '1';
  signal dcm_locked_edge   : std_logic := '1';
  signal mmcm_reset_in     : std_logic;


  

begin

  -- Input buffering
  --------------------------------------
  clkin1_buf : IBUFDS
  port map
   (O  => clkin1,
    I  => clk_in_p,
    IB => clk_in_n);

   -- route clkin1 through a BUFGCE for the MMCM reset generation logic
   bufg_clkin1 : BUFGCE port map (I => clkin1, CE  => '1', O => clkin1_bufg);

   -- detect a falling edge on dcm_locked (after resyncing to this domain)
   lock_sync : tri_mode_ethernet_mac_0_sync_block
   port map (
      clk              => clkin1_bufg,
      data_in          => dcm_locked_int,
      data_out         => dcm_locked_sync
   );

   -- for the falling edge detect we want to force this at power on so init the flop to 1
   dcm_lock_detect_p : process(clkin1_bufg)
   begin
     if clkin1_bufg'event and clkin1_bufg = '1' then
       dcm_locked_reg  <= dcm_locked_sync;
       dcm_locked_edge <= dcm_locked_reg  and not dcm_locked_sync;
     end if;
   end process dcm_lock_detect_p;

   mmcm_reset_in <= glbl_rst or dcm_locked_edge;

   -- the MMCM reset should be at least 5ns - that is one cycle of the input clock -
   -- since the source of the input reset is unknown (a push switch in board design)
   -- this needs to be debounced
   mmcm_reset_gen : tri_mode_ethernet_mac_0_reset_sync
   port map (
      clk               => clkin1_bufg,
      enable            => '1',
      reset_in          => mmcm_reset_in,
      reset_out         => mmcm_rst
   );

   ------------------------------------------------------------------------------
   -- Clock logic to generate required clocks from the 200MHz on board
   -- if 125MHz is available directly this can be removed
   ------------------------------------------------------------------------------
   clock_generator : tri_mode_ethernet_mac_0_clk_wiz
   port map (
      -- Clock in ports
      CLK_IN1           => clkin1,
      -- Clock out ports
      CLK_OUT1          => gtx_clk_bufg,
      CLK_OUT2          => s_axi_aclk,
      CLK_OUT3          => refclk_bufg,
      -- Status and control signals
      RESET             => mmcm_rst,
      LOCKED            => dcm_locked_int
   );

   dcm_locked <= dcm_locked_int;

  

end RTL;
