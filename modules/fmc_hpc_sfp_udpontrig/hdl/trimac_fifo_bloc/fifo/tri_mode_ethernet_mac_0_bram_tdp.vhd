--------------------------------------------------------------------------------
-- Title      : RAM memory for RX and TX client FIFOs
-- Version    : 1.0
-- Project    : Tri-Mode Ethernet MAC
--------------------------------------------------------------------------------
-- File       : tri_mode_ethernet_mac_0_bram_tdp.vhd
-- Author     : Xilinx Inc.
-- -----------------------------------------------------------------------------
-- (c) Copyright 2013 Xilinx, Inc. All rights reserved.
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
-- Description: This is a parameterized inferred block RAM
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------------------------------------------
-- The entity declaration for the block RAM
--------------------------------------------------------------------------------


entity tri_mode_ethernet_mac_0_bram_tdp is
generic (
    DATA_WIDTH    : integer := 8;
    ADDR_WIDTH    : integer := 12
);
port (
    -- Port A
    a_clk   : in  std_logic;
    a_rst   : in  std_logic;
    a_wr    : in  std_logic;
    a_addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    a_din   : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Port B
    b_clk   : in  std_logic;
    b_en    : in  std_logic;
    b_rst   : in  std_logic;
    b_addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    b_dout  : out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end tri_mode_ethernet_mac_0_bram_tdp;

architecture rtl of tri_mode_ethernet_mac_0_bram_tdp is
    -- Shared memory
    constant RAM_DEPTH : integer := 2 ** ADDR_WIDTH;
    type mem_type is array ( RAM_DEPTH-1 downto 0 ) of std_logic_vector(DATA_WIDTH-1 downto 0);
    shared variable mem : mem_type;
begin

-- To write use port A
process(a_clk)
begin
    if(a_clk'event and a_clk='1') then
        if(a_rst='0' and a_wr='1') then
            mem(conv_integer(a_addr)) := a_din;
        end if;
    end if;
end process;

-- To read use Port B
process(b_clk)
begin
    if(b_clk'event and b_clk='1') then
        if (b_rst='1') then
        b_dout <= (others => '0');
        elsif (b_en='1') then
        b_dout <= mem(conv_integer(b_addr));
        end if;
    end if;
end process;

end rtl;

