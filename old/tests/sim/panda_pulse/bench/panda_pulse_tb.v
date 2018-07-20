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
integer     timestamp = 0;
always #4 clk_i = ~clk_i;

// Test vector input and outputs.
reg          SIM_RESET;
reg          INP;
wire [47: 0] DELAY;
reg          DELAY_WSTB;
wire [47: 0] WIDTH;
reg          WIDTH_WSTB;
reg [31: 0]  DELAY_L;
reg          DELAY_L_WSTB;
reg [15: 0]  DELAY_H;
reg          DELAY_H_WSTB;            
reg [31: 0]  WIDTH_L;
reg          WIDTH_L_WSTB;            
reg [15: 0]  WIDTH_H;
reg          WIDTH_H_WSTB;
reg [1:  0]	 TRIG_EDGE;
reg 		 TRIG_EDGE_WSTB;
reg          ENABLE;
reg          VAL;
reg          ERR_OVERFLOW;
reg          ERR_PERIOD;
reg [10: 0]  QUEUE;
reg [31: 0]  MISSED_CNT;    
reg          err_out_o;
reg          test_result = 0;

// Block outputs and status registers.
wire         out_o;

wire [31: 0] missed_cnt_o;
wire [31: 0] queue_o;
wire [31: 0] err_period_o;
wire [31: 0] err_overflow_o;


// Instantiate Unit Under Test
pulse uut (
    .clk_i          ( clk_i          ),
    .inp_i          ( INP            ),
    .enable_i       ( ENABLE         ),  
    .out_o          ( out_o          ),
    .TRIG_EDGE		( TRIG_EDGE		 ),
    .TRIG_EDGE_WSTB ( TRIG_EDGE_WSTB ),	
    .DELAY          ( DELAY          ),
    .DELAY_WSTB     ( DELAY_WSTB     ), 
    .WIDTH          ( WIDTH          ),
    .WIDTH_WSTB     ( WIDTH_WSTB     ),
    .ERR_OVERFLOW   ( err_overflow_o ),
    .ERR_PERIOD     ( err_period_o   ),
    .QUEUE          ( queue_o        ),
    .MISSED_CNT     ( missed_cnt_o   )
);

integer fid[3:0];
integer r[3:0];

// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i) //----------------------------------------- HERE 
    if (is_file_end) begin
        $stop(2);
    end     


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
// TS»¯¯¯¯¯SIM_RESET»¯¯¯¯¯¯INP»¯¯¯¯RESET
integer bus_in[3:0];

initial begin
    SIM_RESET = 0;
    INP = 0;
    //RESET = 0;
    ENABLE = 0;

    @(posedge clk_i);
    fid[0] = $fopen("pulse_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s\n", bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

    r[0] = $fscanf(fid[0], "%d %d %d %d\n", bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[3]) begin
            SIM_RESET <= bus_in[2];
            INP <= bus_in[1];
            //RESET <= bus_in[0];
            ENABLE <= bus_in[0];
        end
        @(posedge clk_i);
    end
end


//
// READ BLOCK REGISTERS VECTOR FILE
//
// TS»¯¯¯¯¯DELAY»¯¯WIDTH»¯¯FORCE_RESET
integer reg_in[10:0];

initial begin
    DELAY_L = 0;
    DELAY_H = 0;
    DELAY_L_WSTB = 0;
    DELAY_H_WSTB = 0;
    WIDTH_L = 0;
    WIDTH_H = 0;
    WIDTH_L_WSTB = 0;
    WIDTH_H_WSTB = 0;
    TRIG_EDGE = 0;
    TRIG_EDGE_WSTB =0;

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("pulse_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s %s %s %s %s\n", reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d %d %d %d %d\n", reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
        wait (timestamp == reg_in[10]) begin
            DELAY_L = reg_in[9];
            DELAY_L_WSTB = reg_in[8];
            DELAY_H = reg_in[7];
            DELAY_H_WSTB = reg_in[6];            
            WIDTH_L = reg_in[5];
            WIDTH_L_WSTB = reg_in[4];            
            WIDTH_H = reg_in[3];
            WIDTH_H_WSTB = reg_in[2];
            TRIG_EDGE = reg_in[1];
            TRIG_EDGE_WSTB = reg_in[0];
        end
        @(posedge clk_i);
    end
end


assign DELAY = {DELAY_H, DELAY_L};
assign WIDTH = {WIDTH_H, WIDTH_L};


always @(DELAY_L_WSTB, DELAY_H_WSTB, WIDTH_L_WSTB, WIDTH_H_WSTB)
	begin
		WIDTH_WSTB = WIDTH_H_WSTB | WIDTH_L_WSTB;
		DELAY_WSTB = DELAY_H_WSTB | DELAY_L_WSTB;
end 


//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
// TS»¯¯¯¯¯OUT

integer bus_out[1:0];
reg     is_file_end;

initial begin
    VAL = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("pulse_bus_out.txt", "r"); // TS, VAL

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s\n", bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d\n", bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[1]) begin
            VAL = bus_out[0];
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

//TS»¯¯¯¯¯ERR_OVERFLOW»¯¯¯ERR_PERIOD»¯¯¯¯¯QUEUE»¯¯MISSED_CNT
integer reg_out[4:0];

initial begin
    ERR_OVERFLOW = 0;
    ERR_PERIOD = 0;
    QUEUE = 0;
    MISSED_CNT = 0;

    @(posedge clk_i);

    // Open "reg_out" file to read
    fid[3] = $fopen("pulse_reg_out.txt", "r");

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s %s %s %s\n", reg_out[4], reg_out[3], reg_out[2], reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d %d %d %d\n", reg_out[4], reg_out[3], reg_out[2], reg_out[1], reg_out[0]);
        wait (timestamp == reg_out[4]) begin
            ERR_OVERFLOW <= reg_out[3];
            ERR_PERIOD <= reg_out[2];
            QUEUE <= reg_out[1];
            MISSED_CNT <= reg_out[0];
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
    
        if (err_out_o == 1) begin
          test_result = 1;
        end   
    
        // If not equal, display an error.
        if (out_o != VAL) begin
            err_out_o = 1;
            $display("OUT error detected at timestamp %d\n", timestamp);
        end
    end
end

endmodule

