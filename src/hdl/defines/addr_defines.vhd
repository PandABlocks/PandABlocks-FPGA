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
constant TTLOUT_VAL         : natural := 0;

constant LVDSOUT_VAL        : natural := 0;

constant LUT_INPA           : natural := 0;
constant LUT_INPB           : natural := 1;
constant LUT_INPC           : natural := 2;
constant LUT_INPD           : natural := 3;
constant LUT_INPE           : natural := 4;
constant LUT_FUNC           : natural := 5;

constant SRGATE_SET         : natural := 0;
constant SRGATE_RST         : natural := 1;
constant SRGATE_SET_EDGE    : natural := 2;
constant SRGATE_RST_EDGE    : natural := 3;
constant SRGATE_FORCE_SET   : natural := 4;
constant SRGATE_FORCE_RST   : natural := 5;

constant DIV_INP            : natural := 0;
constant DIV_RST            : natural := 1;
constant DIV_DIVISOR        : natural := 2;
constant DIV_FIRST_PULSE    : natural := 3;
constant DIV_COUNT          : natural := 4;
constant DIV_FORCE_RST      : natural := 5;

constant PULSE_INP              : natural := 0;
constant PULSE_RST              : natural := 1;
constant PULSE_DELAY_L          : natural := 2;
constant PULSE_DELAY_H          : natural := 3;
constant PULSE_WIDTH_L          : natural := 4;
constant PULSE_WIDTH_H          : natural := 5;
constant PULSE_FORCE_RST        : natural := 6;
constant PULSE_ERR_OVERFLOW     : natural := 7;
constant PULSE_ERR_PERIOD       : natural := 8;
constant PULSE_QUEUE            : natural := 9;
constant PULSE_MISSED_CNT       : natural := 10;

constant SEQ_GATE               : natural := 0;
constant SEQ_INPA               : natural := 1;
constant SEQ_INPB               : natural := 2;
constant SEQ_INPC               : natural := 3;
constant SEQ_INPD               : natural := 4;
constant SEQ_PRESCALE           : natural := 5;
constant SEQ_SOFT_GATE          : natural := 6;
constant SEQ_TABLE_LENGTH       : natural := 7;
constant SEQ_TABLE_CYCLE        : natural := 8;
constant SEQ_CUR_FRAME          : natural := 9;
constant SEQ_CUR_FCYCLE         : natural := 10;
constant SEQ_CUR_TCYCLE         : natural := 11;
constant SEQ_TABLE_STROBES      : natural := 12;
constant SEQ_TABLE_RST          : natural := 13;
constant SEQ_TABLE_DATA         : natural := 14;

constant INENC_PROTOCOL    : natural := 0;
constant INENC_CLKRATE     : natural := 1;
constant INENC_FRAMERATE   : natural := 2;
constant INENC_BITS        : natural := 3;
constant INENC_SETP        : natural := 4;
constant INENC_RST_ON_Z    : natural := 5;

constant OUTENC_A      : natural := 0;
constant OUTENC_B      : natural := 1;
constant OUTENC_Z      : natural := 2;
constant OUTENC_CONN   : natural := 3;
constant OUTENC_POSN   : natural := 4;
constant OUTENC_PROTOCOL   : natural := 5;
constant OUTENC_BITS       : natural := 6;
constant OUTENC_QPRESCALAR : natural := 7;
constant OUTENC_FRC_QSTATE : natural := 8;
constant OUTENC_QSTATE     : natural := 9;

constant COUNTER_ENABLE         : natural := 0;
constant COUNTER_TRIGGER        : natural := 1;
constant COUNTER_DIR            : natural := 2;
constant COUNTER_START          : natural := 3;
constant COUNTER_STEP           : natural := 4;

constant PCAP_ENABLE            : natural := 0;
constant PCAP_FRAME             : natural := 1;
constant PCAP_CAPTURE           : natural := 2;
constant PCAP_MISSED_CAPTURES   : natural := 3;
constant PCAP_ERR_STATUS        : natural := 4;

constant PCOMP_ENABLE       : natural := 0;
constant PCOMP_POSN         : natural := 1;
constant PCOMP_START        : natural := 2;
constant PCOMP_STEP         : natural := 3;
constant PCOMP_WIDTH        : natural := 4;
constant PCOMP_NUMBER       : natural := 5;
constant PCOMP_RELATIVE     : natural := 6;
constant PCOMP_DIR          : natural := 7;
constant PCOMP_FLTR_DELTAT  : natural := 8;
constant PCOMP_FLTR_THOLD   : natural := 9;
constant PCOMP_LUT_ENABLE   : natural := 10;

constant CLOCKS_A_PERIOD        : natural := 0;
constant CLOCKS_B_PERIOD        : natural := 1;
constant CLOCKS_C_PERIOD        : natural := 2;
constant CLOCKS_D_PERIOD        : natural := 3;

constant BITS_A_SET             : natural := 0;
constant BITS_B_SET             : natural := 1;
constant BITS_C_SET             : natural := 2;
constant BITS_D_SET             : natural := 3;

constant SLOW_INENC_CTRL        : natural := 0;
constant SLOW_OUTENC_CTRL       : natural := 1;
constant SLOW_VERSION           : natural := 2;

constant REG_BIT_READ_RST       : natural := 0;
constant REG_BIT_READ_VALUE     : natural := 1;
constant REG_POS_READ_RST       : natural := 2;
constant REG_POS_READ_VALUE     : natural := 3;
constant REG_POS_READ_CHANGES   : natural := 4;
constant REG_PCAP_START_WRITE   : natural := 5;
constant REG_PCAP_WRITE         : natural := 6;
constant REG_PCAP_FRAMING_MASK  : natural := 7;
constant REG_PCAP_FRAMING_ENABLE: natural := 8;
constant REG_PCAP_FRAMING_MODE  : natural := 9;
constant REG_PCAP_ARM           : natural := 10;
constant REG_PCAP_DISARM        : natural := 11;

constant DRV_PCAP_DMAADDR       : natural := 0;
constant DRV_PCAP_BLOCK_SIZE    : natural := 1;
constant DRV_PCAP_TIMEOUT       : natural := 2;
constant DRV_PCAP_IRQ_STATUS    : natural := 3;
constant DRV_PCAP_SMPL_COUNT    : natural := 4;

end addr_defines;

package body addr_defines is


end addr_defines;

