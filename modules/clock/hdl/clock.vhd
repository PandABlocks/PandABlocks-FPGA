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

entity clock is
port (
    -- Clock and Reset
    clk_i             : in  std_logic;
    -- Block Input and Outputs
    outa_o            : out std_logic;
    outb_o            : out std_logic;
    outc_o            : out std_logic;
    outd_o            : out std_logic;
    -- Block Parameters
    ENABLE_i          : in   std_logic;  
    A_PERIOD          : in  std_logic_vector(31 downto 0);
    A_PERIOD_wstb     : in  std_logic;
    B_PERIOD          : in  std_logic_vector(31 downto 0);
    B_PERIOD_wstb     : in  std_logic;
    C_PERIOD          : in  std_logic_vector(31 downto 0);
    C_PERIOD_wstb     : in  std_logic;
    D_PERIOD          : in  std_logic_vector(31 downto 0);
    D_PERIOD_wstb     : in  std_logic
);
end clock;

architecture rtl of clock is

signal reset            : std_logic;

component clockgen is
port (
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    clock_o             : out std_logic;
    ENABLE_i            : in  std_logic;
    DIV                 : in  std_logic_vector(31 downto 0)
);
end component;

begin
reset <= A_PERIOD_wstb or B_PERIOD_wstb or C_PERIOD_wstb or D_PERIOD_wstb;
-- Clock generator instantiations
clockgen_A : clockgen
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    clock_o         => outa_o,
    ENABLE_i        => ENABLE_i,
    DIV             => A_PERIOD
);

clockgen_B : clockgen
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    clock_o         => outb_o,
    ENABLE_i        => ENABLE_i,
    DIV             => B_PERIOD
);

clockgen_C : clockgen
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    clock_o         => outc_o,
    ENABLE_i        => ENABLE_i,
    DIV             => C_PERIOD
);

clockgen_D : clockgen
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    clock_o         => outd_o,
    ENABLE_i        => ENABLE_i,
    DIV             => D_PERIOD
);

end rtl;

--------------------------------------------------------------------------------
--  File:       clockgen.vhd
--  Desc:       Programmable clock generator with ~50% duty cycle.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clockgen is
port (
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    clock_o             : out std_logic;
    ENABLE_i            : in  std_logic;
    DIV                 : in  std_logic_vector(31 downto 0)
);
end clockgen;

architecture rtl of clockgen is

signal counter32        : unsigned(31 downto 0);
signal PERIOD           : unsigned(31 downto 0);

signal start_sync       : std_logic;


begin

--
-- CLOCKA = F_AXI / (A_PERIOD+1)
-- With ~50% duty cycle.
--

PERIOD <= unsigned(DIV) + 1;

process(clk_i)
begin
    if rising_edge(clk_i) then
    
        -- Resync when disabled 
        if (ENABLE_i = '0' and reset_i = '1') then
            start_sync <= '1';
        -- Clear the Resync flag    
        elsif (ENABLE_i = '1') then
            start_sync <= '0';
        end if;        
    
        -- Reset counter on parameter change.
        if (ENABLE_i = '1') then
            if (reset_i = '1' and unsigned(DIV) > 0) or (start_sync = '1') then
                counter32 <= unsigned(DIV) - 1;
                if unsigned(DIV) > 0 then
                    clock_o <= '1';
                else
                    clock_o <= '0';
                end if;                                    
            else
                -- Free running down counter.
                if (counter32 = 0) then
                    counter32 <= unsigned(DIV) - 1;
                else
                    counter32 <= counter32 - 1;
                end if;

                -- Reload when reach Zero and assert clock output.
                if (counter32 = 0 and DIV /= x"00000000") then
                    clock_o <= '1';
                elsif (reset_i = '1' and DIV /= x"00000000") then
                    clock_o <= '1';
                -- Half period reached
                elsif (counter32 = unsigned('0' & PERIOD(31 downto 1))) or (DIV = x"00000000") then
                    clock_o <= '0';
                end if;
            end if;            
        else
            clock_o <= '0';
        end if;
    end if;
end process;

end rtl;


