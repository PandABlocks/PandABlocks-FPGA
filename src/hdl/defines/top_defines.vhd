library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;

package top_defines is

--------------------------------------------------------------------------
-- Enable Module Instantiations
constant DIV_INST               : boolean := true;
constant PULSE_INST             : boolean := true;
constant SEQ_INST               : boolean := true;
constant INENC_INST             : boolean := true;
constant OUTENC_INST            : boolean := true;
constant PCOMP_INST             : boolean := true;
constant PCAP_INST              : boolean := true;
--------------------------------------------------------------------------

--------------------------------------------------------------------------
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
--------------------------------------------------------------------------

-- Block instantiation numbers--------------------------------------------
constant TTLIN_NUM          : positive := 6;
constant TTLOUT_NUM         : positive := 10;
constant LVDSIN_NUM         : positive := 2;
constant LVDSOUT_NUM        : positive := 2;
constant LUT_NUM            : positive := 8;
constant SRGATE_NUM         : positive := 4;
constant DIV_NUM            : positive := 4;
constant PULSE_NUM          : positive := 4;

constant COUNTER_NUM        : positive := 8;

constant ENC_NUM            : positive := 4;
constant PCOMP_NUM          : positive := 4;
constant SEQ_NUM            : positive := 4;
constant BITS_NUM           : positive := 1;
--------------------------------------------------------------------------

-- Bit Bus Width, Multiplexer Select Width.
constant SBUSW              : positive := 128;
constant SBUSBW             : positive := 7;

-- Position Bus Width, Multiplexer Select Width.
constant PBUSW              : positive := 32;
constant PBUSBW             : positive := 5;

-- Extended Position Bus Width.
constant EBUSW              : positive := 12;

--
-- TYPEs :
--
type seq_t is
record
    repeats     : unsigned(31 downto 0);
    trig_mask   : std_logic_vector(3 downto 0);
    trig_cond   : std_logic_vector(3 downto 0);
    outp_ph1    : std_logic_vector(5 downto 0);
    outp_ph2    : std_logic_vector(5 downto 0);
    ph1_time    : unsigned(31 downto 0);
    ph2_time    : unsigned(31 downto 0);
end record;

type slow_packet is
record
    strobe      : std_logic;
    address     : std_logic_vector(PAGE_AW-1 downto 0);
    data        : std_logic_vector(31 downto 0);
end record;
type slow_packet_array is array(natural range <>) of slow_packet;

subtype iobuf_ctrl_t is std_logic_vector(2 downto 0);
type iobuf_ctrl_array is array(natural range <>) of iobuf_ctrl_t;

subtype encmode_t is std_logic_vector(2 downto 0);
type encmode_array is array(natural range <>) of encmode_t;

subtype seq_out_t is std_logic_vector(5 downto 0);
type seq_out_array is array(natural range <>) of seq_out_t;

subtype sysbus_t is std_logic_vector(SBUSW-1 downto 0);
subtype posbus_t is std32_array(PBUSW-1 downto 0);
subtype extbus_t is std32_array(EBUSW-1 downto 0);

-- System Bus Multiplexer Select array type
subtype sbus_muxsel_t is std_logic_vector(SBUSBW-1 downto 0);
type sbus_muxsel_array is array (natural range <>) of sbus_muxsel_t;

subtype pbus_muxsel_t is std_logic_vector(PBUSBW-1 downto 0);

--
-- FUNCTIONs :
--

-- Return selected System Bus bit
function SBIT(sbus : std_logic_vector; sel : sbus_muxsel_t) return std_logic;
function PFIELD(pbus : std32_array; sel : pbus_muxsel_t) return std_logic_vector;

end top_defines;

package body top_defines is

-- Return selected System Bus bit
function SBIT(sbus : std_logic_vector; sel : sbus_muxsel_t) return std_logic is
begin
    return sbus(to_integer(unsigned(sel)));
end SBIT;

-- Return selected Position Bus field
function PFIELD(pbus : std32_array; sel : pbus_muxsel_t) return std_logic_vector is
begin
    return pbus(to_integer(unsigned(sel)));
end PFIELD;

end top_defines;

