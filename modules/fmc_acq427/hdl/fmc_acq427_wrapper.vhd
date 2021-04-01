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

entity fmc_acq427_wrapper is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Outputs to PosBus from FMC
    in_val1_o               : out std32_array(0 downto 0);
    in_val2_o               : out std32_array(0 downto 0);
    in_val3_o               : out std32_array(0 downto 0);
    in_val4_o               : out std32_array(0 downto 0);
    in_val5_o               : out std32_array(0 downto 0);
    in_val6_o               : out std32_array(0 downto 0);
    in_val7_o               : out std32_array(0 downto 0);
    in_val8_o               : out std32_array(0 downto 0);
    -- Outputs to BitBus from FMC
    in_ttl_o               : out std_logic_vector(0 downto 0);
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic := '1';
    FMC_io              : inout fmc_inout_interface
);
end fmc_acq427_wrapper;

architecture rtl of fmc_acq427_wrapper is

---------------------------------------------------------------------------------------
-- FMC pin name translation signals.
---------------------------------------------------------------------------------------
signal p_ADC_CNV_A          : std_logic                     := '0';             --! ADC Convert Control A
signal p_ADC_CNV_B          : std_logic                     := '0';             --! ADC Convert Control B
signal p_ADC_SPI_CLK        : std_logic                     := '0';             --! ADC SPI Clock
signal p_ADC_SDO            : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data
signal p_DAC_SPI_CLK        : std_logic                     := '0';             --! DAC SPI Clock
signal p_DAC_SDI            : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data In
signal p_DAC_SDO            : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data Out
signal p_DAC_SYNC_n         : std_logic                     := '0';             --! DAC SPI SYNC
signal p_DAC_LD_n           : std_logic                     := '0';             --! DAC Load
signal p_DAC_RST_n          : std_logic;                                        --! DAC Reset
--signal p_FMC_EXT_CLK        : std_logic                     := 'Z';             --! Sample Clock from ACQ420FMC -- (unused) GBC:20190321
--signal p_FMC_EXT_TRIG       : std_logic                     := 'Z';             --! Trigger from ACQ420FMC -- (unused) GBC:20190321

-- Internal Names
signal ADC_CNV              : std_logic                     := '0';             --! ADC Convert Control
signal ADC_SPI_CLK          : std_logic                     := '0';             --! ADC SPI Clock
signal ADC_SDO              : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data
signal DAC_SPI_CLK          : std_logic                     := '0';             --! DAC SPI Clock
signal DAC_SDI              : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data In
signal DAC_SDO              : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data Out
signal DAC_SYNC_n           : std_logic                     := '0';             --! DAC SPI SYNC
signal DAC_LD_n             : std_logic                     := '0';             --! DAC Load
signal DAC_RST_n            : std_logic;                                        --! DAC Reset
--signal FMC_EXT_CLK          : std_logic;                                        --! Sample Clock from ACQ420FMC -- (unused) GBC:20190321
--signal FMC_EXT_TRIG         : std_logic;                                        --! Trigger from ACQ420FMC -- (unused) GBC:20190321
--signal FMC_IO_BUS           : std_logic_vector(3 downto 0)  := (others => '0'); --! FMC IO Controls (CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR) -- (unused) GBC:20190321

signal FMC_MODULE_ENABLE_n  : std_logic;                                        --! FPGA Enable Outputs
signal ADC_MODULE_ENABLE    : std_logic_vector(31 downto 0);                    --! FPGA Enable Outputs
signal DAC_MODULE_ENABLE    : std_logic_vector(31 downto 0);
signal ADC_CLK_SELECT       : std_logic_vector(31 downto 0);
signal ADC_CLKDIV           : std_logic_vector(31 downto 0);
signal ADC_FIFO_RESET       : std_logic_vector(31 downto 0);
signal ADC_FIFO_ENABLE      : std_logic_vector(31 downto 0);
signal ADC_RESET            : std_logic_vector(31 downto 0);
signal ADC_ENABLE           : std_logic_vector(31 downto 0);
signal DAC_CLKDIV           : std_logic_vector(31 downto 0);
signal DAC_FIFO_RESET       : std_logic_vector(31 downto 0);
signal DAC_FIFO_ENABLE      : std_logic_vector(31 downto 0);
signal DAC_RESET            : std_logic_vector(31 downto 0);
signal DAC_ENABLE           : std_logic_vector(31 downto 0);
signal CH01_DAC_DATA        : std_logic_vector(31 downto 0);
signal CH02_DAC_DATA        : std_logic_vector(31 downto 0);
signal CH03_DAC_DATA        : std_logic_vector(31 downto 0);
signal CH04_DAC_DATA        : std_logic_vector(31 downto 0);

signal gains            : std32_array(7 downto 0);


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

--signal s_TRIG_DATA          : std_logic := '0';                                 --! External Trigger Data -- (unused) GBC:20190321
--signal s_CLOCK_DATA         : std_logic := '0';                                 --! External Clock Data -- (unused) GBC:20190321

signal ADC_DATAOUT          : std_logic_vector(255 downto 0) := (others => '0');
signal fmc_data             : std32_array(7 downto 0);
signal fmc_data_o           : std32_array(7 downto 0);

--signal FMC_ADC_TRIG_TRI_EN  : std_logic; -- (unused) GBC:20190321
--signal FMC_ADC_CLK_TRI_EN   : std_logic; -- (unused) GBC:20190321

---------------------------------------------------------------------------------------
-- DAC I/O Logic
---------------------------------------------------------------------------------------

signal clk_DAC_IOB          : std_logic;                                        --! DAC SPI Clk for IOBs

signal s_DAC_SPI_CLK        : std_logic := '0';                                 --! DAC SPI Clock
signal s_DAC_SDI            : std_logic_vector(4 downto 1) := (others => '0');  --! DAC SPI Data In
signal s_DAC_SDO            : std_logic_vector(4 downto 1) := (others => '0');  --! DAC SPI Data Out
signal s_DAC_SYNC_n         : std_logic                    := '0';              --! DAC SPI SYNC
signal s_DAC_LD_n           : std_logic                    := '0';              --! DAC Load

signal DAC_DATAIN           : std_logic_vector(127 downto 0) := (others => '0');

---------------------------------------------------------------------------------------
-- Signal Attributes
---------------------------------------------------------------------------------------
-- attribute mark_debug    : string; -- (unused) GBC:20190321
attribute keep          : string;
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
--attribute mark_debug of s_ADC_SDO       : signal is "true"; -- (unused) GBC:20190321

begin

---------------------------------------------------------------------------------------
-- Translate the FMC pin names into ACQ427FMC names
---------------------------------------------------------------------------------------
-- ADC
---------------------------------------------------------------------------------------
-- Input Pins
--p_FMC_EXT_CLK  <=  FMC_io.FMC_LA_P(0); -- (unused) GBC:20190321
--p_FMC_EXT_TRIG <=  FMC_io.FMC_LA_P(12); -- (unused) GBC:20190321
in_ttl_o(0) <= FMC_io.FMC_LA_P(0);
p_ADC_SDO(8)   <=  FMC_io.FMC_LA_P(20);
p_ADC_SDO(7)   <=  FMC_io.FMC_LA_P(21);
p_ADC_SDO(6)   <=  FMC_io.FMC_LA_P(22);
p_ADC_SDO(5)   <=  FMC_io.FMC_LA_P(23);
p_ADC_SDO(4)   <=  FMC_io.FMC_LA_P(16);
p_ADC_SDO(3)   <=  FMC_io.FMC_LA_P(17);
p_ADC_SDO(2)   <=  FMC_io.FMC_LA_P(18);
p_ADC_SDO(1)   <=  FMC_io.FMC_LA_P(19);

-- Output Pins
FMC_io.FMC_LA_P(14)   <=  p_ADC_CNV_A;
FMC_io.FMC_LA_P(15)   <=  p_ADC_CNV_B;
FMC_io.FMC_LA_P(13)   <=  p_ADC_SPI_CLK;


--s_TRIG_DATA    <=  FMC_IO_BUS(1); -- (unused) GBC:20190321
--s_CLOCK_DATA   <=  FMC_IO_BUS(3); -- (unused) GBC:20190321
---------------------------------------------------------------------------------------
-- DAC
---------------------------------------------------------------------------------------
-- Input Pins
p_DAC_SDO(1)        <= FMC_io.FMC_LA_P(8);
p_DAC_SDO(2)        <= FMC_io.FMC_LA_P(9);
p_DAC_SDO(3)        <= FMC_io.FMC_LA_P(10);
p_DAC_SDO(4)        <= FMC_io.FMC_LA_P(11);

-- Output Pins
FMC_io.FMC_CLK0_M2C_P      <= p_DAC_SPI_CLK;

FMC_io.FMC_LA_P(4)         <= p_DAC_SDI(1);
FMC_io.FMC_LA_P(5)         <= p_DAC_SDI(2);
FMC_io.FMC_LA_P(6)         <= p_DAC_SDI(3);
FMC_io.FMC_LA_P(7)         <= p_DAC_SDI(4);
FMC_io.FMC_LA_P(1)         <= p_DAC_SYNC_n;
FMC_io.FMC_LA_P(2)         <= p_DAC_LD_n;
FMC_io.FMC_LA_P(3)         <= p_DAC_RST_n;


---------------------------------------------------------------------------------------
-- IO Buffer Instantiation
---------------------------------------------------------------------------------------
-- ADC
---------------------------------------------------------------------------------------

--FMC_ADC_TRIG_TRI_EN <= not FMC_IO_BUS(0); -- (unused) GBC:20190321
--FMC_ADC_CLK_TRI_EN  <= not FMC_IO_BUS(2); -- (unused) GBC:20190321

--cmp_FMC_ADC_TRIG:       IOBUF port map(IO => p_FMC_EXT_TRIG,I => s_TRIG_DATA,  O => FMC_EXT_TRIG, T => FMC_ADC_TRIG_TRI_EN); -- (unused) GBC:20190321
--cmp_FMC_ADC_CLK:        IOBUF port map(IO => p_FMC_EXT_CLK, I => s_CLOCK_DATA, O => FMC_EXT_CLK,  T => FMC_ADC_CLK_TRI_EN); -- (unused) GBC:20190321

cmp_ADC_CNV_A:          IOBUF port map(IO => p_ADC_CNV_A, I => ADC_CNV, T => FMC_MODULE_ENABLE_n);
cmp_ADC_CNV_B:          IOBUF port map(IO => p_ADC_CNV_B, I => ADC_CNV, T => FMC_MODULE_ENABLE_n);

cmp_ADC_CLK:        OBUFT generic map (SLEW => "FAST") port map(O => p_ADC_SPI_CLK, I => ADC_SPI_CLK, T => FMC_MODULE_ENABLE_n);

gen_ADC_BUFS: for x in 1 to 8 generate
    cmp_ADC_SDO: IBUF port map(I => p_ADC_SDO(x), O => ADC_SDO(x));
end generate gen_ADC_BUFS ;
---------------------------------------------------------------------------------------
-- DAC
---------------------------------------------------------------------------------------
cmp_DAC_RST_n:          IOBUF port map(IO => p_DAC_RST_n,   I => DAC_RST_n,   T => FMC_MODULE_ENABLE_n);

cmp_DAC_SPI_CLK:        IOBUF port map(IO => p_DAC_SPI_CLK, I => DAC_SPI_CLK, T => FMC_MODULE_ENABLE_n);
cmp_DAC_DAC_SYNC_n:     IOBUF port map(IO => p_DAC_SYNC_n,  I => DAC_SYNC_n,  T => FMC_MODULE_ENABLE_n);
cmp_DAC_DAC_LD_n:       IOBUF port map(IO => p_DAC_LD_n,    I => DAC_LD_n,    T => FMC_MODULE_ENABLE_n);

gen_DAC_BUFS: for x in 1 to 4 generate
    cmp_DAC_DAC_SDI:    IOBUF port map(IO => p_DAC_SDI(x),  I => DAC_SDI(x),  T => FMC_MODULE_ENABLE_n);
    cmp_DAC_SDO:        IOBUF port map(IO => p_DAC_SDO(x),  I => '0',         T => '1', O => DAC_SDO(x));
end generate gen_DAC_BUFS ;

fmc_ctrl : entity work.fmc_acq427_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    -- Block Parameters
    IN_GAIN1 => gains(0),
    IN_GAIN1_wstb  => open,
    IN_GAIN2 => gains(1),
    IN_GAIN2_wstb  => open,
    IN_GAIN3 => gains(2),
    IN_GAIN3_wstb  => open,
    IN_GAIN4 => gains(3),
    IN_GAIN4_wstb  => open,
    IN_GAIN5 => gains(4),
    IN_GAIN5_wstb  => open,
    IN_GAIN6 => gains(5),
    IN_GAIN6_wstb  => open,
    IN_GAIN7 => gains(6),
    IN_GAIN7_wstb  => open,
    IN_GAIN8 => gains(7),
    IN_GAIN8_wstb  => open,

    OUT_VAL1_from_bus     => CH01_DAC_DATA,
    OUT_VAL2_from_bus     => CH02_DAC_DATA,
    OUT_VAL3_from_bus     => CH03_DAC_DATA,
    OUT_VAL4_from_bus     => CH04_DAC_DATA,

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


fmc_adc_start : entity work.fmc_adc_start
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    MODULE_ENABLE       => ADC_MODULE_ENABLE,
    ADC_CLK_SELECT      => ADC_CLK_SELECT,
    ADC_CLKDIV          => ADC_CLKDIV,
    ADC_FIFO_RESET      => ADC_FIFO_RESET,
    ADC_FIFO_ENABLE     => ADC_FIFO_ENABLE,
    ADC_RESET           => ADC_RESET,
    ADC_ENABLE          => ADC_ENABLE
);


fmc_dac_start  : entity work.fmc_dac_start
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    MODULE_ENABLE       => DAC_MODULE_ENABLE,
    DAC_CLKDIV          => DAC_CLKDIV,
    DAC_FIFO_RESET      => DAC_FIFO_RESET,
    DAC_FIFO_ENABLE     => DAC_FIFO_ENABLE,
    DAC_RESET           => DAC_RESET,
    DAC_ENABLE          => DAC_ENABLE
);


FMC_MODULE_ENABLE_n <= not (ADC_MODULE_ENABLE(0) or DAC_MODULE_ENABLE(0));

THE_ACQ427FMC_ADC_INTERFACE : entity work.ACQ427FMC_ADC_INTERFACE
port map (
    clk_PANDA               => clk_i,           -- 100 MHz Clock from ARM for ADC Timing
    --EXT_CLOCK               => FMC_EXT_CLK,     -- External Clock Source  -- (unused) GBC:20190321
    --FMC_IO_BUS              => FMC_IO_BUS,      -- FMC IO Controls (CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR) -- (unused) GBC:20190321
    --ADC_CLK_SELECT_REG      => ADC_CLK_SELECT,        -- (unused) GBC:20190321
    ADC_CLKDIV_REG          => ADC_CLKDIV,
    ADC_FIFO_RESET_REG      => ADC_FIFO_RESET,
    ADC_FIFO_ENABLE_REG     => ADC_FIFO_ENABLE,
    ADC_RESET_REG           => ADC_RESET,
    ADC_ENABLE_REG          => ADC_ENABLE,
    clk_ADC_IOB             => clk_ADC_IOB,     -- ADC SPI Clock domain for IOBs
    ADC_SDO                 => s_ADC_SDO,       -- ADC SPI Data
    ADC_CNV                 => ADC_CNV,         -- ADC Convert Control
    ADC_SPI_CLK             => s_ADC_SPI_CLK,   -- ADC SPI Clock
    -- Panda Output
    ADC_DATAOUT             =>  ADC_DATAOUT
    );

fmc_data(7) <= ADC_DATAOUT(31 downto 0);
fmc_data(6) <= ADC_DATAOUT(63 downto 32);
fmc_data(5) <= ADC_DATAOUT(95 downto 64);
fmc_data(4) <= ADC_DATAOUT(127 downto 96);
fmc_data(3) <= ADC_DATAOUT(159 downto 128);
fmc_data(2) <= ADC_DATAOUT(191 downto 160);
fmc_data(1) <= ADC_DATAOUT(223 downto 192);
fmc_data(0) <= ADC_DATAOUT(255 downto 224);
in_val1_o(0) <= fmc_data_o(0);
in_val2_o(0) <= fmc_data_o(1);
in_val3_o(0) <= fmc_data_o(2);
in_val4_o(0) <= fmc_data_o(3);
in_val5_o(0) <= fmc_data_o(4);
in_val6_o(0) <= fmc_data_o(5);
in_val7_o(0) <= fmc_data_o(6);
in_val8_o(0) <= fmc_data_o(7);


IOB_FF_PUSH_ADC: process(clk_ADC_IOB)
begin
if Rising_Edge(clk_ADC_IOB) then
    ADC_SPI_CLK     <= s_ADC_SPI_CLK;
    if s_ADC_SPI_CLK = '1' then -- Only latch in on approaching rising edge
        s_ADC_SDO       <= ADC_SDO;
    end if;
end if;
end process IOB_FF_PUSH_ADC;


THE_ACQ427FMC_DAC_INTERFACE : entity work.ACQ427FMC_DAC_INTERFACE
port map (
    clk_PANDA               =>  clk_i,                -- 125 MHz PandA Clock
    DAC_CLKDIV_REG          => DAC_CLKDIV,
    DAC_FIFO_RESET_REG      => DAC_FIFO_RESET,
    DAC_FIFO_ENABLE_REG     => DAC_FIFO_ENABLE,
    DAC_RESET_REG           => DAC_RESET,
    DAC_ENABLE_REG          => DAC_ENABLE,
    clk_DAC_IOB             => clk_DAC_IOB,          -- DAC SPI Clk for IOBs
    DAC_SPI_CLK             => s_DAC_SPI_CLK,        -- DAC SPI Clock
    DAC_SDI                 => s_DAC_SDI,            -- DAC SPI Data In
    DAC_SDO                 => s_DAC_SDO,            -- DAC SPI Data Out
    DAC_SYNC_n              => s_DAC_SYNC_n,         -- DAC SPI SYNC
    DAC_LD_n                => s_DAC_LD_n,           -- DAC Load
    DAC_RST_n               => DAC_RST_n,            -- DAC Reset
    DAC_DATAIN              => DAC_DATAIN
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

-- Extract the FMC data and apply gain control to it.
gen_channel : for i in 0 to 7 generate
    process (clk_i)
        variable shift : natural;
    begin
        if rising_edge(clk_i) then
            shift := to_integer(unsigned(gains(i)(1 downto 0)));
            fmc_data_o(i) <= std_logic_vector(
                shift_right(signed(fmc_data(i)), shift));
        end if;
    end process;
end generate;

end rtl;

