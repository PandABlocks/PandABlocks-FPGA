`timescale 1ns / 1ps

module panda_lut_tb;

reg clk_i = 0;
always #4 clk_i = ~clk_i;

integer timestamp = 0;

// Inputs
reg         SIM_RESET;
reg         INPA;
reg         INPB;
reg         INPC;
reg         INPD;
reg         INPE;
reg [31:0]  FUNC;
reg         FUNC_WSTB;
reg [1:0]   A;
reg         A_WSTB;
reg [1:0]   B;
reg         B_WSTB;
reg [1:0]   C;
reg         C_WSTB;
reg [1:0]   D;
reg         D_WSTB;
reg [1:0]   E;
reg         E_WSTB;                    
reg         VAL;

reg         err;
reg         test_result = 0;

// Outputs
wire        out_o;

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
// TS»¯¯¯¯¯SIM_RESET»¯¯¯¯¯¯INPA»¯¯¯INPB»¯¯¯INPC»¯¯¯INPD»¯¯¯INPE
integer bus_in[6:0];

initial begin
    SIM_RESET = 0;
    INPA = 0;
    INPB = 0;
    INPC = 0;
    INPD = 0;
    INPE = 0;

    @(posedge clk_i);
    fid[0] = $fopen("lut_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s %s %s %s\n", bus_in[6], bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

    r[0] = $fscanf(fid[0], "%d %d %d %d %d %d %d\n", bus_in[6], bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[6]) begin
            SIM_RESET <= bus_in[5];
            INPA <= bus_in[4];
            INPB <= bus_in[3];
            INPC <= bus_in[2];
            INPD <= bus_in[1];
            INPE <= bus_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK REGISTERS VECTOR FILE
//

// TS»¯¯¯¯¯FUNC
integer reg_in[12:0];

initial begin
    FUNC = 0;
    FUNC_WSTB = 0;
    A = 0;
    A_WSTB = 0;
    B = 0;
    B_WSTB = 0;
    C = 0;
    C_WSTB = 0;
    D = 0;
    D_WSTB = 0;
    E = 0;
    E_WSTB = 0; 

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("lut_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s %s %s %s %s %s %s\n", reg_in[12], reg_in[11], reg_in[10], reg_in[9], reg_in[8], reg_in[7], 
                                                            reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d %d %d %d %d %d %d\n", reg_in[12], reg_in[11], reg_in[10], reg_in[9], reg_in[8], reg_in[7], 
                                                                reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[12]) begin
            FUNC = reg_in[11];
            FUNC_WSTB = reg_in[10];
            A = reg_in[9]
            A_WSTB = reg_in[8];
            B = reg_in[7];
            B_WSTB = reg_in[6];
            C = reg_in[5];
            C_WSTB = reg_in[4];
            D = reg_in[3];
            D_WSTB = reg_in[2];
            E = reg_in[1];
            E_WSTB = reg_in[0];
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
    fid[2] = $fopen("lut_bus_out.txt", "r"); // TS, VAL

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
            //$finish(2);
            err = 1;    
            test_result = 1;        
        end 
    end
end

// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i) //----------------------------------------- HERE 
    if (is_file_end) begin
        $display("Simulation has finished");
        $finish(2);
    end 

// Instantiate the Unit Under Test (UUT)
//panda_lut uut (
lut uut (
        .clk_i          ( clk_i             ),
        //.reset_i        ( SIM_RESET         ),
        .FUNC           ( FUNC              ),
        .A              ( A                 ),
        .B              ( B                 ),
        .C              ( C                 ),
        .D              ( D                 ),
        .E              ( E                 ),
        .inpa_i         ( INPA              ),
        .inpb_i         ( INPB              ),
        .inpc_i         ( INPC              ),
        .inpd_i         ( INPD              ),
        .inpe_i         ( INPE              ),
        .out_o          ( out_o             )
);


endmodule

