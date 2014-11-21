--
-- GENERAL DESCRIPTION:
--
-- AXI3 slave used also for simple bus master.
--
--
--                     /------\
--   WR ADDRESS  ----> |  WR  |
--   WR DATA     ----> |      | -----------
--   WR RESPONSE <---- |  CH  |            |
--                     \------/       /--------\
--                                    | SIMPLE | ---> WR/RD ADDRRESS
--   AXI                              |        | ---> WR DATA
--                                    |   RP   | <--- RD DATA
--                                    |  BUS   | <--- ACKNOWLEDGE
--                     /------\       \--------/
--   RD ADDRESS  ----> |  RD  |            |
--   RD DATA     <---- |  CH  | -----------
--                     \------/
--
--
-- Because AXI bus is quite complex simplier bus was created.
--
-- It combines write and read channel; where write has bigger priority. Command
-- is then send forward to red pitaya bus. When wite or read acknowledge is
-- received AXI response is created and new AXI is accepted.
--
-- To prevent AXI lockups because no response is received; this slave creates its
-- own after 32 cycles (ack_cnt).
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi3_slave is
generic (
    AXI_DW      : natural := 64;        -- Data width
    AXI_AW      : natural := 32;        -- Address width
    AXI_IW      : natural := 8;         -- ID width
    AXI_SW      : natural := AXI_DW/8   -- Strobe width
);
port (
    -- AXI3 Global Signals
    axi_clk_i       : in  std_logic; -- AXI global clock
    axi_rstn_i      : in  std_logic; -- AXI global reset

    -- AXI3 Write address channel
    axi_awid_i      : in  std_logic_vector(AXI_IW-1 downto 0); -- AXI write address ID
    axi_awaddr_i    : in  std_logic_vector(AXI_AW-1 downto 0); -- AXI write address
    axi_awlen_i     : in  std_logic_vector(3 downto 0);  -- AXI write burst length
    axi_awsize_i    : in  std_logic_vector(2 downto 0);  -- AXI write burst size
    axi_awburst_i   : in  std_logic_vector(1 downto 0);  -- AXI write burst type
    axi_awlock_i    : in  std_logic_vector(1 downto 0);  -- AXI write lock type
    axi_awcache_i   : in  std_logic_vector(3 downto 0);  -- AXI write cache type
    axi_awprot_i    : in  std_logic_vector(2 downto 0);  -- AXI write protection type
    axi_awvalid_i   : in  std_logic;                     -- AXI write address valid
    axi_awready_o   : out std_logic;                     -- AXI write ready

    -- AXI3 Write data channel
    axi_wid_i       : in  std_logic_vector(AXI_IW-1 downto 0); -- AXI write data ID
    axi_wdata_i     : in  std_logic_vector(AXI_DW-1 downto 0); -- AXI write data
    axi_wstrb_i     : in  std_logic_vector(AXI_SW-1 downto 0); -- AXI write strobes
    axi_wlast_i     : in  std_logic;                            -- AXI write last
    axi_wvalid_i    : in  std_logic;                            -- AXI write valid
    axi_wready_o    : out std_logic;                            -- AXI write ready

    -- AXI3 Write response channel
    axi_bid_o       : out std_logic_vector(AXI_IW-1 downto 0);  -- AXI write response ID
    axi_bresp_o     : out std_logic_vector(1 downto 0);  -- AXI write response
    axi_bvalid_o    : out std_logic;  -- AXI write response valid
    axi_bready_i    : in  std_logic;  -- AXI write response ready

    -- AXI3 Read address channel
    axi_arid_i      : in  std_logic_vector(AXI_IW-1 downto 0);  -- AXI read address ID
    axi_araddr_i    : in  std_logic_vector(AXI_AW-1 downto 0);  -- AXI read address
    axi_arlen_i     : in  std_logic_vector(3 downto 0);  -- AXI read burst length
    axi_arsize_i    : in  std_logic_vector(2 downto 0);  -- AXI read burst size
    axi_arburst_i   : in  std_logic_vector(1 downto 0);  -- AXI read burst type
    axi_arlock_i    : in  std_logic_vector(1 downto 0);  -- AXI read lock type
    axi_arcache_i   : in  std_logic_vector(3 downto 0);  -- AXI read cache type
    axi_arprot_i    : in  std_logic_vector(2 downto 0);  -- AXI read protection type
    axi_arvalid_i   : in  std_logic;  -- AXI read address valid
    axi_arready_o   : out std_logic;  -- AXI read address ready

    -- AXI3 read data channel
    axi_rid_o       : out std_logic_vector(AXI_IW-1 downto 0);  -- AXI read response ID
    axi_rdata_o     : out std_logic_vector(AXI_DW-1 downto 0);  -- AXI read data
    axi_rresp_o     : out std_logic_vector(1 downto 0);  -- AXI read response
    axi_rlast_o     : out std_logic;  -- AXI read last
    axi_rvalid_o    : out std_logic;  -- AXI read response valid
    axi_rready_i    : in  std_logic;  -- AXI read response ready
    -- System Bus Read/Write Channel
    sys_addr_o      : out std_logic_vector(AXI_AW-1 downto 0) -- system bus read/write address.
    sys_wdata_o     : out std_logic_vector(AXI_DW-1 downto 0) -- system bus write data.
    sys_sel_o       : out std_logic_vector(AXI_SW-1 downto 0) -- system bus write byte select.
    sys_wen_o       : out std_logic_vector;                   -- system bus write enable.
    sys_ren_o       : out std_logic_vector;                   -- system bus read enable.
    sys_rdata_i     : out std_logic_vector(AXI_DW-1 downto 0) -- system bus read data.
    sys_err_i       : in  std_logic;                    -- system bus error indicator.
    sys_ack_i       : in  std_logic                     -- system bus acknowledge signal.
);

architecture rtl of axi3_slave is

signal ack          : std_logic;
signal ack_cnt      : std_logic_vector(5 downto 0);

signal rd_do        : std_logic;
signal rd_arid      : std_logic_vector(AXI_IW-1 downto 0);
signal rd_araddr    : std_logic_vector(AXI_AW-1 downto 0);
signal rd_error     : std_logic;
signal rd_errorw    : std_logic;

signal wr_do        : std_logic;
signal wr_awid      : std_logic_vector(AXI_IW-1 downto 0);
signal wr_awaddr    : std_logic_vector(AXI_AW-1 downto 0);
signal wr_wid       : std_logic_vector(AXI_IW-1 downto 0);
signal wr_wdata     : std_logic_vector(AXI_DW-1 downto 0);
signal wr_error     : std_logic;
signal wr_errorw    : std_logic;

begin

assign wr_errorw = (axi_awlen_i != 4'h0) || (axi_awsize_i != 3'b010); -- error if write burst and more/less than 4B transfer
assign rd_errorw = (axi_arlen_i != 4'h0) || (axi_arsize_i != 3'b010); -- error if read burst and more/less than 4B transfer

process(axi_clk_i) begin
   if (axi_rstn_i == 1'b0) begin
      rd_do    <= 1'b0 ;
      rd_error <= 1'b0 ;
   end
   else begin
      if (axi_arvalid_i && !rd_do && !axi_awvalid_i && !wr_do) -- accept just one read request - write has priority
         rd_do  <= 1'b1 ;
      else if (axi_rready_i && rd_do && ack)
         rd_do  <= 1'b0 ;

      if (axi_arvalid_i && axi_arready_o) begin -- latch ID and address
         rd_arid   <= axi_arid_i   ;
         rd_araddr <= axi_araddr_i ;
         rd_error  <= rd_errorw    ;
      end
   end
end


process(axi_clk_i) begin
   if (axi_rstn_i == 1'b0) begin
      wr_do    <= 1'b0 ;
      wr_error <= 1'b0 ;
   end
   else begin
      if (axi_awvalid_i && !wr_do && !rd_do) -- accept just one write request - if idle
         wr_do  <= 1'b1 ;
      else if (axi_bready_i && wr_do && ack)
         wr_do  <= 1'b0 ;

      if (axi_awvalid_i && axi_awready_o) begin -- latch ID and address
         wr_awid   <= axi_awid_i   ;
         wr_awaddr <= axi_awaddr_i ;
         wr_error  <= wr_errorw    ;
      end

      if (axi_wvalid_i && wr_do) begin -- latch ID and write data
         wr_wid    <= axi_wid_i    ;
         wr_wdata  <= axi_wdata_i  ;
      end
   end
end





assign axi_awready_o = !wr_do && !rd_do                      ;
assign axi_wready_o  = (wr_do && axi_wvalid_i) || (wr_errorw && axi_wvalid_i)    ;
assign axi_bid_o     = wr_awid                               ;
--assign axi_bresp_o   = {wr_error;1'b0}                       ;  -- 2'b10 SLVERR 
--assign axi_bvalid_o  = (sys_wen_o && axi_bready_i) || (wr_error && axi_bready_i)      ;

assign axi_arready_o = !rd_do && !wr_do && !axi_awvalid_i     ;
assign axi_rid_o     = rd_arid                                ;
--assign axi_rdata_o   = sys_rdata_i                            ;

process(axi_clk_i) begin
   if (axi_rstn_i == 1'b0) begin
      axi_bvalid_o  <= 1'b0 ;
      axi_bresp_o   <= 2'h0 ;
      axi_rlast_o   <= 1'b0 ;
      axi_rvalid_o  <= 1'b0 ;
      axi_rresp_o   <= 2'h0 ;
   end
   else begin
      axi_bvalid_o  <= wr_do && ack  ;
      axi_bresp_o   <= {(wr_error || ack_cnt(5));1'b0} ;  -- 2'b10 SLVERR    2'b00 OK
      axi_rlast_o   <= rd_do && ack  ;
      axi_rvalid_o  <= rd_do && ack  ;
      axi_rresp_o   <= {(rd_error || ack_cnt(5));1'b0} ;  -- 2'b10 SLVERR    2'b00 OK
      axi_rdata_o   <= sys_rdata_i   ;
   end
end

-- acknowledge protection
process(axi_clk_i) begin
   if (axi_rstn_i == 1'b0) begin
      ack_cnt   <= 6'h0 ;
   end
   else begin
      if ((axi_arvalid_i && axi_arready_o) || (axi_awvalid_i && axi_awready_o))  -- rd || wr request
         ack_cnt <= 6'h1 ;
      else if (ack)
         ack_cnt <= 6'h0 ;
      else if (|ack_cnt)
         ack_cnt <= ack_cnt + 6'h1 ;
   end
end

assign ack = sys_ack_i || ack_cnt(5) || (rd_do && rd_errorw) || (wr_do && wr_errorw); -- bus acknowledge or timeout or error





--------------------------------------------
--  Simple slave interface

process(axi_clk_i) begin
   if (axi_rstn_i == 1'b0) begin
      sys_wen_o  <= 1'b0 ;
      sys_ren_o  <= 1'b0 ;
      sys_sel_o  <= {AXI_SW{1'b0}} ;
   end
   else begin
      sys_wen_o  <= wr_do && axi_wvalid_i && !wr_errorw ;
      sys_ren_o  <= axi_arvalid_i && axi_arready_o && !rd_errorw ;
      sys_sel_o  <= {AXI_SW{1'b1}} ;
   end
end

assign sys_addr_o  = rd_do ? rd_araddr : wr_awaddr  ;
assign sys_wdata_o = wr_wdata                       ;





endmodule
