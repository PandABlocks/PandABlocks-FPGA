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
    -- Output signals
	btnR                : in std_logic;
	btnC                : in std_logic;
	btnD                : in std_logic;
	btnU                : in std_logic;
    SW                  : in std_logic_vector(7 downto 0);
	oled_sdin           : out std_logic;
	oled_sclk           : out std_logic;
	oled_dc             : out std_logic;
	oled_res            : out std_logic;
	oled_vbat           : out std_logic;
	oled_vdd            : out std_logic;
	led                 : out std_logic_vector(7 downto 0) := X"aa"
);
end zedboard_demo_top;

architecture rtl of zedboard_demo_top is

component oled_top is
generic(FPGA_BUILD : std_logic_vector := X"AAAAAAAA");
port(
    clk : in std_logic;
	btnR : in std_logic;
	btnC : in std_logic;
	btnD : in std_logic;
	btnU : in std_logic;
	oled_sdin : out std_logic;
	oled_sclk : out std_logic;
	oled_dc : out std_logic;
	oled_res : out std_logic;
	oled_vbat : out std_logic;
	oled_vdd : out std_logic;
    switch_set : in std_logic_vector(7 downto 0);
    led_set : in std_logic_vector(7 downto 0);
    oled_disp : in std_logic_vector(1 downto 0)
);
end component;

-- Register interface common

--signal read_strobe      : std_logic_vector(NUM-1 downto 0);
--signal read_data        : std32_array(NUM-1 downto 0);
--signal write_strobe     : std_logic_vector(NUM-1 downto 0);
--signal read_addr        : natural range 0 to (2**read_address_i'length - 1);
--signal write_addr       : natural range 0 to (2**write_address_i'length - 1);
--signal read_ack         : std_logic_vector(NUM-1 downto 0);

signal OLED_DISP           : std_logic_vector(31 downto 0);
signal OLED_DISP_wstb      : std_logic;
signal LED_SELECT          : std_logic_vector(31 downto 0);
signal LED_SELECT_wstb     : std_logic;
signal LED_SET             : std_logic_vector(31 downto 0);
signal LED_SET_wstb        : std_logic;
signal SWITCH_STAT         : std_logic_vector(31 downto 0);

begin

write_ack_o <= '1';

SWITCH_STAT <= ZEROS(24) & SW;

led <= SW when LED_SELECT(0) = '1' else LED_SET(7 downto 0);
--led <= LED_SET(7 downto 0);

oled_top_inst : component oled_top
generic map(FPGA_BUILD => FPGA_BUILD)
port map(
    clk => clk_i,
    btnR => btnR,
	btnC => btnC,
	btnD => btnD,
	btnU => btnU,
	oled_sdin => oled_sdin,
	oled_sclk => oled_sclk,
	oled_dc => oled_dc,
	oled_res => oled_res,
	oled_vbat => oled_vbat,
	oled_vdd => oled_vdd,
    switch_set => SW,
    led_set => LED_SET(7 downto 0),
    oled_disp => OLED_DISP(1 downto 0)
);

zedboard_demo_ctrl_inst : entity work.zedboard_demo_ctrl
port map(
    clk_i => clk_i,
    reset_i => '0',
    bit_bus_i => (others => '0'),
    pos_bus_i => (others => (others => '0')),
    -- Block Parameters
    OLED_DISP => OLED_DISP,
    OLED_DISP_wstb => OLED_DISP_wstb,
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
    write_ack_o         => open
);

end rtl;
