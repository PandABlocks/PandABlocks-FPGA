--------------------------------------------------------------------------------
--  PandA Motion Project - 2017
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Scott Robson (D-TACQ Solutions)
--------------------------------------------------------------------------------
--
--  Description : FMC ACQ430 module interface to D-TACQ ACQ430FMC Module
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

entity fmc_acq430_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Outputs to PosBus from FMC
    val1_o              : out std_logic_vector(31 downto 0);
    val2_o              : out std_logic_vector(31 downto 0);
    val3_o              : out std_logic_vector(31 downto 0);
    val4_o              : out std_logic_vector(31 downto 0);
    val5_o              : out std_logic_vector(31 downto 0);
    val6_o              : out std_logic_vector(31 downto 0);
    val7_o              : out std_logic_vector(31 downto 0);
    val8_o              : out std_logic_vector(31 downto 0);
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    FMC_interface       : inout fmc_interface
);
end fmc_acq430_top;

architecture rtl of fmc_acq430_top is

---------------------------------------------------------------------------------------
-- FMC pin name translation signals.
---------------------------------------------------------------------------------------

signal  p_TRIGGER_DIR   : std_logic := '0';     --! External Trigger Direction Pin
signal  s_TRIG_DATA     : std_logic := '0';     --! External Trigger Data
signal  p_CLOCK_DIR     : std_logic := '0';     --! External Clock Direction Pin
signal  s_CLOCK_DATA    : std_logic := '0';     --! External Clock Data
signal  p_EXT_TRIGGER   : std_logic := '0';     --! External Trigger Pin
signal  p_EXT_CLOCK     : std_logic := '0';     --! External Clock Pin
signal  EXT_TRIGGER     : std_logic := '0';     --! External Trigger
signal  EXT_TRIGGER_MOD : std_logic := '0';     --! External Trigger Mod
signal  EXT_CLOCK       : std_logic := '0';     --! External Clock
signal  EXT_CLOCK_MOD   : std_logic := '0';     --! External Clock Mod
signal  FMC_IO_BUS      : std_logic_vector(4 downto 0) := (others => '0');  --! FMC IO Controls (FMC_LEMO_ROLE,CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR)


signal  p_ADC_MODE_0    : std_logic := '0';     --! ADC mode 0 = High Speed, 1 = High Performance
signal  p_ADC_SPI_CLK   : std_logic := '0';     --! ADC SPI Clock
signal  p_ADC_SDO       : std_logic := '0';     --! ADC SPI Data
signal  p_ADC_SYNC_n    : std_logic := '0';     --! ADC Inter-Device Synchronisation
signal  p_ADC_FSYNC     : std_logic := '0';     --! ADC Frame Sync for start of Sample


-- Internal Names
signal ADC_MODE_0       : std_logic := '0';     --! ADC mode 0 = High Speed, 1 = High Performance
signal ADC_SPI_CLK      : std_logic := '0';     --! ADC SPI Clock
signal ADC_SDO          : std_logic := '0';     --! ADC SPI Data
signal ADC_SYNC_n       : std_logic := '0';     --! ADC Inter-Device Synchronisation
signal ADC_FSYNC        : std_logic := '0';     --! ADC Frame Sync for start of Sample

signal FMC_MODULE_ENABLE_n      : std_logic;            --! FPGA Enable Outputs
signal MODULE_ENABLE            : std_logic_vector(31 downto 0);            --! FPGA Enable Outputs
signal ADC_MODE                 : std_logic_vector(31 downto 0);
signal CLK_SELECT               : std_logic_vector(31 downto 0);
signal ADC_CLKDIV               : std_logic_vector(31 downto 0);
signal FIFO_RESET               : std_logic_vector(31 downto 0);
signal FIFO_ENABLE              : std_logic_vector(31 downto 0);
signal ADC_RESET                : std_logic_vector(31 downto 0);
signal ADC_ENABLE               : std_logic_vector(31 downto 0);

signal clk_SPI_OUT             : std_logic;             --! ADC SPI Clk for IOBs
signal SPI_CLOCK_ENABLE        : std_logic;             --! ADC SPI Clock Enable
signal s_ADC_SYNC_n            : std_logic;             --! ADC Inter-Device Synchronisation
signal s_ADC_FSYNC             : std_logic;             --! ADC Frame Sync for start of Sample
signal s_ADC_SDO               : std_logic;             --! ADC SPI Data

signal ADC_DATAOUT             : std_logic_vector(255 downto 0) := (others => '0');


attribute mark_debug : string;
attribute keep : string;
attribute IOB : string;

attribute keep      of s_ADC_SYNC_n     : signal is "true";
attribute IOB       of ADC_SYNC_n       : signal is "true";

attribute keep      of s_ADC_FSYNC      : signal is "true";
attribute IOB       of ADC_FSYNC        : signal is "true";

attribute keep      of ADC_SDO          : signal is "true";
attribute IOB       of s_ADC_SDO        : signal is "true";

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

-- Translate the FMC pin names into ACQ430FMC names

FMC_interface.FMC_LA_P(14)    <=  p_TRIGGER_DIR;
FMC_interface.FMC_LA_P(10)    <=  p_CLOCK_DIR;

p_EXT_TRIGGER   <=  FMC_interface.FMC_LA_P(13);
p_EXT_CLOCK     <=  FMC_interface.FMC_CLK0_M2C_P;

-- On the ACQ430_TOPDECK only the CLOCK input is present. Make this switchable from Digital FMC IO Control Reg
--EXT_LEMO_SWITCH: process(FMC_IO_BUS,EXT_CLOCK,EXT_TRIGGER,EXT_CLOCK)
EXT_LEMO_SWITCH: process(FMC_IO_BUS)
begin
    if FMC_IO_BUS(4) = '1' then
        EXT_TRIGGER_MOD <=  EXT_CLOCK;
        EXT_CLOCK_MOD       <=  '0';
    else    -- Default configuration. Make initial value 0 in signal instantiation.
        EXT_TRIGGER_MOD     <=  EXT_TRIGGER;
        EXT_CLOCK_MOD       <=  EXT_CLOCK;
    end if;
end process EXT_LEMO_SWITCH;

s_TRIG_DATA     <=  FMC_IO_BUS(1);
s_CLOCK_DATA    <=  FMC_IO_BUS(3);


-- Fix Trigger and Clock as an Input only present
cmp_TRIGGER_DIR:    IOBUF port map(IO => p_TRIGGER_DIR, I => FMC_IO_BUS(0), T => FMC_MODULE_ENABLE_n    );
cmp_CLOCK_DIR:      IOBUF port map(IO => p_CLOCK_DIR,       I => FMC_IO_BUS(2), T => FMC_MODULE_ENABLE_n    );

cmp_EXT_TRIGGER:    IOBUF port map(IO => p_EXT_TRIGGER, I => s_TRIG_DATA    , O => EXT_TRIGGER, T => not FMC_IO_BUS(0));
cmp_EXT_CLOCK:      IBUF port map(I => p_EXT_CLOCK,     O => EXT_CLOCK);

-- Input Pins
p_ADC_SDO           <= FMC_interface.FMC_LA_P(12);


-- Output Pins
FMC_interface.FMC_LA_P(0)         <= p_ADC_MODE_0;
FMC_interface.FMC_LA_P(4)         <= p_ADC_FSYNC;
FMC_interface.FMC_LA_P(8)         <= p_ADC_SPI_CLK;
FMC_interface.FMC_LA_P(16)        <= p_ADC_SYNC_n;

-- Tie off pins - this may change

cmp_ADC_SDO:        IBUF port map(I => p_ADC_SDO,       O => ADC_SDO);
cmp_ADC_MODE_0:     IOBUF port map(IO => p_ADC_MODE_0,  I => ADC_MODE_0,    T => FMC_MODULE_ENABLE_n);
cmp_ADC_FSYNC:      IOBUF port map(IO => p_ADC_FSYNC,   I => ADC_FSYNC,     T => FMC_MODULE_ENABLE_n);
cmp_ADC_SPI_CLK:    IOBUF port map(IO => p_ADC_SPI_CLK, I => ADC_SPI_CLK,   T => FMC_MODULE_ENABLE_n);
cmp_ADC_SYNC_n:     IOBUF port map(IO => p_ADC_SYNC_n,  I => ADC_SYNC_n,    T => FMC_MODULE_ENABLE_n);

-- Unused IO
FMC_interface.FMC_LA_P(33 downto 17)  <= (others => 'Z');
FMC_interface.FMC_LA_P(15)            <= 'Z';
FMC_interface.FMC_LA_P(9)             <= 'Z';
FMC_interface.FMC_LA_P(7 downto 5)    <= (others => 'Z');
FMC_interface.FMC_LA_P(3 downto 1)    <= (others => 'Z');
FMC_interface.FMC_LA_N(33 downto 0)   <= (others => 'Z');



fmc_adc430_start_inst: entity work.fmc_adc430_start
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    MODULE_ENABLE       => MODULE_ENABLE,
    ADC_MODE            => ADC_MODE,
    CLK_SELECT          => CLK_SELECT,
    ADC_CLKDIV          => ADC_CLKDIV,
    FIFO_RESET          => FIFO_RESET,
    FIFO_ENABLE         => FIFO_ENABLE,
    ADC_RESET           => ADC_RESET,
    ADC_ENABLE          => ADC_ENABLE
);

FMC_MODULE_ENABLE_n <= not MODULE_ENABLE(0);
ADC_MODE_0 <= ADC_MODE(0);

THE_ACQ430FMC_INTERFACE : entity work.ACQ430FMC_INTERFACE
port map (
    clk_PANDA                =>  clk_i,                 -- 100 MHz Clock from ARM for ADC Timing

    EXT_CLOCK               =>  EXT_CLOCK_MOD,          -- External Clock Source
    FMC_IO_BUS              =>  FMC_IO_BUS,             -- FMC IO Controls (CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR)

    ADC_MODE_REG            => ADC_MODE,
    CLK_SELECT_REG          => CLK_SELECT,
    ADC_CLKDIV_REG          => ADC_CLKDIV,
    FIFO_RESET_REG          => FIFO_RESET,
    FIFO_ENABLE_REG         => FIFO_ENABLE,
    ADC_RESET_REG           => ADC_RESET,
    ADC_ENABLE_REG          => ADC_ENABLE,

    clk_SPI_OUT             =>  clk_SPI_OUT,
    SPI_CLOCK_ENABLE        =>  SPI_CLOCK_ENABLE,       -- ADC SPI Clock
    ADC_SDO                 =>  s_ADC_SDO,              -- ADC SPI Data
    ADC_SYNC_n              =>  s_ADC_SYNC_n,           -- ADC Inter-Device Synchronisation
    ADC_FSYNC               =>  s_ADC_FSYNC,            -- ADC Frame Sync for start of Sample

    ADC_DATAOUT             =>  ADC_DATAOUT
    );


val8_o <= ADC_DATAOUT(31 downto 0);
val7_o <= ADC_DATAOUT(63 downto 32);
val6_o <= ADC_DATAOUT(95 downto 64);
val5_o <= ADC_DATAOUT(127 downto 96);
val4_o <= ADC_DATAOUT(159 downto 128);
val3_o <= ADC_DATAOUT(191 downto 160);
val2_o <= ADC_DATAOUT(223 downto 192);
val1_o <= ADC_DATAOUT(255 downto 224);

-- Push onto IOB FFs
process(clk_SPI_OUT )
begin
if Falling_Edge(clk_SPI_OUT) then
    ADC_FSYNC   <= s_ADC_FSYNC;
    ADC_SYNC_n  <= s_ADC_SYNC_n;
    s_ADC_SDO   <= ADC_SDO;
end if;
end process;

-- Signals to the physical ADCs
cmp_ADC_SPI_CLK_ODDR : ODDR
generic map(
    DDR_CLK_EDGE    => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
    INIT         => '0', -- Initial value for Q port ('1' or '0')
    SRTYPE       => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
    Q           => ADC_SPI_CLK, -- 1-bit DDR output
    C           => clk_SPI_OUT, -- 1-bit clock input
    CE          => SPI_CLOCK_ENABLE, -- 1-bit clock enable input
    D1          => '1', -- 1-bit data input (positive edge)
    D2          => '0', -- 1-bit data input (negative edge)
    R           => '0', -- 1-bit reset input
    S           => '0' -- 1-bit set input
);

end rtl;
