module test;

panda_pcap_tb tb();

reg [1:0]   wrs, rsp;
reg [3:0]   irq_status;
reg [31:0]  addr, read_addr;
reg         active;

integer i;

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

//parameter integer BLOCK_SIZE = tb.BLOCK_SIZE;
//parameter integer DMA_SIZE   = tb.DMA_SIZE;

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

    // Setup Position Capture
    // PCAP_ENABLE_VAL_ADDR
    tb.zynq.ps.inst.write_data(32'h43C0_0000, 4, 0, wrs);
    // PCAP_TRIGGER_VAL_ADDR
    tb.zynq.ps.inst.write_data(32'h43C0_0004, 4, 1, wrs);
    // PCAP_TIMEOUT_ADDR
    tb.zynq.ps.inst.write_data(32'h43C0_001C, 4, 1000, wrs);

    // PCAP_DMAADDR_ADDR
    tb.zynq.ps.inst.write_data(32'h43C0_0008, 4, addr, wrs);

    // PCAP_SOFT_ARM_ADDR
    tb.zynq.ps.inst.write_data(32'h43C0_0010, 4, 1, wrs);

    // PCAP_DMAADDR_ADDR
    addr = addr + tb.BLOCK_SIZE;
    tb.zynq.ps.inst.write_data(32'h43C0_0008, 4, addr, wrs);

fork
    begin
        while (tb.uut.pcap_enabled) begin
            // Wait for DMA irq
            tb.zynq.ps.inst.wait_interrupt(0,irq_status);
            if (tb.uut.irq_status == 4'b0001) begin
                $display("IRQ on BLOCK_FINISHED with %d samples.", tb.uut.SMPL_COUNT);
                tb_read_to_file("master_hp1","read_from_hp1.txt",read_addr,tb.uut.SMPL_COUNT,rsp);
                read_addr = addr;
                addr = addr + tb.BLOCK_SIZE;
                // PCAP_DMAADDR_ADDR
                tb.zynq.ps.inst.write_data(32'h43C0_0008, 4, addr, wrs);
            end
            else if (tb.uut.irq_status == 4'b0010) begin
                $display("IRQ on CAPT_FINISHED with %d samples.", tb.uut.SMPL_COUNT);
                tb_read_to_file("master_hp1","read_from_hp1.txt",read_addr,tb.uut.SMPL_COUNT,rsp);
            end
            else if (tb.uut.irq_status == 4'b0011) begin
                $display("IRQ on TIMEOUT with %d samples.", tb.uut.SMPL_COUNT);
                tb_read_to_file("master_hp1","read_from_hp1.txt",read_addr,tb.uut.SMPL_COUNT,rsp);
                read_addr = addr;
                addr = addr + tb.BLOCK_SIZE;
                // PCAP_DMAADDR_ADDR
                tb.zynq.ps.inst.write_data(32'h43C0_0008, 4, addr, wrs);
            end
            else if (tb.uut.irq_status == 4'b0100) begin
                $display("IRQ on DISARM with %d samples.", tb.uut.SMPL_COUNT);
                tb_read_to_file("master_hp1","read_from_hp1.txt",read_addr,tb.uut.SMPL_COUNT,rsp);
            end
            else if (tb.uut.irq_status == 4'b0101) begin
                $display("IRQ on ADDR_ERROR...");
                $finish;
            end
            repeat(125) @(posedge tb.FCLK_CLK0);
        end
    end

    begin
        repeat(20000) @(posedge tb.FCLK_CLK0);
        // PCAP_SOFT_DISARM_ADDR
        tb.zynq.ps.inst.write_data(32'h43C0_0014, 4, 1, wrs);
    end

    join

    repeat(1250) @(posedge tb.FCLK_CLK0);

    //Read DMA data into file for verification
//    tb_read_to_file("master_hp1","read_from_hp1.txt",32'h1000_0000,tb.DMA_SIZE,rsp);
    $display("%d DWORDS are read...", tb.DMA_SIZE/4);
    $finish;
end

endmodule
