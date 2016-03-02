--------------------------------------------------------------------------------
--  File:       panda_pcomp_block.vhd
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

entity panda_pcomp_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    -- Output pulse
    act_o               : out std_logic;
    pulse_o             : out std_logic
);
end panda_pcomp_block;

architecture rtl of panda_pcomp_block is

type state_t is (IDLE, POS, NEG);

signal ENABLE_VAL       : std_logic_vector(31 downto 0);
signal POSN_VAL         : std_logic_vector(31 downto 0);
signal START            : std_logic_vector(31 downto 0);
signal STEP             : std_logic_vector(31 downto 0);
signal WIDTH            : std_logic_vector(31 downto 0);
signal NUM              : std_logic_vector(31 downto 0);
signal RELATIVE         : std_logic_vector(31 downto 0);
signal DIR              : std_logic_vector(31 downto 0);
signal DELTAP           : std_logic_vector(31 downto 0);
signal ERR              : std_logic_vector(31 downto 0);

signal enable           : std_logic;
signal posn             : std_logic_vector(31 downto 0);

begin

--
-- Control System Interface
--
pcomp_ctrl : entity work.panda_pcomp_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,

    START               => START,
    START_WSTB          => open,
    STEP                => STEP,
    STEP_WSTB           => open,
    WIDTH               => WIDTH,
    WIDTH_WSTB          => open,
    PNUM                => NUM,
    PNUM_WSTB           => open,
    RELATIVE            => RELATIVE,
    RELATIVE_WSTB       => open,
    DIR                 => DIR,
    DIR_WSTB            => open,
    DELTAP              => DELTAP,
    DELTAP_WSTB         => open,
    USE_TABLE           => open,
    USE_TABLE_WSTB      => open,
    ENABLE              => ENABLE_VAL,
    ENABLE_WSTB         => open,
    INP                 => POSN_VAL,
    INP_WSTB            => open,
    ERROR               => ERR
);

--
-- Design Bus Assignments
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        enable <= SBIT(sysbus_i, ENABLE_VAL(SBUSBW-1 downto 0));
        posn <= PFIELD(posbus_i, POSN_VAL(PBUSBW-1 downto 0));
    end if;
end process;

--
-- Position Compare IP
--
pcomp_inst : entity work.panda_pcomp
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    posn_i              => posn,

    START               => START,
    STEP                => STEP,
    WIDTH               => WIDTH,
    NUM                 => NUM,
    RELATIVE            => RELATIVE(0),
    DIR                 => DIR(0),
    DELTAP              => DELTAP,

    act_o               => act_o,
    err_o               => open,
    pulse_o             => pulse_o
);

end rtl;

