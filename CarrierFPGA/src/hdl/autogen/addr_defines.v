// Functional Address Space Chip Selects
localparam REG_CS = 0;
localparam DRV_CS = 1;
localparam TTLIN_CS = 3;
localparam TTLOUT_CS = 4;
localparam LVDSIN_CS = 5;
localparam LVDSOUT_CS = 6;
localparam LUT_CS = 7;
localparam SRGATE_CS = 8;
localparam DIV_CS = 9;
localparam PULSE_CS = 10;
localparam SEQ_CS = 11;
localparam INENC_CS = 12;
localparam QDEC_CS = 13;
localparam OUTENC_CS = 14;
localparam POSENC_CS = 15;
localparam ADDER_CS = 16;
localparam COUNTER_CS = 17;
localparam PGEN_CS = 18;
localparam PCOMP_CS = 19;
localparam ADC_CS = 20;
localparam PCAP_CS = 21;
localparam BITS_CS = 22;
localparam CLOCKS_CS = 23;
localparam POSITIONS_CS = 24;
localparam SLOW_CS = 25;
localparam FMC_CS = 26;
localparam SFP_CS = 27;

// Block Register Address Space

// REG Block:
localparam REG_FPGA_VERSION = 0;
localparam REG_FPGA_BUILD = 1;
localparam REG_SLOW_VERSION = 2;
localparam REG_BIT_READ_RST = 3;
localparam REG_BIT_READ_VALUE = 4;
localparam REG_POS_READ_RST = 5;
localparam REG_POS_READ_VALUE = 6;
localparam REG_POS_READ_CHANGES = 7;
localparam REG_PCAP_START_WRITE = 8;
localparam REG_PCAP_WRITE = 9;
localparam REG_PCAP_FRAMING_MASK = 10;
localparam REG_PCAP_FRAMING_ENABLE = 11;
localparam REG_PCAP_FRAMING_MODE = 12;
localparam REG_PCAP_ARM = 13;
localparam REG_PCAP_DISARM = 14;
localparam REG_SLOW_REGISTER_STATUS = 15;
localparam REG_PCAP_BIT_DELAY_0 = 28;
localparam REG_PCAP_BIT_DELAY_1 = 29;
localparam REG_PCAP_BIT_DELAY_2 = 30;
localparam REG_PCAP_BIT_DELAY_3 = 31;
localparam REG_PCAP_DATA_DELAY_0 = 32;
localparam REG_PCAP_DATA_DELAY_1 = 33;
localparam REG_PCAP_DATA_DELAY_2 = 34;
localparam REG_PCAP_DATA_DELAY_3 = 35;
localparam REG_PCAP_DATA_DELAY_4 = 36;
localparam REG_PCAP_DATA_DELAY_5 = 37;
localparam REG_PCAP_DATA_DELAY_6 = 38;
localparam REG_PCAP_DATA_DELAY_7 = 39;
localparam REG_PCAP_DATA_DELAY_8 = 40;
localparam REG_PCAP_DATA_DELAY_9 = 41;
localparam REG_PCAP_DATA_DELAY_10 = 42;
localparam REG_PCAP_DATA_DELAY_11 = 43;
localparam REG_PCAP_DATA_DELAY_12 = 44;
localparam REG_PCAP_DATA_DELAY_13 = 45;
localparam REG_PCAP_DATA_DELAY_14 = 46;
localparam REG_PCAP_DATA_DELAY_15 = 47;
localparam REG_PCAP_DATA_DELAY_16 = 48;
localparam REG_PCAP_DATA_DELAY_17 = 49;
localparam REG_PCAP_DATA_DELAY_18 = 50;
localparam REG_PCAP_DATA_DELAY_19 = 51;
localparam REG_PCAP_DATA_DELAY_20 = 52;
localparam REG_PCAP_DATA_DELAY_21 = 53;
localparam REG_PCAP_DATA_DELAY_22 = 54;
localparam REG_PCAP_DATA_DELAY_23 = 55;
localparam REG_PCAP_DATA_DELAY_24 = 56;
localparam REG_PCAP_DATA_DELAY_25 = 57;
localparam REG_PCAP_DATA_DELAY_26 = 58;
localparam REG_PCAP_DATA_DELAY_27 = 59;
localparam REG_PCAP_DATA_DELAY_28 = 60;
localparam REG_PCAP_DATA_DELAY_29 = 61;
localparam REG_PCAP_DATA_DELAY_30 = 62;
localparam REG_PCAP_DATA_DELAY_31 = 63;

// DRV Block:
localparam DRV_PCAP_DMA_RESET = 0;
localparam DRV_PCAP_DMA_START = 1;
localparam DRV_PCAP_DMA_ADDR = 2;
localparam DRV_PCAP_TIMEOUT = 3;
localparam DRV_PCAP_IRQ_STATUS = 4;
localparam DRV_PCAP_BLOCK_SIZE = 6;

// TTLIN Block:
localparam TTLIN_TERM = 0;

// TTLOUT Block:
localparam TTLOUT_VAL = 0;
localparam TTLOUT_VAL_DLY = 1;

// LVDSIN Block:

// LVDSOUT Block:
localparam LVDSOUT_VAL = 0;
localparam LVDSOUT_VAL_DLY = 1;

// LUT Block:
localparam LUT_FUNC = 5;
localparam LUT_INPA = 0;
localparam LUT_INPA_DLY = 6;
localparam LUT_INPB = 1;
localparam LUT_INPB_DLY = 7;
localparam LUT_INPC = 2;
localparam LUT_INPC_DLY = 8;
localparam LUT_INPD = 3;
localparam LUT_INPD_DLY = 9;
localparam LUT_INPE = 4;
localparam LUT_INPE_DLY = 10;

// SRGATE Block:
localparam SRGATE_SET_EDGE = 2;
localparam SRGATE_RST_EDGE = 3;
localparam SRGATE_FORCE_SET = 4;
localparam SRGATE_FORCE_RST = 5;
localparam SRGATE_SET = 0;
localparam SRGATE_SET_DLY = 6;
localparam SRGATE_RST = 1;
localparam SRGATE_RST_DLY = 7;

// DIV Block:
localparam DIV_DIVISOR = 2;
localparam DIV_FIRST_PULSE = 3;
localparam DIV_INP = 0;
localparam DIV_INP_DLY = 5;
localparam DIV_ENABLE = 1;
localparam DIV_ENABLE_DLY = 6;
localparam DIV_COUNT = 4;

// PULSE Block:
localparam PULSE_DELAY_L = 3;
localparam PULSE_DELAY_H = 2;
localparam PULSE_WIDTH_L = 5;
localparam PULSE_WIDTH_H = 4;
localparam PULSE_INP = 0;
localparam PULSE_INP_DLY = 11;
localparam PULSE_ENABLE = 1;
localparam PULSE_ENABLE_DLY = 12;
localparam PULSE_ERR_OVERFLOW = 7;
localparam PULSE_ERR_PERIOD = 8;
localparam PULSE_QUEUE = 9;
localparam PULSE_MISSED_CNT = 10;

// SEQ Block:
localparam SEQ_PRESCALE = 5;
localparam SEQ_TABLE_CYCLE = 8;
localparam SEQ_ENABLE = 0;
localparam SEQ_ENABLE_DLY = 16;
localparam SEQ_INPA = 1;
localparam SEQ_INPA_DLY = 17;
localparam SEQ_INPB = 2;
localparam SEQ_INPB_DLY = 18;
localparam SEQ_INPC = 3;
localparam SEQ_INPC_DLY = 19;
localparam SEQ_INPD = 4;
localparam SEQ_INPD_DLY = 20;
localparam SEQ_CUR_FRAME = 9;
localparam SEQ_CUR_FCYCLE = 10;
localparam SEQ_CUR_TCYCLE = 11;
localparam SEQ_TABLE_START = 13;
localparam SEQ_TABLE_DATA = 14;
localparam SEQ_TABLE_LENGTH = 15;

// INENC Block:
localparam INENC_PROTOCOL = 0;
localparam INENC_CLK_PERIOD = 1;
localparam INENC_FRAME_PERIOD = 2;
localparam INENC_BITS = 3;
localparam INENC_BITS_CRC = 4;
localparam INENC_SETP = 5;
localparam INENC_RST_ON_Z = 6;
localparam INENC_EXTENSION = 7;
localparam INENC_ERR_FRAME = 8;
localparam INENC_ERR_RESPONSE = 9;
localparam INENC_ENC_STATUS = 10;
localparam INENC_DCARD_MODE = 11;

// QDEC Block:
localparam QDEC_RST_ON_Z = 3;
localparam QDEC_SETP = 4;
localparam QDEC_A = 0;
localparam QDEC_A_DLY = 5;
localparam QDEC_B = 1;
localparam QDEC_B_DLY = 6;
localparam QDEC_Z = 2;
localparam QDEC_Z_DLY = 7;

// OUTENC Block:
localparam OUTENC_PROTOCOL = 5;
localparam OUTENC_BITS = 6;
localparam OUTENC_QPERIOD = 7;
localparam OUTENC_ENABLE = 8;
localparam OUTENC_ENABLE_DLY = 10;
localparam OUTENC_A = 0;
localparam OUTENC_A_DLY = 11;
localparam OUTENC_B = 1;
localparam OUTENC_B_DLY = 12;
localparam OUTENC_Z = 2;
localparam OUTENC_Z_DLY = 13;
localparam OUTENC_VAL = 4;
localparam OUTENC_CONN = 3;
localparam OUTENC_CONN_DLY = 14;
localparam OUTENC_QSTATE = 9;

// POSENC Block:
localparam POSENC_INP = 0;
localparam POSENC_QPERIOD = 1;
localparam POSENC_ENABLE = 3;
localparam POSENC_ENABLE_DLY = 5;
localparam POSENC_PROTOCOL = 2;
localparam POSENC_QSTATE = 4;

// ADDER Block:
localparam ADDER_INPA = 0;
localparam ADDER_INPB = 1;
localparam ADDER_INPC = 2;
localparam ADDER_INPD = 3;
localparam ADDER_SCALE = 4;

// COUNTER Block:
localparam COUNTER_DIR = 4;
localparam COUNTER_START = 5;
localparam COUNTER_STEP = 6;
localparam COUNTER_ENABLE = 0;
localparam COUNTER_ENABLE_DLY = 1;
localparam COUNTER_TRIG = 2;
localparam COUNTER_TRIG_DLY = 3;

// PGEN Block:
localparam PGEN_CYCLES = 3;
localparam PGEN_ENABLE = 0;
localparam PGEN_ENABLE_DLY = 6;
localparam PGEN_TRIG = 1;
localparam PGEN_TRIG_DLY = 7;
localparam PGEN_TABLE_ADDRESS = 4;
localparam PGEN_TABLE_LENGTH = 5;
localparam PGEN_TABLE_STATUS = 8;

// PCOMP Block:
localparam PCOMP_START = 2;
localparam PCOMP_STEP = 3;
localparam PCOMP_WIDTH = 4;
localparam PCOMP_PNUM = 5;
localparam PCOMP_RELATIVE = 6;
localparam PCOMP_DIR = 7;
localparam PCOMP_DELTAP = 8;
localparam PCOMP_USE_TABLE = 10;
localparam PCOMP_ENABLE = 0;
localparam PCOMP_ENABLE_DLY = 15;
localparam PCOMP_INP = 1;
localparam PCOMP_ERROR = 14;
localparam PCOMP_TABLE_ADDRESS = 11;
localparam PCOMP_TABLE_LENGTH = 12;
localparam PCOMP_TABLE_STATUS = 16;

// ADC Block:

// PCAP Block:
localparam PCAP_ENABLE = 0;
localparam PCAP_ENABLE_DLY = 5;
localparam PCAP_FRAME = 1;
localparam PCAP_FRAME_DLY = 6;
localparam PCAP_CAPTURE = 2;
localparam PCAP_CAPTURE_DLY = 7;
localparam PCAP_ERR_STATUS = 4;

// BITS Block:
localparam BITS_A = 0;
localparam BITS_B = 1;
localparam BITS_C = 2;
localparam BITS_D = 3;

// CLOCKS Block:
localparam CLOCKS_A_PERIOD = 0;
localparam CLOCKS_B_PERIOD = 1;
localparam CLOCKS_C_PERIOD = 2;
localparam CLOCKS_D_PERIOD = 3;

// POSITIONS Block:

// SLOW Block:
localparam SLOW_TEMP_PSU = 0;
localparam SLOW_TEMP_SFP = 1;
localparam SLOW_TEMP_ENC_L = 2;
localparam SLOW_TEMP_PICO = 3;
localparam SLOW_TEMP_ENC_R = 4;
localparam SLOW_ALIM_12V0 = 5;
localparam SLOW_PICO_5V0 = 6;
localparam SLOW_IO_5V0 = 7;
localparam SLOW_SFP_3V3 = 8;
localparam SLOW_FMC_15VN = 9;
localparam SLOW_FMC_15VP = 10;
localparam SLOW_ENC_24V = 11;
localparam SLOW_FMC_12V = 12;

// FMC Block:
localparam FMC_FMC_PRSNT = 0;
localparam FMC_LINK_UP = 1;
localparam FMC_ERROR_COUNT = 2;
localparam FMC_LA_P_ERROR = 3;
localparam FMC_LA_N_ERROR = 4;
localparam FMC_GTREFCLK = 5;
localparam FMC_FMC_CLK0 = 6;
localparam FMC_FMC_CLK1 = 7;
localparam FMC_SOFT_RESET = 8;
localparam FMC_EXT_CLK = 9;

// SFP Block:
localparam SFP_LINK1_UP = 0;
localparam SFP_ERROR1_COUNT = 1;
localparam SFP_LINK2_UP = 2;
localparam SFP_ERROR2_COUNT = 3;
localparam SFP_LINK3_UP = 4;
localparam SFP_ERROR3_COUNT = 5;
localparam SFP_SFP_CLK1 = 6;
localparam SFP_SFP_CLK2 = 7;
localparam SFP_SFP_CLK3 = 8;
localparam SFP_SOFT_RESET = 9;



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
localparam FMC_BASE = BASE + 4096 * FMC_CS;
localparam SFP_BASE = BASE + 4096 * SFP_CS;
