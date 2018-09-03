////////////////////////////////////////////////////////////////////////////////
// Timing testbench: testblock - First test
// Block simulation for test
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module testblock_1_tb;

reg clk_i = 0;
always #4 clk_i = ~clk_i;

// Inputs from initialisation file
reg         INPA;
reg  [1:0]  A;
reg  [31:0] FUNC;

//Outputs
reg         OUT;		//Output from ini file
wire        OUT_uut;	//Output from UUT
reg         OUT_err;	//Error signal

// Write Strobes

//Signals used within test
reg         test_result = 0;
integer     fid;
integer     r;
integer     timestamp = 0;

//
// Values in the test files are arranged on FPGA clock ticks on the
// first column. This way all files are read synchronously.
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
// Read expected values file
//
integer ignore[15:0];
integer data_in[4:0];
reg is_file_end=0;

initial begin
    FUNC = 0;
    A = 0;
    INPA = 0;
    OUT = 0;

    @(posedge clk_i);
    fid=$fopen("1testblockexpected.csv","r");
    // Read and ignore description field

    r=$fgets(ignore, fid);
    //r=$fscanf(fid,"%s %s %s %s %s\n",
//    );
    while (!$feof(fid)) begin
        r=$fscanf(fid,"%d %d %d %d %d\n",
            data_in[4],
            data_in[3],
            data_in[2],
            data_in[1],
            data_in[0]
        );
        wait (timestamp == data_in[4]) begin
            	FUNC <= data_in[3];
            	A <= data_in[2];
            	INPA <= data_in[1];
            	OUT <= data_in[0];
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
    	if (OUT != OUT_uut) begin
    	    $display("OUT error detected at timestamp %d\n", timestamp);
    	    OUT_err = 1;
    	    test_result = 1;
        end
    end
end

// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i)
begin
    if (is_file_end) begin
        $display("Simulation has finished");
        $finish(2);
    end
end



// Instantiate the Unit Under Test (UUT)
testblock uut (

		.FUNC  		(FUNC     ),
		.A  		(A     ),
		.INPA_i   	(INPA ),
	 	.OUT_o  		(OUT_uut		),
    	.clk_i		(clk_i		)
);

endmodule