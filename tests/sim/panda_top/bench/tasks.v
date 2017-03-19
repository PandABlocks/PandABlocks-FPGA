// Wrapper for Zynx AXI4 transactions.
task REG_WRITE;
    input [31: 0] base;
    input [31: 0] addr;
    input [31: 0] val;
begin
    tb.uut.ps.ps.ps.inst.write_data(base + 4*addr,  4, val, wrs);
    $display("ADDR = %08x, DATA = %08x", base + 4*addr, val);
end
endtask

task REG_READ;
    input  [31: 0] base;
    input  [31: 0] addr;
    output [31: 0] val;
begin
    tb.uut.ps.ps.ps.inst.read_data(base + 4*addr,  4, val, wrs);
end
endtask

task WAIT_IRQ;
    input  [31: 0] status;
begin
    // Wait for DMA irq
    tb.uut.ps.ps.ps.inst.wait_interrupt(0,IRQ_STATUS);
end
endtask

// Zynq INIT
initial begin
    repeat(2) @(posedge tb.uut.ps.FCLK);
    tb.uut.ps.ps.hp1.cdn_axi3_master_bfm_inst.RESPONSE_TIMEOUT = 0;
    tb.uut.ps.ps.hp1.cdn_axi3_master_bfm_inst.set_channel_level_info(0);
    tb.uut.ps.ps.hp1.cdn_axi3_master_bfm_inst.set_function_level_info(0);
    tb.uut.ps.ps.ps.inst.set_function_level_info("ALL",0);
    tb.uut.ps.ps.ps.inst.set_channel_level_info("ALL",0);
end
