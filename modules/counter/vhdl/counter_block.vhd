--------------------------------------------------------------------------------
--  File:       counter_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity counter_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    -- Output pulse
    out_o               : out std_logic_vector(31 downto 0);
    carry_o             : out std_logic
);
end counter_block;

architecture rtl of counter_block is

signal ENABLE_VAL       : std_logic_vector(31 downto 0);
signal TRIG_VAL         : std_logic_vector(31 downto 0);
signal START            : std_logic_vector(31 downto 0);
signal STEP             : std_logic_vector(31 downto 0);
signal MAX              : std_logic_vector(31 downto 0);
signal MIN              : std_logic_vector(31 downto 0);
signal START_WSTB       : std_logic;
signal STEP_WSTB        : std_logic;
signal MAX_WSTB         : std_logic;
signal MIN_WSTB         : std_logic;

signal enable           : std_logic;
signal trig             : std_logic;
signal dir              : std_logic;

begin

--
-- Control System Interface
--
counter_ctrl : entity work.counter_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    trig_o              => trig,
    enable_o            => enable,
    dir_o               => dir,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    START               => START,
    START_WSTB          => START_WSTB,
    STEP                => STEP,
    STEP_WSTB           => STEP_WSTB,
    MAX                 => MAX,
    MAX_WSTB            => MAX_WSTB,
    MIN                 => MIN,
    MIN_WSTB            => MIN_WSTB
);

-- LUT Block Core Instantiation
counter : entity work.counter
port map (
    clk_i               => clk_i,

    enable_i            => enable,
    trigger_i           => trig,
    dir_i               => dir,
    
    START               => START,
    START_WSTB          => START_WSTB,
    STEP_WSTB           => STEP_WSTB,
    STEP                => STEP,
    MAX                 => MAX,
    MAX_WSTB            => MAX_WSTB,
    MIN                 => MIN,
    MIN_WSTB            => MIN_WSTB,

    carry_o             => carry_o,
    out_o               => out_o
);

end rtl;

