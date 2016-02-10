module test;

`include "./addr_defines.v"

panda_pcap_tb tb();

reg [ 1:0]      wrs, rsp;
reg [31:0]      IRQ_STATUS;
reg [ 7:0]      IRQ_FLAGS;
reg [15:0]      SMPL_COUNT;
reg [31:0]      dma_addr;
reg [31:0]      addr;
reg [31:0]      base;
reg [31:0]      total_samples;
reg [31:0]      addr_table[1023: 0];
reg [31:0]      smpl_table[1023: 0];
reg [31:0]      read_data;
reg [31:0]      readback;
reg [31:0]      read_addr;
reg             active;

integer         fid;
integer         r;
integer         len;
integer         irq_count;
integer         data;
integer         i, n, j;
integer         NUMSAMPLE;

// Wrapper for Zynx AXI4 transactions.
task REG_WRITE;
    input [31: 0] base;
    input [31: 0] addr;
    input [31: 0] val;
begin
    tb.zynq.ps.inst.write_data(base + 4*addr,  4, val, wrs);
end
endtask

task REG_READ;
    input  [31: 0] base;
    input  [31: 0] addr;
    output [31: 0] val;
begin
    tb.zynq.ps.inst.read_data(base + 4*addr,  4, val, wrs);
end
endtask

task WAIT_IRQ;
    input  [31: 0] status;
begin
    // Wait for DMA irq
    tb.zynq.ps.inst.wait_interrupt(0,IRQ_STATUS);
end
endtask


`include "./apis_tb.v"

initial begin
    repeat(2) @(posedge tb.FCLK_CLK0);

    /* Disable the function and channel level infos from BFM */
    tb.zynq.hp1.cdn_axi3_master_bfm_inst.RESPONSE_TIMEOUT = 0;
    tb.zynq.hp1.cdn_axi3_master_bfm_inst.set_channel_level_info(0);
    tb.zynq.hp1.cdn_axi3_master_bfm_inst.set_function_level_info(0);

    tb.zynq.ps.inst.set_function_level_info("ALL",0);
    tb.zynq.ps.inst.set_channel_level_info("ALL",0);
end

initial begin
    addr = 32'h1000_0000;
    read_addr = 32'h1000_0000;

    // AXI BFM
    wait(tb.tb_ARESETn === 0) @(posedge tb.FCLK_CLK0);
    wait(tb.tb_ARESETn === 1) @(posedge tb.FCLK_CLK0);

    $display("Reset Done. Setting the Slave profiles \n");

    tb.zynq.ps.inst.set_slave_profile("S_AXI_HP0",2'b11);
    tb.zynq.ps.inst.set_slave_profile("S_AXI_HP1",2'b11);
    $display("Profile Done\n");

    repeat(1250) @(posedge tb.FCLK_CLK0);

    $display("Running FRAMING TEST...");

    base = 32'h43C1_1000;
    addr = 32'h1000_0000;
    read_addr = 32'h1000_0000;
    irq_count = 0;
    total_samples = 0;

    // Setup Position Capture
    REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
    REG_WRITE(REG_BASE, REG_PCAP_WRITE, 12);    // counter #1
    REG_WRITE(REG_BASE, REG_PCAP_WRITE, 13);    // counter #2

    // TTL Inputs are coming from *_tb.vhd
    REG_WRITE(PCAP_BASE, PCAP_ENABLE,  0);      // TTL #0
    REG_WRITE(PCAP_BASE, PCAP_FRAME,   1);      // TTL #1
    REG_WRITE(PCAP_BASE, PCAP_CAPTURE, 2);      // TTL #2

    REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MASK, 32'h180);
    REG_WRITE(REG_BASE, REG_PCAP_FRAMING_ENABLE, 0);
    REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MODE, 0);

    REG_WRITE(DRV_BASE, DRV_PCAP_BLOCK_SIZE, tb.BLOCK_SIZE);
    REG_WRITE(DRV_BASE, DRV_PCAP_TIMEOUT, 2500);
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_RESET, 1);     // DMA reset
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   // Init
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_START, 1);     // ...
    addr = addr + tb.BLOCK_SIZE;                    //
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   //

    REG_WRITE(REG_BASE, REG_PCAP_ARM, 1);

fork begin
    `include "../../panda_top/bench/irq_handler.v"
end

join

    repeat(1250) @(posedge tb.FCLK_CLK0);
    $finish;
end

endmodule
