--------------------------------------------------------------------------------
-- CERN (BE-CO-HT)
-- FMC ADC 100Ms/s core
-- http://www.ohwr.org/projects/fmc-adc-100m14b4cha
--------------------------------------------------------------------------------
--
-- unit name: fmc_adc100Ms_core (fmc_adc100Ms_core.vhd)
--
-- author: Matthieu Cattin (matthieu.cattin@cern.ch)
--         Theodor Stana (t.stana@cern.ch)
--
-- date: 28-02-2011
--
-- description: FMC ADC 100Ms/s core.
--
-- dependencies:
--
-- references:
--    [1] Xilinx UG175. FIFO Generator v6.2, July 23, 2010
--
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
-- last changes: see git log.
--------------------------------------------------------------------------------
-- TODO: - 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
--use work.timetag_core_pkg.all;
use work.genram_pkg.all;
use work.gencores_pkg.all;


entity fmc_adc100Ms_core is
  generic(
    g_multishot_ram_size : natural := 128 --512;--1024;--2048;
    );
  port (
    -- Clock, reset
    sys_clk_i   : in std_logic;
    sys_rst_n_i : in std_logic;

    -- DDR wishbone interface
    wb_ddr_clk_i   : in  std_logic;
    wb_ddr_dat_o   : out std_logic_vector(63 downto 0);

    -- Events output pulses
    trigger_p_o   : out std_logic;
    acq_start_p_o : out std_logic;
    acq_stop_p_o  : out std_logic;
    acq_end_p_o   : out std_logic;

    -- FMC interface
    ext_trigger_p_i : in std_logic;     -- External trigger
    ext_trigger_n_i : in std_logic;

    adc_dco_p_i  : in std_logic;                     -- ADC data clock
    adc_dco_n_i  : in std_logic;
    adc_fr_p_i   : in std_logic;                     -- ADC frame start
    adc_fr_n_i   : in std_logic;
    adc_outa_p_i : in std_logic_vector(3 downto 0);  -- ADC serial data (odd bits)
    adc_outa_n_i : in std_logic_vector(3 downto 0);
    adc_outb_p_i : in std_logic_vector(3 downto 0);  -- ADC serial data (even bits)
    adc_outb_n_i : in std_logic_vector(3 downto 0);

    gpio_dac_clr_n_o : out std_logic;                     -- offset DACs clear (active low)
    gpio_led_acq_o   : out std_logic;                     -- Mezzanine front panel power LED (PWR)
    gpio_led_trig_o  : out std_logic;                     -- Mezzanine front panel trigger LED (TRIG)
    gpio_si570_oe_o  : out std_logic;                     -- Si570 (programmable oscillator) output enable


    -- Control and Status register
    fsm_cmd_i    : in std_logic_vector(1 downto 0); -- "01" acq_start / "10" acq_stop
    fsm_cmd_wstb : in std_logic;
    fmc_clk_oe   : in std_logic;                    -- enable Si570 programme oscillator

    fmc_adc_core_ctl_offset_dac_clr_n_o : in std_logic;
    fmc_adc_core_ctl_test_data_en_o     : in std_logic;
    fmc_adc_core_ctl_man_bitslip_o      : in std_logic;
    
    -- Port for std_logic_vector field: 'State machine status' in reg: 'Status register'
    fmc_adc_core_sta_fsm_i              : out std_logic_vector(2 downto 0);
    -- Port for BIT field: 'SerDes PLL status' in reg: 'Status register'
    fmc_adc_core_sta_serdes_pll_i       : out std_logic;
    -- Port for BIT field: 'SerDes synchronization status' in reg: 'Status register'
    fmc_adc_core_sta_serdes_synced_i    : out std_logic;
    -- Port for BIT field: 'Acquisition configuration status' in reg: 'Status register'
    fmc_adc_core_sta_acq_cfg_i          : out std_logic;
    ---- Port for asynchronous (clock: fs_clk_i) BIT field: 'Hardware trigger selection' in reg: 'Trigger configuration'
    fmc_adc_core_trig_cfg_hw_trig_sel_o      : in  std_logic;
    ---- Port for asynchronous (clock: fs_clk_i) BIT field: 'Hardware trigger polarity' in reg: 'Trigger configuration'
    fmc_adc_core_trig_cfg_hw_trig_pol_o      : in  std_logic;
    ---- Port for asynchronous (clock: fs_clk_i) BIT field: 'Hardware trigger enable' in reg: 'Trigger configuration'
    fmc_adc_core_trig_cfg_hw_trig_en_o       : in  std_logic;
    ---- Port for asynchronous (clock: fs_clk_i) BIT field: 'Software trigger enable' in reg: 'Trigger configuration'
    fmc_adc_core_trig_cfg_sw_trig_en_o       : in  std_logic;
    ---- Port for asynchronous (clock: fs_clk_i) std_logic_vector field: 'Channel selection for internal trigger' in reg: 'Trigger configuration'
    fmc_adc_core_trig_cfg_int_trig_sel_o     : in  std_logic_vector(1 downto 0);
    ---- Port for asynchronous (clock: fs_clk_i) BIT field: 'Enable internal trigger test mode' in reg: 'Trigger configuration'
    fmc_adc_core_trig_cfg_int_trig_test_en_o : in  std_logic;
    ---- Port for BIT field: 'Reserved' in reg: 'Trigger configuration'
    --fmc_adc_core_trig_cfg_reserved_o         : out    std_logic;
    ---- Port for asynchronous (clock: fs_clk_i) std_logic_vector field: 'Internal trigger threshold glitch filter' in reg: 'Trigger configuration'
    fmc_adc_core_trig_cfg_int_trig_thres_filt_o : in  std_logic_vector(7 downto 0);
    ---- Port for asynchronous (clock: fs_clk_i) std_logic_vector field: 'Threshold for internal trigger' in reg: 'Trigger configuration'
    fmc_adc_core_trig_cfg_int_trig_thres_o   : in  std_logic_vector(15 downto 0);
    ---- Port for std_logic_vector field: 'Trigger delay value' in reg: 'Trigger delay'
    fmc_adc_core_trig_dly_o                  : in  std_logic_vector(31 downto 0);
    ---- Ports for asynchronous (clock: fs_clk_i) PASS_THROUGH field: 'Software trigger (ignore on read)' in reg: 'Software trigger'
    --fmc_adc_core_sw_trig_o                   : out    std_logic_vector(31 downto 0);
    fmc_adc_core_sw_trig_wr_o                : in  std_logic;
    ---- Port for std_logic_vector field: 'Number of shots' in reg: 'Number of shots'
    fmc_adc_core_shots_nb_o                  : in  std_logic_vector(15 downto 0);
    ---- Port for std_logic_vector field: 'Remaining shots counter' in reg: 'Remaining shots counter'
    fmc_adc_core_shots_cnt_val_i             : out std_logic_vector(15 downto 0);
    ---- Port for std_logic_vector field: 'Trigger address' in reg: 'Trigger address register'
    --fmc_adc_core_trig_pos_i                  : in     std_logic_vector(31 downto 0);
    ---- Port for asynchronous (clock: fs_clk_i) std_logic_vector field: 'Sampling clock frequency' in reg: 'Sampling clock frequency'
    fmc_adc_core_fs_freq_i                   : out std_logic_vector(31 downto 0);
    ---- Port for asynchronous (clock: fs_clk_i) std_logic_vector field: 'Sample rate decimation' in reg: 'Sample rate'
    fmc_adc_core_sr_deci_o                   : in  std_logic_vector(31 downto 0);
    ---- Port for std_logic_vector field: 'Pre-trigger samples' in reg: 'Pre-trigger samples'
    fmc_adc_core_pre_samples_o               : in  std_logic_vector(31 downto 0);
    ---- Port for std_logic_vector field: 'Post-trigger samples' in reg: 'Post-trigger samples'
    fmc_adc_core_post_samples_o              : in  std_logic_vector(31 downto 0);
    ---- Port for std_logic_vector field: 'Samples counter' in reg: 'Samples counter'
    fmc_adc_core_samples_cnt_i               : out std_logic_vector(31 downto 0);
    
    fmc_single_shot               : out std_logic;
    fmc_fifo_empty                : out std_logic;
    
    fifo_wr_cnt                   : out std_logic_vector(31 downto 0);
    wait_cnt                      : out std_logic_vector(31 downto 0);
    pre_trig_count                : out std_logic_vector(31 downto 0);
        -- Channel1 register
    fmc_adc_core_ch1_sta_val_i    : out std_logic_vector(15 downto 0);
    fmc_adc_core_ch1_gain_val_o   : in  std_logic_vector(15 downto 0);
    fmc_adc_core_ch1_offset_val_o : in  std_logic_vector(15 downto 0);
    fmc_adc_core_ch1_sat_val_o    : in  std_logic_vector(14 downto 0);
        -- Channel2 register
    fmc_adc_core_ch2_sta_val_i    : out std_logic_vector(15 downto 0);
    fmc_adc_core_ch2_gain_val_o   : in  std_logic_vector(15 downto 0);
    fmc_adc_core_ch2_offset_val_o : in  std_logic_vector(15 downto 0);
    fmc_adc_core_ch2_sat_val_o    : in  std_logic_vector(14 downto 0);
        -- Channel3 register
    fmc_adc_core_ch3_sta_val_i    : out std_logic_vector(15 downto 0);
    fmc_adc_core_ch3_gain_val_o   : in  std_logic_vector(15 downto 0);
    fmc_adc_core_ch3_offset_val_o : in  std_logic_vector(15 downto 0);
    fmc_adc_core_ch3_sat_val_o    : in  std_logic_vector(14 downto 0);
        -- Channel4 register
    fmc_adc_core_ch4_sta_val_i    : out std_logic_vector(15 downto 0);
    fmc_adc_core_ch4_gain_val_o   : in  std_logic_vector(15 downto 0);
    fmc_adc_core_ch4_offset_val_o : in  std_logic_vector(15 downto 0);
    fmc_adc_core_ch4_sat_val_o    : in  std_logic_vector(14 downto 0)    
    );
end fmc_adc100Ms_core;


architecture rtl of fmc_adc100Ms_core is


  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------

  component adc_serdes
    generic
      (
        sys_w : integer := 9;                 -- width of the data for the system
        dev_w : integer := 72                 -- width of the data for the device
        );
    port
      (
        -- Datapath
        DATA_IN_FROM_PINS_P : in  std_logic_vector(sys_w-1 downto 0);
        DATA_IN_FROM_PINS_N : in  std_logic_vector(sys_w-1 downto 0);
        DATA_IN_TO_DEVICE   : out std_logic_vector(dev_w-1 downto 0);
        -- Data control
        BITSLIP             : in  std_logic;
        -- Clock and reset signals
        CLK_IN              : in  std_logic;  -- Fast clock from PLL/MMCM
        --CLK_OUT             : out std_logic;
        CLK_DIV_IN          : in  std_logic;  -- Slow clock from PLL/MMCM
        LOCKED_IN           : in  std_logic;
        --LOCKED_OUT          : out std_logic;
        CLK_RESET           : in  std_logic;  -- Reset signal for Clock circuit
        IO_RESET            : in  std_logic   -- Reset signal for IO circuit
        );
  end component adc_serdes;

  component ext_pulse_sync
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
  end component ext_pulse_sync;

  component offset_gain_s
    port (
      rst_n_i  : in  std_logic;                      --! Reset (active low)
      clk_i    : in  std_logic;                      --! Clock
      offset_i : in  std_logic_vector(15 downto 0);  --! Signed offset input (two's complement)
      gain_i   : in  std_logic_vector(15 downto 0);  --! Unsigned gain input
      sat_i    : in  std_logic_vector(14 downto 0);  --! Unsigned saturation value input
      data_i   : in  std_logic_vector(15 downto 0);  --! Signed data input (two's complement)
      data_o   : out std_logic_vector(15 downto 0)   --! Signed data output (two's complement)
      );
  end component offset_gain_s;

  component monostable
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
  end component monostable;

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  constant c_dpram_depth : integer := f_log2_size(g_multishot_ram_size);
  constant DEBUG_ILA     : string  := "FALSE";         
  ------------------------------------------------------------------------------
  -- Types declaration
  ------------------------------------------------------------------------------
  type t_acq_fsm_state is (IDLE, PRE_TRIG, WAIT_TRIG, POST_TRIG, TRIG_TAG, DECR_SHOT);
  type t_data_pipe is array (natural range<>) of std_logic_vector(63 downto 0);

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------

  -- Reset
  signal sys_rst     : std_logic;
  signal fs_rst      : std_logic;
  signal fs_rst_n    : std_logic;

  -- Clocks and PLL
  signal dco_clk       : std_logic;
  signal dco_clk_buf   : std_logic;
  signal clk_fb        : std_logic;
  signal clk_fb_buf    : std_logic;
  signal locked_in     : std_logic;
  signal locked_out    : std_logic;
  signal serdes_clk    : std_logic;
  signal serdes_clk_buf: std_logic;
  signal fs_clk        : std_logic;
  signal fs_clk_buf    : std_logic;
  signal clk_fb_in     : std_logic;
  signal clk_fb_out    : std_logic;
  signal fs_freq       : std_logic_vector(31 downto 0);
  signal fs_freq_t     : std_logic_vector(31 downto 0);
  signal fs_freq_valid : std_logic;

  -- SerDes
  signal serdes_in_p         : std_logic_vector(8 downto 0);
  signal serdes_in_n         : std_logic_vector(8 downto 0);
  signal serdes_out_raw      : std_logic_vector(71 downto 0);
  signal serdes_out_data     : std_logic_vector(63 downto 0);
  signal serdes_out_fr       : std_logic_vector(7 downto 0);
  signal serdes_auto_bitslip : std_logic;
  signal serdes_man_bitslip  : std_logic;
  signal serdes_bitslip      : std_logic;
  signal serdes_synced       : std_logic;
  signal bitslip_sreg        : std_logic_vector(7 downto 0);
  
  signal fmc_adc_core_ctl_man_bitslip_sync0 : std_logic;
  signal fmc_adc_core_ctl_man_bitslip_sync1 : std_logic;
  signal fmc_adc_core_ctl_man_bitslip_sync2 : std_logic;

  -- Trigger
  signal ext_trig_a                 : std_logic;
  signal ext_trig                   : std_logic;
  signal int_trig                   : std_logic;
  signal int_trig_over_thres        : std_logic;
  signal int_trig_over_thres_d      : std_logic;
  signal int_trig_over_thres_filt   : std_logic;
  signal int_trig_over_thres_filt_d : std_logic;
  signal int_trig_sel               : std_logic_vector(1 downto 0);
  signal int_trig_data              : std_logic_vector(15 downto 0);
  signal int_trig_thres             : std_logic_vector(15 downto 0);
  signal int_trig_test_en           : std_logic;
  signal int_trig_thres_filt        : std_logic_vector(7 downto 0);
  signal hw_trig_pol                : std_logic;
  signal hw_trig                    : std_logic;
  signal hw_trig_t                  : std_logic;
  signal hw_trig_sel                : std_logic;
  signal hw_trig_en                 : std_logic;
  signal sw_trig                    : std_logic;
  signal sw_trig_t                  : std_logic;
  signal sw_trig_en                 : std_logic;
  signal trig                       : std_logic;
  signal trig_delay                 : std_logic_vector(31 downto 0);
  signal trig_delay_cnt             : unsigned(31 downto 0);
  signal trig_d                     : std_logic;
  signal trig_align                 : std_logic;

  -- Internal trigger test mode
  signal int_trig_over_thres_tst      : std_logic_vector(15 downto 0);
  signal int_trig_over_thres_filt_tst : std_logic_vector(15 downto 0);
  signal trig_tst                     : std_logic_vector(15 downto 0);

  -- Decimation
  signal decim_factor : std_logic_vector(31 downto 0);
  signal decim_cnt    : unsigned(31 downto 0);
  signal decim_en     : std_logic;

  -- Sync FIFO (from fs_clk to sys_clk_i)
  signal sync_fifo_din   : std_logic_vector(64 downto 0);
  signal sync_fifo_dout  : std_logic_vector(64 downto 0);
  signal sync_fifo_empty : std_logic;
  signal sync_fifo_full  : std_logic;
  signal sync_fifo_wr    : std_logic;
  signal sync_fifo_rd    : std_logic;
  signal sync_fifo_valid : std_logic;

  -- Gain/offset calibration and saturation value
  signal gain_calibr       : std_logic_vector(63 downto 0);
  signal offset_calibr     : std_logic_vector(63 downto 0);
  signal data_calibr_in    : std_logic_vector(63 downto 0);
  signal data_calibr_out   : std_logic_vector(63 downto 0);
  signal data_calibr_out_t : std_logic_vector(63 downto 0);
  signal data_calibr_out_d : t_data_pipe(3 downto 0);
  signal sat_val           : std_logic_vector(59 downto 0);

  -- Acquisition FSM
  signal acq_fsm_current_state : t_acq_fsm_state;
  signal acq_fsm_state         : std_logic_vector(2 downto 0);
  signal fsm_cmd               : std_logic_vector(1 downto 0);
  signal fsm_cmd_wr            : std_logic;
  signal acq_start             : std_logic;
  signal acq_stop              : std_logic;
  signal acq_trig              : std_logic;
  signal acq_end               : std_logic;
  signal acq_end_d             : std_logic;
  signal acq_in_pre_trig       : std_logic;
  signal acq_in_wait_trig      : std_logic;
  signal acq_in_post_trig      : std_logic;
  signal acq_in_trig_tag       : std_logic;
  signal acq_in_trig_tag_d     : std_logic;
  signal samples_wr_en         : std_logic;
  signal acq_config_ok         : std_logic;

  -- Trigger tag insertion in data
  signal trig_tag_done : std_logic;
  signal trig_tag_data : std_logic_vector(63 downto 0);

  -- pre/post trigger and shots counters
  signal pre_trig_value       : std_logic_vector(31 downto 0);
  signal pre_trig_cnt         : unsigned(31 downto 0);
  signal pre_trig_done        : std_logic;
  signal post_trig_value      : std_logic_vector(31 downto 0);
  signal post_trig_cnt        : unsigned(31 downto 0);
  signal post_trig_done       : std_logic;
  signal samples_cnt          : unsigned(31 downto 0);
  signal shots_value          : std_logic_vector(15 downto 0);
  signal shots_cnt            : unsigned(15 downto 0);
  signal serdes_count         : unsigned(31 downto 0);
  signal fifo_wr              : unsigned(31 downto 0);
  signal wait_count           : unsigned(31 downto 0);
  signal remaining_shots      : std_logic_vector(15 downto 0);
  signal shots_done           : std_logic;
  signal shots_decr           : std_logic;
  signal single_shot          : std_logic;
  signal multishot_buffer_sel : std_logic;

  -- Multi-shot mode
  signal dpram_addra_cnt       : unsigned(c_dpram_depth-1 downto 0);
  signal dpram_addra_trig      : unsigned(c_dpram_depth-1 downto 0);
  signal dpram_addra_post_done : unsigned(c_dpram_depth-1 downto 0);
  signal dpram_addrb_cnt       : unsigned(c_dpram_depth-1 downto 0);
  signal dpram_dout            : std_logic_vector(63 downto 0);
  signal dpram_valid           : std_logic;
  signal dpram_valid_t         : std_logic;

  signal dpram0_dina  : std_logic_vector(63 downto 0);
  signal dpram0_addra : std_logic_vector(c_dpram_depth-1 downto 0);
  signal dpram0_wea   : std_logic;
  signal dpram0_addrb : std_logic_vector(c_dpram_depth-1 downto 0);
  signal dpram0_doutb : std_logic_vector(63 downto 0);

  signal dpram1_dina  : std_logic_vector(63 downto 0);
  signal dpram1_addra : std_logic_vector(c_dpram_depth-1 downto 0);
  signal dpram1_wea   : std_logic;
  signal dpram1_addrb : std_logic_vector(c_dpram_depth-1 downto 0);
  signal dpram1_doutb : std_logic_vector(63 downto 0);

  -- Wishbone to DDR flowcontrol FIFO
  signal wb_ddr_fifo_din   : std_logic_vector(64 downto 0);
  signal wb_ddr_fifo_dout  : std_logic_vector(64 downto 0);
  signal wb_ddr_fifo_empty : std_logic;
  signal wb_ddr_fifo_full  : std_logic;
  signal wb_ddr_fifo_wr    : std_logic;
  signal wb_ddr_fifo_rd    : std_logic;
  signal wb_ddr_fifo_valid : std_logic;
  signal wb_ddr_fifo_dreq  : std_logic;
  signal wb_ddr_fifo_wr_en : std_logic;

  -- RAM address counter
  signal ram_addr_cnt : unsigned(24 downto 0);
  signal test_data_en : std_logic;
  signal trig_addr    : std_logic_vector(31 downto 0);
  signal mem_ovr      : std_logic;

  -- Wishbone interface to DDR
  signal wb_ddr_stall_t : std_logic;

  -- LEDs
  signal trig_led     : std_logic;
  signal trig_led_man : std_logic;
  signal acq_led      : std_logic;
  signal acq_led_man  : std_logic;
  
  signal CLR          : std_logic;
  
  -- CHIPSCOPE ILA probes
  signal probe0               : std_logic_vector(31 downto 0);
  signal probe1               : std_logic_vector(31 downto 0);
  signal probe2               : std_logic_vector(31 downto 0);
  signal probe3               : std_logic_vector(31 downto 0);
  -- signal probe4               : std_logic_vector(31 downto 0);
  
  attribute keep : string;--keep name for ila probes
  attribute keep of serdes_synced    : signal is "true";
  attribute keep of serdes_out_fr    : signal is "true";
  
  attribute keep of sync_fifo_valid  : signal is "true";
  attribute keep of sync_fifo_empty  : signal is "true";
  attribute keep of sync_fifo_wr     : signal is "true";
  attribute keep of pre_trig_cnt     : signal is "true";
  attribute keep of acq_in_pre_trig  : signal is "true";
  attribute keep of pre_trig_done    : signal is "true";
  attribute keep of acq_start        : signal is "true";
  attribute keep of fsm_cmd          : signal is "true";
  attribute keep of sw_trig          : signal is "true";
  attribute keep of sys_rst_n_i      : signal is "true";
  attribute keep of sync_fifo_din    : signal is "true";
  attribute keep of serdes_out_data  : signal is "true";
  attribute keep of acq_fsm_state    : signal is "true";
  attribute keep of acq_config_ok    : signal is "true";
  attribute keep of adc_outa_p_i     : signal is "true";
  attribute keep of adc_outa_n_i     : signal is "true";
  attribute keep of adc_outb_p_i     : signal is "true";
  attribute keep of adc_outb_n_i     : signal is "true";
  

begin


  ------------------------------------------------------------------------------
  -- LEDs
  ------------------------------------------------------------------------------
  cmp_acq_led_monostable : monostable
    generic map(
      g_INPUT_POLARITY  => '1',
      g_OUTPUT_POLARITY => '1',
      g_OUTPUT_RETRIG   => true,
      g_OUTPUT_LENGTH   => 12500000
      )
    port map(
      rst_n_i   => sys_rst_n_i,
      clk_i     => sys_clk_i,
      trigger_i => samples_wr_en,
      pulse_o   => acq_led
      );

  gpio_led_acq_o <= acq_led or acq_led_man;-- or (fsm_cmd_i when fsm_cmd_i="01");

  cmp_trig_led_monostable : monostable
    generic map(
      g_INPUT_POLARITY  => '1',
      g_OUTPUT_POLARITY => '1',
      g_OUTPUT_RETRIG   => true,
      g_OUTPUT_LENGTH   => 12500000
      )
    port map(
      rst_n_i   => sys_rst_n_i,
      clk_i     => sys_clk_i,
      trigger_i => acq_trig,
      pulse_o   => trig_led
      );

  gpio_led_trig_o <= trig_led or trig_led_man or fsm_cmd_wr;

  ------------------------------------------------------------------------------
  -- Resets
  ------------------------------------------------------------------------------
  sys_rst  <= not(sys_rst_n_i);
  fs_rst_n <= sys_rst_n_i and locked_in; -- and locked_out;
  fs_rst   <= not(fs_rst_n);

  ------------------------------------------------------------------------------
  -- ADC data clock buffer
  ------------------------------------------------------------------------------
  cmp_dco_buf : IBUFDS
    generic map (
      DIFF_TERM  => true,               -- Differential termination
      IOSTANDARD => "LVDS_25")
    port map (
      I  => adc_dco_p_i,
      IB => adc_dco_n_i,
      O  => dco_clk_buf
      );
     
  --cmp_serdes_out : BUFIO
    --port map (
    --I => dco_clk_buf,
    --O => serdes_clk
    --);
     

  --cmp_serdes_bufio : BUFIO
    --port map (
    --I => dco_clk_buf,
    --O => serdes_clk
    --);
    
  --cmp_fs_clk_bufr : BUFR
    --generic map(
      --BUFR_DIVIDE => "8",
      --SIM_DEVICE  => "7SERIES"
    --)
    --port map (
      --I   => dco_clk_buf,
      --CE  => '1',
      --CLR => not(fs_rst_n),
      --O   => fs_clk
    --); 

  --cmp_dco_bufio : BUFG
    --port map (
    --I => dco_clk_buf,
    --O => dco_clk
    --);
  --cmp_dco_bufio : BUFR
    --generic map(
      --BUFR_DIVIDE => "1",
      --SIM_DEVICE  => "7SERIES"
    --)
    --port map (
      --I   => dco_clk_buf,
      --CE  => '1',
      --CLR => not(fs_rst_n),
      --O   => dco_clk
    --);

  --cmp_dco_bufio : BUFIO2
    --generic map (
      --DIVIDE        => 1,
      --DIVIDE_BYPASS => true,
      --I_INVERT      => false,
      --USE_DOUBLER   => false)
    --port map (
      --I            => dco_clk_buf,
      --IOCLK        => open,
      --DIVCLK       => dco_clk,
      --SERDESSTROBE => open
      --);

  ------------------------------------------------------------------------------
  -- Clock PLL for SerDes
  -- LTC2174-14 must be configured in 16-bit serialization
  --    dco_clk = 4*fs_clk = 400MHz
  ------------------------------------------------------------------------------
  cmp_serdes_clk_pll : PLLE2_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 2,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 1,
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 8,
      CLKOUT1_PHASE      => 0.000,
      CLKOUT1_DUTY_CYCLE => 0.500,
      CLKIN1_PERIOD      => 2.5,
      REF_JITTER1        => 0.010
      )
    port map (
      -- Output clocks
      CLKFBOUT => clk_fb_out,
      CLKOUT0  => serdes_clk,
      CLKOUT1  => fs_clk_buf,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      -- Status and control signals
      LOCKED   => locked_in,
      RST      => sys_rst,
      -- Input clock control
      CLKFBIN  => clk_fb_in,
      CLKIN1   => dco_clk_buf,
      PWRDWN   => '0');
      
  cmp_fs_clk : BUFG
    port map (
    I => fs_clk_buf,
    O => fs_clk
    );
    --clk_fb_in <= clk_fb_out;
  cmp_clk_fb : BUFG
    port map (
    I => clk_fb_out,
    O => clk_fb_in
    );
      
      --cmp_serdes_clk_pll : PLL_BASE
    --generic map (
      --BANDWIDTH          => "OPTIMIZED",
      --CLK_FEEDBACK       => "CLKOUT0",
      --COMPENSATION       => "SYSTEM_SYNCHRONOUS",
      --DIVCLK_DIVIDE      => 1,
      --CLKFBOUT_MULT      => 2,
      --CLKFBOUT_PHASE     => 0.000,
      --CLKOUT0_DIVIDE     => 1,
      --CLKOUT0_PHASE      => 0.000,
      --CLKOUT0_DUTY_CYCLE => 0.500,
      --CLKOUT1_DIVIDE     => 8,
      --CLKOUT1_PHASE      => 0.000,
      --CLKOUT1_DUTY_CYCLE => 0.500,
      --CLKIN_PERIOD       => 2.5,
      --REF_JITTER         => 0.010)
    --port map (
      ---- Output clocks
      --CLKFBOUT => open,
      --CLKOUT0  => serdes_clk_buf,
      --CLKOUT1  => fs_clk_buf,
      --CLKOUT2  => open,
      --CLKOUT3  => open,
      --CLKOUT4  => open,
      --CLKOUT5  => open,
      ---- Status and control signals
      --LOCKED   => locked_in,
      --RST      => sys_rst,
      ---- Input clock control
      --CLKFBIN  => clk_fb,
      --CLKIN    => dco_clk);
      
  --cmp_serdes_clk : BUFR
    --generic map(
      --BUFR_DIVIDE => "1",
      --SIM_DEVICE  => "7SERIES"
    --)
    --port map (
      --I   => dco_clk,
      --CE  => '1',
      --CLR => not(fs_rst_n), --CLR,
      --O   => serdes_clk_buf
    --);
      
  --cmp_dco_clk_div : BUFR
    --generic map(
      --BUFR_DIVIDE => "8",
      --SIM_DEVICE  => "7SERIES"
    --)
    --port map (
      --I   => dco_clk,
      --CE  => '1',
      --CLR => not(fs_rst_n), --CLR,
      --O   => fs_clk_buf
    --);

  --cmp_serdes_clk_buf : BUFG
    --port map (
      --O => serdes_clk,
      --I => serdes_clk_buf
      --);
      
  --cmp_fs_clk_buf : BUFG
    --port map (
      --O => fs_clk,
      --I => fs_clk_buf
      --);

  --cmp_fb_clk_bufio : BUFG
    --port map (
      --O => clk_fb,
      --I => clk_fb_buf
      --);

  --cmp_fb_clk_bufio : BUFIO2FB
    --generic map (
      --DIVIDE_BYPASS => true)
    --port map (
      --I => clk_fb_buf,
      --O => clk_fb
      --);

  -- Sampinling clock frequency meter
  cmp_fs_freq : gc_frequency_meter
    generic map(
      g_with_internal_timebase => true,
      g_clk_sys_freq           => 125000000,
      g_counter_bits           => 32
      )
    port map(
      clk_sys_i    => sys_clk_i,
      clk_in_i     => fs_clk,
      rst_n_i      => sys_rst_n_i,
      pps_p1_i     => '0',
      freq_o       => fs_freq_t,
      freq_valid_o => fs_freq_valid
      );

  p_fs_freq : process (fs_clk, fs_rst_n)
  begin
    if fs_rst_n = '0' then
      fs_freq <= (others => '0');
    elsif rising_edge(fs_clk) then
      if fs_freq_valid = '1' then
        fs_freq <= fs_freq_t;
      end if;
    end if;
  end process p_fs_freq;

  --gen_fb_clk_check : if (g_carrier_type /= "SPEC" and
  --                      g_carrier_type /= "SVEC") generate
  --  assert false report "[fmc_adc100Ms_core] Selected carrier type not supported. Must be SPEC or SVEC." severity failure;
  --end generate gen_fb_clk_check;

  --gen_fb_clk_spec : if g_carrier_type = "SPEC" generate
  --  cmp_fb_clk_buf : BUFG
  --    port map (
  --      O => clk_fb,
  --      I => clk_fb_buf
  --      );
  --end generate gen_fb_clk_spec;

  --gen_fb_clk_svec : if g_carrier_type = "SVEC" generate
  --  clk_fb <= clk_fb_buf;
  --end generate gen_fb_clk_svec;

  ------------------------------------------------------------------------------
  -- ADC data and frame SerDes
  ------------------------------------------------------------------------------
  cmp_adc_serdes : adc_serdes
    port map(
      DATA_IN_FROM_PINS_P => serdes_in_p,
      DATA_IN_FROM_PINS_N => serdes_in_n,
      DATA_IN_TO_DEVICE   => serdes_out_raw,
      BITSLIP             => serdes_bitslip,
      CLK_IN              => serdes_clk,
      --CLK_OUT             => clk_fb_buf,
      CLK_DIV_IN          => fs_clk_buf,
      LOCKED_IN           => locked_in,
      --LOCKED_OUT          => locked_out,
      CLK_RESET           => '0',       -- unused
      IO_RESET            => sys_rst
      );


  --============================================================================
  -- Sampling clock domain
  --============================================================================

  -- serdes inputs forming
  serdes_in_p <= adc_fr_p_i
                 & adc_outa_p_i(3) & adc_outb_p_i(3)
                 & adc_outa_p_i(2) & adc_outb_p_i(2)
                 & adc_outa_p_i(1) & adc_outb_p_i(1)
                 & adc_outa_p_i(0) & adc_outb_p_i(0);
  serdes_in_n <= adc_fr_n_i
                 & adc_outa_n_i(3) & adc_outb_n_i(3)
                 & adc_outa_n_i(2) & adc_outb_n_i(2)
                 & adc_outa_n_i(1) & adc_outb_n_i(1)
                 & adc_outa_n_i(0) & adc_outb_n_i(0);

  -- serdes outputs re-ordering (time slices -> channel)
  --    out_raw :(71:63)(62:54)(53:45)(44:36)(35:27)(26:18)(17:9)(8:0)
  --                |      |      |      |      |      |      |    |
  --                V      V      V      V      V      V      V    V
  --              CH1D12 CH1D10 CH1D8  CH1D6  CH1D4  CH1D2  CH1D0  0   = CH1_B
  --              CH1D13 CH1D11 CH1D9  CH1D7  CH1D5  CH1D3  CH1D1  0   = CH1_A
  --              CH2D12 CH2D10 CH2D8  CH2D6  CH2D4  CH2D2  CH2D0  0   = CH2_B
  --              CH2D13 CH2D11 CH2D9  CH2D7  CH2D5  CH2D3  CH2D1  0   = CH2_A
  --              CH3D12 CH3D10 CH3D8  CH3D6  CH3D4  CH3D2  CH3D0  0   = CH3_B
  --              CH3D13 CH3D11 CH3D9  CH3D7  CH3D5  CH3D3  CH3D1  0   = CH3_A
  --              CH4D12 CH4D10 CH4D8  CH4D6  CH4D4  CH4D2  CH4D0  0   = CH4_B
  --              CH4D13 CH4D11 CH4D9  CH4D7  CH4D5  CH4D3  CH4D1  0   = CH4_A
  --              FR7    FR6    FR5    FR4    FR3    FR2    FR1    FR0 = FR
  --
  --    out_data(15:0)  = CH1
  --    out_data(31:16) = CH2
  --    out_data(47:32) = CH3
  --    out_data(63:48) = CH4
  --    Note: The two LSBs of each channel are always '0' => 14-bit ADC
  gen_serdes_dout_reorder : for I in 0 to 7 generate
    serdes_out_data(0*16 + 2*i)   <= serdes_out_raw(0 + i*9);  -- CH1 even bits
    serdes_out_data(0*16 + 2*i+1) <= serdes_out_raw(1 + i*9);  -- CH1 odd bits
    serdes_out_data(1*16 + 2*i)   <= serdes_out_raw(2 + i*9);  -- CH2 even bits
    serdes_out_data(1*16 + 2*i+1) <= serdes_out_raw(3 + i*9);  -- CH2 odd bits
    serdes_out_data(2*16 + 2*i)   <= serdes_out_raw(4 + i*9);  -- CH3 even bits
    serdes_out_data(2*16 + 2*i+1) <= serdes_out_raw(5 + i*9);  -- CH3 odd bits
    serdes_out_data(3*16 + 2*i)   <= serdes_out_raw(6 + i*9);  -- CH4 even bits
    serdes_out_data(3*16 + 2*i+1) <= serdes_out_raw(7 + i*9);  -- CH4 odd bits
    serdes_out_fr(i)              <= serdes_out_raw(8 + i*9);  -- FR
  end generate gen_serdes_dout_reorder;


  -- serdes bitslip generation
  p_auto_bitslip : process (fs_clk, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      bitslip_sreg        <= std_logic_vector(to_unsigned(1, bitslip_sreg'length));
      serdes_auto_bitslip <= '0';
      serdes_synced       <= '0';
    elsif rising_edge(fs_clk) then

      -- Shift register to generate bitslip enable (serdes_clk/8)
      bitslip_sreg <= bitslip_sreg(0) & bitslip_sreg(bitslip_sreg'length-1 downto 1);

      -- Generate bitslip and synced signal
      if(bitslip_sreg(bitslip_sreg'left) = '1') then
        if(serdes_out_fr /= "00001111") then -- use fr_n pattern (fr_p and fr_n are swapped on the adc mezzanine)
          serdes_auto_bitslip <= '1';
          serdes_synced       <= '0';
        else
          serdes_auto_bitslip <= '0';
          serdes_synced       <= '1';
        end if;
      else
        serdes_auto_bitslip <= '0';
      end if;

    end if;
  end process;

  serdes_bitslip <= serdes_auto_bitslip or serdes_man_bitslip;

  ------------------------------------------------------------------------------
  -- ADC core control and status registers (CSR)
  ------------------------------------------------------------------------------
  -- Control register
  gpio_si570_oe_o     <= fmc_clk_oe;
  gpio_dac_clr_n_o    <= fmc_adc_core_ctl_offset_dac_clr_n_o;
  test_data_en        <= fmc_adc_core_ctl_test_data_en_o; -- used for wb_ddr_dat_o
  serdes_man_bitslip  <= fmc_adc_core_ctl_man_bitslip_o;
  pre_trig_value      <= fmc_adc_core_pre_samples_o;
  post_trig_value     <= fmc_adc_core_post_samples_o;
  trig_delay          <= fmc_adc_core_trig_dly_o;
  hw_trig_sel         <= fmc_adc_core_trig_cfg_hw_trig_sel_o;
  hw_trig_pol         <= fmc_adc_core_trig_cfg_hw_trig_pol_o;
  hw_trig_en          <= fmc_adc_core_trig_cfg_hw_trig_en_o;
  int_trig_sel        <= fmc_adc_core_trig_cfg_int_trig_sel_o;
  int_trig_test_en    <= fmc_adc_core_trig_cfg_int_trig_test_en_o;
  shots_value         <= fmc_adc_core_shots_nb_o;
  sw_trig_t           <= fmc_adc_core_sw_trig_wr_o;
  sw_trig_en          <= fmc_adc_core_trig_cfg_sw_trig_en_o;
  int_trig_thres_filt <= fmc_adc_core_trig_cfg_int_trig_thres_filt_o;
  int_trig_thres      <= fmc_adc_core_trig_cfg_int_trig_thres_o;
  decim_factor        <= fmc_adc_core_sr_deci_o;

  -- Status register
  fmc_adc_core_ch1_sta_val_i       <= serdes_out_data(15 downto  0);
  fmc_adc_core_ch2_sta_val_i       <= serdes_out_data(31 downto 16);
  fmc_adc_core_ch3_sta_val_i       <= serdes_out_data(47 downto 32);
  fmc_adc_core_ch4_sta_val_i       <= serdes_out_data(63 downto 48);
  fmc_adc_core_sta_fsm_i           <= acq_fsm_state;
  fmc_adc_core_fs_freq_i           <= fs_freq;
  fmc_adc_core_sta_serdes_synced_i <= serdes_synced;
  fmc_adc_core_sta_acq_cfg_i       <= acq_config_ok;
  fmc_single_shot                  <= single_shot;
  fmc_adc_core_shots_cnt_val_i     <= remaining_shots;
  fmc_fifo_empty                   <= sync_fifo_empty;
  fmc_adc_core_samples_cnt_i       <= std_logic_vector(samples_cnt);
  fmc_adc_core_sta_serdes_pll_i    <= locked_in;


  ------------------------------------------------------------------------------
  -- Offset and gain calibration
  ------------------------------------------------------------------------------
  gain_calibr(15 downto  0) <= fmc_adc_core_ch1_gain_val_o;
  gain_calibr(31 downto 16) <= fmc_adc_core_ch2_gain_val_o;
  gain_calibr(47 downto 32) <= fmc_adc_core_ch3_gain_val_o;
  gain_calibr(63 downto 48) <= fmc_adc_core_ch4_gain_val_o;
  
  offset_calibr(15 downto  0) <= fmc_adc_core_ch1_offset_val_o;
  offset_calibr(31 downto 16) <= fmc_adc_core_ch2_offset_val_o;
  offset_calibr(47 downto 32) <= fmc_adc_core_ch3_offset_val_o;
  offset_calibr(63 downto 48) <= fmc_adc_core_ch4_offset_val_o;
  
  sat_val(14 downto  0) <= fmc_adc_core_ch1_sat_val_o;
  sat_val(29 downto 15) <= fmc_adc_core_ch2_sat_val_o;
  sat_val(44 downto 30) <= fmc_adc_core_ch3_sat_val_o;
  sat_val(59 downto 45) <= fmc_adc_core_ch4_sat_val_o;
  
  
  l_offset_gain_calibr : for I in 0 to 3 generate
    cmp_offset_gain_calibr : offset_gain_s
      port map(
        rst_n_i  => fs_rst_n,
        clk_i    => fs_clk,
        offset_i => offset_calibr((I+1)*16-1 downto I*16),
        gain_i   => gain_calibr((I+1)*16-1 downto I*16),
        sat_i    => sat_val((I+1)*15-1 downto I*15),
        data_i   => data_calibr_in((I+1)*16-1 downto I*16),
        data_o   => data_calibr_out((I+1)*16-1 downto I*16)
        );
  end generate l_offset_gain_calibr;

  data_calibr_in <= serdes_out_data;

  ------------------------------------------------------------------------------
  -- Trigger
  ------------------------------------------------------------------------------

  -- External hardware trigger differential to single-ended buffer
  cmp_ext_trig_buf : IBUFDS
    generic map (
      DIFF_TERM  => true,               -- Differential termination
      IOSTANDARD => "LVDS_25")
    port map (
      O  => ext_trig_a,
      I  => ext_trigger_p_i,
      IB => ext_trigger_n_i
      );

  -- External hardware trigger synchronization
  cmp_trig_sync : ext_pulse_sync
    generic map(
      g_MIN_PULSE_WIDTH => 1,           -- clk_i ticks
      g_CLK_FREQUENCY   => 100,         -- MHz
      g_OUTPUT_POLARITY => '0',         -- positive pulse
      g_OUTPUT_RETRIG   => false,
      g_OUTPUT_LENGTH   => 1            -- clk_i tick
      )
    port map(
      rst_n_i          => fs_rst_n,
      clk_i            => fs_clk,
      input_polarity_i => hw_trig_pol,
      pulse_i          => ext_trig_a,
      pulse_o          => ext_trig
      );

  -- Internal hardware trigger
  int_trig_data <= data_calibr_out(15 downto 0)  when int_trig_sel = "00" else  -- CH1 selected
                   data_calibr_out(31 downto 16) when int_trig_sel = "01" else  -- CH2 selected
                   data_calibr_out(47 downto 32) when int_trig_sel = "10" else  -- CH3 selected
                   data_calibr_out(63 downto 48) when int_trig_sel = "11" else  -- CH4 selected
                   (others => '0');

  -- Detects input data going over the internal trigger threshold
  p_int_trig : process (fs_clk, fs_rst_n)
  begin
    if fs_rst_n = '0' then
      int_trig_over_thres <= '0';
    elsif rising_edge(fs_clk) then
      if signed(int_trig_data) > signed(int_trig_thres) then
        int_trig_over_thres <= '1';
      else
        int_trig_over_thres <= '0';
      end if;
    end if;
  end process p_int_trig;

  -- Filters out glitches from over threshold signal (rejects noise around the threshold -> hysteresis)
  cmp_dyn_glitch_filt : gc_dyn_glitch_filt
    generic map(
      g_len_width => 8
      )
    port map(
      clk_i   => fs_clk,
      rst_n_i => fs_rst_n,
      len_i   => int_trig_thres_filt(7 downto 0),
      dat_i   => int_trig_over_thres,
      dat_o   => int_trig_over_thres_filt
      );

  -- Detects whether it's a positive or negative slope
  p_int_trig_slope : process (fs_clk, fs_rst_n)
  begin
    if fs_rst_n = '0' then
      int_trig_over_thres_filt_d <= '0';
    elsif rising_edge(fs_clk) then
      int_trig_over_thres_filt_d <= int_trig_over_thres_filt;
    end if;
  end process;

  int_trig <= int_trig_over_thres_filt and not(int_trig_over_thres_filt_d) when hw_trig_pol = '0' else  -- positive slope
              not(int_trig_over_thres_filt) and int_trig_over_thres_filt_d;                             -- negative slope

  -- Hardware trigger selection
  --    internal = adc data threshold
  --    external = pulse from front panel
  hw_trig_t <= ext_trig when hw_trig_sel = '1' else int_trig;

  -- Hardware trigger enable
  hw_trig <= hw_trig_t and hw_trig_en;

  -- Software trigger enable
  sw_trig <= sw_trig_t and sw_trig_en;

  -- Trigger sources ORing
  trig <= sw_trig or hw_trig;

  -- Trigger delay
  p_trig_delay_cnt : process(fs_clk, fs_rst_n)
  begin
    if fs_rst_n = '0' then
      trig_delay_cnt <= (others => '0');
    elsif rising_edge(fs_clk) then
      if trig = '1' then
        trig_delay_cnt <= unsigned(trig_delay);
      elsif trig_delay_cnt /= 0 then
        trig_delay_cnt <= trig_delay_cnt - 1;
      end if;
    end if;
  end process p_trig_delay_cnt;

  p_trig_delay : process(fs_clk, fs_rst_n)
  begin
    if fs_rst_n = '0' then
      trig_d <= '0';
    elsif rising_edge(fs_clk) then
      if trig_delay = X"00000000" then
        if trig = '1' then
          trig_d <= '1';
        else
          trig_d <= '0';
        end if;
      else
        if trig_delay_cnt = X"00000001" then
          trig_d <= '1';
        else
          trig_d <= '0';
        end if;
      end if;
    end if;
  end process p_trig_delay;

  ------------------------------------------------------------------------------
  -- Samples decimation and trigger alignment
  --    When the decimantion is enabled, if the trigger occurs between two
  --    samples it will be realigned to the next sample
  ------------------------------------------------------------------------------
  p_deci_cnt : process (fs_clk, fs_rst_n)
  begin
    if fs_rst_n = '0' then
      decim_cnt <= to_unsigned(1, decim_cnt'length);
      decim_en  <= '0';
    elsif rising_edge(fs_clk) then
      if decim_cnt = to_unsigned(0, decim_cnt'length) then
        if decim_factor /= X"00000000" then
          decim_cnt <= unsigned(decim_factor) - 1;
        end if;
        decim_en <= '1';
      else
        decim_cnt <= decim_cnt - 1;
        decim_en  <= '0';
      end if;
    end if;
  end process p_deci_cnt;

  p_trig_align : process (fs_clk, fs_rst_n)
  begin
    if fs_rst_n = '0' then
      trig_align <= '0';
    elsif rising_edge(fs_clk) then
      if trig_d = '1' then
        trig_align <= '1';
      elsif decim_en = '1' then
        trig_align <= '0';
      end if;
    end if;
  end process p_trig_align;

  ------------------------------------------------------------------------------
  -- Synchronisation FIFO to system clock domain
  ------------------------------------------------------------------------------
  cmp_adc_sync_fifo : generic_async_fifo
    generic map (
      g_data_width             => 65,
      g_size                   => 16,
      g_show_ahead             => false,
      g_with_rd_empty          => true,
      g_with_rd_full           => false,
      g_with_rd_almost_empty   => false,
      g_with_rd_almost_full    => false,
      g_with_rd_count          => false,
      g_with_wr_empty          => false,
      g_with_wr_full           => true,
      g_with_wr_almost_empty   => false,
      g_with_wr_almost_full    => false,
      g_with_wr_count          => false,
      g_almost_empty_threshold => 0,
      g_almost_full_threshold  => 0
      )
    port map(
      rst_n_i           => fs_rst_n,
      clk_wr_i          => fs_clk,
      d_i               => sync_fifo_din,
      we_i              => sync_fifo_wr,
      wr_empty_o        => open,        -- sync_fifo_empty,
      wr_full_o         => sync_fifo_full,
      wr_almost_empty_o => open,
      wr_almost_full_o  => open,
      wr_count_o        => open,
      clk_rd_i          => sys_clk_i,
      q_o               => sync_fifo_dout,
      rd_i              => sync_fifo_rd,
      rd_empty_o        => sync_fifo_empty,
      rd_full_o         => open,
      rd_almost_empty_o => open,
      rd_almost_full_o  => open,
      rd_count_o        => open
      );

  -- One clock cycle delay for the FIFO's VALID signal. Since the General Cores
  -- package does not offer the possibility to use the FWFT feature of the FIFOs,
  -- we simulate the valid flag here according to Figure 4-7 in ref. [1].
  p_sync_fifo_valid : process (sys_clk_i) is
  begin
    if rising_edge(sys_clk_i) then
      sync_fifo_valid <= sync_fifo_rd;
      if (sync_fifo_empty = '1') then
        sync_fifo_valid <= '0';
      end if;
    end if;
  end process;

  -- Internal trigger test mode
  int_trig_over_thres_tst      <= X"1000" when int_trig_over_thres = '1'      else X"0000";
  int_trig_over_thres_filt_tst <= X"1000" when int_trig_over_thres_filt = '1' else X"0000";
  trig_tst                     <= X"1000" when trig_align = '1'               else X"0000";

  -- Delay data to compoensate for internal trigger detection
  p_data_delay : process (fs_clk, fs_rst_n)
  begin
    if fs_rst_n = '0' then
      data_calibr_out_d <= (others => (others => '0'));
    elsif rising_edge(fs_clk) then
      data_calibr_out_d <= data_calibr_out_d(data_calibr_out_d'left-1 downto 0) & data_calibr_out;
    end if;
  end process p_data_delay;

  -- An additional 1 fs_clk period delay is added when internal hw trigger is selected
  sync_fifo_din <= (trig_align &
                    trig_tst & int_trig_over_thres_filt_tst &
                    int_trig_over_thres_tst &
                    data_calibr_out_d(3)(15 downto 0)) when int_trig_test_en = '1' else
                   (trig_align & data_calibr_out_d(3)) when hw_trig_sel = '0' else
                   (trig_align & data_calibr_out);

  -- FOR DEBUG: FR instead of CH1 and SerDes Synced instead of CH2
  --sync_fifo_din <= trig_align & serdes_out_data(63 downto 32) &
  --                 "000000000000000" & serdes_synced &
  --                 "00000000" & serdes_out_fr;

  sync_fifo_wr <= decim_en and serdes_synced and not(sync_fifo_full);
  sync_fifo_rd <= not(sync_fifo_empty);  -- read sync fifo as soon as data are available

  p_fifo_wr_cnt : process (sys_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      fifo_wr <= (others=>'0');
    elsif rising_edge(sys_clk_i) then
      if sync_fifo_valid = '1' then
        fifo_wr <= fifo_wr + 1;
      else
        fifo_wr <= fifo_wr;
      end if;
    end if;
  end process p_fifo_wr_cnt;
  
  fifo_wr_cnt <= std_logic_vector(fifo_wr);


  --============================================================================
  -- System clock domain
  --============================================================================

  ------------------------------------------------------------------------------
  -- Shots counter
  ------------------------------------------------------------------------------
  p_shots_cnt : process (sys_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      shots_cnt   <= to_unsigned(0, shots_cnt'length);
      single_shot <= '0';
    elsif rising_edge(sys_clk_i) then
      if acq_start = '1' then
        shots_cnt <= unsigned(shots_value);
      elsif shots_decr = '1' then
        shots_cnt <= shots_cnt - 1;
      end if;
      if shots_value = std_logic_vector(to_unsigned(1, shots_value'length)) then
        single_shot <= '1';
      else
        single_shot <= '0';
      end if;
    end if;
  end process p_shots_cnt;

  multishot_buffer_sel <= std_logic(shots_cnt(0));
  shots_done           <= '1' when shots_cnt = to_unsigned(1, shots_cnt'length) else '0';
  remaining_shots      <= std_logic_vector(shots_cnt);

  ------------------------------------------------------------------------------
  -- Pre-trigger counter
  ------------------------------------------------------------------------------
  p_pre_trig_cnt : process (sys_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      pre_trig_cnt <= to_unsigned(1, pre_trig_cnt'length);
    elsif rising_edge(sys_clk_i) then
      if (acq_start = '1' or pre_trig_done = '1') then
        if unsigned(pre_trig_value) = to_unsigned(0, pre_trig_value'length) then
          pre_trig_cnt <= (others => '0');
        else
          pre_trig_cnt <= unsigned(pre_trig_value) - 1;
        end if;
      elsif (acq_in_pre_trig = '1' and sync_fifo_valid = '1') then
        pre_trig_cnt <= pre_trig_cnt - 1;
      end if;
    end if;
  end process p_pre_trig_cnt;

  pre_trig_count <= std_logic_vector(pre_trig_cnt);

  pre_trig_done <= '1' when (pre_trig_cnt = to_unsigned(0, pre_trig_cnt'length) and
                             sync_fifo_valid = '1' and acq_in_pre_trig = '1') else '0';

  ------------------------------------------------------------------------------
  -- Post-trigger counter
  ------------------------------------------------------------------------------
  p_post_trig_cnt : process (sys_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      post_trig_cnt <= to_unsigned(1, post_trig_cnt'length);
    elsif rising_edge(sys_clk_i) then
      if (acq_start = '1' or post_trig_done = '1') then
        post_trig_cnt <= unsigned(post_trig_value) - 1;
      elsif (acq_in_post_trig = '1' and sync_fifo_valid = '1') then
        post_trig_cnt <= post_trig_cnt - 1;
      end if;
    end if;
  end process p_post_trig_cnt;

  post_trig_done <= '1' when (post_trig_cnt = to_unsigned(0, post_trig_cnt'length) and
                              sync_fifo_valid = '1' and acq_in_post_trig = '1') else '0';

  ------------------------------------------------------------------------------
  -- Samples counter
  ------------------------------------------------------------------------------
  p_samples_cnt : process (sys_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      samples_cnt <= (others => '0');
    elsif rising_edge(sys_clk_i) then
      if (acq_start = '1') then
        samples_cnt <= (others => '0');
      elsif ((acq_in_pre_trig = '1' or acq_in_post_trig = '1') and sync_fifo_valid = '1') then
        samples_cnt <= samples_cnt + 1;
      end if;
    end if;
  end process p_samples_cnt;

  ------------------------------------------------------------------------------
  -- Acquisition FSM
  ------------------------------------------------------------------------------

  -- Event pulses to time-tag
  trigger_p_o   <= acq_trig;
  acq_start_p_o <= acq_start;
  acq_stop_p_o  <= acq_stop;

  -- End of acquisition pulse generation
  p_acq_end : process (sys_clk_i)
  begin
    if rising_edge(sys_clk_i) then
      if sys_rst_n_i = '0' then
        acq_end_d <= '0';
      else
        acq_end_d <= acq_end;
      end if;
    end if;
  end process p_acq_end;

  acq_end_p_o <= acq_end and not(acq_end_d);

  -- FSM commands
  fsm_cmd    <= fsm_cmd_i;
  fsm_cmd_wr <= fsm_cmd_wstb;
  
  acq_start <= '1' when fsm_cmd_wr = '1' and fsm_cmd = "01" else '0';
  acq_stop  <= '1' when fsm_cmd_wr = '1' and fsm_cmd = "10" else '0';
  acq_trig  <= sync_fifo_valid and sync_fifo_dout(64) and acq_in_wait_trig;
  acq_end   <= trig_tag_done and shots_done;

  -- Check acquisition configuration
  --   Post-trigger sample must be > 0
  --   Shot number must be > 0
  --   Number of sample (+time-tag) in multi-shot must be < multi-shot ram size
  p_acq_cfg_ok: process (sys_clk_i)
  begin
    if rising_edge(sys_clk_i) then
      if sys_rst_n_i = '0' then
        acq_config_ok <= '0';
      elsif unsigned(post_trig_value) = to_unsigned(0, post_trig_value'length) then
         acq_config_ok <= '0';
      elsif unsigned(shots_value) = to_unsigned(0, shots_value'length) then
        acq_config_ok <= '0';
      elsif unsigned(pre_trig_value)+unsigned(post_trig_value)+4 > to_unsigned(g_multishot_ram_size, pre_trig_value'length) and single_shot = '0' then
        acq_config_ok <= '0';
      else
        acq_config_ok <= '1';
      end if;
    end if;
  end process p_acq_cfg_ok;

  --acq_config_ok <= '0' when (unsigned(post_trig_value) = to_unsigned(0, post_trig_value'length)) else
  --                 '0' when (unsigned(shots_value) = to_unsigned(0, shots_value'length))                                                                            else
  --                 '0' when (unsigned(pre_trig_value)+unsigned(post_trig_value)+4 > to_unsigned(g_multishot_ram_size, pre_trig_value'length) and single_shot = '0') else
  --                 '1';

  -- FSM transitions
  p_acq_fsm_transitions : process(sys_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      acq_fsm_current_state <= IDLE;
    elsif rising_edge(sys_clk_i) then

      case acq_fsm_current_state is

        when IDLE =>
          if acq_start = '1' and acq_config_ok = '1' then
            acq_fsm_current_state <= PRE_TRIG;
          end if;

        when PRE_TRIG =>
          if acq_stop = '1' then
            acq_fsm_current_state <= IDLE;
          elsif pre_trig_done = '1' then
            acq_fsm_current_state <= WAIT_TRIG;
          end if;

        when WAIT_TRIG =>
          if acq_stop = '1' then
            acq_fsm_current_state <= IDLE;
          elsif acq_trig = '1' then
            acq_fsm_current_state <= POST_TRIG;
          end if;

        when POST_TRIG =>
          if acq_stop = '1' then
            acq_fsm_current_state <= IDLE;
          elsif post_trig_done = '1' then
            acq_fsm_current_state <= TRIG_TAG;
          end if;

        when TRIG_TAG =>
          if acq_stop = '1' then
            acq_fsm_current_state <= IDLE;
          elsif trig_tag_done = '1' then
            if single_shot = '1' then
              acq_fsm_current_state <= IDLE;
            else
              acq_fsm_current_state <= DECR_SHOT;
            end if;
          end if;

        when DECR_SHOT =>
          if acq_stop = '1' then
            acq_fsm_current_state <= IDLE;
          else
            if shots_done = '1' then
              acq_fsm_current_state <= IDLE;
            else
              acq_fsm_current_state <= PRE_TRIG;
            end if;
          end if;

        when others =>
          acq_fsm_current_state <= IDLE;

      end case;
    end if;
  end process p_acq_fsm_transitions;

  -- FSM outputs
  p_acq_fsm_outputs : process(acq_fsm_current_state)
  begin

    case acq_fsm_current_state is

      when IDLE =>
        shots_decr       <= '0';
        acq_in_pre_trig  <= '0';
        acq_in_wait_trig <= '0';
        acq_in_post_trig <= '0';
        acq_in_trig_tag  <= '0';
        samples_wr_en    <= '0';
        acq_fsm_state    <= "001";

      when PRE_TRIG =>
        shots_decr       <= '0';
        acq_in_pre_trig  <= '1';
        acq_in_wait_trig <= '0';
        acq_in_post_trig <= '0';
        acq_in_trig_tag  <= '0';
        samples_wr_en    <= '1';
        acq_fsm_state    <= "010";

      when WAIT_TRIG =>
        shots_decr       <= '0';
        acq_in_pre_trig  <= '0';
        acq_in_wait_trig <= '1';
        acq_in_post_trig <= '0';
        acq_in_trig_tag  <= '0';
        samples_wr_en    <= '1';
        acq_fsm_state    <= "011";

      when POST_TRIG =>
        shots_decr       <= '0';
        acq_in_pre_trig  <= '0';
        acq_in_wait_trig <= '0';
        acq_in_post_trig <= '1';
        acq_in_trig_tag  <= '0';
        samples_wr_en    <= '1';
        acq_fsm_state    <= "100";

      when TRIG_TAG =>
        shots_decr       <= '0';
        acq_in_pre_trig  <= '0';
        acq_in_wait_trig <= '0';
        acq_in_post_trig <= '0';
        acq_in_trig_tag  <= '1';
        samples_wr_en    <= '0';
        acq_fsm_state    <= "101";

      when DECR_SHOT =>
        shots_decr       <= '1';
        acq_in_pre_trig  <= '0';
        acq_in_wait_trig <= '0';
        acq_in_post_trig <= '0';
        acq_in_trig_tag  <= '0';
        samples_wr_en    <= '0';
        acq_fsm_state    <= "110";

      when others =>
        shots_decr       <= '0';
        acq_in_pre_trig  <= '0';
        acq_in_wait_trig <= '0';
        acq_in_post_trig <= '0';
        acq_in_trig_tag  <= '0';
        samples_wr_en    <= '0';
        acq_fsm_state    <= "111";

    end case;
  end process p_acq_fsm_outputs;

 ------------------------------------------------------------------------------
  -- WAIT_TRIG counter
  ------------------------------------------------------------------------------
  p_wait_count : process (sys_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      wait_count <= (others=>'0');
    elsif rising_edge(sys_clk_i) then
      if acq_in_wait_trig = '1' then
        wait_count <= wait_count + 1;
      else
        wait_count <= wait_count;
      end if;
    end if;
  end process p_wait_count;
  
  wait_cnt <= std_logic_vector(wait_count);

  ------------------------------------------------------------------------------
  -- Inserting trigger time-tag after post_trigger samples
  ------------------------------------------------------------------------------
  p_trig_tag_done : process (sys_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      acq_in_trig_tag_d <= '0';
    elsif rising_edge(sys_clk_i) then
      acq_in_trig_tag_d <= acq_in_trig_tag;
    end if;
  end process p_trig_tag_done;

  trig_tag_done <= acq_in_trig_tag and acq_in_trig_tag_d;

  --trig_tag_data <= trigger_tag_i.fine & trigger_tag_i.coarse when trig_tag_done = '1' else
   --                trigger_tag_i.seconds & trigger_tag_i.meta;

  ------------------------------------------------------------------------------
  -- Dual DPRAM buffers for multi-shots acquisition
  ------------------------------------------------------------------------------

  ---- DPRAM input address counter
  --p_dpram_addra_cnt : process (sys_clk_i, sys_rst_n_i)
  --begin
    --if sys_rst_n_i = '0' then
      --dpram_addra_cnt       <= (others => '0');
      --dpram_addra_trig      <= (others => '0');
      --dpram_addra_post_done <= (others => '0');
    --elsif rising_edge(sys_clk_i) then
      --if shots_decr = '1' then
        --dpram_addra_cnt <= to_unsigned(0, dpram_addra_cnt'length);
      --elsif (samples_wr_en = '1' and sync_fifo_valid = '1') or (acq_in_trig_tag = '1') then
        --dpram_addra_cnt <= dpram_addra_cnt + 1;
      --end if;
      --if acq_trig = '1' then
        --dpram_addra_trig <= dpram_addra_cnt;
      --end if;
      --if post_trig_done = '1' then
        --dpram_addra_post_done <= dpram_addra_cnt;
      --end if;
    --end if;
  --end process p_dpram_addra_cnt;

  ---- DPRAM inputs
  --dpram0_addra <= std_logic_vector(dpram_addra_cnt);
  --dpram1_addra <= std_logic_vector(dpram_addra_cnt);
  --dpram0_dina  <= sync_fifo_dout(63 downto 0)                            when acq_in_trig_tag = '0'      else trig_tag_data;
  --dpram1_dina  <= sync_fifo_dout(63 downto 0)                            when acq_in_trig_tag = '0'      else trig_tag_data;
  --dpram0_wea   <= (samples_wr_en and sync_fifo_valid) or acq_in_trig_tag when multishot_buffer_sel = '0' else '0';
  --dpram1_wea   <= (samples_wr_en and sync_fifo_valid) or acq_in_trig_tag when multishot_buffer_sel = '1' else '0';

  ---- DPRAMs
  --cmp_multishot_dpram0 : generic_dpram
    --generic map
    --(
      --g_data_width               => 64,
      --g_size                     => g_multishot_ram_size,
      --g_with_byte_enable         => false,
      --g_addr_conflict_resolution => "read_first",
      --g_dual_clock               => true
      ---- default values for the rest of the generics are okay
      --)
    --port map
    --(
      --rst_n_i => sys_rst_n_i,
      --clka_i  => sys_clk_i,
      --bwea_i  => open,
      --wea_i   => dpram0_wea,
      --aa_i    => dpram0_addra,
      --da_i    => dpram0_dina,
      --qa_o    => open,
      --clkb_i  => sys_clk_i,
      --bweb_i  => open,
      --ab_i    => dpram0_addrb,
      ---- db_i    => (others => '0'),
      --qb_o    => dpram0_doutb
      --);

  --cmp_multishot_dpram1 : generic_dpram
    --generic map
    --(
      --g_data_width               => 64,
      --g_size                     => g_multishot_ram_size,
      --g_with_byte_enable         => false,
      --g_addr_conflict_resolution => "read_first",
      --g_dual_clock               => false
      ---- default values for the rest of the generics are okay
      --)
    --port map
    --(
      --rst_n_i => sys_rst_n_i,
      --clka_i  => sys_clk_i,
      --bwea_i  => open,
      --wea_i   => dpram1_wea,
      --aa_i    => dpram1_addra,
      --da_i    => dpram1_dina,
      --qa_o    => open,
      --clkb_i  => sys_clk_i,
      --bweb_i  => open,
      --ab_i    => dpram1_addrb,
      ---- db_i    => (others => '0'),
      --qb_o    => dpram1_doutb
      --);

  ---- DPRAM output address counter
  --p_dpram_addrb_cnt : process (sys_clk_i, sys_rst_n_i)
  --begin
    --if sys_rst_n_i = '0' then
      --dpram_addrb_cnt <= (others => '0');
      --dpram_valid_t   <= '0';
      --dpram_valid     <= '0';
    --elsif rising_edge(sys_clk_i) then
      --if trig_tag_done = '1' then
        --dpram_addrb_cnt <= dpram_addra_trig - unsigned(pre_trig_value(c_dpram_depth-1 downto 0));
        --dpram_valid_t   <= '1';
      --elsif (dpram_addrb_cnt = dpram_addra_post_done + 2) then  -- reads 2 extra addresses -> trigger time-tag
        --dpram_valid_t <= '0';
      --else
        --dpram_addrb_cnt <= dpram_addrb_cnt + 1;
      --end if;
      --dpram_valid <= dpram_valid_t;
    --end if;
  --end process p_dpram_addrb_cnt;

  ---- DPRAM output mux
  --dpram_dout   <= dpram0_doutb when multishot_buffer_sel = '1' else dpram1_doutb;
  --dpram0_addrb <= std_logic_vector(dpram_addrb_cnt);
  --dpram1_addrb <= std_logic_vector(dpram_addrb_cnt);

  ------------------------------------------------------------------------------
  -- Flow control FIFO for data to DDR
  ------------------------------------------------------------------------------
  cmp_wb_ddr_fifo : generic_sync_fifo
    generic map (
      g_data_width             => 65,
      g_size                   => 64,
      g_show_ahead             => false,
      g_with_empty             => true,
      g_with_full              => true,
      g_with_almost_empty      => false,
      g_with_almost_full       => false,
      g_with_count             => false,
      g_almost_empty_threshold => 0,
      g_almost_full_threshold  => 0
      )
    port map(
      rst_n_i        => sys_rst_n_i,
      clk_i          => sys_clk_i,
      d_i            => wb_ddr_fifo_din,
      we_i           => wb_ddr_fifo_wr,
      q_o            => wb_ddr_fifo_dout,
      rd_i           => wb_ddr_fifo_rd,
      empty_o        => wb_ddr_fifo_empty,
      full_o         => wb_ddr_fifo_full,
      almost_empty_o => open,
      almost_full_o  => open,
      count_o        => open
      );

  -- One clock cycle delay for the FIFO's VALID signal. Since the General Cores
  -- package does not offer the possibility to use the FWFT feature of the FIFOs,
  -- we simulate the valid flag here according to Figure 4-7 in ref. [1].
  p_wb_ddr_fifo_valid : process (sys_clk_i) is
  begin
    if rising_edge(sys_clk_i) then
      wb_ddr_fifo_valid <= wb_ddr_fifo_rd;
      if (wb_ddr_fifo_empty = '1') then
        wb_ddr_fifo_valid <= '0';
      end if;
    end if;
  end process;

  p_wb_ddr_fifo_input : process (sys_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      wb_ddr_fifo_din   <= (others => '0');
      wb_ddr_fifo_wr_en <= '0';
    elsif rising_edge(sys_clk_i) then
      if single_shot = '1' then
        if acq_in_trig_tag = '1' then
          --wb_ddr_fifo_din   <= '0' & trig_tag_data;
          wb_ddr_fifo_wr_en <= acq_in_trig_tag;
        else
          wb_ddr_fifo_din   <= acq_trig & sync_fifo_dout(63 downto 0);  -- trigger + data
          wb_ddr_fifo_wr_en <= samples_wr_en and sync_fifo_valid;
        end if;
      else
        wb_ddr_fifo_din   <= '0' & dpram_dout;
        wb_ddr_fifo_wr_en <= dpram_valid;
      end if;
    end if;
  end process p_wb_ddr_fifo_input;

  wb_ddr_fifo_wr <= wb_ddr_fifo_wr_en and not(wb_ddr_fifo_full);

  wb_ddr_fifo_rd   <= wb_ddr_fifo_dreq and not(wb_ddr_fifo_empty) and not(wb_ddr_stall_t);
  wb_ddr_fifo_dreq <= '1';

  ------------------------------------------------------------------------------
  -- RAM address counter (32-bit word address)
  ------------------------------------------------------------------------------
  p_ram_addr_cnt : process (wb_ddr_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      ram_addr_cnt <= (others => '0');
    elsif rising_edge(wb_ddr_clk_i) then
      if acq_start = '1' then
        ram_addr_cnt <= (others => '0');
      elsif wb_ddr_fifo_valid = '1' then
        ram_addr_cnt <= ram_addr_cnt + 1;
      end if;
    end if;
  end process p_ram_addr_cnt;

  ------------------------------------------------------------------------------
  -- Store trigger DDR address (byte address)
  ------------------------------------------------------------------------------
  p_trig_addr : process (wb_ddr_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      trig_addr <= (others => '0');
    elsif rising_edge(wb_ddr_clk_i) then
      if wb_ddr_fifo_dout(64) = '1' and wb_ddr_fifo_valid = '1' then
        trig_addr <= "0000" & std_logic_vector(ram_addr_cnt) & "000";
      end if;
    end if;
  end process p_trig_addr;

  ------------------------------------------------------------------------------
  -- Wishbone master (to DDR)
  ------------------------------------------------------------------------------
  p_wb_master : process (wb_ddr_clk_i, sys_rst_n_i)
  begin
    if sys_rst_n_i = '0' then
      wb_ddr_dat_o   <= (others => '0');
    elsif rising_edge(wb_ddr_clk_i) then
      if wb_ddr_fifo_valid = '1' then
        if test_data_en = '1' then
          wb_ddr_dat_o <= x"00000000" & "0000000" & std_logic_vector(ram_addr_cnt);
        else
          wb_ddr_dat_o <= wb_ddr_fifo_dout(63 downto 0);
        end if;
      end if;
    end if;
  end process p_wb_master;
  
  --p_wb_master : process (wb_ddr_clk_i, sys_rst_n_i)
  --begin
    --if sys_rst_n_i = '0' then
      --wb_ddr_cyc_o   <= '0';
      --wb_ddr_we_o    <= '0';
      --wb_ddr_stb_o   <= '0';
      --wb_ddr_adr_o   <= (others => '0');
      --wb_ddr_dat_o   <= (others => '0');
      --wb_ddr_stall_t <= '0';
    --elsif rising_edge(wb_ddr_clk_i) then

      --if wb_ddr_fifo_valid = '1' then   --if (wb_ddr_fifo_valid = '1') and (wb_ddr_stall_i = '0') then
        --wb_ddr_stb_o <= '1';
        --wb_ddr_adr_o <= "0000000" & std_logic_vector(ram_addr_cnt);
        --if test_data_en = '1' then
          --wb_ddr_dat_o <= x"00000000" & "0000000" & std_logic_vector(ram_addr_cnt);
        --else
          --wb_ddr_dat_o <= wb_ddr_fifo_dout(63 downto 0);
        --end if;
      --else
        --wb_ddr_stb_o <= '0';
      --end if;

      --if wb_ddr_fifo_valid = '1' then
        --wb_ddr_cyc_o <= '1';
        --wb_ddr_we_o  <= '1';
        ----elsif (wb_ddr_fifo_empty = '1') and (acq_end = '1') then
      --elsif (wb_ddr_fifo_empty = '1') and (acq_fsm_state = "001") then
        --wb_ddr_cyc_o <= '0';
        --wb_ddr_we_o  <= '0';
      --end if;

      --wb_ddr_stall_t <= wb_ddr_stall_i;

    --end if;
  --end process p_wb_master;
  --wb_ddr_dat_o <= wb_ddr_fifo_dout(63 downto 0); --sync_fifo_dout(63 downto 0);

  --wb_ddr_sel_o <= X"FF";






---------------------------------------------------------------------------
-- Chipscope ILA Debug purpose
---------------------------------------------------------------------------
ILA_GEN : IF (DEBUG_ILA= "TRUE") GENERATE--false GENERATE--
   My_chipscope_ila_probe_0 : entity work.ila_32x8K
     PORT MAP(
       clk    => fs_clk, -- 100MHz
       probe0 => probe0
       );

   probe0(10 downto 0) <= serdes_synced&               -- 1 bit
                          locked_in&                   -- 1 bit
                          serdes_bitslip&              -- 1 bit
                          serdes_out_fr;               -- 8 bit
                          --adc_outa_p_i&                -- 4 bit
                          --adc_outa_n_i&                -- 4 bit
                          --adc_outb_p_i&                -- 4 bit
                          --adc_outb_n_i;                -- 4 bit
                          --sync_fifo_dout(7 downto 0)&  -- 8 bit
                          --serdes_out_data(15 downto 0); -- 1 bit --> SUM = 21 bits

   probe0(31 downto 11) <= (others=>'0');
   
   --My_chipscope_ila_probe_1 : entity work.ila_32x8K
     --PORT MAP(
       --clk    => fs_clk, -- 100MHz
       --probe0 => probe1
       --);

   --probe1(29 downto 0) <= sync_fifo_dout(7 downto 0)&
                          --serdes_out_data(7 downto 0)&
                          --decim_en&
                          --serdes_bitslip&
                          --serdes_synced&
                          --acq_start&
                          --fsm_cmd&
                          --serdes_out_fr;
                          
   --probe1(31 downto 30) <= (others=>'0');

   --My_chipscope_ila_probe_2 : entity work.ila_32x8K
     --PORT MAP(
       --clk    => sys_clk_i, -- 125MHz
       --probe0 => probe2
       --);

   --probe2(31 downto 0) <= serdes_synced&            -- 1 bit
                          --sync_fifo_valid&          -- 1 bit
                          --sync_fifo_empty&          -- 1 bit
                          --acq_in_pre_trig&          -- 1 bit
                          --acq_start&                -- 1 bit
                          --sw_trig&                  -- 1 bit
                          --std_logic_vector(pre_trig_cnt(3 downto 0))& -- 5 bit
                          --sync_fifo_dout(15 downto 0)& 
                          --sync_fifo_wr&
                          --pre_trig_done&
                          --acq_fsm_state&
                          --acq_config_ok;         -- 1 bit --> SUM = 11 bits
                          
   ----probe2(31 downto 31) <= (others=>'0');

--My_chipscope_ila_probe_3 : entity work.ila_32x8K
     --PORT MAP(
       --clk    => sys_clk_i, -- 125MHz
       --probe0 => probe3
       --);

   --probe3(31 downto 0) <= sync_fifo_dout(7 downto 0)&
                          --wb_ddr_fifo_din(7 downto 0)&
                          --wb_ddr_fifo_dout(7 downto 0)&
                          --serdes_bitslip&
                          --serdes_synced&
                          --serdes_out_fr(5 downto 0); -- 8 bits
                          
   --probe3(31 downto 27) <= (others=>'0');

END GENERATE;

end rtl;
