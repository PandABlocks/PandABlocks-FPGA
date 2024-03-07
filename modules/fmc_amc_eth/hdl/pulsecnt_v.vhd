--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : 
--------------------------------------------------------------------------------
--
--  Description : 32-bit pulse counter (vector)
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.top_defines.all;

entity pulsecnt_v is
generic (
    trig_num           : positive := 1
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    SOFT_RESET_i        : in  std_logic;
    trig_v_i            : in  std_logic_vector(trig_num-1 downto 0);
    carry_v_o           : out std_logic_vector(trig_num-1 downto 0);
    cnt_v_o             : out std32_array(trig_num-1 downto 0)
);
end entity;

architecture rtl of pulsecnt_v is

component pulsecnt is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    SOFT_RESET_i        : in  std_logic;
    trig_i              : in  std_logic;
    carry_o             : out std_logic;
    cnt_o               : out std_logic_vector(31 downto 0)
);
end component;

begin

gen_cnt_i: for I in 0 to trig_num-1 generate
    gen_pulsecnt_i: pulsecnt
        port map(
        -- Clock and Reset
        clk_i               => clk_i,
        reset_i             => reset_i,
        -- Block Input and Outputs
        SOFT_RESET_i        => SOFT_RESET_i,
        trig_i              => trig_v_i(I),
        carry_o             => carry_v_o(I),
        cnt_o               => cnt_v_o(I)
        );
end generate;

end rtl;

