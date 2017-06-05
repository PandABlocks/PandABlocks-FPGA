`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000


module panda_pcomp_tb;

// Inputs
reg         clk_i = 0;
reg         reset_i;
reg         enable_i;
reg [31: 0] posn_i;
wire [63: 0] table_posn;


integer timestamp = 0;

reg             SIM_RESET;
reg             ENABLE;
reg  [31: 0]    INP;
reg  [31: 0]    START;
reg  [31: 0]    STEP;
reg  [31: 0]    WIDTH;
reg  [31: 0]    PNUM;
reg             RELATIVE;
reg             DIR;
reg  [31: 0]    DELTAP;
reg             USE_TABLE;
reg  [31: 0]    TABLE_ADDRESS;
reg  [31: 0]    TABLE_LENGTH;
reg             ACTIVE;
reg             OUT;
reg             ERROR;
reg  [31: 0]    TABLE_STATUS;
reg             TABLE_LENGTH_WSTB; 
wire  [31: 0]   STATUS;
wire            table_pos;

// Outputs
wire [31: 0]    err0_o;
wire            act0_o;
wire            pulse0_o;
wire [31: 0]    err1_o;
wire            act1_o;
wire            pulse1_o;

wire            table_read;
wire            table_end;
wire            dma_req;    
wire [31: 0]    dma_addr;
wire [7: 0]     dma_len;

reg             test_result = 0;
 
integer fid[3:0];
integer r[3:0];

//
// Values in the test files are arranged on FPGA clock ticks on the
// first column. This way all files are read syncronously.
//
// To achieve that a free running global Timestamp Counter below
// is used.
//

initial begin
    repeat (5) @(posedge clk_i);
    while (1) begin
        timestamp <= timestamp + 1;
        @(posedge clk_i);
    end
end


// Clock and Reset
always #4 clk_i = !clk_i;


// pcomp_bus_in.txt
// TS ####### SIM_RESET ###### ENABLE ###### INP

//
// READ BLOCK INPUTS VECTOR FILE
//
integer bus_in[3:0];     // TS SET RST

initial begin
    SIM_RESET = 0;
    ENABLE = 0;
    INP = 0;

    @(posedge clk_i);
    fid[0] = $fopen("pcomp_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s\n", bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d\n", bus_in[3],  bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[3]) begin
            SIM_RESET <= bus_in[2];
            ENABLE <= bus_in[1];
            INP <= bus_in[0];
        end
        @(posedge clk_i);
    end
end


// pcomp_bus_out.txt
// TS ###### ACTIVE ###### OUT

//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
integer bus_out[2:0];
reg     is_file_end;

initial begin
    ACTIVE = 0;
    OUT = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("pcomp_bus_out.txt", "r"); // TS, VAL

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s %s\n", bus_out[2], bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d %d \n", bus_out[2], bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[2]) begin
            ACTIVE = bus_out[1];
            OUT = bus_out[0];
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

    is_file_end = 1;
end


// pcomp_reg_out.txt
// TS ###### ERROR ###### TABLE_STATUS

integer reg_out[2:0];
reg     is_2file_end;

initial begin
    ERROR = 0;
    TABLE_STATUS = 0;
    is_2file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[3] = $fopen("pcomp_bus_out.txt", "r"); // TS, VAL

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s %s\n", reg_out[2], reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d %d \n", reg_out[2], reg_out[1], reg_out[0]);
        wait (timestamp == reg_out[2]) begin
            ERROR = reg_out[1];
            TABLE_STATUS = reg_out[0];
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

    is_2file_end = 1;
end


// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i) //----------------------------------------- HERE 
    if (is_file_end & is_2file_end) begin
        $stop(2);
    end    


//pcomp_reg_in.txt
// TS ###### START ###### STEP ###### WDITH ###### PNUM ###### RELATIVE ###### DIR ###### DELTAP ###### USE_TABLE ###### TABLE_ADDRESS ######TABLE_LENGTH
integer reg_in[10:0];

initial begin
    START = 0;
    STEP = 0;
    WIDTH = 0;
    PNUM = 0;
    RELATIVE = 0;
    DIR = 0;
    DELTAP = 0;
    USE_TABLE = 0;
    TABLE_ADDRESS = 0;
    TABLE_LENGTH = 0;

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("pcomp_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s %s %s %s %s\n", reg_in[10], reg_in[9], reg_in[8], 
            reg_in[7], reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d %d %d %d %d\n", reg_in[10], reg_in[9], reg_in[8], 
              reg_in[7], reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[10]) begin
            START = reg_in[9];
            STEP = reg_in[8];
            WIDTH = reg_in[7];
            PNUM = reg_in[6];
            RELATIVE = reg_in[5];
            DIR = reg_in[4];
            DELTAP = reg_in[3];
            USE_TABLE = reg_in[2];
            TABLE_ADDRESS = reg_in[1];
            TABLE_LENGTH = reg_in[0];
        end
        @(posedge clk_i);
    end
end


//
// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//
always @(posedge clk_i)
begin
    if (~is_file_end) begin
        if (ERROR != err0_o) begin
          test_result = 1;
          $display("ERROR detected %d\n", timestamp);
        end   
    end
end


// Instantiate the Unit Under Test (UUT)
pcomp uut0 (
    .clk_i              ( clk_i             ),
    .reset_i            ( reset_i           ),
    .enable_i           ( ENABLE            ),    
    .posn_i             ( INP               ),
    .START              ( START             ),
    .STEP               ( STEP              ),    
    .WIDTH              ( WIDTH             ),    
    .NUM                ( PNUM              ),
    .RELATIVE           ( RELATIVE          ),    
    .DIR                ( DIR               ),
    .DELTAP             ( DELTAP            ),
    .act_o              ( act0_o            ),
    .err_o              ( err0_o            ),
    .out_o              ( pulse0_o          ),
    .table_posn_i       ( table_posn        ),
    .table_read_o       ( table_read        ), ///////////////
    .table_end_i        ( table_end         ),
    .USE_TABLE          ( USE_TABLE         )
);

//pcomp uut1 (
//    .clk_i              ( clk_i             ),
//    .reset_i            ( reset_i           ),
//    .enable_i           ( enable_i          ),
//    .posn_i             ( posn_i            ),
//    .START              ( 4000              ),
//    .STEP               ( 100               ),
//    .WIDTH              ( 50                ),
//    .NUM                ( 100               ),
//    .RELATIVE           ( 1'b0              ),
//    .DIR                ( 1'b1              ),
//    .DELTAP             ( 100               ),
//    .act_o              ( act1_o            ),
//    .err_o              ( err1_o            ),
//    .out_o              ( pulse1_o          ),
//    .table_posn_i       ( 64'h0             ),
//    .table_read_o       ( table_read        ), ///////////////
//    .table_end_i        ( 1'b0              ), /////////////// 
//    .USE_TABLE          ( 1'b0              )
//);


pcomp_table uut2 (
    .clk_i              ( clk_i             ), //
    .enable_i           ( ENABLE            ),
    .trig_i             ( table_read        ), //
    .out_o              ( table_posn        ),
    .table_end_o        ( table_end         ),
    
    .CYCLES             ( 32'h1             ), // -------?
    .TABLE_ADDR         ( TABLE_ADDRESS     ),
    .TABLE_LENGTH       ( TABLE_LENGTH      ),
    .TABLE_LENGTH_WSTB  ( TABLE_LENGTH_WSTB ), //
    .STATUS             ( STATUS            ),
    .dma_req_o          ( dma_req           ), // output pcomp_block
    .dma_ack_i          ( 1'b0              ), // input pcomp_block
    .dma_done_i         ( 1'b0              ), // input pcomp_block
    .dma_addr_o         ( dma_addr          ), // output pcomp_block
    .dma_len_o          ( dma_len           ), // output pcomp_block 
    .dma_data_i         ( 32'h0             ), // input pcomp_block
    .dma_valid_i        ( 1'b0              )  // input pcomp_block
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

