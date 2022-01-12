--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   14:59:19 10/22/2009
-- Design Name:
-- Module Name:   C:/mcattin/fpga_design/cvorb_cvorg/sources/monostable_tb.vhd
-- Project Name:  cvorb_v3
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: monostable
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity monostable_tb is
end monostable_tb;

architecture behavior of monostable_tb is

  -- Component Declaration for the Unit Under Test (UUT)

  component monostable
    generic(
      g_INPUT_POLARITY  : std_logic := '1';  --! pulse_i polarity
                                             --! ('0'=negative, 1=positive)
      g_OUTPUT_POLARITY : std_logic := '1';  --! pulse_o polarity
                                             --! ('0'=negative, 1=positive)
      g_OUTPUT_RETRIG   : boolean := FALSE;  --! 
      g_OUTPUT_LENGTH   : natural   := 1     --! pulse_o lenght (in clk_i ticks)
      );
    port(
      rst_n_i : in  std_logic;
      clk_i   : in  std_logic;
      trigger_i : in  std_logic;
      pulse_o : out std_logic
      );
  end component;


  --Inputs
  signal rst_n_i : std_logic := '0';
  signal clk_i   : std_logic := '0';
  signal trigger_i : std_logic := '0';

  --Outputs
  signal pulse_o : std_logic;

  -- Clock period definitions
  constant clk_i_period : time := 25 us;

begin

  -- Instantiate the Unit Under Test (UUT)
  uut : monostable
    generic map(
      g_INPUT_POLARITY  => '1',
      g_OUTPUT_POLARITY => '0',
      g_OUTPUT_RETRIG   => FALSE,
      g_OUTPUT_LENGTH   => 10
      )
    port map (
      rst_n_i => rst_n_i,
      clk_i   => clk_i,
      trigger_i => trigger_i,
      pulse_o => pulse_o
      );

  -- Clock process definitions
  clk_i_process : process
  begin
    clk_i <= '0';
    wait for 12.5 ns;
    clk_i <= '1';
    wait for 12.5 ns;
  end process;


  -- Stimulus process
  stim_proc : process
  begin
    -- hold reset state for 1 us.
    rst_n_i <= '0';
    wait for 1 us;
    rst_n_i <= '1';
    wait for 100 ns;
    wait until rising_edge(clk_i);


    trigger_i <= '1';
    wait until rising_edge(clk_i);
    --wait for 500 ns;
    trigger_i <= '0';

    wait for 200 ns;

    wait until rising_edge(clk_i);
    trigger_i <= '1';
    wait until rising_edge(clk_i);
    trigger_i <= '0';

    wait;
  end process;

end;
