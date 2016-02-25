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

repeat(500) @(posedge tb.uut.ps.FCLK);

// Setup a timer for capture input test
REG_WRITE(COUNTER_BASE, COUNTER_ENABLE, 62);    // SEQ_ACTIVE
REG_WRITE(COUNTER_BASE, COUNTER_TRIGGER, 38);   // SEQ_OUTA
REG_WRITE(COUNTER_BASE, COUNTER_START, 0);
REG_WRITE(COUNTER_BASE, COUNTER_STEP, 1);

// Setup a sequencer to output 10 pulses with 200usec period.
REG_WRITE(SEQ_BASE, SEQ_PRESCALE, 125);         // 1usec
REG_WRITE(SEQ_BASE, SEQ_TABLE_CYCLE, 1);        // Don't repeat

REG_WRITE(SEQ_BASE, SEQ_TABLE_START, 0);
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 16);      // Repeats
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 32'h1F003F00);
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 1);         // 1us on
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 1);         // 1us off
REG_WRITE(SEQ_BASE, SEQ_TABLE_LENGTH, 1 * 4);   // # of DWORDs

REG_WRITE(SEQ_BASE, SEQ_GATE, 106);             // PCAP_ACTIVE
REG_WRITE(SEQ_BASE, SEQ_INPA, 1);               // BITS_ONE

// Setup Position Capture
REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, 12);        // counter #1

REG_WRITE(PCAP_BASE, PCAP_ENABLE,  62);         // SEQ_ACTIVE
REG_WRITE(PCAP_BASE, PCAP_FRAME,   0);          // BITS_ZER0
REG_WRITE(PCAP_BASE, PCAP_CAPTURE, 38);         // SEQ_OUTA

REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MASK, 0);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_ENABLE, 0);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MODE, 0);

REG_WRITE(DRV_BASE, DRV_PCAP_BLOCK_SIZE, tb.BLOCK_SIZE);
REG_WRITE(DRV_BASE, DRV_PCAP_TIMEOUT, 0);
REG_WRITE(DRV_BASE, DRV_PCAP_DMA_RESET, 1);     // DMA reset
REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   // Init
REG_WRITE(DRV_BASE, DRV_PCAP_DMA_START, 1);     // ...
addr = addr + tb.BLOCK_SIZE;                    //
REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   //

repeat(1250) @(posedge tb.uut.ps.FCLK);

ARMS = 1;

fork

// Generate consecutive ARM signals.
begin
    for (k = 0; k < ARMS; k = k + 1) begin
        REG_WRITE(REG_BASE, REG_PCAP_ARM, 1);
        wait (pcap_completed == 1);
        pcap_completed = 0;
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
