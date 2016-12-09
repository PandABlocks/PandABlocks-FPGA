$display("Running DRIVER TEST...");

PGEN_REPEAT  = 2;
PGEN_SAMPLES = 5;

tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h1);
tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h0);

repeat(125) @(posedge tb.uut.ps.FCLK);

// Setup a timer for capture input test
REG_WRITE(COUNTER_BASE, COUNTER_ENABLE, BITS_ONE0);
REG_WRITE(COUNTER_BASE, COUNTER_TRIG, FMC_INP20);
REG_WRITE(COUNTER_BASE, COUNTER_START, 1000);
REG_WRITE(COUNTER_BASE, COUNTER_STEP, 1);

// Setup Position Capture
REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT0);

REG_WRITE(PCAP_BASE, PCAP_ENABLE, BITS_ONE0);
REG_WRITE(PCAP_BASE, PCAP_FRAME, FMC_INP10);
REG_WRITE(PCAP_BASE, PCAP_CAPTURE, FMC_INP20);

REG_WRITE(REG_BASE, REG_PCAP_FRAMING_ENABLE, 0);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MASK, 0);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MODE, 0);

REG_WRITE(DRV_BASE, DRV_PCAP_BLOCK_SIZE, tb.BLOCK_SIZE);
REG_WRITE(DRV_BASE, DRV_PCAP_TIMEOUT, 0);

repeat(125) @(posedge tb.uut.ps.FCLK);
REG_WRITE(INENC_BASE, INENC_PROTOCOL, 2);
REG_READ(INENC_BASE, INENC_STATUS, STATUS);

ARMS = 1;
FRAME_COUNT = 10;

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
    enable = 1;

    for (m = 0; m < ARMS; m = m + 1) begin
        @(posedge pcap_armed);
        repeat(125) @(posedge tb.uut.FCLK_CLK0);
        for (j = 0; j < FRAME_COUNT; j = j + 1) begin
            frame = 1; @(posedge tb.uut.FCLK_CLK0);frame = 0;
            repeat(100) @(posedge tb.uut.FCLK_CLK0);
            if (j < FRAME_COUNT - 1) begin
                capture = 1; @(posedge tb.uut.FCLK_CLK0);capture = 0;
                repeat(25) @(posedge tb.uut.FCLK_CLK0);
            end
        end
    end

    repeat(1250) @(posedge tb.uut.FCLK_CLK0);
    REG_WRITE(REG_BASE, REG_PCAP_DISARM, 1);           // PCAP Arm
    repeat(1250) @(posedge tb.uut.FCLK_CLK0);
end

`include "./irq_handler.v"

join

repeat(1250) @(posedge tb.uut.ps.FCLK);
$finish;
