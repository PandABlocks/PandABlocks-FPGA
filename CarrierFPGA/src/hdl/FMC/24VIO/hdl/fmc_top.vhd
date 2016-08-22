--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : FMC Loopback Design exercised all LA lines and GTX on the LPC
--                connector.
--
--                This module must be used with Whizz Systems FMC Loopback card
--                where LA[16:0] are outputs, and loopbacked to LA[33:17] as 
--                inputs.
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
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
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
    GTREFCLK_N          : in    std_logic;
    -- DO NOT EDIT ABOVE THIS LINE ---------------------

    -- EDIT BELOW THIS LINE ----------------------------
    -- Add application specific ports and connect on the top-level
    sysbus_i            : in    sysbus_t;
    fmc_inp1_o          : out   std_logic;
    fmc_inp2_o          : out   std_logic;
    fmc_inp3_o          : out   std_logic;
    fmc_inp4_o          : out   std_logic;
    fmc_inp5_o          : out   std_logic;
    fmc_inp6_o          : out   std_logic;
    fmc_inp7_o          : out   std_logic;
    fmc_inp8_o          : out   std_logic
);
end fmc_top;

architecture rtl of fmc_top is

signal FMC_CLK0_M2C     : std_logic;
signal FMC_CLK1_M2C     : std_logic;
signal EXTCLK           : std_logic;
signal FMC_PRSNT_DW     : std_logic_vector(31 downto 0);
signal fmc_in           : std_logic_vector(7 downto 0);
signal fmc_out          : std_logic_vector(7 downto 0);

begin

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
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    -- Block Parameters
    FMC_PRSNT           => FMC_PRSNT_DW,
    out1_o              => fmc_out(0),
    out2_o              => fmc_out(1),
    out3_o              => fmc_out(2),
    out4_o              => fmc_out(3),
    out5_o              => fmc_out(4),
    out6_o              => fmc_out(5),
    out7_o              => fmc_out(6),
    out8_o              => fmc_out(7),
    -- Memory Bus Interface
    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_dat_o
);

---------------------------------------------------------------------------
-- FMC Application Core
---------------------------------------------------------------------------
fmc_24vio_inst : entity work.fmc_24vio
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    FMC_LA_P            => FMC_LA_P,
    FMC_LA_N            => FMC_LA_N,
    fmc_in_o            => fmc_in,
    fmc_out_i           => fmc_out
);

---------------------------------------------------------------------------
-- Assign outputs
---------------------------------------------------------------------------
fmc_inp1_o <= fmc_in(0);
fmc_inp2_o <= fmc_in(1);
fmc_inp3_o <= fmc_in(2);
fmc_inp4_o <= fmc_in(3);
fmc_inp5_o <= fmc_in(4);
fmc_inp6_o <= fmc_in(5);
fmc_inp7_o <= fmc_in(6);
fmc_inp8_o <= fmc_in(7);

end rtl;

