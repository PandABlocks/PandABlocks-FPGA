`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000


module panda_pcomp_tb;

// Inputs
reg         clk_i = 0;

integer timestamp = 0;

reg             SIM_RESET;
reg             ENABLE;
reg  [31: 0]    INP;
reg  [31: 0]    START;
reg 			START_WSTB;
reg  [31: 0]    STEP;
reg				STEP_WSTB;
reg  [31: 0]    WIDTH;
reg				WIDTH_WSTB;
reg  [31: 0]    PNUM;
reg 			PNUM_WSTB;
reg             RELATIVE;
reg				RELATIVE_WSTB;
reg             DIR;
reg				DIR_WSTB;
reg  [31: 0]    DELTAP;
reg 			DELTAP_WSTB;
reg             ACTIVE;
reg             OUT;
reg             ERROR;

// Outputs
wire [31: 0]    err;
wire            act;
wire            out;

wire            table_read;   

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
// TS ###### ERROR ###### 

integer reg_out[1:0];
reg     is_2file_end;

initial begin
    ERROR = 0;
    is_2file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[3] = $fopen("pcomp_reg_out.txt", "r"); // TS, VAL

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s\n", reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d\n", reg_out[1], reg_out[0]);
        wait (timestamp == reg_out[1]) begin
            ERROR = reg_out[0];
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
integer reg_in[14:0];

initial begin
    START = 0;
    START_WSTB = 0;
    STEP = 0;
    STEP_WSTB = 0;
    WIDTH = 0;
    WIDTH_WSTB = 0;
    PNUM = 0;
    PNUM_WSTB = 0;
    RELATIVE = 0;
    RELATIVE_WSTB = 0;
    DIR = 0;
    DIR_WSTB = 0;
    DELTAP = 0;
    DELTAP_WSTB = 0;

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("pcomp_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s\n", reg_in[14], reg_in[13], 
            reg_in[12], reg_in[11], reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], reg_in[5], 
            reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n", reg_in[14], reg_in[13], 
            reg_in[12], reg_in[11], reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], reg_in[5], 
            reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[14]) begin
            START = reg_in[13];
            START_WSTB = reg_in[12];
            STEP = reg_in[11];
            STEP_WSTB = reg_in[10];
            WIDTH = reg_in[9];
            WIDTH_WSTB = reg_in[8];
            PNUM = reg_in[7];
            PNUM_WSTB = reg_in[6];
            RELATIVE = reg_in[5];
            RELATIVE_WSTB = reg_in[4];
            DIR = reg_in[3];
            DIR_WSTB = reg_in[2];
            DELTAP = reg_in[1];
            DELTAP_WSTB = reg_in[0];

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
        if (ACTIVE != act) begin
            test_result = 1;
            $display("ERROR active strobes different %d\n", timestamp);
        end     
        if (out != OUT) begin
            test_result = 1;
            $display("ERROR outputs are different %d\n", timestamp);       
        end   
        if (ERROR != err[0]) begin
            test_result = 1;
            $display("ERROR, error strobe outputs are different %d\n", timestamp);
        end 
    end
end


// Instantiate the Unit Under Test (UUT)
pcomp uut_pcomp (
    .clk_i              ( clk_i             ),
    .reset_i            ( SIM_RESET         ),
    .enable_i           ( ENABLE            ),    
    .posn_i             ( INP               ),
    .START              ( START             ),
    .STEP               ( STEP              ),    
    .WIDTH              ( WIDTH             ),    
    .NUM                ( PNUM              ),
    .RELATIVE           ( RELATIVE          ),    
    .DIR                ( DIR               ),
    .DELTAP             ( DELTAP            ),
    .act_o              ( act               ),
    .err_o              ( err               ),
    .out_o              ( out               ),
    .table_posn_i       ( 0'b0              ),
    .table_read_o       ( table_read        ), 
    .table_end_i        ( 0'b0              ),
    .USE_TABLE          ( 0'b0              )
);
    

endmodule

