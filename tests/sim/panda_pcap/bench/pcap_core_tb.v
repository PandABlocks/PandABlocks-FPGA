`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000


module pcap_core_tb;

// Inputs
reg              clk_i = 0;
reg              reset_i;
reg [1:0]        CAPTURE_EDGE;
reg [5:0]        SHIFT_SUM;
reg              ARM;
reg              DISARM;
reg              START_WRITE;
reg [31:0]       WRITE;
reg              WRITE_WSTB;
reg              enable_i;
reg              capture_i;
reg              gate_i;
reg              dma_full_i = 0; 
reg [31:0]       sysbus_i[127:0]; 
reg [31:0]       posbus_i[31:0];
wire [32*12-1:0] extbus_i = 0;

// Outputs
wire [31:0]      health;
wire [31:0]      pcap_dat_o;
wire             pcap_dat_valid_o;
wire             pcap_done_o;
wire             pcap_actv_o;
wire [2:0]       pcap_status_o;

wire [127:0]     sysbus;
wire [32*32-1:0] posbus;
//reg [127:0]     sysbus;
//reg [32*32-1:0] posbus;

reg              test_result = 0; 
reg	             err_data;


// Instantiate the Unit Under Test (UUT)
pcap_core_wrapper uut (
    .clk_i              ( clk_i             ),
    .reset_i            ( reset_i           ),
    .CAPTURE_EDGE       ( CAPTURE_EDGE      ),
    .SHIFT_SUM          ( SHIFT_SUM         ),
    .ARM                ( ARM               ),
    .DISARM             ( DISARM            ),
    .START_WRITE        ( START_WRITE       ),
    .WRITE              ( WRITE             ),
    .WRITE_WSTB         ( WRITE_WSTB        ),
    .CAPTURE_EDGE       ( CAPTURE_EDGE      ),
    .SHIFT_SUM          ( SHIFT_SUM         ),
    .HEALTH             ( health            ),
    .enable_i           ( enable_i          ),
    .capture_i          ( capture_i         ),
    .gate_i             ( gate_i            ),
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

// EXT BUS
// ts_start(63 downto 0)   - Timestamp of the first gate high in current capture relative to enable
// ts_end(63 downto 0)     - Timestamp of the last gate high + 1 in current capture relative to enable   
// ts_capture(63 downto 0) - Timestamp of capture event relative to enable   
// samples(31 downto 0)    - Number of gated samples in the current capture
// bits0(31 downto 0)      - Quadrant 0 of bit_bus
// bits1(31 downto 0)      - Quadrant 1 of bit_bus
// bits2(31 downto 0)      - Quadrant 2 of bit_bus
// bits3(31 downto 0)      - Quadrant 3 of bit_bus



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
        //`include "../../panda_pcomp/bench/file_io.v"
        `include "../../panda_pcap/bench/file_io.v"         
        $finish;
    end

    begin
        while (1) begin
            @(posedge clk_i);
            reset_i  = vectors[1];
            enable_i = vectors[2];
            gate_i = vectors[3];
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
	localparam N		= 91;	
    reg [31:0] vectors[31: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        //`include "../../panda_pcomp/bench/file_io.v"
        `include "../../panda_pcap/bench/file_io.v"         
    end

    begin
        while (1) begin
            @(posedge clk_i);
            CAPTURE_EDGE = vectors[1];
            SHIFT_SUM = vectors[3];
            START_WRITE = vectors[5];
            WRITE = vectors[7];
            WRITE_WSTB = vectors[8];
            ARM = vectors[16]; //wstb
            DISARM = vectors[18]; // wstb
        end
    end
join

end

// write index
// (0-31)	posbus;
//	32		(others => '0');
// (36-33)	extbus(4 downto 1);
//	37		capture_ts(31 downto 0);
//	38		capture_ts(63 downto 32);
//	39		frame_length(31 downto 0);
//	40		capture_offset(31 downto 0);
//	41		(others => '0');
//	42		sysbus(31 downto 0);
//	43		sysbus(63 downto 32);
//	44		sysbus(95 downto 64);
//	45		sysbus(127 downto 96);
// (49-46)	extbus;
// (63-50)	(others => '0');	



//
// Read Bus Outputs
//
reg         ACTIVE = 0;
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
        //`include "../../panda_pcomp/bench/file_io.v"
        `include "../../panda_pcap/bench/file_io.v"                 
    end

    begin
        while (1) begin
            @(posedge clk_i);
            ACTIVE <= vectors[1];
            DATA   <= vectors[2];
            DATA_WSTB <= vectors[3];
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
        //`include "../../panda_pcomp/bench/file_io.v"
        `include "../../panda_pcap/bench/file_io.v"        
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
        //`include "../../panda_pcomp/bench/file_io.v"    
        `include "../../panda_pcap/bench/file_io.v"
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

 	
 	
genvar i; 		
for (i=0; i<128; i=i+1) assign sysbus[i] = sysbus_i[i][0]; 


//
// Read Bus Outputs
//

reg [31: 0] HEALTH;

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
        //`include "../../panda_pcomp/bench/file_io.v"
        `include "../../panda_pcap/bench/file_io.v"         
        $finish;
    end

    begin
        while (1) begin
            @(posedge clk_i);
            HEALTH = vectors[1];
        end
    end
join

    repeat(12500) @(posedge clk_i);
    $finish;
end


//
// Test error detection
//

reg [4:0] cnt = 0; 
reg       ACTIVE_dly;

always@(posedge clk_i)
begin
    ACTIVE_dly <= ACTIVE;
    if (ACTIVE_dly == 0 && ACTIVE == 1) begin
        cnt <= cnt + 1;
    end    
end



// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//

reg [31:0] DATA_del1;
reg [31:0] DATA_del2;
reg        DATA_WSTB_del1;
reg        DATA_WSTB_del2;

reg err_health;
reg err_act;

always @(posedge clk_i) 
begin
   
    // Regresion test result   
    if (err_data == 1 || err_health == 1 || err_act == 1) begin
    	test_result <= 1;
    end 	      
    
    // Health
    // 0 = OK
    // 1 = Too Close
    // 2 = Sample Overflow 
    if (HEALTH != health) begin
    	err_health = 1;
		$display("HEALTH error detected at timestamp, test number, %d %d\n", timestamp, cnt);    		
    end 
    else begin
    	err_health = 0;
    end		
            
    // PCAP Block active  
    if (pcap_actv_o != ACTIVE) begin 
    //if (pcap_actv_o != ACTIVE_dly) begin    
        err_act = 1;
        $display("ACTIVE error detected at timestamp, test_number,  %d %d\n", timestamp, cnt);    		
    end 
    else begin
        err_act = 0;
    end         
    
    DATA_WSTB_del1 <= DATA_WSTB;
    DATA_WSTB_del2 <= DATA_WSTB_del1;
    
    DATA_del1 <= DATA;
    DATA_del2 <= DATA_del1;  
     
    // Output data compare 
    if (DATA_WSTB_del2 == 1) begin
   		if (pcap_dat_o != DATA_del2) begin 
    		err_data = 1;    	
		    $display("DATA error detected at timestamp, DATA_del2, cap pcap data, test number,  %d %d %d %d\n", timestamp, DATA_del2, pcap_dat_o, cnt);    		
    	end 
    end 	
    else begin
    	err_data = 0;
    end  	 	
end 
			   	
genvar j;
for (j=0; j<32; j=j+1) assign posbus[j*32+31 : 32*j] = posbus_i[j]; 



endmodule    

