library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.support.all;
use work.addr_defines.all;

package slow_defines_daq is

-- Number of Status Registers
constant REGS_NUM           : natural := 4;

--
-- WRITE ONLY Registers
--
constant WRITE_RESET        : natural := 0;
constant TTLIN1_TERM        : natural := 1;
constant TTLIN2_TERM        : natural := 2;
constant TTLIN3_TERM_unused : natural := 1;
constant TTLIN4_TERM_unused : natural := 2;
constant TTLIN5_TERM_unused : natural := 1;
constant TTLIN6_TERM_unused : natural := 2;
constant TTL_LEDS           : natural := 3;

--
-- READ ONLY Registers
--
constant SLOW_VERSION       : natural := 0;
constant TEMP_PSU           : natural := 1;
constant TEMP_SFP           : natural := 2;
constant TEMP_PICO          : natural := 3;
constant ALIM_12V0          : natural := 4;
constant PICO_5V0           : natural := 5;
constant IO_5V0             : natural := 6;
constant SFP_3V3            : natural := 7;
constant FMC_15VN           : natural := 8;
constant FMC_15VP           : natural := 9;
constant ENC_24V            : natural := 10;
constant FMC_12V            : natural := 11;

-- TTLIN TERM Address List
constant TTLTERM_ADDR_LIST  : page_array(TTLIN_NUM-1 downto 0) := (
                                std_logic_vector(to_unsigned(TTLIN2_TERM, PAGE_AW)),
                                std_logic_vector(to_unsigned(TTLIN1_TERM, PAGE_AW))
                            );

end slow_defines_daq;

package body slow_defines_daq is


end slow_defines_daq;
