`timescale 1ns / 1ps

module panda_slowctrl_tb;

// Inputs
reg rst_i;
reg clk_i = 0;
reg clk50 = 0;
reg         wr_req_i;
reg [31: 0] wr_dat_i;
reg [9 : 0] wr_adr_i;
reg         spi_sclk_i;
reg         spi_dat_i;

// Outputs
wire busy_o;
wire spi_sclk_o;
wire spi_dat_o;
wire [31: 0] rd_dat_o;
wire [9 : 0] rd_adr_o;
wire         rd_val_o;

always #4 clk_i = !clk_i;
always #10 clk50 = !clk50;

initial begin
    rst_i = 1;
    repeat(10) @(posedge clk_i);
    rst_i = 0;
end

// Instantiate the Unit Under Test (UUT)
panda_slowctrl uut (
    .clk_i      ( clk_i         ),
    .reset_i    ( rst_i         ),
    .wr_req_i   ( wr_req_i      ),
    .wr_dat_i   ( wr_dat_i      ),
    .wr_adr_i   ( wr_adr_i      ),
    .rd_adr_o   ( rd_adr_o      ),
    .rd_dat_o   ( rd_dat_o      ),
    .rd_val_o   ( rd_val_o      ),
    .busy_o     ( busy_o        ),
    .spi_sclk_o ( spi_sclk_o    ),
    .spi_dat_o  ( spi_dat_o     ),
    .spi_sclk_i ( spi_sclk_o    ),
    .spi_dat_i  ( spi_dat_o     )
);

initial begin
        // Initialize Inputs
        wr_req_i = 0;
        wr_dat_i = 0;
        wr_adr_i = 0;
        repeat(1250) @(posedge clk_i);
        wr_req_i = 1;
        wr_dat_i = 32'h55AA55AA;
        wr_adr_i = 10'h3AA;
        repeat(1) @(posedge clk_i);
        wr_req_i = 0;
        wr_dat_i = 0;
        wr_adr_i = 0;
        repeat(1250) @(posedge clk_i);
        wr_req_i = 1;
        wr_dat_i = 32'hAA55AA55;
        wr_adr_i = 10'h355;
        repeat(1) @(posedge clk_i);
        wr_req_i = 0;
        wr_dat_i = 0;
        wr_adr_i = 0;
        repeat(1250) @(posedge clk_i);
end

reg  [31:0]  slw_dat_i = 32'h12345678;
wire [31:0]  slw_dat_o;
wire [ 9:0]  slw_addr_o;
wire         slw_wstb_o;
wire         slw_busy_o;

//// Slow FPGA Slave
//slow_spicore slow_spicore_inst (
//    .clk_i              ( clk50             ),
//    .reset_i            ( rst_i             ),
//
//    .dat_i              ( slw_dat_i         ),
//    .dat_o              ( slw_dat_o         ),
//    .addr_o             ( slw_addr_o        ),
//    .wstb_o             ( slw_wstb_o        ),
//    .busy_o             ( slw_busy_o        ),
//
//    .spi_csn_i          ( spi_csn_o         ),
//    .spi_sclk_i         ( spi_sclk_o        ),
//    .spi_dat_o          ( spi_dat_i         ),
//    .spi_dat_i          ( spi_dat_o         )
//);


endmodule

