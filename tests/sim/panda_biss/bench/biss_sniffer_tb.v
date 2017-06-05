`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   07:36:13 04/12/2016
// Design Name:   biss_sniffer
// Module Name:   /home/iu42/hardware/trunk/FPGA/zebra2-server/CarrierFPGA/sim/panda_biss/bench/biss_sniffer_tb.v
// Project Name:  panda_top
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: biss_sniffer
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module biss_sniffer_tb;

// Inputs
reg clk_i = 0;
reg reset_i;
reg [7:0] BITS = 32;
reg ssi_sck_0;
reg ssi_dat_0;
reg ssi_sck_1;
reg ssi_dat_1;
reg STATUS_RSTB = 0;

// Outputs
wire [31:0] posn_0;
wire [31:0] posn_1;
wire [31:0] STATUS_0;
wire [31:0] STATUS_1;

integer fid_0, fid_1, r;

always #4 clk_i = ~clk_i;

initial begin
    reset_i = 1;
    repeat (5) @(posedge clk_i);
    reset_i = 0;
end

// Instantiate the Unit Under Test (UUT)
biss_sniffer uut_0 (
    .clk_i      ( clk_i         ),
    .reset_i    ( reset_i       ),
    .BITS       ( BITS          ),
    //.STATUS     ( STATUS_0      ),
    //.STATUS_RSTB( STATUS_RSTB   ),
    .link_up_o  ( link_up_o     ),
    .error_o    ( error_o       ), 
    .ssi_sck_i  ( ssi_sck_0     ),
    .ssi_dat_i  ( ssi_dat_0     ),
    .posn_o     ( posn_0        )
);

// Instantiate the Unit Under Test (UUT)
biss_sniffer uut_1 (
    .clk_i      ( clk_i         ),
    .reset_i    ( reset_i       ),
    .BITS       ( BITS          ),
    //.STATUS     ( STATUS_1      ),
    //.STATUS_RSTB( STATUS_RSTB   ),
    .link_up_o  ( link_up_o     ),
    .error_o    ( error_o       ), 
    .ssi_sck_i  ( ssi_sck_1     ),
    .ssi_dat_i  ( ssi_dat_1     ),
    .posn_o     ( posn_1        )
);

// Channel 0
initial begin
    ssi_sck_0 = 1;
    ssi_dat_0 = 1;

    // Clear STATUS first thing
    repeat (10) @(posedge clk_i);
    STATUS_RSTB <= 1'b1;@(posedge clk_i);STATUS_RSTB <= 1'b0;

    repeat (50) @(posedge clk_i);
    fid_0 = $fopen("biss0.prn", "r");

    // Read and ignore description field
    while (!$feof(fid_0)) begin
        r = $fscanf(fid_0, "%d %d\n", ssi_sck_0, ssi_dat_0);
        @(posedge clk_i);
    end

    repeat (1250) @(posedge clk_i);
    STATUS_RSTB <= 1'b1;@(posedge clk_i);STATUS_RSTB <= 1'b0;
    repeat (12500) @(posedge clk_i);
    $finish;
end

// Channel 1
initial begin
    ssi_sck_1 = 1;
    ssi_dat_1 = 1;

    repeat (50) @(posedge clk_i);
    fid_1 = $fopen("biss2.prn", "r");

    // Read and ignore description field
    while (!$feof(fid_1)) begin
        r = $fscanf(fid_1, "%d %d\n", ssi_sck_1, ssi_dat_1);
        @(posedge clk_i);
    end

    repeat (1250) @(posedge clk_i);
    STATUS_RSTB <= 1'b1;@(posedge clk_i);STATUS_RSTB <= 1'b0;
    repeat (12500) @(posedge clk_i);
    $finish;
end

endmodule

