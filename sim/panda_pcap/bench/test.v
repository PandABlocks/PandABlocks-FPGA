module test;

`include "./addr_defines.v"

panda_pcap_tb tb();

reg [1:0]       wrs, rsp;
reg [3:0]       IRQ_STATUS;
reg [31:0]      SMPL_COUNT;
reg [31:0]      dma_addr;
reg [31:0]      addr;
reg [31:0]      base;
reg [31:0]      total_samples;

reg [31:0]    addr_table[1023: 0];
reg [31:0]    smpl_table[1023: 0];
integer         irq_count;

reg [31:0]      read_data;
reg [31:0]      readback;


integer         fid;
integer         r;
integer         len;

integer         data;

reg [31:0]      read_addr;
reg             active;

integer i, n;
// Wrapper for Zynx AXI4 transactions.
task REG_WRITE;
    input [31: 0] base;
    input [31: 0] addr;
    input [31: 0] val;
begin
    tb.zynq.ps.inst.write_data(base + 4*addr,  4, val, wrs);
end
endtask

task REG_READ;
    input  [31: 0] base;
    input  [31: 0] addr;
    output [31: 0] val;
begin
    tb.zynq.ps.inst.read_data(base + 4*addr,  4, val, wrs);
end
endtask

`include "./apis_tb.v"

initial begin
    repeat(2) @(posedge tb.FCLK_CLK0);

    /* Disable the function and channel level infos from BFM */
    tb.zynq.hp1.cdn_axi3_master_bfm_inst.RESPONSE_TIMEOUT = 0;
    tb.zynq.hp1.cdn_axi3_master_bfm_inst.set_channel_level_info(0);
    tb.zynq.hp1.cdn_axi3_master_bfm_inst.set_function_level_info(0);

    tb.zynq.ps.inst.set_function_level_info("ALL",0);
    tb.zynq.ps.inst.set_channel_level_info("ALL",0);
end

initial begin
    addr = 32'h1000_0000;
    read_addr = 32'h1000_0000;

    // AXI BFM
    wait(tb.tb_ARESETn === 0) @(posedge tb.FCLK_CLK0);
    wait(tb.tb_ARESETn === 1) @(posedge tb.FCLK_CLK0);

    $display("Reset Done. Setting the Slave profiles \n");

    tb.zynq.ps.inst.set_slave_profile("S_AXI_HP0",2'b11);
    tb.zynq.ps.inst.set_slave_profile("S_AXI_HP1",2'b11);
    $display("Profile Done\n");

    repeat(1250) @(posedge tb.FCLK_CLK0);

    $display("Running FRAMING TEST...");

    base = 32'h43C1_1000;
    addr = 32'h1000_0000;
    read_addr = 32'h1000_0000;
    irq_count = 0;
    total_samples = 0;

    // Setup Position Capture
    REG_WRITE(REG_BASE, REG_PCAP_START_WRITE, 1);
    REG_WRITE(REG_BASE, REG_PCAP_WRITE, 12);    // counter #1
    REG_WRITE(REG_BASE, REG_PCAP_WRITE, 13);    // counter #2

    REG_WRITE(PCAP_BASE, PCAP_ENABLE,  0);      // TTL #0
    REG_WRITE(PCAP_BASE, PCAP_FRAME,   1);      // TTL #1
    REG_WRITE(PCAP_BASE, PCAP_CAPTURE, 2);      // TTL #2

    REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MASK, 32'h180);
    REG_WRITE(REG_BASE, REG_PCAP_FRAMING_ENABLE, 0);
    REG_WRITE(REG_BASE, REG_PCAP_FRAMING_MODE, 0);

    REG_WRITE(DRV_BASE, DRV_PCAP_BLOCK_SIZE, tb.BLOCK_SIZE);
    REG_WRITE(DRV_BASE, DRV_PCAP_TIMEOUT, 0);
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_RESET, 1);     // DMA reset
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   // Init
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_START, 1);     // ...
    addr = addr + tb.BLOCK_SIZE;                    //
    REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);   //

    REG_WRITE(REG_BASE, REG_PCAP_ARM, 1);

fork begin
    while (1) begin
        // Wait for DMA irq
        tb.zynq.ps.inst.wait_interrupt(0,IRQ_STATUS);
        // Read IRQ Status and Sample Count Registers
        REG_READ(DRV_BASE, DRV_PCAP_IRQ_STATUS, IRQ_STATUS);
        REG_READ(DRV_BASE, DRV_PCAP_SMPL_COUNT, SMPL_COUNT);

        // Keep track of address and sample count.
        smpl_table[irq_count] = SMPL_COUNT;
        addr_table[irq_count] = read_addr;
        irq_count = irq_count + 1;

        // Set next DMA address
        read_addr = addr;
        addr = addr + tb.BLOCK_SIZE;

        if (IRQ_STATUS == 4'b0001) begin
            $display("IRQ on BLOCK_FINISHED with %d samples.", SMPL_COUNT);
            // DRV_PCAP_DMA_ADDR
            REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);
        end
        else if (IRQ_STATUS == 4'b0010) begin
            $display("IRQ on CAPT_FINISHED with %d samples.", SMPL_COUNT);

            // Read scattered data from host memory into a file.
            for (i=0; i<irq_count; i=i+1) begin
                $display("Reading %d Samples from Address=%08x", smpl_table[i], addr_table[i]);
                tb_read_to_file("master_hp1","read_from_hp1.txt",addr_table[i],4*smpl_table[i],rsp);
                total_samples = total_samples + smpl_table[i];
            end

            $display("Total Samples = %d", total_samples);
            $finish;
        end
        else if (IRQ_STATUS == 4'b0011) begin
            $display("IRQ on TIMEOUT with %d samples.", SMPL_COUNT);
            REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);
        end
        else if (IRQ_STATUS == 4'b0100) begin
            $display("IRQ on DISARM with %d samples.", SMPL_COUNT);
            // Read scattered data from host memory into a file.
            for (i=0; i<irq_count; i=i+1) begin
                $display("Reading %d Samples from Address=%08x", smpl_table[i], addr_table[i]);
                tb_read_to_file("master_hp1","read_from_hp1.txt",addr_table[i],4*smpl_table[i],rsp);
                total_samples = total_samples + smpl_table[i];
            end
            $display("Total Samples = %d", total_samples);
            $finish;
        end
        else if (IRQ_STATUS == 4'b0110) begin
            $display("IRQ on INT_DISARM with %d samples.", SMPL_COUNT);
            // Read scattered data from host memory into a file.
            for (i=0; i<irq_count; i=i+1) begin
                $display("Reading %d Samples from Address=%08x", smpl_table[i], addr_table[i]);
                tb_read_to_file("master_hp1","read_from_hp1.txt",addr_table[i],4*smpl_table[i],rsp);
                total_samples = total_samples + smpl_table[i];
            end
            $display("Total Samples = %d", total_samples);
            $finish;
        end
        else if (IRQ_STATUS == 4'b0101) begin
            $display("IRQ on ADDR_ERROR...");
            $finish;
        end
    end
end

join

    repeat(1250) @(posedge tb.FCLK_CLK0);
    $finish;
end

endmodule
