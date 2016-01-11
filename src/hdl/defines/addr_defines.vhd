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
constant COUNTER_CS             : natural := 13;
constant PCAP_CS                : natural := 17;
constant CLOCKS_CS              : natural := 28;
constant BITS_CS                : natural := 29;
constant POSITIONS_CS           : natural := 30;
constant REG_CS                 : natural := 31;

--????
constant ENCIN_CS               : natural := 7;
constant ENCOUT_CS              : natural := 8;
constant PCOMP_CS               : natural := 13;
--????

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
constant SRGATE_FORCE_RESET_ADDR: std_logic_vector := TO_SVECTOR(5, BLK_AW);

constant DIV_INP_VAL_ADDR       : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant DIV_RST_VAL_ADDR       : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant DIV_FIRST_PULSE_ADDR   : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant DIV_DIVISOR_ADDR       : std_logic_vector := TO_SVECTOR(3, BLK_AW);
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
constant SEQ_TABLE_REPEAT_ADDR  : std_logic_vector := TO_SVECTOR(7, BLK_AW);
constant SEQ_TABLE_LENGTH_ADDR  : std_logic_vector := TO_SVECTOR(8, BLK_AW);
constant SEQ_TABLE_RST_ADDR     : std_logic_vector := TO_SVECTOR(9, BLK_AW);
constant SEQ_TABLE_DATA_ADDR    : std_logic_vector := TO_SVECTOR(10, BLK_AW);
constant SEQ_CUR_FRAME_ADDR     : std_logic_vector := TO_SVECTOR(11, BLK_AW);
constant SEQ_CUR_FCYCLE_ADDR    : std_logic_vector := TO_SVECTOR(12, BLK_AW);
constant SEQ_CUR_TCYCLE_ADDR    : std_logic_vector := TO_SVECTOR(13, BLK_AW);
constant SEQ_CUR_STATE_ADDR     : std_logic_vector := TO_SVECTOR(14, BLK_AW);

constant COUNTER_ENABLE_VAL_ADDR: std_logic_vector  := TO_SVECTOR(0, BLK_AW);
constant COUNTER_TRIGGER_VAL_ADDR: std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant COUNTER_DIR_ADDR       : std_logic_vector  := TO_SVECTOR(2, BLK_AW);
constant COUNTER_START_ADDR     : std_logic_vector  := TO_SVECTOR(3, BLK_AW);
constant COUNTER_STEP_ADDR      : std_logic_vector  := TO_SVECTOR(4, BLK_AW);

constant PCAP_ENABLE_VAL_ADDR   : std_logic_vector := TO_SVECTOR(0, PAGE_AW);
constant PCAP_TRIGGER_VAL_ADDR  : std_logic_vector := TO_SVECTOR(1, PAGE_AW);
constant PCAP_DMAADDR_ADDR      : std_logic_vector := TO_SVECTOR(2, PAGE_AW);
constant PCAP_SOFT_ARM_ADDR     : std_logic_vector := TO_SVECTOR(3, PAGE_AW);
constant PCAP_SOFT_DISARM_ADDR  : std_logic_vector := TO_SVECTOR(4, PAGE_AW);
constant PCAP_TIMEOUT_ADDR      : std_logic_vector := TO_SVECTOR(6, PAGE_AW);
constant PCAP_BITBUS_MASK_ADDR  : std_logic_vector := TO_SVECTOR(7, PAGE_AW);
constant PCAP_CAPTURE_MASK_ADDR : std_logic_vector := TO_SVECTOR(8, PAGE_AW);
constant PCAP_EXT_MASK_ADDR     : std_logic_vector := TO_SVECTOR(9,  PAGE_AW);
constant PCAP_FRAME_ENA_ADDR    : std_logic_vector := TO_SVECTOR(10, PAGE_AW);
constant PCAP_IRQ_STATUS_ADDR   : std_logic_vector := TO_SVECTOR(11, PAGE_AW);
constant PCAP_SMPL_COUNT_ADDR   : std_logic_vector := TO_SVECTOR(12, PAGE_AW);
constant PCAP_BLOCK_SIZE_ADDR   : std_logic_vector := TO_SVECTOR(13, PAGE_AW);
constant PCAP_TRIG_MISSES_ADDR  : std_logic_vector := TO_SVECTOR(14, PAGE_AW);
constant PCAP_ERR_STATUS_ADDR   : std_logic_vector := TO_SVECTOR(15, PAGE_AW);



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


constant REG_BIT_READ_RESET_ADDR: std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant REG_BIT_READ_VALUE_ADDR: std_logic_vector := TO_SVECTOR(1, BLK_AW);

--
-- ENCODER Block Register Address Space
--
constant ENCIN_PROT_ADDR        : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant ENCIN_RATE_ADDR        : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant ENCIN_BITS_ADDR        : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant ENCIN_FRM_SRC_ADDR     : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant ENCIN_FRM_VAL_ADDR     : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant ENCIN_SETP_ADDR        : std_logic_vector := TO_SVECTOR(5, BLK_AW);

constant ENCOUT_POSN_VAL_ADDR   : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant ENCOUT_PROT_ADDR       : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant ENCOUT_BITS_ADDR       : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant ENCOUT_FRC_QSTATE_ADDR : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant ENCOUT_QSTATE_ADDR     : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant ENCOUT_QPRESCALAR_ADDR : std_logic_vector := TO_SVECTOR(5, BLK_AW);

constant PCOMP_ENABLE_VAL_ADDR  : std_logic_vector := TO_SVECTOR(0, BLK_AW);
constant PCOMP_POSN_VAL_ADDR    : std_logic_vector := TO_SVECTOR(1, BLK_AW);
constant PCOMP_START_ADDR       : std_logic_vector := TO_SVECTOR(2, BLK_AW);
constant PCOMP_STEP_ADDR        : std_logic_vector := TO_SVECTOR(3, BLK_AW);
constant PCOMP_WIDTH_ADDR       : std_logic_vector := TO_SVECTOR(4, BLK_AW);
constant PCOMP_COUNT_ADDR       : std_logic_vector := TO_SVECTOR(5, BLK_AW);
constant PCOMP_RELATIVE_ADDR    : std_logic_vector := TO_SVECTOR(6, BLK_AW);
constant PCOMP_DIR_ADDR         : std_logic_vector := TO_SVECTOR(7, BLK_AW);
constant PCOMP_FLTR_DELTAT_ADDR : std_logic_vector := TO_SVECTOR(8, BLK_AW);
constant PCOMP_FLTR_THOLD_ADDR  : std_logic_vector := TO_SVECTOR(9, BLK_AW);

end addr_defines;

package body addr_defines is


end addr_defines;

