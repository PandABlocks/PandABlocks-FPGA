module test;

panda_top_tb tb();

reg [1:0]   wrs, rsp;
reg [3:0]   irq_status;
reg [31:0]  addr;
reg         active;

reg [31:0]  read_data;

integer i;

`include "./apis_tb.v"

initial begin
    repeat(2) @(posedge tb.uut.ps.FCLK);
    tb.uut.ps.ps.hp1.cdn_axi3_master_bfm_inst.RESPONSE_TIMEOUT = 0;
    tb.uut.ps.ps.hp1.cdn_axi3_master_bfm_inst.set_channel_level_info(0);
    tb.uut.ps.ps.hp1.cdn_axi3_master_bfm_inst.set_function_level_info(0);
    tb.uut.ps.ps.ps.inst.set_function_level_info("ALL",0);
    tb.uut.ps.ps.ps.inst.set_channel_level_info("ALL",0);
end

initial begin
    wait(tb.uut.ps.tb_ARESETn === 0) @(posedge tb.uut.ps.FCLK);
    wait(tb.uut.ps.tb_ARESETn === 1) @(posedge tb.uut.ps.FCLK);

    $display("Reset Done. Setting the Slave profiles \n");
    tb.uut.ps.ps.ps.inst.set_slave_profile("S_AXI_HP0",2'b11);
    $display("Profile Done\n");

    // TTL Loopback for TTLOUT[5:0]
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_0000,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_0100,  4, 1, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_0200,  4, 2, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_0300,  4, 3, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_0400,  4, 4, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_0500,  4, 5, wrs);

    // LVDS Loopback
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_1000,  4, 6, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_1100,  4, 7, wrs);

    // LUT
    // A
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2000,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2004,  4, 1, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2008,  4, 2, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_200C,  4, 3, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2010,  4, 4, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2014,  4, 32'hffff0000, wrs);

    // A&B|C&~D
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2100,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2104,  4, 1, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2108,  4, 2, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_210C,  4, 3, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2110,  4, 4, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2114,  4, 32'hff303030, wrs);

    // SRGATE
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_3000,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_3004,  4, 3, wrs);

    // DIV
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_4000,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_400C,  4, 4000, wrs);

    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_4100,  4, 3, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_410C,  4, 4000, wrs);

    // Force Reset on both DIVs.
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_4014,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_4114,  4, 0, wrs);

    repeat(100) @(posedge tb.uut.ps.FCLK);
    tb.uut.ps.ps.ps.inst.read_data(32'h43C0_4010,  4, read_data, wrs);
    $display("Read Data = (%0d)\n",read_data);
    tb.uut.ps.ps.ps.inst.read_data(32'h43C0_4110,  4, read_data, wrs);
    $display("Read Data = (%0d)\n",read_data);

    // Setup Position Capture
    // BLOCK_SIZE in TLPs
    //tb.uut.ps.ps.ps.inst.write_data(32'h43C1_F000,  4, 1, wrs);

    repeat(100000) @(posedge tb.uut.ps.FCLK);

    $finish;
end

endmodule
