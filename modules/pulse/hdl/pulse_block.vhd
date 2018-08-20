--------------------------------------------------------------------------------
--  File:       pulse_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity pulse_block is
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
    out_o               : out std_logic
);
end pulse_block;

architecture rtl of pulse_block is

signal TRIG_EDGE        : std_logic_vector(31 downto 0);
signal TRIG_EDGE_WSTB   : std_logic;
signal INP_VAL          : std_logic_vector(31 downto 0);
signal ENABLE_VAL       : std_logic_vector(31 downto 0);
signal DELAY            : std_logic_vector(63 downto 0);
signal DELAY_WSTB       : std_logic;
signal WIDTH            : std_logic_vector(63 downto 0);
signal WIDTH_WSTB       : std_logic;
signal DROPPED          : std_logic_vector(31 downto 0);
signal QUEUED           : std_logic_vector(31 downto 0);

signal trig             : std_logic;
signal enable           : std_logic;

begin

pulse_ctrl : entity work.pulse_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    trig_o              => trig,
    enable_o            => enable,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    TRIG_EDGE           => TRIG_EDGE,
    TRIG_EDGE_WSTB      => TRIG_EDGE_WSTB,
    DELAY_L             => DELAY(31 downto 0),
    DELAY_H             => DELAY(63 downto 32),
    DELAY_H_WSTB        => DELAY_WSTB,
    WIDTH_L             => WIDTH(31 downto 0),
    WIDTH_H             => WIDTH(63 downto 32),
    WIDTH_H_WSTB        => WIDTH_WSTB,
    QUEUED              => QUEUED,
    DROPPED             => DROPPED
);

-- LUT Block Core Instantiation
pulse : entity work.pulse
port map (
    clk_i               => clk_i,

    trig_i              => trig,
    enable_i            => enable,
    out_o               => out_o,

    TRIG_EDGE           => TRIG_EDGE(1 downto 0),
    TRIG_EDGE_WSTB      => TRIG_EDGE_WSTB,
    DELAY               => DELAY(47 downto 0),
    DELAY_WSTB          => DELAY_WSTB,
    WIDTH               => WIDTH(47 downto 0),
    WIDTH_WSTB          => WIDTH_WSTB,
    QUEUED              => QUEUED,
    DROPPED             => DROPPED
);

end rtl;

