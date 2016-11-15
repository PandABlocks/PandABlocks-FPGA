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
    a_o                 : out std_logic;
    b_o                 : out std_logic;
    z_o                 : out std_logic;
    sclk_i              : in  std_logic;
    sdat_i              : in  std_logic;
    sdat_o              : out std_logic;
    conn_o              : out std_logic;
    -- Position Field interface
    PROTOCOL            : out std_logic_vector(2 downto 0);
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t
);
end entity;

architecture rtl of outenc_block is

signal reset            : std_logic;

-- Block Configuration Registers
signal PROTOCOL_i       : std_logic_vector(31 downto 0);
signal PROTOCOL_WSTB    : std_logic;
signal BITS             : std_logic_vector(31 downto 0);
signal BITS_WSTB        : std_logic;
signal QPERIOD          : std_logic_vector(31 downto 0);
signal QPERIOD_WSTB     : std_logic;
signal QSTATE           : std_logic_vector(31 downto 0);

signal a, b, z          : std_logic;
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
    a_o                 => a,
    b_o                 => b,
    z_o                 => z,
    conn_o              => conn_o,
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
    BITS                => BITS,
    BITS_WSTB           => BITS_WSTB,
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => QPERIOD_WSTB,
    QSTATE              => QSTATE
);

--
-- Core instantiation
--
outenc_inst : entity work.outenc
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset,
    --
    a_i                 => a,
    b_i                 => b,
    z_i                 => z,
    posn_i              => posn,
    enable_i            => enable,
    -- Encoder I/O Pads
    a_o                 => a_o,
    b_o                 => b_o,
    z_o                 => z_o,
    sclk_i              => sclk_i,
    sdat_i              => sdat_i,
    sdat_o              => sdat_o,
    -- Block Parameters
    PROTOCOL            => PROTOCOL_i(2 downto 0),
    BITS                => BITS(7 downto 0),
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => QPERIOD_WSTB,
    QSTATE              => QSTATE
);

end rtl;

