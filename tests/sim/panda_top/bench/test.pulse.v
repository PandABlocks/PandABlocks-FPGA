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
repeat(2500) @(posedge tb.uut.ps.FCLK);
REG_WRITE(CLOCKS_BASE, CLOCKS_A_PERIOD, 12500);
REG_WRITE(TTLOUT_BASE, TTLOUT_VAL, CLOCKS_OUTA0);
REG_WRITE(TTLOUT_BASE + 32'h100, TTLOUT_VAL, PULSE_OUT0);
REG_WRITE(TTLOUT_BASE + 32'h200, TTLOUT_VAL, PULSE_OUT3);

REG_WRITE(PULSE_BASE, PULSE_INP, TTLIN_VAL0);
REG_WRITE(PULSE_BASE, PULSE_DELAY_L, 1250);
REG_WRITE(PULSE_BASE, PULSE_WIDTH_L, 1250);
REG_WRITE(PULSE_BASE, PULSE_ENABLE, 1);

REG_WRITE(PULSE_BASE + 32'h300, PULSE_INP, TTLIN_VAL0);
REG_WRITE(PULSE_BASE + 32'h300, PULSE_DELAY_L, 1250);
REG_WRITE(PULSE_BASE + 32'h300, PULSE_WIDTH_L, 2500);
REG_WRITE(PULSE_BASE + 32'h300, PULSE_ENABLE, 1);

repeat(500 * 125) @(posedge tb.uut.ps.FCLK);

$finish;
