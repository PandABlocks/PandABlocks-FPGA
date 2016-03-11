$display("Running DRIVER TEST...");

base = 32'h43C1_1000;
addr = 32'h1000_0000;
read_addr = 32'h1000_0000;
irq_count = 0;
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

// Setup a timer for capture input test
REG_WRITE(COUNTER_BASE, COUNTER_ENABLE, PCAP_ACTIVE0);
REG_WRITE(COUNTER_BASE, COUNTER_TRIG, PULSE_OUT0);
REG_WRITE(COUNTER_BASE, COUNTER_START, 1000);
REG_WRITE(COUNTER_BASE, COUNTER_STEP, 1000);

REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_ENABLE, PCAP_ACTIVE0);
REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_TRIG, PULSE_OUT0);
REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_START, 1000);
REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_STEP, 1000);

// Setup a sequencer to output 10 pulses with 200usec period.
REG_WRITE(SEQ_BASE, SEQ_PRESCALE, 125);         // 1usec
REG_WRITE(SEQ_BASE, SEQ_TABLE_CYCLE, 1);        // Don't repeat
REG_WRITE(SEQ_BASE, SEQ_TABLE_START, 0);
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 10);        // Repeats
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 32'h1F3F0000);
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 1);         // 1us on
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 1);         // 1us off
REG_WRITE(SEQ_BASE, SEQ_TABLE_LENGTH, 1 * 4);   // # of DWORDs
REG_WRITE(SEQ_BASE, SEQ_ENABLE, PCAP_ACTIVE0);
REG_WRITE(SEQ_BASE, SEQ_INPA, BITS_ONE0);

// Setup a sequencer to output 10 pulses with 200usec period.
REG_WRITE(SEQ_BASE + 32'h100, SEQ_PRESCALE, 250);         // 2usec
REG_WRITE(SEQ_BASE + 32'h100, SEQ_TABLE_CYCLE, 1);        // Don't repeat
REG_WRITE(SEQ_BASE + 32'h100, SEQ_TABLE_START, 0);
REG_WRITE(SEQ_BASE + 32'h100, SEQ_TABLE_DATA, 10);        // Repeats
REG_WRITE(SEQ_BASE + 32'h100, SEQ_TABLE_DATA, 32'h1F3F0000);
REG_WRITE(SEQ_BASE + 32'h100, SEQ_TABLE_DATA, 1);         // 1us on
REG_WRITE(SEQ_BASE + 32'h100, SEQ_TABLE_DATA, 1);         // 1us off
REG_WRITE(SEQ_BASE + 32'h100, SEQ_TABLE_LENGTH, 1 * 4);   // # of DWORDs
REG_WRITE(SEQ_BASE + 32'h100, SEQ_ENABLE, PCAP_ACTIVE0);
REG_WRITE(SEQ_BASE + 32'h100, SEQ_INPA, BITS_ONE0);

// Setup a Pulse block to delay SEQ_OUTA0
REG_WRITE(PULSE_BASE, PULSE_DELAY_L, 100);
REG_WRITE(PULSE_BASE, PULSE_DELAY_H, 0);
REG_WRITE(PULSE_BASE, PULSE_WIDTH_L, 125);
REG_WRITE(PULSE_BASE, PULSE_WIDTH_H, 0);
REG_WRITE(PULSE_BASE, PULSE_INP, SEQ_OUTA0);
REG_WRITE(PULSE_BASE, PULSE_ENABLE, BITS_ONE0);

// Setup Position Capture
REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, 37);

REG_WRITE(PCAP_BASE, PCAP_ENABLE,  SEQ_ACTIVE0);
REG_WRITE(PCAP_BASE, PCAP_FRAME,   SEQ_OUTA0);
REG_WRITE(PCAP_BASE, PCAP_CAPTURE, SEQ_OUTA1);

framing_mask = framing_mask | (1 << COUNTER_OUT0);

REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MASK, framing_mask);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MODE, 0);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_ENABLE, 1);

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
end
    `include "./irq_handler.v"
join

repeat(1250) @(posedge tb.uut.ps.FCLK);
$finish;
