library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package addr_defines is

-- Functional Address Space Chip Selects
constant REG_CS : natural := 31;
constant DRV_CS : natural := 25;
constant TTLIN_CS : natural := 18;
constant TTLOUT_CS : natural := 0;
constant LVDSIN_CS : natural := 17;
constant LVDSOUT_CS : natural := 1;
constant LUT_CS : natural := 2;
constant SRGATE_CS : natural := 3;
constant DIV_CS : natural := 4;
constant PULSE_CS : natural := 5;
constant SEQ_CS : natural := 6;
constant INENC_CS : natural := 7;
constant QDEC_CS : natural := 8;
constant OUTENC_CS : natural := 9;
constant POSENC_CS : natural := 10;
constant ADDER_CS : natural := 12;
constant COUNTER_CS : natural := 13;
constant PGEN_CS : natural := 14;
constant PCOMP_CS : natural := 15;
constant ADC_CS : natural := 26;
constant PCAP_CS : natural := 16;
constant BITS_CS : natural := 28;
constant CLOCKS_CS : natural := 29;
constant POSITIONS_CS : natural := 30;
constant SLOW_CS : natural := 27;

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

-- DRV Block:
constant DRV_PCAP_DMAADDR : natural := 0;
constant DRV_PCAP_TIMEOUT : natural := 1;
constant DRV_PCAP_IRQ_STATUS : natural := 2;
constant DRV_PCAP_SMPL_COUNT : natural := 3;
constant DRV_PCAP_BLOCK_SIZE : natural := 4;

-- TTLIN Block:
constant TTLIN_TERM : natural := 0;

-- TTLOUT Block:
constant TTLOUT_VAL : natural := 0;

-- LVDSIN Block:

-- LVDSOUT Block:
constant LVDSOUT_VAL : natural := 0;

-- LUT Block:
constant LUT_FUNC : natural := 5;
constant LUT_INPA : natural := 0;
constant LUT_INPB : natural := 1;
constant LUT_INPC : natural := 2;
constant LUT_INPD : natural := 3;
constant LUT_INPE : natural := 4;

-- SRGATE Block:
constant SRGATE_SET_EDGE : natural := 2;
constant SRGATE_RST_EDGE : natural := 3;
constant SRGATE_FORCE_SET : natural := 4;
constant SRGATE_FORCE_RST : natural := 5;
constant SRGATE_SET : natural := 0;
constant SRGATE_RST : natural := 1;

-- DIV Block:
constant DIV_DIVISOR : natural := 2;
constant DIV_FIRST_PULSE : natural := 3;
constant DIV_FORCE_RST : natural := 5;
constant DIV_INP : natural := 0;
constant DIV_RST : natural := 1;
constant DIV_COUNT : natural := 4;

-- PULSE Block:
constant PULSE_DELAY_L : natural := 3;
constant PULSE_DELAY_H : natural := 2;
constant PULSE_WIDTH_L : natural := 5;
constant PULSE_WIDTH_H : natural := 4;
constant PULSE_FORCE_RST : natural := 6;
constant PULSE_INP : natural := 0;
constant PULSE_RST : natural := 1;
constant PULSE_ERR_OVERFLOW : natural := 7;
constant PULSE_ERR_PERIOD : natural := 8;
constant PULSE_QUEUE : natural := 9;
constant PULSE_MISSED_CNT : natural := 10;

-- SEQ Block:
constant SEQ_PRESCALE : natural := 5;
constant SEQ_SOFT_GATE : natural := 6;
constant SEQ_TABLE_CYCLE : natural := 8;
constant SEQ_GATE : natural := 0;
constant SEQ_INPA : natural := 1;
constant SEQ_INPB : natural := 2;
constant SEQ_INPC : natural := 3;
constant SEQ_INPD : natural := 4;
constant SEQ_CUR_FRAME : natural := 9;
constant SEQ_CUR_FCYCLE : natural := 10;
constant SEQ_CUR_TCYCLE : natural := 11;
constant SEQ_TABLE_STROBES : natural := 12;
constant SEQ_TABLE_START : natural := 13;
constant SEQ_TABLE_DATA : natural := 14;
constant SEQ_TABLE_LENGTH : natural := 15;

-- INENC Block:
constant INENC_PROTOCOL : natural := 0;
constant INENC_CLKRATE : natural := 1;
constant INENC_FRAMERATE : natural := 2;
constant INENC_BITS : natural := 3;
constant INENC_SETP : natural := 4;
constant INENC_RST_ON_Z : natural := 5;
constant INENC_EXTENSION : natural := 6;

-- QDEC Block:
constant QDEC_RST_ON_Z : natural := 3;
constant QDEC_SETP : natural := 4;
constant QDEC_A : natural := 0;
constant QDEC_B : natural := 1;
constant QDEC_Z : natural := 2;

-- OUTENC Block:
constant OUTENC_PROTOCOL : natural := 5;
constant OUTENC_BITS : natural := 6;
constant OUTENC_QPRESCALAR : natural := 7;
constant OUTENC_FORCE_QSTATE : natural := 8;
constant OUTENC_A : natural := 0;
constant OUTENC_B : natural := 1;
constant OUTENC_Z : natural := 2;
constant OUTENC_POSN : natural := 4;
constant OUTENC_CONN : natural := 3;
constant OUTENC_QSTATE : natural := 9;

-- POSENC Block:
constant POSENC_POSN : natural := 0;
constant POSENC_QPRESCALAR : natural := 1;
constant POSENC_MODE : natural := 2;
constant POSENC_FORCE_QSTATE : natural := 3;
constant POSENC_QSTATE : natural := 4;

-- ADDER Block:
constant ADDER_MASK : natural := 1;
constant ADDER_OUTSCALE : natural := 2;

-- COUNTER Block:
constant COUNTER_DIR : natural := 2;
constant COUNTER_START : natural := 3;
constant COUNTER_STEP : natural := 4;
constant COUNTER_ENABLE : natural := 0;
constant COUNTER_TRIGGER : natural := 1;

-- PGEN Block:
constant PGEN_SAMPLES : natural := 2;
constant PGEN_CYCLES : natural := 3;
constant PGEN_ENABLE : natural := 0;
constant PGEN_TRIGGER : natural := 1;
constant PGEN_TABLE_START : natural := 4;
constant PGEN_TABLE_DATA : natural := 5;

-- PCOMP Block:
constant PCOMP_START : natural := 2;
constant PCOMP_STEP : natural := 3;
constant PCOMP_WIDTH : natural := 4;
constant PCOMP_PNUM : natural := 5;
constant PCOMP_RELATIVE : natural := 6;
constant PCOMP_DIR : natural := 7;
constant PCOMP_FLTR_DELTAT : natural := 8;
constant PCOMP_FLTR_THOLD : natural := 9;
constant PCOMP_LUT_ENABLE : natural := 10;
constant PCOMP_ENABLE : natural := 0;
constant PCOMP_POSN : natural := 1;
constant PCOMP_TABLE_START : natural := 11;
constant PCOMP_TABLE_DATA : natural := 12;

-- ADC Block:
constant ADC_TRIGGER : natural := 0;
constant ADC_RST : natural := 1;

-- PCAP Block:
constant PCAP_ENABLE : natural := 0;
constant PCAP_FRAME : natural := 1;
constant PCAP_CAPTURE : natural := 2;
constant PCAP_MISSED_CAPTURES : natural := 3;
constant PCAP_ERR_STATUS : natural := 4;

-- BITS Block:
constant BITS_A_SET : natural := 0;
constant BITS_B_SET : natural := 1;
constant BITS_C_SET : natural := 2;
constant BITS_D_SET : natural := 3;

-- CLOCKS Block:
constant CLOCKS_A_PERIOD : natural := 0;
constant CLOCKS_B_PERIOD : natural := 1;
constant CLOCKS_C_PERIOD : natural := 2;
constant CLOCKS_D_PERIOD : natural := 3;

-- POSITIONS Block:

-- SLOW Block:
constant SLOW_FPGA_VERSION : natural := 0;
constant SLOW_ENC_CONN : natural := 1;


end addr_defines;

package body addr_defines is


end addr_defines;
