--------------------------------------------------------------------------------
--  File:       calc_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity calc_block is
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
end calc_block;

architecture rtl of calc_block is

signal inpa   : std_logic_vector(31 downto 0);
signal inpb   : std_logic_vector(31 downto 0);
signal inpc   : std_logic_vector(31 downto 0);
signal inpd   : std_logic_vector(31 downto 0);

signal A      : std_logic_vector(31 downto 0);
signal B      : std_logic_vector(31 downto 0);
signal C      : std_logic_vector(31 downto 0);
signal D      : std_logic_vector(31 downto 0);
signal FUNC   : std_logic_vector(31 downto 0);

begin

--
-- Control System Interface
--
calc_ctrl : entity work.calc_ctrl
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

    A                   => A,
    A_WSTB              => open,
    B                   => B,
    B_WSTB              => open,
    C                   => C,
    C_WSTB              => open,
    D                   => D,
    D_WSTB              => open,
    FUNC                => FUNC,
    FUNC_WSTB           => open
);

-- LUT Block Core Instantiation
calc : entity work.calc
port map (
    clk_i   => clk_i,

    inpa_i  => inpa,
    inpb_i  => inpb,
    inpc_i  => inpc,
    inpd_i  => inpd,
    out_o   => out_o,

    A       => A(0),
    B       => B(0),
    C       => C(0),
    D       => D(0),
    FUNC    => FUNC(1 downto 0)
);

end rtl;

