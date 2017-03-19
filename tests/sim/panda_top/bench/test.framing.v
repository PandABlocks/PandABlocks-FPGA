$display("Running FRAMING TEST...");

base = 32'h43C1_1000;
addr = 32'h1000_0000;
read_addr = 32'h1000_0000;
irq_count = 0;
pcap_armed = 0;
total_samples = 0;
pcap_completed = 0;
arm = 0;
enable = 0;
capture = 0;
framing_mask = 0;

PGEN_REPEAT  = 2;
PGEN_SAMPLES = 5;

tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h1);
tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h0);

repeat(125) @(posedge tb.uut.ps.FCLK);

// Setup Position Capture
REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT0);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT2);


REG_WRITE(PCAP_BASE, PCAP_ENABLE,  BITS_ONE0);
REG_WRITE(PCAP_BASE, PCAP_FRAME,   TTLIN_VAL0);
REG_WRITE(PCAP_BASE, PCAP_CAPTURE, TTLIN_VAL1);
REG_WRITE(PCAP_BASE, PCAP_FRAME_NUM, 150);

framing_mask = framing_mask | (1 << COUNTER_OUT0);

REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MASK, framing_mask);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MODE, 0);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_ENABLE, 1);

REG_WRITE(DRV_BASE, DRV_PCAP_BLOCK_SIZE, tb.BLOCK_SIZE);
REG_WRITE(DRV_BASE, DRV_PCAP_TIMEOUT, 0);

repeat(125) @(posedge tb.uut.ps.FCLK);

ARMS = 2;

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
end
    `include "./irq_handler.v"
join

repeat(1250) @(posedge tb.uut.ps.FCLK);
$finish;
