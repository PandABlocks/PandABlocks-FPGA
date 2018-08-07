`timescale 1ns / 1ps

module panda_slowctrl_tb;

parameter TTLIN_NUM = 6;
parameter TTLOUT_NUM = 10;
parameter ENC_NUM = 4;
parameter PAGE_NUM = 5;
parameter MOD_COUNT = 2**PAGE_NUM;
parameter PAGE_AW = 10;  


// Inputs
reg rst_i;
reg clk_i = 0;
reg clk50 = 0;
reg         spi_sclk_i;
reg         spi_dat_i;

reg [MOD_COUNT-1:0]   write_strobe_i;
reg [PAGE_AW-1:0]     write_address_i; 
reg [31:0]            write_data_i;  
wire        write_ack_o;

reg [TTLIN_NUM-1: 0]  ttlin_i = 0;
reg [TTLOUT_NUM-1: 0] ttlout_i = 0;
reg [ENC_NUM-1: 0]    inenc_conn_i = 0;
reg [ENC_NUM-1: 0]    outenc_conn_i = 0;

wire [31:0]  SLOW_FPGA_VERSION;
wire [127:0] DCARD_MODE;    

// Outputs
wire busy_o;
wire spi_sclk_o;
wire spi_dat_o;
wire [31: 0] read_data_o;
wire [9 : 0] read_address_o;
wire         read_ack_o;

always #4 clk_i = !clk_i;
always #10 clk50 = !clk50;

initial begin
    rst_i = 1;
    repeat(10) @(posedge clk_i);
    rst_i = 0;
end

// Instantiate the Unit Under Test (UUT)
slowcont_wrapper uut      (
    .clk_i              ( clk_i             ),
    .reset_i            ( rst_i             ),
    
    .write_strobe_i     ( write_strobe_i    ),
    .write_data_i       ( write_data_i      ),
    .write_address_i    ( write_address_i   ),
    .write_ack_o        ( write_ack_o       ),
    
    .read_strobe_i      ( read_strobe_i     ),   
    .read_address_i     ( read_address_o    ),
    .read_data_o        ( read_data_o       ),
    .read_ack_o         ( read_ack_o        ),
    
    .ttlin_i            ( ttlin_i           ),  
    .ttlout_i           ( ttlout_i          ),  
    .inenc_conn_i       ( inenc_conn_i      ),  
    .outenc_conn_i      ( outenc_conn_i     ),
    
    .SLOW_FPGA_VERSION  ( SLOW_FPGA_VERSION ),
    .DCARD_MODE         ( DCARD_MODE        ),        
    
    .spi_sclk_o         ( spi_sclk_o        ),
    .spi_dat_o          ( spi_dat_o         ),
    .spi_sclk_i         ( spi_sclk_o        ),
    .spi_dat_i          ( spi_dat_o         )
);

initial begin
        // Initialize Inputs
        write_strobe_i = 0;
        write_data_i = 0;
        write_address_i = 0;
        repeat(1250) @(posedge clk_i);
        write_strobe_i = 1;
        write_data_i = 32'h55AA55AA;
        write_address_i = 10'h3AA;
        repeat(1) @(posedge clk_i);
        write_strobe_i = 0;
        write_data_i = 0;
        write_address_i = 0;
        repeat(1250) @(posedge clk_i);
        write_strobe_i = 1;
        write_data_i = 32'hAA55AA55;
        write_address_i = 10'h355;
        repeat(1) @(posedge clk_i);
        write_strobe_i = 0;
        write_data_i = 0;
        write_address_i = 0;
        repeat(1250) @(posedge clk_i);
end


wire [5:0]  ttlin_term;
wire [15:0] ttl_leds;
wire [3:0]  status_leds;
wire [3:0]  enc_leds_o;
wire [3:0]  outenc_conn_o;

wire [ENC_NUM-1:0]  INENC_PROTOCOL;
wire [ENC_NUM-1:0]  OUTENC_PROTOCOL;
reg  [4*32-1:0]     TEMP_MON;
reg  [7*32-1:0]     VOLT_MON;   


// BUFFER problem 
// Slow FPGA Slave inside the SLOW FPGA
//ERROR: [VRFC 10-716] formal port inenc_protocol of mode out cannot be associated with actual port inenc_protocol of mode buffer [/home/zhz92437/code_panda/PandaFPGA/SlowFPGA/src/hdl/zynq_interface.vhd:119]
//ERROR: [VRFC 10-716] formal port outenc_protocol of mode out cannot be associated with actual port outenc_protocol of mode buffer [/home/zhz92437/code_panda/PandaFPGA/SlowFPGA/src/hdl/zynq_interface.vhd:120]
//zynq_interface_wrapper (
//    .clk_i              ( clk50             ),
//    .reset_i            ( rst_i             ),
//
//    .spi_sclk_o         ( spi_csn_o         ),
//    .spi_sclk_i         ( spi_sclk_o        ),
//    .spi_dat_o          ( spi_dat_i         ),
//    .spi_dat_i          ( spi_dat_o         ),
//
//    .ttlin_term_o       ( ttlin_term_o      ),
//    .ttl_leds_o         ( ttl_leds_o        ),  
//    .status_leds        ( status_leds       ),  
//    .enc_leds_o         ( enc_leds_o        ),  
//    .outenc_conn_o      ( outenc_conn_o     ),
//    
//    .INENC_PROTOCOL     ( INENC_PROTOCOL    ),
//    .OUTENC_PROTOCOL    ( OUTENC_PROTOCOL   ),
//    .DCARD_MODE         ( DCARD_MODE        ),
//    .TEMP_MON           ( TEMP_MON          ),
//    .VOLT_MON           ( VOLT_MON          )
//);


endmodule

