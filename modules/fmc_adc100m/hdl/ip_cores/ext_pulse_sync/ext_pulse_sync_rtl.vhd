--=============================================================================
-- @file ext_pulse_sync_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.utils_pkg.all;
--! Specific packages
-------------------------------------------------------------------------------
-- --
-- CERN, BE-CO-HT, Synchronize an asnychronous external pulse to a clock
-- --
-------------------------------------------------------------------------------
--
-- Unit name: External pulse synchronizer (ext_pulse_sync_rtl)
--
--! @brief Synchronize an asnychronous external pulse to a clock
--!
--
--! @author Matthieu Cattin (matthieu dot cattin at cern dot ch)
--
--! @date 22\10\2009
--
--! @version v1.0
--
--! @details Latency = 5 clk_i ticks
--!
--! <b>Dependencies:</b>\n
--! utils_pkg.vhd
--!
--! <b>References:</b>\n
--!
--!
--! <b>Modified by:</b>\n
--! Author:
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! 22.10.2009    mcattin     Creation from pulse_sync_rtl.vhd
--! 27.10.2009    mcattin     Possibility for output monostable to be
--!                           retriggerable
--! 03.03.2011    mcattin     Input polarity from port instead of generic
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
--! Entity declaration for External pulse synchronizer
--=============================================================================
entity ext_pulse_sync is
  generic(
    g_MIN_PULSE_WIDTH : natural   := 2;      --! Minimum input pulse width
                                             --! (in ns), must be >1 clk_i tick
    g_CLK_FREQUENCY   : natural   := 40;     --! clk_i frequency (in MHz)
    g_OUTPUT_POLARITY : std_logic := '1';    --! pulse_o polarity
                                             --! (1=negative, 0=positive)
    g_OUTPUT_RETRIG   : boolean   := false;  --! Retriggerable output monostable
    g_OUTPUT_LENGTH   : natural   := 1       --! pulse_o lenght (in clk_i ticks)
    );
  port (
    rst_n_i          : in  std_logic;        --! Reset (active low)
    clk_i            : in  std_logic;        --! Clock to synchronize pulse
    input_polarity_i : in  std_logic;        --! Input pulse polarity (1=negative, 0=positive)
    pulse_i          : in  std_logic;        --! Asynchronous input pulse
    pulse_o          : out std_logic         --! Synchronized output pulse
    );
end entity ext_pulse_sync;


--=============================================================================
--! Architecture declaration External pulse synchronizer
--=============================================================================
architecture rtl of ext_pulse_sync is

  --! g_MIN_PULSE_WIDTH converted into clk_i ticks
  constant c_NB_TICKS : natural := 1 + to_integer(to_unsigned(g_MIN_PULSE_WIDTH, log2_ceil(g_MIN_PULSE_WIDTH))*
                                                  to_unsigned(g_CLK_FREQUENCY, log2_ceil(g_CLK_FREQUENCY))/
                                                  to_unsigned(1000, log2_ceil(1000)));
  --! FFs to synchronize input pulse
  signal s_pulse_sync_reg   : std_logic_vector(1 downto 0)                  := (others => '0');
  --! Pulse length counter
  signal s_pulse_length_cnt : unsigned(log2_ceil(c_NB_TICKS) downto 0)      := (others => '0');
  --! Output pulse monostable counter
  signal s_monostable_cnt   : unsigned(log2_ceil(g_OUTPUT_LENGTH) downto 0) := (others => '0');
  --! Pulse to start output monostable
  signal s_sync_pulse       : std_logic_vector(1 downto 0)                  := (others => '0');
  --! Output pulse for readback
  signal s_output_pulse     : std_logic                                     := '0';


--=============================================================================
--! Architecture begin
--=============================================================================
begin


--*****************************************************************************
-- Begin of p_pulse_sync
--! Process: Synchronise input pulse to clk_i clock
--*****************************************************************************
  p_pulse_sync : process(clk_i, rst_n_i)
  begin
    if rst_n_i = '0' then
      s_pulse_sync_reg <= (others => '0');
    elsif rising_edge(clk_i) then
      s_pulse_sync_reg <= s_pulse_sync_reg(0) & pulse_i;
    end if;
  end process p_pulse_sync;


--*****************************************************************************
-- Begin of p_pulse_length_cnt
--! Process: Counts input pulse length
--*****************************************************************************
  p_pulse_length_cnt : process(clk_i, rst_n_i)
  begin
    if rst_n_i = '0' then
      s_pulse_length_cnt <= (others => '0');
      s_sync_pulse(0)    <= '0';
    elsif rising_edge(clk_i) then
      if s_pulse_sync_reg(1) = input_polarity_i then
        s_pulse_length_cnt <= (others => '0');
        s_sync_pulse(0)    <= '0';
      elsif s_pulse_length_cnt = to_unsigned(c_NB_TICKS, s_pulse_length_cnt'length) then
        s_sync_pulse(0) <= '1';
      elsif s_pulse_sync_reg(1) = not(input_polarity_i) then
        s_pulse_length_cnt <= s_pulse_length_cnt + 1;
        s_sync_pulse(0)    <= '0';
      end if;
    end if;
  end process p_pulse_length_cnt;


--*****************************************************************************
-- Begin of p_start_pulse
--! Process: FF to generate monostable start pulse
--*****************************************************************************
  p_start_pulse : process (clk_i, rst_n_i)
  begin
    if rst_n_i = '0' then
      s_sync_pulse(1) <= '0';
    elsif rising_edge(clk_i) then
      s_sync_pulse(1) <= s_sync_pulse(0);
    end if;
  end process p_start_pulse;


--*****************************************************************************
-- Begin of p_monostable
--! Process: Monostable to generate output pulse
--*****************************************************************************
  p_monostable : process (clk_i, rst_n_i)
  begin
    if rst_n_i = '0' then
      s_monostable_cnt <= (others => '0');
      s_output_pulse   <= g_OUTPUT_POLARITY;
    elsif rising_edge(clk_i) then
      if ((not(g_OUTPUT_RETRIG) and ((s_sync_pulse(0) and not(s_sync_pulse(1))) = '1')
           and (s_output_pulse = g_OUTPUT_POLARITY))              -- non-retriggerable
          or (g_OUTPUT_RETRIG and (s_sync_pulse(0) = '1'))) then  -- retriggerable
        s_monostable_cnt <= to_unsigned(g_OUTPUT_LENGTH, s_monostable_cnt'length) - 1;
        s_output_pulse   <= not(g_OUTPUT_POLARITY);
      elsif s_monostable_cnt = to_unsigned(0, s_monostable_cnt'length) then
        s_output_pulse <= g_OUTPUT_POLARITY;
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
