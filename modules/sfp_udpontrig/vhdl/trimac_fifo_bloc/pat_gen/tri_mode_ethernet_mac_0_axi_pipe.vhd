--------------------------------------------------------------------------------
-- File       : tri_mode_ethernet_mac_0_axi_pipe.vhd
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
-- Description:  A simple pipeline module to simplify the timing where a pattern
-- generator and address swap module can be muxed into the data path
--
--------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tri_mode_ethernet_mac_0_axi_pipe is
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
end tri_mode_ethernet_mac_0_axi_pipe;

architecture rtl of tri_mode_ethernet_mac_0_axi_pipe is

   signal rd_addr                      : unsigned(5 downto 0) := (others => '0');
   signal wr_addr                      : unsigned(5 downto 0) := (others => '0');
   signal wea                          : std_logic;
   signal rx_axis_fifo_tready_int      : std_logic;
   signal rx_axis_fifo_tvalid_int      : std_logic;
   signal rd_block                     : unsigned(1 downto 0) := (others => '0');
   signal wr_block                     : unsigned(1 downto 0) := (others => '0');

begin

rx_axis_fifo_tready_in  <= rx_axis_fifo_tready_int;
rx_axis_fifo_tvalid_out <= rx_axis_fifo_tvalid_int;

-- should always write when valid data is accepted
wr_enable : process (rx_axis_fifo_tvalid_in, rx_axis_fifo_tready_int)
begin
   wea <= rx_axis_fifo_tvalid_in and rx_axis_fifo_tready_int;
end process wr_enable;

-- simply increment the write address after any valid write
wr_addr_p : process (axi_tclk)
begin
   if axi_tclk'event and axi_tclk = '1' then
      if axi_tresetn = '0' then
         wr_addr <= (others => '0');
      elsif rx_axis_fifo_tvalid_in = '1' and rx_axis_fifo_tready_int = '1' then
         wr_addr <= wr_addr + 1;
      end if;
   end if;
end process wr_addr_p;

-- simply increment the read address after any validated read
rd_addr_p : process (axi_tclk)
begin
   if axi_tclk'event and axi_tclk = '1' then
      if axi_tresetn = '0' then
         rd_addr <= (others => '0');
      elsif rx_axis_fifo_tvalid_int = '1' and rx_axis_fifo_tready_out = '1' then
         rd_addr <= rd_addr + 1;
      end if;
   end if;
end process rd_addr_p;

wr_block <= wr_addr(5 downto 4);
rd_block <= rd_addr(5 downto 4) -1;


-- need to generate the ready output - this is entirely dependant upon the full state
-- of the fifo
tready_p : process (axi_tclk)
begin
   if axi_tclk'event and axi_tclk = '1' then
      if axi_tresetn = '0' then
         rx_axis_fifo_tready_int <= '0';
      else
         if wr_block = rd_block then
            rx_axis_fifo_tready_int <= '0';
         else
            rx_axis_fifo_tready_int <= '1';
         end if;
      end if;
   end if;
end process tready_p;

-- need to generate the valid output - this is entirely dependant upon the full state
-- of the fifo
tvalid_p : process (rd_addr, wr_addr)
begin
   if wr_addr = rd_addr then
      rx_axis_fifo_tvalid_int <= '0';
   else
      rx_axis_fifo_tvalid_int <= '1';
   end if;
end process tvalid_p;


LUT6_gen : for I in 0 to 7 generate
begin
   RAM64X1D_inst : RAM64X1D
   port map (
      DPO        => rx_axis_fifo_tdata_out(I),
      SPO        => open,
      A0         => wr_addr(0),
      A1         => wr_addr(1),
      A2         => wr_addr(2),
      A3         => wr_addr(3),
      A4         => wr_addr(4),
      A5         => wr_addr(5),
      D          => rx_axis_fifo_tdata_in(I),
      DPRA0      => rd_addr(0),
      DPRA1      => rd_addr(1),
      DPRA2      => rd_addr(2),
      DPRA3      => rd_addr(3),
      DPRA4      => rd_addr(4),
      DPRA5      => rd_addr(5),
      WCLK       => axi_tclk,
      WE         => wea
   );
end generate;

RAM64X1D_inst : RAM64X1D
port map (
   DPO        => rx_axis_fifo_tlast_out,
   SPO        => open,
   A0         => wr_addr(0),
   A1         => wr_addr(1),
   A2         => wr_addr(2),
   A3         => wr_addr(3),
   A4         => wr_addr(4),
   A5         => wr_addr(5),
   D          => rx_axis_fifo_tlast_in,
   DPRA0      => rd_addr(0),
   DPRA1      => rd_addr(1),
   DPRA2      => rd_addr(2),
   DPRA3      => rd_addr(3),
   DPRA4      => rd_addr(4),
   DPRA5      => rd_addr(5),
   WCLK       => axi_tclk,
   WE         => wea
);

end rtl;
