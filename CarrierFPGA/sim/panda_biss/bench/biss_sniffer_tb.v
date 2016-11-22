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
reg [7:0] STATUS_BITS = 2;
reg [7:0] CRC_BITS = 6;
reg ssi_sck_i;
reg ssi_dat_i;

// Outputs
wire [31:0] posn_o;

integer fid, r;

always #4 clk_i = ~clk_i;

initial begin
    reset_i = 1;
    repeat (5) @(posedge clk_i);
    reset_i = 0;
end


// Instantiate the Unit Under Test (UUT)
biss_sniffer uut (
    .clk_i      ( clk_i         ),
    .reset_i    ( reset_i       ),
    .BITS       ( BITS          ),
    .STATUS_BITS( STATUS_BITS   ),
    .CRC_BITS   ( CRC_BITS      ),
    .ssi_sck_i  ( ssi_sck_i     ),
    .ssi_dat_i  ( ssi_dat_i     ),
    .posn_o     ( posn_o        )
);

initial begin
    ssi_sck_i = 1;
    ssi_dat_i = 1;

    repeat (50) @(posedge clk_i);
    fid = $fopen("biss.prn", "r");

    // Read and ignore description field
    while (!$feof(fid)) begin
        r = $fscanf(fid, "%d %d\n", ssi_dat_i, ssi_sck_i);
        @(posedge clk_i);
    end

    repeat (12500) @(posedge clk_i);
    $finish;
end

endmodule

