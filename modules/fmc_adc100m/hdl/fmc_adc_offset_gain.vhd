--------------------------------------------------------------------------------
--  PandA Motion Project - 2022
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
-- Unit name   : fmc_adc_offset_gain (fmc_adc_offset_gain.vhd)
-- Description : Offset and gain correction with configurable saturation.
--               Input and output are signed.
--               Latency = 4
--
--                           ___               ___           ________
--  ADC raw data            |   | offset_data |   | product |        |
--              data_i ---->| + |------------>| X |-------->|saturate|--> data_o
--  16-bit signed           |___|             |___|         |________|
--                            ^                 ^               ^
--                            |                 |               |
--                         offset_i           gain_i          sat_i
--                         16 bits             16 bits        15 bits
--                         signed           fixed point      unsigned
--
--------------------------------------------------------------------------------
-- Copyright (c) 2022 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CERN (BE-CO-HT)
-- Offset and gain correction, signed data input and output (two's complement)
-- http://www.ohwr.org/projects/fmc-adc-100m14b4cha
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- library UNISIM;
-- use UNISIM.vcomponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

------------------------------------------------------------------------------
-- Entity declaration
------------------------------------------------------------------------------
entity fmc_adc_offset_gain is
  port (
    -- synchronous clock and reset
    clk_i    : in  std_logic;                      -- Clock
    rst_i    : in  std_logic;                      -- Synchronous Reset (active high)
    -- parameters (must be synchronous to clk_i)
    offset_i : in  std_logic_vector(15 downto 0);  -- 16-bit signed offset input (two's complement)
    gain_i   : in  std_logic_vector(15 downto 0);  -- 16-bit unsigned gain input (fixed-point)
    sat_i    : in  std_logic_vector(14 downto 0);  -- 15-bit unsigned saturation value input
    -- adc data in/out
    data_i   : in  std_logic_vector(15 downto 0);  -- Signed data input (two's complement)
    data_o   : out std_logic_vector(15 downto 0)   -- Signed data output (two's complement)
    );
end entity fmc_adc_offset_gain;


------------------------------------------------------------------------------
-- Architecture declaration
------------------------------------------------------------------------------
architecture rtl of fmc_adc_offset_gain is

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  constant c_one            : signed(16 downto 0) := to_signed(1, 17);
  constant c_mult_latency   : natural := 1 ;

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------
  --signal data_in_d   : std_logic_vector(15 downto 0) := (others => '0');
  signal data_r1      : std_logic_vector(17 downto 0) := (others => '0'); -- data + offset
  signal gain_r1      : std_logic_vector(17 downto 0) := (others => '0');
  signal product_r2   : std_logic_vector(35 downto 0) := (others => '0');
  signal product_r3   : std_logic_vector(16 downto 0);
  signal pos_sat      : signed(16 downto 0);
  signal neg_sat      : signed(16 downto 0);
  signal data_sat     : std_logic_vector(15 downto 0);

-- Begin of code
begin

  ------------------------------------------------------------------------------
  -- Add offset to input data
  -- data_r1 = signed(data_)i + signed)offset)
  -- gain_r1 = unsigned(gain_i)
  ------------------------------------------------------------------------------
  p_offset : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        data_r1 <= (others => '0');
        gain_r1 <= (others => '0');
      else
        -- propagate sign for signed offset_i
        data_r1 <= std_logic_vector(signed(data_i(15) & data_i(15) & data_i) +
                                        signed(offset_i(15) & offset_i(15) & offset_i));
        gain_r1 <= "00" & gain_i;
      end if;
    end if;
  end process p_offset;


  ------------------------------------------------------------------------------
  -- Multiple input data + offset by gain
  ------------------------------------------------------------------------------
  -- MULT_MACRO: Multiply Function implemented in a DSP48E
  --             7 Series
  -- Xilinx HDL Language Template, version 2020.1
  ------------------------------------------------------------------------------
  cmp_multiplier : MULT_MACRO
    generic map (
      DEVICE  => "7SERIES",             -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
      LATENCY => c_mult_latency,        -- Desired clock cycle latency, 0-4
      WIDTH_A => 18,                    -- Multiplier A-input bus width, 1-25
      WIDTH_B => 18)                    -- Multiplier B-input bus width, 1-18
    port map (
      CE  => '1',                       -- 1-bit active high input clock enable
      CLK => clk_i,                     -- 1-bit positive edge clock input
      RST => rst_i,                     -- 1-bit input active high synchronous reset
      A   => gain_r1,                   -- Multiplier input A, WIDTH_A
      B   => data_r1,                   -- Multiplier input B, WIDTH_B
      P   => product_r2                 -- Multiplier ouput, WIDTH_A+WIDTH_B
      );


  -- Additional register stage to solve timing issues
  p_pipeline : process (clk_i)
  begin
    if rising_edge(clk_i) then
        product_r3 <= product_r2(31 downto 15);
    end if;
  end process p_pipeline;

  ------------------------------------------------------------------------------
  -- Saturate addition and multiplication result
  ------------------------------------------------------------------------------
  pos_sat <= signed("00" & sat_i);
  neg_sat <= signed(not(pos_sat)) + c_one;

  p_saturate : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        data_sat <= (others => '0');
      elsif signed(product_r3) >= pos_sat then
        data_sat <= std_logic_vector(pos_sat(15 downto 0));  -- saturate positive
      elsif signed(product_r3) <= neg_sat then
        data_sat <= std_logic_vector(neg_sat(15 downto 0));  -- saturate negative
      else
        data_sat <= product_r3(15 downto 0);
      end if;
    end if;
  end process p_saturate;

  -- connect output
  data_o <= data_sat;

end rtl;
-- End of code

