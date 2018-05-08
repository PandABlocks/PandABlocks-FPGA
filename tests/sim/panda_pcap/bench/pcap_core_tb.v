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
wire [31:0]      HEALTH_o;
wire [31:0]      pcap_dat_o;
wire             pcap_dat_valid_o;
wire             pcap_done_o;
wire             pcap_actv_o;
wire [2:0]       pcap_status_o;

wire [127:0]     sysbus;
wire [32*32-1:0] posbus;

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
    .HEALTH             ( HEALTH_o          ),
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
        `include "../../panda_pcap/bench/file_io.v"         
        $finish;
    end

    begin
        while (1) begin
            @(posedge clk_i);
            reset_i  <= vectors[1];
            enable_i <= vectors[2];
            gate_i <= vectors[3];
            capture_i <= vectors[4];
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
        `include "../../panda_pcap/bench/file_io.v"         
    end

    begin
        while (1) begin
            @(posedge clk_i);
            CAPTURE_EDGE <= vectors[1];
            SHIFT_SUM <= vectors[3];
            START_WRITE = vectors[6];
            WRITE <= vectors[7];
            WRITE_WSTB <= vectors[8];
            ARM <= vectors[16]; //wstb
            DISARM <= vectors[18]; // wstb
        end
    end
join

end



//
// Read Bus Outputs
//
reg         ACTIVE = 0;
reg [31:0]  DATA;
reg         DATA_WSTB;
reg 		ERROR;
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
        `include "../../panda_pcap/bench/file_io.v"                 
        
    end

    begin
        while (1) begin
            @(posedge clk_i);
            ACTIVE <= vectors[1];
            DATA   <= vectors[2];
            DATA_WSTB <= vectors[3];
			ERROR <= vectors[4];
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
        `include "../../panda_pcap/bench/file_io.v"        
    end

    begin
        while (1) begin
            @(posedge clk_i);
            for (i = 1; i < 33 ; i = i+1) begin
                posbus_i[i-1] <= vectors[i];
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
    reg vectors[N-1: 0];

    reg     [8192*2*10:0] line;
    integer          file, c, r, i;
    reg     [31: 0]  TS;

fork
    begin
        `include "../../panda_pcap/bench/file_io.v"
    end

    begin
        while (1) begin
            @(posedge clk_i);
            for (i = 1; i < 129 ; i = i+1) begin
                sysbus_i[i-1] <= vectors[i];
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
        `include "../../panda_pcap/bench/file_io.v"         
        $finish;
    end

    begin
        while (1) begin
            @(posedge clk_i);
            HEALTH <= vectors[1];
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


reg err_health;
reg err_act;
reg err_dat_valid;

always @(posedge clk_i) 
begin
   
    // Regresion test result   
    if (err_data == 1 || err_health == 1 || err_act == 1 || err_dat_valid == 1) begin
    	test_result <= 1;
    end 	      
        
    // Health
    // 0 = OK
    // 1 = Too Close
    // 2 = Sample Overflow 
	if (HEALTH != HEALTH_o) begin
    	err_health <= 1;
		$display("HEALTH error detected at timestamp, test number, %d %d\n", timestamp, cnt);    		
    end 
    else begin
    	err_health <= 0;
    end		
            
    // PCAP Block active  
    if (pcap_actv_o != ACTIVE) begin    
        err_act <= 1;
        $display("ACTIVE error detected at timestamp, test_number,  %d %d\n", timestamp, cnt);    		
    end 
    else begin
        err_act <= 0;
    end         
        
    // Check the data valid signal
    if (DATA_WSTB != pcap_dat_valid_o) begin
        err_dat_valid <= 1;
        $display("DATA VALID error detected at timestemp, test_number, %d %d\n", timestamp, cnt);     
    end 
    else begin
        err_dat_valid <= 0;
    end     
     
    // Output data compare 
   	if (DATA_WSTB == 1) begin
   		if (pcap_dat_o != DATA) begin 
    		err_data <= 1;    	
		    $display("DATA error detected at timestamp, DATA, cap pcap data, test number,  %d %d %d %d\n", timestamp, DATA, pcap_dat_o, cnt);    		
    	end 
		else begin
			err_data <= 0;
		end    
	end 	
    else begin
    	err_data <= 0;
    end  	 	
end 
			   	
genvar j;
for (j=0; j<32; j=j+1) assign posbus[j*32+31 : 32*j] = posbus_i[j]; 



endmodule    

