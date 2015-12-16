//
// Testbench for panda_pulse.vhd
//
// The testbench reads input and register vectors from external files, and
// feeds to the panda_pulse block.
//
// The expected output results are read from external files and compared with
// the actual block outputs.
//
// Following files are used as test vectors:
//      pulse_bus_in.txt    : input port test vectors
//      pulse_reg_in.txt    : register test vectors
//      pulse_bus_out.txt   : expected output values
//      pulse_reg_out.txt   : expected status values
//
// Please look at the individual file to see how test vectors are organised.
//
// If there is a mismatch between the expected outputs, an error with timestamp
// information is printed on the screen.
//
`timescale 1ns / 1ps

module panda_pulse_tb;

// Inputs
reg         clk_i = 0;
reg         inp_i;
reg         rst_i;

reg [47: 0] DELAY;
reg [47: 0] WIDTH;
reg         FORCE_RST;

// Outputs
wire         out_o;
reg          out_expected;
wire         perr_o;
reg          perr_expected;

wire         ERR_OVERFLOW;
reg          ERR_OVERFLOW_EXPECTED;
wire         ERR_PERIOD;
reg          ERR_PERIOD_EXPECTED;
wire [10: 0] QUEUE;
reg  [10: 0] QUEUE_EXPECTED;
wire [31: 0] MISSED_CNT;
reg  [31: 0] MISSED_CNT_EXPECTED;



// Clock and Reset
always #4 clk_i = ~clk_i;

initial begin
    rst_i = 1;
    #100
    rst_i = 0;
end

// Instantiate Unit Under Test
panda_pulse uut (
    .clk_i          ( clk_i         ),
    .inp_i          ( inp_i         ),
    .rst_i          ( rst_i         ),
    .out_o          ( out_o         ),
    .perr_o         ( perr_o        ),
    .DELAY          ( DELAY         ),
    .WIDTH          ( WIDTH         ),
    .FORCE_RST      ( FORCE_RST     ),
    .ERR_OVERFLOW   ( ERR_OVERFLOW  ),
    .ERR_PERIOD     ( ERR_PERIOD    ),
    .QUEUE          ( QUEUE         ),
    .MISSED_CNT     ( MISSED_CNT    )
);

integer fid[3:0];
integer r[3:0];

//
// Values in the test files are arranged on FPGA clock ticks on the
// first column. This way all files are read syncronously.
//
// To achieve that a free running global Timestamp Counter below
// is used.
//
integer timestamp = 0;

initial begin
    @(posedge clk_i);
    @(posedge clk_i);
    while (1) begin
        timestamp <= timestamp + 1;
        @(posedge clk_i);
    end
end

//
// READ BLOCK INPUTS VECTOR FILE
//
integer bus_in[2:0];     // TS, INP, RESET;

initial begin
    inp_i = 0;
    rst_i = 0;

    @(posedge clk_i);
    fid[0] = $fopen("pulse_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s\n", bus_in[2], bus_in[1], bus_in[0]);

    // Read first timestamp
    r[0] = $fscanf(fid[0], "%d %d %d\n", bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin
        if (timestamp == bus_in[2]-1) begin
            inp_i <= bus_in[1];
            rst_i <= bus_in[0];
            r[0] = $fscanf(fid[0], "%d %d %d\n", bus_in[2], bus_in[1], bus_in[0]);
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK REGISTERS VECTOR FILE
//
integer reg_in[3:0];     // TS, DELAY, WIDTH, FORCE_RESET

initial begin
    DELAY = 0;
    WIDTH = 0;
    FORCE_RST = 0;

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("pulse_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s\n", reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    // Read first timestamp
    r[1] = $fscanf(fid[1], "%d %d %d %d\n", reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        if (timestamp == reg_in[3]-1) begin
            DELAY = reg_in[2];
            WIDTH = reg_in[1];
            FORCE_RST = reg_in[0];

            r[1] = $fscanf(fid[1], "%d %d %d %d\n", reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
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
    out_expected = 0;
    perr_expected = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("pulse_bus_out.txt", "r");

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s %s\n", bus_out[2], bus_out[1], bus_out[0]);

    // Read first timestamp
    r[2] = $fscanf(fid[2], "%d %d %d\n", bus_out[2], bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        if (timestamp == bus_out[2] - 1) begin
            out_expected = bus_out[1];
            perr_expected = bus_out[0];
            r[2] = $fscanf(fid[2], "%d %d %d\n", bus_out[2], bus_out[1], bus_out[0]);
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

    is_file_end = 1;
end

//
// READ BLOCK EXPECTED REGISTER OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
integer reg_out[4:0];
initial begin
    ERR_OVERFLOW_EXPECTED = 0;
    ERR_PERIOD_EXPECTED = 0;
    QUEUE_EXPECTED = 0;
    MISSED_CNT_EXPECTED = 0;

    @(posedge clk_i);

    // Open "reg_out" file
    fid[3] = $fopen("pulse_reg_out.txt", "r");

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s %s %s %s\n", reg_out[4], reg_out[3], reg_out[2], reg_out[1], reg_out[0]);

    // Read first timestamp
    r[3] = $fscanf(fid[3], "%d %d %d %d %d\n", reg_out[4], reg_out[3], reg_out[2], reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        if (timestamp == reg_out[4] - 1) begin
            ERR_OVERFLOW_EXPECTED <= reg_out[3];
            ERR_PERIOD_EXPECTED <= reg_out[2];
            QUEUE_EXPECTED <= reg_out[1];
            MISSED_CNT_EXPECTED <= reg_out[0];
            r[3] = $fscanf(fid[3], "%d %d %d %d %d\n", reg_out[4], reg_out[3], reg_out[2], reg_out[1], reg_out[0]);
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
        // If not equal, display an error.
        if (out_o != out_expected) begin
            $display("OUT error detected at timestamp %d\n", timestamp);
        end

        if (perr_o != perr_expected) begin
            $display("PERR error detected at timestamp %d\n", timestamp);
        end
    end
end

endmodule

