--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : FMC 24VIO module interface to Diamond FMC-24VIO Module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity fmc_24vio is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- FMC LA I/O
    FMC_LA_P            : inout std_logic_vector(33 downto 0);
    FMC_LA_N            : inout std_logic_vector(33 downto 0);
    --
    OUT_PWR_ON          : in  std_logic;
    OUT_EN              : in  std_logic;
    -- MAX31915 control interface
    IN_VTSEL            : in  std_logic;
    IN_DB               : in  std_logic_vector(1 downto 0);
    IN_FAULT            : out std_logic_vector(31 downto 0);
    -- MAX14900 control interface
    OUT_PUSHPL          : in  std_logic;
    OUT_FLTR            : in  std_logic;
    OUT_SRIAL           : in  std_logic;
    OUT_FAULT           : out std_logic_vector(31 downto 0);
    OUT_CONFIG          : in  std_logic_vector(15 downto 0);
    OUT_STATUS          : out std_logic_vector(31 downto 0);
    -- 24V <-> IO Inteface
    fmc_in_o            : out std_logic_vector(7 downto 0);
    fmc_out_i           : in  std_logic_vector(7 downto 0)
);
end fmc_24vio;

architecture rtl of fmc_24vio is

signal out_csn          : std_logic;
signal out_sclk         : std_logic;
signal out_miso         : std_logic;
signal out_mosi         : std_logic;

begin

-- Inputs coming from FMC connector
fmc_in_o(0) <= FMC_LA_P(0);
fmc_in_o(1) <= FMC_LA_N(0);
fmc_in_o(2) <= FMC_LA_P(1);
fmc_in_o(3) <= FMC_LA_N(1);
fmc_in_o(4) <= FMC_LA_P(2);
fmc_in_o(5) <= FMC_LA_N(2);
fmc_in_o(6) <= FMC_LA_P(3);
fmc_in_o(7) <= FMC_LA_N(3);

-- Outputs towards FMC connector
FMC_LA_P(4) <= fmc_out_i(0);
FMC_LA_N(4) <= fmc_out_i(1);
FMC_LA_P(5) <= fmc_out_i(2);
FMC_LA_N(5) <= fmc_out_i(3);
FMC_LA_P(6) <= fmc_out_i(4);
FMC_LA_N(6) <= fmc_out_i(5);
FMC_LA_P(7) <= fmc_out_i(6);
FMC_LA_N(7) <= fmc_out_i(7);

--------------------------------------------------------------------------
-- MAX31915 Octal, Digital Input Translator Control
--------------------------------------------------------------------------

-- Input CMOS or IEC 61131-2 compliant
-- Logic 0 = CMOS compliant
-- Logic 1 = IEC 61131-2 compliant
FMC_LA_P(8) <= IN_VTSEL;

-- Debounce (Filtering) Time Select Inputs
-- 00 : None
-- 01 : 0.025ms
-- 10 : 0.75ms
-- 11 : 3ms
FMC_LA_N(8) <= IN_DB(0);
FMC_LA_P(9) <= IN_DB(1);

-- Indicates Low Supply Voltage Alarm (Active Low)
IN_FAULT(0) <= FMC_LA_N(9);     -- UVFAULT

-- Indicates Hot Temperature Alarm. OR’ed with the UVFAULT indicator
IN_FAULT(1) <= FMC_LA_P(10);     -- FAULT

--------------------------------------------------------------------------
-- MAX14900E Octal, High-Speed, Industrial, High-Side Switch
--------------------------------------------------------------------------
FMC_LA_N(10) <= out_csn;
FMC_LA_P(11) <= out_sclk;
FMC_LA_N(11) <= out_mosi;
out_miso <= FMC_LA_P(12);

FMC_LA_N(12) <= OUT_EN;
FMC_LA_P(13) <= OUT_PWR_ON;

FMC_LA_N(13) <= OUT_PUSHPL;     -- Global Push-Pull/High-Side Select
FMC_LA_P(14) <= OUT_SRIAL;      -- Serial/Parallel Select
OUT_FAULT(0) <= FMC_LA_N(14);   -- Global Fault
FMC_LA_P(15) <= OUT_FLTR;       -- Glitch Filter Enable
--FMC_LA_N(15) <= 'Z';            -- Not used

-- 16-bit SPI Configuration and Status Interface
max14900_ctrl_inst : entity work.max14900_ctrl
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    csn_o           => out_csn,
    sclk_o          => out_sclk,
    miso_i          => out_miso,
    mosi_o          => out_mosi,
    config_i        => OUT_CONFIG,
    status_o        => OUT_STATUS(15 downto 0)
);

-- Unused IO
--FMC_LA_P(33 downto 16) <= (others => 'Z');
--FMC_LA_N(33 downto 16) <= (others => 'Z');

IN_FAULT(31 downto 2) <= (others => '0');
OUT_FAULT(31 downto 1) <= (others => '0');
OUT_STATUS(31 downto 16) <= (others => '0');

end rtl;