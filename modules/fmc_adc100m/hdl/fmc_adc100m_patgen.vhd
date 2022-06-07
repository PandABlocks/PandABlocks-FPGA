--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : FMC-ADC-100M-14b4Cha on NAMC-ZYNQ-FMC board
-- Design name    : fmc_adc100m_patgen.vhd
-- Description    : test pattern generator for all ADC channels

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

library work;
use work.fmc_adc_types.all;

--------------------------------------------------------------------------------
-- Entity declaration
--------------------------------------------------------------------------------
entity fmc_adc100m_patgen is
  port (
    -- clock and reset
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- control inputs
    enable_i        : in  std_logic;
    -- data output (4 channels)
    data_ch_o       : out std16_array(1 to 4)
);
end fmc_adc100m_patgen;


architecture rtl of fmc_adc100m_patgen is

  signal ch_counter : unsigned(11 downto 0) := (others=>'0');

-- Begin of code
begin

  p_patgen : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if reset_i = '1' then
        ch_counter <= (others=>'0');
      elsif enable_i = '1' then
        ch_counter <= ch_counter + 1 ;
      end if;
    end if;
  end process p_patgen;

-- assign outputs
data_ch_o(1) <= x"1" & std_logic_vector(ch_counter);
data_ch_o(2) <= x"2" & std_logic_vector(ch_counter);
data_ch_o(3) <= x"3" & std_logic_vector(ch_counter);
data_ch_o(4) <= x"4" & std_logic_vector(ch_counter);


end rtl;
-- End of code
