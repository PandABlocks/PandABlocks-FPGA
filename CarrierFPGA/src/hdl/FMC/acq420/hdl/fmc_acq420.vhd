--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Configurable D-Tacq ACQ420 FMC (ADC) top level interface
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity fmc_acq420 is
generic (
    -- Number of ADC channels
    N                   : natural := 4
);
port (
    -- Clock and Reset
    clk125_i            : in  std_logic;
    clk100_i            : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Inputs
    enable_i            : in  std_logic;
    -- Block Parameters
    ADC1_GAIN           : in  std_logic_vector(1 downto 0);
    ADC2_GAIN           : in  std_logic_vector(1 downto 0);
    ADC3_GAIN           : in  std_logic_vector(1 downto 0);
    ADC4_GAIN           : in  std_logic_vector(1 downto 0);
    -- FMC LA I/O
    FMC_LA_P            : inout std_logic_vector(33 downto 0);
    FMC_LA_N            : inout std_logic_vector(33 downto 0);
    -- ADC Data Interface
    adc_data_o          : out std32_array(N-1 downto 0);
    adc_data_val_o      : out std_logic_vector(N-1 downto 0)
);
end fmc_acq420;

architecture rtl of fmc_acq420 is

signal adc_cnv          : std_logic_vector(N-1 downto 0);
signal adc_busy         : std_logic_vector(N-1 downto 0);
signal adc_sck          : std_logic_vector(N-1 downto 0);
signal adc_sdo          : std_logic_vector(N-1 downto 0);
signal adc_data         : std32_array(N-1 downto 0);
signal adc_data_val     : std_logic_vector(N-1 downto 0);

begin

--------------------------------------------------------------------------
-- Generate all ADC channels. System clock for LTC is 100MHz.
--------------------------------------------------------------------------
ADCS : FOR I IN 0 TO N-1 GENERATE

adc_inst : entity work.ltc23xx
port map (
    clk_i               => clk100_i,
    reset_i             => reset_i,
    enable_i            => enable_i,

    ADC_BITS            => X"12",     -- 18-bits
    ADC_TSMPL           => X"64",     -- 1000ns
    ADC_TCONV           => X"35",     -- 530ns

    adc_cnv_o           => adc_cnv(I),
    adc_busy_i          => adc_busy(I),
    adc_sck_o           => adc_sck(I),
    adc_sdo_i           => adc_sdo(I),

    adc_data_o          => adc_data(I),
    adc_data_val_o      => adc_data_val(I)
);

sync_inst : entity work.syncdata
port map (
    clk_i               => clk100_i,
    clk_o               => clk125_i,
    dat_i               => adc_data(I),
    val_i               => adc_data_val(I),
    dat_o               => adc_data_o(I),
    val_o               => adc_data_val_o(I)
);

END GENERATE;

--------------------------------------------------------------------------
-- FMC Connector Mapping
--------------------------------------------------------------------------
-- Channel 1
FMC_LA_P(0) <= adc_cnv(0);
FMC_LA_P(1) <= adc_sck(0);
adc_sdo(0)  <= FMC_LA_P(3);

FMC_LA_P(16) <= ADC1_GAIN(0);
FMC_LA_P(17) <= ADC1_GAIN(1);

-- Channel 2
FMC_LA_P(5) <= adc_cnv(1);
FMC_LA_P(8) <= adc_sck(1);
adc_sdo(1)  <= FMC_LA_P(9);

FMC_LA_P(18) <= ADC2_GAIN(0);
FMC_LA_P(19) <= ADC2_GAIN(1);

-- Channel 3
FMC_LA_P(2) <= adc_cnv(2);
adc_sdo(2)  <= FMC_LA_P(4);
FMC_LA_P(7) <= adc_sck(2);

FMC_LA_P(20) <= ADC3_GAIN(0);
FMC_LA_P(21) <= ADC3_GAIN(1);

-- Channel 4
FMC_LA_P(11) <= adc_cnv(3);
FMC_LA_P(12) <= adc_sck(3);
adc_sdo(3)  <= FMC_LA_P(15);

FMC_LA_P(22) <= ADC4_GAIN(0);
FMC_LA_P(23) <= ADC4_GAIN(1);

--------------------------------------------------------------------------
-- Unsused IO
--------------------------------------------------------------------------
FMC_LA_N <= (others => 'Z');

end rtl;

