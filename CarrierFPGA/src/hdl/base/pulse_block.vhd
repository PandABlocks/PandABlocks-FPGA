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
    out_o               : out std_logic;
    perr_o              : out std_logic
);
end pulse_block;

architecture rtl of pulse_block is

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

pulse_ctrl : entity work.pulse_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    inp_o               => inp,
    enable_o            => enable,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    DELAY_L             => DELAY(31 downto 0),
    DELAY_H             => DELAY(63 downto 32),
    DELAY_H_WSTB        => DELAY_WSTB,
    WIDTH_L             => WIDTH(31 downto 0),
    WIDTH_H             => WIDTH(63 downto 32),
    WIDTH_H_WSTB        => WIDTH_WSTB,
    ERR_OVERFLOW        => ERR_OVERFLOW,
    ERR_PERIOD          => ERR_PERIOD,
    QUEUE               => QUEUE,
    MISSED_CNT          => MISSED_CNT
);

-- LUT Block Core Instantiation
pulse : entity work.pulse
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

