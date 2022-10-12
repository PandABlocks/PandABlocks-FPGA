--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : FMC-ADC-100M-14b4Cha on NAMC-ZYNQ-FMC board
-- Design name    : ltc2174_2lanes_ddr_receiver.vhd
-- Description    : implementation of all the platform-specific logic necessary
--                  to receive data from an LTC2174 working in 2-lane, 16-bit
--                  serialization mode
--                  using DDR reception scheme (default), Serial and Parallel
--                  clock buffers for clock generation (no PLL nor MMCM)
--
-- Author         : Thierry GARREL (ELSYS-Design)
-- Synthesizable  : Yes
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2022 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------
-- 2022-03-10 : at least one IDELAYCTRL must be instanciated when using IDELAYE2
--              Reference Clock for IDELAYCTRL. Has to come from BUFG.
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity ltc2174_2lanes_ddr_receiver is
  generic (
    G_DEBUG_ILA         : boolean := FALSE;   -- Generate ILA for debugging
    G_SERIAL_CLK_BUF    : string := "BUFIO";  -- Buffer type for SERDES serial clock : BUFIO or BUFG or BUFR or BUFH
                                              -- Parallel clock generated from clk_serdes with BUFR with BUFR_DIVIDE by 4
    G_DCO_IDELAY_VALUE  : natural := 0 ;      -- Delay Tap setting for IDELAYE2 on adc_clk (0-31)
    G_DATA_IDELAY_VALUE : natural := 0        -- Delay Tap setting for IDELAYE2 on adc_fr,adc_outa,adc_outb (0-31)
 );
  port (
    -- IDELAYCTRL is needed for calibration
    -- When IDELAYCTRL REFCLK is 200 MHz, IDELAY delay chain consist of 31 taps of 78 ps
    idelay_refclock_i   : in  std_logic;      -- REFCLK input of IDELAYCTRL (muse be 200 MHz).
    idelay_rst_i        : in  std_logic;      -- RST input of IDELAYCTRL. Minimum pulse width 52.0 ns
    idelay_locked_o     : out std_logic;      -- indicate that IDELAYE2 modules are calibrated

    -- ADC serial interface
    adc_dco_p_i         : in  std_logic;                    -- ADC_DCO is the serial bit clock (bit_clk)
    adc_dco_n_i         : in  std_logic;
    adc_fr_p_i          : in  std_logic;                    -- ADC frame start
    adc_fr_n_i          : in  std_logic;
    adc_outa_p_i        : in  std_logic_vector(3 downto 0); -- ADC serial data in (odd bits)
    adc_outa_n_i        : in  std_logic_vector(3 downto 0);
    adc_outb_p_i        : in  std_logic_vector(3 downto 0); -- ADC serial data in (even bits)
    adc_outb_n_i        : in  std_logic_vector(3 downto 0);

    -- SERDES status
    serdes_arst_i       : in  std_logic;  -- Async reset input (active high) for iserdes
    serdes_bslip_i      : in  std_logic;  -- Manual bitslip command (optional)
    serdes_synced_o     : out std_logic;  -- Indication that SERDES is ok and locked to frame start pattern
    serdes_bitslip_o    : out std_logic;  -- Copy of ISERDES BITSLIP input

    -- ADC parallel data out (clk_div clock domain)
    adc_data_o          : out std_logic_vector(63 downto 0);
    --  (15:0)  = CH1, (31:16) = CH2, (47:32) = CH3, (63:48) = CH4
    --  The two LSBs of each channel are always '0'
    adc_ch1_o           : out std_logic_vector(15 downto 0);
    adc_ch2_o           : out std_logic_vector(15 downto 0);
    adc_ch3_o           : out std_logic_vector(15 downto 0);
    adc_ch4_o           : out std_logic_vector(15 downto 0);
    -- ADC divided clock, for FPGA logic (clk_div)
    adc_clk_o           : out std_logic

);
end ltc2174_2lanes_ddr_receiver;

architecture rtl of ltc2174_2lanes_ddr_receiver is

  --  Constants
  constant C_ADC_CHANNELS   : natural := 4; -- Number of ADC channels
  constant C_SERIAL_LANES   : natural := 2; -- Number of Lanes per channel
  constant C_SERIAL_BITS    : natural := 8; -- Number of Bits per Lane

  constant C_REF_FREQ       : real := 200.0 ; -- Parameter to set reference frequency used by IDELAYCTRL

  --constant C_DCO_IDELAY_VALUE   : natural := 0  ;   -- 0 to 31
  --constant C_DATA_IDELAY_VALUE  : natural := 0  ;   -- 0 to 31


  -- ADC outputs
  signal adc_dco_in         : std_logic;  -- adc_dco is the serial bit clock (bit clock)
  signal adc_dco_dly        : std_logic;  -- adc_dco delayed
  signal adc_fr_in          : std_logic;  -- adc_fr is the frame clock (parallel clock)
  signal adc_fr_dly         : std_logic;  -- adc_fr delayed
  signal adc_outa_in        : std_logic_vector(3 downto 0);
  signal adc_outa_dly       : std_logic_vector(3 downto 0);
  signal adc_outb_in        : std_logic_vector(3 downto 0);
  signal adc_outb_dly       : std_logic_vector(3 downto 0);

  -- Clock signals
  signal clk_div_pre        : std_logic;
  signal clk_div_buf        : std_logic; -- Parallel clock
  signal clk_serdes_pre     : std_logic;
  signal clk_serdes_buf     : std_logic;
  signal clk_serdes_p       : std_logic; -- SERDES clock
  signal clk_serdes_n       : std_logic;

  signal idelay_locked      : std_logic;
  signal rst_count          : unsigned(3 downto 0); -- 0 to 15
  signal serdes_rst         : std_logic                     := '0';
  signal serdes_auto_bslip  : std_logic                     := '0';
  signal serdes_bitslip     : std_logic                     := '0';
  signal serdes_synced      : std_logic                     := '0';
  signal serdes_serial_in   : std_logic_vector(8 downto 0)  := (others => '0');
  signal serdes_out_fr      : std_logic_vector(7 downto 0)  := (others => '0');
  -- BITSLIP shift register
  signal bitslip_sreg       : unsigned(7 downto 0)          := to_unsigned(1, 8);

  -- SERDES array : 1 (FR) + C_SERIAL_BITS (8)
  type serdes_array is array (0 to C_SERIAL_BITS) of std_logic_vector(7 downto 0);
  signal serdes_parallel_out : serdes_array := (others => (others => '0'));

  signal adc_data_out       : std_logic_vector(63 downto 0);


  attribute keep : string; -- keep name for ila probes

  attribute keep of idelay_locked    : signal is "true";
  attribute keep of serdes_bitslip   : signal is "true";
  attribute keep of serdes_synced    : signal is "true";
  attribute keep of serdes_out_fr    : signal is "true";
  attribute keep of adc_data_out     : signal is "true";


-- Begin of code
begin

  ------------------------------------------------------------------------------
  -- Differential input buffers per input pair
  ------------------------------------------------------------------------------

  -- Create ADC data clock logic
  cmp_adc_dco_ibufgds : IBUFGDS
    generic map (
      DIFF_TERM    => TRUE,
      IBUF_LOW_PWR => TRUE,
      IOSTANDARD   => "LVDS_25")
    port map (
      I  => adc_dco_p_i,
      IB => adc_dco_n_i,
      O  => adc_dco_in);

  -- Create ADC frame start logic
  cmp_adc_fr_ibuf : IBUFDS
    generic map (
      DIFF_TERM    => TRUE,
      IBUF_LOW_PWR => TRUE,
      IOSTANDARD   => "LVDS_25")
    port map (
      I  => adc_fr_p_i,
      IB => adc_fr_n_i,
      O  => adc_fr_in);

    -- Create ADC data input logic
    gen_adc_data_ibufs : for I in 0 to C_ADC_CHANNELS-1 generate

      cmp_adc_outa_ibufs : IBUFDS
        generic map (
          DIFF_TERM    => TRUE,
          IBUF_LOW_PWR => TRUE,
          IOSTANDARD   => "LVDS_25")
        port map (
          I  => adc_outa_p_i(i),
          IB => adc_outa_n_i(i),
          O  => adc_outa_in(i));

      cmp_adc_outb_ibufs : IBUFDS
        generic map (
          DIFF_TERM    => TRUE,
          IBUF_LOW_PWR => TRUE,
          IOSTANDARD   => "LVDS_25")
        port map (
          I  => adc_outb_p_i(i),
          IB => adc_outb_n_i(i),
          O  => adc_outb_in(i));

  end generate gen_adc_data_ibufs;


  ------------------------------------------------------------------------------
  -- IODELAY for data/clock
  ------------------------------------------------------------------------------

  -- delay the ADC dco clock :  IDATAIN = adc_dco_in DATAOUT = adc_dco_dly
  -- UG953 (v2020.2) 7 Series FPGA and Zynq-7000 SoC Libraries Guide
  -- The IDELAYE2 is a 31-tap, wraparound delay element with a calibrated tap resolution
  cmp_adc_dco_idelay : IDELAYE2
  generic map (
    CINVCTRL_SEL                => "FALSE",             -- Enable dynamic clock inversion (FALSE, TRUE)
    DELAY_SRC                   => "IDATAIN",           -- Delay input (IDATAIN, DATAIN)
    HIGH_PERFORMANCE_MODE       => "TRUE",              -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
    IDELAY_TYPE                 => "VAR_LOAD",          -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
    IDELAY_VALUE                => G_DCO_IDELAY_VALUE,  -- Delay Tap setting (0-31)
                                                        -- Ignored when IDELAY_VALUE set to VAR_LOAD or VAR_LOAD_PIPE
    PIPE_SEL                    => "FALSE",             -- Select pipelined mode, FALSE, TRUE
    REFCLK_FREQUENCY            => C_REF_FREQ,          -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
    SIGNAL_PATTERN              => "CLOCK"              -- DATA, CLOCK input signal
  )
  port map (
    CNTVALUEOUT                 => open,                -- (out) Counter value output
    DATAOUT                     => adc_dco_dly,         -- (out) Delayed data output
    C                           => clk_div_buf,         -- (in)  Clock input
    CE                          => '0',                 -- (in)  Active high enable increment/decrement input
    CINVCTRL                    => '0',                 -- (in)  Dynamic clock inversion input
    CNTVALUEIN                  => "00000",             -- (in)  Counter value input
    DATAIN                      => '0',                 -- (in)  Internal delay data input
    IDATAIN                     => adc_dco_in,          -- (in)  Data input from the I/O
    INC                         => '0',                 -- (in)  Increment / Decrement tap delay input
    LD                          => '0',                 -- (in)  Load IDELAY_VALUE input
    LDPIPEEN                    => '0',                 -- (in)  Enable PIPELINE register to load data input
    --REGRST                    => serdes_arst_i        -- Resets the pipeline register to all zeros.
    REGRST                      => '0'                  -- Only used in "VAR_LOAD_PIPE" mode.
  );


  -- delay the ADC frame start input : IDATAIN = adc_fr_in DATAOUT = adc_fr_dly
  cmp_adc_fr_idelay : IDELAYE2
  generic map (
    CINVCTRL_SEL                => "FALSE",
    DELAY_SRC                   => "IDATAIN",             -- Delay input (IDATAIN, DATAIN)
    HIGH_PERFORMANCE_MODE       => "TRUE",                -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
    IDELAY_TYPE                 => "VAR_LOAD",            -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
    IDELAY_VALUE                => g_DATA_IDELAY_VALUE,   -- 0 to 31. Ignored when IDELAY_VALUE set to VAR_LOAD or VAR_LOAD_PIPE
    PIPE_SEL                    => "FALSE",
    REFCLK_FREQUENCY            => C_REF_FREQ,
    SIGNAL_PATTERN              => "CLOCK"
  )
  port map (
    CNTVALUEOUT                 => open,
    DATAOUT                     => adc_fr_dly,
    C                           => clk_div_buf,
    CE                          => '0',
    CINVCTRL                    => '0',
    CNTVALUEIN                  => "00000",
    DATAIN                      => '0',
    IDATAIN                     => adc_fr_in,
    INC                         => '0',
    LD                          => '0',
    LDPIPEEN                    => '0',
    --REGRST                    => serdes_arst_i      -- Resets the pipeline register to all zeros.
    REGRST                      => '0'                  -- Only used in "VAR_LOAD_PIPE" mode.
  );


  -- delay the ADC data inputs for all channels
  gen_adc_data_idelay : for I in 0 to C_ADC_CHANNELS-1 generate

    -- Delay the ADC_outA inputs (odd bits) : IDATAIN = adc_outa_in(i) DATAOUT = adc_outa_dly(i)
    cmp_adc_outa_idelay : IDELAYE2
    generic map (
      CINVCTRL_SEL              => "FALSE",
      DELAY_SRC                 => "IDATAIN",
      HIGH_PERFORMANCE_MODE     => "TRUE",
      IDELAY_TYPE               => "VAR_LOAD",
      IDELAY_VALUE              => g_DATA_IDELAY_VALUE,
      PIPE_SEL                  => "FALSE",
      REFCLK_FREQUENCY          => C_REF_FREQ,
      SIGNAL_PATTERN            => "DATA"
    )
    port map (
      CNTVALUEOUT               => open,
      DATAOUT                   => adc_outa_dly(I),
      C                         => clk_div_buf,
      CE                        => '0',
      CINVCTRL                  => '0',
      CNTVALUEIN                => "00000",
      DATAIN                    => '0',
      IDATAIN                   => adc_outa_in(I),
      INC                       => '0',
      LD                        => '0',
      LDPIPEEN                  => '0',
      --REGRST                  => serdes_arst_i      -- Resets the pipeline register to all zeros.
      REGRST                    => '0'                  -- Only used in "VAR_LOAD_PIPE" mode.
    );

    -- Delay the ADC_outB inputs (even bits) : IDATAIN = adc_outb_in(i) DATAOUT = adc_outb_dly(i)
    cmp_adc_outb_idelay : IDELAYE2
    generic map (
      CINVCTRL_SEL              => "FALSE",
      DELAY_SRC                 => "IDATAIN",
      HIGH_PERFORMANCE_MODE     => "TRUE",
      IDELAY_TYPE               => "VAR_LOAD",
      IDELAY_VALUE              => g_DATA_IDELAY_VALUE,
      PIPE_SEL                  => "FALSE",
      REFCLK_FREQUENCY          => C_REF_FREQ,
      SIGNAL_PATTERN            => "DATA"
    )
    port map (
      CNTVALUEOUT               => open,
      DATAOUT                   => adc_outb_dly(I),
      C                         => clk_div_buf,
      CE                        => '0',
      CINVCTRL                  => '0',
      CNTVALUEIN                => "00000",
      DATAIN                    => '0',
      IDATAIN                   => adc_outb_in(I),
      INC                       => '0',
      LD                        => '0',
      LDPIPEEN                  => '0',
      --REGRST                  => serdes_arst_i      -- Resets the pipeline register to all zeros.
      REGRST                    => '0'                  -- Only used in "VAR_LOAD_PIPE" mode.
    );

  end generate gen_adc_data_idelay;

  -- UG471 (v1.10) 7 series FPGA SelectIO resources user guide page 124
  -- If the IDELAYE2 or ODELAYE2 primitives are instantiated, the IDELAYCTRL
  -- module must also be instantiated.
  -- The IDELAYCTRL module continuously calibrates the individual delay taps (IDELAY/ODELAY)
  -- in its region, to reduce the effects of process, voltage, and temperature variations.
  -- The IDELAYCTRL module calibrates IDELAY and ODELAY using the user supplied REFCLK.

  -- IDELAYCTRL must be reset after configuration and the REFCLK signal is stable.
  -- REFCLK must be F_IDELAYCTRL_REF in the specified ppm tolerance (IDELAY_CTRL_PRECISION)
  --        to garuantee a specified IDELAY and ODELAY resolution (T_IDELAYRESOLUTION).
  --
  -- inputs
  -- -------
  -- RST      : active-high asynchronous reset.
  --            A reset pulse ot T_IDELAYCTRL_RPW is required
  -- REFCLK   : provides a time reference to IDELAYCTRL to calibrate all IDELAY
  --            and ODELAY modules in the same region.
  --            Must be driven by a global or horizontal clock buffer (BUFG Or BUFH)
  -- outputs
  -- -------
  -- RDY      : indicates when IDELAY and ODELAY modules in the specific region are calibrated.
  --            RDY = 0 if REFCLK is held High or Low for more than 1 clok period
  --            if RDY = 0 => IDELAYCTRL module must be reset
  --            Implementation tools allow RDY to be unconnected/ignored

  -- DS191 (v1.18.1) Zynq-7000 SoC (7030, 7035, 7045, 7100) DC and AC Switching Characteristics
  --
  --  F_IDELAYCTRL_REF        = 200 / 300 / 400 MHz (-2 speed grade)
  --  IDELAY_CTRL_PRECISION   = 10 MHz
  --  T_IDELAYCTRL_RPW        = 52.0 ns
  --  T_IDELAYRESOLUTION      = 1/(32 x 2 x F_REF) us  | F_REF 200 MHz => 78 ps
  --
  --      F_REF (MHz)         : 100     200     300     400
  --      T_IDELAYRESOLUTION  : 156 ps  78 ps   52 ps   39 ps
  --

  -- UG953 (v2020.2) : 7 Series FPGA and Zynq-7000 SoC Librairies guide | page 372

  -- IDELAYCTRL: IDELAYE2/ODELAYE2 Tap Delay Value Control
  cmp_idelayctrl : IDELAYCTRL
  port map (
    REFCLK  => idelay_refclock_i,     -- RECLK must be 200 MHz
    RST     => idelay_rst_i,          -- Active-High asynchronous reset input
    RDY     => idelay_locked          -- Indicates the validity of REFCLK input
  );

  idelay_locked_o <= idelay_locked;

  ------------------------------------------------------------------------------
  -- Clock generation for deserializer
  --
  -- DDR scheme proposed in XAPP585 (v1.1.2) July 18, 2018.
  ------------------------------------------------------------------------------

  -- XAPP585, v1.1.2, page 7, figure 2, without calibration. Calibration can be
  -- added later if needed.

  -- connect to cmp_adc_dco_idelay output
  clk_serdes_pre <= adc_dco_dly;
  clk_div_pre    <= adc_dco_dly;

  ------------------------------------------------------------------------------
  -- Data clock for SERDES serial data
  ------------------------------------------------------------------------------

  gen_clk_serdes_bufg : if G_SERIAL_CLK_BUF = "BUFG" generate
    cmp_clk_serdes_bufg : BUFG
      port map (
        I => clk_serdes_pre,
        O => clk_serdes_buf
      );
  end generate gen_clk_serdes_bufg;

  gen_clk_serdes_bufio : if G_SERIAL_CLK_BUF = "BUFIO" generate
    cmp_clk_serdes_bufio : BUFIO        -- BUFG or BUFR // BUFIO : Clock region assignment has failed.
      port map (
        I   => clk_serdes_pre,
        O   => clk_serdes_buf
      );
  end generate gen_clk_serdes_bufio;

  gen_clk_serdes_bufr : if G_SERIAL_CLK_BUF = "BUFR" generate
    cmp_clk_serdes_bufr : BUFR
      generic map (
        BUFR_DIVIDE => "1" )
      port map (
        I   => clk_serdes_pre,
        CE  => '1',
        CLR => '0',
        O   => clk_serdes_buf
      );
  end generate gen_clk_serdes_bufr;

  gen_clk_serdes_bufh : if G_SERIAL_CLK_BUF = "BUFH" generate
    cmp_clk_serdes_bufh : BUFH
      port map (
        I   => clk_serdes_pre,
        O   => clk_serdes_buf
      );
  end generate gen_clk_serdes_bufh;


  ------------------------------------------------------------------------------
  -- Divided clock for SERDES parallel data : clk_div_pre --|>-- clk_div_buf
  --                                                       BUFR
  --                                                   @ BUFR_DIVIDE = 4
  ------------------------------------------------------------------------------

  -- We divide by 4 as the clock is DDR and we are not using a CMT,
  -- but the input clock directly. The only option here is BUFR
  cmp_clk_div_bufr : BUFR
    generic map (
      BUFR_DIVIDE => "4" )
      port map (
        I => clk_div_pre,           -- adc_dco_dly
        CE  => '1',
        CLR => '0',
        O => clk_div_buf);          --  clk_div_pre / 4


  -- SERDES clock
  clk_serdes_p <= clk_serdes_buf;
  clk_serdes_n <= not clk_serdes_buf;

  ------------------------------------------------------------------------------
  -- SERDES Reset
  --
  -- UG471 (v1.10) : 7 Series FPGAs SelectIO Resources User Guide
  -- Every ISERDESE2 in a multiple bit input structure should therefore be driven
  -- by the same reset signal, asserted, and deasserted synchronously to CLKDIV
  -- to ensure that all ISERDESE2 elements come out of reset in synchronization
  --
  -- The reset signal should only be deasserted when it is known that CLK and
  -- CLKDIV are stable and present, and should be a minimum of two CLKDIV pulses
  ------------------------------------------------------------------------------

  -- serdes_rst asserted asynchronously to CLK_DIV and deasserted Synchronously to CLK_DIV
  p_serdes_reset : process(clk_div_buf,idelay_locked,serdes_arst_i)
  begin
    if (idelay_locked = '0' or serdes_arst_i = '1') then
      serdes_rst <= '1';
      rst_count <= "0000";
    elsif rising_edge(clk_div_buf) then
      if rst_count = "1000" then      -- maintain serdes_rst for 8 clk_div clock periods
        serdes_rst <= '0';
      else
        rst_count <= rst_count + 1;
      end if;
    end if;
  end process;


  ------------------------------------------------------------------------------
  -- Bitslip mechanism for deserializer
  ------------------------------------------------------------------------------

  p_auto_bitslip : process (clk_div_buf)
  begin
    if rising_edge(clk_div_buf) then
      -- Shift register to generate bitslip enable once every 8 clock ticks
      bitslip_sreg <= bitslip_sreg(0) & bitslip_sreg(bitslip_sreg'length-1 downto 1);

      -- Generate bitslip and synced signal
      if(bitslip_sreg(bitslip_sreg'LEFT) = '1') then
        -- use fr_n pattern (fr_p and fr_n are swapped on the adc mezzanine)
        if(serdes_out_fr /= "00001111") then
          serdes_auto_bslip <= '1';
          serdes_synced     <= '0';
        else
          serdes_auto_bslip <= '0';
          serdes_synced     <= '1';
        end if;
      else
        serdes_auto_bslip <= '0';
      end if;
    end if;
  end process p_auto_bitslip;

  serdes_bitslip    <= serdes_auto_bslip or serdes_bslip_i;
  serdes_synced_o   <= serdes_synced;

  serdes_bitslip_o  <= serdes_bitslip;

  ------------------------------------------------------------------------------
  -- Data deserializer
  --
  -- For the ISERDES, we use the template proposed in ug471_7Series_SelectIO,
  -- (v1.10) May 8, 2018, pages 143-158. No cascading is needed since 7-series
  -- support up to 8 bits per SERDES.
  ------------------------------------------------------------------------------

  -- serdes inputs forming
  serdes_serial_in <= adc_fr_dly                            -- 8
                      & adc_outa_dly(3) & adc_outb_dly(3)   -- 7 6
                      & adc_outa_dly(2) & adc_outb_dly(2)   -- 5 4
                      & adc_outa_dly(1) & adc_outb_dly(1)   -- 3 2
                      & adc_outa_dly(0) & adc_outb_dly(0);  -- 1 0

  gen_adc_data_iserdes : for I in 0 to C_SERIAL_BITS generate

    cmp_adc_iserdes : ISERDESE2
      generic map (
        DATA_RATE      => "DDR",                  -- SDR / DDR
        DATA_WIDTH     => 8,                      -- Parallel data width (2-8,10,14)
        INTERFACE_TYPE => "NETWORKING",
        IOBDELAY       => "IFD",                  -- NONE, BOTH, IBUF, IFD
        SERDES_MODE    => "MASTER")               -- MASTER, SLAVE
      port map (
        D            => '0',                      -- 1-bit input: Data input
        DDLY         => serdes_serial_in(I),      -- 1-bit input: Serial data from IDELAYE2
        CE1          => '1',
        CE2          => '1',
        CLK          => clk_serdes_p,             -- 1-bit input: High-speed clock
        CLKB         => clk_serdes_n,             -- Inverted version of CLK input
        RST          => serdes_rst,
        CLKDIV       => clk_div_buf,              -- 1-bit input: Divided clock
        CLKDIVP      => '0',
        OCLK         => '0',
        OCLKB        => '0',
        DYNCLKSEL    => '0',
        DYNCLKDIVSEL => '0',
        SHIFTIN1     => '0',                    -- 1-bit (each) input: Data width expansion input ports
        SHIFTIN2     => '0',
        BITSLIP      => serdes_bitslip,         --  1-bit input:

        -- The BITSLIP pin performs a Bitslip operation synchronous to CLKDIV when asserted (active High).
        -- Subsequently, the data seen on the Q1 to Q8 output ports will shift, as in a barrel-shifter
        -- operation, one position every time Bitslip is invoked (DDR operation is different from SDR).

        O            => open,                         -- 1-bit output: Combinatorial output
        Q1           => serdes_parallel_out(I)(0),    -- 1-bit (each) output: Registered data outputs
        Q2           => serdes_parallel_out(I)(1),
        Q3           => serdes_parallel_out(I)(2),
        Q4           => serdes_parallel_out(I)(3),
        Q5           => serdes_parallel_out(I)(4),
        Q6           => serdes_parallel_out(I)(5),
        Q7           => serdes_parallel_out(I)(6),
        Q8           => serdes_parallel_out(I)(7),
        OFB          => '0',
        SHIFTOUT1    => open,                       --  1-bit (each) output: Data width expansion output ports
        SHIFTOUT2    => open);

  end generate gen_adc_data_iserdes;

  -- Get the Frame start directly from the iserdes output
  serdes_out_fr <= serdes_parallel_out(8);

  -- Data re-ordering for serdes outputs
  gen_serdes_dout_reorder : for I in 0 to C_ADC_CHANNELS-1 generate
    gen_serdes_dout_reorder_bits : for J in 0 to C_SERIAL_BITS-1 generate
      -- OUT#B: even bits
      adc_data_out(I*16 + 2*J)     <= serdes_parallel_out(2*I)(J);
      -- OUT#A: odd bits
      adc_data_out(I*16 + 2*J + 1) <= serdes_parallel_out(2*I + 1)(J);
    end generate gen_serdes_dout_reorder_bits;
  end generate gen_serdes_dout_reorder;


  -------------------------------------------
  -- Assign adc_data outputs per channel
  -------------------------------------------
  --  (15:0)  = CH1, (31:16) = CH2, (47:32) = CH3, (63:48) = CH4

  p_adc_output : process(clk_div_buf)
  begin
    if rising_edge(clk_div_buf) then
      -- all channels
      adc_data_o  <= adc_data_out;
      --  (15:0)  = CH1, (31:16) = CH2, (47:32) = CH3, (63:48) = CH4
      --  The two LSBs of each channel are always '0'
      adc_ch1_o   <= adc_data_out(15 downto 0);
      adc_ch2_o   <= adc_data_out(31 downto 16);
      adc_ch3_o   <= adc_data_out(47 downto 32);
      adc_ch4_o   <= adc_data_out(63 downto 48);
    end if;
  end process;

  -- Drive out the divided clock, to be used by the FPGA logic
  adc_clk_o <= clk_div_buf;



-----------------------------------------------------------------------------
-- Chipscope ILA Debug purpose
-----------------------------------------------------------------------------
ILA_GEN : if G_DEBUG_ILA generate

  -- CHIPSCOPE ILA probes
  signal probe0       : std_logic_vector(31 downto 0);
  --signal probe1       : std_logic_vector(31 downto 0);


-- Begin of ILA code
begin

    ILA_0 : entity work.ila_32x8K   -- ILA IP (32-bit wide with 8K Depth)
    port map ( clk => clk_div_buf, probe0 => probe0 );

    --                                                 bits       index
    probe0(31 downto 20) <= idelay_locked             -- 1        31
                          & serdes_rst                -- 1        30
                          & serdes_out_fr             -- 8        29:22
                          & serdes_bitslip            -- 1        21
                          & serdes_synced ;           -- 1        20

    probe0(19 downto 16) <= (others=>'0');
    probe0(15 downto 0)  <=  adc_data_out(15 downto 0);


end generate;
-- End of ILA code



end rtl;
-- End of code

