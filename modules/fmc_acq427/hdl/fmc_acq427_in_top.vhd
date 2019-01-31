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

entity fmc_acq427_in_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bitbus_i            : in  std_logic_vector(127 downto 0);
    posbus_i            : in  std32_array(31 downto 0);
    -- Generic Inputs to BitBus and PosBus from FMC and SFP
    fmc_inputs_o        : out std_logic_vector(15 downto 0) := (others=>'0');
    fmc_data_o          : out std32_array(7 downto 0) := (others=>(others=>'0'));         -- 8 channels of 32-bit data
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic := '1';
    FMC_interface       : inout fmc_interface
);
end fmc_acq427_in_top;

architecture rtl of fmc_acq427_in_top is

---------------------------------------------------------------------------------------
-- FMC pin name translation signals.
---------------------------------------------------------------------------------------
signal p_ADC_CNV_A          : std_logic                     := '0';             --! ADC Convert Control A
signal p_ADC_CNV_B          : std_logic                     := '0';             --! ADC Convert Control B
signal p_ADC_SPI_CLK        : std_logic                     := '0';             --! ADC SPI Clock
signal p_ADC_SDO            : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data
signal p_FMC_EXT_CLK        : std_logic;                                        --! Sample Clock from ACQ420FMC
signal p_FMC_EXT_TRIG       : std_logic;                                        --! Trigger from ACQ420FMC

-- Internal Names
signal ADC_CNV              : std_logic                     := '0';             --! ADC Convert Control
signal ADC_SPI_CLK          : std_logic                     := '0';             --! ADC SPI Clock
signal ADC_SDO              : std_logic_vector( 8 downto 1) := (others => '0'); --! ADC SPI Data
signal FMC_EXT_CLK          : std_logic;                                        --! Sample Clock from ACQ420FMC
signal FMC_EXT_TRIG         : std_logic;                                        --! Trigger from ACQ420FMC
signal FMC_IO_BUS           : std_logic_vector(3 downto 0)  := (others => '0'); --! FMC IO Controls (CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR)

signal FMC_MODULE_ENABLE_n  : std_logic;                                        --! FPGA Enable Outputs
signal MODULE_ENABLE        : std_logic_vector(31 downto 0);                    --! FPGA Enable Outputs
signal ADC_CLK_SELECT       : std_logic_vector(31 downto 0);
signal ADC_CLKDIV           : std_logic_vector(31 downto 0);
signal ADC_FIFO_RESET       : std_logic_vector(31 downto 0);
signal ADC_FIFO_ENABLE      : std_logic_vector(31 downto 0);
signal ADC_RESET            : std_logic_vector(31 downto 0);
signal ADC_ENABLE           : std_logic_vector(31 downto 0);

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

signal s_TRIG_DATA          : std_logic := '0';                                 --! External Trigger Data
signal s_CLOCK_DATA         : std_logic := '0';                                 --! External Clock Data

signal ADC_DATAOUT          : std_logic_vector(255 downto 0) := (others => '0');
signal fmc_data             : std32_array(7 downto 0);


---------------------------------------------------------------------------------------
-- Signal Attributes
---------------------------------------------------------------------------------------
attribute mark_debug    : string;
attribute keep          : string;
attribute IOB           : string;


-- ADC Attributes
attribute keep      of ADC_SDO          : signal is "true";
attribute IOB       of s_ADC_SDO        : signal is "true";

attribute keep      of s_ADC_SPI_CLK    : signal is "true";
attribute IOB       of ADC_SPI_CLK      : signal is "true";

--------------------------------------------------------------------------------------
-- debug test using mark_debug
---------------------------------------------------------------------------------------
--attribute mark_debug of s_ADC_SDO       : signal is "true";

begin

---------------------------------------------------------------------------------------
-- Translate the FMC pin names into ACQ427FMC names
---------------------------------------------------------------------------------------
-- ADC
---------------------------------------------------------------------------------------
-- Input Pins
p_FMC_EXT_CLK  <=  FMC_interface.FMC_LA_P(0);
p_FMC_EXT_TRIG <=  FMC_interface.FMC_LA_P(12);
p_ADC_SDO(8)   <=  FMC_interface.FMC_LA_P(20);
p_ADC_SDO(7)   <=  FMC_interface.FMC_LA_P(21);
p_ADC_SDO(6)   <=  FMC_interface.FMC_LA_P(22);
p_ADC_SDO(5)   <=  FMC_interface.FMC_LA_P(23);
p_ADC_SDO(4)   <=  FMC_interface.FMC_LA_P(16);
p_ADC_SDO(3)   <=  FMC_interface.FMC_LA_P(17);
p_ADC_SDO(2)   <=  FMC_interface.FMC_LA_P(18);
p_ADC_SDO(1)   <=  FMC_interface.FMC_LA_P(19);

-- Output Pins
FMC_interface.FMC_LA_P(14)   <=  p_ADC_CNV_A;
FMC_interface.FMC_LA_P(15)   <=  p_ADC_CNV_B;
FMC_interface.FMC_LA_P(13)   <=  p_ADC_SPI_CLK;


s_TRIG_DATA    <=  FMC_IO_BUS(1);
s_CLOCK_DATA   <=  FMC_IO_BUS(3);


---------------------------------------------------------------------------------------
-- IO Buffer Instantiation
---------------------------------------------------------------------------------------
-- ADC
---------------------------------------------------------------------------------------
cmp_FMC_ADC_TRIG:       IOBUF port map(IO => p_FMC_EXT_TRIG,I => s_TRIG_DATA,  O => FMC_EXT_TRIG, T => not FMC_IO_BUS(0));
cmp_FMC_ADC_CLK:        IOBUF port map(IO => p_FMC_EXT_CLK, I => s_CLOCK_DATA, O => FMC_EXT_CLK,  T => not FMC_IO_BUS(2));

cmp_ADC_CNV_A:          IOBUF port map(IO => p_ADC_CNV_A, I => ADC_CNV, T => FMC_MODULE_ENABLE_n);
cmp_ADC_CNV_B:          IOBUF port map(IO => p_ADC_CNV_B, I => ADC_CNV, T => FMC_MODULE_ENABLE_n);

cmp_ADC_CLK:        OBUFT generic map (SLEW => "FAST") port map(O => p_ADC_SPI_CLK, I => ADC_SPI_CLK, T => FMC_MODULE_ENABLE_n);

gen_ADC_BUFS: for x in 1 to 8 generate
    cmp_ADC_SDO: IBUF port map(I => p_ADC_SDO(x), O => ADC_SDO(x));
end generate gen_ADC_BUFS ;

fmc_ctrl : entity work.fmc_acq427_in_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bitbus_i,
    pos_bus_i           => posbus_i,
    -- Block Parameters
    GAIN1 => gains(0),
    GAIN1_wstb  => open,
    GAIN2 => gains(1),
    GAIN2_wstb  => open,
    GAIN3 => gains(2),
    GAIN3_wstb  => open,
    GAIN4 => gains(3),
    GAIN4_wstb  => open,
    GAIN5 => gains(4),
    GAIN5_wstb  => open,
    GAIN6 => gains(5),
    GAIN6_wstb  => open,
    GAIN7 => gains(6),
    GAIN7_wstb  => open,
    GAIN8 => gains(7),
    GAIN8_wstb  => open,
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
    MODULE_ENABLE       => MODULE_ENABLE,
    ADC_CLK_SELECT      => ADC_CLK_SELECT,
    ADC_CLKDIV          => ADC_CLKDIV,
    ADC_FIFO_RESET      => ADC_FIFO_RESET,
    ADC_FIFO_ENABLE     => ADC_FIFO_ENABLE,
    ADC_RESET           => ADC_RESET,
    ADC_ENABLE          => ADC_ENABLE
);



FMC_MODULE_ENABLE_n <= not MODULE_ENABLE(0);

THE_ACQ427FMC_ADC_INTERFACE : entity work.ACQ427FMC_ADC_INTERFACE
port map (
    clk_PANDA               => clk_i,           -- 100 MHz Clock from ARM for ADC Timing
    EXT_CLOCK               => FMC_EXT_CLK,     -- External Clock Source
    FMC_IO_BUS              => FMC_IO_BUS,      -- FMC IO Controls (CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR)
    ADC_CLK_SELECT_REG      => ADC_CLK_SELECT,
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

-- Extract the FMC data and apply gain control to it.
gen_channel : for i in 0 to 7 generate
    process (clk_i)
        variable shift : natural := to_integer(unsigned(gains(i)(1 downto 0)));
    begin
        if rising_edge(clk_i) then
            fmc_data_o(i) <= std_logic_vector(
                shift_right(signed(fmc_data(i)), shift));
        end if;
    end process;
end generate;


IOB_FF_PUSH_ADC: process(clk_ADC_IOB)
begin
if Rising_Edge(clk_ADC_IOB) then
    ADC_SPI_CLK     <= s_ADC_SPI_CLK;
    if s_ADC_SPI_CLK = '1' then -- Only latch in on approaching rising edge
        s_ADC_SDO       <= ADC_SDO;
    end if;
end if;
end process IOB_FF_PUSH_ADC;



end rtl;

