library ieee;
use ieee.std_logic_1164.all;

use work.support.all;
use work.top_defines.all;
use work.version.all;

entity us_system_top is
generic (NUM : natural := 1);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    sys_i2c_mux_o       : out std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic
);
end us_system_top;

architecture rtl of us_system_top is

signal sys_i2c_mux : std_logic_vector(31 downto 0);

begin

sys_i2c_mux_o <= sys_i2c_mux(0);

us_system_ctrl_inst : entity work.us_system_ctrl
port map(
    clk_i => clk_i,
    reset_i => '0',
    bit_bus_i => (others => '0'),
    pos_bus_i => (others => (others => '0')),
    SYS_I2C_MUX         => sys_i2c_mux,
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
