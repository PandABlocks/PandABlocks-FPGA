`timescale 1ns / 1ps

module panda_bits_tb;

// Inputs
reg clk_i = 0;

reg     SIM_RESET;
reg     A;
reg     A_WSTB;
reg     B;
reg     B_WSTB;
reg     C;
reg     C_WSTB;
reg     D;
reg     D_WSTB;
reg     OUTA;
reg     OUTB;
reg     OUTC;
reg     OUTD;

wire    softa;
wire    softb;
wire    softc;
wire    softd;

reg     erra;
reg     errb;
reg     errc;
reg     errd;
reg test_result = 0; 

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
integer bus_in[1:0];

initial begin
    SIM_RESET = 0;

    @(posedge clk_i);
    fid[0] = $fopen("bits_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s \n", bus_in[1], bus_in[0]);

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
// TS»¯¯¯¯¯DIVISOR»FIRST_PULSE»¯¯¯¯FORCE_RESET
//integer reg_in[3:0];
integer reg_in[8:0];

initial begin
    A = 0;
    A_WSTB = 0;
    B = 0;
    B_WSTB = 0;
    C = 0;
    C_WSTB = 0;
    D = 0;
    D_WSTB = 0;
    
    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("bits_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s %s %s\n", reg_in[8], reg_in[7], reg_in[6], 
                    reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d %d %d\n", reg_in[8], reg_in[7], reg_in[6], 
                    reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[8]) begin
            A = reg_in[7];
            A_WSTB = reg_in[6];
            B = reg_in[5];
            B_WSTB = reg_in[4];
            C = reg_in[3];
            C_WSTB = reg_in[2];
            D = reg_in[1];
            D_WSTB = reg_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
integer bus_out[6:0];
reg     is_file_end;

initial begin
    OUTA = 0;
    OUTB = 0;
    OUTC = 0;
    OUTD = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("bits_bus_out.txt", "r"); // TS»¯¯¯¯¯OUTD»¯¯¯OUTN

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s %s %s %s\n", bus_out[4], bus_out[3], bus_out[2], bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d %d %d %d\n", bus_out[4], bus_out[3], bus_out[2], bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[4]) begin
            OUTA = bus_out[3];
            OUTB = bus_out[2];
            OUTC = bus_out[1];
            OUTD = bus_out[0];
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
    if (OUTA != softa) begin
        erra = 1;
        test_result = 1;    
    end 
    if (OUTB != softb) begin
        errb = 1;
        test_result = 1;    
    end  
    
    if (OUTC != softc) begin
        errc = 1;
        test_result = 1;    
    end
    
    if (OUTD != softd) begin
        errd = 1;
        test_result = 1;        
    end
end


// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i)  
    if (is_file_end) begin
        $stop(2);
    end  


// Instantiate the Unit Under Test (UUT)
//panda_div uut (
bits uut (
        .clk_i            ( clk_i             ),
        .softa_o          ( softa             ),
        .softb_o          ( softb             ),
        .softc_o          ( softc             ),
        .softd_o          ( softd             ), 
        .SOFTA_SET        ( A                 ),
        .SOFTB_SET        ( B                 ), 
        .SOFTC_SET        ( C                 ),
        .SOFTD_SET        ( D                 )   
);


endmodule

