`timescale 1ns / 1ps

module event_dbus_tb;

parameter k28_5              = 8'hBC;
parameter c_code_heartbeat   = 8'h7A;
parameter c_code_reset_presc = 8'h7B;
parameter c_code_event_code  = 8'h7C;
parameter c_code_reset_event = 8'h7D;
parameter c_code_seconds_0   = 8'h70;
parameter c_code_seconds_1   = 8'h71;  


reg          clk=0;
reg          cclk=0;
reg          sclk=0;
reg          bclk=0;
reg          mclk=0;

reg  [7:0]   event_codes;
reg  [11:0]  event_cnt=0; // 4096 


reg          reset_i;
reg  [1:0]   rxdisperr_i=0; 
reg  [1:0]   rxnotintable_i=0;
reg  [1:0]   rxcharisk_i;
//reg  [31:0]  EVENT1=32'h00000110;
//reg  [31:0]  EVENT2=32'h00000120;
//reg  [31:0]  EVENT3=32'h00000140;
reg  [31:0]  EVENT1=32'h0000007C;
reg  [31:0]  EVENT2=32'h0000007B;
reg  [31:0]  EVENT3=32'h0000007A;
reg  [31:0]  EVENT4=32'h00000180;
wire         rx_link_ok_o;
wire         bit1_o;
wire         bit2_o;
wire         bit3_o;
wire         bit4_o;
wire         loss_lock;
wire         rx_error_o;        
wire [31:0]  utime_o;


//wire [7:0]  dbus;
reg [15:0] txdata;

always #4 clk = !clk;
always #8192 cclk = !cclk;
always #512 sclk = !sclk;
always #256 bclk = !bclk;
always #1024 mclk = !mclk;

initial begin
    reset_i = 1;
    #128
    reset_i = 0;
end     


always@(posedge clk)begin
    event_cnt <= event_cnt +1;
    if (event_cnt == 12'b000001111111) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_heartbeat;
    end else if (event_cnt == 12'b000001000000) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_reset_presc;
    end else if (event_cnt == 12'b000100010001) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_event_code;
    end else if (event_cnt == 4062) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4063) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4064) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4065) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0; // 1
    end else if (event_cnt == 4066) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4067) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4068) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4069) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1; // 2
    end else if (event_cnt == 4070) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4071) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4072) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4073) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0; // 3
    end else if (event_cnt == 4074) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4075) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4076) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4077) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1; // 4
    end else if (event_cnt == 4078) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4079) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4080) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4081) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0; // 5
    end else if (event_cnt == 4082) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4083) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4084) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4085) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1; // 6
    end else if (event_cnt == 4086) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4087) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4088) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4089) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0; // 7
    end else if (event_cnt == 4090) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4091) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    end else if (event_cnt == 4092) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    end else if (event_cnt == 4093) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1; // 8
    end else if (event_cnt == 4094) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_reset_event;
    end else if (event_cnt[0] == 1) begin
        rxcharisk_i <= 1;
        event_codes <= k28_5;    
    end else begin
        rxcharisk_i <= 0;
        event_codes <= 0;
    end 
end         


always@(posedge clk) begin
    txdata = {cclk, sclk, bclk, mclk, 4'h0, event_codes}; 
end


integer file;     
initial begin
    file = $fopen("output.txt", "w");
    #100000;
    $fclose(file);
end


always@(posedge clk)
begin
    $fwrite(file, "%h\n", txdata);
end
        

sfp_receiver #(.events(4)) 
         uut(
          .clk_i              ( clk            ),
          .reset_i            ( reset_i        ),
          .rxdisperr_i        ( rxdisperr_i    ),
          .rxcharisk_i        ( rxcharisk_i    ),    
          .rxdata_i           ( txdata         ),
          .rxnotintable_i     ( rxnotintable_i ),
          .EVENT1             ( EVENT1         ),
          .EVENT2             ( EVENT2         ),
          .EVENT3             ( EVENT3         ),
          .EVENT4             ( EVENT4         ),
          .rx_link_ok_o       ( rx_link_ok_o   ),
          .loss_lock_o        ( loss_lock      ),   
          .rx_error_o         ( rx_error_o     ),           
          .bit1_o             ( bit1_o         ),
          .bit2_o             ( bit2_o         ),
          .bit3_o             ( bit3_o         ),
          .bit4_o             ( bit4_o         ),
          .utime_o            ( utime_o        )
          );

                     
endmodule    
