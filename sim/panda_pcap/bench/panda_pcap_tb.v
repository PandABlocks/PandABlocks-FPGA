`timescale 1ns / 1ps

module panda_pcap_tb;

// Inputs
reg S_AXI_HP0_ARVALID;
reg S_AXI_HP0_AWVALID;
reg S_AXI_HP0_BREADY;
reg S_AXI_HP0_RREADY;
reg S_AXI_HP0_WLAST;
reg S_AXI_HP0_WVALID;
reg [1:0] S_AXI_HP0_ARBURST;
reg [1:0] S_AXI_HP0_ARLOCK;
reg [2:0] S_AXI_HP0_ARSIZE;
reg [1:0] S_AXI_HP0_AWBURST;
reg [1:0] S_AXI_HP0_AWLOCK;
reg [2:0] S_AXI_HP0_AWSIZE;
reg [2:0] S_AXI_HP0_ARPROT;
reg [2:0] S_AXI_HP0_AWPROT;
reg [31:0] S_AXI_HP0_ARADDR;
reg [31:0] S_AXI_HP0_AWADDR;
reg [3:0] S_AXI_HP0_ARCACHE;
reg [3:0] S_AXI_HP0_ARLEN;
reg [3:0] S_AXI_HP0_ARQOS;
reg [3:0] S_AXI_HP0_AWCACHE;
reg [3:0] S_AXI_HP0_AWLEN;
reg [3:0] S_AXI_HP0_AWQOS;
reg [5:0] S_AXI_HP0_ARID;
reg [5:0] S_AXI_HP0_AWID;
reg [5:0] S_AXI_HP0_WID;
reg [63:0] S_AXI_HP0_WDATA;
reg [7:0] S_AXI_HP0_WSTRB;
reg [3:0] IRQ_F2P;

// Outputs
wire S_AXI_HP0_ARREADY;
wire S_AXI_HP0_AWREADY;
wire S_AXI_HP0_BVALID;
wire S_AXI_HP0_RLAST;
wire S_AXI_HP0_RVALID;
wire S_AXI_HP0_WREADY;
wire [1:0] S_AXI_HP0_BRESP;
wire [1:0] S_AXI_HP0_RRESP;
wire [5:0] S_AXI_HP0_BID;
wire [5:0] S_AXI_HP0_RID;
wire [63:0] S_AXI_HP0_RDATA;
wire FCLK_CLK0;
wire FCLK_CLK1;
wire FCLK_CLK2;
wire FCLK_CLK3;
wire FCLK_RESET0_N;
wire FCLK_RESET1_N;
wire FCLK_RESET2_N;
wire FCLK_RESET3_N;


reg tb_ACLK;
reg tb_ARESETn;

initial begin
    tb_ACLK = 1'b0;
end

always #10 tb_ACLK = !tb_ACLK;

initial begin
    tb_ARESETn = 1'b0;
    // Release the reset on the posedge of the clk.
    repeat(1000)@(posedge tb_ACLK);
    tb_ARESETn = 1'b1;
    @(posedge tb_ACLK);
end

// Instantiate the Unit Under Test (UUT)
processing_system7_bfm_0 zynq_ps
(
    .S_AXI_HP0_ARREADY  (S_AXI_HP0_ARREADY),
    .S_AXI_HP0_AWREADY  (S_AXI_HP0_AWREADY),
    .S_AXI_HP0_BVALID   (S_AXI_HP0_BVALID),
    .S_AXI_HP0_RLAST    (S_AXI_HP0_RLAST),
    .S_AXI_HP0_RVALID   (S_AXI_HP0_RVALID), 
    .S_AXI_HP0_WREADY   (S_AXI_HP0_WREADY), 
    .S_AXI_HP0_BRESP    (S_AXI_HP0_BRESP), 
    .S_AXI_HP0_RRESP    (S_AXI_HP0_RRESP), 
    .S_AXI_HP0_BID      (S_AXI_HP0_BID), 
    .S_AXI_HP0_RID      (S_AXI_HP0_RID), 
    .S_AXI_HP0_RDATA    (S_AXI_HP0_RDATA), 
    .S_AXI_HP0_ACLK     (FCLK_CLK0              ),
    .S_AXI_HP0_ARVALID(S_AXI_HP0_ARVALID), 
    .S_AXI_HP0_AWVALID(S_AXI_HP0_AWVALID), 
    .S_AXI_HP0_BREADY(S_AXI_HP0_BREADY), 
    .S_AXI_HP0_RREADY(S_AXI_HP0_RREADY), 
    .S_AXI_HP0_WLAST(S_AXI_HP0_WLAST), 
    .S_AXI_HP0_WVALID(S_AXI_HP0_WVALID), 
    .S_AXI_HP0_ARBURST(S_AXI_HP0_ARBURST), 
    .S_AXI_HP0_ARLOCK(S_AXI_HP0_ARLOCK), 
    .S_AXI_HP0_ARSIZE(S_AXI_HP0_ARSIZE), 
    .S_AXI_HP0_AWBURST(S_AXI_HP0_AWBURST), 
    .S_AXI_HP0_AWLOCK(S_AXI_HP0_AWLOCK), 
    .S_AXI_HP0_AWSIZE(S_AXI_HP0_AWSIZE), 
    .S_AXI_HP0_ARPROT(S_AXI_HP0_ARPROT), 
    .S_AXI_HP0_AWPROT(S_AXI_HP0_AWPROT), 
    .S_AXI_HP0_ARADDR(S_AXI_HP0_ARADDR), 
    .S_AXI_HP0_AWADDR(S_AXI_HP0_AWADDR), 
    .S_AXI_HP0_ARCACHE(S_AXI_HP0_ARCACHE), 
    .S_AXI_HP0_ARLEN(S_AXI_HP0_ARLEN), 
    .S_AXI_HP0_ARQOS(S_AXI_HP0_ARQOS), 
    .S_AXI_HP0_AWCACHE(S_AXI_HP0_AWCACHE), 
    .S_AXI_HP0_AWLEN(S_AXI_HP0_AWLEN), 
    .S_AXI_HP0_AWQOS(S_AXI_HP0_AWQOS), 
    .S_AXI_HP0_ARID(S_AXI_HP0_ARID), 
    .S_AXI_HP0_AWID(S_AXI_HP0_AWID), 
    .S_AXI_HP0_WID(S_AXI_HP0_WID), 
    .S_AXI_HP0_WDATA(S_AXI_HP0_WDATA), 
    .S_AXI_HP0_WSTRB(S_AXI_HP0_WSTRB), 
    .FCLK_CLK0(FCLK_CLK0), 
    .FCLK_CLK1(FCLK_CLK1), 
    .FCLK_CLK2(FCLK_CLK2), 
    .FCLK_CLK3(FCLK_CLK3), 
    .FCLK_RESET0_N(FCLK_RESET0_N), 
    .FCLK_RESET1_N(FCLK_RESET1_N), 
    .FCLK_RESET2_N(FCLK_RESET2_N), 
    .FCLK_RESET3_N(FCLK_RESET3_N), 
    .PS_SRSTB           (tb_ARESETn             ),
    .PS_CLK             (tb_ACLK                ),
    .PS_PORB            (tb_ARESETn             ),
    .IRQ_F2P            (IRQ_F2P                )
);







initial begin
    IRQ_F2P = 0;

    // Wait 100 ns for global reset to finish
    #100;
end

endmodule

