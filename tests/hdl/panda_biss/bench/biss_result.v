`timescale 1ns / 1ps


module biss_result
    (
     input             clk_i,
     input             reset_i,
     input             ssi_sck_i,
     input             ssi_dat_i,
     input [7:0]       BITS,
     output reg        result_ready,
     output reg [31:0] data_result,
     output reg [1:0]  nEnW_data,
     output reg [5:0]  CRC_data
     );  


parameter BISS_SYNCH = 0;
parameter BISS_ACK = 1;
parameter BISS_START = 2;
parameter BISS_ZERO = 3;
parameter BISS_DATA = 4;
parameter BISS_nEnW = 5;
parameter BISS_CRC = 6;
parameter BISS_TIMEOUT = 7; 


reg [3:0]   SM_BISS = 0;
reg         ssi_sck_prev;
wire        ssi_sck_rising_edge;
reg [7:0]   data_cnt = 0;
reg [31:0]  data;
reg [11:0]  timeout_cnt;



// Find the rising edge of the ssi_sck clock 
assign ssi_sck_rising_edge = !ssi_sck_prev & ssi_sck_i; 



always @(posedge clk_i)
begin        
    // Hack to get this work (#1)    
    #1 ssi_sck_prev <= ssi_sck_i;

    case (SM_BISS)
       // BiSS Synch state
       BISS_SYNCH:
       begin
            data_cnt <= 0;
            timeout_cnt <= 0;
            if (ssi_sck_i == 0 && ssi_dat_i == 0) begin
               SM_BISS <= BISS_ACK;
            end 
       end
       // BiSS ACK state
       BISS_ACK:
       begin
            if (ssi_sck_rising_edge == 1 && ssi_dat_i == 0) begin
                SM_BISS <= BISS_START;
            end
       end         
       // BiSS START state
       BISS_START:
       begin
            if (ssi_sck_rising_edge == 1 && ssi_dat_i == 1) begin
                SM_BISS <= BISS_ZERO;
            end 
       end 
       // BiSS ZERO state
       BISS_ZERO: 
       begin
            if (ssi_sck_rising_edge == 1 && ssi_dat_i == 0) begin
                SM_BISS <= BISS_DATA;
            end 
       end
       // BiSS DATA state
       BISS_DATA:
       begin
            if (ssi_sck_rising_edge == 1) begin
                data_cnt <= data_cnt +1;
                data[31 - data_cnt] <= ssi_dat_i;
                // This work from 1 to 32 bits
                if (data_cnt == BITS-1) begin
                    SM_BISS <= BISS_nEnW;
                end
            end
       end                                         
       // BiSS nEnW state
       // nE error flag
       // nW warning flag 
       BISS_nEnW:
       begin
            if (ssi_sck_rising_edge == 1) begin
                data_cnt <= data_cnt +1;
                nEnW_data[33-data_cnt] <= ssi_dat_i; 
                if (data_cnt == BITS+1) begin
                    SM_BISS <= BISS_CRC;
                end 
            end                   
       end    
       // BiSS CRC state      
       BISS_CRC:
       begin
            if (ssi_sck_rising_edge == 1) begin
                data_cnt <= data_cnt +1;
                CRC_data[39-data_cnt] <= ssi_dat_i;
                if (data_cnt == BITS+7) begin
                    data_result <= data;
                    SM_BISS <= BISS_TIMEOUT;
                end
            end               
       end  
       // Time out state 
       BISS_TIMEOUT: 
       begin
            if (timeout_cnt == 200) begin
                result_ready = 1;
            end else if (timeout_cnt == 210) begin     
                result_ready <= 0;
            end
            timeout_cnt <= timeout_cnt +1;
            // Wait for 20us 
            if (timeout_cnt == 2500) begin
                SM_BISS <= BISS_SYNCH;
            end
       end                              
    endcase;
end      


endmodule
