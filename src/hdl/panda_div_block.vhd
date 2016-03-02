--------------------------------------------------------------------------------
--  File:       panda_div_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity panda_div_block is
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
    outd_o              : out std_logic;
    outn_o              : out std_logic
);
end panda_div_block;

architecture rtl of panda_div_block is

signal INP_VAL          : std_logic_vector(31 downto 0);
signal ENABLE_VAL       : std_logic_vector(31 downto 0);
signal FIRST_PULSE      : std_logic_vector(31 downto 0);
signal DIVISOR          : std_logic_vector(31 downto 0);
signal COUNT            : std_logic_vector(31 downto 0);
signal DIVISOR_WSTB     : std_logic;
signal FIRST_PULSE_WSTB : std_logic;

signal inp              : std_logic;
signal enable           : std_logic;

begin

--
-- Control System Interface
--
div_ctrl : entity work.panda_div_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_dat_o,

    DIVISOR             => DIVISOR,
    DIVISOR_WSTB        => DIVISOR_WSTB,
    FIRST_PULSE         => FIRST_PULSE,
    FIRST_PULSE_WSTB    => FIRST_PULSE_WSTB,
    INP                 => INP_VAL,
    INP_WSTB            => open,
    ENABLE              => ENABLE_VAL,
    ENABLE_WSTB         => open,
    COUNT               => COUNT
);

--
-- Core Input Port Assignments
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        inp <= SBIT(sysbus_i, INP_VAL(SBUSBW-1 downto 0));
        enable <= SBIT(sysbus_i, ENABLE_VAL(SBUSBW-1 downto 0));
    end if;
end process;

-- LUT Block Core Instantiation
panda_div : entity work.panda_div
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    inp_i               => inp,
    enable_i            => enable,
    outd_o              => outd_o,
    outn_o              => outn_o,

    DIVISOR             => DIVISOR,
    DIVISOR_WSTB        => DIVISOR_WSTB,
    FIRST_PULSE         => FIRST_PULSE(0),
    FIRST_PULSE_WSTB    => FIRST_PULSE_WSTB,

    COUNT               => COUNT
);

end rtl;

