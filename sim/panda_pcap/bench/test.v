module test;

panda_pcap_tb tb();

reg [1:0]   wrs, rsp;
reg [3:0]   irq_status;
reg [31:0]  addr;
reg         active;

integer i;

`include "./apis_tb.v"

initial begin
    repeat(2) @(posedge tb.tb_ACLK);

    /* Disable the function and channel level infos from BFM */
    tb.zynq.hp1.cdn_axi3_master_bfm_inst.RESPONSE_TIMEOUT = 0;
    tb.zynq.hp1.cdn_axi3_master_bfm_inst.set_channel_level_info(0);
    tb.zynq.hp1.cdn_axi3_master_bfm_inst.set_function_level_info(0);

    tb.zynq.ps.inst.set_function_level_info("ALL",0);
    tb.zynq.ps.inst.set_channel_level_info("ALL",0);
end

parameter integer DMA_SIZE   = 1024*1024;     // 1MB
parameter integer BLOCK_SIZE = 4*1024;        // 4KB

initial begin
    addr = 32'h1000_0000;
    active = 1;
    wait(tb.tb_ARESETn === 0) @(posedge tb.FCLK_CLK0);
    wait(tb.tb_ARESETn === 1) @(posedge tb.FCLK_CLK0);

    $display("Reset Done. Setting the Slave profiles \n");

    tb.zynq.ps.inst.set_slave_profile("S_AXI_HP0",2'b11);
    tb.zynq.ps.inst.set_slave_profile("S_AXI_HP1",2'b11);
    $display("Profile Done\n");

    repeat(1250) @(posedge tb.FCLK_CLK0);

    // Setup Position Capture
    // BLOCK_SIZE in TLPs
    tb.zynq.ps.inst.write_data(32'h43C0_0000 + 4*2,  4, BLOCK_SIZE/128, wrs);
    // DBG: DMA size in DWORDs
    tb.zynq.ps.inst.write_data(32'h43C0_0000 + 4*13, 4, DMA_SIZE/4, wrs);

    tb.zynq.ps.inst.write_data(32'h43C0_0000 + 4*3,  4, addr, wrs); //addr
    tb.zynq.ps.inst.write_data(32'h43C0_0000 + 4*10, 4, 32'h1, wrs); //dbg
    tb.zynq.ps.inst.write_data(32'h43C0_0000 + 4*4,  4, 32'h1, wrs); //arm

    addr = addr + BLOCK_SIZE;
    tb.zynq.ps.inst.write_data(32'h43C0_0000 + 4*3,  4, addr, wrs); //addr
    tb.zynq.ps.inst.write_data(32'h43C0_0000 + 4*11, 4, 32'h1, wrs); //ena

    while (active) begin
        // Wait for DMA irq
        tb.zynq.ps.inst.wait_interrupt(0,irq_status);
        if (tb.uut.irq_status == 4'b0010) begin
            $display("IRQ on BLOCK_FINISHED...");
            addr = addr + BLOCK_SIZE;
            tb.zynq.ps.inst.write_data(32'h43C0_0000 + 4*3, 4, addr, wrs); //addr
        end
        else if (tb.uut.irq_status == 4'b0001) begin
            $display("IRQ on LAST_TLP...");
            active = 0;
        end
        else if (tb.uut.irq_status == 4'b0100) begin
            $display("IRQ on ADDR_ERROR...");
            $finish;
        end
        else if (tb.uut.irq_status == 4'b1000) begin
            $display("IRQ on USER_ABORT...");
            $finish;
        end
        repeat(125) @(posedge tb.FCLK_CLK0);
    end

    repeat(125) @(posedge tb.FCLK_CLK0);

    //Read DMA data into file for verification
    tb_read_to_file("master_hp1","read_from_hp1.txt",32'h1000_0000,DMA_SIZE,rsp);

    $finish;
end

endmodule
