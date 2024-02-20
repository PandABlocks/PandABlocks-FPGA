library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines_gen;

package top_defines is

--------------------------------------------------------------------------
-- Memory Setup Parameters
-- Total of 128KByte memory is divided into 32 pages of 4K each.
-- Each page can address 16 design blocks
-- Each block can hold 64 DWORD registers

-- Number of total pages = 2**CSW
constant PAGE_NUM               : natural := 5;
-- Number of DWORDs per page = 2**PAGE_AW
constant PAGE_AW                : natural := 10;
-- Number of DWORDs per block = 2**BLK_AW
constant BLK_AW                 : natural := 6;
-- Number of total block's bit width
constant BLK_NUM                : natural := PAGE_AW - BLK_AW;
--------------------------------------------------------------------------

constant MOD_COUNT              : natural := 2**PAGE_NUM;
subtype MOD_RANGE               is natural range 0 to MOD_COUNT-1;

-- Read Addr to Ack delay
constant RD_ADDR2ACK            : std_logic_vector(4 downto 0) := "00010";

-- Block instantiation numbers--------------------------------------------
constant ENC_NUM                : natural := 4;
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- Aliasing for top_defines_gen.

alias BBUSW is top_defines_gen.BBUSW;
alias BBUSBW is top_defines_gen.BBUSBW;
alias PBUSW is top_defines_gen.PBUSW;
alias PBUSBW is top_defines_gen.PBUSBW;
alias EBUSW is top_defines_gen.EBUSW;
alias PCAP_STD_DEV_OPTION is top_defines_gen.PCAP_STD_DEV_OPTION;
alias FINE_DELAY_OPTION is top_defines_gen.FINE_DELAY_OPTION;
--------------------------------------------------------------------------

constant DCARD_MONITOR          : std_logic_vector(2 downto 0) := "011";

type t_mode_group is array (8 downto 0) of std_logic_vector(31 downto 0);
type t_mode is array (PBUSW-1 downto 0) of t_mode_group;
type t_ts is array (6 downto 0) of std_logic_vector(31 downto 0);
type t_bits is array (3 downto 0) of std_logic_vector(31 downto 0);

type t_mode_ts_bits is
record
    mode   : t_mode;
    ts     : t_ts;
    bits   : t_bits;
end record;

--
-- TYPEs :
--

-- FMC Block Record declarations

type FMC_input_interface is
  record
    EXTCLK          : std_logic;
    FMC_PRSNT       : std_logic;
    FMC_CLK1_M2C_P  : std_logic;
    FMC_CLK1_M2C_N  : std_logic;
    GTREFCLK        : std_logic;
    RXP_IN          : std_logic;
    RXN_IN          : std_logic;
    MAC_ADDR        : std_logic_vector(47 downto 0);
    MAC_ADDR_WS     : std_logic;
  end record FMC_input_interface;

type FMC_inout_interface is
  record
    FMC_LA_P        : std_logic_vector(33 downto 0);
    FMC_LA_N        : std_logic_vector(33 downto 0);
    FMC_CLK0_M2C_P  : std_logic;
    FMC_CLK0_M2C_N  : std_logic;
  end record FMC_inout_interface;

constant FMC_io_init : FMC_inout_interface := (FMC_LA_P => (others => 'Z'),
                                               FMC_LA_N => (others => 'Z'),
                                               FMC_CLK0_M2C_P => 'Z',
                                               FMC_CLK0_M2C_N => 'Z');

type FMC_output_interface is
  record
    TXP_OUT         : std_logic;
    TXN_OUT         : std_logic;
  end record FMC_output_interface;

constant FMC_o_init : FMC_output_interface := (TXP_OUT => 'Z',
                                               TXN_OUT => 'Z');

-- SFP Block Record declarations

type SFP_input_interface is
  record
    SFP_LOS     : std_logic;
    GTREFCLK    : std_logic;
    RXN_IN      : std_logic;
    RXP_IN      : std_logic;
    MAC_ADDR    : std_logic_vector(47 downto 0);
    MAC_ADDR_WS : std_logic;
    MGT_CLK_SEL : std_logic;
  end record SFP_input_interface;

type SFP_output_interface is
  record
    TXN_OUT     : std_logic;
    TXP_OUT     : std_logic;
    MGT_REC_CLK : std_logic;
    LINK_UP     : std_logic;
    TS_SEC      : std_logic_vector(31 downto 0);
    TS_TICKS    : std_logic_vector(31 downto 0);
  end record SFP_output_interface;

constant SFP_o_init : SFP_output_interface := (TXN_OUT => 'Z',
                                               TXP_OUT => 'Z',
                                               MGT_REC_CLK => '0',
                                               LINK_UP => '0',
                                               TS_SEC => (others => '0'),
                                               TS_TICKS => (others => '0')
);


type seq_t is
record
    repeats     : unsigned(15 downto 0);
    trigger     : unsigned(3 downto 0);
    out1        : std_logic_vector(5 downto 0);
    out2        : std_logic_vector(5 downto 0);
    position    : signed(31 downto 0);
    time1       : unsigned(31 downto 0);
    time2       : unsigned(31 downto 0);
end record;

type slow_packet is
record
    strobe      : std_logic;
    address     : std_logic_vector(PAGE_AW-1 downto 0);
    data        : std_logic_vector(31 downto 0);
end record;
type slow_packet_array is array(natural range <>) of slow_packet;

subtype std2_t is std_logic_vector(1 downto 0);
type std2_array is array(natural range <>) of std2_t;

subtype std3_t is std_logic_vector(2 downto 0);
type std3_array is array(natural range <>) of std3_t;

subtype std4_t is std_logic_vector(3 downto 0);
type std4_array is array(natural range <>) of std4_t;

subtype unsigned4_t is unsigned(3 downto 0);
type unsigned4_array is array(natural range <>) of unsigned4_t;

subtype std8_t is std_logic_vector(7 downto 0);
type std8_array is array(natural range <>) of std8_t;

subtype std16_t is std_logic_vector(15 downto 0);
type std16_array is array(natural range <>) of std16_t;

subtype std32_t is std_logic_vector(31 downto 0);
type std32_array is array(natural range <>) of std32_t;

subtype unsigned32_t is unsigned(31 downto 0);
type unsigned32_array is array(natural range <>) of unsigned32_t;

subtype std48_t is std_logic_vector(47 downto 0);
type std48_array is array(natural range <>) of std48_t;

subtype std64_t is std_logic_vector(63 downto 0);
type std64_array is array(natural range <>) of std64_t;

subtype page_t is std_logic_vector(PAGE_AW-1 downto 0);
type page_array is array(natural range <>) of page_t;

subtype seq_out_t is std_logic_vector(5 downto 0);
type seq_out_array is array(natural range <>) of seq_out_t;

subtype bit_bus_t is std_logic_vector(BBUSW-1 downto 0);
subtype pos_bus_t is std32_array(PBUSW-1 downto 0);
subtype extbus_t is std32_array(EBUSW-1 downto 0);

--
-- FUNCTIONs :
--

-- Return selected System Bus bit
function SBIT(sbus, sel : std_logic_vector)
    return std_logic;
function PFIELD(pbus : std32_array; sel : std_logic_vector)
    return std_logic_vector;
function compute_block_strobe(addr : std_logic_vector; index : natural)
    return std_logic;
function to_std_logic(cond : boolean)
    return std_logic;

--
-- Components
--
component ila_32x8K
port (
    clk             : in  std_logic;
    probe0          : in  std_logic_vector(31 downto 0)
);
end component;


end top_defines;

package body top_defines is

-- Return selected System Bus bit
function SBIT(sbus, sel : std_logic_vector)
    return std_logic is
begin
    return sbus(to_integer(unsigned(sel)));
end SBIT;

-- Return selected Position Bus field
function PFIELD(pbus : std32_array; sel : std_logic_vector)
    return std_logic_vector is
begin
    return pbus(to_integer(unsigned(sel)));
end PFIELD;


function compute_block_strobe(addr : std_logic_vector; index : natural)
    return std_logic is
begin
    if addr(PAGE_AW-1 downto BLK_AW) =
            std_logic_vector(to_unsigned(index, PAGE_AW-BLK_AW)) then
        return '1';
    else
        return '0';
    end if;
end compute_block_strobe;

function to_std_logic(cond : boolean) return std_logic is
begin
    if cond then
        return '1';
    else
        return '0';
    end if;
end function;

end top_defines;

