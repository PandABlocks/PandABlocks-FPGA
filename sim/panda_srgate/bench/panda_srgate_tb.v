`timescale 1ns / 1ps

module panda_srgate_tb;

reg clk_i = 0;
always #4 clk_i = ~clk_i;

integer timestamp = 0;

// Inputs
reg     SIM_RESET;
reg     SET;
reg     RESET;
reg     SET_EDGE;
reg     RST_EDGE;
reg     FORCE_SET;
reg     FORCE_RST;
reg     VAL;

// Outputs
wire out_o;

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
integer bus_in[3:0];     // TS SET RST
initial begin
    SIM_RESET = 0;
    SET = 0;
    RESET = 0;

    @(posedge clk_i);
    fid[0] = $fopen("srgate_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s\n", bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d\n", bus_in[3],  bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[3]) begin
            SIM_RESET <= bus_in[2];
            SET <= bus_in[1];
            RESET <= bus_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK REGISTERS VECTOR FILE
//
integer reg_in[4:0];     // TS, SET_EDGE, RST_EDGE, FORCE_SET, FORCE_RST

initial begin
    SET_EDGE = 0;
    RST_EDGE = 0;
    FORCE_SET = 0;
    FORCE_RST = 0;

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("srgate_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s\n", reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d\n", reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[4]) begin
            SET_EDGE = reg_in[3];
            RST_EDGE = reg_in[2];
            FORCE_SET = reg_in[1];
            FORCE_RST = reg_in[0];
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
    VAL = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("srgate_bus_out.txt", "r"); // TS, VAL

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s\n", bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d \n", bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[1]) begin
            VAL = bus_out[0];
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
        // If not equal, display an error.
        if (out_o != VAL) begin
            $display("OUT error detected at timestamp %d\n", timestamp);
            $finish(2);
        end
   end
end

// Instantiate the Unit Under Test (UUT)
panda_srgate uut (
        .clk_i          ( clk_i             ),
        .reset_i        ( SIM_RESET         ),
        .set_i          ( SET               ),
        .rst_i          ( RESET             ),
        .out_o          ( out_o             ),
        .SET_EDGE       ( SET_EDGE          ),
        .RST_EDGE       ( RST_EDGE          ),
        .FORCE_SET      ( FORCE_SET         ),
        .FORCE_RST      ( FORCE_RST         )
);

endmodule

