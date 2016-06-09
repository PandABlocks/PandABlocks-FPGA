$display("Position based snake scan testing...");

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
REG_WRITE(INENC_BASE, INENC_PROTOCOL, 0);
REG_WRITE(OUTENC_BASE, OUTENC_PROTOCOL, 0);

// Position Compare Block #0
REG_WRITE(PCOMP_BASE, PCOMP_ENABLE, PCAP_ACTIVE0);
REG_WRITE(PCOMP_BASE, PCOMP_INP, INENC_VAL0);
REG_WRITE(PCOMP_BASE, PCOMP_DELTAP, 100);
REG_WRITE(PCOMP_BASE, PCOMP_START, 1000);
REG_WRITE(PCOMP_BASE, PCOMP_STEP, 0);
REG_WRITE(PCOMP_BASE, PCOMP_WIDTH, 9000);
REG_WRITE(PCOMP_BASE, PCOMP_DIR, 0);
REG_WRITE(PCOMP_BASE, PCOMP_PNUM, 1);

REG_WRITE(PCOMP_BASE+32'h100, PCOMP_ENABLE, PCAP_ACTIVE0);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_INP, INENC_VAL0);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_DELTAP, 100);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_START, 10000);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_STEP, 0);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_WIDTH, 9000);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_DIR, 1);
REG_WRITE(PCOMP_BASE+32'h100, PCOMP_PNUM, 1);

REG_WRITE(PCOMP_BASE+32'h200, PCOMP_ENABLE, PCOMP_OUT0);
REG_WRITE(PCOMP_BASE+32'h200, PCOMP_INP, INENC_VAL0);
REG_WRITE(PCOMP_BASE+32'h200, PCOMP_DELTAP, 0);
REG_WRITE(PCOMP_BASE+32'h200, PCOMP_START, 0);
REG_WRITE(PCOMP_BASE+32'h200, PCOMP_STEP, 100);
REG_WRITE(PCOMP_BASE+32'h200, PCOMP_WIDTH, 10);
REG_WRITE(PCOMP_BASE+32'h200, PCOMP_DIR, 0);
REG_WRITE(PCOMP_BASE+32'h200, PCOMP_PNUM, 0);
REG_WRITE(PCOMP_BASE+32'h200, PCOMP_RELATIVE, 1);

REG_WRITE(PCOMP_BASE+32'h300, PCOMP_ENABLE, PCOMP_OUT1);
REG_WRITE(PCOMP_BASE+32'h300, PCOMP_INP, INENC_VAL0);
REG_WRITE(PCOMP_BASE+32'h300, PCOMP_DELTAP, 0);
REG_WRITE(PCOMP_BASE+32'h300, PCOMP_START, 0);
REG_WRITE(PCOMP_BASE+32'h300, PCOMP_STEP, 100);
REG_WRITE(PCOMP_BASE+32'h300, PCOMP_WIDTH, 10);
REG_WRITE(PCOMP_BASE+32'h300, PCOMP_DIR, 1);
REG_WRITE(PCOMP_BASE+32'h300, PCOMP_PNUM, 0);
REG_WRITE(PCOMP_BASE+32'h300, PCOMP_RELATIVE, 1);

REG_WRITE(LUT_BASE, LUT_INPA, PCOMP_ACTIVE0);
REG_WRITE(LUT_BASE, LUT_INPB, PCOMP_ACTIVE1);
REG_WRITE(LUT_BASE, LUT_FUNC, 32'd4294967040); // A|B

REG_WRITE(LUT_BASE+32'h100, LUT_INPA, PCOMP_OUT2);
REG_WRITE(LUT_BASE+32'h100, LUT_FUNC, 65535); // ~A

REG_WRITE(PULSE_BASE, PULSE_INP, LUT_OUT1);
REG_WRITE(PULSE_BASE, PULSE_DELAY_L, 0);
REG_WRITE(PULSE_BASE, PULSE_WIDTH_L, 10);
REG_WRITE(PULSE_BASE, PULSE_ENABLE, 1);

REG_WRITE(LUT_BASE+32'h200, LUT_INPA, PCOMP_OUT3);
REG_WRITE(LUT_BASE+32'h200, LUT_FUNC, 65535); // ~A

REG_WRITE(PULSE_BASE + 32'h100, PULSE_INP, LUT_OUT2);
REG_WRITE(PULSE_BASE + 32'h100, PULSE_DELAY_L, 0);
REG_WRITE(PULSE_BASE + 32'h100, PULSE_WIDTH_L, 10);
REG_WRITE(PULSE_BASE + 32'h100, PULSE_ENABLE, 1);

REG_WRITE(LUT_BASE+32'h300, LUT_INPA, PCOMP_OUT2);
REG_WRITE(LUT_BASE+32'h300, LUT_INPB, PCOMP_OUT3);
REG_WRITE(LUT_BASE+32'h300, LUT_INPC, PULSE_OUT0);
REG_WRITE(LUT_BASE+32'h300, LUT_INPD, PULSE_OUT1);
REG_WRITE(LUT_BASE+32'h300, LUT_FUNC, 32'd4294967040); //A|B
//REG_WRITE(LUT_BASE+32'h300, LUT_FUNC, 4294967292); //A|B|C|D

// Capture Block
REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
REG_WRITE(REG_BASE, REG_PCAP_WRITE, INENC_VAL0);

REG_WRITE(PCAP_BASE, PCAP_ENABLE, LUT_OUT0);
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
    for (k = 0; k < ARMS; k = k + 1) begin
        @(posedge pcap_armed);
        repeat(125) @(posedge tb.uut.FCLK_CLK0);
        for (i=0; i<10; i=i+1) begin
            tb.encoder.Turn(11000);
            tb.encoder.Turn(-11000);
            tb.encoder.Turn(11000);
            tb.encoder.Turn(-11000);
            tb.encoder.Turn(11000);
            tb.encoder.Turn(-11000);
        end
    end
end

begin
    `include "./irq_handler.v"
end

join
