`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000


module panda_pcomp_tb;

// Inputs
reg         clk_i = 0;
reg         reset_i;
reg         enable_i;
reg [31:0]  posn_i;

// Outputs
wire [31: 0]    err0_o;
wire            act0_o;
wire            pulse0_o;
wire [31: 0]    err1_o;
wire            act1_o;
wire            pulse1_o;

// Clock and Reset
always #4 clk_i = !clk_i;

// Instantiate the Unit Under Test (UUT)
pcomp uut0 (
    .clk_i              ( clk_i             ),
    .reset_i            ( reset_i           ),
    .enable_i           ( enable_i          ),
    .posn_i             ( posn_i            ),
    .START              ( 1000              ),
    .STEP               ( 100               ),
    .WIDTH              ( 50                ),
    .NUM                ( 100               ),
    .RELATIVE           ( 1'b0              ),
    .DIR                ( 1'b0              ),
    .DELTAP             ( 100               ),
    .act_o              ( act0_o            ),
    .err_o              ( err0_o            ),
    .out_o              ( pulse0_o          ),
    .table_posn_i       ( 64'h0             ),
    .USE_TABLE          ( 1'b0              )
);

pcomp uut1 (
    .clk_i              ( clk_i             ),
    .reset_i            ( reset_i           ),
    .enable_i           ( enable_i          ),
    .posn_i             ( posn_i            ),
    .START              ( 4000              ),
    .STEP               ( 100               ),
    .WIDTH              ( 50                ),
    .NUM                ( 100               ),
    .RELATIVE           ( 1'b0              ),
    .DIR                ( 1'b1              ),
    .DELTAP             ( 100               ),
    .act_o              ( act1_o            ),
    .err_o              ( err1_o            ),
    .out_o              ( pulse1_o          ),
    .table_posn_i       ( 64'h0             ),
    .USE_TABLE          ( 1'b0              )
);

//
// Read Bus Inputs
//
integer i;

initial
begin : bus_inputs
    posn_i = 0;
    reset_i = 1;
    enable_i = 0;
    repeat(125) @(posedge clk_i);
    reset_i = 0;
    enable_i = 1;
    posn_i = 5000;
    repeat(1250) @(posedge clk_i);

    for (i = 0; i < 5000; i = i + 1) begin
        if (posn_i == 3801)
            posn_i <= 3750;
        else
            posn_i <= posn_i - 1;
        repeat(125) @(posedge clk_i);
    end

    repeat(12500) @(posedge clk_i);
    $finish;
end


endmodule

