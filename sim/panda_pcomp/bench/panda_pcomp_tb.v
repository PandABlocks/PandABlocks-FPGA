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
reg [31:0]  START;
reg [31:0]  STEP;
reg [31:0]  WIDTH;
reg [31:0]  NUM;
reg         RELATIVE;
reg         DIR;
reg [31:0]  DELTAP;
reg         USE_TABLE;

// Outputs
wire [31: 0]    err_o;
reg  [31: 0]    ERR;
wire            act_o;
reg             ACT;
wire            pulse_o;
reg             PULSE;

// Testbench specific
integer timestamp = 0;

// Clock and Reset
always #4 clk_i = !clk_i;

initial begin
    reset_i = 1;
    repeat(10) @(posedge clk_i);
    reset_i = 0;
end

//
// Values in the test files are arranged on FPGA clock ticks on the
// first column. This way all files are read syncronously.
//
// To achieve that a free running global Timestamp Counter below
// is used.
//
initial begin
    repeat(12500) @(posedge clk_i);
    while (1) begin
        @(posedge clk_i);
        timestamp <= timestamp + 1;
    end
end

// Instantiate the Unit Under Test (UUT)
pcomp uut (
    .clk_i              ( clk_i             ),
    .reset_i            ( reset_i           ),
    .enable_i           ( enable_i          ),
    .posn_i             ( posn_i            ),
    .START              ( START             ),
    .STEP               ( STEP              ),
    .WIDTH              ( WIDTH             ),
    .NUM                ( NUM               ),
    .RELATIVE           ( RELATIVE          ),
    .DIR                ( DIR               ),
    .DELTAP             ( DELTAP            ),
    .act_o              ( act_o             ),
    .err_o              ( err_o             ),
    .pulse_o            ( pulse_o           ),
    .table_posn_i       ( 64'h0             ),
    .USE_TABLE          ( USE_TABLE         )
);

//
// Read Bus Inputs
//
initial
begin : bus_inputs
    localparam filename = "pcomp_bus_in.txt";
    localparam N        = 4;
    reg [31:0] vectors[31: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "./file_io.v"
        $finish;
    end

    begin
        while (1) begin
            @(posedge clk_i);
            reset_i  = vectors[1];
            enable_i = vectors[2];
            posn_i   = vectors[3];
        end
    end
join

    repeat(12500) @(posedge clk_i);
    $finish;
end

//
// Read Register Inputs
//
initial
begin : reg_inputs
    localparam filename = "pcomp_reg_in.txt";
    localparam N        = 21;
    reg [31:0] vectors[31: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "./file_io.v"
    end

    begin
        while (1) begin
            @(posedge clk_i);
            START       = vectors[1];
            STEP        = vectors[3];
            WIDTH       = vectors[5];
            NUM         = vectors[7];
            RELATIVE    = vectors[9];
            DIR         = vectors[11];
            DELTAP      = vectors[13];
            USE_TABLE   = vectors[15];
        end
    end
join

end

//
// Read Bus Outputs
//
initial
begin : bus_outputs
    localparam filename = "pcomp_bus_out.txt";
    localparam N        = 3;
    reg [31:0] vectors[31: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "./file_io.v"
    end

    begin
        while (1) begin
            @(posedge clk_i);
            ACT   = vectors[1];
            PULSE = vectors[2];
        end
    end
join

end

//
// Read Reg Outputs
//
initial
begin : reg_outputs
    localparam filename = "pcomp_reg_out.txt";
    localparam N        = 2;
    reg [31:0] vectors[31: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "./file_io.v"
    end

    begin
        while (1) begin
            @(posedge clk_i);
            ERR = vectors[1];
        end
    end
join

end

endmodule

