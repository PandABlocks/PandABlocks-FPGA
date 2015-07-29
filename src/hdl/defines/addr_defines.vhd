library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;

package addr_defines is

-- Memory Setup Parameters
constant MEM_CS_NUM             : natural := 5;     -- Memory pages = 2**CSW
constant MEM_AW                 : natural := 8;     -- 2**AW Words per page
constant BLK_AW                 : natural := 4;     -- 2**AW Words per block

-- Functional Address Space Chip Selects
constant DIGIO_CS               : natural := 0;
constant SEQ_CS                 : natural := 5;
constant ENCIN_CS               : natural := 6;
constant ENCOUT_CS              : natural := 8;
constant PCOMP_CS               : natural := 13;

-- Block Register Space
constant DIGOUT_VAL_ADDR        : std_logic_vector := TO_STD_VECTOR(0, BLK_AW);

constant ENCIN_PROT_ADDR        : std_logic_vector := TO_STD_VECTOR(0, BLK_AW);
constant ENCIN_RATE_ADDR        : std_logic_vector := TO_STD_VECTOR(1, BLK_AW);
constant ENCIN_BITS_ADDR        : std_logic_vector := TO_STD_VECTOR(2, BLK_AW);
constant ENCIN_FRM_SRC_ADDR     : std_logic_vector := TO_STD_VECTOR(3, BLK_AW);
constant ENCIN_FRM_VAL_ADDR     : std_logic_vector := TO_STD_VECTOR(4, BLK_AW);
constant ENCIN_SETP_ADDR        : std_logic_vector := TO_STD_VECTOR(5, BLK_AW);

constant ENCOUT_POSN_VAL_ADDR   : std_logic_vector := TO_STD_VECTOR(0, BLK_AW);
constant ENCOUT_PROT_ADDR       : std_logic_vector := TO_STD_VECTOR(1, BLK_AW);
constant ENCOUT_BITS_ADDR       : std_logic_vector := TO_STD_VECTOR(2, BLK_AW);
constant ENCOUT_FRC_QSTATE_ADDR : std_logic_vector := TO_STD_VECTOR(3, BLK_AW);
constant ENCOUT_QSTATE_ADDR     : std_logic_vector := TO_STD_VECTOR(4, BLK_AW);
constant ENCOUT_QPRESCALAR_ADDR : std_logic_vector := TO_STD_VECTOR(5, BLK_AW);

constant PCOMP_ENABLE_VAL_ADDR  : std_logic_vector := TO_STD_VECTOR(0, BLK_AW);
constant PCOMP_POSN_VAL_ADDR    : std_logic_vector := TO_STD_VECTOR(1, BLK_AW);
constant PCOMP_START_ADDR       : std_logic_vector := TO_STD_VECTOR(2, BLK_AW);
constant PCOMP_STEP_ADDR        : std_logic_vector := TO_STD_VECTOR(3, BLK_AW);
constant PCOMP_WIDTH_ADDR       : std_logic_vector := TO_STD_VECTOR(4, BLK_AW);
constant PCOMP_COUNT_ADDR       : std_logic_vector := TO_STD_VECTOR(5, BLK_AW);
constant PCOMP_RELATIVE_ADDR    : std_logic_vector := TO_STD_VECTOR(6, BLK_AW);
constant PCOMP_DIR_ADDR         : std_logic_vector := TO_STD_VECTOR(7, BLK_AW);
constant PCOMP_FLTR_DELTAT_ADDR : std_logic_vector := TO_STD_VECTOR(8, BLK_AW);
constant PCOMP_FLTR_THOLD_ADDR  : std_logic_vector := TO_STD_VECTOR(9, BLK_AW);

constant SEQ_ENABLE_VAL_ADDR    : std_logic_vector := TO_STD_VECTOR(0, BLK_AW);
constant SEQ_INP0_VAL_ADDR      : std_logic_vector := TO_STD_VECTOR(1, BLK_AW);
constant SEQ_INP1_VAL_ADDR      : std_logic_vector := TO_STD_VECTOR(2, BLK_AW);
constant SEQ_INP2_VAL_ADDR      : std_logic_vector := TO_STD_VECTOR(3, BLK_AW);
constant SEQ_INP3_VAL_ADDR      : std_logic_vector := TO_STD_VECTOR(4, BLK_AW);
constant SEQ_MEM_START_ADDR     : std_logic_vector := TO_STD_VECTOR(5, BLK_AW);
constant SEQ_MEM_WSTB_ADDR      : std_logic_vector := TO_STD_VECTOR(6, BLK_AW);
constant SEQ_CLK_PRESC_ADDR     : std_logic_vector := TO_STD_VECTOR(7, BLK_AW);
constant SEQ_TABLE_WORDS_ADDR   : std_logic_vector := TO_STD_VECTOR(8, BLK_AW);
constant SEQ_TABLE_REPEAT_ADDR  : std_logic_vector := TO_STD_VECTOR(9, BLK_AW);
constant SEQ_CUR_FRAME_ADDR     : std_logic_vector := TO_STD_VECTOR(10, BLK_AW);
constant SEQ_CUR_FCYCLE_ADDR    : std_logic_vector := TO_STD_VECTOR(11, BLK_AW);
constant SEQ_CUR_TCYCLE_ADDR    : std_logic_vector := TO_STD_VECTOR(12, BLK_AW);

end addr_defines;

package body addr_defines is


end addr_defines;

