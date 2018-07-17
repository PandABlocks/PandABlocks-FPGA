`timescale 1ns / 1ps

module outenc_tb;

parameter C_MODE = 1;

// Inputs
reg         clk_i = 0;
reg         reset_i;
reg         a_ext_i;
reg         b_ext_i;
reg         z_ext_i;
reg         data_ext_i;
reg [31:0]  posn_i = 32'hFFFFFFFF;
reg         enable_i;
reg [2:0]   PROTOCOL;
//reg         BYPASS = 0;
reg [1:0]   MODE = C_MODE;
reg [7:0]   BITS = 32;
reg [31:0]  QPERIOD;

reg  [31:0] CLK_PERIOD = 100;
reg  [31:0] FRAME_PERIOD = 50;
reg         ssi_dat_i;

// Outputs
wire        A_OUT;
wire        B_OUT;
wire        Z_OUT;
wire        DATA_OUT;
reg         CLK_IN;
wire [31:0] QSTATE; 

wire        ssi_sck_o;
wire [31:0] ssi_posn_o;
wire        ssi_posn_valid_o;        


wire        biss_sck_o;
reg         biss_dat_i;
wire [31:0] biss_posn_o;
wire        biss_posn_valid_o;

reg         biss_not_ssi = C_MODE[0];
  

always #4 clk_i = !clk_i;

// Instantiate the Unit Under Test (UUT)
outenc uut (
        .clk_i          ( clk_i         ), 
        .reset_i        ( reset_i       ), 
        .a_ext_i        ( a_ext_i       ), 
        .b_ext_i        ( b_ext_i       ), 
        .z_ext_i        ( z_ext_i       ), 
        .data_ext_i     ( data_ext_i    ), 
        .posn_i         ( posn_i        ), 
        .enable_i       ( enable_i      ), 

        .A_OUT          ( A_OUT         ), 
        .B_OUT          ( B_OUT         ), 
        .Z_OUT          ( Z_OUT         ), 
        .DATA_OUT       ( DATA_OUT      ), 
        .CLK_IN         ( CLK_IN        ),        

        .PROTOCOL       ( PROTOCOL      ), 
//        .BYPASS         ( BYPASS        ),   
        .MODE           ( MODE          ),
        .BITS           ( BITS          ), 
        .QPERIOD        ( QPERIOD       ),
        .QPERIOD_WSTB   ( QPERIOD_WSTB  ),
        .QSTATE         ( QSTATE        )
);



//assign CLK_IN = ssi_sck_o;
//assign ssi_dat_i = DATA_OUT;

always @(biss_not_ssi, DATA_OUT, ssi_sck_o, biss_sck_o)
begin
    if (biss_not_ssi == 0) begin
        CLK_IN = ssi_sck_o;
        ssi_dat_i = DATA_OUT;
    end else begin
        CLK_IN = biss_sck_o;
        biss_dat_i = DATA_OUT;
   end
end            


always @(biss_not_ssi, ssi_posn_valid_o, biss_posn_valid_o)
begin
    if (biss_not_ssi == 0) begin
        if (ssi_posn_valid_o == 1) begin
            posn_i = posn_i + 32'ha5a5a5a5;        
        end
    end else begin
        if (biss_posn_valid_o == 1) begin
            posn_i = posn_i + 32'ha5a5a5a5;
        end 
    end
end             
    


ssi_master ssi_master_uut(
        .clk_i          ( clk_i             ),
        .reset_i        ( reset_i           ),
        .BITS           ( BITS              ),
        .CLK_PERIOD     ( CLK_PERIOD        ),
        .FRAME_PERIOD   ( FRAME_PERIOD      ),
        .ssi_sck_o      ( ssi_sck_o         ),
        .ssi_dat_i      ( ssi_dat_i         ),
        .posn_o         ( ssi_posn_o        ),
        .posn_valid_o   ( ssi_posn_valid_o  )
);                 


biss_master biss_master_uut(
        .clk_i          ( clk_i             ),
        .reset_i        ( reset_i           ),
        .BITS           ( BITS              ),
        .CLK_PERIOD     ( CLK_PERIOD        ),
        .FRAME_PERIOD   ( FRAME_PERIOD      ),
        .biss_sck_o     ( biss_sck_o        ),
        .biss_dat_i     ( biss_dat_i        ),
        .posn_o         ( biss_posn_o       ),
        .posn_valid_o   ( biss_posn_valid_o )
);         


initial begin
    reset_i = 1;
    a_ext_i = 0;
    b_ext_i = 0;
    z_ext_i = 0;
    data_ext_i = 0;
    posn_i = 0;
    enable_i = 0;
    PROTOCOL = 0;
    QPERIOD = 125;

    repeat(100) @(posedge clk_i);
    reset_i = 0;
        
    repeat(1250) @(posedge clk_i);

    repeat(125) @(posedge clk_i);
    enable_i = 1;
    repeat(125) @(posedge clk_i);
//    posn_i = 1000;
    repeat(1250) @(posedge clk_i);
//    posn_i = 7;
    //
    repeat(1250) @(posedge clk_i);
//    posn_i = 21;

    repeat(1250) @(posedge clk_i);
//    posn_i = 200;

    repeat(1250) @(posedge clk_i);
//    posn_i = 9;

    
    repeat(12500) @(posedge clk_i);
    $finish;
end

endmodule

