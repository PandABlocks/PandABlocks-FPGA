module test;

`include "./registers.v"
`include "./apis_tb.v"

panda_top_tb tb();

reg [511:0]     test_name = "POSITION_TEST";

reg [1:0]       wrs, rsp;
reg [3:0]       IRQ_STATUS;
reg [31:0]      SMPL_COUNT;
reg [31:0]      dma_addr;
reg [31:0]      addr;
reg [31:0]      base;
reg [31:0]      total_samples;

reg [31:0]      addr_table[31: 0];
reg [31:0]      smpl_table[31: 0];
integer         irq_count;

reg [31:0]      read_data;


integer         fid;
integer         r;
integer         len;

integer         data;

reg [31:0]      read_addr;
reg             active;

integer i;


// Wrapper for Zynx AXI4 transactions.
task REG_WRITE;
    input [31: 0] base;
    input [31: 0] addr;
    input [31: 0] val;
begin
    tb.uut.ps.ps.ps.inst.write_data(base + 4*addr,  4, val, wrs);
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

    tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h1);
    tb.uut.ps.ps.ps.inst.fpga_soft_reset(32'h0);

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
else if (test_name == "PCAP_TEST") begin
    $display("RUNNING PCAP TEST...");

    base = 32'h43C1_1000;
    addr = 32'h1000_0000;
    read_addr = 32'h1000_0000;
    irq_count = 0;
    total_samples = 0;

    repeat(1250) @(posedge tb.uut.ps.FCLK);

fork
begin
    // CLOCKS-CLKA/B/C/D
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_C000,  4, 125, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_C004,  4, 250, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_C008,  4, 500, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_C00C,  4, 1000, wrs);

    // Set-up Counters 0/1
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D000 + 4*COUNTER_ENABLE_VAL_ADDR,  4, 118, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D000 + 4*COUNTER_TRIGGER_VAL_ADDR, 4, 122, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D000 + 4*COUNTER_STEP_ADDR, 4, 1, wrs);

    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D100 + 4*COUNTER_ENABLE_VAL_ADDR,  4, 118, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D100 + 4*COUNTER_TRIGGER_VAL_ADDR, 4, 122, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D100 + 4*COUNTER_STEP_ADDR, 4, 1, wrs);

    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D300 + 4*COUNTER_ENABLE_VAL_ADDR,  4, 118, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D300 + 4*COUNTER_TRIGGER_VAL_ADDR, 4, 122, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D300 + 4*COUNTER_STEP_ADDR, 4, 1, wrs);

    // PCAP_ENABLE_VAL_ADDR
    tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_ENABLE_VAL_ADDR, 4, 118, wrs);

    // PCAP_TRIGGER_VAL_ADDR
    tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_TRIGGER_VAL_ADDR, 4, 122, wrs);

    // PCAP_BITBUS_MASK_ADDR
    tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_BITBUS_MASK_ADDR, 4, 0, wrs);

    // PCAP_CAPTURE_MASK_ADDR
    tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_CAPTURE_MASK_ADDR, 4,
    32'h0000_B000, wrs);

    // PCAP_EXT_MASK_ADDR
    tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_EXT_MASK_ADDR, 4, 0, wrs);

    // PCAP_TIMEOUT_ADDR
    tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_TIMEOUT_ADDR, 4, 0, wrs);

    // PCAP_DMAADDR_ADDR
    tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_DMAADDR_ADDR, 4, addr, wrs);

    // PCAP_SOFT_ARM_ADDR
    tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_SOFT_ARM_ADDR, 4, 1, wrs);

    // PCAP_DMAADDR_ADDR
    addr = addr + tb.BLOCK_SIZE;
    tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_DMAADDR_ADDR, 4, addr, wrs);

    // SOFTA/
    repeat(1250) @(posedge tb.uut.ps.FCLK);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_D000,  4, 1, wrs);
    repeat(125 * 1000) @(posedge tb.uut.ps.FCLK);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_D000,  4, 0, wrs);
end

begin
    while (1) begin
        // Wait for DMA irq
        tb.uut.ps.ps.ps.inst.wait_interrupt(0,IRQ_STATUS);
        // Read IRQ Status and Sample Count Registers
        tb.uut.ps.ps.ps.inst.read_data(base+4*PCAP_IRQ_STATUS_ADDR,  4, IRQ_STATUS, wrs);
        tb.uut.ps.ps.ps.inst.read_data(base+4*PCAP_SMPL_COUNT_ADDR,  4, SMPL_COUNT, wrs);

        // Keep track of address and sample count.
        smpl_table[irq_count] = SMPL_COUNT;
        addr_table[irq_count] = read_addr;
        irq_count = irq_count + 1;

        // Set next DMA address
        read_addr = addr;
        addr = addr + tb.BLOCK_SIZE;

        if (IRQ_STATUS == 4'b0001) begin
            $display("IRQ on BLOCK_FINISHED with %d samples.", SMPL_COUNT);
            // PCAP_DMAADDR_ADDR
            tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_DMAADDR_ADDR, 4, addr, wrs);
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
            // PCAP_DMAADDR_ADDR
            tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_DMAADDR_ADDR, 4, addr, wrs);
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

begin
    repeat(125 * 1000) @(posedge tb.uut.ps.FCLK);
    // PCAP_SOFT_DISARM_ADDR
    //tb.uut.ps.ps.ps.inst.write_data(base+4*PCAP_SOFT_DISARM_ADDR, 4, 1, wrs);
end

join

    repeat(1250) @(posedge tb.uut.ps.FCLK);

    $finish;
end
else if (test_name == "INENC_TEST") begin
    repeat(1250) @(posedge tb.uut.ps.FCLK);
    // SLOW_INENC_CTRL_ADDR
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_B000, 4, 32'h3, wrs);
    // SLOW_OUTENC_CTRL_ADDR
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_B000, 4, 32'h7, wrs);
    repeat(25000) @(posedge tb.uut.ps.FCLK);
    $finish;
end
else if (test_name == "SSIENC_TEST") begin
    repeat(1250) @(posedge tb.uut.ps.FCLK);
    // CLOCKS-CLKA as trigger source
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_C000,  4, 12500, wrs);
    // Set-up Counters 0 as position source
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D000 + 4*COUNTER_ENABLE_VAL_ADDR,  4, 118, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D000 + 4*COUNTER_TRIGGER_VAL_ADDR, 4, 122, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_D000 + 4*COUNTER_STEP_ADDR, 4, 1, wrs);

    // SLOW_INENC_CTRL_ADDR
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_B000, 4, 32'hC, wrs);
    // SLOW_OUTENC_CTRL_ADDR
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_B004, 4, 32'h28, wrs);

    // Set-up OutEnc
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_8000 + 4*OUTENC_PROTOCOL_ADDR, 4, 1, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_8000 + 4*OUTENC_BITS_ADDR, 4, 24, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_8000 + 4*OUTENC_POSN_VAL_ADDR, 4, 12, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_8000 + 4*OUTENC_BITS_ADDR, 4, 24, wrs);

    // Set-up InEnc
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_7000 + 4*INENC_PROTOCOL_ADDR, 4, 1, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_7000 + 4*INENC_BITS_ADDR, 4, 24, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_7000 + 4*INENC_CLKRATE_ADDR, 4, 125, wrs);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C0_7000 + 4*INENC_FRAMERATE_ADDR, 4, 100, wrs);

    repeat(1250) @(posedge tb.uut.ps.FCLK);
    tb.uut.ps.ps.ps.inst.write_data(32'h43C1_D000,  4, 1, wrs);

    repeat(40000) @(posedge tb.uut.ps.FCLK);
    $finish;
end
else if (test_name == "POSITION_TEST") begin
    $display("Running POSITION TEST...");

    base = 32'h43C1_1000;
    addr = 32'h1000_0000;
    read_addr = 32'h1000_0000;
    irq_count = 0;
    total_samples = 0;

    repeat(1250) @(posedge tb.uut.ps.FCLK);

    repeat(1250) @(posedge tb.uut.ps.FCLK);
    // Setup Slow Controller Block for Absolute
    REG_WRITE(SLOW_BASE, SLOW_INENC_CTRL_ADDR, 32'h3);
    REG_WRITE(SLOW_BASE, SLOW_OUTENC_CTRL_ADDR, 32'h7);

    // Setup Position Compare Block
    REG_WRITE(PCOMP_BASE, PCOMP_ENABLE_VAL_ADDR, 106);  // pcap_act
    REG_WRITE(PCOMP_BASE, PCOMP_POSN_VAL_ADDR, 1);      // inenc_posn(0)
    REG_WRITE(PCOMP_BASE, PCOMP_START_ADDR, 100);
    REG_WRITE(PCOMP_BASE, PCOMP_STEP_ADDR, 100);
    REG_WRITE(PCOMP_BASE, PCOMP_WIDTH_ADDR, 10);
    REG_WRITE(PCOMP_BASE, PCOMP_NUM_ADDR, 10);

    // Setup Position Capture
    REG_WRITE(PCAP_BASE, PCAP_ENABLE_VAL_ADDR, 98);     // pcomp_act(0)
    REG_WRITE(PCAP_BASE, PCAP_TRIGGER_VAL_ADDR, 102);   // pcomp_pulse
    REG_WRITE(PCAP_BASE, PCAP_BITBUS_MASK_ADDR, 0);
    REG_WRITE(PCAP_BASE, PCAP_CAPTURE_MASK_ADDR, 2);
    REG_WRITE(PCAP_BASE, PCAP_EXT_MASK_ADDR, 0);
    REG_WRITE(PCAP_BASE, PCAP_TIMEOUT_ADDR, 0);
    REG_WRITE(PCAP_BASE, PCAP_DMAADDR_ADDR, addr);
    REG_WRITE(PCAP_BASE, PCAP_SOFT_ARM_ADDR, 1);
    addr = addr + tb.BLOCK_SIZE;
    REG_WRITE(PCAP_BASE, PCAP_DMAADDR_ADDR, addr);
    repeat(1250) @(posedge tb.uut.ps.FCLK);

fork
begin
    tb.encoder.Turn(1500);
end

begin
    while (1) begin
        // Wait for DMA irq
        tb.uut.ps.ps.ps.inst.wait_interrupt(0,IRQ_STATUS);
        // Read IRQ Status and Sample Count Registers
        REG_READ(PCAP_BASE, PCAP_IRQ_STATUS_ADDR, IRQ_STATUS);
        REG_READ(PCAP_BASE, PCAP_SMPL_COUNT_ADDR, SMPL_COUNT);

        // Keep track of address and sample count.
        smpl_table[irq_count] = SMPL_COUNT;
        addr_table[irq_count] = read_addr;
        irq_count = irq_count + 1;

        // Set next DMA address
        read_addr = addr;
        addr = addr + tb.BLOCK_SIZE;

        if (IRQ_STATUS == 4'b0001) begin
            $display("IRQ on BLOCK_FINISHED with %d samples.", SMPL_COUNT);
            // PCAP_DMAADDR_ADDR
            REG_WRITE(PCAP_BASE, PCAP_DMAADDR_ADDR, addr);
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
            REG_WRITE(PCAP_BASE, PCAP_DMAADDR_ADDR, addr);
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

    repeat(1250) @(posedge tb.uut.ps.FCLK);

    $finish;
end
else
    $display("NO TEST SELECTED...");
    repeat(100000) @(posedge tb.uut.ps.FCLK);

    $finish;
end

endmodule
