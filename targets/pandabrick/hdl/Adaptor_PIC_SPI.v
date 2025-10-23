//`timescale 1ns / 1ps

// =======  Transfer data to/from Adaptor-Board PIC Micro  =======
//
//	 Transfers 16-bit data word to (and from) the PIC periodically (every 2.5mS), no error checking.
//

module Adaptor_PIC_SPI(

	input	 		i_clk,        // 125MHz System (AXI) clock.
	output			o_PIC_SC,     // SPI Serial Clock
	output			o_PIC_CS,     // SPI Chip Select (low during transfer)
	output			o_PIC_DI,     // SPI PIC Data In (to PIC)
	input			i_PIC_DO,     // SPI PIC Data Out (from PIC) 
	output 			o_done,       // Transfer finished on Rising edge of this output.
	                              // 
	input	[15:0]	i_data,       // Data to send to the PIC
	                              //   UVWT read mode   - Axis 8-1 on i_data[15:8]  - '1' sets uvwt mode
	                              //   Serial Pass mode - Axis 8-1 on i_data[7:0]   - '1' sets pass-through mode
	                              //
	output	[15:0]	o_data        // Data received from the PIC
	                              //   LoS        - Axis 8-1 on o_data[15:8]
	                              //   LD Jumpers - Axis 8-1 on o_data[7:0]         - '0' if jumper fitted
);


// --------------------------------------

reg         CLK_OUT = 1;
reg         CS_OUT  = 1;
reg         SDO_OUT = 0;
reg  [7:0]	state;
reg  [7:0]	data_count;
reg			running = 0;
reg  [15:0] tx_shift_reg=0;
reg  [15:0] rx_shift_reg=0;
reg  [15:0] latched_o_data=0;

reg   [10:0] pic_clk_counter=0;
reg   [7:0] pic_frm_counter=0;
wire        slow_clk;
reg         clk_plse;
reg         pic_frm=0;

// --------------------------------------

// SPI Clock Generator...

always@(posedge i_clk)
begin
    if (pic_clk_counter==1250)  // = 100kHz, giving 50kHz SPI clock rate.
    begin
           clk_plse <= 1;
           pic_clk_counter <= 0;
    end
    else
    begin
           clk_plse <= 0;
           pic_clk_counter <= pic_clk_counter + 1;
    end
end 

BUFGCE #(
   .CE_TYPE("SYNC"),               // ASYNC, HARDSYNC, SYNC
   .IS_CE_INVERTED(1'b0),          // Programmable inversion on CE
   .IS_I_INVERTED(1'b0),           // Programmable inversion on I
   .SIM_DEVICE("ULTRASCALE_PLUS")  // ULTRASCALE, ULTRASCALE_PLUS
)

BUFGCE_inst (
   .O(slow_clk),
   .CE(clk_plse),
   .I(i_clk)
);

// SPI Frame rate generator...

always@(posedge slow_clk)
begin
    if (pic_frm_counter==250)   // Update every 2.5mS
    begin
        pic_frm <= 1;
        pic_frm_counter <= 0;
    end
    else
    begin
        pic_frm <= 0;
        pic_frm_counter <= pic_frm_counter + 1;
    end
end


// --------------------------------------

// Sequence:
//				idle... CS and SC both high.
//
//				(set i_start high to initiate transfer).
//					CS Low and set data bit
//					SC Low
//					SC High and set next data bit
//					  ...repeat last two lines for all 16 bits
//					CS High and flag done.
//
 
always@(posedge slow_clk)
begin

	if (pic_frm==1 && running==0)		// Detected Start input flag while not running
	begin
		state        <= 0;				// reset counters and start running
		data_count   <= 0;
		running      <= 1;
		tx_shift_reg <= i_data;
		rx_shift_reg <= 0;
	end

	
	
	if (running == 1)						// DATA TRANSFER...
	begin
	
		case (state)
	        0:  begin
	               CLK_OUT <= 1;                       // ensure clock high
	               state   <= 1;   
	            end
	        
	        1:  begin
	               CS_OUT  <= 0;				       // CS low
	               SDO_OUT <= tx_shift_reg[15];        // Set first bit
	               state   <= 2;   
	            end          
					
	        2:  begin
	               CLK_OUT    <= 0;				       // clock low
	               rx_shift_reg[0] <= i_PIC_DO;	       // read in data bit
	               tx_shift_reg <= tx_shift_reg<<1;    // shift TX ready for next bit
				   data_count <= data_count  + 1'b1;
				   state      <= 3;
	            end
	        
	        3:  begin
	               CLK_OUT <= 1;                       // clock high
	               SDO_OUT <= tx_shift_reg[15];        // Set next bit
	               
                    if (data_count==16) begin				   // check for end of word
				        state <= 4;
                        latched_o_data <= rx_shift_reg;
		            end else begin
						state <= 2;
                        rx_shift_reg <= rx_shift_reg<<1;       // shift RX ready for next bit
                    end
				end
				
			4:  begin
	                CS_OUT  <= 1;		                 // end of word, so CS high
				    CLK_OUT <= 1;
				    SDO_OUT <= 0;				
					running <= 0;                      // and stop.
				end

			
			default:	
				running <= 0;
			
		endcase
	
	end
	
end


// --------------------------------------


assign o_PIC_SC = CLK_OUT;

assign o_PIC_CS = CS_OUT;

assign o_PIC_DI = SDO_OUT;

assign o_done = ~running;

assign o_data = latched_o_data;


endmodule



