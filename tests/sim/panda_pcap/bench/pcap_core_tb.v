`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000


module pcap_core_tb;

// Inputs
reg clk_i = 0;
reg reset_i;
reg ARM;
reg DISARM;
reg START_WRITE;
reg [31:0] WRITE;
reg WRITE_WSTB;
reg [31:0] FRAMING_MASK;
reg FRAMING_ENABLE;
reg [31:0] FRAMING_MODE;
reg enable_i;
reg capture_i;
reg frame_i;
reg dma_full_i = 0; 
reg [31:0] sysbus_i[127:0]; 
reg [31:0] posbus_i[31:0];
wire [32*12-1:0] extbus_i = 0;

// Outputs
wire [31:0] ERR_STATUS;
wire [31:0] pcap_dat_o;
wire pcap_dat_valid_o;
wire pcap_done_o;
wire pcap_actv_o;
wire [2:0] pcap_status_o;

wire [127:0] sysbus;
//////reg [127:0] sysbus; 
wire [32*32-1 : 0] posbus;

reg [31:0] CAP_DATA;
reg [31:0] CAP_DATA2;

reg	CAP_DATA_WSTB;
reg	CAP_DATA_WSTB2;

reg [31:0] cap_pcap_dat_o;
reg cap_pcap_dat_valid;

reg test_result = 0; 
reg	err_data;

// Instantiate the Unit Under Test (UUT)
pcap_core_wrapper uut (
    .clk_i              ( clk_i             ),
    .reset_i            ( reset_i           ),
    .ARM                ( ARM               ),
    .DISARM             ( DISARM            ),
    .START_WRITE        ( START_WRITE       ),
    .WRITE              ( WRITE             ),
    .WRITE_WSTB         ( WRITE_WSTB        ),
    .FRAMING_MASK       ( FRAMING_MASK      ),
    .FRAMING_ENABLE     ( FRAMING_ENABLE    ),
    .FRAMING_MODE       ( FRAMING_MODE      ),
    .ERR_STATUS         ( ERR_STATUS        ),
    .enable_i           ( enable_i          ),
    .capture_i          ( capture_i         ),
    .frame_i            ( frame_i           ),
    .dma_full_i         ( 1'b0              ),
    .sysbus_i           ( sysbus 			),
    .posbus_i           ( posbus            ),
    .extbus_i           ( extbus_i          ),
    .pcap_dat_o         ( pcap_dat_o        ),
    .pcap_dat_valid_o   ( pcap_dat_valid_o  ),
    .pcap_done_o        ( pcap_done_o       ),
    .pcap_actv_o        ( pcap_actv_o       ),
    .pcap_status_o      ( pcap_status_o     )
);

// Testbench specific
integer timestamp = 0;

// Clock and Reset
always #4 clk_i = !clk_i;

//
// Values in the test files are arranged on FPGA clock ticks on the
// first column. This way all files are read syncronously.
//
// To achieve that a free running global Timestamp Counter below
// is used.
//
initial begin
    repeat(12500) @(posedge clk_i);
    while (1) begin
        @(posedge clk_i);
        timestamp <= timestamp + 1;
    end
end

//
// Read Bus Inputs
//
initial
begin : bus_inputs
    localparam filename = "pcap_bus_in.txt";
    localparam N        = 5;
    reg [31:0] vectors[31: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "../../panda_pcomp/bench/file_io.v"
        //`include "../../panda_pcap/bench/file_io.v"         
        $finish;
    end

    begin
        while (1) begin
            @(posedge clk_i);
            reset_i  = vectors[1];
            enable_i = vectors[2];
            frame_i = vectors[3];
            capture_i = vectors[4];
        end
    end
join

    repeat(12500) @(posedge clk_i);
    $finish;
end

//
// Read Register Inputs
//
initial
begin : reg_inputs
    localparam filename = "pcap_reg_in.txt";
	localparam N		= 87;	
    reg [31:0] vectors[31: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "../../panda_pcomp/bench/file_io.v"
       // `include "../../panda_pcap/bench/file_io.v"         
    end

    begin
        while (1) begin
            @(posedge clk_i);
            /////START_WRITE = vectors[1];
            START_WRITE = vectors[2];           
            WRITE = vectors[3];
            WRITE_WSTB = vectors[4];
            FRAMING_MASK = vectors[5];
            FRAMING_ENABLE = vectors[7];
            FRAMING_MODE = vectors[9];
            ARM = vectors[12];      // wstb
            DISARM = vectors[14];   // wstb
        end
    end
join

end


//
// Read Bus Outputs
//
reg         ACTIVE;
reg [31:0]  DATA;
reg         DATA_WSTB;
//reg [31:0]  ERROR;

initial
begin : bus_outputs
    localparam filename = "pcap_bus_out.txt";
    localparam N        = 5;
    reg [31:0] vectors[31: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "../../panda_pcomp/bench/file_io.v"
       // `include "../../panda_pcap/bench/file_io.v"         
    end

    begin
        while (1) begin
            @(posedge clk_i);
            ACTIVE = vectors[1];
            DATA   = vectors[2];
            DATA_WSTB = vectors[3];
            //ERROR = vectors[4];
        end
    end
join

end

//
// Read Position Bus
//
initial
begin : pos_inputs
    localparam filename = "pcap_pos_bus.txt";
    localparam N        = 33;
    reg [31:0] vectors[N-1: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
         `include "../../panda_pcomp/bench/file_io.v"
        // `include "../../panda_pcap/bench/file_io.v"        
    end

    begin
        while (1) begin
            @(posedge clk_i);
            for (i = 1; i < 33 ; i = i+1) begin
                posbus_i[i-1] = vectors[i];
            end
        end
    end
join

end



//
// Read Bit Bus
//
initial
begin : bit_inputs
    localparam filename = "pcap_bit_bus.txt";
    localparam N        = 129;
    //reg [31:0] vectors[N-1: 0];
    reg vectors[N-1: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "../../panda_pcomp/bench/file_io.v"    
       // `include "../../panda_pcap/bench/file_io.v"
    end

    begin
        while (1) begin
            @(posedge clk_i);
            for (i = 1; i < 129 ; i = i+1) begin
                sysbus_i[i-1] = vectors[i];
            end
			
        end
    end
join

end


//integer i;
//
//initial begin
//	for (i = 0; i < 129 ; i = i+1) 
//		sysbus[i] = sysbus_i[i][0];
//	end 
 		

assign sysbus[0] = sysbus_i[0][0]; assign sysbus[1] = sysbus_i[1][0]; assign sysbus[2] = sysbus_i[2][0]; assign sysbus[3] = sysbus_i[3][0];
assign sysbus[4] = sysbus_i[4][0]; assign sysbus[5] = sysbus_i[5][0]; assign sysbus[6] = sysbus_i[6][0]; assign sysbus[7] = sysbus_i[7][0];
assign sysbus[8] = sysbus_i[8][0]; assign sysbus[9] = sysbus_i[9][0]; assign sysbus[10] = sysbus_i[10][0]; assign sysbus[11] = sysbus_i[11][0];
assign sysbus[12] = sysbus_i[12][0]; assign sysbus[13] = sysbus_i[13][0]; assign sysbus[14] = sysbus_i[14][0]; assign sysbus[15] = sysbus_i[15][0];
assign sysbus[16] = sysbus_i[16][0]; assign sysbus[17] = sysbus_i[17][0]; assign sysbus[18] = sysbus_i[18][0]; assign sysbus[19] = sysbus_i[19][0];
assign sysbus[20] = sysbus_i[20][0]; assign sysbus[21] = sysbus_i[21][0]; assign sysbus[22] = sysbus_i[22][0]; assign sysbus[23] = sysbus_i[23][0];
assign sysbus[24] = sysbus_i[24][0]; assign sysbus[25] = sysbus_i[25][0]; assign sysbus[26] = sysbus_i[26][0]; assign sysbus[27] = sysbus_i[27][0];
assign sysbus[28] = sysbus_i[28][0]; assign sysbus[29] = sysbus_i[29][0]; assign sysbus[30] = sysbus_i[30][0]; assign sysbus[31] = sysbus_i[31][0];
assign sysbus[32] = sysbus_i[32][0]; assign sysbus[33] = sysbus_i[33][0]; assign sysbus[34] = sysbus_i[34][0]; assign sysbus[35] = sysbus_i[35][0];
assign sysbus[36] = sysbus_i[36][0]; assign sysbus[37] = sysbus_i[37][0]; assign sysbus[38] = sysbus_i[38][0]; assign sysbus[39] = sysbus_i[39][0];
assign sysbus[40] = sysbus_i[40][0]; assign sysbus[41] = sysbus_i[41][0]; assign sysbus[42] = sysbus_i[42][0]; assign sysbus[43] = sysbus_i[43][0];
assign sysbus[44] = sysbus_i[44][0]; assign sysbus[45] = sysbus_i[45][0]; assign sysbus[46] = sysbus_i[46][0]; assign sysbus[47] = sysbus_i[47][0];
assign sysbus[48] = sysbus_i[48][0]; assign sysbus[49] = sysbus_i[49][0]; assign sysbus[50] = sysbus_i[50][0]; assign sysbus[51] = sysbus_i[51][0];
assign sysbus[52] = sysbus_i[52][0]; assign sysbus[53] = sysbus_i[53][0]; assign sysbus[54] = sysbus_i[54][0]; assign sysbus[55] = sysbus_i[55][0];
assign sysbus[56] = sysbus_i[56][0]; assign sysbus[57] = sysbus_i[57][0]; assign sysbus[58] = sysbus_i[58][0]; assign sysbus[59] = sysbus_i[59][0];
assign sysbus[60] = sysbus_i[60][0]; assign sysbus[61] = sysbus_i[61][0]; assign sysbus[62] = sysbus_i[62][0]; assign sysbus[63] = sysbus_i[63][0];
assign sysbus[64] = sysbus_i[64][0]; assign sysbus[65] = sysbus_i[65][0]; assign sysbus[66] = sysbus_i[66][0]; assign sysbus[67] = sysbus_i[67][0];
assign sysbus[68] = sysbus_i[68][0]; assign sysbus[69] = sysbus_i[69][0]; assign sysbus[70] = sysbus_i[70][0]; assign sysbus[71] = sysbus_i[71][0];
assign sysbus[72] = sysbus_i[72][0]; assign sysbus[73] = sysbus_i[73][0]; assign sysbus[74] = sysbus_i[74][0]; assign sysbus[75] = sysbus_i[75][0];
assign sysbus[76] = sysbus_i[76][0]; assign sysbus[77] = sysbus_i[77][0]; assign sysbus[78] = sysbus_i[78][0]; assign sysbus[79] = sysbus_i[79][0];
assign sysbus[80] = sysbus_i[80][0]; assign sysbus[81] = sysbus_i[81][0]; assign sysbus[82] = sysbus_i[82][0]; assign sysbus[83] = sysbus_i[83][0];
assign sysbus[84] = sysbus_i[84][0]; assign sysbus[85] = sysbus_i[85][0]; assign sysbus[86] = sysbus_i[86][0]; assign sysbus[87] = sysbus_i[87][0];
assign sysbus[88] = sysbus_i[88][0]; assign sysbus[89] = sysbus_i[89][0]; assign sysbus[90] = sysbus_i[90][0]; assign sysbus[91] = sysbus_i[91][0];
assign sysbus[92] = sysbus_i[92][0]; assign sysbus[93] = sysbus_i[93][0]; assign sysbus[94] = sysbus_i[94][0]; assign sysbus[95] = sysbus_i[95][0];
assign sysbus[96] = sysbus_i[96][0]; assign sysbus[97] = sysbus_i[97][0]; assign sysbus[98] = sysbus_i[98][0]; assign sysbus[99] = sysbus_i[99][0];
assign sysbus[100] = sysbus_i[100][0]; assign sysbus[101] = sysbus_i[101][0]; assign sysbus[102] = sysbus_i[102][0]; assign sysbus[103] = sysbus_i[103][0];
assign sysbus[104] = sysbus_i[104][0]; assign sysbus[105] = sysbus_i[105][0]; assign sysbus[106] = sysbus_i[106][0]; assign sysbus[107] = sysbus_i[107][0];
assign sysbus[108] = sysbus_i[108][0]; assign sysbus[109] = sysbus_i[109][0]; assign sysbus[110] = sysbus_i[110][0]; assign sysbus[111] = sysbus_i[111][0];
assign sysbus[112] = sysbus_i[112][0]; assign sysbus[113] = sysbus_i[113][0]; assign sysbus[114] = sysbus_i[114][0]; assign sysbus[115] = sysbus_i[115][0];
assign sysbus[116] = sysbus_i[116][0]; assign sysbus[117] = sysbus_i[117][0]; assign sysbus[118] = sysbus_i[118][0]; assign sysbus[119] = sysbus_i[119][0];
assign sysbus[120] = sysbus_i[120][0]; assign sysbus[121] = sysbus_i[121][0]; assign sysbus[122] = sysbus_i[122][0]; assign sysbus[123] = sysbus_i[123][0];
assign sysbus[124] = sysbus_i[124][0]; assign sysbus[125] = sysbus_i[125][0]; assign sysbus[126] = sysbus_i[126][0]; assign sysbus[127] = sysbus_i[127][0];


//
// Read Bus Outputs
//

reg [31: 0] err_status;

initial
begin : reg_outputs
    localparam filename = "pcap_reg_out.txt";
    localparam N        = 2;
    reg [31:0] vectors[31: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "../../panda_pcomp/bench/file_io.v"
        // `include "../../panda_pcap/bench/file_io.v"         
        $finish;
    end

    begin
        while (1) begin
            @(posedge clk_i);
            err_status = vectors[1];
        end
    end
join

    repeat(12500) @(posedge clk_i);
    $finish;
end


// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//

reg err_stat;

always @(posedge clk_i) 
begin
	// Synch the testbench data ( = and <= do different things i.e block and non blocking ) 
	CAP_DATA <= DATA;
    CAP_DATA2 <= CAP_DATA;
    // Synch the testbench data
    CAP_DATA_WSTB <= DATA_WSTB;
    CAP_DATA_WSTB2 <= CAP_DATA_WSTB;
    // Synch the output data
    cap_pcap_dat_o <= pcap_dat_o;
    cap_pcap_dat_valid <= pcap_dat_valid_o;
      
    if (err_data == 1 || err_stat == 1) begin
    	test_result = 1;
    end 	      
    
    if (err_status != ERR_STATUS) begin
    	err_stat = 1;
    end 
    else begin
    	err_stat = 0;
    end		
     
    if (CAP_DATA_WSTB2 == 1) begin
   		if (cap_pcap_dat_o != CAP_DATA2) begin 
    		err_data = 1;    	
		    $display("DATA error detected at timestamp, CAP_DATA2, cap pcap data  %d %d %d\n", timestamp, CAP_DATA2, cap_pcap_dat_o);    		
    	end 
    end 	
    else begin
    	err_data = 0;
    end  	 	
end 
			   	

assign posbus[0 * 32 + 31  : 32 * 0 ] = posbus_i[0];
assign posbus[1 * 32 + 31  : 32 * 1 ] = posbus_i[1];
assign posbus[2 * 32 + 31  : 32 * 2 ] = posbus_i[2];
assign posbus[3 * 32 + 31  : 32 * 3 ] = posbus_i[3];
assign posbus[4 * 32 + 31  : 32 * 4 ] = posbus_i[4];
assign posbus[5 * 32 + 31  : 32 * 5 ] = posbus_i[5];
assign posbus[6 * 32 + 31  : 32 * 6 ] = posbus_i[6];
assign posbus[7 * 32 + 31  : 32 * 7 ] = posbus_i[7];
assign posbus[8 * 32 + 31  : 32 * 8 ] = posbus_i[8];
assign posbus[9 * 32 + 31  : 32 * 9 ] = posbus_i[9];
assign posbus[10 * 32 + 31 : 32 * 10] = posbus_i[10];
assign posbus[11 * 32 + 31 : 32 * 11] = posbus_i[11];
assign posbus[12 * 32 + 31 : 32 * 12] = posbus_i[12];
assign posbus[13 * 32 + 31 : 32 * 13] = posbus_i[13];
assign posbus[14 * 32 + 31 : 32 * 14] = posbus_i[14];
assign posbus[15 * 32 + 31 : 32 * 15] = posbus_i[15];
assign posbus[16 * 32 + 31 : 32 * 16] = posbus_i[16];
assign posbus[17 * 32 + 31 : 32 * 17] = posbus_i[17];
assign posbus[18 * 32 + 31 : 32 * 18] = posbus_i[18];
assign posbus[19 * 32 + 31 : 32 * 19] = posbus_i[19];
assign posbus[20 * 32 + 31 : 32 * 20] = posbus_i[20];
assign posbus[21 * 32 + 31 : 32 * 21] = posbus_i[21];
assign posbus[22 * 32 + 31 : 32 * 22] = posbus_i[22];
assign posbus[23 * 32 + 31 : 32 * 23] = posbus_i[23];
assign posbus[24 * 32 + 31 : 32 * 24] = posbus_i[24];
assign posbus[25 * 32 + 31 : 32 * 25] = posbus_i[25];
assign posbus[26 * 32 + 31 : 32 * 26] = posbus_i[26];
assign posbus[27 * 32 + 31 : 32 * 27] = posbus_i[27];
assign posbus[28 * 32 + 31 : 32 * 28] = posbus_i[28];
assign posbus[29 * 32 + 31 : 32 * 29] = posbus_i[29];
assign posbus[30 * 32 + 31 : 32 * 30] = posbus_i[30];
assign posbus[31 * 32 + 31 : 32 * 31] = posbus_i[31];



endmodule

