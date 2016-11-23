--------------------------------------------------------------------------------
--  File:       adder_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity adder_block is
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
    posbus_i            : in  posbus_t;
    -- Output pulse
    out_o               : out std_logic_vector(31 downto 0)
);
end adder_block;

architecture rtl of adder_block is

signal inpa             : std_logic_vector(31 downto 0);
signal inpb             : std_logic_vector(31 downto 0);
signal inpc             : std_logic_vector(31 downto 0);
signal inpd             : std_logic_vector(31 downto 0);

signal INPA_INVERT      : std_logic_vector(31 downto 0);
signal INPB_INVERT      : std_logic_vector(31 downto 0);
signal INPC_INVERT      : std_logic_vector(31 downto 0);
signal INPD_INVERT      : std_logic_vector(31 downto 0);
signal SCALE            : std_logic_vector(31 downto 0);

begin

--
-- Control System Interface
--
adder_ctrl : entity work.adder_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => (others => '0'),
    posbus_i            => posbus_i,
    inpa_o              => inpa,
    inpb_o              => inpb,
    inpc_o              => inpc,
    inpd_o              => inpd,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    INPA_INVERT         => INPA_INVERT,
    INPA_INVERT_WSTB    => open,
    INPB_INVERT         => INPB_INVERT,
    INPB_INVERT_WSTB    => open,
    INPC_INVERT         => INPC_INVERT,
    INPC_INVERT_WSTB    => open,
    INPD_INVERT         => INPD_INVERT,
    INPD_INVERT_WSTB    => open,
    SCALE               => SCALE,
    SCALE_WSTB          => open
);

-- LUT Block Core Instantiation
adder : entity work.adder
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    inpa_i              => inpa,
    inpb_i              => inpb,
    inpc_i              => inpc,
    inpd_i              => inpd,
    out_o               => out_o,

    INPA_INVERT         => INPA_INVERT(0),
    INPB_INVERT         => INPB_INVERT(0),
    INPC_INVERT         => INPC_INVERT(0),
    INPD_INVERT         => INPD_INVERT(0),
    SCALE               => SCALE(1 downto 0)
);

end rtl;

