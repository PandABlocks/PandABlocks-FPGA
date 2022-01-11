
-- file: adc_serdes.vhd
-- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- None
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity adc_serdes is
generic
 (-- width of the data for the system
  sys_w       : integer := 9;
  -- width of the data for the device
  dev_w       : integer := 72);
port
 (
  -- From the system into the device
  DATA_IN_FROM_PINS_P     : in    std_logic_vector(sys_w-1 downto 0);
  DATA_IN_FROM_PINS_N     : in    std_logic_vector(sys_w-1 downto 0);
  DATA_IN_TO_DEVICE       : out   std_logic_vector(dev_w-1 downto 0);

  BITSLIP                 : in    std_logic;
-- Clock and reset signals
  CLK_IN                  : in    std_logic;                    -- Fast clock from PLL/MMCM
  --CLK_OUT                 : out   std_logic;
  CLK_DIV_IN              : in    std_logic;                    -- Slow clock from PLL/MMCM
  LOCKED_IN               : in    std_logic;
  --LOCKED_OUT              : out   std_logic;
  CLK_RESET               : in    std_logic;                    -- Reset signal for Clock circuit
  IO_RESET                : in    std_logic);                   -- Reset signal for IO circuit
end adc_serdes;

architecture xilinx of adc_serdes is
  --attribute CORE_GENERATION_INFO            : string;
  --attribute CORE_GENERATION_INFO of xilinx  : architecture is "adc_serdes,selectio_wiz_v2_0,{component_name=adc_serdes,bus_dir=INPUTS,bus_sig_type=DIFF,bus_io_std=LVDS_25,use_serialization=true,use_phase_detector=false,serialization_factor=8,enable_bitslip=true,enable_train=false,system_data_width=9,bus_in_delay=NONE,bus_out_delay=NONE,clk_sig_type=SINGLE,clk_io_std=LVCMOS25,clk_buf=BUFPLL,active_edge=RISING,clk_delay=NONE,v6_bus_in_delay=NONE,v6_bus_out_delay=NONE,v6_clk_buf=BUFIO,v6_active_edge=NOT_APP,v6_ddr_alignment=SAME_EDGE_PIPELINED,v6_oddr_alignment=SAME_EDGE,ddr_alignment=C0,v6_interface_type=NETWORKING,interface_type=RETIMED,v6_bus_in_tap=0,v6_bus_out_tap=0,v6_clk_io_std=LVCMOS18,v6_clk_sig_type=DIFF}";
  constant clock_enable            : std_logic := '1';
  signal clk_in_int_bufio          : std_logic;
  signal clk_in_int_buf            : std_logic;
  signal clk_div_in_int            : std_logic;


  signal clk_in_buf : std_logic;
  signal clk_div_in_buf : std_logic;

  -- After the buffer
  signal data_in_from_pins_int     : std_logic_vector(sys_w-1 downto 0);
  -- Between the delay and serdes
  signal data_in_from_pins_delay   : std_logic_vector(sys_w-1 downto 0);


  constant num_serial_bits         : integer := dev_w/sys_w; -- 72/9=8
  type serdarr is array (0 to 7) of std_logic_vector(sys_w-1 downto 0);
  -- Array to use intermediately from the serdes to the internal
  --  devices. bus "0" is the leftmost bus
  -- * fills in starting with 0
  signal iserdes_q                 : serdarr := (( others => (others => '0')));
  signal serdesstrobe              : std_logic;
  signal icascade                  : std_logic_vector(sys_w-1 downto 0);
  signal slave_shiftout            : std_logic_vector(sys_w-1 downto 0);
  signal CLR                       : std_logic;
  signal CE                        : std_logic;


begin



  -- Create the clock logic
  --bufg_inst1 : BUFG
    --port map (
      --O => clk_in_buf,
      --I => CLK_IN
      --);
  --bufg_inst2 : BUFG
    --port map (
      --O => clk_div_in_buf,
      --I => CLK_DIV_IN
      --);
 

   --bufpll_inst : BUFPLL
    --generic map (
      --DIVIDE       => 8)
    --port map (
      --IOCLK        => clk_in_int_buf,
      --LOCK         => LOCKED_OUT,
      --SERDESSTROBE => serdesstrobe,
      --GCLK         => CLK_DIV_IN,  -- GCLK pin must be driven by BUFG
      --LOCKED       => LOCKED_IN,
      --PLLIN        => CLK_IN);

     --BUFIO_inst : BUFIO
       --port map (
         --O => clk_in_buf, -- 1-bit output: Clock output (connect to I/O clock loads).
         --I => CLK_IN  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
       --);

     --BUFR_inst : BUFR
       --generic map(
         --BUFR_DIVIDE => "1",
         --SIM_DEVICE  => "7SERIES"
        --)
       --port map (
         --I   => CLK_IN,
         --CE  => clock_enable,
         --CLR => '0',
         --O   => clk_in_buf
        --);

     --BUFR_inst2 : BUFR
       --generic map (
         --BUFR_DIVIDE => "BYPASS",--"8",            -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8"
         --SIM_DEVICE  => "7SERIES"       -- Must be set to "7SERIES"
         --)
         --port map (
         --O           => clk_div_in_buf, -- 1-bit output: Clock output port
         --CE          => clock_enable,   -- 1-bit input: Active high, clock enable (Divided modes only)
         --CLR         => '0',            -- 1-bit input: Active high, asynchronous clear (Divided modes only)
         --I           => CLK_DIV_IN      -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
         --);

     --BUFIO_inst : BUFIO
       --port map (
         --I => CLK_DIV_IN,
         --O => clk_in_int_bufio
         --);

  --CLK_OUT <= clk_in_buf;

  -- We have multiple bits- step over every bit, instantiating the required elements
  pins: for pin_count in 0 to sys_w-1 generate 

  begin
    -- Instantiate the buffers
    ----------------------------------
    -- Instantiate a buffer for every bit of the data bus
    ibufds_inst : IBUFDS
      generic map (
        DIFF_TERM    => TRUE, -- Differential termination
        IBUF_LOW_PWR => TRUE,
        IOSTANDARD   => "LVDS_25")
      port map (
        I          => DATA_IN_FROM_PINS_P  (pin_count),
        IB         => DATA_IN_FROM_PINS_N  (pin_count),
        O          => data_in_from_pins_int(pin_count)
        );

    -- Pass through the delay
    -----------------------------------
    data_in_from_pins_delay(pin_count) <= data_in_from_pins_int(pin_count);

    -- Instantiate the serdes primitive
    ----------------------------------
    -- declare the iserdes
    iserdes2_master : ISERDESE2
      generic map (
        DATA_RATE         => "SDR",
        DATA_WIDTH        => 8,
        DYN_CLKDIV_INV_EN => "FALSE", -- Enable DYNCLKDIVINVSEL inversion (FALSE,TRUE)
        DYN_CLK_INV_EN    => "FALSE", -- Enable DYNCLKINVSEL inversion (FALSE,TRUE)
        --INIT_Q1-INIT_Q4: Initial value on the Q outputs(0/1)
        INIT_Q1           => '0',
        INIT_Q2           => '0',
        INIT_Q3           => '0',
        INIT_Q4           => '0',
        INTERFACE_TYPE    => "NETWORKING",
        IOBDELAY          => "NONE",  -- NONE, BOTH, IBUF, IFD
        NUM_CE            => 1,       -- Number of clock enables(1,2)
        OFB_USED          => "FALSE", -- Select OFB path (FALSE,TRUE)
        SERDES_MODE       => "MASTER",
        --SRVAL_Q1-SRVAL_Q4: Q output values when SR is used(0/1)
        SRVAL_Q1          => '1',
        SRVAL_Q2          => '1',
        SRVAL_Q3          => '1',
        SRVAL_Q4          => '1'
        )
      port map (
        O            => open,           --1-bit output: Combinatorial output
        Q1           => iserdes_q(7)(pin_count),
        Q2           => iserdes_q(6)(pin_count),
        Q3           => iserdes_q(5)(pin_count),
        Q4           => iserdes_q(4)(pin_count),
        Q5           => iserdes_q(3)(pin_count), -- open,
        Q6           => iserdes_q(2)(pin_count), -- open,
        Q7           => iserdes_q(1)(pin_count), -- open,
        Q8           => iserdes_q(0)(pin_count), -- open,
        SHIFTOUT1    => open,                    -- icascade(pin_count),
        SHIFTOUT2    => open,
        
        BITSLIP      => BITSLIP,        -- 1-bit Invoke Bitslip. This can be used with any DATA_WIDTH, cascaded or not.
                                        -- The amount of bitslip is fixed by the DATA_WIDTH selection.
        CE1          => LOCKED_IN,   -- 1-bit Clock enable input
        CE2          => '0',            -- 1-bit Clock enable input
        CLKDIVP      => '0',            -- 1-bit input: TBD
        CLK          => CLK_IN, --clk_in_buf,     -- 1-bit IO Clock network input. Optionally Invertible. This is the primary clock. High Speed clk.
                                        -- input used when the clock doubler circuit is not engaged (see DATA_RATE
                                        -- attribute).
        CLKB         => '0',            -- 1-bit input: Second High speed clock input only for MEMORY_QDR mode
        CLKDIV       => CLK_DIV_IN,--clk_div_in_buf, -- 1-bit input: Divided clock input  
        OCLK         => '0',            -- 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY"
        DYNCLKDIVSEL => '0',            -- 1-bit input: Dynamic CLKDIV inversion
        DYNCLKSEL    => '0',            -- 1-bit input: Dynamic CLK/CLKB inversion
        D            => data_in_from_pins_delay(pin_count), -- 1-bit input: signal from IOB.
        DDLY         => '0',            -- 1-bit input: Serial data from IDELAYE2
        OFB          => '0',            -- 1-bit input: Data feedback from OSERDESE2
        OCLKB        => '0',            -- 1-bit input: High speed negative edge output clock

        RST          => IO_RESET,       -- 1-bit Asynchronous reset only.
        SHIFTIN1     => '0',            -- slave_shiftout(pin_count),
        SHIFTIN2     => '0'
        );


     -- Concatenate the serdes outputs together. Keep the timesliced
     --   bits together, and placing the earliest bits on the right
     --   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
     --       the output will be 3210, 7654, ...
     -------------------------------------------------------------

     in_slices: for slice_count in 0 to num_serial_bits-1 generate begin
        -- This places the first data in time on the right
        --DATA_IN_TO_DEVICE(slice_count*sys_w+sys_w-1 downto slice_count*sys_w) <=
        --  iserdes_q(num_serial_bits-slice_count-1);
        -- To place the first data in time on the left, use the
        --   following code, instead
         DATA_IN_TO_DEVICE(slice_count*sys_w+sys_w-1 downto slice_count*sys_w) <=
           iserdes_q(slice_count);
     end generate in_slices;


  end generate pins;


end xilinx;



