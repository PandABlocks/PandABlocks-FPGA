--------------------------------------------------------------------------------
-- File       : tri_mode_ethernet_mac_0_example_design_resets.vhd
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
-- Description:  This block generates fully synchronous resets for each clock domain

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tri_mode_ethernet_mac_0_example_design_resets is
   port (
   -- clocks
   s_axi_aclk                 : in std_logic;
   gtx_clk                    : in std_logic;

   -- asynchronous resets
   glbl_rst                   : in std_logic;
   reset_error                : in std_logic;
   rx_reset                   : in std_logic;
   tx_reset                   : in std_logic;

   dcm_locked                 : in std_logic;

   -- synchronous reset outputs
 
   glbl_rst_intn              : out std_logic;
   
   gtx_resetn                 : out std_logic := '0';
   vector_resetn              : out std_logic := '0';
   phy_resetn                 : out std_logic;
   chk_resetn                 : out std_logic := '0'
   );
end tri_mode_ethernet_mac_0_example_design_resets;

architecture RTL of tri_mode_ethernet_mac_0_example_design_resets is

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


-- define internal signals
    signal vector_pre_resetn  : std_logic := '0';
    signal vector_reset_int   : std_logic;
    signal combined_reset     : std_logic;
    signal gtx_pre_resetn     : std_logic := '0';
    signal gtx_clk_reset_int  : std_logic;
    signal clear_checker      : std_logic;
    signal chk_pre_resetn     : std_logic := '0';
    signal chk_reset_int      : std_logic;
    signal dcm_locked_sync    : std_logic;
    signal glbl_rst_int       : std_logic;
    signal phy_resetn_int     : std_logic;
    signal phy_reset_count    : unsigned(5 downto 0) := (others => '0');

begin

  ------------------------------------------------------------------------------
  -- Synchronise the async dcm_locked into the gtx_clk clock domain
  ------------------------------------------------------------------------------
   dcm_sync : tri_mode_ethernet_mac_0_sync_block
   port map (
      clk              => gtx_clk,
      data_in          => dcm_locked,
      data_out         => dcm_locked_sync
   );

  ------------------------------------------------------------------------------
  -- Generate resets required for the fifo side signals etc
  ------------------------------------------------------------------------------
  -- in each case the async reset is first captured and then synchronised

   -----------------
   -- global reset
   glbl_reset_gen : tri_mode_ethernet_mac_0_reset_sync
   port map (
      clk               => gtx_clk,
      enable            => dcm_locked_sync,
      reset_in          => glbl_rst,
      reset_out         => glbl_rst_int
   );

   glbl_rst_intn <= not glbl_rst_int;


  -----------------
  -- Vector controller reset
    vector_reset_gen : tri_mode_ethernet_mac_0_reset_sync
    port map (
      clk              => gtx_clk,
      enable           => dcm_locked_sync,
      reset_in         => glbl_rst,
      reset_out        => vector_reset_int
   );

   -- Create fully synchronous reset in the global clock domain.
   vector_reset_p : process(gtx_clk)
   begin
     if gtx_clk'event and gtx_clk = '1' then
       if vector_reset_int = '1' then
         vector_pre_resetn <= '0';
         vector_resetn     <= '0';
       else
         vector_pre_resetn <= '1';
         vector_resetn     <= vector_pre_resetn;
       end if;
     end if;
   end process vector_reset_p;

  -----------------
  -- gtx_clk reset
    combined_reset <= glbl_rst or rx_reset or tx_reset;

    gtx_reset_gen : tri_mode_ethernet_mac_0_reset_sync
    port map (
      clk              => gtx_clk,
      enable           => dcm_locked_sync,
      reset_in         => combined_reset,
      reset_out        => gtx_clk_reset_int
   );

   -- Create fully synchronous reset in the gtx_clk domain.
   gtx_reset_p : process(gtx_clk)
   begin
     if gtx_clk'event and gtx_clk = '1' then
       if gtx_clk_reset_int = '1' then
         gtx_pre_resetn <= '0';
         gtx_resetn     <= '0';
       else
         gtx_pre_resetn <= '1';
         gtx_resetn     <= gtx_pre_resetn;
       end if;
     end if;
   end process gtx_reset_p;

  -----------------
  -- data check reset
    clear_checker <= glbl_rst or reset_error;

    chk_reset_gen : tri_mode_ethernet_mac_0_reset_sync
    port map (
      clk              => gtx_clk,
      enable           => dcm_locked_sync,
      reset_in         => clear_checker,
      reset_out        => chk_reset_int
   );

   -- Create fully synchronous reset in the gtx_clk domain.
   chk_reset_p : process(gtx_clk)
   begin
     if gtx_clk'event and gtx_clk = '1' then
       if chk_reset_int = '1' then
         chk_pre_resetn <= '0';
         chk_resetn     <= '0';
       else
         chk_pre_resetn <= '1';
         chk_resetn     <= chk_pre_resetn;
       end if;
     end if;
   end process chk_reset_p;


   -----------------
   -- PHY reset
   -- the phy reset output (active low) needs to be held for at least 10x25MHZ cycles
   -- this is derived using the 125MHz available and a 6 bit counter
   phy_reset_p : process(gtx_clk)
   begin
     if gtx_clk'event and gtx_clk = '1' then
       if glbl_rst_int = '1' then
         phy_resetn_int  <= '0';
         phy_reset_count <= (others => '0');
       else
         if phy_reset_count /= "111111" then
            phy_reset_count <= phy_reset_count + "000001";
         else
            phy_resetn_int <= '1';
         end if;
       end if;
     end if;
   end process phy_reset_p;

   phy_resetn <= phy_resetn_int;

end RTL;
