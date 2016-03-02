--------------------------------------------------------------------------------
--  File:       panda_pulse_block.vhd
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

entity panda_pulse_block is
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
    out_o               : out std_logic;
    perr_o              : out std_logic
);
end panda_pulse_block;

architecture rtl of panda_pulse_block is

signal INP_VAL          : std_logic_vector(31 downto 0);
signal ENABLE_VAL       : std_logic_vector(31 downto 0);
signal DELAY            : std_logic_vector(63 downto 0);
signal DELAY_WSTB       : std_logic;
signal WIDTH            : std_logic_vector(63 downto 0);
signal WIDTH_WSTB       : std_logic;
signal MISSED_CNT       : std_logic_vector(31 downto 0);
signal ERR_OVERFLOW     : std_logic_vector(31 downto 0);
signal ERR_PERIOD       : std_logic_vector(31 downto 0);
signal QUEUE            : std_logic_vector(31 downto 0);

signal inp              : std_logic;
signal enable           : std_logic;

begin

pulse_ctrl : entity work.panda_pulse_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_dat_o,

    DELAY               => DELAY,
    DELAY_WSTB          => DELAY_WSTB,
    WIDTH               => WIDTH,
    WIDTH_WSTB          => WIDTH_WSTB,
    INP                 => INP_VAL,
    INP_WSTB            => open,
    ENABLE              => ENABLE_VAL,
    ENABLE_WSTB         => open,
    ERR_OVERFLOW        => ERR_OVERFLOW,
    ERR_PERIOD          => ERR_PERIOD,
    QUEUE               => QUEUE,
    MISSED_CNT          => MISSED_CNT
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
panda_pulse : entity work.panda_pulse
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    inp_i               => inp,
    enable_i            => enable,
    out_o               => out_o,
    perr_o              => perr_o,

    DELAY               => DELAY(47 downto 0),
    DELAY_WSTB          => DELAY_WSTB,
    WIDTH               => WIDTH(47 downto 0),
    WIDTH_WSTB          => WIDTH_WSTB,
    ERR_OVERFLOW        => ERR_OVERFLOW,
    ERR_PERIOD          => ERR_PERIOD,
    QUEUE               => QUEUE,
    MISSED_CNT          => MISSED_CNT
);

end rtl;

