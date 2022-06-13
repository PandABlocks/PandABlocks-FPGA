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
    adc_clk         : in  std_logic;
    adc_reset       : in  std_logic;
    -- Block parameters (in adc_clk domain)
    RESET           : in  std_logic;
    ENABLE          : in  std_logic;
    PERIOD          : in  std_logic_vector(31 downto 0);  -- Prescaler counter period (0 to 2**31-1)
    PERIOD_wstb     : in  std_logic;
    -- Block output (4 channels)
    data_ch_o       : out std16_array(1 to 4);
    pulse_o         : out std_logic
);
end fmc_adc100m_patgen;


----------------------------------------------------------------------------
--   PERIOD (dec)           PERIOD (hex)   : Period (sec)     FREQUENCY (Hz)
--  ------------------------------------------------------------------------
--              1  (1e0)    0x00000001         10   ns (MIN)  100  MHz
--             10  (1e1)    0x0000000A        100   ns        10   MHz
--            100  (1e2)    0x00000064          1   us        1    MHz
--          1 000  (1e3)    0x000003E8     :   10   us        100  kHz
--         10 000  (1e4)    0x00002710     :  100   us        10   kHz
--        100 000  (1e5)    0x000186A0     :    1   ms        1    kHz
--      1 000 000  (1e6)    0x000F4240     :   10   ms        100  Hz
--     10 000 000  (1e7)    0x00989680     :  100   ms        10   Hz
--     50 000 000  (5e7)    0x02FAF080     :  0,5   sec       2    Hz
--    100 000 000  (1e8)    0x05F5E100     :  1     sec       1    Hz
--    200 000 000  (2e8)    0x0BEBC200     :  2     sec       0.5  Hz
--    500 000 000  (5e8)    0x1DCD6500     :  5     sec       0.2  Hz
--  1 000 000 000  (1e9)    0x3B9ACA00     :  10    sec       0.1  Hz
--  2 147 483 647  (2^31-1) 0xFFFFFFFF     :  21,47 sec (MAX) 0.046 Hz
----------------------------------------------------------------------------


architecture rtl of fmc_adc100m_patgen is

  constant c_zero         : unsigned(31 downto 0) := x"00000000";
  constant c_one          : unsigned(31 downto 0) := x"00000001";

  signal PERIOD_new       : std_logic;
  signal PERIOD_rollover  : unsigned(31 downto 0);
  signal clk_count        : unsigned(31 downto 0);
  signal clk_pulse        : std_logic;

  signal ch_counter       : unsigned(11 downto 0) := (others=>'0');


-- Begin of code
begin


  -- Prescaler period
  p_prescaler_period : process(adc_clk)
  begin
    if rising_edge(adc_clk) then
      if adc_reset = '1' then
        PERIOD_rollover <= c_zero;
        PERIOD_new <= '0';
      else
        -- wait the end of Prescaler counter (clk_pulse= '1') before loading new PERIOD
        if PERIOD_wstb = '1' then
          PERIOD_new <= '1';
        elsif clk_pulse = '1' then
          PERIOD_new <= '0';
          if unsigned(PERIOD) = c_zero then
              PERIOD_rollover <= c_zero;
          else
              PERIOD_rollover <= unsigned(PERIOD)-1;
          end if;
        end if;
      end if;
    end if;
  end process p_prescaler_period;

  -- Prescaler counter
  p_prescaler_counter : process(adc_clk)
  begin
    if rising_edge(adc_clk) then
      if adc_reset = '1' then
        clk_count <= c_zero;
      else
        if (clk_pulse = '1') then
          clk_count <= c_zero;
        else
          clk_count <= clk_count + 1;
        end if;
      end if;
    end if;
  end process p_prescaler_counter;

  clk_pulse <= '1' when (clk_count = PERIOD_rollover) else '0';

  -- Pattern generator : simple counter
  p_patgen : process(adc_clk)
  begin
    if rising_edge(adc_clk) then
      if (adc_reset = '1' or RESET = '1') then
        ch_counter <= (others=>'0');
      elsif ENABLE = '1' then
        if clk_pulse = '1' then
          ch_counter <= ch_counter + 1 ;
        end if;
      end if;
    end if;
  end process p_patgen;

  -- assign outputs : set channel number on bits[31:28]
  data_ch_o(1) <= x"1" & std_logic_vector(ch_counter);
  data_ch_o(2) <= x"2" & std_logic_vector(ch_counter);
  data_ch_o(3) <= x"3" & std_logic_vector(ch_counter);
  data_ch_o(4) <= x"4" & std_logic_vector(ch_counter);

  pulse_o      <= clk_pulse;


end rtl;
-- End of code
