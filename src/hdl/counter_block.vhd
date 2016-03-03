--------------------------------------------------------------------------------
--  File:       panda_counter_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_counter_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    -- Output pulse
    count_o             : out std_logic_vector(31 downto 0);
    carry_o             : out std_logic
);
end panda_counter_block;

architecture rtl of panda_counter_block is

signal ENABLE_VAL       : std_logic_vector(31 downto 0);
signal TRIG_VAL         : std_logic_vector(31 downto 0);
signal DIR              : std_logic_vector(31 downto 0);
signal START            : std_logic_vector(31 downto 0);
signal START_WSTB       : std_logic;
signal STEP             : std_logic_vector(31 downto 0);

signal enable           : std_logic;
signal trig             : std_logic;

begin

--
-- Control System Interface
--
counter_ctrl : entity work.panda_counter_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,

    DIR                 => DIR,
    DIR_WSTB            => open,
    START               => START,
    START_WSTB          => START_WSTB,
    STEP                => STEP,
    STEP_WSTB           => open,
    ENABLE              => ENABLE_VAL,
    ENABLE_WSTB         => open,
    TRIG                => TRIG_VAL,
    TRIG_WSTB           => open
);

--
-- Core Input Port Assignments
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        enable <= SBIT(sysbus_i, ENABLE_VAL(SBUSBW-1 downto 0));
        trig <= SBIT(sysbus_i, TRIG_VAL(SBUSBW-1 downto 0));
    end if;
end process;


-- LUT Block Core Instantiation
panda_counter : entity work.panda_counter
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    trigger_i           => trig,
    carry_o             => carry_o,

    DIR                 => DIR(0),
    START               => START,
    START_LOAD          => START_WSTB,
    STEP                => STEP,

    COUNT               => count_o
);

end rtl;

