// Functional Address Space Chip Selects
localparam REG_CS  = 31;
localparam DRV_CS  = 25;
localparam TTLIN_CS  = 18;
localparam TTLOUT_CS  = 0;
localparam LVDSIN_CS  = 17;
localparam LVDSOUT_CS  = 1;
localparam LUT_CS  = 2;
localparam SRGATE_CS  = 3;
localparam DIV_CS  = 4;
localparam PULSE_CS  = 5;
localparam SEQ_CS  = 6;
localparam INENC_CS  = 7;
localparam QDEC_CS  = 8;
localparam OUTENC_CS  = 9;
localparam POSENC_CS  = 10;
localparam ADDER_CS  = 12;
localparam COUNTER_CS  = 13;
localparam PGEN_CS  = 14;
localparam PCOMP_CS  = 15;
localparam ADC_CS  = 26;
localparam PCAP_CS  = 16;
localparam BITS_CS  = 28;
localparam CLOCKS_CS  = 29;
localparam POSITIONS_CS  = 30;
localparam SLOW_CS  = 27;

// Block Register Address Space

// REG Block:
localparam REG_FPGA_VERSION  = 0;
localparam REG_FPGA_BUILD  = 1;
localparam REG_SLOW_VERSION  = 2;
localparam REG_BIT_READ_RST  = 3;
localparam REG_BIT_READ_VALUE  = 4;
localparam REG_POS_READ_RST  = 5;
localparam REG_POS_READ_VALUE  = 6;
localparam REG_POS_READ_CHANGES  = 7;
localparam REG_PCAP_START_WRITE  = 8;
localparam REG_PCAP_WRITE  = 9;
localparam REG_PCAP_FRAMING_MASK  = 10;
localparam REG_PCAP_FRAMING_ENABLE  = 11;
localparam REG_PCAP_FRAMING_MODE  = 12;
localparam REG_PCAP_ARM  = 13;
localparam REG_PCAP_DISARM  = 14;
localparam REG_SLOW_REGISTER_STATUS  = 15;

// DRV Block:
localparam DRV_PCAP_DMAADDR  = 0;
localparam DRV_PCAP_TIMEOUT  = 1;
localparam DRV_PCAP_IRQ_STATUS  = 2;
localparam DRV_PCAP_SMPL_COUNT  = 3;
localparam DRV_PCAP_BLOCK_SIZE  = 4;

// TTLIN Block:
localparam TTLIN_TERM  = 0;

// TTLOUT Block:
localparam TTLOUT_VAL  = 0;

// LVDSIN Block:

// LVDSOUT Block:
localparam LVDSOUT_VAL  = 0;

// LUT Block:
localparam LUT_FUNC  = 5;
localparam LUT_INPA  = 0;
localparam LUT_INPB  = 1;
localparam LUT_INPC  = 2;
localparam LUT_INPD  = 3;
localparam LUT_INPE  = 4;

// SRGATE Block:
localparam SRGATE_SET_EDGE  = 2;
localparam SRGATE_RST_EDGE  = 3;
localparam SRGATE_FORCE_SET  = 4;
localparam SRGATE_FORCE_RST  = 5;
localparam SRGATE_SET  = 0;
localparam SRGATE_RST  = 1;

// DIV Block:
localparam DIV_DIVISOR  = 2;
localparam DIV_FIRST_PULSE  = 3;
localparam DIV_FORCE_RST  = 5;
localparam DIV_INP  = 0;
localparam DIV_RST  = 1;
localparam DIV_COUNT  = 4;

// PULSE Block:
localparam PULSE_DELAY_L  = 3;
localparam PULSE_DELAY_H  = 2;
localparam PULSE_WIDTH_L  = 5;
localparam PULSE_WIDTH_H  = 4;
localparam PULSE_FORCE_RST  = 6;
localparam PULSE_INP  = 0;
localparam PULSE_RST  = 1;
localparam PULSE_ERR_OVERFLOW  = 7;
localparam PULSE_ERR_PERIOD  = 8;
localparam PULSE_QUEUE  = 9;
localparam PULSE_MISSED_CNT  = 10;

// SEQ Block:
localparam SEQ_PRESCALE  = 5;
localparam SEQ_SOFT_GATE  = 6;
localparam SEQ_TABLE_CYCLE  = 8;
localparam SEQ_GATE  = 0;
localparam SEQ_INPA  = 1;
localparam SEQ_INPB  = 2;
localparam SEQ_INPC  = 3;
localparam SEQ_INPD  = 4;
localparam SEQ_CUR_FRAME  = 9;
localparam SEQ_CUR_FCYCLE  = 10;
localparam SEQ_CUR_TCYCLE  = 11;
localparam SEQ_TABLE_STROBES  = 12;
localparam SEQ_TABLE_START  = 13;
localparam SEQ_TABLE_DATA  = 14;
localparam SEQ_TABLE_LENGTH  = 15;

// INENC Block:
localparam INENC_PROTOCOL  = 0;
localparam INENC_CLKRATE  = 1;
localparam INENC_FRAMERATE  = 2;
localparam INENC_BITS  = 3;
localparam INENC_SETP  = 4;
localparam INENC_RST_ON_Z  = 5;
localparam INENC_EXTENSION  = 6;

// QDEC Block:
localparam QDEC_RST_ON_Z  = 3;
localparam QDEC_SETP  = 4;
localparam QDEC_A  = 0;
localparam QDEC_B  = 1;
localparam QDEC_Z  = 2;

// OUTENC Block:
localparam OUTENC_PROTOCOL  = 5;
localparam OUTENC_BITS  = 6;
localparam OUTENC_QPRESCALAR  = 7;
localparam OUTENC_FORCE_QSTATE  = 8;
localparam OUTENC_A  = 0;
localparam OUTENC_B  = 1;
localparam OUTENC_Z  = 2;
localparam OUTENC_POSN  = 4;
localparam OUTENC_CONN  = 3;
localparam OUTENC_QSTATE  = 9;

// POSENC Block:
localparam POSENC_POSN  = 0;
localparam POSENC_QPRESCALAR  = 1;
localparam POSENC_MODE  = 2;
localparam POSENC_FORCE_QSTATE  = 3;
localparam POSENC_QSTATE  = 4;

// ADDER Block:
localparam ADDER_MASK  = 1;
localparam ADDER_OUTSCALE  = 2;

// COUNTER Block:
localparam COUNTER_DIR  = 2;
localparam COUNTER_START  = 3;
localparam COUNTER_STEP  = 4;
localparam COUNTER_ENABLE  = 0;
localparam COUNTER_TRIGGER  = 1;

// PGEN Block:
localparam PGEN_SAMPLES  = 2;
localparam PGEN_CYCLES  = 3;
localparam PGEN_ENABLE  = 0;
localparam PGEN_TRIGGER  = 1;
localparam PGEN_TABLE_START  = 4;
localparam PGEN_TABLE_DATA  = 5;

// PCOMP Block:
localparam PCOMP_START  = 2;
localparam PCOMP_STEP  = 3;
localparam PCOMP_WIDTH  = 4;
localparam PCOMP_PNUM  = 5;
localparam PCOMP_RELATIVE  = 6;
localparam PCOMP_DIR  = 7;
localparam PCOMP_FLTR_DELTAT  = 8;
localparam PCOMP_FLTR_THOLD  = 9;
localparam PCOMP_LUT_ENABLE  = 10;
localparam PCOMP_ENABLE  = 0;
localparam PCOMP_POSN  = 1;
localparam PCOMP_TABLE_START  = 11;
localparam PCOMP_TABLE_DATA  = 12;

// ADC Block:
localparam ADC_TRIGGER  = 0;
localparam ADC_RST  = 1;

// PCAP Block:
localparam PCAP_ENABLE  = 0;
localparam PCAP_FRAME  = 1;
localparam PCAP_CAPTURE  = 2;
localparam PCAP_MISSED_CAPTURES  = 3;
localparam PCAP_ERR_STATUS  = 4;

// BITS Block:
localparam BITS_A_SET  = 0;
localparam BITS_B_SET  = 1;
localparam BITS_C_SET  = 2;
localparam BITS_D_SET  = 3;

// CLOCKS Block:
localparam CLOCKS_A_PERIOD  = 0;
localparam CLOCKS_B_PERIOD  = 1;
localparam CLOCKS_C_PERIOD  = 2;
localparam CLOCKS_D_PERIOD  = 3;

// POSITIONS Block:

// SLOW Block:
localparam SLOW_FPGA_VERSION  = 0;
localparam SLOW_ENC_CONN  = 1;


// Panda Base Address and block base addresses
localparam BASE = 32'h43C0_0000;
localparam REG_BASE = BASE + 4096 * REG_CS;
localparam DRV_BASE = BASE + 4096 * DRV_CS;
localparam TTLIN_BASE = BASE + 4096 * TTLIN_CS;
localparam TTLOUT_BASE = BASE + 4096 * TTLOUT_CS;
localparam LVDSIN_BASE = BASE + 4096 * LVDSIN_CS;
localparam LVDSOUT_BASE = BASE + 4096 * LVDSOUT_CS;
localparam LUT_BASE = BASE + 4096 * LUT_CS;
localparam SRGATE_BASE = BASE + 4096 * SRGATE_CS;
localparam DIV_BASE = BASE + 4096 * DIV_CS;
localparam PULSE_BASE = BASE + 4096 * PULSE_CS;
localparam SEQ_BASE = BASE + 4096 * SEQ_CS;
localparam INENC_BASE = BASE + 4096 * INENC_CS;
localparam QDEC_BASE = BASE + 4096 * QDEC_CS;
localparam OUTENC_BASE = BASE + 4096 * OUTENC_CS;
localparam POSENC_BASE = BASE + 4096 * POSENC_CS;
localparam ADDER_BASE = BASE + 4096 * ADDER_CS;
localparam COUNTER_BASE = BASE + 4096 * COUNTER_CS;
localparam PGEN_BASE = BASE + 4096 * PGEN_CS;
localparam PCOMP_BASE = BASE + 4096 * PCOMP_CS;
localparam ADC_BASE = BASE + 4096 * ADC_CS;
localparam PCAP_BASE = BASE + 4096 * PCAP_CS;
localparam BITS_BASE = BASE + 4096 * BITS_CS;
localparam CLOCKS_BASE = BASE + 4096 * CLOCKS_CS;
localparam POSITIONS_BASE = BASE + 4096 * POSITIONS_CS;
localparam SLOW_BASE = BASE + 4096 * SLOW_CS;
