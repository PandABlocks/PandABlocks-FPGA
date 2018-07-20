`timescale 1ns / 1ps


module panda_pcap_arming_tb;

// Inputs
reg clk_i = 0;
reg reset_i;
reg ARM;
reg DISARM;
reg enable_i;
reg abort_i;
reg ongoing_capture_i;
reg dma_fifo_ready_i;

// Outputs
wire dma_fifo_reset_o;
wire pcap_armed_o;
wire pcap_enabled_o;
wire [2:0] pcap_disarmed_o;

// Instantiate the Unit Under Test (UUT)
//panda_pcap_arming uut (
pcap_arming uut (  
        .clk_i(clk_i), 
        .reset_i(reset_i), 
        .ARM(ARM), 
        .DISARM(DISARM), 
        .enable_i(enable_i), 
        .abort_i(abort_i), 
        .ongoing_capture_i(ongoing_capture_i), 
        .dma_fifo_reset_o(dma_fifo_reset_o), 
        .dma_fifo_ready_i(dma_fifo_ready_i), 
        .pcap_armed_o(pcap_armed_o), 
        .pcap_enabled_o(pcap_enabled_o), 
        .pcap_disarmed_o(pcap_disarmed_o)
);

// Clock and Reset
always #4 clk_i = !clk_i;

initial begin
    reset_i = 1;
    repeat(10) @(posedge clk_i);
    reset_i = 0;
end

// Initial conditions
initial begin
end

//
// Values in the test files are arranged on FPGA clock ticks on the
// first column. This way all files are read syncronously.
//
// To achieve that a free running global Timestamp Counter below
// is used.
//
integer timestamp = 0;

initial begin
    while (1) begin
        @(posedge clk_i);
        timestamp <= timestamp + 1;
    end
end

//
// READ BLOCK INPUTS VECTOR FILE
//
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000

integer file, c, r;
reg [8192:0] line; /* Line of text read from file */

integer TS;

initial begin : file_block
    TS = 0;
    ARM = 0;
    DISARM = 0;
    enable_i = 0;
    abort_i = 0;
    ongoing_capture_i = 0;
    dma_fifo_ready_i = 0;
    repeat(3) @(posedge clk_i);

    file = $fopen("arming_in.txt", "r");
    if (file == `NULL) // If error opening file
        disable file_block; // Just quit

    c = $fgetc(file);
    while (c != `EOF) begin
        /* Check the first character for comment */
        if (c == "/") begin
            r = $fgets(line, file);
            $display("%s\n", line);
        end
        else begin
            // Push the character back to the file then read the next time
            r = $ungetc(c, file);
            r = $fscanf(file,"%d\n", TS);

            wait (TS == timestamp) begin
                $display("Timestamp = %d", TS);
                r = $fscanf(file, "%d %d %d %d %d %d\n", ARM, DISARM, enable_i, abort_i, ongoing_capture_i, dma_fifo_ready_i);
            end
        end
        c = $fgetc(file);
        @(posedge clk_i);
    end

    repeat(1250) @(posedge clk_i);
    $finish;
end

endmodule

