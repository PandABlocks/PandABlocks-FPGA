module test;

`include "./addr_defines.v"

// Inputs to testbench
wire [5:0]   ttlin_pad;

panda_pcap_tb tb (
    .ttlin_pad      ( ttlin_pad)
);

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
reg             pcap_completed;

integer         fid;
integer         r;
integer         len;
integer         irq_count;
integer         data;
integer         i, n, j, k, m;
integer         NUMSAMPLE;
integer         ARMS;

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

reg     arm, arm_prev, arm_rise;
reg     enable, enable_prev, enable_rise;
reg     capture;

initial begin
    arm_prev <= 0;
    enable_prev <= 0;
    arm_rise <= 0;
    enable_rise <= 0;
end

always @(posedge tb.FCLK_CLK0)
begin
    arm_prev <= arm;
    enable_prev <= enable;

    arm_rise <= arm & !arm_prev;
    enable_rise <= enable & !enable_prev;
end

assign ttlin_pad[0] = enable;
assign ttlin_pad[1] = 0;
assign ttlin_pad[2] = capture;
assign ttlin_pad[5:3] = 0;

initial begin
    base = 32'h43C1_1000;
    addr = 32'h1000_0000;
    read_addr = 32'h1000_0000;
    irq_count = 0;
    total_samples = 0;
    pcap_completed = 0;
    arm = 0;
    enable = 0;
    capture = 0;


    // AXI BFM
    wait(tb.tb_ARESETn === 0) @(posedge tb.FCLK_CLK0);
    wait(tb.tb_ARESETn === 1) @(posedge tb.FCLK_CLK0);

    $display("Reset Done. Setting the Slave profiles \n");

    tb.zynq.ps.inst.set_slave_profile("S_AXI_HP0",2'b11);
    tb.zynq.ps.inst.set_slave_profile("S_AXI_HP1",2'b11);
    $display("Profile Done\n");

    repeat(1250) @(posedge tb.FCLK_CLK0);

    $display("Running FRAMING TEST...");

    repeat(500) @(posedge tb.FCLK_CLK0);

    // Setup Position Capture
    REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
    REG_WRITE(REG_BASE, REG_PCAP_WRITE, 12);    // counter #1
    REG_WRITE(REG_BASE, REG_PCAP_WRITE, 13);    // counter #2
    REG_WRITE(REG_BASE, REG_PCAP_WRITE, 15);    // counter #4

    REG_WRITE(PCAP_BASE, PCAP_ENABLE,  2);      // TTL #0
    REG_WRITE(PCAP_BASE, PCAP_FRAME,   3);      // TTL #1
    REG_WRITE(PCAP_BASE, PCAP_CAPTURE, 4);      // TTL #2

    REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MASK, 32'h180);
    REG_WRITE(REG_BASE, REG_PCAP_FRAMING_ENABLE, 0);
    REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MODE, 0);

    REG_WRITE(DRV_BASE, DRV_PCAP_BLOCK_SIZE, tb.BLOCK_SIZE);
    REG_WRITE(DRV_BASE, DRV_PCAP_TIMEOUT, 0);
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_RESET, 1);     // DMA reset
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   // Init
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_START, 1);     // ...
    addr = addr + tb.BLOCK_SIZE;                    //
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   //

    NUMSAMPLE = 100;
    ARMS = 1;
fork

// Generate consecutive ARM signals.
begin

    for (k = 0; k < ARMS; k = k + 1) begin
        arm = 0;
        REG_WRITE(REG_BASE, REG_PCAP_ARM, 1);
        arm = 1;
        wait (pcap_completed == 1);
        pcap_completed = 0;
        repeat(12500) @(posedge tb.FCLK_CLK0);
    end

    $finish;
end

// Enable follows an arm_rise
begin

    while (1) begin
        wait (arm_rise == 1);
        repeat(1250) @(posedge tb.FCLK_CLK0);
        enable = 1;
        repeat(125)  @(posedge tb.FCLK_CLK0); // give time to capture
        wait (n == NUMSAMPLE - 1);
        repeat(250) @(posedge tb.FCLK_CLK0);
        enable = 0;
    end
end

// Capture @ 1MHz starts firing following enable_rise
begin

    while (1) begin
        wait (enable_rise == 1);
        for (n = 0; n < NUMSAMPLE; n = n+1) begin
            capture = 1;
            repeat(1) @(posedge tb.FCLK_CLK0);
            capture = 0;
            repeat(124) @(posedge tb.FCLK_CLK0);
        end
    end
end

// Frame
begin
//    for (i = 0; i < 10; i = i+1) begin
//        ttlin_pad[1] = 1;
//        repeat(500) @(posedge tb.FCLK_CLK0);
//        ttlin_pad[1] = 0;
//        repeat(1500) @(posedge tb.FCLK_CLK0);
//    end
end


begin
    `include "../../panda_top/bench/irq_handler.v"
end

join

    repeat(1250) @(posedge tb.FCLK_CLK0);
    $finish;
end

endmodule
