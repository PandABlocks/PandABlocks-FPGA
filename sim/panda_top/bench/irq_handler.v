while (1) begin
    // Wait for DMA irq
    tb.uut.ps.ps.ps.inst.wait_interrupt(0,IRQ_STATUS);
    // Read IRQ Status and Sample Count Registers
    REG_READ(DRV_BASE, DRV_PCAP_IRQ_STATUS, IRQ_STATUS);
    SMPL_COUNT = IRQ_STATUS[31:16];
    IRQ_FLAGS = IRQ_STATUS[3:0];

    // Keep track of address and sample count.
    smpl_table[irq_count] = SMPL_COUNT;
    addr_table[irq_count] = read_addr;
    irq_count = irq_count + 1;

    // Set next DMA address
    read_addr = addr;
    addr = addr + tb.BLOCK_SIZE;

    if (IRQ_FLAGS == 4'b0001) begin
        $display("IRQ on BLOCK_FINISHED with %d samples.", SMPL_COUNT);
        // DRV_PCAP_DMA_ADDR
        REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);
    end
    else if (IRQ_FLAGS == 4'b0010) begin
        $display("IRQ on CAPT_FINISHED with %d samples.", SMPL_COUNT);

        // Read scattered data from host memory into a file.
        for (j=0; j<irq_count; j=j+1) begin
            $display("Reading %d Samples from Address=%08x", smpl_table[j], addr_table[j]);
            tb_read_to_file("master_hp1","read_from_hp1.txt",addr_table[j],4*smpl_table[j],rsp);
            total_samples = total_samples + smpl_table[j];
        end

        $display("Total Samples = %d", total_samples);
        $finish;
    end
    else if (IRQ_FLAGS == 4'b0011) begin
        $display("IRQ on TIMEOUT with %d samples.", SMPL_COUNT);
        REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);
    end
    else if (IRQ_FLAGS == 4'b0100) begin
        $display("IRQ on DISARM with %d samples.", SMPL_COUNT);
        // Read scattered data from host memory into a file.
        for (j=0; j<irq_count; j=j+1) begin
            $display("Reading %d Samples from Address=%08x", smpl_table[j], addr_table[j]);
            tb_read_to_file("master_hp1","read_from_hp1.txt",addr_table[j],4*smpl_table[j],rsp);
            total_samples = total_samples + smpl_table[j];
        end
        $display("Total Samples = %d", total_samples);
        $finish;
    end
    else if (IRQ_FLAGS == 4'b0110) begin
        $display("IRQ on INT_DISARM with %d samples.", SMPL_COUNT);
        // Read scattered data from host memory into a file.
        for (j=0; j<irq_count; j=j+1) begin
            $display("Reading %d Samples from Address=%08x", smpl_table[j], addr_table[j]);
            tb_read_to_file("master_hp1","read_from_hp1.txt",addr_table[j],4*smpl_table[j],rsp);
            total_samples = total_samples + smpl_table[j];
        end
        $display("Total Samples = %d", total_samples);
        $finish;
    end
    else if (IRQ_FLAGS == 4'b0101) begin
        $display("IRQ on ADDR_ERROR...");
        $finish;
    end
    else begin
        $display("Unknown IRQ...");
        repeat(1250) @(posedge tb.uut.ps.FCLK);
        $finish;
    end
end

