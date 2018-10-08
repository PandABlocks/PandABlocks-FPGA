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

entity fmc_dac427_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bitbus_i            : in  std_logic_vector(127 downto 0);
    posbus_i            : in  std32_array(31 downto 0);
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- LA I/O
    FMC_LA_P            : inout std_logic_vector(33 downto 0) := (others => 'Z');
    FMC_CLK0_M2C_P      : inout std_logic
);
end fmc_dac427_top;

architecture rtl of fmc_dac427_top is

---------------------------------------------------------------------------------------
-- FMC pin name translation signals.
---------------------------------------------------------------------------------------
signal p_FMC_EXT_CLK        : std_logic;                                        --! Sample Clock from ACQ420FMC
signal p_FMC_EXT_TRIG       : std_logic;                                        --! Trigger from ACQ420FMC
signal p_DAC_SPI_CLK        : std_logic                     := '0';             --! DAC SPI Clock
signal p_DAC_SDI            : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data In
signal p_DAC_SDO            : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data Out
signal p_DAC_SYNC_n         : std_logic                     := '0';             --! DAC SPI SYNC
signal p_DAC_LD_n           : std_logic                     := '0';             --! DAC Load
signal p_DAC_RST_n          : std_logic;                                        --! DAC Reset

-- Internal Names
signal DAC_SPI_CLK          : std_logic                     := '0';             --! DAC SPI Clock
signal DAC_SDI              : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data In
signal DAC_SDO              : std_logic_vector( 4 downto 1) := (others => '0'); --! DAC SPI Data Out
signal DAC_SYNC_n           : std_logic                     := '0';             --! DAC SPI SYNC
signal DAC_LD_n             : std_logic                     := '0';             --! DAC Load
signal DAC_RST_n            : std_logic;                                        --! DAC Reset
signal FMC_EXT_CLK          : std_logic;                                        --! Sample Clock from ACQ420FMC
signal FMC_EXT_TRIG         : std_logic;                                        --! Trigger from ACQ420FMC
signal FMC_IO_BUS           : std_logic_vector(3 downto 0)  := (others => '0'); --! FMC IO Controls (CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR)

signal FMC_MODULE_ENABLE_n  : std_logic;                                        --! FPGA Enable Outputs
signal MODULE_ENABLE        : std_logic_vector(31 downto 0);                    --! FPGA Enable Outputs
signal DAC_CLKDIV           : std_logic_vector(31 downto 0);
signal DAC_FIFO_RESET       : std_logic_vector(31 downto 0);
signal DAC_FIFO_ENABLE      : std_logic_vector(31 downto 0);
signal DAC_RESET            : std_logic_vector(31 downto 0);
signal DAC_ENABLE           : std_logic_vector(31 downto 0);
signal CH01_DAC_DATA        : std_logic_vector(31 downto 0);
signal CH02_DAC_DATA        : std_logic_vector(31 downto 0);
signal CH03_DAC_DATA        : std_logic_vector(31 downto 0);
signal CH04_DAC_DATA        : std_logic_vector(31 downto 0);

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
attribute mark_debug    : string;
attribute keep          : string;
attribute IOB           : string;


-- DAC Attributes
attribute keep      of s_DAC_SPI_CLK    : signal is "true";
attribute IOB       of DAC_SPI_CLK      : signal is "true";

attribute keep      of s_DAC_SDI        : signal is "true";
attribute IOB       of DAC_SDI          : signal is "true";

attribute keep      of DAC_SDO          : signal is "true";
attribute IOB       of s_DAC_SDO        : signal is "true";

attribute keep      of s_DAC_SYNC_n     : signal is "true";
attribute IOB       of DAC_SYNC_n       : signal is "true";


begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

---------------------------------------------------------------------------------------
-- Translate the FMC pin names into ACQ427FMC names
---------------------------------------------------------------------------------------
-- DAC
---------------------------------------------------------------------------------------
-- Input Pins
p_DAC_SDO(1)        <= FMC_LA_P(8);
p_DAC_SDO(2)        <= FMC_LA_P(9);
p_DAC_SDO(3)        <= FMC_LA_P(10);
p_DAC_SDO(4)        <= FMC_LA_P(11);

FMC_LA_P(4)         <= p_DAC_SDI(1);
FMC_LA_P(5)         <= p_DAC_SDI(2);
FMC_LA_P(6)         <= p_DAC_SDI(3);
FMC_LA_P(7)         <= p_DAC_SDI(4);
FMC_LA_P(1)         <= p_DAC_SYNC_n;
FMC_LA_P(2)         <= p_DAC_LD_n;
FMC_LA_P(3)         <= p_DAC_RST_n;


-- Output Pins
FMC_CLK0_M2C_P      <= p_DAC_SPI_CLK;

---------------------------------------------------------------------------------------
-- IO Buffer Instantiation
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



fmc_ctrl : entity work.dac_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => bitbus_i,
    posbus_i            => posbus_i,
        
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


fmc_dac_start  : entity work.fmc_dac_start
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    MODULE_ENABLE       => MODULE_ENABLE,
    DAC_CLKDIV          => DAC_CLKDIV,
    DAC_FIFO_RESET      => DAC_FIFO_RESET,
    DAC_FIFO_ENABLE     => DAC_FIFO_ENABLE,
    DAC_RESET           => DAC_RESET,
    DAC_ENABLE          => DAC_ENABLE
);    
            

FMC_MODULE_ENABLE_n <= not MODULE_ENABLE(0);


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

end rtl;

