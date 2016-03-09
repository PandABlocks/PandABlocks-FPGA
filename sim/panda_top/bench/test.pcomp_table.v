$display("Running PCAP TEST...");

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

repeat(500) @(posedge tb.uut.FCLK_CLK0);
REG_WRITE(INENC_BASE, INENC_PROTOCOL, 0);
REG_WRITE(OUTENC_BASE, OUTENC_PROTOCOL, 0);

// Setup Position Compare Block #0
REG_WRITE(PCOMP_BASE, PCOMP_ENABLE, 106);           // pcap_act
REG_WRITE(PCOMP_BASE, PCOMP_INP, 1);               // inenc_posn(0)
REG_WRITE(PCOMP_BASE, PCOMP_DELTAP, 0);
REG_WRITE(PCOMP_BASE, PCOMP_START, 0);
REG_WRITE(PCOMP_BASE, PCOMP_STEP, 0);
REG_WRITE(PCOMP_BASE, PCOMP_WIDTH, 0);
REG_WRITE(PCOMP_BASE, PCOMP_DIR, 0);
REG_WRITE(PCOMP_BASE, PCOMP_PNUM, 5);
REG_WRITE(PCOMP_BASE, PCOMP_USE_TABLE, 1);
REG_WRITE(PCOMP_BASE, PCOMP_TABLE_ADDRESS, 32'h0002_0000);
REG_WRITE(PCOMP_BASE, PCOMP_TABLE_LENGTH, 1024);

// Setup Position Capture
REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, 1);             // enc #1

REG_WRITE(PCAP_BASE, PCAP_ENABLE, 98);              // pcomp_act(0)
REG_WRITE(PCAP_BASE, PCAP_CAPTURE, 102);            // pcomp_pulse(0)

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
    for (k = 0; k < ARMS; k = k + 1) begin
        @(posedge pcap_armed);
        repeat(125) @(posedge tb.uut.FCLK_CLK0);
        for (i=0; i<10; i=i+1) begin
            tb.encoder.Turn(1500);
            tb.encoder.Turn(-1500);
        end
    end
end

begin
    `include "./irq_handler.v"
end

join
