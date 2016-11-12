module test;

`include "../../../src/hdl/autogen/addr_defines.v"
`include "../../../src/hdl/autogen/panda_bitbus.v"
`include "./apis_tb.v"

// Inputs to testbench
wire [5:0]   ttlin_pad;

`define TESTNAME    "test.pcap.v"

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
reg             pcap_armed;
reg             pcap_completed;
reg [31:0]      framing_mask;

integer         irq_count;
integer         i, n, j, k, m;
integer         NUMSAMPLE;
integer         ARMS;
integer         PGEN_REPEAT;
integer         PGEN_SAMPLES;

`include "tasks.v"

assign ttlin_pad[5:0] = 0;

// Instantiate Testbench
panda_top_tb tb(
    .pcap_armed     (   pcap_armed  )
);

initial begin
    wrs = 0; rsp = 0;
    IRQ_STATUS = 0;
    IRQ_FLAGS = 0;
    SMPL_COUNT = 0;
    NUMSAMPLE = 0;
    ARMS = 0;
    i = 0; n = 0; j = 0; k = 0; m = 0;

    // Initial RESET to Zynq
    wait(tb.uut.ps.tb_ARESETn === 0) @(posedge tb.uut.ps.FCLK);
    wait(tb.uut.ps.tb_ARESETn === 1) @(posedge tb.uut.ps.FCLK);

    $display("Reset Done. Setting the Slave profiles \n");
    tb.uut.ps.ps.ps.inst.set_slave_profile("S_AXI_HP0",2'b10);
    $display("Profile Done\n");

    /*
     * Start TEST Cases
     */
    `include `TESTNAME
end

endmodule
