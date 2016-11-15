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
REG_WRITE(COUNTER_BASE, COUNTER_TRIG, SEQ_OUTA0);
REG_WRITE(COUNTER_BASE, COUNTER_START, 1000);
REG_WRITE(COUNTER_BASE, COUNTER_STEP, 1);

REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_ENABLE, PCAP_ACTIVE0);
REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_TRIG, SEQ_OUTA0);
REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_START, 1000);
REG_WRITE(COUNTER_BASE + 32'h100, COUNTER_STEP, 1);

// Setup a sequencer to output 10 pulses with 200usec period.
REG_WRITE(SEQ_BASE, SEQ_PRESCALE, 1);       // 8nsec
REG_WRITE(SEQ_BASE, SEQ_TABLE_CYCLE, 1);        // Don't repeat
REG_WRITE(SEQ_BASE, SEQ_TABLE_START, 0);
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 4000000);      // Repeats
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 32'h1F003F00);
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 50);        // 1us on
REG_WRITE(SEQ_BASE, SEQ_TABLE_DATA, 50);        // 1us off
REG_WRITE(SEQ_BASE, SEQ_TABLE_LENGTH, 1 * 4);  // # of DWORDs
REG_WRITE(SEQ_BASE, SEQ_ENABLE, PCAP_ACTIVE0);
REG_WRITE(SEQ_BASE, SEQ_INPA, BITS_ONE0);

// Setup Position Capture
REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT0);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT2);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT3);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT4);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT5);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, COUNTER_OUT6);

REG_WRITE(PCAP_BASE, PCAP_ENABLE,  SEQ_ACTIVE0);
REG_WRITE(PCAP_BASE, PCAP_FRAME,   SEQ_OUTA0);
REG_WRITE(PCAP_BASE, PCAP_CAPTURE, SEQ_OUTA0);

REG_WRITE(REG_BASE, REG_PCAP_FRAMING_ENABLE, 0);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MASK, 0);
REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MODE, 0);

REG_WRITE(DRV_BASE, DRV_PCAP_BLOCK_SIZE, tb.BLOCK_SIZE);
REG_WRITE(DRV_BASE, DRV_PCAP_TIMEOUT, 100*20);

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
