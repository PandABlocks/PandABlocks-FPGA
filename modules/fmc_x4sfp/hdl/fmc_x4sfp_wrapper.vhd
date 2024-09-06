library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;
use work.top_defines.all;
use work.interface_types.all;

entity fmc_x4sfp_wrapper is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
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
end fmc_x4sfp_wrapper;

architecture rtl of fmc_x4sfp_wrapper is

constant NUM_I2C_CHANS : natural := 5;

signal FMC_PRSNT_DW     : std_logic_vector(31 downto 0);
signal FMC_I2C_MUX_VEC  : std_logic_vector(31 downto 0);
signal FMC_I2C_MUX      : integer range 0 to NUM_I2C_CHANS-1;
signal FMC_CLK0_M2C     : std_logic;
signal FMC_CLK1_M2C     : std_logic;
signal FREQ_VAL         : std32_array(1 downto 0);
signal test_clocks      : std_logic_vector(1 downto 0);
signal FMC_SDA_DEMUX    : std_logic_vector(NUM_I2C_CHANS-1 downto 0);
signal FMC_SCL_DEMUX    : std_logic_vector(NUM_I2C_CHANS-1 downto 0);

begin

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
FMC_PRSNT_DW <= ZEROS(30) & FMC.FMC_PRSNT;
FMC_I2C_MUX <= to_integer(unsigned(FMC_I2C_MUX_VEC));

-- Mux/Demux the SFP I2C for the HiTechGlobal FMC (HTG-FMC-x4-SFP)
-- Note that SFP numbering is reversed wrt to the FMC DP numbering
-- S0 SDA/SCL on LA00_N_CC/LA00_P_CC --- DP3
-- S1 SDA/SCL on LA01_N_CC/LA01_P_CC --- DP2
-- S2 SDA/SCL on LA02_N/LA02_P       --- DP1
-- S3 SDA/SCL on LA04_N/LA04_P       --- DP0   
-- OSC SDA/SCL on LA05_N/LA05_P
-- OSC_EN on LA03_N and CLK_SEL on LA03_P
-- Note CLK_SEL needs to be set to '0' as incorrectly pulled high on card

FMC.FMC_LA_P(3) <= '0'; -- CLK_SEL
FMC.FMC_LA_N(3) <= '1'; -- OSC_EN

FMC.FMC_LA_N(0) <= FMC_SDA_DEMUX(3);
FMC.FMC_LA_P(0) <= FMC_SCL_DEMUX(3);
FMC.FMC_LA_N(1) <= FMC_SDA_DEMUX(2);
FMC.FMC_LA_P(1) <= FMC_SCL_DEMUX(2);
FMC.FMC_LA_N(2) <= FMC_SDA_DEMUX(1);
FMC.FMC_LA_P(2) <= FMC_SCL_DEMUX(1);
FMC.FMC_LA_N(4) <= FMC_SDA_DEMUX(0);
FMC.FMC_LA_P(4) <= FMC_SCL_DEMUX(0);
FMC.FMC_LA_N(5) <= FMC_SDA_DEMUX(4);
FMC.FMC_LA_P(5) <= FMC_SCL_DEMUX(4);

-- Mux/Demux for FMC I2C

FMC.FMC_I2C_SDA_in <= FMC_SDA_DEMUX(FMC_I2C_MUX) when 
    FMC_I2C_MUX < NUM_I2C_CHANS else FMC_SDA_DEMUX(NUM_I2C_CHANS-1);
FMC.FMC_I2C_SCL_in <= FMC_SCL_DEMUX(FMC_I2C_MUX) when 
    FMC_I2C_MUX < NUM_I2C_CHANS else FMC_SCL_DEMUX(NUM_I2C_CHANS-1);

FMC_DEMUX_GEN: for chan in 0 to NUM_I2C_CHANS-1 generate
    FMC_SDA_DEMUX(chan) <= '0' when
        FMC_I2C_MUX = chan and FMC.FMC_I2C_SDA_tri = '0' and FMC.FMC_I2C_SDA_out = '0'
        else 'Z';
    FMC_SCL_DEMUX(chan) <= '0' when
        FMC_I2C_MUX = chan and FMC.FMC_I2C_SCL_tri = '0' and FMC.FMC_I2C_SCL_out = '0'
        else 'Z';
end generate;


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
    I           => FMC.FMC_CLK0_M2C_P,
    IB          => FMC.FMC_CLK0_M2C_N
);

IBUFGDS_CLK1 : IBUFGDS
generic map (
    DIFF_TERM   => TRUE,
    IOSTANDARD  => "LVDS"
)
port map (
    O           => FMC_CLK1_M2C,
    I           => FMC.FMC_CLK1_M2C_P,
    IB          => FMC.FMC_CLK1_M2C_N
);

---------------------------------------------------------------------------
-- FMC Clocks Frequency Counter
---------------------------------------------------------------------------

test_clocks(0) <= FMC_CLK0_M2C;
test_clocks(1) <= FMC_CLK1_M2C;

freq_counter_inst : entity work.freq_counter
generic map ( NUM => 2)
port map (
    refclk          => clk_i,
    reset           => reset_i,
    test_clocks     => test_clocks,
    freq_out        => FREQ_VAL
);

fmc_x4sfp_inst : entity work.fmc_x4sfp_ctrl
port map(
    clk_i => clk_i,
    reset_i => reset_i,
    bit_bus_i => bit_bus_i,
    pos_bus_i => pos_bus_i,
    -- Block Parameters
    FMC_PRSNT           => FMC_PRSNT_DW,
    FMC_I2C_MUX         => FMC_I2C_MUX_VEC,
    FMC_CLK0            => FREQ_VAL(0),
    FMC_CLK1            => FREQ_VAL(1),
    -- Memory Bus Interface
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o
);
end rtl;

