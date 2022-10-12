--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : FMC-ADC-100M-14b4Cha on NAMC-ZYNQ-FMC board
-- Design name    : bitslip_monitor.vhd
-- Description    : Montoring Serdes BITLIP input signal
--
-- Author         : Thierry GARREL (ELSYS-Design)
-- Synthesizable  : Yes
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2022 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


--------------------------------------------------------------------------------
-- Entity declaration
--------------------------------------------------------------------------------
entity bitslip_monitor is
  port (
    -- clock and reset
    adc_clk_i             : in  std_logic;  -- 100 mhz adc clock
    adc_reset_i           : in  std_logic;  -- reset synchronous to adc_clk (active high)
    -- Block input
    serdes_bitslip_i      : in std_logic;   -- Bitslip input from Serdes
    -- Block parameters (in adc_clk domain)
    BITSLIP_MONITOR_EN    : in  std_logic;  -- Enable Bitslip monitoring
    BITSLIP_ERROR         : out std_logic   -- Bitslip triggered  while Enable was High
);
end bitslip_monitor;

------------------------------------------------------------------
-- Arxhictecture
------------------------------------------------------------------
architecture rtl of bitslip_monitor is

  signal bitslip_triggered : std_logic;

-- Begin of code
begin

  monitor_p : process(adc_clk_i)
  begin
    if rising_edge(adc_clk_i) then
      if BITSLIP_MONITOR_EN = '1' then
        if serdes_bitslip_i = '1' then
          bitslip_triggered <= '1';
        end if;
      else
        bitslip_triggered <= '0';
      end if;
    end if;
  end process;

  -- assign output
  BITSLIP_ERROR <= bitslip_triggered;


end rtl;
-- End of code
