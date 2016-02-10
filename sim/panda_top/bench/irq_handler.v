while (1) begin
    // Wait for DMA irq
    WAIT_IRQ(IRQ_STATUS);
    // Read IRQ Status and Sample Count Registers
    REG_READ(DRV_BASE, DRV_PCAP_IRQ_STATUS, IRQ_STATUS);
    SMPL_COUNT = IRQ_STATUS[31:16];
    IRQ_FLAGS = IRQ_STATUS[7:0];

    // Keep track of address and sample count.
    smpl_table[irq_count] = SMPL_COUNT;
    addr_table[irq_count] = read_addr;
    irq_count = irq_count + 1;

    // Set next DMA address
    read_addr = addr;
    addr = addr + tb.BLOCK_SIZE;

    if (IRQ_FLAGS[0] == 1'b0) begin
        if (IRQ_FLAGS[5] == 1'b1)
            $display("IRQ on TIMEOUT with %d samples.", SMPL_COUNT);
        else if (IRQ_FLAGS[6] == 1'b1)
            $display("IRQ on BLOCK_FINISHED with %d samples.", SMPL_COUNT);

        // DRV_PCAP_DMA_ADDR
        REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);
    end
    else if (IRQ_FLAGS[0] == 1'b1) begin
        $display("IRQ on COMPLETION with %d samples.", SMPL_COUNT);
        $display("Completion Status = %d", IRQ_FLAGS);

        // Read scattered data from host memory into a file.
        for (j=0; j<irq_count; j=j+1) begin
            $display("Reading %d Samples from Address=%08x", smpl_table[j], addr_table[j]);
            tb_read_to_file("master_hp1","read_from_hp1.txt",addr_table[j],4*smpl_table[j],rsp);
            total_samples = total_samples + smpl_table[j];
        end

        $display("Total Samples = %d", total_samples);
        // DRV_PCAP_DMA_ADDR
        REG_WRITE(DRV_BASE, DRV_PCAP_DMA_ADDR, addr);
        $finish;
    end
end

