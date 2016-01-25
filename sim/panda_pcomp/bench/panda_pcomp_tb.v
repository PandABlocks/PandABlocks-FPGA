`timescale 1ns / 1ps

module panda_pcomp_tb;

// Inputs
reg clk_i = 0;
reg reset_i;
reg enable_i;

reg [31:0] posn_i;
reg [31:0] PCOMP_START;
reg [31:0] PCOMP_STEP;
reg [31:0] PCOMP_WIDTH;
reg [31:0] PCOMP_NUM;
reg PCOMP_RELATIVE;
reg PCOMP_DIR;
reg [31:0] PCOMP_FLTR_DELTAT;
reg [15:0] PCOMP_FLTR_THOLD;

// Outputs
wire act_o;
wire pulse_o;


always #4 clk_i = ~clk_i;

// Instantiate the Unit Under Test (UUT)
panda_pcomp uut (
    .clk_i              ( clk_i                 ),
    .reset_i            ( reset_i               ),
    .enable_i           ( enable_i              ),
    .posn_i             ( posn_i                ),
    .PCOMP_START        ( PCOMP_START           ),
    .PCOMP_STEP         ( PCOMP_STEP            ),
    .PCOMP_WIDTH        ( PCOMP_WIDTH           ),
    .PCOMP_NUM          ( PCOMP_NUM             ),
    .PCOMP_RELATIVE     ( PCOMP_RELATIVE        ),
    .PCOMP_DIR          ( PCOMP_DIR             ),
    .PCOMP_FLTR_DELTAT  ( PCOMP_FLTR_DELTAT     ),
    .PCOMP_FLTR_THOLD   ( PCOMP_FLTR_THOLD      ),
    .act_o(act_o), 
    .pulse_o(pulse_o)
);

initial begin
    reset_i = 1;
    repeat(10) @(posedge clk_i)
    reset_i = 0;
end

integer i;
integer j;
integer DELTA;

initial begin
    i = 0;
    j = 0;
    DELTA = 1;
    enable_i = 0;
    posn_i = 0;
    PCOMP_START = 0;
    PCOMP_STEP = 0;
    PCOMP_WIDTH = 0;
    PCOMP_NUM = 0;
    PCOMP_RELATIVE = 0;
    PCOMP_DIR = 0;
    PCOMP_FLTR_DELTAT = 0;
    PCOMP_FLTR_THOLD = 0;

    repeat(1250) @(posedge clk_i)
    PCOMP_START = 4000;
    PCOMP_STEP  = 0;
    PCOMP_WIDTH = 2000;
    PCOMP_NUM   = 5;
    PCOMP_RELATIVE = 0;
    PCOMP_DIR = 1;
    PCOMP_FLTR_DELTAT = 125*10;
    PCOMP_FLTR_THOLD = 2;
    repeat(1250) @(posedge clk_i)

    enable_i = 1;

    repeat(1250) @(posedge clk_i);

    for (j=0; j<500;j=j+1) begin
        if (j%2) DELTA = -1;
        else DELTA = 1;

        for (i=0; i<5000;i=i+1) begin
            posn_i = posn_i + DELTA;
            repeat(125) @(posedge clk_i);
        end
    end

end

endmodule

