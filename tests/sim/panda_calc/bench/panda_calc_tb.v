`timescale 1ns / 1ps

module panda_calc_tb;

// Inputs
reg clk_i = 0;

reg         SIM_RESET;
reg [31:0]  inpa_i;
reg [31:0]  inpb_i;
reg [31:0]  inpc_i;
reg [31:0]  inpd_i;       

reg         A;
reg         A_WSTB;
reg         B;
reg         B_WSTB;
reg         C;
reg         C_WSTB;
reg         D;
reg         D_WSTB;
reg [1:0]   FUNC;
reg [1:0]   FUNC_DLY;
reg         FUNC_WSTB;

reg [31:0]  OUT;

wire [31:0] out_o;

reg         test_result = 0; 

always #4 clk_i = ~clk_i;

integer fid[2:0];
integer r[2:0];

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

// TS»¯¯¯¯¯SIM_RESET
integer bus_in[5:0];

initial begin
    SIM_RESET = 0;
    inpa_i = 0;
    inpb_i = 0;
    inpc_i = 0;
    inpd_i = 0;   

    @(posedge clk_i);
    fid[0] = $fopen("calc_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s %s %s\n", bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d %d %d\n", bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[5]) begin
            SIM_RESET <= bus_in[4];
            inpa_i <= bus_in[3];
            inpb_i <= bus_in[2];
            inpc_i <= bus_in[1];
            inpd_i <= bus_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK REGISTERS VECTOR FILE
//
// TS»¯¯¯¯¯A»¯¯¯¯¯B»¯¯¯¯¯C»¯¯¯¯¯D»¯¯¯¯FORCE_RESET
//integer reg_in[3:0];
integer reg_in[10:0];

initial begin
    A = 0;
    A_WSTB = 0;
    B = 0;
    B_WSTB = 0;
    C = 0;
    C_WSTB = 0;
    D = 0;
    D_WSTB = 0;
    FUNC = 0;
    FUNC_WSTB = 0;
    
    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("calc_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s %s %s %s %s\n", reg_in[10], reg_in[9], reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], 
                    reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d %d %d %d %d\n", reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], 
                    reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[10]) begin
            A <= reg_in[9];
            A_WSTB <= reg_in[8];
            B <= reg_in[7];
            B_WSTB <= reg_in[6];
            C <= reg_in[5];
            C_WSTB <= reg_in[4];
            D <= reg_in[3];
            D_WSTB <= reg_in[2];
            FUNC <= reg_in[1];
            FUNC_WSTB <= reg_in[0];
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
    fid[2] = $fopen("calc_bus_out.txt", "r"); // TS»¯¯¯¯¯OUT

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s\n", bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d\n", bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[1]) begin
            OUT <= bus_out[0];
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
    if (OUT != out_o) begin
        $display("A error detected at timestamp %d\n", timestamp, OUT, out_o);
        test_result = 1;    
    end 
end


// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i)  
    if (is_file_end) begin
        $stop(2);
    end  


// THIS NEEDS TO BE FIXED
always @ (posedge clk_i)
begin
    FUNC_DLY <= FUNC;
end    


// Instantiate the Unit Under Test (UUT)
calc uut(
        .clk_i     ( clk_i    ),
        .inpa_i    ( inpa_i   ),
        .inpb_i    ( inpb_i   ),
        .inpc_i    ( inpc_i   ),
        .inpd_i    ( inpd_i   ),
        .out_o     ( out_o    ),
        .A         ( A        ),
        .B         ( B        ),
        .C         ( C        ),
        .D         ( D        ),
        .FUNC      ( FUNC_DLY )
);


endmodule

