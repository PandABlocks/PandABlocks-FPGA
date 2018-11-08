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
reg          event_clk_i=0;
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
reg          EVENT1_WSTB;
reg  [31:0]  EVENT2=32'h0000007B;
reg          EVENT2_WSTB;
reg  [31:0]  EVENT3=32'h0000007A;
reg          EVENT3_WSTB;
reg  [31:0]  EVENT4=32'h00000180;
reg          EVENT4_WSTB;
wire         rx_link_ok_o;
wire         bit1_o;
wire         bit2_o;
wire         bit3_o;
wire         bit4_o;
wire         loss_lock;
wire         rx_error_o;        
reg  [3:0]   write_cnt=0;    

//wire [7:0]  dbus;
reg [15:0] txdata;

wire [7:0] dbus_comp [3:0];

always #4 clk = !clk;
//always #4.00256164 event_clk_i = !event_clk_i;
always #4 event_clk_i = !event_clk_i;
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
    if (reset_i == 0) begin
        if (write_cnt < 5) begin
            write_cnt <= write_cnt +1;
        end
        // Generate the write strobe for the EVENT1 reg update
        if (write_cnt == 0) begin
            EVENT1_WSTB <= 1;
            EVENT2_WSTB <= 0;
            EVENT3_WSTB <= 0;
            EVENT4_WSTB <= 0;            
        // Generate the write strobe for the EVENT2 reg update
        end else if (write_cnt == 1) begin
            EVENT1_WSTB <= 0;
            EVENT2_WSTB <= 1;
            EVENT3_WSTB <= 0;
            EVENT4_WSTB <= 0;            
        // Generate the write strobe for the EVENT3 reg update            
        end else if (write_cnt == 2) begin
            EVENT1_WSTB <= 0;
            EVENT2_WSTB <= 0;
            EVENT3_WSTB <= 1;
            EVENT4_WSTB <= 0;            
        // Generate the write strobe for the EVENT4 reg update            
        end else if (write_cnt == 3) begin
            EVENT1_WSTB <= 0;
            EVENT2_WSTB <= 0;
            EVENT3_WSTB <= 0;
            EVENT4_WSTB <= 1;
        // Disable all write strtobes             
        end else if (write_cnt == 4) begin
            EVENT1_WSTB <= 0;
            EVENT2_WSTB <= 0;
            EVENT3_WSTB <= 0;
            EVENT4_WSTB <= 0;            
        end
    end
end                    


// Event code generator
always@(posedge event_clk_i)begin
    event_cnt <= event_cnt +1;
    // Heartbeat event
    if (event_cnt == 12'b000001111111) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_heartbeat;
    // Reset_presc event 
    end else if (event_cnt == 12'b000001000000) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_reset_presc;
    // Event code event
    end else if (event_cnt == 12'b000100010001) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_event_code;
    // Second event
    end else if (event_cnt == 4062) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4063) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4064) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4065) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0; // 1
    // Second event
    end else if (event_cnt == 4066) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4067) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4068) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4069) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1; // 2
    // Second event
    end else if (event_cnt == 4070) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4071) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4072) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4073) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0; // 3
    // Second event
    end else if (event_cnt == 4074) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4075) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4076) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4077) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1; // 4
    // Second event
    end else if (event_cnt == 4078) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4079) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4080) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4081) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0; // 5
    // Second event
    end else if (event_cnt == 4082) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4083) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4084) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4085) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1; // 6
    // Second event
    end else if (event_cnt == 4086) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4087) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4088) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4089) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0; // 7
    // Second event
    end else if (event_cnt == 4090) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4091) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1;
    // Second event
    end else if (event_cnt == 4092) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_0;
    // Second event
    end else if (event_cnt == 4093) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_seconds_1; // 8
    // Reset event
    end else if (event_cnt == 4094) begin
        rxcharisk_i <= 0;
        event_codes <= c_code_reset_event;
    // BC synch K character 
    end else if (event_cnt[0] == 1) begin
        rxcharisk_i <= 0;
        event_codes <= k28_5;    
    // Empty 
    end else begin
        rxcharisk_i <= 0;
        event_codes <= 0;
    end 
end         


// Package the data
// Name           bit     
// cclk         - 15
// sclk         - 14
// bclk         - 13
// mclk         - 12
// empty        - 11 - 8
// event_codes  -  7 - 0   
always@(posedge event_clk_i) begin
    txdata = {cclk, sclk, bclk, mclk, 4'h0, event_codes}; 
end
     
     
// And the EVENT registers with the data being sent
// If the result of the ANDing is not then there is
// a match
assign dbus_comp[0] = EVENT1[7:0] & txdata[15:8];
assign dbus_comp[1] = EVENT2[7:0] & txdata[15:8];
assign dbus_comp[2] = EVENT3[7:0] & txdata[15:8];
assign dbus_comp[3] = EVENT4[7:0] & txdata[15:8];
     
     
     
integer i;
reg [8:0] EVENTS [3:0];
reg [3:0] EVENT_STROBES;
reg [3:0] EVENT_STROBES1;
reg [3:0] EVENT_STROBES2;
always@(posedge event_clk_i) begin
    EVENTS[0] <= EVENT1[8:0];
    EVENTS[1] <= EVENT2[8:0];
    EVENTS[2] <= EVENT3[8:0];
    EVENTS[3] <= EVENT4[8:0];
    for (i=0; i<4; i=i+1) begin
        // Check for events or clocks passed out on the dbus event 
        if ((EVENTS[i][8] == 0 && EVENTS[i][7:0] == txdata[7:0] && rxcharisk_i[0] == 0) ||
           (EVENTS[i][8] == 1 && dbus_comp[i] !== 8'h00 && rxcharisk_i[1] == 0)) begin
           EVENT_STROBES[i] <= 1;
        end else begin
            EVENT_STROBES[i] <= 0;
        end
        // 
        EVENT_STROBES1 <= EVENT_STROBES;
        EVENT_STROBES2 <= EVENT_STROBES1;
    end           
end          
     

// Write out to a file
//integer file;     
//initial begin
//    file = $fopen("output.txt", "w");
//    #100000;
//    $fclose(file);
//end


//always@(posedge clk)
//begin
//    $fwrite(file, "%h\n", txdata);
//end
        

sfp_receiver #(.events(4)) 
         uut(
          .clk_i              ( clk            ),
          .event_clk_i        ( event_clk_i    ),   
          .reset_i            ( reset_i        ),
          .rxdisperr_i        ( rxdisperr_i    ),
          .rxcharisk_i        ( rxcharisk_i    ),    
          .rxdata_i           ( txdata         ),
          .rxnotintable_i     ( rxnotintable_i ),
          .EVENT1             ( EVENT1         ),
          .EVENT1_WSTB        ( EVENT1_WSTB    ),         
          .EVENT2             ( EVENT2         ),
          .EVENT2_WSTB        ( EVENT2_WSTB    ),         
          .EVENT3             ( EVENT3         ),
          .EVENT3_WSTB        ( EVENT3_WSTB    ),         
          .EVENT4             ( EVENT4         ),
          .EVENT4_WSTB        ( EVENT4_WSTB    ),         
          .rx_link_ok_o       ( rx_link_ok_o   ),
          .loss_lock_o        ( loss_lock      ),   
          .rx_error_o         ( rx_error_o     ),           
          .bit1_o             ( bit1_o         ),
          .bit2_o             ( bit2_o         ),
          .bit3_o             ( bit3_o         ),
          .bit4_o             ( bit4_o         )
          );

                     
endmodule    
