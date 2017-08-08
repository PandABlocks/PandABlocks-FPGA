`timescale 1ns / 1ps

module panda_counter_tb;

reg clk_i = 0;
always #4 clk_i = ~clk_i;

integer timestamp = 0;

// Inputs
reg        SIM_RESET;
reg        ENABLE;
reg        TRIG;
reg        DIR;
reg        DIR_WSTB;
reg [31:0] START;
reg        START_WSTB;
reg [31:0] STEP;
reg        STEP_WSTB;
reg        CARRY;
reg [31:0] OUT;   
reg        err;
reg        test_result;

// Outputs
wire [31:0] out;
wire        carry;

//integer fid[3:0];
//integer r[3:0];
integer fid[2:0];
integer r[2:0];


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

//
// READ BLOCK INPUTS VECTOR FILE
//
integer bus_in[3:0];     // TS, SET, ENABLE, TRIG
initial begin
    SIM_RESET = 0;
    ENABLE = 0;
    TRIG = 0;

    @(posedge clk_i);
    fid[0] = $fopen("counter_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s\n", bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d\n", bus_in[3],  bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[3]) begin
            SIM_RESET = bus_in[2];
            ENABLE = bus_in[1];
            TRIG = bus_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK REGISTERS VECTOR FILE
//
integer reg_in[6:0];     // TS, DIR, DIR_WSTB, START, START_WSTB, STEP, STEP_WSTB 

initial begin
    DIR = 0;
    DIR_WSTB = 0;
    START = 0;
    START_WSTB = 0;
    STEP = 0;
    STEP_WSTB = 0;

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("counter_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s\n", reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d\n", reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[6]) begin  
            DIR = reg_in[5];
            DIR_WSTB = reg_in[4];            
            START = reg_in[3];
            START_WSTB = reg_in[2];            
            STEP = reg_in[1];
            STEP_WSTB = reg_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
integer bus_out[2:0];
reg     is_file_end;

initial begin
    CARRY = 0;
    OUT = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("counter_bus_out.txt", "r"); // TS, CARRY,  OUT   

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s %s\n", bus_out[2], bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d %d\n", bus_out[2], bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[2]) begin
            CARRY = bus_out[1];
            OUT = bus_out[0];
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

    is_file_end = 1;
end

//
// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//
always @(posedge clk_i)
begin
    if (~is_file_end) begin
        if (ENABLE == 1) begin
            // If not equal, display an error.
            if (out != OUT) begin
                $display("OUT error detected at timestamp %d\n", timestamp);
                err = 1;
                test_result = 1;
            end 
        end
    end
end


// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i) //----------------------------------------- HERE 
    if (is_file_end) begin
        $stop(2);
    end  


// Instantiate the Unit Under Test (UUT)
//panda_srgate uut (
counter uut (
        .clk_i              ( clk_i             ),
        .enable_i           ( ENABLE            ),
        .trigger_i          ( TRIG              ),
        .carry_o            ( carry             ),
        .DIR                ( DIR               ),
        .START              ( START             ),
        .START_LOAD         ( START_WSTB        ),
        .STEP               ( STEP              ),
        .STEP_WSTB          ( STEP_WSTB         ),
        .out_o              ( out               )
);

endmodule

