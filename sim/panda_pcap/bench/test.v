module test;

panda_pcap_tb tb();

initial begin
    repeat(2) @(posedge tb.tb_ACLK);
    /* Disable the function and channel level infos from BFM */
    tb.zynq_ps.inst.set_function_level_info("ALL",0);
    tb.zynq_ps.inst.set_channel_level_info("ALL",1);
end


initial begin
    wait(tb.tb_ARESETn === 0) @(posedge tb.tb_ACLK);
    wait(tb.tb_ARESETn === 1) @(posedge tb.tb_ACLK);

    $display("Reset Done. Setting the Slave profiles \n");

    tb.zynq_ps.inst.set_slave_profile("S_AXI_HP0",2'b11);
    $display("Profile Done\n");

    repeat(5) @(posedge tb.tb_ACLK);

    $display("Start Preload \n");
    tb.zynq_ps.inst.pre_load_mem_from_file("preload_ddr.txt",32'h0010_0000,1024);
    tb.zynq_ps.inst.pre_load_mem(2,32'h0000_0000,1024);
    $display("Done Preload \n");
    force tb.zynq_ps.inst.IRQ_F2P = 4'b0000;
    $finish;
end

endmodule
