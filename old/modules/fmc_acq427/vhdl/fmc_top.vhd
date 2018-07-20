--------------------------------------------------------------------------------
--  PandA Motion Project - 2017,18
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Scott Robson (D-TACQ Solutions)
--------------------------------------------------------------------------------
--
--  Description : FMC ACQ427 module interface to D-TACQ ACQ427FMC Module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity fmc_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bitbus_i            : in  std_logic_vector(127 downto 0);
    posbus_i            : in  std32_array(31 downto 0);
    -- Generic Inputs to BitBus and PosBus from FMC and SFP
    fmc_inputs_o        : out std_logic_vector(15 downto 0);
    fmc_data_o          : out std32_array(15 downto 0);         -- 8 channels of 32-bit data
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- External Differential Clock (via front panel SMA)
    EXTCLK_P            : in    std_logic;
    EXTCLK_N            : in    std_logic;
    -- LA I/O
    FMC_PRSNT           : in    std_logic;
    FMC_LA_P            : inout std_logic_vector(33 downto 0);
    FMC_LA_N            : inout std_logic_vector(33 downto 0);
    FMC_CLK0_M2C_P      : inout std_logic;
    FMC_CLK0_M2C_N      : in    std_logic;
    FMC_CLK1_M2C_P      : in    std_logic;
    FMC_CLK1_M2C_N      : in    std_logic;
    -- GTX I/O
    TXP_OUT             : out   std_logic;
    TXN_OUT             : out   std_logic;
    RXP_IN              : in    std_logic;
    RXN_IN              : in    std_logic;
    GTREFCLK_P          : in    std_logic;
    GTREFCLK_N          : in    std_logic
);
end fmc_top;

architecture rtl of fmc_top is

---------------------------------------------------------------------------------------
-- FMC pin name translation signals.
---------------------------------------------------------------------------------------
signal p_ADC_CNV_A      : std_logic                     := '0';             --! ADC Convert Control A
signal p_ADC_CNV_B      : std_logic                     := '0';             --! ADC Convert Control B
signal p_ADC_SPI_CLK    : std_logic                     := '0';             --! ADC SPI Clock
signal p_ADC_SDO        : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data
signal p_FMC_EXT_CLK    : std_logic;                                        --! Sample Clock from ACQ420FMC
signal p_FMC_EXT_TRIG   : std_logic;                                        --! Trigger from ACQ420FMC
signal p_DAC_SPI_CLK    : std_logic                     := '0';             --! DAC SPI Clock
signal p_DAC_SDI        : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data In
signal p_DAC_SDO        : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data Out
signal p_DAC_SYNC_n     : std_logic                     := '0';             --! DAC SPI SYNC
signal p_DAC_LD_n       : std_logic                     := '0';             --! DAC Load
signal p_DAC_RST_n      : std_logic;                                        --! DAC Reset

-- Internal Names
signal ADC_CNV          : std_logic                     := '0';             --! ADC Convert Control
signal ADC_SPI_CLK      : std_logic                     := '0';             --! ADC SPI Clock
signal ADC_SDO          : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data
signal DAC_SPI_CLK      : std_logic                     := '0';             --! DAC SPI Clock
signal DAC_SDI          : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data In
signal DAC_SDO          : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data Out
signal DAC_SYNC_n       : std_logic                     := '0';             --! DAC SPI SYNC
signal DAC_LD_n         : std_logic                     := '0';             --! DAC Load
signal DAC_RST_n        : std_logic;                                        --! DAC Reset
signal FMC_EXT_CLK      : std_logic;                                        --! Sample Clock from ACQ420FMC
signal FMC_EXT_TRIG     : std_logic;                                        --! Trigger from ACQ420FMC
signal FMC_IO_BUS       : std_logic_vector(3 downto 0)  := (others => '0'); --! FMC IO Controls (CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR)

signal FMC_MODULE_ENABLE_n      : std_logic;                                --! FPGA Enable Outputs
signal MODULE_ENABLE            : std_logic_vector(31 downto 0);            --! FPGA Enable Outputs
signal ADC_CLK_SELECT           : std_logic_vector(31 downto 0);
signal ADC_CLKDIV               : std_logic_vector(31 downto 0);
signal ADC_FIFO_RESET           : std_logic_vector(31 downto 0);
signal ADC_FIFO_ENABLE          : std_logic_vector(31 downto 0);
signal ADC_RESET                : std_logic_vector(31 downto 0);
signal ADC_ENABLE               : std_logic_vector(31 downto 0);
signal DAC_CLKDIV               : std_logic_vector(31 downto 0);
signal DAC_FIFO_RESET           : std_logic_vector(31 downto 0);
signal DAC_FIFO_ENABLE          : std_logic_vector(31 downto 0);
signal DAC_RESET                : std_logic_vector(31 downto 0);
signal DAC_ENABLE               : std_logic_vector(31 downto 0);
signal CH01_DAC_DATA            : std_logic_vector(31 downto 0);
signal CH02_DAC_DATA            : std_logic_vector(31 downto 0);
signal CH03_DAC_DATA            : std_logic_vector(31 downto 0);
signal CH04_DAC_DATA            : std_logic_vector(31 downto 0);

---------------------------------------------------------------------------------------
-- ADC I/O Logic
---------------------------------------------------------------------------------------

signal clk_ADC_IOB          : std_logic;                                        --! ADC SPI Clk for IOBs

signal s_ADC_SPI_CLK        : std_logic;                                        --! ADC SPI Clock
signal s_ADC_SDO            : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data
signal s_ADC_SDO_IDELAY     : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data Idelay
signal s_ADC_SDO_d1         : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data
signal s_ADC_SDO_d2         : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data

signal s_ADC_SPI_CLK_STOP   : std_logic;                                        --! Stop the ADC SPI Clock

signal SPI_IDELAY_DATA      : std_logic_vector(4 downto 0);                     --! IDELAY Tap Delay Value
signal SPI_IDELAY_LD        : std_logic;                                        --! IDELAY Load Tap Delay Value

signal s_TRIG_DATA          : std_logic := '0';                                 --! External Trigger Data
signal s_CLOCK_DATA         : std_logic := '0';                                 --! External Clock Data

signal ADC_DATAOUT          : std_logic_vector(255 downto 0) := (others => '0');

---------------------------------------------------------------------------------------
-- DAC I/O Logic
---------------------------------------------------------------------------------------

signal clk_DAC_IOB          : std_logic;                                        --! DAC SPI Clk for IOBs

signal s_DAC_SPI_CLK        : std_logic := '0';                                 --! DAC SPI Clock
signal s_DAC_SDI            : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data In
signal s_DAC_SDO            : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data Out
signal s_DAC_SYNC_n         : std_logic                 := '0';                 --! DAC SPI SYNC
signal s_DAC_LD_n           : std_logic                 := '0';                 --! DAC Load

signal DAC_DATAIN           : std_logic_vector(127 downto 0) := (others => '0');

---------------------------------------------------------------------------------------
-- Signal Attributes
---------------------------------------------------------------------------------------
attribute mark_debug    : string;
attribute keep      : string;
attribute IOB           : string;


-- ADC Attributes
attribute keep      of ADC_SDO          : signal is "true";
attribute IOB       of s_ADC_SDO        : signal is "true";

attribute keep      of s_ADC_SPI_CLK    : signal is "true";
attribute IOB       of ADC_SPI_CLK      : signal is "true";

-- DAC Attributes
attribute keep      of s_DAC_SPI_CLK    : signal is "true";
attribute IOB       of DAC_SPI_CLK      : signal is "true";

attribute keep      of s_DAC_SDI        : signal is "true";
attribute IOB       of DAC_SDI          : signal is "true";

attribute keep      of DAC_SDO          : signal is "true";
attribute IOB       of s_DAC_SDO        : signal is "true";

attribute keep      of s_DAC_SYNC_n     : signal is "true";
attribute IOB       of DAC_SYNC_n       : signal is "true";

--------------------------------------------------------------------------------------
-- debug test using mark_debug
---------------------------------------------------------------------------------------
--attribute mark_debug of s_ADC_SDO       : signal is "true";

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

---------------------------------------------------------------------------------------
-- Translate the FMC pin names into ACQ427FMC names
---------------------------------------------------------------------------------------
-- ADC
---------------------------------------------------------------------------------------
-- Input Pins
p_FMC_EXT_CLK           <=  FMC_LA_P(0);
p_FMC_EXT_TRIG          <=  FMC_LA_P(12);
p_ADC_SDO(8)            <=  FMC_LA_P(20);
p_ADC_SDO(7)            <=  FMC_LA_P(21);
p_ADC_SDO(6)            <=  FMC_LA_P(22);
p_ADC_SDO(5)            <=  FMC_LA_P(23);
p_ADC_SDO(4)            <=  FMC_LA_P(16);
p_ADC_SDO(3)            <=  FMC_LA_P(17);
p_ADC_SDO(2)            <=  FMC_LA_P(18);
p_ADC_SDO(1)            <=  FMC_LA_P(19);

-- Output Pins
FMC_LA_P(14)            <=  p_ADC_CNV_A;
FMC_LA_P(15)            <=  p_ADC_CNV_B;
FMC_LA_P(13)            <=  p_ADC_SPI_CLK;

s_TRIG_DATA             <=  FMC_IO_BUS(1);
s_CLOCK_DATA            <=  FMC_IO_BUS(3);

-- DAC
---------------------------------------------------------------------------------------
-- Input Pins
p_DAC_SDO(1)        <= FMC_LA_P(8);
p_DAC_SDO(2)        <= FMC_LA_P(9);
p_DAC_SDO(3)        <= FMC_LA_P(10);
p_DAC_SDO(4)        <= FMC_LA_P(11);

-- Output Pins
FMC_CLK0_M2C_P      <= p_DAC_SPI_CLK;

FMC_LA_P(4)         <= p_DAC_SDI(1);
FMC_LA_P(5)         <= p_DAC_SDI(2);
FMC_LA_P(6)         <= p_DAC_SDI(3);
FMC_LA_P(7)         <= p_DAC_SDI(4);
FMC_LA_P(1)         <= p_DAC_SYNC_n;
FMC_LA_P(2)         <= p_DAC_LD_n;
FMC_LA_P(3)         <= p_DAC_RST_n;


---------------------------------------------------------------------------------------
-- IO Buffer Instantiation
---------------------------------------------------------------------------------------
-- ADC
---------------------------------------------------------------------------------------
cmp_FMC_ADC_TRIG:       IOBUF port map(IO => p_FMC_EXT_TRIG,    I => s_TRIG_DATA,       O => FMC_EXT_TRIG,      T => not FMC_IO_BUS(0));
cmp_FMC_ADC_CLK:        IOBUF port map(IO => p_FMC_EXT_CLK, I => s_CLOCK_DATA,      O => FMC_EXT_CLK,       T => not FMC_IO_BUS(2));

cmp_ADC_CNV_A:          IOBUF port map(IO => p_ADC_CNV_A,       I => ADC_CNV,           T => FMC_MODULE_ENABLE_n);
cmp_ADC_CNV_B:          IOBUF port map(IO => p_ADC_CNV_B,       I => ADC_CNV,           T => FMC_MODULE_ENABLE_n);

cmp_ADC_CLK:        OBUFT generic map (SLEW => "FAST") port map(O => p_ADC_SPI_CLK, I => ADC_SPI_CLK, T => FMC_MODULE_ENABLE_n);

gen_ADC_BUFS: for x in 1 to 8 generate
    cmp_ADC_SDO:        IBUF port map(I => p_ADC_SDO(x),        O => ADC_SDO(x));
end generate gen_ADC_BUFS ;

-- DAC
---------------------------------------------------------------------------------------
cmp_DAC_RST_n:          IOBUF port map(IO => p_DAC_RST_n,       I => DAC_RST_n,         T => FMC_MODULE_ENABLE_n);

cmp_DAC_SPI_CLK:        IOBUF port map(IO => p_DAC_SPI_CLK, I => DAC_SPI_CLK,       T => FMC_MODULE_ENABLE_n);
cmp_DAC_DAC_SYNC_n:     IOBUF port map(IO => p_DAC_SYNC_n,      I => DAC_SYNC_n,        T => FMC_MODULE_ENABLE_n);
cmp_DAC_DAC_LD_n:       IOBUF port map(IO => p_DAC_LD_n,        I => DAC_LD_n,          T => FMC_MODULE_ENABLE_n);

gen_DAC_BUFS: for x in 1 to 4 generate
    cmp_DAC_DAC_SDI:    IOBUF port map(IO => p_DAC_SDI(x),      I => DAC_SDI(x),        T => FMC_MODULE_ENABLE_n);
    cmp_DAC_SDO:        IOBUF port map(IO => p_DAC_SDO(x),      I => '0',               T => '1',               O => DAC_SDO(x));
end generate gen_DAC_BUFS ;


-- Unused IO
FMC_LA_P(33 downto 24)  <= (others => 'Z');
FMC_LA_N(33 downto 0)   <= (others => 'Z');

fmc_ctrl : entity work.fmc_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => bitbus_i,
    posbus_i            => posbus_i,

    MODULE_EN           => MODULE_ENABLE,
    ADC_CLK_SELECT      => ADC_CLK_SELECT,
    ADC_CLKDIV          => ADC_CLKDIV,
    ADC_FIFO_RESET      => ADC_FIFO_RESET,
    ADC_FIFO_ENABLE     => ADC_FIFO_ENABLE,
    ADC_RESET           => ADC_RESET,
    ADC_ENABLE          => ADC_ENABLE,
    DAC_CLKDIV          => DAC_CLKDIV,
    DAC_FIFO_RESET      => DAC_FIFO_RESET,
    DAC_FIFO_ENABLE     => DAC_FIFO_ENABLE,
    DAC_RESET           => DAC_RESET,
    DAC_ENABLE          => DAC_ENABLE,
    ch01_dac_data_o     => CH01_DAC_DATA,
    ch02_dac_data_o     => CH02_DAC_DATA,
    ch03_dac_data_o     => CH03_DAC_DATA,
    ch04_dac_data_o     => CH04_DAC_DATA,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data_o,
    read_ack_o          => open,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open
);

FMC_MODULE_ENABLE_n <= not MODULE_ENABLE(0);

THE_ACQ427FMC_ADC_INTERFACE : entity work.ACQ427FMC_ADC_INTERFACE
port map (
    clk_PANDA               =>  clk_i,                 -- 100 MHz Clock from ARM for ADC Timing

    EXT_CLOCK               =>  FMC_EXT_CLK,          -- External Clock Source
    FMC_IO_BUS              =>  FMC_IO_BUS,             -- FMC IO Controls (CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR)

    ADC_CLK_SELECT_REG      => ADC_CLK_SELECT,
    ADC_CLKDIV_REG          => ADC_CLKDIV,
    ADC_FIFO_RESET_REG      => ADC_FIFO_RESET,
    ADC_FIFO_ENABLE_REG     => ADC_FIFO_ENABLE,
    ADC_RESET_REG           => ADC_RESET,
    ADC_ENABLE_REG          => ADC_ENABLE,

    clk_ADC_IOB             =>  clk_ADC_IOB,                -- ADC SPI Clock domain for IOBs
    ADC_SDO                 =>  s_ADC_SDO,                  -- ADC SPI Data
    ADC_CNV                 =>  ADC_CNV,                    -- ADC Convert Control
    ADC_SPI_CLK             =>  s_ADC_SPI_CLK,              -- ADC SPI Clock
    --ADC_A0                    =>  ADC_A0,                 -- AD8251 Gain Setting Address Bit 0
    --ADC_A1                    =>  ADC_A1                  -- AD8251 Gain Setting Address Bit 1

    ADC_DATAOUT             =>  ADC_DATAOUT
    );

fmc_data_o(7) <= ADC_DATAOUT(31 downto 0);
fmc_data_o(6) <= ADC_DATAOUT(63 downto 32);
fmc_data_o(5) <= ADC_DATAOUT(95 downto 64);
fmc_data_o(4) <= ADC_DATAOUT(127 downto 96);
fmc_data_o(3) <= ADC_DATAOUT(159 downto 128);
fmc_data_o(2) <= ADC_DATAOUT(191 downto 160);
fmc_data_o(1) <= ADC_DATAOUT(223 downto 192);
fmc_data_o(0) <= ADC_DATAOUT(255 downto 224);


IOB_FF_PUSH_ADC: process(clk_ADC_IOB)
begin
if Rising_Edge(clk_ADC_IOB) then
    ADC_SPI_CLK     <= s_ADC_SPI_CLK;
    if s_ADC_SPI_CLK = '1' then                                             -- Only latch in on approaching rising edge
        s_ADC_SDO       <= ADC_SDO;
    end if;
end if;
end process IOB_FF_PUSH_ADC;


THE_ACQ427FMC_DAC_INTERFACE : entity work.ACQ427FMC_DAC_INTERFACE
port map (
    clk_PANDA               =>  clk_i,                 -- 125 MHz PandA Clock

    DAC_CLKDIV_REG          => DAC_CLKDIV,
    DAC_FIFO_RESET_REG      => DAC_FIFO_RESET,
    DAC_FIFO_ENABLE_REG     => DAC_FIFO_ENABLE,
    DAC_RESET_REG           => DAC_RESET,
    DAC_ENABLE_REG          => DAC_ENABLE,

    clk_DAC_IOB             =>  clk_DAC_IOB,            -- DAC SPI Clk for IOBs
    DAC_SPI_CLK             =>  s_DAC_SPI_CLK,          -- DAC SPI Clock
    DAC_SDI                 =>  s_DAC_SDI,              -- DAC SPI Data In
    DAC_SDO                 =>  s_DAC_SDO,              -- DAC SPI Data Out
    DAC_SYNC_n              =>  s_DAC_SYNC_n,           -- DAC SPI SYNC
    DAC_LD_n                =>  s_DAC_LD_n,             -- DAC Load
    DAC_RST_n               =>  DAC_RST_n,               -- DAC Reset

    DAC_DATAIN              =>  DAC_DATAIN
    );

DAC_DATAIN  <= CH01_DAC_DATA & CH02_DAC_DATA & CH03_DAC_DATA & CH04_DAC_DATA;

DAC_LD_n <= s_DAC_LD_n;     -- This is asynchronous so do not push onto an I/O Buffer


--! Push the SPI Signals onto IOB Flip Flips
IOB_FF_PUSH_DAC:    process(clk_DAC_IOB)
begin
if Rising_edge(clk_DAC_IOB) then
    DAC_SPI_CLK     <= s_DAC_SPI_CLK;
    DAC_SDI         <= s_DAC_SDI;
    DAC_SYNC_n      <= s_DAC_SYNC_n;

    s_DAC_SDO       <= DAC_SDO;

end if;
end process IOB_FF_PUSH_DAC;

end rtl;

