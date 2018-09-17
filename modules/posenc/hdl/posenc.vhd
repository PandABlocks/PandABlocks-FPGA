library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity posenc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Inputs and Outputs
    inp_i               : in  std_logic_vector(31 downto 0);
    enable_i            : in  std_logic;
    -- Encoder I/O Pads
    a_o                 : out std_logic;
    b_o                 : out std_logic;
    -- Block parameters
    PROTOCOL            : in  std_logic_vector(1 downto 0);
    PERIOD              : in  std_logic_vector(31 downto 0);
    PERIOD_WSTB         : in  std_logic;
    STATE_o             : out std_logic_vector(1 downto 0)
);
end entity;

architecture rtl of posenc is

signal a, b, step, dir  : std_logic;
signal STATE_FULL       : std_logic_vector(31 downto 0);
signal reset            : std_logic;
signal period_i         : std_logic_vector(31 downto 0);
begin
--	
-- INCREMENTAL OUT
--

reset <= not enable_i;

qenc : entity work.qenc
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    enable_i        => enable_i,
    posn_i          => inp_i,
    QPERIOD         => period_i,
    QPERIOD_WSTB    => PERIOD_WSTB,
    QSTATE          => STATE_FULL,
    a_o             => a,
    b_o             => b,
    step_o          => step,
    dir_o           => dir
);

-- The period needs to be set greater than 1
period_i <= PERIOD when (unsigned(PERIOD) /= 1) else  (0 => '0',
                                                      1 => '1',
                                                 others => '0');
 
-- Added clock to Protocol 1 Assignment so that the positive edge of the step
-- output lines up with the positive edge of the quadrature output
a_o <= a    when (PROTOCOL(0) = '0') else
       step when (rising_edge(clk_i));
b_o <= b    when (PROTOCOL(0) = '0') else dir;
STATE_o <= STATE_FULL(1 downto 0);
end rtl;

