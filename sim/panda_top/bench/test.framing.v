$display("Running FRAMING TEST...");

base = 32'h43C1_1000;
addr = 32'h1000_0000;
read_addr = 32'h1000_0000;
irq_count = 0;
total_samples = 0;
pcap_completed = 0;
arm = 0;
enable = 0;
capture = 0;

repeat(500) @(posedge tb.uut.FCLK_CLK0);

// Setup a timer for capture input test
REG_WRITE(COUNTER_BASE, COUNTER_ENABLE, 2);       // TTL #0
REG_WRITE(COUNTER_BASE, COUNTER_TRIGGER, 4);      // TTL #2
REG_WRITE(COUNTER_BASE, COUNTER_START, 10);
REG_WRITE(COUNTER_BASE, COUNTER_STEP, 5);

REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_ENABLE, 2);       // TTL #0
REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_TRIGGER, 4);      // TTL #2
REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_START, 100);
REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_STEP, 50);

REG_WRITE(COUNTER_BASE + 32'h200, COUNTER_ENABLE, 2);       // TTL #0
REG_WRITE(COUNTER_BASE + 32'h200, COUNTER_TRIGGER, 4);      // TTL #2
REG_WRITE(COUNTER_BASE + 32'h200, COUNTER_START, 1000);
REG_WRITE(COUNTER_BASE + 32'h200, COUNTER_STEP, 500);

REG_WRITE(COUNTER_BASE + 32'h300, COUNTER_ENABLE, 2);       // TTL #0
REG_WRITE(COUNTER_BASE + 32'h300, COUNTER_TRIGGER, 4);      // TTL #2
REG_WRITE(COUNTER_BASE + 32'h300, COUNTER_START, 10000);
REG_WRITE(COUNTER_BASE + 32'h300, COUNTER_STEP, 5000);

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

NUMSAMPLE = 5000;
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
        // Gap until next arming.
        repeat(12500) @(posedge tb.uut.FCLK_CLK0);
    end

    $finish;
end

// Enable follows an arm_rise
begin
    while (1) begin
        wait (arm_rise == 1);
        repeat(1250) @(posedge tb.uut.FCLK_CLK0);
        enable = 1;
        wait (n == NUMSAMPLE - 1);
        repeat(250) @(posedge tb.uut.FCLK_CLK0);
        enable = 0;
    end
end

// Capture @ 1MHz starts firing following enable_rise
begin
    while (1) begin
        wait (enable_rise == 1);
        @(posedge tb.uut.FCLK_CLK0);
        for (n = 0; n < NUMSAMPLE; n = n + 1) begin
            capture = 1;
            repeat(1) @(posedge tb.uut.FCLK_CLK0);
            capture = 0;
            repeat(124) @(posedge tb.uut.FCLK_CLK0);
        end
    end
end

// Frame
//begin
//    for (i = 0; i < 10; i = i+1) begin
//        ttlin_pad[1] = 1;
//        repeat(500) @(posedge tb.FCLK_CLK0);
//        ttlin_pad[1] = 0;
//        repeat(1500) @(posedge tb.FCLK_CLK0);
//    end
//end

begin
    `include "../../panda_top/bench/irq_handler.v"
end

join

repeat(1250) @(posedge tb.uut.FCLK_CLK0);
$finish;

