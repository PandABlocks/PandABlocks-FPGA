--------------------------------------------------------------------------------
-- File       : tri_mode_ethernet_mac_0_address_swap.vhd
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
-- Description:  This address swap block will accept the first 12 byte of a packet before
-- starting to loop it out.  At this point both the source and destination fields have 
-- been completely captured and can therefore be swapped.
--
--------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tri_mode_ethernet_mac_0_address_swap is
   port (
    axi_tclk                        : in  std_logic;
    axi_tresetn                     : in  std_logic;
    
    -- address swap enable control
    enable_address_swap             : in  std_logic;
    
    -- data from the RX FIFO
    rx_axis_fifo_tdata              : in  std_logic_vector(7 downto 0);
    rx_axis_fifo_tvalid             : in  std_logic;
    rx_axis_fifo_tlast              : in  std_logic;
    rx_axis_fifo_tready             : out std_logic;
    -- data TO the tx fifo
    tx_axis_fifo_tdata              : out std_logic_vector(7 downto 0) := (others => '0');
    tx_axis_fifo_tvalid             : out std_logic;
    tx_axis_fifo_tlast              : out std_logic;
    tx_axis_fifo_tready             : in std_logic                                
    
  );
end tri_mode_ethernet_mac_0_address_swap;
 
architecture rtl of tri_mode_ethernet_mac_0_address_swap is
 
   -- State machine
   type rd_state_typ is    (IDLE,      
                            WAIT_S,      
                            READ_DEST, 
                            READ_SRC,  
                            READ_DEST2,
                            READ_SRC2, 
                            READ);      


   type wr_state_typ is    (IDLE_W,      
                            WRITE_SLOT1,
                            WRITE_SLOT2,
                            WRITE);
                                       
   signal next_rd_state             : rd_state_typ;
   signal rd_state                  : rd_state_typ;
   signal next_wr_state             : wr_state_typ;
   signal wr_state                  : wr_state_typ;

   signal rx_axis_fifo_tvalid_reg   : std_logic;
   signal rx_axis_fifo_tlast_reg    : std_logic;
   signal wr_count                  : unsigned(3 downto 0) := (others => '0');
   signal fifo_full                 : std_logic;

   signal wr_slot                   : unsigned(2 downto 0) := (others => '0');
   signal wr_addr                   : unsigned(2 downto 0) := (others => '0');
   signal dia                       : std_logic_vector(8 downto 0);
   signal doa                       : std_logic_vector(8 downto 0);
   signal wea                       : std_logic;

   signal rd_count                  : unsigned(3 downto 0) := (others => '0');
   signal fifo_empty                : std_logic;

   signal rd_slot                   : unsigned(2 downto 0) := (others => '0');
   signal rd_addr                   : unsigned(2 downto 0) := (others => '0');
   signal dob                       : std_logic_vector(8 downto 0);
   signal tx_axis_fifo_tvalid_int   : std_logic;
   signal tx_axis_fifo_tlast_int    : std_logic;
   signal rx_axis_fifo_tready_int   : std_logic;

   signal axi_treset                : std_logic;
   
   signal new_packet_start          : std_logic;
   signal rd_count_6                : std_logic;
   signal rd_count_12               : std_logic;
   signal slot_diff                 : unsigned(2 downto 0) := (others => '0');
   signal packet_waiting            : std_logic;
   signal address_swap              : std_logic := '0';


begin

   rx_axis_fifo_tready <= rx_axis_fifo_tready_int;
   axi_treset <= not axi_tresetn;

   -- capture a new packet starting as we only want to start taking it once the read side is idle
   new_pkt_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if axi_treset = '1' then
            new_packet_start <= '0';
         elsif wr_state = IDLE_W and packet_waiting = '0' and rx_axis_fifo_tvalid = '1' and 
               (rx_axis_fifo_tvalid_reg = '0' or rx_axis_fifo_tlast_reg = '1') then
            new_packet_start <= '1';
         elsif  wr_state /= IDLE_W then
            new_packet_start <= '0';
         end if;
      end if;
   end process new_pkt_p;

   -- need to monitor the RX FIFO AXI interface and when a new transaction starts capture the first
   -- 6 bytes of the frame.  Use a LUT6 to capture the data - allows some backoff to take place
   -- need to maintain a read an write interface..

   -- Write interface
   reg_axi_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         rx_axis_fifo_tvalid_reg <= rx_axis_fifo_tvalid;
         rx_axis_fifo_tlast_reg <= rx_axis_fifo_tlast;
      end if;
   end process reg_axi_p;

   -- simple write state machine
   next_wr_s : process(wr_state, rx_axis_fifo_tvalid,  wr_count, rx_axis_fifo_tlast, 
                        new_packet_start, rd_state)
   begin
      next_wr_state <= wr_state;
      case wr_state is
         -- detect a rising edge on TVALID OR TLAST on previous cycle AND TVALID
         when IDLE_W =>
            if rd_state = IDLE and new_packet_start = '1' then
               next_wr_state <= WRITE_SLOT1;
            end if;
         -- finish writing when tlast is high
         when WRITE_SLOT1 =>
            if wr_count = X"6" and rx_axis_fifo_tvalid = '1' then
               next_wr_state <= WRITE_SLOT2;
            elsif rx_axis_fifo_tlast = '1' and rx_axis_fifo_tvalid = '1' then
               next_wr_state <= IDLE_W;
            end if;
         when WRITE_SLOT2 =>
            if wr_count = X"c" and rx_axis_fifo_tvalid = '1' then
               next_wr_state <= WRITE;
            elsif rx_axis_fifo_tlast = '1' and rx_axis_fifo_tvalid = '1' then
               next_wr_state <= IDLE_W;
            end if;
         when WRITE =>
            if rx_axis_fifo_tlast = '1' and rx_axis_fifo_tvalid = '1' then
               next_wr_state <= IDLE_W;
            end if;
      end case;
   end process;

   wr_state_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if axi_treset = '1' then
            wr_state <= IDLE_W;
         elsif fifo_full = '0' then
            wr_state <= next_wr_state;
         end if;
      end if;
   end process wr_state_p;

   packet_wait_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if axi_treset = '1' then
            packet_waiting <= '0';
         elsif wr_state = IDLE_W and next_wr_state = WRITE_SLOT1 then
            packet_waiting <= '1';
         elsif rd_state /= IDLE then
            packet_waiting <= '0';
         end if;
      end if;
   end process packet_wait_p;

   -- generate a write count to control where the data is written
   wr_count_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if axi_treset = '1' then
            wr_count <= (others => '0');
         else 
            if wr_state = IDLE_W and next_wr_state = WRITE_SLOT1 then
               wr_count <= X"1";
            elsif wr_state /= IDLE_W and rx_axis_fifo_tvalid = '1' and fifo_full = '0' and wr_count /= x"f" then
               wr_count <= wr_count + X"1";
            end if;
         end if;
      end if;
   end process wr_count_p;

   -- we have a 64 deep lut - to simplify storing/fetching of data this is split into 8 address slots.  When 
   -- a new packet starts the first byte of the address is stored in the next available address slot, with the next address being 
   -- stored in the next slot (i.e after a gap of two locations).  Once the addresses have been stored the data starts 
   -- at the next slot and then continues until completion.
   wr_slot_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if axi_treset = '1' then
            wr_slot <= (others => '0');
            wr_addr <= (others => '0'); 
         elsif wr_state = IDLE_W and next_wr_state = WRITE_SLOT1 then
            wr_slot <= "000";
            wr_addr <= (others => '0'); 
         elsif wr_state = WRITE_SLOT1 and next_wr_state = WRITE_SLOT2 then
            wr_slot <= "001";
            wr_addr <= (others => '0'); 
         elsif wr_state = WRITE_SLOT2 and next_wr_state = WRITE then
            wr_slot <= "010";
            wr_addr <= (others => '0'); 
         elsif rx_axis_fifo_tready_int = '1' and rx_axis_fifo_tvalid = '1' and fifo_full = '0' then
            wr_addr <= wr_addr + "001";
            if wr_addr = "111" then
               wr_slot <= wr_slot + "001";
            end if;
         end if;
      end if;
   end process wr_slot_p;

   slot_diff <= rd_slot - wr_slot;

   -- need to generate full logic to generate the ready - simplified by there only being
   -- one clock domain..
   -- to allow for reaction time generate as full when we are only one slot away
   fifo_full_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if (slot_diff = "010" or slot_diff = "001") and wr_state = WRITE then
            fifo_full <= '1';
         else
            fifo_full <= '0';
         end if;
      end if;
   end process fifo_full_p;

   rx_axis_fifo_tready_int <= '1' when fifo_full = '0' and wr_state /= IDLE_W else '0';


   dia <= rx_axis_fifo_tlast & rx_axis_fifo_tdata;
   wea <= '1' when rx_axis_fifo_tready_int = '1' else '0';

   LUT6_gen : for I in 0 to 8 generate
   begin
      RAM64X1D_inst : RAM64X1D
      port map (
         DPO        => dob(I), 
         SPO        => doa(I), 
         A0         => wr_addr(0),
         A1         => wr_addr(1),
         A2         => wr_addr(2),
         A3         => wr_slot(0),
         A4         => wr_slot(1),
         A5         => wr_slot(2),
         D          => dia(I), 
         DPRA0      => rd_addr(0),
         DPRA1      => rd_addr(1),
         DPRA2      => rd_addr(2),
         DPRA3      => rd_slot(0),
         DPRA4      => rd_slot(1),
         DPRA5      => rd_slot(2),
         WCLK       => axi_tclk,
         WE         => wea
      );
   end generate;

   -- read logic - this is kicked into action when the wr_state moves from IDLE but will not start to read until
   -- the wr_state moves to WRITE as the two addresses are then in situ
   -- can then choose if we wish to addess swap or not - if a small packet is rxd which is less than the required 12 bytes
   -- the read logic will revert to non address swap and just output what is there..

   next_rd_s : process(rd_state, enable_address_swap, rd_count_6, rd_count_12, tx_axis_fifo_tready, dob, 
                       wr_state, tx_axis_fifo_tvalid_int)
   begin
      next_rd_state <= rd_state;
      case rd_state is
         when IDLE =>
            if wr_state /= IDLE_W then
               next_rd_state <= WAIT_S;
            end if;
         when WAIT_S =>
            if wr_state = IDLE_W then
               next_rd_state <= READ_DEST2;
            elsif wr_state = WRITE then
               if enable_address_swap = '1' then
                  next_rd_state <= READ_SRC;
               else
                  next_rd_state <= READ_DEST2;
               end if;
            end if;
         when READ_SRC =>
            if rd_count_6 = '1' and tx_axis_fifo_tready = '1' and tx_axis_fifo_tvalid_int = '1' then
               next_rd_state <= READ_DEST;
            end if;
         when READ_DEST =>
            if rd_count_12 = '1' and tx_axis_fifo_tready = '1' and tx_axis_fifo_tvalid_int = '1' then
               next_rd_state <= READ;
            end if;
         when READ_DEST2 =>
            if rd_count_6 = '1' and tx_axis_fifo_tready = '1' and tx_axis_fifo_tvalid_int = '1' then
               next_rd_state <= READ_SRC2;
            end if;
         when READ_SRC2 =>
            if rd_count_12 = '1' and tx_axis_fifo_tready = '1' and tx_axis_fifo_tvalid_int = '1' then
               next_rd_state <= READ;
            end if;
         when READ =>
            if dob(8) = '1' and tx_axis_fifo_tready = '1' and tx_axis_fifo_tvalid_int = '1' then
               next_rd_state <= IDLE;
            end if;
         when others =>
            next_rd_state <= IDLE;
      end case;
   end process;

   rd_state_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if axi_treset = '1' then
            rd_state <= IDLE;
         else
            rd_state <= next_rd_state;
         end if;
      end if;
   end process rd_state_p;

   -- generate a read count to control where the data is read
   rd_count_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if axi_treset = '1' then
            rd_count <= (others => '0');
            rd_count_6 <= '0';
            rd_count_12 <= '0';
         else 
            if rd_state = WAIT_S then
               rd_count <= X"1";
            elsif rd_state /= IDLE and tx_axis_fifo_tvalid_int = '1' and 
                  tx_axis_fifo_tready = '1' and rd_count /= X"f" then
               rd_count <= rd_count + X"1";
               if rd_count = X"5" then
                  rd_count_6 <= '1';
               else
                  rd_count_6 <= '0';
               end if;
               if rd_count = X"b" then
                  rd_count_12 <= '1';
               else
                  rd_count_12 <= '0';
               end if;
            end if;
         end if;
      end if;
   end process rd_count_p;

   -- sample the address swap enable to make sure it doesn't change through out the frame
   active_swap_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if rd_state = IDLE then
            address_swap    <= enable_address_swap;
         end if;
      end if;
   end process active_swap_p;

   -- we have a 64 deep lut - to simplify storing/fetching of data this is split into 8 address slots.  When 
   -- a new packet starts the first byte of the address is stored in the next available address slot, with the next address being 
   -- stored in the next slot (i.e after a gap of two locations).  Once the addresses have been stored the data starts 
   -- at the next slot and then continues until completion.
   rd_slot_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if axi_treset = '1' then
            rd_slot <= (others => '0');
         elsif rd_state = WAIT_S and address_swap = '0' then
            rd_slot <= "000";
         elsif rd_state = WAIT_S and address_swap = '1' then
            rd_slot <= "001";
         elsif rd_count_6 = '1' and tx_axis_fifo_tready = '1' and tx_axis_fifo_tvalid_int = '1' and address_swap = '0' then
            rd_slot <= "001";
         elsif rd_count_6 = '1' and tx_axis_fifo_tready = '1' and tx_axis_fifo_tvalid_int = '1' and address_swap = '1' then
            rd_slot <= "000";
         elsif rd_count_12 = '1' and tx_axis_fifo_tready = '1' and tx_axis_fifo_tvalid_int = '1' then
            rd_slot <= "010";  
         elsif tx_axis_fifo_tvalid_int = '1' and tx_axis_fifo_tready = '1' then
            if rd_addr = "111" then
               rd_slot <= rd_slot + "001";
            end if;
         end if;
      end if;
   end process rd_slot_p;

   rd_addr_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if axi_treset = '1' then
            rd_addr <= (others => '0'); 
         elsif rd_state = WAIT_S then
            rd_addr <= (others => '0'); 
         elsif tx_axis_fifo_tvalid_int = '1' and tx_axis_fifo_tready = '1' then
            if rd_count_6 = '1' or rd_count_12 = '1' then
               rd_addr <= (others => '0'); 
            else
               rd_addr <= rd_addr + "001";
            end if;
         end if;
      end if;
   end process rd_addr_p;

   -- need to generate empty to generate the tvalid for the tx_fifo interface - the empty is purely a compare of the 
   -- rd/wr access point - if the same and TLAST (dob[8]) is low then must still be in packet so drop tvalid - and stall read
   empty_p : process (wr_slot, wr_addr, rd_slot, rd_addr)
   begin
      if wr_slot = rd_slot and wr_addr = rd_addr then
         fifo_empty <= '1';
      else
         fifo_empty <= '0';
      end if;
   end process;

   -- generate the tvalid 
   valid_p : process (rd_state, fifo_empty, tx_axis_fifo_tready, dob)
   begin
      if rd_state = IDLE then
         tx_axis_fifo_tvalid_int <= '0';
      elsif rd_state /= WAIT_S then
         if fifo_empty = '1' and tx_axis_fifo_tready = '1' and dob(8) = '0' then
            tx_axis_fifo_tvalid_int <= '0';
         else
            tx_axis_fifo_tvalid_int <= '1';
         end if;
      else
         tx_axis_fifo_tvalid_int <= '0';
      end if;
   end process;

   -- and the output data/tlast
   rd_data_p : process (axi_tclk)
   begin
      if axi_tclk'event and axi_tclk = '1' then
         if tx_axis_fifo_tready = '1' then
            if fifo_empty = '0' then
               tx_axis_fifo_tdata <= dob(7 downto 0);
            end if;
            tx_axis_fifo_tvalid <= tx_axis_fifo_tvalid_int;
            tx_axis_fifo_tlast_int <= dob(8);
         end if;
      end if;
   end process rd_data_p;

   tx_axis_fifo_tlast <= tx_axis_fifo_tlast_int;
   
end rtl;






