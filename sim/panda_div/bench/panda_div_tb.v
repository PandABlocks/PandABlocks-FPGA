`timescale 1ns / 1ps

module panda_div_tb;

// Inputs
reg clk_i = 0;


reg SIM_RESET;
reg INP;
reg RESET;

reg FIRST_PULSE;
reg [31:0] DIVISOR;
reg FORCE_RST;

// Outputs
wire outd_o;
reg  OUTD;
wire outn_o;
reg  OUTN;
wire [31:0] COUNT;
reg  [31:0] COUNT_EXPECTED;

always #4 clk_i = ~clk_i;

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
    repeat (5) @(posedge clk_i);
    while (1) begin
        timestamp <= timestamp + 1;
        @(posedge clk_i);
    end
end

//
// READ BLOCK INPUTS VECTOR FILE
//

// TS»¯¯¯¯¯SIM_RESET»¯¯¯¯¯¯INP»¯¯¯¯RESET
integer bus_in[3:0];

initial begin
    SIM_RESET = 0;
    INP = 0;
    RESET = 0;

    @(posedge clk_i);
    fid[0] = $fopen("div_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s\n", bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d\n", bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[3]) begin
            SIM_RESET <= bus_in[2];
            INP <= bus_in[1];
            RESET <= bus_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK REGISTERS VECTOR FILE
//
// TS»¯¯¯¯¯DIVISOR»FIRST_PULSE»¯¯¯¯FORCE_RESET
integer reg_in[3:0];

initial begin
    DIVISOR     = 0;
    FIRST_PULSE = 0;
    FORCE_RST   = 0;

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("div_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s\n", reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d\n", reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[3]) begin
            DIVISOR = reg_in[2];
            FIRST_PULSE = reg_in[1];
            FORCE_RST = reg_in[0];

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
    OUTN = 0;
    OUTD = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("div_bus_out.txt", "r"); // TS»¯¯¯¯¯OUTD»¯¯¯OUTN

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s %s\n", bus_out[2], bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d %d\n", bus_out[2], bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[2]) begin
            OUTD = bus_out[1];
            OUTN = bus_out[0];
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
    COUNT_EXPECTED = 0;

    @(posedge clk_i);

    // Open "reg_out" file
    fid[3] = $fopen("div_reg_out.txt", "r");

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s\n", reg_out[1], reg_out[0]);


    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d\n", reg_out[1], reg_out[0]);
        wait (timestamp == reg_out[1]) begin
            COUNT_EXPECTED <= reg_out[0];
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
        if (outn_o != OUTN) begin
            $display("OUTN error detected at timestamp %d\n", timestamp);
        end

        if (outd_o != OUTD) begin
            $display("OUTN error detected at timestamp %d\n", timestamp);
        end

        if (COUNT != COUNT_EXPECTED) begin
            $display("COUNT error detected at timestamp %d\n", timestamp);
        end
    end
end

// Instantiate the Unit Under Test (UUT)
panda_div uut (
        .clk_i          ( clk_i             ),
        .inp_i          ( INP               ),
        .rst_i          ( RESET             ),
        .outd_o         ( outd_o            ),
        .outn_o         ( outn_o            ),
        .FIRST_PULSE    ( FIRST_PULSE       ),
        .DIVISOR        ( DIVISOR           ),
        .FORCE_RST      ( FORCE_RST         ),
        .COUNT          ( COUNT             )
);


endmodule

