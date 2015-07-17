library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.type_defines.all;

package addr_defines is

-- Memory Setup Parameters
constant MEM_CS_NUM : natural := 5;     -- Memory pages = 2**CSW
constant MEM_AW     : natural := 8;     -- 2**AW Words per page
constant BLK_AW     : natural := 4;     -- 2**AW Words per block

-- Functional Address Space Chip Selects
constant ENCIN_CS               : natural := 6;
constant ENCOUT_CS              : natural := 8;

-- Block Register Space
constant ENCIN_PROT_ADDR        : std_logic_vector := TO_STD_VECTOR(0, BLK_AW);
constant ENCIN_RATE_ADDR        : std_logic_vector := TO_STD_VECTOR(1, BLK_AW);
constant ENCIN_BITS_ADDR        : std_logic_vector := TO_STD_VECTOR(2, BLK_AW);
constant ENCIN_FRM_SRC_ADDR     : std_logic_vector := TO_STD_VECTOR(3, BLK_AW);
constant ENCIN_FRM_VAL_ADDR     : std_logic_vector := TO_STD_VECTOR(4, BLK_AW);
constant ENCIN_SETP_ADDR        : std_logic_vector := TO_STD_VECTOR(5, BLK_AW);


constant ENCOUT_PROT_ADDR       : std_logic_vector := TO_STD_VECTOR(0, BLK_AW);
constant ENCOUT_BITS_ADDR       : std_logic_vector := TO_STD_VECTOR(1, BLK_AW);
constant ENCOUT_FRC_QSTATE_ADDR : std_logic_vector := TO_STD_VECTOR(2, BLK_AW);
constant ENCOUT_QSTATE_ADDR     : std_logic_vector := TO_STD_VECTOR(3, BLK_AW);
constant ENCOUT_QPRESCALAR_ADDR : std_logic_vector := TO_STD_VECTOR(4, BLK_AW);


end addr_defines;


package body addr_defines is


end addr_defines;

