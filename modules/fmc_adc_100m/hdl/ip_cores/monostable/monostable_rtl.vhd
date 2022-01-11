--=============================================================================
-- @file monostable_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
--! Specific packages
-------------------------------------------------------------------------------
-- --
-- CERN, BE-CO-HT, Monostable
-- --
-------------------------------------------------------------------------------
--
-- Unit name: Monostable (monostable_rtl)
--
--! @brief Monostable
--!
--
--! @author Matthieu Cattin (matthieu dot cattin at cern dot ch)
--
--! @date 27\10\2009
--
--! @version v1.0
--
--! @details
--!
--! <b>Dependencies:</b>\n
--!
--! <b>References:</b>\n
--!
--!
--! <b>Modified by:</b>\n
--! Author:
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! 27.10.2009    mcattin     Creation from ext_pulse_sync_rtl.vhd
--!
--------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--------------------------------------------------------------------------------
-- This source file is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Lesser General Public License as published by the
-- Free Software Foundation; either version 2.1 of the License, or (at your
-- option) any later version. This source is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
-- of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU Lesser General Public License for more details. You should have
-- received a copy of the GNU Lesser General Public License along with this
-- source; if not, download it from http://www.gnu.org/licenses/lgpl-2.1.html
--------------------------------------------------------------------------------
--! @todo
--
-------------------------------------------------------------------------------


--=============================================================================
--! Entity declaration for Monostable
--=============================================================================
entity monostable is
  generic(
    g_INPUT_POLARITY  : std_logic := '1';    --! trigger_i polarity
                                             --! ('0'=negative, 1=positive)
    g_OUTPUT_POLARITY : std_logic := '1';    --! pulse_o polarity
                                             --! ('0'=negative, 1=positive)
    g_OUTPUT_RETRIG   : boolean   := false;  --! Retriggerable output monostable
    g_OUTPUT_LENGTH   : natural   := 1       --! pulse_o lenght (in clk_i ticks)
    );
  port (
    rst_n_i   : in  std_logic;               --! Reset (active low)
    clk_i     : in  std_logic;               --! Clock
    trigger_i : in  std_logic;               --! Trigger input pulse
    pulse_o   : out std_logic                --! Monostable output pulse
    );
end entity monostable;


--=============================================================================
--! Architecture declaration Monostable
--=============================================================================
architecture rtl of monostable is

  --! log2 function
  function log2_ceil(N : natural) return positive is
  begin
    if N <= 2 then
      return 1;
    elsif N mod 2 = 0 then
      return 1 + log2_ceil(N/2);
    else
      return 1 + log2_ceil((N+1)/2);
    end if;
  end;

  --! FFs for monostable start
  signal s_trigger_d      : std_logic_vector(1 downto 0)                  := (others => '0');
  --! Output pulse monostable counter
  signal s_monostable_cnt : unsigned(log2_ceil(g_OUTPUT_LENGTH) downto 0) := (others => '0');
  --! Output pulse for readback
  signal s_output_pulse   : std_logic                                     := '0';



--=============================================================================
--! Architecture begin
--=============================================================================
begin


--*****************************************************************************
-- Begin of p_trigger
--! Process: FF to generate monostable start pulse
--*****************************************************************************
  p_trigger : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        s_trigger_d <= (others => '0');
      else
        if trigger_i = g_INPUT_POLARITY then
          s_trigger_d(0) <= '1';
        else
          s_trigger_d(0) <= '0';
        end if;
        s_trigger_d(1) <= s_trigger_d(0);
      end if;
    end if;
  end process p_trigger;


--*****************************************************************************
-- Begin of p_monostable
--! Process: Monostable to generate output pulse
--*****************************************************************************
  p_monostable : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        s_monostable_cnt <= (others => '0');
        s_output_pulse   <= not(g_OUTPUT_POLARITY);
      elsif ((not(g_OUTPUT_RETRIG)
              and ((s_trigger_d(0) and not(s_trigger_d(1))) = '1')
              and (s_output_pulse /= g_OUTPUT_POLARITY))            -- non-retriggerable
             or (g_OUTPUT_RETRIG and (s_trigger_d(0) = '1'))) then  -- retriggerable
        s_monostable_cnt <= to_unsigned(g_OUTPUT_LENGTH, s_monostable_cnt'length) - 1;
        s_output_pulse   <= g_OUTPUT_POLARITY;
      elsif s_monostable_cnt = to_unsigned(0, s_monostable_cnt'length) then
        s_output_pulse <= not(g_OUTPUT_POLARITY);
      else
        s_monostable_cnt <= s_monostable_cnt - 1;
      end if;
    end if;
  end process p_monostable;

  pulse_o <= s_output_pulse;

end architecture rtl;
--=============================================================================
--! Architecture end
--=============================================================================
