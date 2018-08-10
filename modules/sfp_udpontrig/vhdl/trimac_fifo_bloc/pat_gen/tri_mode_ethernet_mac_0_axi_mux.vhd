--------------------------------------------------------------------------------
-- File       : tri_mode_ethernet_mac_0_axi_mux.v
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
-- Description:  A simple AXI-Streaming MUX
--
--------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;


entity tri_mode_ethernet_mac_0_axi_mux is
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

end tri_mode_ethernet_mac_0_axi_mux;

architecture rtl of tri_mode_ethernet_mac_0_axi_mux is

begin

   main_mux : process(mux_select, tdata0, tvalid0, tlast0, tdata1, 
                      tvalid1, tlast1)
   begin
      if mux_select = '1' then
         tdata    <= tdata1;
         tvalid   <= tvalid1;
         tlast    <= tlast1;
      else
         tdata    <= tdata0;
         tvalid   <= tvalid0;
         tlast    <= tlast0;
      end if;
   end process;

   split : process (mux_select, tready)
   begin
      if mux_select = '1' then
         tready0     <= '1';
      else
         tready0     <= tready;
      end if;
      tready1     <= tready;
   end process;

end rtl;
