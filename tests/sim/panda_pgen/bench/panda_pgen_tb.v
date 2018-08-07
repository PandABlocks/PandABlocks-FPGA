`timescale 1ns / 1ps

module panda_pgen_tb;

reg clk_i = 0;
always #4 clk_i = ~clk_i;

integer timestamp = 0;

// Inputs
reg        SIM_RESET;
reg        ENABLE;
reg        TRIG;
reg [31:0] CYCLES = 0;
reg        CYCLES_WSTB;
reg [31:0] TABLE_ADDRESS;
reg        TABLE_ADDRESS_WSTB;
reg [31:0] TABLE_LENGTH = 0;
reg        TABLE_LENGTH_WSTB;
reg [31:0] TABLE_STATUS;
reg [31:0] OUT;

wire [31:0] status;
wire [31:0] out;       
wire        dma_req; 
wire [31:0] dma_addr;       
wire [7: 0] dma_len;
wire [31:0] dma_data = 0;

reg        err = 0;
reg        test_result = 0;


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

//
// READ BLOCK INPUTS VECTOR FILE
//
integer bus_in[3:0];     // TS, SET, ENABLE, TRIG
initial begin
    SIM_RESET = 0;
    ENABLE = 0;
    TRIG = 0;

    @(posedge clk_i);
    fid[0] = $fopen("pgen_bus_in.txt", "r");

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
    CYCLES = 0;
    CYCLES_WSTB = 0;
    TABLE_ADDRESS = 0;
    TABLE_ADDRESS_WSTB = 0;
    TABLE_LENGTH = 0;
    TABLE_LENGTH_WSTB = 0;
    
    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("pgen_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s\n", reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d\n", reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[6]) begin  
            CYCLES = reg_in[5];
            CYCLES_WSTB = reg_in[4];
            TABLE_ADDRESS = reg_in[3];
            TABLE_ADDRESS_WSTB = reg_in[2];
            TABLE_LENGTH = reg_in[1];
            TABLE_LENGTH_WSTB = reg_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
integer bus_out[1:0];
reg     is_file_end;

initial begin
    OUT = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("pgen_bus_out.txt", "r"); // TS, OUT   

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s\n", bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d\n", bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[1]) begin
            OUT = bus_out[0];
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
integer reg_out[1:0];

initial begin
    OUT = 0;

    @(posedge clk_i);

    // Open "reg_out" file
    fid[3] = $fopen("pgen_reg_out.txt", "r"); // TS, OUT   

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s\n", reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d\n", reg_out[1], reg_out[0]);
        wait (timestamp == reg_out[1]) begin
            TABLE_STATUS = reg_out[0];
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);
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
pgen uut (
        .clk_i              ( clk_i             ),
        .enable_i           ( ENABLE            ),
        .trig_i             ( TRIG              ),
        .out_o              ( out               ),
        .CYCLES             ( CYCLES            ),
        .TABLE_ADDR         ( TABLE_ADDRESS     ),
        .TABLE_LENGTH       ( TABLE_LENGTH      ),
        .TABLE_LENGTH_WSTB  ( TABLE_LENGTH_WSTB ),
        .STATUS             ( status            ),
        .dma_req_o          ( dma_req           ),
        .dma_ack_i          ( 0'b0              ),
        .dma_done_i         ( 0'b0              ),
        .dma_addr_o         ( dma_addr          ),
        .dma_len_o          ( dma_len           ),
        .dma_data_i         ( dma_data          ),
        .dma_valid_i        ( 0'b0              )
);

endmodule

