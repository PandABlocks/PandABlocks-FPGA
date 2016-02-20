module test;

`include "./addr_defines.v"
`include "./apis_tb.v"

// Inputs to testbench
wire [5:0]   ttlin_pad;

panda_top_tb tb(
    .ttlin_pad      ( ttlin_pad)
);

//reg [511:0]     test_name = "COUNTER_TEST";
//reg [511:0]     test_name = "READBACK_BIT_TEST";
//reg [511:0]     test_name = "PCAP_TEST";
reg [511:0]     test_name = "FRAMING_TEST";
//reg [511:0]     test_name = "ENCODER_TEST";
//reg [511:0]     test_name = "DRIVER_TEST";
//reg [511:0]     test_name = "TIMEOUT_TEST";

reg [ 1:0]      wrs, rsp;
reg [31:0]      IRQ_STATUS;
reg [ 7:0]      IRQ_FLAGS;
reg [15:0]      SMPL_COUNT;
reg [31:0]      addr;
reg [31:0]      base;
reg [31:0]      total_samples;
reg [31:0]      addr_table[31: 0];
reg [31:0]      smpl_table[31: 0];
reg [31:0]      read_addr;
reg             pcap_completed;

integer         irq_count;
integer         n, j, k, m;
integer         NUMSAMPLE;
integer         ARMS;

`include "tasks.v"

assign ttlin_pad[0] = enable;
assign ttlin_pad[1] = 0;
assign ttlin_pad[2] = capture;
assign ttlin_pad[5:3] = 0;

initial begin
    wrs = 0; rsp = 0;
    IRQ_STATUS = 0;
    IRQ_FLAGS = 0;
    SMPL_COUNT = 0;
    NUMSAMPLE = 0;
    ARMS = 0;
    n = 0; j = 0; k = 0; m = 0;

    // Initial RESET to Zynq
    wait(tb.uut.ps.tb_ARESETn === 0) @(posedge tb.uut.ps.FCLK);
    wait(tb.uut.ps.tb_ARESETn === 1) @(posedge tb.uut.ps.FCLK);

    $display("Reset Done. Setting the Slave profiles \n");
    tb.uut.ps.ps.ps.inst.set_slave_profile("S_AXI_HP0",2'b11);
    $display("Profile Done\n");

    tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h1);
    tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h0);

    /*
     * Start TEST Cases
     */
    if (test_name == "FRAMING_TEST") begin
        `include "test.framing.v"
    end
    else begin
        $display("NO TEST SELECTED...");
        repeat(100000) @(posedge tb.uut.FCLK_CLK0);
        $finish;
    end
end

endmodule
