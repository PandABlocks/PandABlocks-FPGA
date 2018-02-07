--------------------------------------------------------------------------------
--  File:       srgate_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity srgate_block is
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
end srgate_block;

architecture rtl of srgate_block is

signal WHEN_DISABLED    : std_logic_vector(31 downto 0);
signal SET_EDGE         : std_logic_vector(31 downto 0);
signal RST_EDGE         : std_logic_vector(31 downto 0);
signal FORCE_SET        : std_logic;
signal FORCE_RST        : std_logic;

signal enable           : std_logic;    
signal set              : std_logic;
signal rst              : std_logic;

begin

--
-- Control System Interface
--
srgate_ctrl : entity work.srgate_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    enable_o            => enable,
    set_o               => set,
    rst_o               => rst,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    WHEN_DISABLED       => WHEN_DISABLED,
    WHEN_DISABLED_WSTB  => open,
    SET_EDGE            => SET_EDGE,
    SET_EDGE_WSTB       => open,
    RST_EDGE            => RST_EDGE,
    RST_EDGE_WSTB       => open,
    FORCE_SET           => open,
    FORCE_SET_WSTB      => FORCE_SET,
    FORCE_RST           => open,
    FORCE_RST_WSTB      => FORCE_RST
);

-- LUT Block Core Instantiation
srgate : entity work.srgate
port map (
    clk_i           => clk_i,
    enable_i        => enable, 
    set_i           => set,
    rst_i           => rst,
    out_o           => out_o,
    WHEN_DISABLED   => WHEN_DISABLED(1 downto 0),    
    SET_EDGE        => SET_EDGE(1 downto 0),
    RST_EDGE        => RST_EDGE(1 downto 0),
    FORCE_SET       => FORCE_SET,
    FORCE_RST       => FORCE_RST
);

end rtl;

