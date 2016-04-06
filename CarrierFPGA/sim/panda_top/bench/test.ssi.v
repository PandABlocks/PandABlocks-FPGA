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

repeat(2500) @(posedge tb.uut.ps.FCLK);
REG_WRITE(OUTENC_BASE, OUTENC_CONN, BITS_ONE0);     // Slow
repeat(15000) @(posedge tb.uut.ps.FCLK);
REG_WRITE(OUTENC_BASE, OUTENC_PROTOCOL, 1);         // Slow
repeat(15000) @(posedge tb.uut.ps.FCLK);
REG_WRITE(OUTENC_BASE, OUTENC_BITS, 24);
REG_WRITE(OUTENC_BASE, OUTENC_VAL, 1);

REG_WRITE(INENC_BASE, INENC_PROTOCOL, 1);           // Slow
repeat(15000) @(posedge tb.uut.ps.FCLK);
REG_WRITE(INENC_BASE, INENC_CLK_PERIOD, 125);
REG_WRITE(INENC_BASE, INENC_FRAME_PERIOD,12500);
REG_WRITE(INENC_BASE, INENC_BITS, 24);

repeat(50000) @(posedge tb.uut.ps.FCLK);

$finish;
