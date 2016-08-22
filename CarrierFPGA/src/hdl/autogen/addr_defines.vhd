library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package addr_defines is

-- Functional Address Space Chip Selects
constant REG_CS : natural := 0;
constant DRV_CS : natural := 1;
constant TTLIN_CS : natural := 3;
constant TTLOUT_CS : natural := 4;
constant LVDSIN_CS : natural := 5;
constant LVDSOUT_CS : natural := 6;
constant LUT_CS : natural := 7;
constant SRGATE_CS : natural := 8;
constant DIV_CS : natural := 9;
constant PULSE_CS : natural := 10;
constant SEQ_CS : natural := 11;
constant INENC_CS : natural := 12;
constant QDEC_CS : natural := 13;
constant OUTENC_CS : natural := 14;
constant POSENC_CS : natural := 15;
constant ADDER_CS : natural := 16;
constant COUNTER_CS : natural := 17;
constant PGEN_CS : natural := 18;
constant PCOMP_CS : natural := 19;
constant ADC_CS : natural := 20;
constant PCAP_CS : natural := 21;
constant BITS_CS : natural := 22;
constant CLOCKS_CS : natural := 23;
constant POSITIONS_CS : natural := 24;
constant SLOW_CS : natural := 25;
constant FMC_CS : natural := 26;
constant SFP_CS : natural := 27;

-- Block Register Address Space

-- REG Block:
constant REG_FPGA_VERSION : natural := 0;
constant REG_FPGA_BUILD : natural := 1;
constant REG_SLOW_VERSION : natural := 2;
constant REG_BIT_READ_RST : natural := 3;
constant REG_BIT_READ_VALUE : natural := 4;
constant REG_POS_READ_RST : natural := 5;
constant REG_POS_READ_VALUE : natural := 6;
constant REG_POS_READ_CHANGES : natural := 7;
constant REG_PCAP_START_WRITE : natural := 8;
constant REG_PCAP_WRITE : natural := 9;
constant REG_PCAP_FRAMING_MASK : natural := 10;
constant REG_PCAP_FRAMING_ENABLE : natural := 11;
constant REG_PCAP_FRAMING_MODE : natural := 12;
constant REG_PCAP_ARM : natural := 13;
constant REG_PCAP_DISARM : natural := 14;
constant REG_SLOW_REGISTER_STATUS : natural := 15;
constant REG_PCAP_BIT_DELAY_0 : natural := 28;
constant REG_PCAP_BIT_DELAY_1 : natural := 29;
constant REG_PCAP_BIT_DELAY_2 : natural := 30;
constant REG_PCAP_BIT_DELAY_3 : natural := 31;
constant REG_PCAP_DATA_DELAY_0 : natural := 32;
constant REG_PCAP_DATA_DELAY_1 : natural := 33;
constant REG_PCAP_DATA_DELAY_2 : natural := 34;
constant REG_PCAP_DATA_DELAY_3 : natural := 35;
constant REG_PCAP_DATA_DELAY_4 : natural := 36;
constant REG_PCAP_DATA_DELAY_5 : natural := 37;
constant REG_PCAP_DATA_DELAY_6 : natural := 38;
constant REG_PCAP_DATA_DELAY_7 : natural := 39;
constant REG_PCAP_DATA_DELAY_8 : natural := 40;
constant REG_PCAP_DATA_DELAY_9 : natural := 41;
constant REG_PCAP_DATA_DELAY_10 : natural := 42;
constant REG_PCAP_DATA_DELAY_11 : natural := 43;
constant REG_PCAP_DATA_DELAY_12 : natural := 44;
constant REG_PCAP_DATA_DELAY_13 : natural := 45;
constant REG_PCAP_DATA_DELAY_14 : natural := 46;
constant REG_PCAP_DATA_DELAY_15 : natural := 47;
constant REG_PCAP_DATA_DELAY_16 : natural := 48;
constant REG_PCAP_DATA_DELAY_17 : natural := 49;
constant REG_PCAP_DATA_DELAY_18 : natural := 50;
constant REG_PCAP_DATA_DELAY_19 : natural := 51;
constant REG_PCAP_DATA_DELAY_20 : natural := 52;
constant REG_PCAP_DATA_DELAY_21 : natural := 53;
constant REG_PCAP_DATA_DELAY_22 : natural := 54;
constant REG_PCAP_DATA_DELAY_23 : natural := 55;
constant REG_PCAP_DATA_DELAY_24 : natural := 56;
constant REG_PCAP_DATA_DELAY_25 : natural := 57;
constant REG_PCAP_DATA_DELAY_26 : natural := 58;
constant REG_PCAP_DATA_DELAY_27 : natural := 59;
constant REG_PCAP_DATA_DELAY_28 : natural := 60;
constant REG_PCAP_DATA_DELAY_29 : natural := 61;
constant REG_PCAP_DATA_DELAY_30 : natural := 62;
constant REG_PCAP_DATA_DELAY_31 : natural := 63;

-- DRV Block:
constant DRV_PCAP_DMA_RESET : natural := 0;
constant DRV_PCAP_DMA_START : natural := 1;
constant DRV_PCAP_DMA_ADDR : natural := 2;
constant DRV_PCAP_TIMEOUT : natural := 3;
constant DRV_PCAP_IRQ_STATUS : natural := 4;
constant DRV_PCAP_BLOCK_SIZE : natural := 6;

-- TTLIN Block:
constant TTLIN_TERM : natural := 0;

-- TTLOUT Block:
constant TTLOUT_VAL : natural := 0;
constant TTLOUT_VAL_DLY : natural := 1;

-- LVDSIN Block:

-- LVDSOUT Block:
constant LVDSOUT_VAL : natural := 0;
constant LVDSOUT_VAL_DLY : natural := 1;

-- LUT Block:
constant LUT_FUNC : natural := 5;
constant LUT_INPA : natural := 0;
constant LUT_INPA_DLY : natural := 6;
constant LUT_INPB : natural := 1;
constant LUT_INPB_DLY : natural := 7;
constant LUT_INPC : natural := 2;
constant LUT_INPC_DLY : natural := 8;
constant LUT_INPD : natural := 3;
constant LUT_INPD_DLY : natural := 9;
constant LUT_INPE : natural := 4;
constant LUT_INPE_DLY : natural := 10;

-- SRGATE Block:
constant SRGATE_SET_EDGE : natural := 2;
constant SRGATE_RST_EDGE : natural := 3;
constant SRGATE_FORCE_SET : natural := 4;
constant SRGATE_FORCE_RST : natural := 5;
constant SRGATE_SET : natural := 0;
constant SRGATE_SET_DLY : natural := 6;
constant SRGATE_RST : natural := 1;
constant SRGATE_RST_DLY : natural := 7;

-- DIV Block:
constant DIV_DIVISOR : natural := 2;
constant DIV_FIRST_PULSE : natural := 3;
constant DIV_INP : natural := 0;
constant DIV_INP_DLY : natural := 5;
constant DIV_ENABLE : natural := 1;
constant DIV_ENABLE_DLY : natural := 6;
constant DIV_COUNT : natural := 4;

-- PULSE Block:
constant PULSE_DELAY_L : natural := 3;
constant PULSE_DELAY_H : natural := 2;
constant PULSE_WIDTH_L : natural := 5;
constant PULSE_WIDTH_H : natural := 4;
constant PULSE_INP : natural := 0;
constant PULSE_INP_DLY : natural := 11;
constant PULSE_ENABLE : natural := 1;
constant PULSE_ENABLE_DLY : natural := 12;
constant PULSE_ERR_OVERFLOW : natural := 7;
constant PULSE_ERR_PERIOD : natural := 8;
constant PULSE_QUEUE : natural := 9;
constant PULSE_MISSED_CNT : natural := 10;

-- SEQ Block:
constant SEQ_PRESCALE : natural := 5;
constant SEQ_TABLE_CYCLE : natural := 8;
constant SEQ_ENABLE : natural := 0;
constant SEQ_ENABLE_DLY : natural := 16;
constant SEQ_INPA : natural := 1;
constant SEQ_INPA_DLY : natural := 17;
constant SEQ_INPB : natural := 2;
constant SEQ_INPB_DLY : natural := 18;
constant SEQ_INPC : natural := 3;
constant SEQ_INPC_DLY : natural := 19;
constant SEQ_INPD : natural := 4;
constant SEQ_INPD_DLY : natural := 20;
constant SEQ_CUR_FRAME : natural := 9;
constant SEQ_CUR_FCYCLE : natural := 10;
constant SEQ_CUR_TCYCLE : natural := 11;
constant SEQ_TABLE_START : natural := 13;
constant SEQ_TABLE_DATA : natural := 14;
constant SEQ_TABLE_LENGTH : natural := 15;

-- INENC Block:
constant INENC_PROTOCOL : natural := 0;
constant INENC_CLK_PERIOD : natural := 1;
constant INENC_FRAME_PERIOD : natural := 2;
constant INENC_BITS : natural := 3;
constant INENC_BITS_CRC : natural := 4;
constant INENC_SETP : natural := 5;
constant INENC_RST_ON_Z : natural := 6;
constant INENC_EXTENSION : natural := 7;
constant INENC_ERR_FRAME : natural := 8;
constant INENC_ERR_RESPONSE : natural := 9;
constant INENC_ENC_STATUS : natural := 10;
constant INENC_DCARD_MODE : natural := 11;

-- QDEC Block:
constant QDEC_RST_ON_Z : natural := 3;
constant QDEC_SETP : natural := 4;
constant QDEC_A : natural := 0;
constant QDEC_A_DLY : natural := 5;
constant QDEC_B : natural := 1;
constant QDEC_B_DLY : natural := 6;
constant QDEC_Z : natural := 2;
constant QDEC_Z_DLY : natural := 7;

-- OUTENC Block:
constant OUTENC_PROTOCOL : natural := 5;
constant OUTENC_BITS : natural := 6;
constant OUTENC_QPERIOD : natural := 7;
constant OUTENC_ENABLE : natural := 8;
constant OUTENC_ENABLE_DLY : natural := 10;
constant OUTENC_A : natural := 0;
constant OUTENC_A_DLY : natural := 11;
constant OUTENC_B : natural := 1;
constant OUTENC_B_DLY : natural := 12;
constant OUTENC_Z : natural := 2;
constant OUTENC_Z_DLY : natural := 13;
constant OUTENC_VAL : natural := 4;
constant OUTENC_CONN : natural := 3;
constant OUTENC_CONN_DLY : natural := 14;
constant OUTENC_QSTATE : natural := 9;

-- POSENC Block:
constant POSENC_INP : natural := 0;
constant POSENC_QPERIOD : natural := 1;
constant POSENC_ENABLE : natural := 3;
constant POSENC_ENABLE_DLY : natural := 5;
constant POSENC_PROTOCOL : natural := 2;
constant POSENC_QSTATE : natural := 4;

-- ADDER Block:
constant ADDER_INPA : natural := 0;
constant ADDER_INPB : natural := 1;
constant ADDER_INPC : natural := 2;
constant ADDER_INPD : natural := 3;
constant ADDER_SCALE : natural := 4;

-- COUNTER Block:
constant COUNTER_DIR : natural := 4;
constant COUNTER_START : natural := 5;
constant COUNTER_STEP : natural := 6;
constant COUNTER_ENABLE : natural := 0;
constant COUNTER_ENABLE_DLY : natural := 1;
constant COUNTER_TRIG : natural := 2;
constant COUNTER_TRIG_DLY : natural := 3;

-- PGEN Block:
constant PGEN_CYCLES : natural := 3;
constant PGEN_ENABLE : natural := 0;
constant PGEN_ENABLE_DLY : natural := 6;
constant PGEN_TRIG : natural := 1;
constant PGEN_TRIG_DLY : natural := 7;
constant PGEN_TABLE_ADDRESS : natural := 4;
constant PGEN_TABLE_LENGTH : natural := 5;
constant PGEN_TABLE_STATUS : natural := 8;

-- PCOMP Block:
constant PCOMP_START : natural := 2;
constant PCOMP_STEP : natural := 3;
constant PCOMP_WIDTH : natural := 4;
constant PCOMP_PNUM : natural := 5;
constant PCOMP_RELATIVE : natural := 6;
constant PCOMP_DIR : natural := 7;
constant PCOMP_DELTAP : natural := 8;
constant PCOMP_USE_TABLE : natural := 10;
constant PCOMP_ENABLE : natural := 0;
constant PCOMP_ENABLE_DLY : natural := 15;
constant PCOMP_INP : natural := 1;
constant PCOMP_ERROR : natural := 14;
constant PCOMP_TABLE_ADDRESS : natural := 11;
constant PCOMP_TABLE_LENGTH : natural := 12;
constant PCOMP_TABLE_STATUS : natural := 16;

-- ADC Block:

-- PCAP Block:
constant PCAP_ENABLE : natural := 0;
constant PCAP_ENABLE_DLY : natural := 5;
constant PCAP_FRAME : natural := 1;
constant PCAP_FRAME_DLY : natural := 6;
constant PCAP_CAPTURE : natural := 2;
constant PCAP_CAPTURE_DLY : natural := 7;
constant PCAP_ERR_STATUS : natural := 4;

-- BITS Block:
constant BITS_A : natural := 0;
constant BITS_B : natural := 1;
constant BITS_C : natural := 2;
constant BITS_D : natural := 3;

-- CLOCKS Block:
constant CLOCKS_A_PERIOD : natural := 0;
constant CLOCKS_B_PERIOD : natural := 1;
constant CLOCKS_C_PERIOD : natural := 2;
constant CLOCKS_D_PERIOD : natural := 3;

-- POSITIONS Block:

-- SLOW Block:
constant SLOW_TEMP_PSU : natural := 0;
constant SLOW_TEMP_SFP : natural := 1;
constant SLOW_TEMP_ENC_L : natural := 2;
constant SLOW_TEMP_PICO : natural := 3;
constant SLOW_TEMP_ENC_R : natural := 4;
constant SLOW_ALIM_12V0 : natural := 5;
constant SLOW_PICO_5V0 : natural := 6;
constant SLOW_IO_5V0 : natural := 7;
constant SLOW_SFP_3V3 : natural := 8;
constant SLOW_FMC_15VN : natural := 9;
constant SLOW_FMC_15VP : natural := 10;
constant SLOW_ENC_24V : natural := 11;
constant SLOW_FMC_12V : natural := 12;

-- FMC Block:
constant FMC_FMC_PRSNT : natural := 0;
constant FMC_OUT1 : natural := 1;
constant FMC_OUT1_DLY : natural := 9;
constant FMC_OUT2 : natural := 2;
constant FMC_OUT2_DLY : natural := 10;
constant FMC_OUT3 : natural := 3;
constant FMC_OUT3_DLY : natural := 11;
constant FMC_OUT4 : natural := 4;
constant FMC_OUT4_DLY : natural := 12;
constant FMC_OUT5 : natural := 5;
constant FMC_OUT5_DLY : natural := 13;
constant FMC_OUT6 : natural := 6;
constant FMC_OUT6_DLY : natural := 14;
constant FMC_OUT7 : natural := 7;
constant FMC_OUT7_DLY : natural := 15;
constant FMC_OUT8 : natural := 8;
constant FMC_OUT8_DLY : natural := 16;

-- SFP Block:
constant SFP_LINK1_UP : natural := 0;
constant SFP_ERROR1_COUNT : natural := 1;
constant SFP_LINK2_UP : natural := 2;
constant SFP_ERROR2_COUNT : natural := 3;
constant SFP_LINK3_UP : natural := 4;
constant SFP_ERROR3_COUNT : natural := 5;
constant SFP_SFP_CLK1 : natural := 6;
constant SFP_SFP_CLK2 : natural := 7;
constant SFP_SFP_CLK3 : natural := 8;
constant SFP_SOFT_RESET : natural := 9;



end addr_defines;

package body addr_defines is


end addr_defines;