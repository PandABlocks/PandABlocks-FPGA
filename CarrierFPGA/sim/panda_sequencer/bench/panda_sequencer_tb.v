`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000

module panda_sequencer_tb;

// Inputs
reg clk_i = 0;

reg reset_i;
reg gate_i;
reg inpa_i;
reg inpb_i;
reg inpc_i;
reg inpd_i;

reg [31:0] PRESCALE;
reg SOFT_GATE;
reg TABLE_START;
reg [31:0] TABLE_DATA;
reg TABLE_WSTB;
reg [31:0] TABLE_CYCLE;
reg [15:0] TABLE_LENGTH;
reg         TABLE_LENGTH_WSTB;

// Outputs
wire outa_o;
reg OUTA;
wire outb_o;
reg OUTB;
wire outc_o;
reg OUTC;
wire outd_o;
reg OUTD;
wire oute_o;
reg OUTE;
wire outf_o;
reg OUTF;
wire active_o;
reg ACTIVE;

wire [31:0] CUR_FRAME;
reg [31: 0] TB_CUR_FRAME;
wire [31:0] CUR_FCYCLE;
reg [31: 0] TB_CUR_FCYCLE;
wire [31:0] CUR_TCYCLE;
reg [31: 0] TB_CUR_TCYCLE;

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
    repeat(5) @(posedge clk_i);
    while (1) begin
        @(posedge clk_i);
        timestamp <= timestamp + 1;
    end
end


// Instantiate the Unit Under Test (UUT)
panda_sequencer uut (
    .clk_i              ( clk_i                 ),
    .reset_i            ( reset_i               ),
    .gate_i             ( gate_i                ),
    .inpa_i             ( inpa_i                ),
    .inpb_i             ( inpb_i                ),
    .inpc_i             ( inpc_i                ),
    .inpd_i             ( inpd_i                ),
    .outa_o             ( outa_o                ),
    .outb_o             ( outb_o                ),
    .outc_o             ( outc_o                ),
    .outd_o             ( outd_o                ),
    .oute_o             ( oute_o                ),
    .outf_o             ( outf_o                ),
    .active_o           ( active_o              ),
    .PRESCALE           ( PRESCALE              ),
    .SOFT_GATE          ( SOFT_GATE             ),
    .TABLE_START        ( TABLE_START           ),
    .TABLE_DATA         ( TABLE_DATA            ),
    .TABLE_WSTB         ( TABLE_WSTB            ),
    .TABLE_CYCLE        ( TABLE_CYCLE           ),
    .TABLE_LENGTH       ( TABLE_LENGTH          ),
    .TABLE_LENGTH_WSTB  ( TABLE_LENGTH_WSTB     ),
    .CUR_FRAME          ( CUR_FRAME             ),
    .CUR_FCYCLE         ( CUR_FCYCLE            ),
    .CUR_TCYCLE         ( CUR_TCYCLE            )
);

//
// Read Bus Inputs
//
initial
begin : bus_inputs
    localparam filename = "seq_bus_in.txt";
    localparam N        = 7;
    reg [31:0] vectors[31: 0];

    reg     [8192:0] line;
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
            reset_i = vectors[1];
            gate_i  = vectors[2];
            inpa_i  = vectors[3];
            inpb_i  = vectors[4];
            inpc_i  = vectors[5];
            inpd_i  = vectors[6];
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
    localparam filename = "seq_reg_in.txt";
    localparam N        = 13;
    reg [31:0] vectors[31: 0];

    reg     [8192:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "./file_io.v"
    end

    begin
        while (1) begin
            @(posedge clk_i);
            PRESCALE     = vectors[1];
            SOFT_GATE    = vectors[3];
            TABLE_CYCLE  = vectors[5];
            TABLE_START  = vectors[8];
            TABLE_DATA   = vectors[9];
            TABLE_WSTB   = vectors[10];
            TABLE_LENGTH = vectors[11];
            TABLE_LENGTH_WSTB = vectors[12];
        end
    end
join

end

//
// Read Bus Outputs
//
initial
begin : bus_outputs
    localparam filename = "seq_bus_out.txt";
    localparam N        = 8;
    reg [31:0] vectors[31: 0];

    reg     [8192:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "./file_io.v"
    end

    begin
        while (1) begin
            @(posedge clk_i);
            OUTA = vectors[1];
            OUTB = vectors[2];
            OUTC = vectors[3];
            OUTD = vectors[4];
            OUTE = vectors[5];
            OUTF = vectors[6];
            ACTIVE = vectors[7];
        end
    end
join

end

//
// Read Register Outputs
//
initial
begin : reg_outputs
    localparam filename = "seq_reg_out.txt";
    localparam N        = 5;
    reg [31:0] vectors[31: 0];

    reg     [8192:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "./file_io.v"
    end

    begin
        while (1) begin
            @(posedge clk_i);
            TB_CUR_FRAME   = vectors[1];
            TB_CUR_FCYCLE  = vectors[2];
            TB_CUR_TCYCLE  = vectors[3];
        end
    end
join

end

endmodule

