localparam TTL_CS                   = 0;
localparam LVDS_CS                  = 1;
localparam LUT_CS                   = 2;
localparam SRGATE_CS                = 3;
localparam DIV_CS                   = 4;
localparam PULSE_CS                 = 5;
localparam SEQ_CS                   = 6;
localparam INENC_CS                 = 7;
localparam QDEC_CS                  = 8;
localparam OUTENC_CS                = 9;
localparam POSENC                   = 10;
localparam CALC                     = 11;
localparam ADDER                    = 12;
localparam COUNTER_CS               = 13;
localparam PGEN                     = 14;
localparam PCOMP_CS                 = 15;
localparam PCAP_CS                  = 16;
localparam SLOW_CS                  = 27;
localparam CLOCKS_CS                = 28;
localparam BITS_CS                  = 29;
localparam POSITIONS_CS             = 30;
localparam REG_CS                   = 31;


// Panda Base Address
localparam BASE                     = 32'h43C0_0000;

localparam INENC_BASE               = BASE + 4096 * INENC_CS;
localparam PCOMP_BASE               = BASE + 4096 * PCOMP_CS;
localparam PCAP_BASE                = BASE + 4096 * PCAP_CS;
localparam SLOW_BASE                = BASE + 4096 * SLOW_CS;
localparam CLOCKS_BASE              = BASE + 4096 * CLOCKS_CS;

// Block Registers

localparam TTLOUT_VAL_ADDR          = 0;

localparam LVDSOUT_VAL_ADDR         = 0;

localparam LUT_INPA_VAL_ADDR        = 0;
localparam LUT_INPB_VAL_ADDR        = 1;
localparam LUT_INPC_VAL_ADDR        = 2;
localparam LUT_INPD_VAL_ADDR        = 3;
localparam LUT_INPE_VAL_ADDR        = 4;
localparam LUT_FUNC_ADDR            = 5;

localparam SRGATE_SET_VAL_ADDR      = 0;
localparam SRGATE_RST_VAL_ADDR      = 1;
localparam SRGATE_SET_EDGE_ADDR     = 2;
localparam SRGATE_RST_EDGE_ADDR     = 3;
localparam SRGATE_FORCE_SET_ADDR    = 4;
localparam SRGATE_FORCE_RST_ADDR    = 5;

localparam DIV_INP_VAL_ADDR         = 0;
localparam DIV_RST_VAL_ADDR         = 1;
localparam DIV_DIVISOR_ADDR         = 2;
localparam DIV_FIRST_PULSE_ADDR     = 3;
localparam DIV_COUNT_ADDR           = 4;
localparam DIV_FORCE_RST_ADDR       = 5;

localparam PULSE_INP_VAL_ADDR       = 0;
localparam PULSE_RST_VAL_ADDR       = 1;
localparam PULSE_DELAY_L_ADDR       = 2;
localparam PULSE_DELAY_H_ADDR       = 3;
localparam PULSE_WIDTH_L_ADDR       = 4;
localparam PULSE_WIDTH_H_ADDR       = 5;
localparam PULSE_FORCE_RST_ADDR     = 6;
localparam PULSE_ERR_OVERFLOW_ADDR  = 7;
localparam PULSE_ERR_PERIOD_ADDR    = 8;
localparam PULSE_QUEUE_ADDR         = 9;
localparam PULSE_MISSED_CNT_ADDR    = 10;

localparam SEQ_GATE_VAL_ADDR        = 0;
localparam SEQ_INPA_VAL_ADDR        = 1;
localparam SEQ_INPB_VAL_ADDR        = 2;
localparam SEQ_INPC_VAL_ADDR        = 3;
localparam SEQ_INPD_VAL_ADDR        = 4;
localparam SEQ_PRESCALE_ADDR        = 5;
localparam SEQ_SOFT_GATE_ADDR       = 6;
localparam SEQ_TABLE_LENGTH_ADDR    = 7;
localparam SEQ_TABLE_CYCLE_ADDR     = 8;
localparam SEQ_CUR_FRAME_ADDR       = 9;
localparam SEQ_CUR_FCYCLE_ADDR      = 10;
localparam SEQ_CUR_TCYCLE_ADDR      = 11;
localparam SEQ_TABLE_STROBES_ADDR   = 12;
localparam SEQ_TABLE_RST_ADDR       = 13;
localparam SEQ_TABLE_DATA_ADDR      = 14;

localparam INENC_PROTOCOL_ADDR      = 0;
localparam INENC_CLKRATE_ADDR       = 1;
localparam INENC_FRAMERATE_ADDR     = 2;
localparam INENC_BITS_ADDR          = 3;
localparam INENC_SETP_ADDR          = 4;
localparam INENC_RST_ON_Z_ADDR      = 5;

localparam OUTENC_A_VAL_ADDR        = 0;
localparam OUTENC_B_VAL_ADDR        = 1;
localparam OUTENC_Z_VAL_ADDR        = 2;
localparam OUTENC_CONN_VAL_ADDR     = 3;
localparam OUTENC_POSN_VAL_ADDR     = 4;
localparam OUTENC_PROTOCOL_ADDR     = 5;
localparam OUTENC_BITS_ADDR         = 6;
localparam OUTENC_QPRESCALAR_ADDR   = 7;
localparam OUTENC_FRC_QSTATE_ADDR   = 8;
localparam OUTENC_QSTATE_ADDR       = 9;

localparam COUNTER_ENABLE_VAL_ADDR  = 0;
localparam COUNTER_TRIGGER_VAL_ADDR = 1;
localparam COUNTER_DIR_ADDR         = 2;
localparam COUNTER_START_ADDR       = 3;
localparam COUNTER_STEP_ADDR        = 4;

localparam PCAP_ENABLE_VAL_ADDR     = 0;
localparam PCAP_TRIGGER_VAL_ADDR    = 1;
localparam PCAP_DMAADDR_ADDR        = 2;
localparam PCAP_SOFT_ARM_ADDR       = 3;
localparam PCAP_SOFT_DISARM_ADDR    = 4;
localparam PCAP_TIMEOUT_ADDR        = 6;
localparam PCAP_BITBUS_MASK_ADDR    = 7;
localparam PCAP_CAPTURE_MASK_ADDR   = 8;
localparam PCAP_EXT_MASK_ADDR       = 9;
localparam PCAP_FRAME_ENA_ADDR      = 10;
localparam PCAP_IRQ_STATUS_ADDR     = 11;
localparam PCAP_SMPL_COUNT_ADDR     = 12;
localparam PCAP_BLOCK_SIZE_ADDR     = 13;
localparam PCAP_TRIG_MISSES_ADDR    = 14;
localparam PCAP_ERR_STATUS_ADDR     = 15;

localparam PCOMP_ENABLE_VAL_ADDR    = 0;
localparam PCOMP_POSN_VAL_ADDR      = 1;
localparam PCOMP_START_ADDR         = 2;
localparam PCOMP_STEP_ADDR          = 3;
localparam PCOMP_WIDTH_ADDR         = 4;
localparam PCOMP_NUM_ADDR           = 5;
localparam PCOMP_RELATIVE_ADDR      = 6;
localparam PCOMP_DIR_ADDR           = 7;
localparam PCOMP_FLTR_DELTAT_ADDR   = 8;
localparam PCOMP_FLTR_THOLD_ADDR    = 9;
localparam PCOMP_LUT_ENABLE_ADDR    = 10;

localparam SLOW_INENC_CTRL_ADDR     = 0;
localparam SLOW_OUTENC_CTRL_ADDR    = 1;

