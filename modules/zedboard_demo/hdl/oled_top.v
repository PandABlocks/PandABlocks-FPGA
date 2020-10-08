`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Arthur Brown
// 
// Create Date: 10/1/2016
// Module Name: top
// Project Name: OLED Demo
// Tool Versions: Vivado 2016.4
// Description: creates OLED Demo, handles user inputs to operate OLED control module
// 
// Dependencies: OLEDCtrl.v, debouncer.v
// 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////

module oled_top
#(parameter FPGA_BUILD = 32'hFFFFFFFF)(
    input clk,
    input btnR,// CPU Reset Button turns the display on and off
    input btnC,// Center DPad Button turns every pixel on the display on or resets to previous state
    input btnD,// Upper DPad Button updates the delay to the contents of the local memory
    input btnU,// Bottom DPad Button clears the display
    output oled_sdin,
    output oled_sclk,
    output oled_dc,
    output oled_res,
    output oled_vbat,
    output oled_vdd,
    input [7:0] switch_set,
    input [7:0] led_set,
    input [1:0] oled_disp
//    output oled_cs,// used in Pmod OLED implementation
//    output [7:0] led
);
    //state machine codes
    localparam Idle       = 0;
    localparam Init       = 1;
    localparam Active     = 2;
    localparam Done       = 3;
    localparam FullDisp   = 4;
    localparam Write      = 5;
    localparam WriteWait  = 6;
    localparam UpdateWait = 7;
    
    //text to be displayed
    localparam str1=" PandABlocks", str1len=16;
    localparam str2=" on ZedBoard", str2len=16;
    localparam str3=" Demo!      ", str3len=16;
    //localparam str4=" Ver        ", str4len=16;
    localparam str4len=16;

    reg [95:0] str4 = 96'd0;

    wire [95:0] switch_val = {" SW = 0x", hexChar(switch_set[7:4]), hexChar(switch_set[3:0]), "  "};
    wire [95:0] leds_val =   {" LEDS = 0x", hexChar(led_set[7:4]), hexChar(led_set[3:0])};

    wire [95:0] version = 96'd0;
    assign version[95:72] = " 0x";
    assign version[71:64] = hexChar(FPGA_BUILD[31:28]);
    assign version[63:56] = hexChar(FPGA_BUILD[27:24]);
    assign version[55:48] = hexChar(FPGA_BUILD[23:20]);
    assign version[47:40] = hexChar(FPGA_BUILD[19:16]);
    assign version[39:32] = hexChar(FPGA_BUILD[15:12]);
    assign version[31:24] = hexChar(FPGA_BUILD[11:8]);
    assign version[23:16] = hexChar(FPGA_BUILD[7:4]);
    assign version[15:8]  = hexChar(FPGA_BUILD[3:0]);
    assign version[7:0]   = " ";

    always@(*)
        case (oled_disp)
            2'd0 : str4 = version;
            2'd1 : str4 = switch_val;
            2'd2 : str4 = leds_val;
            default : str4 = 96'd0;
        endcase
            
    localparam AUTO_START = 1; // determines whether the OLED will be automatically initialized when the board is programmed
    	
    //state machine registers.
    reg [2:0] state = (AUTO_START == 1) ? Init : Idle;
    reg [5:0] count = 0;//loop index variable
    reg       once = 0;//bool to see if we have set up local pixel memory in this session
        
    //oled control signals
    //command start signals, assert high to start command
    reg        update_start = 0;        //update oled display over spi
    reg        disp_on_start = AUTO_START;       //turn the oled display on
    reg        disp_off_start = 0;      //turn the oled display off
    reg        toggle_disp_start = 0;   //turns on every pixel on the oled, or returns the display to before each pixel was turned on
    reg        write_start = 0;         //writes a character bitmap into local memory
    //data signals for oled controls
    reg        update_clear = 0;        //when asserted high, an update command clears the display, instead of filling from memory
    reg  [8:0] write_base_addr = 0;     //location to write character to, two most significant bits are row position, 0 is topmost. bottom seven bits are X position, addressed by pixel x position.
    reg  [7:0] write_ascii_data = 0;    //ascii value of character to write to memory
    //active high command ready signals, appropriate start commands are ignored when these are not asserted high
    wire       disp_on_ready;
    wire       disp_off_ready;
    wire       toggle_disp_ready;
    wire       update_ready;
    wire       write_ready;
    
    //debounced button signals used for state transitions
    wire       rst;     // CPU RESET BUTTON turns the display on and off, on display_on, local memory is filled from string parameters
    wire       dBtnC;   // Center DPad Button tied to toggle_disp command 
    wire       dBtnU;   // Upper DPad Button tied to update without clear
    wire       dBtnD;   // Bottom DPad Button tied to update with clear
    	
	//instantiate OLED controller
    OLEDCtrl m_OLEDCtrl (
        .clk                (clk),              
        .write_start        (write_start),      
        .write_ascii_data   (write_ascii_data), 
        .write_base_addr    (write_base_addr),  
        .write_ready        (write_ready),      
        .update_start       (update_start),     
        .update_ready       (update_ready),     
        .update_clear       (update_clear),    
        .disp_on_start      (disp_on_start),    
        .disp_on_ready      (disp_on_ready),    
        .disp_off_start     (disp_off_start),   
        .disp_off_ready     (disp_off_ready),   
        .toggle_disp_start  (toggle_disp_start),
        .toggle_disp_ready  (toggle_disp_ready),
        .SDIN               (oled_sdin),        
        .SCLK               (oled_sclk),        
        .DC                 (oled_dc  ),        
        .RES                (oled_res ),        
        .VBAT               (oled_vbat),        
        .VDD                (oled_vdd )
    );
//    assign oled_cs = 1'b0;
/*
localparam line1 = {0,1,2,3,0,1,2,3,0,1,2,3,01,2,3};
localparam line2 = {4,5,6,7,4,5,6,7,4,5,6,74,5,6,7};
localparam line3 = {8,9,10,11,8,9,10,11,8,9,10,11,8,9,10,11};
localparam line4 = {12,13,14,15,12,131,14,15,12,13,14,15,12,131,14,15};
*/
//localparam line1 = {4{8'h0,8'h1,8'h2,8'h3}};
//localparam line2 = {4{8'h4,8'h5,8'h6,8'h7}};
//localparam line3 = {4{8'h8,8'h9,8'ha,8'hb}};
//localparam line4 = {4{8'hc,8'hd,8'he,8'hf}};
/*
localparam line1 = 0;
localparam line2 = 0;
localparam line3 = 0;
localparam line4 = 0;
*/

    always@(write_base_addr)
        case (write_base_addr[8:7])//select string as [y]
        0: write_ascii_data <= 8'hff & ({8'h0,8'h1,8'h2,8'h3,str1}     >> ({3'b0, (str1len - 1 - write_base_addr[6:3])} << 3));//index string parameters as str[x]
        1: write_ascii_data <= 8'hff & ({8'h4,8'h5,8'h6,8'h7,str2}     >> ({3'b0, (str2len - 1 - write_base_addr[6:3])} << 3));
        2: write_ascii_data <= 8'hff & ({8'h8,8'h9,8'ha,8'hb,str3}     >> ({3'b0, (str3len - 1 - write_base_addr[6:3])} << 3));
        3: write_ascii_data <= 8'hff & ({8'hc,8'hd,8'he,8'hf,str4}     >> ({3'b0, (str4len - 1 - write_base_addr[6:3])} << 3));
        endcase
/*
    always@(write_base_addr)
        case (write_base_addr[8:7])//select string as [y]
        0: write_ascii_data <= 8'hff & (line1     >> ({3'b0, (str1len - 1 - write_base_addr[6:3])} << 3));//index string parameters as str[x]
        1: write_ascii_data <= 8'hff & (line2     >> ({3'b0, (str2len - 1 - write_base_addr[6:3])} << 3));
        2: write_ascii_data <= 8'hff & (line3     >> ({3'b0, (str3len - 1 - write_base_addr[6:3])} << 3));
        3: write_ascii_data <= 8'hff & (line4     >> ({3'b0, (str4len - 1 - write_base_addr[6:3])} << 3));
        endcase
*/
    //debouncers ensure single state machine loop per button press. noisy signals cause possibility of multiple "positive edges" per press.
    debouncer #(
        .COUNT_MAX(65535),
        .COUNT_WIDTH(16)
    ) get_dBtnC (
        .clk(clk),
        .A(btnC),
        .B(dBtnC)
    );
    debouncer #(
        .COUNT_MAX(65535),
        .COUNT_WIDTH(16)
    ) get_dBtnU (
        .clk(clk),
        .A(btnU),
        .B(dBtnU)
    );
    debouncer #(
        .COUNT_MAX(65535),
        .COUNT_WIDTH(16)
    ) get_dBtnD (
        .clk(clk),
        .A(btnD),
        .B(dBtnD)
    );
    debouncer #(
        .COUNT_MAX(65535),
        .COUNT_WIDTH(16)
    )  get_rst (
        .clk(clk),
        .A(btnR),
        .B(rst)
    );
    
    //assign led = update_ready;//display whether btnU, BtnD controls are available..
    assign init_done = disp_off_ready | toggle_disp_ready | write_ready | update_ready;//parse ready signals for clarity
    assign init_ready = disp_on_ready;
    always@(posedge clk)
        case (state)
            Idle: begin
                if (rst == 1'b1 && init_ready == 1'b1) begin
                    disp_on_start <= 1'b1;
                    state <= Init;
                end
                once <= 0;
            end
            Init: begin
                disp_on_start <= 1'b0;
                if (rst == 1'b0 && init_done == 1'b1)
                    state <= Active;
            end
            Active: begin // hold until ready, then accept input
                if (rst && disp_off_ready) begin
                    disp_off_start <= 1'b1;
                    state <= Done;
                end else if (once == 0 && write_ready) begin
                    write_start <= 1'b1;
                    write_base_addr <= 'b0;
                    state <= WriteWait;
                end else if (once == 1 && dBtnU == 1) begin
                    update_start <= 1'b1;
                    update_clear <= 1'b0;
                    state <= UpdateWait;
                end else if (once == 1 && dBtnD == 1) begin
                    update_start <= 1'b1;
                    update_clear <= 1'b1;
                    state <= UpdateWait;
                end else if (dBtnC == 1'b1 && toggle_disp_ready == 1'b1) begin
                    toggle_disp_start <= 1'b1;
                    state <= FullDisp;
                end
            end
            Write: begin
                write_start <= 1'b1;
                write_base_addr <= write_base_addr + 9'h8;
                //write_ascii_data updated with write_base_addr
                state <= WriteWait;
            end
            WriteWait: begin
                write_start <= 1'b0;
                if (write_ready == 1'b1)
                    if (write_base_addr == 9'h1f8) begin
                        once <= 1;
                        state <= Active;
                    end else begin
                        state <= Write;
                    end
            end
            UpdateWait: begin
                update_start <= 0;
                if (dBtnU == 0 && init_done == 1'b1)
                    state <= Active;
            end
            Done: begin
                disp_off_start <= 1'b0;
                if (rst == 1'b0 && init_ready == 1'b1)
                    state <= Idle;
            end
            FullDisp: begin
                toggle_disp_start <= 1'b0;
                if (dBtnC == 1'b0 && init_done == 1'b1)
                    state <= Active;
            end
            default: state <= Idle;
        endcase

function [7:0] hexChar;
    input [3:0] hex_bits;
    case (hex_bits)
        4'h0 : hexChar = "0";
        4'h1 : hexChar = "1";
        4'h2 : hexChar = "2";
        4'h3 : hexChar = "3";
        4'h4 : hexChar = "4";
        4'h5 : hexChar = "5";
        4'h6 : hexChar = "6";
        4'h7 : hexChar = "7";
        4'h8 : hexChar = "8";
        4'h9 : hexChar = "9";
        4'ha : hexChar = "a";
        4'hb : hexChar = "b";
        4'hc : hexChar = "c";
        4'hd : hexChar = "d";
        4'he : hexChar = "e";
        4'hf : hexChar = "f";
        default : hexChar = "?";
    endcase
endfunction


endmodule
