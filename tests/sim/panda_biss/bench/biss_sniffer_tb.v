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
reg STATUS_RSTB_0 = 0;
reg STATUS_RSTB_1 = 0; 

// Outputs
wire [31:0] posn_0;
wire [31:0] posn_1;
wire [31:0] STATUS_0;
wire [31:0] STATUS_1;

wire link_up_o1;
wire link_up_o2;
wire error_o1;
wire error_o2;

wire result_ready_0;
wire result_ready_1;
wire [31:0] data_result_0;
wire [31:0] data_result_1;
wire [5:0]  CRC_data_0;
wire [5:0]  CRC_data_1;

reg err_0;
reg err_1;

reg test_result = 0;

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
    .link_up_o  ( link_up_o1    ),
    .error_o    ( error_o1      ), 
    .ssi_sck_i  ( ssi_sck_0     ),
    .ssi_dat_i  ( ssi_dat_0     ),
    .posn_o     ( posn_0        )
);

// Instantiate the Unit Under Test (UUT)
biss_sniffer uut_1 (
    .clk_i      ( clk_i         ),
    .reset_i    ( reset_i       ),
    .BITS       ( BITS          ),
    .link_up_o  ( link_up_o2    ),
    .error_o    ( error_o2      ), 
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
    STATUS_RSTB_0 <= 1'b1;@(posedge clk_i);STATUS_RSTB_0 <= 1'b0;

    repeat (50) @(posedge clk_i);
    fid_0 = $fopen("biss0.prn", "r");

    // Read and ignore description field
    while (!$feof(fid_0)) begin
        r = $fscanf(fid_0, "%d %d\n", ssi_sck_0, ssi_dat_0);
        @(posedge clk_i);
    end

//    repeat (1250) @(posedge clk_i);
    repeat (1000) @(posedge clk_i);
    STATUS_RSTB_0 <= 1'b1;@(posedge clk_i);STATUS_RSTB_0 <= 1'b0;
//    repeat (12500) @(posedge clk_i);
    repeat (10000) @(posedge clk_i);   
//    $finish;
end

// Channel 1
initial begin
    ssi_sck_1 = 1;
    ssi_dat_1 = 1;

    // Clear STATUS first thing
    repeat (10) @(posedge clk_i);
    STATUS_RSTB_1 <= 1'b1;@(posedge clk_i);STATUS_RSTB_1 <= 1'b0;   

    repeat (50) @(posedge clk_i);
    fid_1 = $fopen("biss2.prn", "r");

    // Read and ignore description field
    while (!$feof(fid_1)) begin
        r = $fscanf(fid_1, "%d %d\n", ssi_sck_1, ssi_dat_1);
        @(posedge clk_i);
    end

//    repeat (1250) @(posedge clk_i);
    repeat (1000) @(posedge clk_i);    
    STATUS_RSTB_1 <= 1'b1;@(posedge clk_i);STATUS_RSTB_1 <= 1'b0;
//    repeat (12500) @(posedge clk_i);
    repeat (10000) @(posedge clk_i);
    $finish;
end

//  Instantiate BiSS result generator 1
biss_result uut2 (
    .clk_i          ( clk_i          ),
    .reset_i        ( reset_i        ),
    .ssi_sck_i      ( ssi_sck_0      ),
    .ssi_dat_i      ( ssi_dat_0      ),
    .BITS           ( BITS           ),
    .result_ready   ( result_ready_0 ),
    .data_result    ( data_result_0  ),          
    .CRC_data       ( CRC_data_0     )   
);

//  Instantiate BiSS result generator 2 
biss_result uut3 (
    .clk_i          ( clk_i          ),
    .reset_i        ( reset_i        ),
    .ssi_sck_i      ( ssi_sck_1      ),
    .ssi_dat_i      ( ssi_dat_1      ),
    .BITS           ( BITS           ),   
    .result_ready   ( result_ready_1 ),
    .data_result    ( data_result_1  ),
    .CRC_data       ( CRC_data_1     )          
);


always @(posedge clk_i)
begin
    if (result_ready_0 == 1) begin
        if (data_result_0 != posn_0) begin
            err_0 <= 1;
            test_result <= 1;
            $display("BiSS Sniffer 0 result different from expected result %d,%d\n", data_result_1,posn_0);    
        end else begin
            err_0 <= 0;
        end     
    end
    if (result_ready_1 == 1) begin    
        if (data_result_1 != posn_1) begin
            err_1 <= 1;
            test_result <= 1;
            $display("BiSS Sniffer 1 result different from expected result %d, %d\n", data_result_1, posn_1);
        end else begin
            err_1 <= 0;
        end    
    end
end                         

endmodule
