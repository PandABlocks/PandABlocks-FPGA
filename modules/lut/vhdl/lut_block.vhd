--------------------------------------------------------------------------------
--  File:       lut_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity lut_block is
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
end lut_block;

architecture rtl of lut_block is

signal FUNC             : std_logic_vector(31 downto 0);
signal FUNC_WSTB        : std_logic;

signal inpa             : std_logic;
signal inpb             : std_logic;
signal inpc             : std_logic;
signal inpd             : std_logic;
signal inpe             : std_logic;

begin

--
-- Control System Interface
--
lut_ctrl : entity work.lut_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    inpa_o              => inpa,
    inpb_o              => inpb,
    inpc_o              => inpc,
    inpd_o              => inpd,
    inpe_o              => inpe,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    FUNC                => FUNC,
    FUNC_WSTB           => open

);

-- LUT Block Core Instantiation
lut : entity work.lut
port map (
    clk_i       => clk_i,

    inpa_i      => inpa,
    inpb_i      => inpb,
    inpc_i      => inpc,
    inpd_i      => inpd,
    inpe_i      => inpe,
    out_o       => out_o,

    FUNC        => FUNC
);


end rtl;

