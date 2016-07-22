$display("Running Position Based Snake Scan Test...");

base = 32'h43C1_1000;
addr = 32'h1000_0000;
read_addr = 32'h1000_0000;
irq_count = 0;
total_samples = 0;
pcap_armed = 0;
pcap_completed = 0;
arm = 0;
enable = 0;
capture = 0;

$display("Start Preload \n");
tb.uut.ps.ps.ps.inst.pre_load_mem_from_file("pcomp_ddr.txt",32'h0001_0000,1024);
tb.uut.ps.ps.ps.inst.pre_load_mem_from_file("pcomp_neg_ddr.txt",32'h0002_0000,1024);

tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h1);
tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h0);

// Incremental protocol
repeat(500) @(posedge tb.uut.FCLK_CLK0);
REG_WRITE(INENC_BASE, INENC_PROTOCOL, 1);
repeat(12500) @(posedge tb.uut.FCLK_CLK0);
REG_WRITE(INENC_BASE, INENC_BITS, 19);
repeat(12500) @(posedge tb.uut.FCLK_CLK0);
REG_WRITE(OUTENC_BASE, OUTENC_PROTOCOL, 1);
repeat(12500) @(posedge tb.uut.FCLK_CLK0);
REG_WRITE(OUTENC_BASE, OUTENC_BITS, 19);
repeat(12500) @(posedge tb.uut.FCLK_CLK0);

// Position Compare Block #0
REG_WRITE(PCOMP_BASE, PCOMP_ENABLE, PCAP_ACTIVE0);
REG_WRITE(PCOMP_BASE, PCOMP_INP, INENC_VAL0);
REG_WRITE(PCOMP_BASE, PCOMP_DELTAP, 10);
REG_WRITE(PCOMP_BASE, PCOMP_START, 100);
REG_WRITE(PCOMP_BASE, PCOMP_STEP, 0);
REG_WRITE(PCOMP_BASE, PCOMP_WIDTH, 900);
REG_WRITE(PCOMP_BASE, PCOMP_DIR, 0);
REG_WRITE(PCOMP_BASE, PCOMP_PNUM, 1);

REG_WRITE(PCOMP_BASE+32'h100, PCOMP_ENABLE, PCAP_ACTIVE0);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_INP, INENC_VAL0);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_DELTAP, 10);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_START, 1000);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_STEP, 0);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_WIDTH, 900);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_DIR, 1);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_PNUM, 1);

// Capture Block
REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, INENC_VAL0);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, INENC_VAL0);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, INENC_VAL0);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, INENC_VAL0);

REG_WRITE(PCAP_BASE, PCAP_ENABLE, LUT_OUT0);
REG_WRITE(PCAP_BASE, PCAP_ENABLE_DLY, 0);
REG_WRITE(PCAP_BASE, PCAP_CAPTURE, LUT_OUT3);

REG_WRITE(DRV_BASE, DRV_PCAP_BLOCK_SIZE, tb.BLOCK_SIZE);
REG_WRITE(DRV_BASE, DRV_PCAP_TIMEOUT, 0);

repeat(125) @(posedge tb.uut.ps.FCLK);

ARMS = 1;

fork

// Generate consecutive ARM signals.
begin
    for (k = 0; k < ARMS; k = k + 1) begin
        REG_WRITE(DRV_BASE, DRV_PCAP_DMA_RESET, 1);     // DMA Reset
        REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   // DMA Addr
        REG_WRITE(DRV_BASE, DRV_PCAP_DMA_START, 1);     // DMA Start
        addr = addr + tb.BLOCK_SIZE;                    //
        REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   // DMA Addr
        repeat(125) @(posedge tb.uut.ps.FCLK);
        REG_WRITE(REG_BASE, REG_PCAP_ARM, 1);           // PCAP Arm
        pcap_armed = 1;
        wait (pcap_completed == 1);
        //
        // Clear and Wait for new ARM
        //
        pcap_armed = 0;
        pcap_completed = 0;
        irq_count = 0;
        total_samples = 0;
        addr = 32'h1000_0000;
        read_addr = 32'h1000_0000;
        // Gap until next arming.
        repeat(12500) @(posedge tb.uut.FCLK_CLK0);
    end
    $finish;
end

begin
    `include "./irq_handler.v"
end

join
