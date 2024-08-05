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
use work.interface_types.all;

entity fmc_acq430_wrapper is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Outputs to PosBus from FMC
    val1_o              : out std32_array(0 downto 0);
    val2_o              : out std32_array(0 downto 0);
    val3_o              : out std32_array(0 downto 0);
    val4_o              : out std32_array(0 downto 0);
    val5_o              : out std32_array(0 downto 0);
    val6_o              : out std32_array(0 downto 0);
    val7_o              : out std32_array(0 downto 0);
    val8_o              : out std32_array(0 downto 0);
    -- Outputs to BitBus from FMC
    ttl_o               : out std_logic_vector(0 downto 0);
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    FMC                 : view FMC_Module
);
end fmc_acq430_wrapper;

architecture rtl of fmc_acq430_wrapper is

---------------------------------------------------------------------------------------
-- FMC pin name translation signals.
---------------------------------------------------------------------------------------

signal  p_TRIGGER_DIR   : std_logic := '0';     --! External Trigger Direction Pin
--signal  s_TRIG_DATA     : std_logic := '0';     --! External Trigger Data -- (unused) GBC:20190321
signal  p_CLOCK_DIR     : std_logic := '0';     --! External Clock Direction Pin
--signal  s_CLOCK_DATA    : std_logic := '0';     --! External Clock Data -- (unused) GBC:20190321
--signal  p_EXT_TRIGGER   : std_logic := '0';     --! External Trigger Pin -- (unused) GBC:20190321
--signal  p_EXT_CLOCK     : std_logic := '0';     --! External Clock Pin -- (unused) GBC:20190321
--signal  EXT_TRIGGER     : std_logic := '0';     --! External Trigger -- (unused) GBC:20190321
--signal  EXT_TRIGGER_MOD : std_logic := '0';     --! External Trigger Mod -- (unused) GBC:20190321
--signal  EXT_CLOCK       : std_logic := '0';     --! External Clock -- (unused) GBC:20190321
--signal  EXT_CLOCK_MOD   : std_logic := '0';     --! External Clock Mod -- (unused) GBC:20190321
--signal  FMC_IO_BUS      : std_logic_vector(4 downto 0) := (others => '0');  --! FMC IO Controls (FMC_LEMO_ROLE,CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR) -- (unused) GBC:20190321


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


-- attribute mark_debug : string; --GBC:20190321
attribute keep : string;
attribute IOB : string;

attribute keep      of s_ADC_SYNC_n     : signal is "true";
attribute IOB       of ADC_SYNC_n       : signal is "true";

attribute keep      of s_ADC_FSYNC      : signal is "true";
attribute IOB       of ADC_FSYNC        : signal is "true";

attribute keep      of ADC_SDO          : signal is "true";
attribute IOB       of s_ADC_SDO        : signal is "true";

begin

-- Control register interface
-- Not actually used but added for consistency with other modules
fmc_ctrl: entity work.fmc_acq430_ctrl
port map(
    -- Clock and Reset
    clk_i =>            clk_i,
    reset_i =>          reset_i,
    bit_bus_i =>        bit_bus_i,
    pos_bus_i =>         pos_bus_i,
    -- Block Parameters
    -- Memory Bus Interface
    read_strobe_i =>    read_strobe_i,
    read_address_i =>   read_address_i(BLK_AW-1 downto 0),
    read_data_o =>      read_data_o,
    read_ack_o =>       read_ack_o,

    write_strobe_i =>   write_strobe_i,
    write_address_i =>  write_address_i(BLK_AW-1 downto 0),
    write_data_i =>     write_data_i,
    write_ack_o =>      write_ack_o
);



-- Translate the FMC pin names into ACQ430FMC names

FMC.FMC_LA_P(14)    <=  p_TRIGGER_DIR;
FMC.FMC_LA_P(10)    <=  p_CLOCK_DIR;

--p_EXT_TRIGGER   <=  FMC.FMC_LA_P(13); -- (unused) GBC:20190321
--p_EXT_CLOCK     <=  FMC.FMC_CLK0_M2C_P; -- (unused) GBC:20190321
ttl_o(0) <= FMC.FMC_CLK0_M2C_P;

-- On the ACQ430_TOPDECK only the CLOCK input is present. Make this switchable from Digital FMC IO Control Reg
-- Commented GBC:20190403
--EXT_LEMO_SWITCH: process(FMC_IO_BUS,EXT_CLOCK,EXT_TRIGGER,EXT_CLOCK)
--EXT_LEMO_SWITCH: process(FMC_IO_BUS)
--begin
--    if FMC_IO_BUS(4) = '1' then
--        EXT_TRIGGER_MOD <=  EXT_CLOCK;
--        EXT_CLOCK_MOD       <=  '0';
--    else    -- Default configuration. Make initial value 0 in signal instantiation.
--        EXT_TRIGGER_MOD     <=  EXT_TRIGGER;
--        EXT_CLOCK_MOD       <=  EXT_CLOCK;
--    end if;
--end process EXT_LEMO_SWITCH;

--s_TRIG_DATA     <=  FMC_IO_BUS(1); -- (unused) GBC:20190321
--s_CLOCK_DATA    <=  FMC_IO_BUS(3); -- (unused) GBC:20190321


-- Fix Trigger and Clock as an Input only present
--cmp_TRIGGER_DIR:    IOBUF port map(IO => p_TRIGGER_DIR, I => FMC_IO_BUS(0), T => FMC_MODULE_ENABLE_n    ); -- GBC:20190321
--cmp_CLOCK_DIR:      IOBUF port map(IO => p_CLOCK_DIR,       I => FMC_IO_BUS(2), T => FMC_MODULE_ENABLE_n    ); -- GBC:20190321
cmp_TRIGGER_DIR:    IOBUF port map(IO => p_TRIGGER_DIR, I => '0', T => FMC_MODULE_ENABLE_n    );
cmp_CLOCK_DIR:      IOBUF port map(IO => p_CLOCK_DIR,       I => '0', T => FMC_MODULE_ENABLE_n    );

--cmp_EXT_TRIGGER:    IOBUF port map(IO => p_EXT_TRIGGER, I => s_TRIG_DATA    , O => EXT_TRIGGER, T => not FMC_IO_BUS(0)); -- (unused) GBC:20190321

--cmp_EXT_CLOCK:      IBUF port map(I => p_EXT_CLOCK,     O => EXT_CLOCK); -- (unused) GBC:20190321

-- Input Pins
p_ADC_SDO           <= FMC.FMC_LA_P(12);


-- Output Pins
FMC.FMC_LA_P(0)         <= p_ADC_MODE_0;
FMC.FMC_LA_P(4)         <= p_ADC_FSYNC;
FMC.FMC_LA_P(8)         <= p_ADC_SPI_CLK;
FMC.FMC_LA_P(16)        <= p_ADC_SYNC_n;

-- Tie off pins - this may change

cmp_ADC_SDO:        IBUF port map(I => p_ADC_SDO,       O => ADC_SDO);
cmp_ADC_MODE_0:     IOBUF port map(IO => p_ADC_MODE_0,  I => ADC_MODE_0,    T => FMC_MODULE_ENABLE_n);
cmp_ADC_FSYNC:      IOBUF port map(IO => p_ADC_FSYNC,   I => ADC_FSYNC,     T => FMC_MODULE_ENABLE_n);
cmp_ADC_SPI_CLK:    IOBUF port map(IO => p_ADC_SPI_CLK, I => ADC_SPI_CLK,   T => FMC_MODULE_ENABLE_n);
cmp_ADC_SYNC_n:     IOBUF port map(IO => p_ADC_SYNC_n,  I => ADC_SYNC_n,    T => FMC_MODULE_ENABLE_n);

-- Unused IO
--FMC.FMC_LA_P(33 downto 17)  <= (others => 'Z');
--FMC.FMC_LA_P(15)            <= 'Z';
--FMC.FMC_LA_P(9)             <= 'Z';
--FMC.FMC_LA_P(7 downto 5)    <= (others => 'Z');
--FMC.FMC_LA_P(3 downto 1)    <= (others => 'Z');
--FMC.FMC_LA_N(33 downto 0)   <= (others => 'Z');



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

    --EXT_CLOCK               =>  EXT_CLOCK_MOD,          -- External Clock Source -- (unused) GBC:20190321
    --FMC_IO_BUS              =>  FMC_IO_BUS,             -- FMC IO Controls (CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR) -- (unused) GBC:20190321

    ADC_MODE_REG            => ADC_MODE,
    --CLK_SELECT_REG          => CLK_SELECT,
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


val8_o(0) <= ADC_DATAOUT(31 downto 0);
val7_o(0) <= ADC_DATAOUT(63 downto 32);
val6_o(0) <= ADC_DATAOUT(95 downto 64);
val5_o(0) <= ADC_DATAOUT(127 downto 96);
val4_o(0) <= ADC_DATAOUT(159 downto 128);
val3_o(0) <= ADC_DATAOUT(191 downto 160);
val2_o(0) <= ADC_DATAOUT(223 downto 192);
val1_o(0) <= ADC_DATAOUT(255 downto 224);

-- Push onto IOB FFs
process(clk_SPI_OUT )
begin
if Falling_Edge(clk_SPI_OUT) then
    ADC_FSYNC   <= s_ADC_FSYNC;
    ADC_SYNC_n  <= s_ADC_SYNC_n;
    s_ADC_SDO   <= ADC_SDO;
end if;
end process;

adapt_clock_inst : entity work.enablable_clock_oddr
port map (
    clock_i  => clk_SPI_OUT,
    clock_o  => ADC_SPI_CLK,
    enable_i => SPI_CLOCK_ENABLE
);

end rtl;
