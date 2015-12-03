module test;

panda_top_tb tb();

reg [511:0]     test_name = "PULSE_TEST";

reg [1:0]       wrs, rsp;
reg [3:0]       irq_status;
reg [31:0]      addr;
reg             active;

reg [31:0]      read_data;

integer         i;
integer         fid;
integer         r;
integer         len;

integer         data;

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

if (test_name == "TTL_TEST") begin
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

end
else if (test_name == "LUT_TEST") begin
    // LUT -1
    // A
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2000,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2004,  4, 1, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2008,  4, 2, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_200C,  4, 3, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2010,  4, 4, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2014,  4, 32'hffff0000, wrs);

    // LUT -2
    // A&B|C&~D
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2100,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2104,  4, 1, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2108,  4, 2, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_210C,  4, 3, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2110,  4, 4, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_2114,  4, 32'hff303030, wrs);
end
else if (test_name == "SRGATE_TEST") begin
    // SRGATE
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_3000,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_3004,  4, 3, wrs);
end
else if (test_name == "DIV_TEST") begin
    // DIV-1
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_4000,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_400C,  4, 4000, wrs);

    // DIV-2
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_4100,  4, 3, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_410C,  4, 4000, wrs);

        // Force Reset on both DIVs.
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_4014,  4, 0, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_4114,  4, 0, wrs);

        // Read COUNT status from DIVs
    repeat(100) @(posedge tb.uut.ps.FCLK);
    tb.uut.ps.ps.ps.inst.read_data(32'h43C0_4010,  4, read_data, wrs);
    $display("Read Data = (%0d)\n",read_data);
    tb.uut.ps.ps.ps.inst.read_data(32'h43C0_4110,  4, read_data, wrs);
    $display("Read Data = (%0d)\n",read_data);

end
else if (test_name == "PULSE_TEST") begin
    $display("RUNNING PULSE TEST...");
        // CLOCKS-CLKA/B/C/D
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_C000,  4,125, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_C004,  4,250, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_C008,  4,500, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_C00C,  4,1000, wrs);

        // PULSE-1
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5000,  4,122, wrs); //INP
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5004,  4,127, wrs); //RST
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5008,  4,  5, wrs); //D-L
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_500C,  4,  0, wrs); //D-H
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5010,  4, 25, wrs); //W-L
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5014,  4,  0, wrs); //W-H
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5018,  4,  0, wrs); //FORCE
        // PULSE-2
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5100,  4, 0, wrs); //INP
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5108,  4, 5, wrs); //D-L
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_510C,  4, 0, wrs); //D-H
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5110,  4,20, wrs); //W-L
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5114,  4, 0, wrs); //W-H
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5118,  4, 0, wrs); //FORCE
        // PULSE-3
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5200,  4, 0, wrs); //INP
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5208,  4, 5, wrs); //D-L
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_520C,  4, 0, wrs); //D-H
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5210,  4,30, wrs); //W-L
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5214,  4, 0, wrs); //W-H
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5218,  4, 0, wrs); //FORCE
        // PULSE-2
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5300,  4, 0, wrs); //INP
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5308,  4, 5, wrs); //D-L
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_530C,  4, 0, wrs); //D-H
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5310,  4,40, wrs); //W-L
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5314,  4, 0, wrs); //W-H
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_5318,  4, 0, wrs); //FORCE
end
else if (test_name == "SEQ_TEST") begin
    $display("RUNNING SEQUENCER TEST...");
    len <= 1;
    fid = $fopen("table.dat", "r");
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_6004,  4, 0, wrs); //INPA
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_6008,  4, 0, wrs); //INPA
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_600C,  4, 0, wrs); //INPA
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_6010,  4, 0, wrs); //INPA
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_6014,  4, 2, wrs); //PRESC

    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_601C,  4, 2, wrs); //TREPEAT
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_6024,  4, 1, wrs); //TRST

    while (!$feof(fid)) begin
        r = $fscanf(fid, "%d\n", data);
        tb.uut.ps.ps.ps.inst.write_data(32'h43C0_6028,  4, data, wrs); //TDAT
        len <= len + 1;
        repeat(1) @(posedge tb.uut.ps.FCLK);
    end

    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_6020,  4, len, wrs);//TLEN
    repeat(1250) @(posedge tb.uut.ps.FCLK);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_6018,  4, 1, wrs);//SGATE
    repeat(1250) @(posedge tb.uut.ps.FCLK);

    tb.uut.ps.ps.ps.inst.read_data(32'h43C0_602C,  4, read_data, wrs);
    $display("CUR_FRAME = (%0d)\n",read_data);
    tb.uut.ps.ps.ps.inst.read_data(32'h43C0_6030,  4, read_data, wrs);
    $display("CUR_FCYCLE = (%0d)\n",read_data);
    tb.uut.ps.ps.ps.inst.read_data(32'h43C0_6034,  4, read_data, wrs);
    $display("CUR_TCYCLE = (%0d)\n",read_data);
    tb.uut.ps.ps.ps.inst.read_data(32'h43C0_6038,  4, read_data, wrs);
    $display("STATE = (%0d)\n",read_data);
end
else
    $display("NO TEST SELECTED...");

// Setup Position Capture
    // BLOCK_SIZE in TLPs
    //tb.uut.ps.ps.ps.inst.write_data(32'h43C1_F000,  4, 1, wrs);
    repeat(100000) @(posedge tb.uut.ps.FCLK);

    $finish;
end

endmodule
