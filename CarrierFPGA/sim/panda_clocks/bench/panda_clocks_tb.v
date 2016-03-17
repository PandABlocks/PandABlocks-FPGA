`timescale 1ns / 1ps

module panda_clocks_tb;

reg clk_i = 0;
always #4 clk_i = ~clk_i;

integer timestamp = 0;

// Inputs
reg         SIM_RESET;
reg [31: 0] A_PERIOD;
reg [31: 0] B_PERIOD;
reg [31: 0] C_PERIOD;
reg [31: 0] D_PERIOD;
reg         A;
reg         B;
reg         C;
reg         D;

// Outputs
wire        clocka_o;
wire        clockb_o;
wire        clockc_o;
wire        clockd_o;

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
// TS»¯¯¯¯¯SIM_RESET
integer bus_in[1:0];

initial begin
    SIM_RESET = 0;

    @(posedge clk_i);
    fid[0] = $fopen("clocks_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s\n", bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

    r[0] = $fscanf(fid[0], "%d %d\n", bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[1]) begin
            SIM_RESET <= bus_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK REGISTERS VECTOR FILE
//

// TS»¯¯¯¯¯A_PERIOD»¯¯¯¯¯¯¯B_PERIOD»¯¯¯¯¯¯¯C_PERIOD»¯¯¯¯¯¯¯D_PERIOD
integer reg_in[4:0];

initial begin
    A_PERIOD = 0;
    B_PERIOD = 0;
    C_PERIOD = 0;
    D_PERIOD = 0;

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("clocks_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s\n", reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d\n", reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[4]) begin
            A_PERIOD = reg_in[3];
            B_PERIOD = reg_in[2];
            C_PERIOD = reg_in[1];
            D_PERIOD = reg_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
integer bus_out[4:0];
reg     is_file_end;

initial begin
    A = 0;
    B = 0;
    C = 0;
    D = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("clocks_bus_out.txt", "r");

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s %s %s %s\n", bus_out[4], bus_out[3], bus_out[2], bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d %d %d %d\n", bus_out[4], bus_out[3], bus_out[2], bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[4]) begin
            A = bus_out[3];
            B = bus_out[2];
            C = bus_out[1];
            D = bus_out[0];
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
        if (clocka_o != A) begin
            $display("A error detected at timestamp %d\n", timestamp);
            $finish(2);
        end
        if (clockb_o != B) begin
            $display("B error detected at timestamp %d\n", timestamp);
            $finish(2);
        end
        if (clockc_o != C) begin
            $display("C error detected at timestamp %d\n", timestamp);
            $finish(2);
        end
        if (clockd_o != D) begin
            $display("D error detected at timestamp %d\n", timestamp);
            $finish(2);
        end
    end
end

// Instantiate the Unit Under Test (UUT)
panda_clocks uut (
        .clk_i          ( clk_i             ),
        .reset_i        ( SIM_RESET         ),

        .clocka_o       ( clocka_o          ),
        .clockb_o       ( clockb_o          ),
        .clockc_o       ( clockc_o          ),
        .clockd_o       ( clockd_o          ),

        .CLOCKA_DIV     ( A_PERIOD          ),
        .CLOCKB_DIV     ( B_PERIOD          ),
        .CLOCKC_DIV     ( C_PERIOD          ),
        .CLOCKD_DIV     ( D_PERIOD          )
);


endmodule

