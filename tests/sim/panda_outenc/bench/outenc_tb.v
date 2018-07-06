`timescale 1ns / 1ps

module outenc_tb;

// Inputs
reg         clk_i = 0;
reg         reset_i;
reg         a_ext_i;
reg         b_ext_i;
reg         z_ext_i;
reg         data_ext_i;
reg [31:0]  posn_i;
reg         enable_i;
reg [2:0]   PROTOCOL;
reg         BYPASS;
reg [7:0]   BITS;
reg [31:0]  QPERIOD;

// Outputs
wire        A_OUT;
wire        B_OUT;
wire        Z_OUT;
wire        DATA_OUT;
reg         CLK_IN = 0;
wire [31:0] QSTATE; 

always #4 clk_i = !clk_i;

// Instantiate the Unit Under Test (UUT)
outenc uut (
        .clk_i          ( clk_i         ), 
        .reset_i        ( reset_i       ), 
        .a_ext_i        ( a_ext_i       ), 
        .b_ext_i        ( b_ext_i       ), 
        .z_ext_i        ( z_ext_i       ), 
        .data_ext_i     ( data_ext_i    ), 
        .posn_i         ( posn_i        ), 
        .enable_i       ( enable_i      ), 

        .A_OUT          ( A_OUT         ), 
        .B_OUT          ( B_OUT         ), 
        .Z_OUT          ( Z_OUT         ), 
        .DATA_OUT       ( DATA_OUT      ), 
        .CLK_IN         ( CLK_IN        ),        

        .PROTOCOL       ( PROTOCOL      ), 
        .BYPASS         ( BYPASS        ),   
        .BITS           ( BITS          ), 
        .QPERIOD        ( QPERIOD       ),
        .QPERIOD_WSTB   ( QPERIOD_WSTB  ),
        .QSTATE         ( QSTATE        )
);


//
//QUAD RECEIVER
//
//wire [31: 0]    quadin_posn;

//quadin quadin (
//    .clk_i        ( clk_i               ),
//    .reset_i      ( reset_i             ),
//    .a_ext_i      ( a_o                 ),
//    .b_ext_i      ( b_o                 ),
//    .z_ext_i      ( 1'b0                ),
//    .rst_z_i      ( 1'b0                ),
//    .setp_val_i   ( 0                   ),
//    .setp_wstb_i  ( 1'b0                ),
//    .posn_o       ( quadin_posn         )
//);



initial begin
    reset_i = 1;
    a_ext_i = 0;
    b_ext_i = 0;
    z_ext_i = 0;
    data_ext_i = 0;
    posn_i = 0;
    enable_i = 0;
    PROTOCOL = 0;
    BYPASS = 0;
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
    //
    repeat(1250) @(posedge clk_i);
    posn_i = 21;

    repeat(1250) @(posedge clk_i);
    posn_i = 200;

    repeat(1250) @(posedge clk_i);
    posn_i = 9;

    
    repeat(12500) @(posedge clk_i);
    $finish;
end

endmodule

