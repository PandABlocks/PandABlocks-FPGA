--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : FMC Top-Level Generic VHDL entity to support various FMC
--                modules.
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
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Standard FMC Block ports, do not add to or delete
    clk_i               : in  std_logic;
    clk_aux_i           : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bitbus_i            : in  std_logic_vector(127 downto 0);
    posbus_i            : in  std32_array(31 downto 0);
    -- Generic Inputs to BitBus and PosBus from FMC and SFP
    fmc_inputs_o        : out std_logic_vector(15 downto 0);
    fmc_data_o          : out std32_array(15 downto 0);
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
    FMC_CLK0_M2C_P      : in    std_logic;
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

signal FMC_CLK0_M2C     : std_logic;
signal FMC_CLK1_M2C     : std_logic;
signal EXTCLK           : std_logic;
signal FMC_PRSNT_DW     : std_logic_vector(31 downto 0);
signal ADC1_GAIN        : std_logic_vector(31 downto 0);
signal ADC2_GAIN        : std_logic_vector(31 downto 0);
signal ADC3_GAIN        : std_logic_vector(31 downto 0);
signal ADC4_GAIN        : std_logic_vector(31 downto 0);
signal enable           : std_logic;

-- Need to keep these signal for IOB packing
attribute keep              : string;
attribute keep of ADC1_GAIN : signal is "true";
attribute keep of ADC2_GAIN : signal is "true";
attribute keep of ADC3_GAIN : signal is "true";
attribute keep of ADC4_GAIN : signal is "true";

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY       => RD_ADDR2ACK
);

-- Multiplex read data out from multiple instantiations

---------------------------------------------------------------------------
-- FMC Mezzanine Clocks
---------------------------------------------------------------------------
IBUFGDS_CLK0 : IBUFGDS
generic map (
    DIFF_TERM   => TRUE,
    IOSTANDARD  => "LVDS"
)
port map (
    O           => FMC_CLK0_M2C,
    I           => FMC_CLK0_M2C_P,
    IB          => FMC_CLK0_M2C_N
);

IBUFGDS_CLK1 : IBUFGDS
generic map (
    DIFF_TERM   => TRUE,
    IOSTANDARD  => "LVDS"
)
port map (
    O           => FMC_CLK1_M2C,
    I           => FMC_CLK1_M2C_P,
    IB          => FMC_CLK1_M2C_N
);

--------------------------------------------------------------------------
-- External Clock interface (for testing)
--------------------------------------------------------------------------
IBUFGDS_EXT : IBUFGDS
generic map (
    DIFF_TERM   => FALSE,
    IOSTANDARD  => "LVDS_25"
)
port map (
    O           => EXTCLK,
    I           => EXTCLK_P,
    IB          => EXTCLK_N
);

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
FMC_PRSNT_DW <= ZEROS(31) & FMC_PRSNT;

fmc_ctrl : entity work.fmc_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => bitbus_i,
    posbus_i            => (others => (others => '0')),
    enable_o            => enable,
    -- Block Parameters
    PRESENT             => FMC_PRSNT_DW,
    ADC1_GAIN           => ADC1_GAIN,
    ADC1_GAIN_WSTB      => open,
    ADC2_GAIN           => ADC2_GAIN,
    ADC2_GAIN_WSTB      => open,
    ADC3_GAIN           => ADC3_GAIN,
    ADC3_GAIN_WSTB      => open,
    ADC4_GAIN           => ADC4_GAIN,
    ADC4_GAIN_WSTB      => open,
    -- Memory Bus Interface
    read_strobe_i       => '0',
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data_o,
    read_ack_o          => open,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open
);

---------------------------------------------------------------------------
-- FMC Application Core
---------------------------------------------------------------------------
fmc_acq420_inst : entity work.fmc_acq420
port map (
    -- Clock and Reset
    clk125_i            => clk_i,
    clk100_i            => clk_aux_i,
    reset_i             => reset_i,
    -- Block Inputs
    enable_i            => enable,
    -- Block Parameters
    ADC1_GAIN           => ADC1_GAIN(1 downto 0),
    ADC2_GAIN           => ADC2_GAIN(1 downto 0),
    ADC3_GAIN           => ADC3_GAIN(1 downto 0),
    ADC4_GAIN           => ADC4_GAIN(1 downto 0),
    -- FMC LA I/O
    FMC_LA_P            => FMC_LA_P,
    FMC_LA_N            => FMC_LA_N,
    -- ADC Data Interface
    adc_data_val_o      => fmc_inputs_o(3 downto 0),
    adc_data_o          => fmc_data_o(3 downto 0)
);

---------------------------------------------------------------------------
-- Assign outputs
---------------------------------------------------------------------------
fmc_inputs_o(15 downto 4) <= (others => '0');
fmc_data_o(15 downto 4) <= (others => (others => '0'));

end rtl;

