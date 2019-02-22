--------------------------------------------------------------------------------
--  File:       srgate.vhd
--  Desc:       SR Gate Generator.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity srgate is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    enable_i            : in  std_logic;
    set_i               : in  std_logic;
    rst_i               : in  std_logic;
    out_o               : out std_logic;
    -- Block Parameters
    WHEN_DISABLED       : in  std_logic_vector(31 downto 0);
    SET_EDGE            : in  std_logic_vector(31 downto 0);
    RST_EDGE            : in  std_logic_vector(31 downto 0);
    FORCE_SET           : in  std_logic_vector(31 downto 0);
    FORCE_SET_WSTB      : in  std_logic;
    FORCE_RST           : in  std_logic_vector(31 downto 0);
    FORCE_RST_WSTB      : in  std_logic
);
end srgate;

architecture rtl of srgate is

constant c_trig_edge_neg        : std_logic_vector(1 downto 0) := "01";
constant c_trig_edge_pos        : std_logic_vector(1 downto 0) := "00";
constant c_trig_edge_either     : std_logic_vector(1 downto 0) := "10";

constant c_output_low           : std_logic_vector(1 downto 0) := "00";
constant c_output_high          : std_logic_vector(1 downto 0) := "01";

signal set_prev         : std_logic;
signal rst_prev         : std_logic;
signal set_rise         : std_logic;
signal rst_rise         : std_logic;
signal set_fall         : std_logic;
signal rst_fall         : std_logic;

signal set              : std_logic;
signal rst              : std_logic;
signal pulse            : std_logic := '0';

begin

-- Register inputs
process(clk_i)
begin
    if rising_edge(clk_i) then
        set_prev <= set_i;
        rst_prev <= rst_i;
    end if;
end process;

-- Detect rising and falling edge of set and reset inputs
set_rise  <= set_i and not set_prev;
rst_rise  <= rst_i and not rst_prev;
set_fall  <= not set_i and set_prev;
rst_fall  <= not rst_i and rst_prev;

set <= set_fall when (SET_EDGE(1 downto 0) = c_trig_edge_neg) else
       set_rise or set_fall when (SET_EDGE(1 downto 0) = c_trig_edge_either) else
       set_rise;
rst <= rst_fall when (RST_EDGE(1 downto 0) = c_trig_edge_neg) else
       rst_rise or rst_fall when (RST_EDGE(1 downto 0) = c_trig_edge_either) else
       rst_rise;



--
-- Special SRGate with support for forcing the output.
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        if enable_i = '1' then
            -- Simple SRGate logic
            if (FORCE_RST_WSTB = '1') then
                pulse <= '0';
            elsif (FORCE_SET_WSTB = '1') then
                pulse <= '1';
            elsif (rst = '1') then
                pulse <= '0';
            elsif (set = '1') then
                pulse <= '1';
            end if;
        else
            if WHEN_DISABLED(1 downto 0) = c_output_low then
                pulse <= '0';
            elsif WHEN_DISABLED(1 downto 0) = c_output_high then
                pulse <= '1';
            end if;
        end if;
    end if;
end process;

--out_o <= pulse when enable_i = '1' else '0';
out_o <= pulse;

end rtl;
