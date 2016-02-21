$display("Running PCAP TEST...");

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
REG_WRITE(INENC_BASE, INENC_PROTOCOL, 0);
REG_WRITE(OUTENC_BASE, OUTENC_PROTOCOL, 0);

// Setup a timer for capture input test
REG_WRITE(COUNTER_BASE, COUNTER_ENABLE, 106);       // pcap_act
REG_WRITE(COUNTER_BASE, COUNTER_TRIGGER, 102);      // pcomp_pulse
REG_WRITE(COUNTER_BASE, COUNTER_START, 1000);
REG_WRITE(COUNTER_BASE, COUNTER_STEP, 500);

// Setup Position Compare Block #0
REG_WRITE(PCOMP_BASE, PCOMP_ENABLE, 106);           // pcap_act
REG_WRITE(PCOMP_BASE, PCOMP_POSN, 1);               // inenc_posn(0)
REG_WRITE(PCOMP_BASE, PCOMP_DELTAP, 25);
REG_WRITE(PCOMP_BASE, PCOMP_START, 75);
REG_WRITE(PCOMP_BASE, PCOMP_STEP, 0);
REG_WRITE(PCOMP_BASE, PCOMP_WIDTH, 1400);
REG_WRITE(PCOMP_BASE, PCOMP_DIR, 0);
REG_WRITE(PCOMP_BASE, PCOMP_PNUM, 5);

// Setup Position Compare Block #1
REG_WRITE(PCOMP_BASE + 32'h100, PCOMP_ENABLE, 102); // pcomp_pulse(0)
REG_WRITE(PCOMP_BASE + 32'h100, PCOMP_POSN, 1);     // inenc_posn(0)
REG_WRITE(PCOMP_BASE + 32'h100, PCOMP_DELTAP, 10);
REG_WRITE(PCOMP_BASE + 32'h100, PCOMP_START, 100);
REG_WRITE(PCOMP_BASE + 32'h100, PCOMP_STEP, 100);
REG_WRITE(PCOMP_BASE + 32'h100, PCOMP_WIDTH, 10);
REG_WRITE(PCOMP_BASE + 32'h100, PCOMP_DIR, 0);
REG_WRITE(PCOMP_BASE + 32'h100, PCOMP_PNUM, 0);


// Setup Position Capture
REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, 1);             // enc #1
//REG_WRITE(REG_BASE, REG_PCAP_WRITE, 11);          // counter #1

REG_WRITE(PCAP_BASE, PCAP_ENABLE, 98);              // pcomp_act(0)
REG_WRITE(PCAP_BASE, PCAP_CAPTURE, 103);            // pcomp_pulse(1)

REG_WRITE(DRV_BASE, DRV_PCAP_BLOCK_SIZE, tb.BLOCK_SIZE);
REG_WRITE(DRV_BASE, DRV_PCAP_TIMEOUT, 0);
REG_WRITE(DRV_BASE, DRV_PCAP_DMA_RESET, 1);     // DMA reset
REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   // Init
REG_WRITE(DRV_BASE, DRV_PCAP_DMA_START, 1);     // ...
addr = addr + tb.BLOCK_SIZE;                    //
REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   //

REG_WRITE(REG_BASE, REG_PCAP_ARM, 1);
repeat(1250) @(posedge tb.uut.ps.FCLK);

fork
begin
    for (i=0; i<10; i=i+1) begin
        tb.encoder.Turn(1500);
        tb.encoder.Turn(-1500);
    end
end

begin
    `include "./irq_handler.v"
end

// Wait to finish
begin
    wait (pcap_completed == 1);
    pcap_completed = 0;
    // Gap until next arming.
    repeat(1250) @(posedge tb.uut.FCLK_CLK0);
    $finish;
end



join

repeat(1250) @(posedge tb.uut.FCLK_CLK0);
$finish;
