library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;

entity outenc_block is
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
    -- Encoder I/O Pads
    A_OUT               : out std_logic;
    B_OUT               : out std_logic;
    Z_OUT               : out std_logic;
    CLK_IN              : in  std_logic;
    DATA_OUT            : out std_logic;
    CONN_OUT            : out std_logic;
    -- Position Field interface
    PROTOCOL            : out std_logic_vector(2 downto 0);
    DCARD_MODE          : in  std_logic_vector(31 downto 0);
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t
);
end entity;

architecture rtl of outenc_block is

signal reset            : std_logic;

-- Block Configuration Registers
signal PROTOCOL_i       : std_logic_vector(31 downto 0);
signal BYPASS           : std_logic_vector(31 downto 0);
signal PROTOCOL_WSTB    : std_logic;
signal BITS             : std_logic_vector(31 downto 0);
signal BITS_WSTB        : std_logic;
signal QPERIOD          : std_logic_vector(31 downto 0);
signal QPERIOD_WSTB     : std_logic;
signal QSTATE           : std_logic_vector(31 downto 0);
signal DCARD_ID         : std_logic_vector(31 downto 0);

signal a_ext, b_ext, z_ext, data_ext    : std_logic;
signal posn             : std_logic_vector(31 downto 0);
signal enable           : std_logic;

begin

-- Assign outputs
PROTOCOL <= PROTOCOL_i(2 downto 0);

-- Certain parameter changes must initiate a block reset.
reset <= reset_i or PROTOCOL_WSTB or BITS_WSTB;

--
-- Control System Interface
--
outenc_ctrl : entity work.outenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    a_o                 => a_ext,
    b_o                 => b_ext,
    z_o                 => z_ext,
    data_o              => data_ext,
    conn_o              => CONN_OUT,
    enable_o            => enable,
    val_o               => posn,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    -- Block Parameters
    PROTOCOL            => PROTOCOL_i,
    PROTOCOL_WSTB       => PROTOCOL_WSTB,
    DCARD_ID            => DCARD_ID,
    BYPASS              => BYPASS,
    BITS                => BITS,
    BITS_WSTB           => BITS_WSTB,
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => QPERIOD_WSTB,
    QSTATE              => QSTATE
);

DCARD_ID <= x"0000000" & '0' & DCARD_MODE(3 downto 1);

--
-- Core instantiation
--
outenc_inst : entity work.outenc
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset,
    --
    a_ext_i             => a_ext,
    b_ext_i             => b_ext,
    z_ext_i             => z_ext,
    data_ext_i          => data_ext,
    posn_i              => posn,
    enable_i            => enable,
    -- Encoder I/O Pads
    A_OUT               => A_OUT,
    B_OUT               => B_OUT,
    Z_OUT               => Z_OUT,
    CLK_IN              => CLK_IN,
    DATA_OUT            => DATA_OUT,
    -- Block Parameters
    PROTOCOL            => PROTOCOL_i(2 downto 0),
    BYPASS              => BYPASS(0),
    BITS                => BITS(7 downto 0),
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => QPERIOD_WSTB,
    QSTATE              => QSTATE
);

end rtl;

