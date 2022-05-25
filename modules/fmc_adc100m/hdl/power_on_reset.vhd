--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : FMC-ADC-100M-14b-4Cha on NAMC-ZYNQ-FMC board
-- Module name    : power_on_reset.vhd
-- Purpose        : generation of N clock cycles reset pulse issued at start up
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

-- ------------------------------------
--  Power On Reset with NO reset input
-- ------------------------------------
-- g_CYCLES clock cycles reset pulse issued at start up
entity power_on_reset is
generic (
  g_CYCLES  : natural range 1 to 31 := 10   -- reset duration in clock cycles (max 31)
);
port (
  clock_i   : in  std_logic;  -- clock input
  clock_en  : in  std_logic;  -- clock enable
  reset_o   : out std_logic   -- reset output
);
end entity power_on_reset;


architecture rtl of power_on_reset is

  signal count_r    : unsigned (4 downto 0) := (others=>'0'); -- init for simulation
  signal reset_r    : std_logic := '1'; -- init for simulation

Begin

  clock_p :process (clock_i)
  begin
    if rising_edge(clock_i) then
      if clock_en = '1' then
        if count_r /= g_CYCLES then     -- If counter hasn't reached this value then
          count_r <= count_r + 1;       -- keep counting
          reset_r <= '1';               -- and force the Reset
        else
          count_r <= count_r;
          reset_r <= '0';               -- release the Reset
        end if;
      end if;
    end if;
  end process;

  reset_o  <= reset_r;

end rtl;


