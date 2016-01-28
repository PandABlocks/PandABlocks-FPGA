--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : CLOCKS block provides 4 user configurable clock sources.
--                Clock period is controlled by user register in clock ticks.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity panda_clocks is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    clocka_o            : out std_logic;
    clockb_o            : out std_logic;
    clockc_o            : out std_logic;
    clockd_o            : out std_logic;
    -- Block Parameters
    CLOCKA_DIV          : in  std_logic_vector(31 downto 0);
    CLOCKB_DIV          : in  std_logic_vector(31 downto 0);
    CLOCKC_DIV          : in  std_logic_vector(31 downto 0);
    CLOCKD_DIV          : in  std_logic_vector(31 downto 0)
);
end panda_clocks;

architecture rtl of panda_clocks is

component panda_clockgen is
port (
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    clock_o             : out std_logic;
    DIV                 : in  std_logic_vector(31 downto 0)
);
end component;

signal DIVA_PREV        : std_logic_vector(31 downto 0);
signal DIVB_PREV        : std_logic_vector(31 downto 0);
signal DIVC_PREV        : std_logic_vector(31 downto 0);
signal DIVD_PREV        : std_logic_vector(31 downto 0);
signal config_reset     : std_logic;
signal reset            : std_logic;

begin

-- Register inputs
process(clk_i)
begin
    if rising_edge(clk_i) then
        DIVA_PREV <= CLOCKA_DIV;
        DIVB_PREV <= CLOCKB_DIV;
        DIVC_PREV <= CLOCKC_DIV;
        DIVD_PREV <= CLOCKD_DIV;
    end if;
end process;

config_reset <= '1' when (CLOCKA_DIV /= DIVA_PREV) or
                         (CLOCKB_DIV /= DIVB_PREV) or
                         (CLOCKC_DIV /= DIVC_PREV) or
                         (CLOCKD_DIV /= DIVD_PREV)
                else '0';

reset <= config_reset or reset_i;


-- Clock generator instantiations
clockgen_A : panda_clockgen
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    clock_o         => clocka_o,
    DIV             => CLOCKA_DIV
);

clockgen_B : panda_clockgen
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    clock_o         => clockb_o,
    DIV             => CLOCKB_DIV
);

clockgen_C : panda_clockgen
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    clock_o         => clockc_o,
    DIV             => CLOCKC_DIV
);

clockgen_D : panda_clockgen
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    clock_o         => clockd_o,
    DIV             => CLOCKD_DIV
);

end rtl;

--------------------------------------------------------------------------------
--  File:       panda_clockgen.vhd
--  Desc:       Programmable clock generator with ~50% duty cycle.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity panda_clockgen is
port (
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    clock_o             : out std_logic;
    DIV                 : in  std_logic_vector(31 downto 0)
);
end panda_clockgen;

architecture rtl of panda_clockgen is

signal counter32        : unsigned(31 downto 0);
signal DIV_PREV         : std_logic_vector(31 downto 0);
signal PERIOD           : unsigned(31 downto 0);

begin

--
-- CLOCKA = F_AXI / (CLOCKA_DIV+1)
-- With ~50% duty cycle.
--

PERIOD <= unsigned(DIV) + 1;

process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Reset counter on parameter change.
        if (reset_i = '1') then
            counter32 <= unsigned(DIV) - 1;
            clock_o <= '0';
        else
            -- Free running down counter.
            if (counter32 = 0) then
                counter32 <= unsigned(DIV) - 1;
            else
                counter32 <= counter32 - 1;
            end if;

            -- Half period reached
            if (counter32 = unsigned('0' & PERIOD(31 downto 1))) then
                clock_o <= '1';
            -- Reload when reach Zero and assert clock output.
            elsif (counter32 = 0) then
                clock_o <= '0';
            end if;
        end if;
    end if;
end process;

end rtl;


