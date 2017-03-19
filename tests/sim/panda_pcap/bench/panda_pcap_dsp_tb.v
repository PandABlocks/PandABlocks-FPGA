`timescale 1ns / 1ps


module panda_pcap_dsp_tb;

// Inputs
reg clk_i = 0;
reg reset_i;
reg enable_i;
reg frame_i;
reg capture_i;
reg [31:0] FRAMING_MASK;
reg FRAMING_ENABLE;
reg [3:0] FRAMING_MODE;

// Outputs
wire capture_o;
wire [63:0] posn_o;

always #4 clk_i = !clk_i;

// Instantiate the Unit Under Test (UUT)
panda_pcap_dsp uut (
        .clk_i          ( clk_i             ),
        .reset_i        ( reset_i           ),
        .enable_i       ( enable_i          ),
        .frame_i        ( frame_i           ),
        .capture_i      ( capture_i         ),
        .FRAMING_MASK   ( FRAMING_MASK      ),
        .FRAMING_ENABLE ( FRAMING_ENABLE    ),
        .FRAMING_MODE   ( FRAMING_MODE      ),
        .capture_o      ( capture_o         )
//        .posn_o         ( posn_o            )
);

initial begin
    reset_i = 1;
    repeat(10) @(posedge clk_i);
    reset_i = 0;
end

integer i, n;

initial begin
    enable_i = 0;
    frame_i = 0;
    capture_i = 0;
    FRAMING_MASK = 0;
    FRAMING_ENABLE = 0;
    FRAMING_MODE = 0;
    repeat(1250) @(posedge clk_i);

    i = 0;
    n = 0;
    enable_i = 1;
    frame_i = 0;

    FRAMING_ENABLE = 1;
    repeat(1250) @(posedge clk_i);

fork
begin
    for (i = 0; i < 10; i = i+1) begin
        frame_i = 1;
        repeat(500) @(posedge clk_i);
        frame_i = 0;
        repeat(1500) @(posedge clk_i);
    end
end

begin
    repeat(500) @(posedge clk_i);
    for (n = 0; n < 5; n = n+1) begin
        capture_i = 1;
        repeat(500) @(posedge clk_i);
        capture_i = 0;
        repeat(3500) @(posedge clk_i);
    end
end

join

    repeat(1250) @(posedge clk_i);
    $finish;

end

endmodule

