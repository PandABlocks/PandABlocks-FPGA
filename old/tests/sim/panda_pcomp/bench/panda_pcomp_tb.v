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

reg  [31: 0]    PRE_START;
reg 			PRE_START_WSTB;
reg  [31: 0]    START;
reg				START_WSTB;
reg  [31: 0]    WIDTH;
reg				WIDTH_WSTB;
reg  [31: 0]    STEP;
reg 			STEP_WSTB;   
reg  [31: 0]    PULSES;
reg				PULSES_WSTB;
reg             RELATIVE;
reg				RELATIVE_WSTB;
reg  [1: 0]     DIR;
reg 			DIR_WSTB;
reg  [1: 0]     HEALTH;
reg  [31: 0]    PRODUCED;
reg  [2: 0]     STATE;
reg             ACTIVE;
reg             OUT;

reg             active_failed;
reg             out_failed;
reg             health_failed;
reg             produced_failed;
reg             state_failed =0;

reg             ACTIVE_DLY;
reg  [7: 0]     COUNT_TESTS = 0;

// Outputs
wire [1: 0]     health;
wire [31: 0]    produced;
wire [2: 0]     state;
wire            act;
wire            out;


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
// TS ###### HEALTH ###### PRODUCED ###### STATE  

integer reg_out[3:0];
reg     is_2file_end;

initial begin
    HEALTH = 0;
    PRODUCED = 0;
    STATE = 0;
    is_2file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[3] = $fopen("pcomp_reg_out.txt", "r"); // TS, VAL

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s %s %s\n", reg_out[3], reg_out[2], reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d %d %d\n", reg_out[3], reg_out[2], reg_out[1], reg_out[0]);
        wait (timestamp == reg_out[3]) begin
            HEALTH = reg_out[2];
            PRODUCED = reg_out[1];
            STATE = reg_out[0];
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
// TS ###### PRE_START ###### START ###### WDITH ###### STEP ###### PULSES ###### RELATIVE ###### DIR ###### DELTAP --- WHAT ABOUT DELTAP??
integer reg_in[14:0];

initial begin
    PRE_START = 0;
    PRE_START_WSTB = 0;
    START = 0;
    START_WSTB = 0;
    WIDTH = 0;
    WIDTH_WSTB = 0;
    STEP = 0;
    STEP_WSTB = 0;
    PULSES = 0;
    PULSES_WSTB = 0;
    RELATIVE = 0;
    RELATIVE_WSTB = 0;
    DIR = 0;
    DIR_WSTB = 0;

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
            PRE_START = reg_in[13];
            PRE_START_WSTB = reg_in[12];
            START = reg_in[11];
            START_WSTB = reg_in[10];
            WIDTH = reg_in[9];
            WIDTH_WSTB = reg_in[8];
            STEP = reg_in[7];
            STEP_WSTB = reg_in[6];
            PULSES = reg_in[5];
            PULSES_WSTB = reg_in[4];
            RELATIVE = reg_in[3];
            RELATIVE_WSTB = reg_in[2];
            DIR = reg_in[1];
            DIR_WSTB = reg_in[0];

        end
        @(posedge clk_i);
    end
end


// Count tests
always @(posedge clk_i)
begin
    ACTIVE_DLY <= ACTIVE;
    if (ACTIVE_DLY == 0 & ACTIVE == 1) begin
        COUNT_TESTS <= COUNT_TESTS +1;
    end 
end          



//
// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//
always @(posedge clk_i)
begin
    if (~is_file_end) begin
        // Active strobes  
        if (ACTIVE != act) begin
            active_failed = 1;
            test_result = 1;
            $display("ERROR active strobes different %d\n", timestamp);
        end     
        else begin
            active_failed = 0;
        end     
        // Output active
        if (out != OUT) begin
            out_failed = 1;
            test_result = 1;
            $display("ERROR outputs are different %d\n", timestamp);       
        end
        else begin
            out_failed = 0;
        end        
        // Health 
        if (HEALTH != health) begin
            health_failed = 1;
            test_result = 1;
            $display("ERROR health outputs are different %d\n", timestamp);
        end
        else begin
            health_failed = 0;
        end 
        // Produced
        if (PRODUCED != produced) begin
            produced_failed = 1;
            test_result = 1;
            $display("ERROR produced outputs are different %d\n", timestamp);
        end 
        else begin
            produced_failed = 0;
        end     
        // State
        if (STATE != 0) begin
            if (STATE != state) begin
                state_failed = 1;
                test_result = 1;
                $display("ERROR state outputs are different %d\n", timestamp);
            end 
            else begin
                state_failed = 0;
            end    
        end                
    end
end

         

// Instantiate the Unit Under Test (UUT)
pcomp uut_pcomp (
    .clk_i              ( clk_i             ),
    .reset_i            ( SIM_RESET         ),
    .enable_i           ( ENABLE            ),    
    .posn_i             ( INP               ),
    .PRE_START          ( PRE_START         ),
    .START              ( START             ),    
    .WIDTH              ( WIDTH             ),    
    .STEP               ( STEP              ),
    .PULSES             ( PULSES            ),    
    .RELATIVE           ( RELATIVE          ),
    .DIR                ( DIR               ),
    .health_o           ( health            ),
    .produced_o         ( produced          ),
    .state_o            ( state             ),  
    .act_o              ( act               ),
    .out_o              ( out               )
);
    

endmodule

