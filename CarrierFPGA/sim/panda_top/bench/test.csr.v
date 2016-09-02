$display("Running Position Based Snake Scan Test...");

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

// Position Compare Block #0
REG_WRITE(PCOMP_BASE, PCOMP_ENABLE, PCAP_ACTIVE0);

repeat(125) @(posedge tb.uut.ps.FCLK);

$finish;


