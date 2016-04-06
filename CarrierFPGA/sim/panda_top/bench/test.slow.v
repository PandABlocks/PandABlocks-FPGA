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

repeat(1250) @(posedge tb.uut.ps.FCLK);
REG_WRITE(INENC_BASE, INENC_PROTOCOL, 0);
repeat(25000) @(posedge tb.uut.ps.FCLK);
REG_WRITE(INENC_BASE + 32'h100, INENC_PROTOCOL, 1);
repeat(25000) @(posedge tb.uut.ps.FCLK);
REG_WRITE(INENC_BASE + 32'h200, INENC_PROTOCOL, 2);
repeat(25000) @(posedge tb.uut.ps.FCLK);
REG_WRITE(INENC_BASE + 32'h300, INENC_PROTOCOL, 3);
repeat(25000) @(posedge tb.uut.ps.FCLK);

repeat(1250) @(posedge tb.uut.ps.FCLK);
REG_WRITE(OUTENC_BASE, OUTENC_PROTOCOL, 0);
repeat(25000) @(posedge tb.uut.ps.FCLK);
REG_WRITE(OUTENC_BASE + 32'h100, OUTENC_PROTOCOL, 1);
repeat(25000) @(posedge tb.uut.ps.FCLK);
REG_WRITE(OUTENC_BASE + 32'h200, OUTENC_PROTOCOL, 2);
repeat(25000) @(posedge tb.uut.ps.FCLK);
REG_WRITE(OUTENC_BASE + 32'h300, OUTENC_PROTOCOL, 3);
repeat(25000) @(posedge tb.uut.ps.FCLK);

$finish;
