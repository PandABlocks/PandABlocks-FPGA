`timescale 1ns / 1ps

module outenc_tb;

// Inputs
reg clk_i = 0;
reg reset_i;
reg a_i;
reg b_i;
reg z_i;
reg conn_i;
reg [31:0] posn_i;
reg enable_i;
reg sclk_i;
reg sdat_i;
reg [2:0] PROTOCOL;
reg [7:0] BITS;
reg [31:0] QPERIOD;

// Outputs
wire a_o;
wire b_o;
wire z_o;
wire conn_o;
wire sdat_o;
wire sdat_dir_o;
wire [31:0] QSTATE;
wire [2:0] enc_mode_o;
wire [2:0] iobuf_ctrl_o;

always #4 clk_i = !clk_i;

// Instantiate the Unit Under Test (UUT)
outenc uut (
        .clk_i(clk_i), 
        .reset_i(reset_i), 
        .a_i(a_i), 
        .b_i(b_i), 
        .z_i(z_i), 
        .conn_i(conn_i), 
        .posn_i(posn_i), 
        .enable_i(enable_i), 
        .a_o(a_o), 
        .b_o(b_o), 
        .z_o(z_o), 
        .conn_o(conn_o), 
        .sclk_i(sclk_i), 
        .sdat_i(sdat_i), 
        .sdat_o(sdat_o), 
        .sdat_dir_o(sdat_dir_o), 
        .PROTOCOL(PROTOCOL), 
        .BITS(BITS), 
        .QPERIOD(QPERIOD), 
        .QSTATE(QSTATE), 
        .enc_mode_o(enc_mode_o), 
        .iobuf_ctrl_o(iobuf_ctrl_o)
);


//
//QUAD RECEIVER
//
wire [31: 0]    quadin_posn;

quadin quadin (
    .clk_i        ( clk_i               ),
    .reset_i      ( reset_i             ),
    .a_i          ( a_o                 ),
    .b_i          ( b_o                 ),
    .z_i          ( 1'b0                ),
    .rst_z_i      ( 1'b0                ),
    .setp_val_i   ( 0                   ),
    .setp_wstb_i  ( 1'b0                ),
    .posn_o       ( quadin_posn         )
);


initial begin
    reset_i = 1;
    a_i = 0;
    b_i = 0;
    z_i = 0;
    conn_i = 0;
    posn_i = 0;
    enable_i = 0;
    sclk_i = 0;
    sdat_i = 0;
    PROTOCOL = 0;
    BITS = 0;
    QPERIOD = 125;

    repeat(100) @(posedge clk_i);
    reset_i = 0;
    repeat(1250) @(posedge clk_i);

    repeat(125) @(posedge clk_i);
    enable_i = 1;
    repeat(125) @(posedge clk_i);
    posn_i = 1000;
    repeat(1250) @(posedge clk_i);
    posn_i = 7;
    repeat(12500) @(posedge clk_i);
    $finish;
end

endmodule

