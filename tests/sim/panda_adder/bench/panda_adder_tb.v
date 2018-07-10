`timescale 1ns / 1ps

module panda_adder_tb;

reg clk_i = 0;
always #4 clk_i = ~clk_i;

integer timestamp = 0;

// Inputs
reg [31:0]  INPA;
reg [31:0]  INPB;
reg [31:0]  INPC;
reg [31:0]  INPD;
reg         INPA_INVERT;
reg         INPA_INVERT_WSTB;
reg         INPB_INVERT;
reg         INPB_INVERT_WSTB;
reg         INPC_INVERT;
reg         INPC_INVERT_WSTB;
reg         INPD_INVERT;
reg         INPD_INVERT_WSTB;
reg  [1:0]  SCALE;
reg         SCALE_WSTB;        

wire [31:0] out_o;
reg  [31:0] OUT;   

reg         reset_i;
reg         out_err = 0;
reg         test_result = 0;


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
// TS»¯¯¯¯¯SIM_RESET
integer bus_in[5:0];

initial begin
    reset_i = 0;
    INPA = 0;
    INPB = 0;
    INPC = 0;
    INPD = 0;

    @(posedge clk_i);
    fid[0] = $fopen("adder_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s %s %s\n", bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

    r[0] = $fscanf(fid[0], "%d %d %d %d %d %d\n", bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[5]) begin
            reset_i <= bus_in[4];
            INPA <= bus_in[3];
            INPB <= bus_in[2];
            INPC <= bus_in[1];
            INPD <= bus_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK REGISTERS VECTOR FILE
//

// TS»¯¯¯¯¯INPA_INVERT»¯¯¯¯¯¯¯INPB_INVERT»¯¯¯¯¯¯¯INPC_INVERT»¯¯¯¯¯¯¯INPC_INVERT»¯¯¯¯¯¯¯SCALE
integer reg_in[10:0];

initial begin
    INPA_INVERT = 0;
    INPA_INVERT_WSTB = 0;
    INPB_INVERT = 0;
    INPB_INVERT_WSTB = 0;
    INPC_INVERT = 0;
    INPC_INVERT_WSTB = 0;
    INPD_INVERT = 0; 
    INPD_INVERT_WSTB = 0;
    SCALE = 0;
    SCALE_WSTB = 0; 
    
    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("adder_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s %s %s %s %s\n", reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d %d %d %d %d\n", reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[10]) begin
            INPA_INVERT = reg_in[9];
            INPA_INVERT_WSTB = reg_in[8];
            INPB_INVERT = reg_in[7];
            INPB_INVERT_WSTB = reg_in[6];
            INPC_INVERT = reg_in[5];
            INPC_INVERT_WSTB = reg_in[4];          
            INPD_INVERT = reg_in[3];
            INPD_INVERT_WSTB = reg_in[2];
            SCALE = reg_in[1];
            SCALE_WSTB = reg_in[0];
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
    fid[2] = $fopen("adder_bus_out.txt", "r");

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s\n", bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d\n", bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[1]) begin
            OUT = bus_out[0];
        end
        @(posedge clk_i);
    end
    
    is_file_end = 1;

end

//
// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//
always @(posedge clk_i)
begin
    if (~is_file_end) begin
        if (out_err == 1) begin
            test_result = 1;
        end    
        if (out_o != OUT) begin
            $display("Outputs error at timestamp %d\n", timestamp);
            out_err <= 1;
        end 
    end
end


// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i)  
    if (is_file_end) begin
        $stop(2);
    end  

// Instantiate the Unit Under Test (UUT)
//panda_adder uut (
adder uut (
        .clk_i        ( clk_i       ),

        .inpa_i       ( INPA        ),
        .inpb_i       ( INPB        ),
        .inpc_i       ( INPC        ),
        .inpd_i       ( INPD        ),
        .out_o        ( out_o       ),    

        .INPA_INVERT  ( INPA_INVERT ),
        .INPB_INVERT  ( INPB_INVERT ),
        .INPC_INVERT  ( INPC_INVERT ),
        .INPD_INVERT  ( INPD_INVERT ),
        .SCALE        ( SCALE       )      
);


endmodule

