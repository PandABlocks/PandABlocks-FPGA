--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : FMC-ADC-100M-14b-4Cha on NAMC-ZYNQ-FMC board
-- Module name    : gen_refclk_200mhz.vhd
-- Purpose        : generation of 200 Mhz reference clock for IDELAYCTRL
--                  module using a PLLE2_BASE Zynq-7000 primitive
--
-- Author         : Thierry GARREL (ELSYS-Design)
-- Synthesizable  : NO
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2022 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity gen_refclk_200mhz is
generic (
  g_CLK_IN_PERIOD     : real := 10.0;     -- clock input period (ns)
  g_CLK_IN_MULT       : natural := 8;     -- multiplication Factor to reach min PLL VCO frequency (800.0 to 1866.0 MHz)
  g_REFCLK_DIVIDE     : natural := 4;     -- REFCLK division factor to reach 200 MHz frequency (from VCO)
  g_RESET_CYCLES      : natural := 20     -- reset duration in REFCLK cycles
);
port (
  clock_i         : in  std_logic;    -- clock input
  -- REFCLK domain
  refclk_o        : out std_logic;    -- REFCLK input of IDELAYCTRL (muse be 200 Mhz).
  refclk_locked_o : out std_logic;    -- PLL locked
  refclk_reset_o  : out std_logic     -- Reset output. Deactivate 'RESET_CYCLES' after pll_locked rise
);
end entity gen_refclk_200mhz;


architecture rtl of gen_refclk_200mhz is


  -- IDELAYCTRL is needed for calibration
  -- When IDELAYCTRL REFCLK is 200 MHz, IDELAY delay chain consist of 64 taps of 78 ps
  signal refclk_pll_clkfbout  : std_logic;
  signal refclk_pll_clkfbin   : std_logic;
  signal refclk_pll_clkout0   : std_logic;
  signal refclk_pll_locked    : std_logic;

  signal refclk_bufg          : std_logic;

Begin


  cmp_refclk_pll : PLLE2_BASE
  generic map (
    BANDWIDTH           => "OPTIMIZED",   -- OPTIMIZED, HIGH, LOW
    -- VCO Frequency range is 800.000 to 1866.000 MHz
    -- Multiply incoming clock by 8 to meet VCO min frequency and divide by 4
    CLKFBOUT_MULT       => g_CLK_IN_MULT,       -- Multiply value for all CLKOUT, (2-64)
    CLKFBOUT_PHASE      => 0.0,                 -- Phase offset in degrees of CLKFB, (-360.000-360.000).
    CLKIN1_PERIOD       => g_CLK_IN_PERIOD,     -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    CLKOUT0_DIVIDE      => g_REFCLK_DIVIDE,
    CLKOUT0_DUTY_CYCLE  => 0.5,
    CLKOUT0_PHASE       => 0.0,
    DIVCLK_DIVIDE       => 1,             -- Master division value, (1-56)
    REF_JITTER1         => 0.01,          -- Reference input jitter in UI, (0.000-0.999).
    STARTUP_WAIT        => "FALSE"        -- Delay DONE until PLL Locks, ("TRUE"/"FALSE")
   )
   port map (
      CLKOUT0           => refclk_pll_clkout0,
      CLKFBOUT          => refclk_pll_clkfbout,
      LOCKED            => refclk_pll_locked,
      CLKIN1            => clock_i,   -- 100 MHz
      PWRDWN            => '0',
      RST               => '0',
      CLKFBIN           => refclk_pll_clkfbin
   );

  cmp_clk_fb_bufg : BUFG
  port map ( I => refclk_pll_clkfbout, O => refclk_pll_clkfbin);

  cmp_clkout0_bufg : BUFG
  port map ( I => refclk_pll_clkout0, O => refclk_bufg);


  -- Generation of power-on reset (at least 50 ns)
  cmp_poweron_reset : entity work.power_on_reset
  generic map ( g_CYCLES  => g_RESET_CYCLES )
  port map (
    clock_i  => refclk_bufg,          -- in
    clock_en => refclk_pll_locked,    -- in
    reset_o  => refclk_reset_o        -- out
  );

  refclk_o        <= refclk_bufg;
  refclk_locked_o <= refclk_pll_locked;


end rtl;


