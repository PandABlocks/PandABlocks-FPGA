library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;

package addr_defines is

-- Memory Setup Parameters
-- Total of 128KByte memory is divided into 32 pages of 4K each.
-- Each page can address 16 design blocks
-- Each block can hold 64 DWORD registers

-- Number of total pages = 2**CSW
constant PAGE_NUM               : natural := 5;
-- Number of DWORDs per page = 2**PAGE_AW
constant PAGE_AW                : natural := 10;
-- Number of DWORS per block = 2**BLK_AW
constant BLK_AW                 : natural := 6;

-- Functional Address Space Chip Selects
constant TTL_CS                 : natural := 0;
constant LVDS_CS                : natural := 1;
constant LUT_CS                 : natural := 2;
constant SRGATE_CS              : natural := 3;
constant DIV_CS                 : natural := 4;
constant PULSE_CS               : natural := 5;
constant SEQ_CS                 : natural := 6;
constant INENC_CS               : natural := 7;
constant QDEC_CS                : natural := 8;
constant OUTENC_CS              : natural := 9;
constant POSENC                 : natural := 10;
constant CALC                   : natural := 11;
constant ADDER                  : natural := 12;
constant COUNTER_CS             : natural := 13;
constant PGEN                   : natural := 14;
constant PCOMP_CS               : natural := 15;
constant PCAP_CS                : natural := 16;
constant SLOW_CS                : natural := 26;
constant CLOCKS_CS              : natural := 27;
constant BITS_CS                : natural := 28;
constant POSITIONS_CS           : natural := 29;
constant DRV_CS                 : natural := 30;
constant REG_CS                 : natural := 31;


--
-- LOGIC Block Register Address Space
--
constant TTLOUT_VAL_ADDR        : std_logic_vector := TO_SVECTOR(0, BLK_AW);

constant LVDSOUT_VAL_ADDR       : std_logic_vector := TO_SVECTOR(0, BLK_AW);

constant LUT_INPA_VAL_ADDR      : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant LUT_INPB_VAL_ADDR      : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant LUT_INPC_VAL_ADDR      : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant LUT_INPD_VAL_ADDR      : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant LUT_INPE_VAL_ADDR      : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant LUT_FUNC_ADDR          : std_logic_vector := TO_SVECTOR(5, BLK_AW);

constant SRGATE_SET_VAL_ADDR    : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant SRGATE_RST_VAL_ADDR    : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant SRGATE_SET_EDGE_ADDR   : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant SRGATE_RST_EDGE_ADDR   : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant SRGATE_FORCE_SET_ADDR  : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant SRGATE_FORCE_RST_ADDR  : std_logic_vector := TO_SVECTOR(5, BLK_AW);

constant DIV_INP_VAL_ADDR       : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant DIV_RST_VAL_ADDR       : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant DIV_DIVISOR_ADDR       : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant DIV_FIRST_PULSE_ADDR   : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant DIV_COUNT_ADDR         : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant DIV_FORCE_RST_ADDR     : std_logic_vector := TO_SVECTOR(5, BLK_AW);

constant PULSE_INP_VAL_ADDR     : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant PULSE_RST_VAL_ADDR     : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant PULSE_DELAY_L_ADDR     : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant PULSE_DELAY_H_ADDR     : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant PULSE_WIDTH_L_ADDR     : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant PULSE_WIDTH_H_ADDR     : std_logic_vector := TO_SVECTOR(5, BLK_AW);
constant PULSE_FORCE_RST_ADDR   : std_logic_vector := TO_SVECTOR(6, BLK_AW);
constant PULSE_ERR_OVERFLOW_ADDR: std_logic_vector := TO_SVECTOR(7, BLK_AW);
constant PULSE_ERR_PERIOD_ADDR  : std_logic_vector := TO_SVECTOR(8, BLK_AW);
constant PULSE_QUEUE_ADDR       : std_logic_vector := TO_SVECTOR(9, BLK_AW);
constant PULSE_MISSED_CNT_ADDR  : std_logic_vector := TO_SVECTOR(10, BLK_AW);

constant SEQ_GATE_VAL_ADDR      : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant SEQ_INPA_VAL_ADDR      : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant SEQ_INPB_VAL_ADDR      : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant SEQ_INPC_VAL_ADDR      : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant SEQ_INPD_VAL_ADDR      : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant SEQ_PRESCALE_ADDR      : std_logic_vector := TO_SVECTOR(5, BLK_AW);
constant SEQ_SOFT_GATE_ADDR     : std_logic_vector := TO_SVECTOR(6, BLK_AW);
constant SEQ_TABLE_LENGTH_ADDR  : std_logic_vector := TO_SVECTOR(7, BLK_AW);
constant SEQ_TABLE_CYCLE_ADDR   : std_logic_vector := TO_SVECTOR(8, BLK_AW);
constant SEQ_CUR_FRAME_ADDR     : std_logic_vector := TO_SVECTOR(9, BLK_AW);
constant SEQ_CUR_FCYCLE_ADDR    : std_logic_vector := TO_SVECTOR(10, BLK_AW);
constant SEQ_CUR_TCYCLE_ADDR    : std_logic_vector := TO_SVECTOR(11, BLK_AW);
constant SEQ_TABLE_STROBES_ADDR : std_logic_vector := TO_SVECTOR(12, BLK_AW);
constant SEQ_TABLE_RST_ADDR     : std_logic_vector := TO_SVECTOR(13, BLK_AW);
constant SEQ_TABLE_DATA_ADDR    : std_logic_vector := TO_SVECTOR(14, BLK_AW);

constant INENC_PROTOCOL_ADDR    : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant INENC_CLKRATE_ADDR     : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant INENC_FRAMERATE_ADDR   : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant INENC_BITS_ADDR        : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant INENC_SETP_ADDR        : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant INENC_RST_ON_Z_ADDR    : std_logic_vector := TO_SVECTOR(5, BLK_AW);

constant OUTENC_A_VAL_ADDR      : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant OUTENC_B_VAL_ADDR      : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant OUTENC_Z_VAL_ADDR      : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant OUTENC_CONN_VAL_ADDR   : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant OUTENC_POSN_VAL_ADDR   : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant OUTENC_PROTOCOL_ADDR   : std_logic_vector := TO_SVECTOR(5, BLK_AW);
constant OUTENC_BITS_ADDR       : std_logic_vector := TO_SVECTOR(6, BLK_AW);
constant OUTENC_QPRESCALAR_ADDR : std_logic_vector := TO_SVECTOR(7, BLK_AW);
constant OUTENC_FRC_QSTATE_ADDR : std_logic_vector := TO_SVECTOR(8, BLK_AW);
constant OUTENC_QSTATE_ADDR     : std_logic_vector := TO_SVECTOR(9, BLK_AW);

constant COUNTER_ENABLE         : std_logic_vector  := TO_SVECTOR(0, BLK_AW);
constant COUNTER_TRIGGER        : std_logic_vector  := TO_SVECTOR(1, BLK_AW);
constant COUNTER_DIR            : std_logic_vector  := TO_SVECTOR(2, BLK_AW);
constant COUNTER_START          : std_logic_vector  := TO_SVECTOR(3, BLK_AW);
constant COUNTER_STEP           : std_logic_vector  := TO_SVECTOR(4, BLK_AW);

constant PCAP_ENABLE            : std_logic_vector := TO_SVECTOR(0, PAGE_AW);
constant PCAP_FRAME             : std_logic_vector := TO_SVECTOR(1, PAGE_AW);
constant PCAP_CAPTURE           : std_logic_vector := TO_SVECTOR(2, PAGE_AW);
constant PCAP_MISSED_CAPTURES   : std_logic_vector := TO_SVECTOR(3, PAGE_AW);
constant PCAP_ERR_STATUS        : std_logic_vector := TO_SVECTOR(4, PAGE_AW);

constant PCOMP_ENABLE_VAL_ADDR  : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant PCOMP_POSN_VAL_ADDR    : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant PCOMP_START_ADDR       : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant PCOMP_STEP_ADDR        : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant PCOMP_WIDTH_ADDR       : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant PCOMP_NUM_ADDR         : std_logic_vector := TO_SVECTOR(5, BLK_AW);
constant PCOMP_RELATIVE_ADDR    : std_logic_vector := TO_SVECTOR(6, BLK_AW);
constant PCOMP_DIR_ADDR         : std_logic_vector := TO_SVECTOR(7, BLK_AW);
constant PCOMP_FLTR_DELTAT_ADDR : std_logic_vector := TO_SVECTOR(8, BLK_AW);
constant PCOMP_FLTR_THOLD_ADDR  : std_logic_vector := TO_SVECTOR(9, BLK_AW);
constant PCOMP_LUT_ENABLE_ADDR  : std_logic_vector := TO_SVECTOR(10, BLK_AW);

constant SLOW_INENC_CTRL_ADDR   : std_logic_vector := TO_SVECTOR(0, PAGE_AW);
constant SLOW_OUTENC_CTRL_ADDR  : std_logic_vector := TO_SVECTOR(1, PAGE_AW);
constant SLOW_VERSION_ADDR      : std_logic_vector := TO_SVECTOR(2, PAGE_AW);

constant REG_BIT_READ_RST       : std_logic_vector := TO_SVECTOR(0, PAGE_AW);
constant REG_BIT_READ_VALUE     : std_logic_vector := TO_SVECTOR(1, PAGE_AW);
constant REG_POS_READ_RST       : std_logic_vector := TO_SVECTOR(2, PAGE_AW);
constant REG_POS_READ_VALUE     : std_logic_vector := TO_SVECTOR(3, PAGE_AW);
constant REG_POS_READ_CHANGES   : std_logic_vector := TO_SVECTOR(4, PAGE_AW);
constant REG_PCAP_START_WRITE   : std_logic_vector := TO_SVECTOR(5, PAGE_AW);
constant REG_PCAP_WRITE         : std_logic_vector := TO_SVECTOR(6, PAGE_AW);
constant REG_PCAP_FRAMING_MASK  : std_logic_vector := TO_SVECTOR(7, PAGE_AW);
constant REG_PCAP_FRAMING_ENABLE: std_logic_vector := TO_SVECTOR(8, PAGE_AW);
constant REG_PCAP_ARM           : std_logic_vector := TO_SVECTOR(9, PAGE_AW);
constant REG_PCAP_DISARM        : std_logic_vector := TO_SVECTOR(10,PAGE_AW);

constant DRV_PCAP_DMAADDR       : std_logic_vector := TO_SVECTOR(0, PAGE_AW);
constant DRV_PCAP_BLOCK_SIZE    : std_logic_vector := TO_SVECTOR(1, PAGE_AW);
constant DRV_PCAP_TIMEOUT       : std_logic_vector := TO_SVECTOR(2, PAGE_AW);
constant DRV_PCAP_IRQ_STATUS    : std_logic_vector := TO_SVECTOR(3, PAGE_AW);
constant DRV_PCAP_SMPL_COUNT    : std_logic_vector := TO_SVECTOR(4, PAGE_AW);

--
-- TOP Block Register Address Space
--
type tCLOCKS is
record
    CLOCKA_DIV      : natural;
    CLOCKB_DIV      : natural;
    CLOCKC_DIV      : natural;
    CLOCKD_DIV      : natural;
end record;

constant CLOCKS     : tCLOCKS := (0,1,2,3);

type tBITS is
record
    SOFTA_SET       : natural;
    SOFTB_SET       : natural;
    SOFTC_SET       : natural;
    SOFTD_SET       : natural;
end record;

constant BITS     : tBITS := (0,1,2,3);


end addr_defines;

package body addr_defines is


end addr_defines;

