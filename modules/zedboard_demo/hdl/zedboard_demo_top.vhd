library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

use work.support.all;
use work.top_defines.all;
use work.version.all;

entity zedboard_demo_top is
generic (NUM : natural := 1);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;

    SW                  : in std_logic_vector(7 downto 0);
	led                 : out std_logic_vector(7 downto 0) := X"aa"
);
end zedboard_demo_top;

architecture rtl of zedboard_demo_top is

signal LED_SELECT          : std_logic_vector(31 downto 0);
signal LED_SELECT_wstb     : std_logic;
signal LED_SET             : std_logic_vector(31 downto 0);
signal LED_SET_wstb        : std_logic;
signal SWITCH_STAT         : std_logic_vector(31 downto 0);

begin

SWITCH_STAT <= ZEROS(24) & SW;

led <= SW when LED_SELECT(0) = '1' else LED_SET(7 downto 0);

zedboard_demo_ctrl_inst : entity work.zedboard_demo_ctrl
port map(
    clk_i => clk_i,
    reset_i => '0',
    bit_bus_i => (others => '0'),
    pos_bus_i => (others => (others => '0')),
    -- Block Parameters
    LED_SELECT => LED_SELECT,
    LED_SELECT_wstb => LED_SELECT_wstb,
    LED_SET => LED_SET,
    LED_SET_wstb => LED_SET_wstb,
    SWITCH_STAT => SWITCH_STAT,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o
);

end rtl;
