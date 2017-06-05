`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000


module pcap_core_2tb;

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

integer fid[3:0];

integer r[3:0];


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
// READ BLOCK INPUTS VECTOR FILE
//
// TS»¯¯¯¯¯RESET»¯¯¯¯¯¯ENABLE»¯¯¯¯FRAME»¯¯¯¯CAPTURE
integer bus_in[4:0];

initial begin
    reset_i = 0;
    enable_i = 0;
    frame_i = 0;
    capture_i = 0;

    @(posedge clk_i);
    fid[0] = $fopen("pcap_bus_in.txt", "r");
    
    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s %s\n", bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d %d\n", bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[4]) begin
            // TS	SIM_RESET TRIG INP ENABLE
            reset_i <= bus_in[3];
            enable_i <= bus_in[2];
            frame_i <= bus_in[1];
            capture_i <= bus_in[0];
        end
        @(posedge clk_i);
    end
end


//
// READ BLOCK REGISTERS VECTOR FILE
//
// TS»¯¯¯¯¯
integer reg_in[53:0];

initial begin
    START_WRITE    = 0;
    WRITE          = 0;
    WRITE_WSTB     = 0;
    FRAMING_MASK   = 0;
    FRAMING_ENABLE = 0;
    FRAMING_MODE   = 0;
    ARM            = 0;
    DISARM         = 0;     

    @(posedge clk_i);

    // Open "reg_in" file
     fid[1] = $fopen("pcap_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s \n", 
    reg_in[53], reg_in[52], reg_in[51], reg_in[50], reg_in[49], reg_in[48], reg_in[47], reg_in[46], reg_in[45], reg_in[44], reg_in[43], reg_in[42], reg_in[41], reg_in[40], reg_in[39], reg_in[38], 
    reg_in[37], reg_in[36], reg_in[35], reg_in[34], reg_in[33], reg_in[32], reg_in[31], reg_in[30], reg_in[29], reg_in[28], reg_in[27], reg_in[26], reg_in[25], reg_in[24], reg_in[23], reg_in[22], 
    reg_in[21], reg_in[20], reg_in[19], reg_in[18], reg_in[17], reg_in[16], reg_in[15], reg_in[14], reg_in[13], reg_in[12], reg_in[11], reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], 
    reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d \n", 
        reg_in[53], reg_in[52], reg_in[51], reg_in[50], reg_in[49], reg_in[48], reg_in[47], reg_in[46], reg_in[45], reg_in[44], reg_in[43], reg_in[42], reg_in[41], reg_in[40], reg_in[39], reg_in[38], 
        reg_in[37], reg_in[36], reg_in[35], reg_in[34], reg_in[33], reg_in[32], reg_in[31], reg_in[30], reg_in[29], reg_in[28], reg_in[27], reg_in[26], reg_in[25], reg_in[24], reg_in[23], reg_in[22], 
        reg_in[21], reg_in[20], reg_in[19], reg_in[18], reg_in[17], reg_in[16], reg_in[15], reg_in[14], reg_in[13], reg_in[12], reg_in[11], reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], 
        reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]); 
        
        wait (timestamp == reg_in[85])begin              
            START_WRITE = reg_in[52];        
            WRITE = reg_in[50];
            WRITE_WSTB = reg_in[49];
            FRAMING_MASK = reg_in[48];
            FRAMING_ENABLE = reg_in[46];
            FRAMING_MODE = reg_in[44];
            ARM = reg_in[41];
            DISARM = reg_in[39];
        end
        @(posedge clk_i);
    end
end


//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
// TS»¯¯¯¯¯ACTIVE»¯¯¯¯¯DATA»¯¯¯¯¯DATA_WSTB»¯¯¯¯¯ERROR»
integer bus_out[4:0];
reg         is_file_end;
reg         ACTIVE;
reg         DATA;
reg         DATA_WSTB;
reg [31:0]  ERROR;

initial begin
    ACTIVE      = 0;
    DATA        = 0;
    DATA_WSTB   = 0;
    ERROR       = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("pcap_bus_out.txt", "r"); // TS»¯¯¯¯¯OUT»¯¯¯READY

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s %s %s %s\n", bus_out[4], bus_out[3], bus_out[2], bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d %d %d %d\n", bus_out[4], bus_out[3], bus_out[2], bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[4]) begin
            ACTIVE = bus_out[3];
            DATA = bus_out[2];
            DATA_WSTB = bus_out[1];
            ERROR = bus_out[0];
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

    is_file_end = 1;
end



//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
// TS»¯¯¯¯¯ACTIVE»¯¯¯¯¯DATA»¯¯¯¯¯DATA_WSTB»¯¯¯¯¯ERROR»
integer posbus_in[32:0];

integer i;

initial begin
    ACTIVE      = 0;
    DATA        = 0;
    DATA_WSTB   = 0;
    ERROR       = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[3] = $fopen("pcap_pos_bus.txt", "r"); // TS»¯¯¯¯¯OUT»¯¯¯READY

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s \n", 
    posbus_in[32], posbus_in[31], posbus_in[30], posbus_in[29], posbus_in[28], posbus_in[27], posbus_in[26], posbus_in[25], posbus_in[24], posbus_in[23], 
    posbus_in[22], posbus_in[21], posbus_in[20], posbus_in[19], posbus_in[18], posbus_in[17], posbus_in[16], posbus_in[15], posbus_in[14], posbus_in[13], 
    posbus_in[12], posbus_in[11], posbus_in[10], posbus_in[9], posbus_in[8], posbus_in[7], posbus_in[6], posbus_in[5], posbus_in[4], posbus_in[3], posbus_in[2], 
    posbus_in[1], posbus_in[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d \n", 
        posbus_in[32], posbus_in[31], posbus_in[30], posbus_in[29], posbus_in[28], posbus_in[27], posbus_in[26], posbus_in[25], posbus_in[24], posbus_in[23], 
        posbus_in[22], posbus_in[21], posbus_in[20], posbus_in[19], posbus_in[18], posbus_in[17], posbus_in[16], posbus_in[15], posbus_in[14], posbus_in[13], 
        posbus_in[12], posbus_in[11], posbus_in[10], posbus_in[9], posbus_in[8], posbus_in[7], posbus_in[6], posbus_in[5], posbus_in[4], posbus_in[3], posbus_in[2], 
        posbus_in[1], posbus_in[0]);
        
        wait (timestamp == posbus_in[32]) begin
            for (i = 1; i < 32 ; i = i+1) begin
              posbus_i[i-1] = posbus_in[i]; 
            end   
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

end


// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i) //----------------------------------------- HERE 
    if (is_file_end) begin
        $stop(2);
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

