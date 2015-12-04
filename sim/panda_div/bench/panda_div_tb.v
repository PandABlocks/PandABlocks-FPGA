`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:59:15 12/03/2015
// Design Name:   panda_div
// Module Name:   /home/iu42/hardware/trunk/FPGA/PandA-Motion-Project/PandaFPGA/sim/panda_div/bench/panda_div_tb.v
// Project Name:  panda_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: panda_div
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module panda_div_tb;

	// Inputs
	reg clk_i;
	reg inp_i;
	reg rst_i;
	reg FIRST_PULSE;
	reg [31:0] DIVISOR;
	reg FORCE_RST;

	// Outputs
	wire outd_o;
	wire outn_o;
	wire [31:0] COUNT;

	// Instantiate the Unit Under Test (UUT)
	panda_div uut (
		.clk_i(clk_i), 
		.inp_i(inp_i), 
		.rst_i(rst_i), 
		.outd_o(outd_o), 
		.outn_o(outn_o), 
		.FIRST_PULSE(FIRST_PULSE), 
		.DIVISOR(DIVISOR), 
		.FORCE_RST(FORCE_RST), 
		.COUNT(COUNT)
	);

	initial begin
		// Initialize Inputs
		clk_i = 0;
		inp_i = 0;
		rst_i = 0;
		FIRST_PULSE = 0;
		DIVISOR = 0;
		FORCE_RST = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

