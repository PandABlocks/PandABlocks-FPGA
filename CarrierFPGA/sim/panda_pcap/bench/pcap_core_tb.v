`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000


module pcap_core_tb;

// Inputs
reg clk_i = 0;
reg reset_i;
reg ARM;
reg DISARM;
reg START_WRITE;
reg [31:0] WRITE;
reg WRITE_WSTB;
reg [31:0] FRAMING_MASK;
reg FRAMING_ENABLE;
reg [31:0] FRAMING_MODE;
reg enable_i;
reg capture_i;
reg frame_i;
reg dma_full_i;
reg [127:0] sysbus_i;
reg [31:0] posbus_i[31:0];
wire [32*12-1:0] extbus_i = 0;

// Outputs
wire [31:0] ERR_STATUS;
wire dma_fifo_reset_o;
wire [31:0] pcap_dat_o;
wire pcap_dat_valid_o;
wire pcap_done_o;
wire pcap_actv_o;
wire [2:0] pcap_status_o;

wire [32*32-1 : 0] posbus;


// Instantiate the Unit Under Test (UUT)
pcap_core_wrapper uut (
    .clk_i              ( clk_i             ),
    .reset_i            ( reset_i           ),
    .ARM                ( ARM               ),
    .DISARM             ( DISARM            ),
    .START_WRITE        ( START_WRITE       ),
    .WRITE              ( WRITE             ),
    .WRITE_WSTB         ( WRITE_WSTB        ),
    .FRAMING_MASK       ( FRAMING_MASK      ),
    .FRAMING_ENABLE     ( FRAMING_ENABLE    ),
    .FRAMING_MODE       ( FRAMING_MODE      ),
    .ERR_STATUS         ( ERR_STATUS        ),
    .enable_i           ( enable_i          ),
    .capture_i          ( capture_i         ),
    .frame_i            ( frame_i           ),
    .dma_full_i         ( 1'b0              ),
    .sysbus_i           ( 128'h0) , //sysbus_i          ),
    .posbus_i           ( posbus            ),
    .extbus_i           ( extbus_i          ),
//    .dma_fifo_reset_o   ( dma_fifo_reset_o  ),
    .pcap_dat_o         ( pcap_dat_o        ),
    .pcap_dat_valid_o   ( pcap_dat_valid_o  ),
    .pcap_done_o        ( pcap_done_o       ),
    .pcap_actv_o        ( pcap_actv_o       ),
    .pcap_status_o      ( pcap_status_o     )
);

// Testbench specific
integer timestamp = 0;

// Clock and Reset
always #4 clk_i = !clk_i;

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

//
// Read Bus Inputs
//
initial
begin : bus_inputs
    localparam filename = "pcap_bus_in.txt";
    localparam N        = 5;
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
            frame_i = vectors[3];
            capture_i = vectors[4];
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
    localparam filename = "pcap_reg_in.txt";
    localparam N        = 15;
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
            START_WRITE = vectors[1];
            WRITE = vectors[3];
            WRITE_WSTB = vectors[4];
            FRAMING_MASK = vectors[5];
            FRAMING_ENABLE = vectors[7];
            FRAMING_MODE = vectors[9];
            ARM = vectors[12];      // wstb
            DISARM = vectors[14];   // wstb
        end
    end
join

end


//
// Read Bus Outputs
//
reg         ACTIVE;
reg [31:0]  DATA;
reg         DATA_WSTB;
reg [31:0]  ERROR;

initial
begin : bus_outputs
    localparam filename = "pcap_bus_out.txt";
    localparam N        = 5;
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
            ACTIVE = vectors[1];
            DATA   = vectors[2];
            DATA_WSTB = vectors[3];
            ERROR = vectors[4];
        end
    end
join

end

//
// Read Position Bus
//
integer i;

initial
begin : pos_inputs
    localparam filename = "pcap_pos_bus.txt";
    localparam N        = 33;
    reg [31:0] vectors[N-1: 0];

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
            for (i = 1; i < 33 ; i = i+1) begin
                posbus_i[i-1] = vectors[i];
            end
        end
    end
join

end

//
// Read Bit Bus
//
//integer i;
//
//initial
//begin : bit_inputs
//    localparam filename = "pcap_pos_bus.txt";
//    localparam N        = 33;
//    reg [31:0] vectors[31: 0];
//
//    reg     [8192*2*10:0] line;
//    integer          file, c, r, i;
//    reg     [31: 0]  TS;
//
//fork
//    begin
//        `include "./file_io.v"
//    end
//
//    begin
//        while (1) begin
//            @(posedge clk_i);
//            for (i = 1; i < 32 ; i = i+1) begin
//                posbus_i[i-1] = vectors[i];
//            end
//        end
//    end
//join
//
//end


assign posbus[0 * 32 + 31  : 32 * 0 ] = posbus_i[0];
assign posbus[1 * 32 + 31  : 32 * 1 ] = posbus_i[1];
assign posbus[2 * 32 + 31  : 32 * 2 ] = posbus_i[2];
assign posbus[3 * 32 + 31  : 32 * 3 ] = posbus_i[3];
assign posbus[4 * 32 + 31  : 32 * 4 ] = posbus_i[4];
assign posbus[5 * 32 + 31  : 32 * 5 ] = posbus_i[5];
assign posbus[6 * 32 + 31  : 32 * 6 ] = posbus_i[6];
assign posbus[7 * 32 + 31  : 32 * 7 ] = posbus_i[7];
assign posbus[8 * 32 + 31  : 32 * 8 ] = posbus_i[8];
assign posbus[9 * 32 + 31  : 32 * 9 ] = posbus_i[9];
assign posbus[10 * 32 + 31 : 32 * 10] = posbus_i[10];
assign posbus[11 * 32 + 31 : 32 * 11] = posbus_i[11];
assign posbus[12 * 32 + 31 : 32 * 12] = posbus_i[12];
assign posbus[13 * 32 + 31 : 32 * 13] = posbus_i[13];
assign posbus[14 * 32 + 31 : 32 * 14] = posbus_i[14];
assign posbus[15 * 32 + 31 : 32 * 15] = posbus_i[15];
assign posbus[16 * 32 + 31 : 32 * 16] = posbus_i[16];
assign posbus[17 * 32 + 31 : 32 * 17] = posbus_i[17];
assign posbus[18 * 32 + 31 : 32 * 18] = posbus_i[18];
assign posbus[19 * 32 + 31 : 32 * 19] = posbus_i[19];
assign posbus[20 * 32 + 31 : 32 * 20] = posbus_i[20];
assign posbus[21 * 32 + 31 : 32 * 21] = posbus_i[21];
assign posbus[22 * 32 + 31 : 32 * 22] = posbus_i[22];
assign posbus[23 * 32 + 31 : 32 * 23] = posbus_i[23];
assign posbus[24 * 32 + 31 : 32 * 24] = posbus_i[24];
assign posbus[25 * 32 + 31 : 32 * 25] = posbus_i[25];
assign posbus[26 * 32 + 31 : 32 * 26] = posbus_i[26];
assign posbus[27 * 32 + 31 : 32 * 27] = posbus_i[27];
assign posbus[28 * 32 + 31 : 32 * 28] = posbus_i[28];
assign posbus[29 * 32 + 31 : 32 * 29] = posbus_i[29];
assign posbus[30 * 32 + 31 : 32 * 30] = posbus_i[30];
assign posbus[31 * 32 + 31 : 32 * 31] = posbus_i[31];



endmodule

