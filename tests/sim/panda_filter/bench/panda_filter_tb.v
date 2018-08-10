`timescale 1ns / 1ps

module panda_filter_tb;

// Inputs
reg clk_i = 0;

reg SIM_RESET;
reg TRIG;
reg ENABLE;

reg [31:0] INP;

reg [1:0] MODE;
reg MODE_WSTB;
reg [1:0] HEALTH;

wire [31:0] out_o;
reg READY;
wire ready_o;

wire [1:0] health_o;
reg [31:0] OUT;

reg [1:0] health_o_dly;

reg test_result;

reg     err_health0;
reg     err_health1;
reg     err_out;


always #4 clk_i = ~clk_i;

// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i) //----------------------------------------- HERE 
    if (is_file_end) begin
        $stop(2);
    end       


//integer fid[2:0];
integer fid[3:0];

//integer r[2:0];
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
// TS»¯¯¯¯¯SIM_RESET»¯¯¯¯¯¯TRIG»¯¯¯¯INP»¯¯¯¯ENABLE
integer bus_in[4:0];

initial begin
    SIM_RESET = 0;
    TRIG = 0;
    INP = 0;
    ENABLE = 0;

    @(posedge clk_i);
    fid[0] = $fopen("filter_bus_in.txt", "r");
    
    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s %s\n", bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d %d\n", bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[4]) begin
            // TS	SIM_RESET TRIG INP ENABLE
            SIM_RESET = bus_in[3];
            TRIG = bus_in[2];
            INP = bus_in[1];
            ENABLE = bus_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK REGISTERS VECTOR FILE
//
// TS»¯¯¯¯¯MODE»MODE_WSTB»¯¯¯¯INP_WSTB
integer reg_in[2:0];

initial begin
    MODE          = 0;
    MODE_WSTB     = 0;

    @(posedge clk_i);

    // Open "reg_in" file
     fid[1] = $fopen("filter_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s\n", reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d\n", reg_in[2], reg_in[1], reg_in[0]); 
        wait (timestamp == reg_in[2])begin  
            // TS	MODE and MODE_WSTB            
            MODE = reg_in[1];        
            MODE_WSTB = reg_in[0];
        end
        @(posedge clk_i);
    end
end

//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
// TS»¯¯¯¯¯OUT»¯¯¯¯¯READY»
integer bus_out[2:0];
reg     is_file_end;

initial begin
    OUT   = 0;
    READY = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("filter_bus_out.txt", "r"); // TS»¯¯¯¯¯OUT»¯¯¯READY

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s %s\n", bus_out[2], bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d %d\n", bus_out[2], bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[2]) begin
            OUT = bus_out[1];
            READY = bus_out[0];
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

    is_file_end = 1;
end

//
// READ BLOCK EXPECTED ERROR OUTPUTS FILE TO COMPARE AGAINTS ERROR
// OUTPUTS
//
// TS»¯¯¯¯¯HEALTH»
integer reg_out[1:0];

initial begin
    HEALTH = 0;

    @(posedge clk_i);

    // Open "reg_out" file
    fid[3] = $fopen("filter_reg_out.txt", "r"); // TS»¯¯¯¯¯HEALTH

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s\n", reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d\n", reg_out[1], reg_out[0]);
        wait (timestamp == reg_out[1]) begin
            HEALTH = reg_out[0];
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
    health_o_dly <= health_o; 
    
    if (err_out == 1) begin
      test_result = 1;
    end     
            
    if (~is_file_end) begin
        if (OUT != out_o & ready_o) begin
            err_out <= 1;
            $display("OUTN error detected at 1.timestamp the expected value is 2.OUT and result is 3.out_o %d, %d, %d\n", timestamp, OUT, out_o);   
        end else begin
            err_out <= 0;
        end
        if (health_o[0] == 1 & health_o_dly[0] == 0) begin
            err_health0 <= 1;
            $display("ERROR Accumulator overflow the number of results output are %d\n", timestamp); 
        end else begin 
            err_health0 <= 0;
        end  
        if (health_o[1] == 1 & health_o_dly[1] == 0) begin
            err_health1 <= 1;
            $display("ERROR Divider has been doubled triggered before result ready the number of results output are %d\n", timestamp);
        end else begin
            err_health1 <= 0;  
        end   
    end
end


// Instantiate the Unit Under Test (UUT)
filter uut (
        .clk_i          ( clk_i             ),
        .mode_i         ( MODE              ), 
        .trig_i         ( TRIG              ),
        .inp_i          ( INP               ),
        .enable_i       ( ENABLE            ),
        .out_o          ( out_o             ),
        .ready_o        ( ready_o           ),
        .health_o       ( health_o          )
);                


endmodule

