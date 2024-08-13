library ieee;
use ieee.std_logic_1164.all;

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

signal FMC_PRSNT_DW     : std_logic_vector(31 downto 0);
signal FMC_I2C_MUX_VEC  : std_logic_vector(31 downto 0);
signal CLK_SEL          : std_logic_vector(31 downto 0);
signal OE_OSC           : std_logic_vector(31 downto 0);
signal FMC_I2C_MUX      : std_logic_vector(2 downto 0);

begin

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
FMC_PRSNT_DW <= ZEROS(30) & FMC.FMC_PRSNT;
FMC_I2C_MUX <= FMC_I2C_MUX_VEC(2 downto 0);
FMC.FMC_LA_P(3) <= CLK_SEL(0);
FMC.FMC_LA_N(3) <= OE_OSC(0);

-- Mux/Demux the SFP I2C for the HiTechGlobal FMC (HTG-FMC-x4-SFP)
-- S0 SDA/SCL on LA00_N_CC/LA00_P_CC
-- S1 SDA/SCL on LA01_N_CC/LA01_P_CC
-- S2 SDA/SCL on LA02_N/LA02_P
-- S3 SDA/SCL on LA04_N/LA04_P
-- OSC SDA/SCL on LA05_N/LA05_P

-- Mux/Demux for FMC I2C

sda_mux: with FMC_I2C_MUX select
    FMC.FMC_I2C_SDA_in <=   FMC.FMC_LA_N(0) when "000",
                            FMC.FMC_LA_N(1) when "001",
                            FMC.FMC_LA_N(2) when "010",
                            FMC.FMC_LA_N(4) when "011",
                            FMC.FMC_LA_N(5) when others;

scl_mux: with FMC_I2C_MUX select
    FMC.FMC_I2C_SCL_in <=   FMC.FMC_LA_P(0) when "000",
                            FMC.FMC_LA_P(1) when "001",
                            FMC.FMC_LA_P(2) when "010",
                            FMC.FMC_LA_P(4) when "011",
                            FMC.FMC_LA_P(5) when others;

FMC.FMC_LA_N(0) <= '0' when (FMC_I2C_MUX = "000" and FMC.FMC_I2C_SDA_tri = '0' and FMC.FMC_I2C_SDA_out = '0') else 'Z';
FMC.FMC_LA_P(0) <= '0' when (FMC_I2C_MUX = "000" and FMC.FMC_I2C_SCL_tri = '0' and FMC.FMC_I2C_SCL_out = '0') else 'Z';
FMC.FMC_LA_N(1) <= '0' when (FMC_I2C_MUX = "001" and FMC.FMC_I2C_SDA_tri = '0' and FMC.FMC_I2C_SDA_out = '0') else 'Z';
FMC.FMC_LA_P(1) <= '0' when (FMC_I2C_MUX = "001" and FMC.FMC_I2C_SCL_tri = '0' and FMC.FMC_I2C_SCL_out = '0') else 'Z';
FMC.FMC_LA_N(2) <= '0' when (FMC_I2C_MUX = "010" and FMC.FMC_I2C_SDA_tri = '0' and FMC.FMC_I2C_SDA_out = '0') else 'Z';
FMC.FMC_LA_P(2) <= '0' when (FMC_I2C_MUX = "010" and FMC.FMC_I2C_SCL_tri = '0' and FMC.FMC_I2C_SCL_out = '0') else 'Z';
FMC.FMC_LA_N(4) <= '0' when (FMC_I2C_MUX = "011" and FMC.FMC_I2C_SDA_tri = '0' and FMC.FMC_I2C_SDA_out = '0') else 'Z';
FMC.FMC_LA_P(4) <= '0' when (FMC_I2C_MUX = "011" and FMC.FMC_I2C_SCL_tri = '0' and FMC.FMC_I2C_SCL_out = '0') else 'Z';
FMC.FMC_LA_N(5) <= '0' when (FMC_I2C_MUX = "100" and FMC.FMC_I2C_SDA_tri = '0' and FMC.FMC_I2C_SDA_out = '0') else 'Z';
FMC.FMC_LA_P(5) <= '0' when (FMC_I2C_MUX = "100" and FMC.FMC_I2C_SCL_tri = '0' and FMC.FMC_I2C_SCL_out = '0') else 'Z';


fmc_x4sfp_inst : entity work.fmc_x4sfp_ctrl
port map(
    clk_i => clk_i,
    reset_i => reset_i,
    bit_bus_i => bit_bus_i,
    pos_bus_i => pos_bus_i,
    -- Block Parameters
    FMC_PRSNT               => FMC_PRSNT_DW,
    FMC_I2C_MUX             => FMC_I2C_MUX_VEC,
    CLK_SEL                 => CLK_SEL,
    OE_OSC                  => OE_OSC,
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
