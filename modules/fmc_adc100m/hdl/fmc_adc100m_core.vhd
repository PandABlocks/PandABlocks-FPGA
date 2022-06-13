--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : FMC-ADC-100M-14b4Cha on NAMC-ZYNQ-FMC board
-- Design name    : fmc_adc100m_core.vhd
-- Description    : FMC ADC 100Ms/s core.
--                  Implements gain/offset correction on the adc deserialized
--                  data stream. The four channels data and the trigger signal
--                  are synchronized to sys_clk clock domain using a FIFO.
--                  The configuration registers coming from fmc_adc100m_ctrl
--                  block in the sys_clk domain are synchronized to the adc_clk
--                  domain using 2FFs chains synchronizers.
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

library work;
use work.fmc_adc_types.all;

--------------------------------------------------------------------------------
-- Entity declaration
--------------------------------------------------------------------------------
entity fmc_adc100m_core is
  generic(
    g_DEBUG_ILA           : boolean := FALSE
  );
  port (

    -- **********************************
    -- *** ADC clock domain (clk_div) ***
    -- **********************************
    -- ADC divided clock (100 MHz)
    adc_clk_i           : in  std_logic;
    adc_reset_i         : in  std_logic; -- reset synchronous to adc_clk (active high)
    -- ADC parallel data from SERDES (by channel array)
    adc_data_ch         : in  std16_array(1 to 4);

    -- IDELAYCTRL and SERDES statuts
    idelay_locked_i     : in  std_logic;
    serdes_synced_i     : in  std_logic;

    -- Configuration registers coming from fmc_adc100m_ctrl in the sys_clk domain
    -- are synchronized to the adc_clk domain using chains synchronizers.

    -- Gain/offset calibration parameters
    fmc_gain_ch         : in  fmc_gain_array(1 to 4);
    fmc_offset_ch       : in  fmc_offset_array(1 to 4);
    fmc_sat_ch          : in  fmc_sat_array(1 to 4);

    -- Pattern Generator
    PATGEN_ENABLE       : in  std_logic;
    PATGEN_RESET        : in  std_logic;
    PATGEN_PERIOD       : in  std_logic_vector(31 downto 0);
    PATGEN_PERIOD_wstb  : in  std_logic;
    -- FIFO input selection
    FIFO_INPUT_SEL      : in  std_logic_vector(1 downto 0);  -- "00" serdes "01" offset_gain "10" pattern_generator


    -- ************************
    -- *** SYS clock domain ***
    -- ************************
    -- System clock and reset from PS core (125 mhz)
    sys_clk_i           : in  std_logic;
    sys_reset_i         : in  std_logic;

    -- FIFO status

    -- FMC data output (sys_clk domain)
    -- 4 Channels of ADC Dataout for connection to Position Bus
    fmc_dataout_o       : out fmc_dataout_array(1 to 4);
    fmc_dataout_valid_o : out std1_array(1 to 4)

);
end fmc_adc100m_core;


architecture rtl of fmc_adc100m_core is

  ------------------------------------------------------------------------------
  -- Attributes used for Vivado tool flow
  ------------------------------------------------------------------------------
  attribute async_reg   : string; -- synchronizing register within a synchronization chain
  attribute keep        : string; -- keep name for ila probes

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------
  -- adc_clk clock domain
  signal patgen_data_ch       : std16_array(1 to 4);

  signal adc_data_ch_calib    : std16_array(1 to 4);
  signal adc_fifo_din         : std16_array(1 to 4);
  signal adc_fifo_wr_en       : std1_array(1 to 4);
  signal adc_fifo_full        : std1_array(1 to 4);

  -- sys_clk clock domain
  signal fmc_fifo_rd_en       : std1_array(1 to 4);
  signal fmc_fifo_empty       : std1_array(1 to 4);
  signal fmc_fifo_rd_count    : std8_array(1 to 4);

  signal fmc_fifo_dout        : fmc_dataout_array(1 to 4);
  signal fmc_fifo_rd_valid    : std1_array(1 to 4);


  -- Attributes for ILA

-- Begin of code
begin

  ------------------------------------------------------
  -- pattern generator instanciation (adc_clk domain)
  ------------------------------------------------------
  cmp_fmc_adc100m_patgen : entity work.fmc_adc100m_patgen
  port map (
    -- clock and reset
    adc_clk       => adc_clk_i,
    adc_reset     => adc_reset_i,
    -- Block parameters
    RESET         => PATGEN_RESET,
    ENABLE        => PATGEN_ENABLE,
    PERIOD        => PATGEN_PERIOD,
    PERIOD_wstb   => PATGEN_PERIOD_wstb,
    -- data output (4 channels)
    data_ch_o     => patgen_data_ch,
    pulse_o       => open
  );


 ------------------------------------------------------------------------------
  -- Offset and gain calibration (adc_clk domain)
  ------------------------------------------------------------------------------
  -- Offset and gain correction, signed data input and output (two's complement)

  gen_offset_gain_corr : for i in 1 to C_ADC_CHANNELS generate
      cmp_fmc_offset_gain : entity work.fmc_adc_offset_gain
      port map(
        -- synchronous clock and reset
        clk_i     => adc_clk_i,
        rst_i     => adc_reset_i,
        -- parameters (must be synchronous to clk_i)
        offset_i  => fmc_offset_ch(i),                 --  in  (15:0)  Signed offset input (two's complement)
        gain_i    => fmc_gain_ch(i),                   --  in  (15:0)  Unsigned gain input
        sat_i     => fmc_sat_ch(i),                    --  in  (14:0)  Unsigned saturation value input
        -- adc data in/out                             --
        data_i    => adc_data_ch(i),                   --  in  (15:0)  Signed data input (two's complement)
        data_o    => adc_data_ch_calib(i)              --  out (15:0)  Signed data output (two's complement)
        );                                             --
  end generate gen_offset_gain_corr;


  ------------------------------------------------------------------------------
  -- FIFO data_in mux process
  -- Choice between SERDES, Offset_Gain and Pattern Generator outputs
  ------------------------------------------------------------------------------
  p_fifo_din_mux : process(adc_clk_i)
  begin
      if rising_edge(adc_clk_i) then
        -- "00" serdes "01" offset_gain "10" pattern_generator
        case FIFO_INPUT_SEL is
          when "00"   => adc_fifo_din <= adc_data_ch;         -- SERDES output
          when "01"   => adc_fifo_din <= adc_data_ch_calib;   -- Offset_Gain output
          when "10"   => adc_fifo_din <= patgen_data_ch;      -- Pattern Generator output
          when others => adc_fifo_din <= adc_data_ch;         -- SERDES output
        end case;
      end if;
  end process p_fifo_din_mux;


  ------------------------------------------------------------------------------
  -- Synchronisation FIFO to system clock domain
  ------------------------------------------------------------------------------
  -- ADC Buffer FIFO using Xilinx IP Module
  -- Type : independant clock block RAM
  -- data width : 16 / depth : 256
  -- Read Latency : 1

  gen_fmc_adc_ch_fifo : for i in 1 to C_ADC_CHANNELS generate
  begin

  -- FIFO write control
    p_fifo_write : process(adc_clk_i)
    begin
        if rising_edge(adc_clk_i) then
          if adc_reset_i = '1' then
            adc_fifo_wr_en(i) <= '0';
          else
            adc_fifo_wr_en(i) <= idelay_locked_i and serdes_synced_i;
          end if;
        end if;
    end process;

    -- FIFO instance
    cmp_fmc_ch_fifo : entity work.fmc_adc100m_ch_fifo
      port map (
          rst           => sys_reset_i,             -- in
          -- write side (adc_clk)
          wr_clk        => adc_clk_i,               -- in
          wr_en         => adc_fifo_wr_en(i),       -- in
          din           => adc_fifo_din(i),          -- in (15:0)    adc_data_ch_calib(i)
          full          => adc_fifo_full(i),        -- out
            -- read side (sys_clk)
          rd_clk        => sys_clk_i,               -- in
          rd_en         => fmc_fifo_rd_en(i),       -- in
          dout          => fmc_fifo_dout(i),        -- out (15:0)
          empty         => fmc_fifo_empty(i),       -- out
          rd_data_count => fmc_fifo_rd_count(i)     -- out (7:0)
      );


    -- FIFO read control
    fmc_fifo_rd_en(i) <= '1' when (fmc_fifo_rd_count(i) >= x"01" and fmc_fifo_empty(i) = '0') else '0';

    p_fifo_read : process(sys_clk_i)
    begin
        if rising_edge(sys_clk_i) then
          -- FIFO read latency = 1 clk
          fmc_fifo_rd_valid(i) <= fmc_fifo_rd_en(i);
          -- FIFO read control
--++      if fmc_fifo_rd_count(i) >= x"01" and fmc_fifo_empty(i) = '0' then
--++          fmc_fifo_rd_en(i) <= '1';
--++      else
--++          fmc_fifo_rd_en(i) <= '0';
--++      end if;
      end if;
    end process p_fifo_read;

  end generate gen_fmc_adc_ch_fifo;

  -- assign outputs
  fmc_dataout_o        <= fmc_fifo_dout;
  fmc_dataout_valid_o  <= fmc_fifo_rd_valid;


end rtl;
-- End of code







