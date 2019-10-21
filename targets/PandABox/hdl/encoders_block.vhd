library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity encoders_block is
port (
    -- Clock and Reset
    clk_i                   : in  std_logic;
    reset_i                 : in  std_logic;
    -- Memory Bus Interface
    OUTENC_read_strobe_i    : in  std_logic;
    OUTENC_read_data_o      : out std_logic_vector(31 downto 0);
    OUTENC_read_ack_o       : out std_logic;

    OUTENC_write_strobe_i   : in  std_logic;
    OUTENC_write_ack_o      : out std_logic;

    INENC_read_strobe_i     : in  std_logic;
    INENC_read_data_o       : out std_logic_vector(31 downto 0);
    INENC_read_ack_o        : out std_logic;

    INENC_write_strobe_i    : in  std_logic;
    INENC_write_ack_o       : out std_logic;

    read_address_i          : in  std_logic_vector(PAGE_AW-1 downto 0);

    write_address_i         : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i            : in  std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    A_OUT_o                 : out std_logic;
    B_OUT_o                 : out std_logic;
    Z_OUT_o                 : out std_logic;
    CLK_IN_i                : in  std_logic;
    DATA_OUT_o              : out std_logic;
    OUTENC_CONN_OUT_o       : out std_logic;

    A_IN_i                  : in  std_logic;
    B_IN_i                  : in  std_logic;
    Z_IN_i                  : in  std_logic;
    CLK_OUT_o               : out std_logic;
    DATA_IN_i               : in  std_logic;
    INENC_CONN_OUT_o        : out std_logic;
    -- Position Field interface
    OUTENC_PROTOCOL_o       : out std_logic_vector(2 downto 0);
    DCARD_MODE_i            : in  std_logic_vector(31 downto 0);
    bit_bus_i               : in  bit_bus_t;
    pos_bus_i               : in  pos_bus_t;
    INENC_PROTOCOL_o        : out std_logic_vector(2 downto 0);
    posn_o                  : out std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of encoders_block is

signal reset            : std_logic;

-- Block Configuration Registers
signal GENERATOR_ERROR          : std_logic_vector(31 downto 0);
signal OUTENC_PROTOCOL          : std_logic_vector(31 downto 0);
signal BYPASS                   : std_logic_vector(31 downto 0);
signal OUTENC_PROTOCOL_WSTB     : std_logic;
signal OUTENC_BITS              : std_logic_vector(31 downto 0);
signal OUTENC_BITS_WSTB         : std_logic;
signal QPERIOD                  : std_logic_vector(31 downto 0);
signal QPERIOD_WSTB             : std_logic;
signal QSTATE                   : std_logic_vector(31 downto 0);
signal DCARD_TYPE               : std_logic_vector(31 downto 0);
signal OUTENC_HEALTH            : std_logic_vector(31 downto 0);
signal a_ext, b_ext, z_ext, data_ext    : std_logic;
signal posn                     : std_logic_vector(31 downto 0);
signal enable                   : std_logic;


signal clk_ext                  : std_logic;
-- Block Configuration Registers
signal INENC_PROTOCOL           : std_logic_vector(31 downto 0);
signal INENC_PROTOCOL_WSTB      : std_logic;
signal CLK_SRC                  : std_logic_vector(31 downto 0);
signal CLK_PERIOD               : std_logic_vector(31 downto 0);
signal CLK_PERIOD_WSTB          : std_logic;
signal FRAME_PERIOD             : std_logic_vector(31 downto 0);
signal FRAME_PERIOD_WSTB        : std_logic;
signal INENC_BITS               : std_logic_vector(31 downto 0);
signal INENC_BITS_WSTB          : std_logic;
signal SETP                     : std_logic_vector(31 downto 0);
signal SETP_WSTB                : std_logic;
signal RST_ON_Z                 : std_logic_vector(31 downto 0);
signal STATUS                   : std_logic_vector(31 downto 0);
signal read_ack                 : std_logic;
signal LSB_DISCARD              : std_logic_vector(31 downto 0);
signal MSB_DISCARD              : std_logic_vector(31 downto 0);
signal INENC_HEALTH             : std_logic_vector(31 downto 0);
signal HOMED                    : std_logic_vector(31 downto 0);

signal slow                     : slow_packet;

signal read_addr                : natural range 0 to (2**read_address_i'length - 1);

begin

-- Assign outputs
OUTENC_PROTOCOL_o <= OUTENC_PROTOCOL(2 downto 0);
OUTENC_CONN_OUT_o <= enable;
-- Certain parameter changes must initiate a block reset.
reset <= reset_i or OUTENC_PROTOCOL_WSTB or OUTENC_BITS_WSTB or INENC_PROTOCOL_WSTB
         or CLK_PERIOD_WSTB or FRAME_PERIOD_WSTB or INENC_BITS_WSTB;

--
-- Control System Interface
--
outenc_ctrl : entity work.outenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    a_from_bus          => a_ext,
    b_from_bus          => b_ext,
    z_from_bus          => z_ext,
    data_from_bus       => data_ext,
    enable_from_bus     => enable,
    val_from_bus        => posn,

    read_strobe_i       => OUTENC_read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => OUTENC_read_data_o,
    read_ack_o          => OUTENC_read_ack_o,

    write_strobe_i      => OUTENC_write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => OUTENC_write_ack_o,

    -- Block Parameters
    GENERATOR_ERROR     => GENERATOR_ERROR,
    PROTOCOL            => OUTENC_PROTOCOL,
    PROTOCOL_WSTB       => OUTENC_PROTOCOL_WSTB,
    DCARD_TYPE          => DCARD_TYPE,
    BITS                => OUTENC_BITS,
    BITS_WSTB           => OUTENC_BITS_WSTB,
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => QPERIOD_WSTB,
    HEALTH              => OUTENC_HEALTH,
    QSTATE              => QSTATE
);

DCARD_TYPE <= x"0000000" & '0' & DCARD_MODE_i(3 downto 1);

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
    A_OUT               => A_OUT_o,
    B_OUT               => B_OUT_o,
    Z_OUT               => Z_OUT_o,
    CLK_IN              => CLK_IN_i,
    DATA_OUT            => DATA_OUT_o,
    -- Block Parameters
    GENERATOR_ERROR     => GENERATOR_ERROR(0),
    PROTOCOL            => OUTENC_PROTOCOL(2 downto 0),
    BITS                => OUTENC_BITS(7 downto 0),
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => QPERIOD_WSTB,
    HEALTH              => OUTENC_HEALTH,
    QSTATE              => QSTATE
);

-- Assign outputs
INENC_PROTOCOL_o <= INENC_PROTOCOL(2 downto 0);

-- Input encoder connection status comes from either
--  * Dcard pin [12] for incremental, or
--  * link_up status for absolute in loopback mode
INENC_CONN_OUT_o <= STATUS(0);

--------------------------------------------------------------------------
-- Control System Interface
--------------------------------------------------------------------------
inenc_ctrl : entity work.inenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    clk_from_bus        => clk_ext,

    read_strobe_i       => INENC_read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => INENC_read_data_o,
    read_ack_o          => INENC_read_ack_o,

    write_strobe_i      => INENC_write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => INENC_write_ack_o,

    PROTOCOL            => INENC_PROTOCOL,
    PROTOCOL_WSTB       => INENC_PROTOCOL_WSTB,
    CLK_SRC             => CLK_SRC,
    CLK_SRC_WSTB        => open,
    CLK_PERIOD          => CLK_PERIOD,
    CLK_PERIOD_WSTB     => CLK_PERIOD_WSTB,
    FRAME_PERIOD        => FRAME_PERIOD,
    FRAME_PERIOD_WSTB   => FRAME_PERIOD_WSTB,
    BITS                => INENC_BITS,
    BITS_WSTB           => INENC_BITS_WSTB,
    LSB_DISCARD         => LSB_DISCARD,
    LSB_DISCARD_WSTB    => open,
    MSB_DISCARD         => MSB_DISCARD,
    MSB_DISCARD_WSTB    => open,
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z,
    RST_ON_Z_WSTB       => open,
    HEALTH              => INENC_HEALTH,
    HOMED               => HOMED,
    DCARD_TYPE          => DCARD_TYPE
);

read_addr <= to_integer(unsigned(read_address_i));

--------------------------------------------------------------------------
-- INENC block instantiation
--------------------------------------------------------------------------
inenc_inst : entity work.inenc
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset,
    --
    A_IN                => A_IN_i,
    B_IN                => B_IN_i,
    Z_IN                => Z_IN_i,
    CLK_OUT             => CLK_OUT_o,
    DATA_IN             => DATA_IN_i,
    CLK_IN              => CLK_IN_i,
    --
    clk_out_ext_i       => clk_ext,
    --
    DCARD_MODE          => DCARD_MODE_i,
    PROTOCOL            => INENC_PROTOCOL(2 downto 0),
    CLK_SRC             => CLK_SRC(0),
    CLK_PERIOD          => CLK_PERIOD,
    FRAME_PERIOD        => FRAME_PERIOD,
    BITS                => INENC_BITS(7 downto 0),
    LSB_DISCARD         => LSB_DISCARD(4 downto 0),
    MSB_DISCARD         => MSB_DISCARD(4 downto 0),
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z,
    STATUS              => STATUS,
    HEALTH              => INENC_HEALTH,
    HOMED               => HOMED,
    --
    posn_o              => posn_o
);

end rtl;
