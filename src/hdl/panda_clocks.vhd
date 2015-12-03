--------------------------------------------------------------------------------
--  File:       panda_clocks.vhd
--  Desc:       Position user clocks.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_clocks is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
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
    clock_o             : out std_logic;
    DIV                 : in  std_logic_vector(31 downto 0)
);
end component;

begin

-- Clock generator instantiations
panda_clockgen_A : panda_clockgen
port map (
    clk_i           => clk_i,
    clock_o         => clocka_o,
    DIV             => CLOCKA_DIV
);

panda_clockgen_B : panda_clockgen
port map (
    clk_i           => clk_i,
    clock_o         => clockb_o,
    DIV             => CLOCKB_DIV
);

panda_clockgen_C : panda_clockgen
port map (
    clk_i           => clk_i,
    clock_o         => clockc_o,
    DIV             => CLOCKC_DIV
);

panda_clockgen_D : panda_clockgen
port map (
    clk_i           => clk_i,
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
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    clock_o             : out std_logic;
    -- Block Parameters
    DIV                 : in  std_logic_vector(31 downto 0)
);
end panda_clockgen;

architecture rtl of panda_clockgen is

signal DIV_PREV         : std_logic_vector(31 downto 0);

begin

-- Register inputs
process(clk_i)
begin
    if rising_edge(clk_i) then
        DIV_PREV <= DIV;
    end if;
end process;

--
-- CLOCKA = F_AXI / (CLOCKA_DIV+1)
-- With ~50% duty cycle.
--
process(clk_i)
    variable counter32       : unsigned(31 downto 0);
begin
    if rising_edge(clk_i) then
        -- Reset counter on parameter change.
        if (DIV /= DIV_PREV) then
            counter32 := unsigned(DIV) - 1;
            clock_o <= '0';
        -- Half period reached
        elsif (counter32 = unsigned('0' & DIV(31 downto 1))) then
            counter32 := counter32 - 1;
            clock_o <= '1';
        -- Reload when reach Zero and assert clock output.
        elsif (counter32 = 0) then
            counter32 := unsigned(DIV) - 1;
            clock_o <= '0';
        -- Continue counting.
        else
            counter32 := counter32 - 1;
        end if;
    end if;
end process;

end rtl;


