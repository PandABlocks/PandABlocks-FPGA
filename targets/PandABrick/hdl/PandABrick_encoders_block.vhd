library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity pandabrick_encoders_block is
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

    read_address_i          : in  std_logic_vector(BLK_AW-1 downto 0);

    write_address_i         : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i            : in  std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    INENC_A_o               : out std_logic;
    INENC_B_o               : out std_logic;
    INENC_Z_o               : out std_logic;
    INENC_DATA_o            : out std_logic;

    OUTENC_PROTOCOL_o       : out std_logic_vector(31 downto 0);
    OUTENC_PROTOCOL_WSTB_o  : out std_logic;
    INENC_PROTOCOL_o        : out std_logic_vector(31 downto 0);
    INENC_PROTOCOL_WSTB_o   : out std_logic;

    OUTENC_CONN_OUT_o       : out std_logic;
    INENC_CONN_OUT_o        : out std_logic;

    clk_int_o               : out std_logic;

    pin_ENC_A_in            : in  std_logic;
    pin_ENC_B_in            : in  std_logic;
    pin_ENC_Z_in            : in  std_logic;
    pin_ENC_A_out           : out std_logic;
    pin_ENC_B_out           : out std_logic;
    pin_ENC_Z_out           : out std_logic;
    
    pin_PMAC_SCLK_RX        : in std_logic;
    pin_ENC_SDA_RX          : in std_logic;
    pin_PMAC_SDA_RX         : in std_logic;
    pin_ENC_SCLK_RX         : in std_logic;
	
    pin_ENC_SCLK_TX         : out std_logic;
    pin_ENC_SDA_TX          : out std_logic;
    pin_ENC_SDA_TX_EN       : out std_logic;
    pin_PMAC_SDA_TX         : out std_logic;
    pin_PMAC_SDA_TX_EN      : out std_logic;
    

    -- Position Field interface
    DCARD_MODE_i            : in  std_logic_vector(31 downto 0);
    bit_bus_i               : in  bit_bus_t;
    pos_bus_i               : in  pos_bus_t;
    posn_o                  : out std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of pandabrick_encoders_block is

signal reset            : std_logic;

-- Block Configuration Registers
signal GENERATOR_ERROR          : std_logic_vector(31 downto 0);
signal OUTENC_PROTOCOL          : std_logic_vector(31 downto 0);
signal OUTENC_PROTOCOL_WSTB     : std_logic;
signal OUTENC_ENCODING          : std_logic_vector(31 downto 0);
signal OUTENC_ENCODING_WSTB     : std_logic;
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
signal INENC_ENCODING           : std_logic_vector(31 downto 0);
signal INENC_ENCODING_WSTB      : std_logic;
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

signal read_addr                : natural range 0 to (2**read_address_i'length - 1);

begin

-- Assign outputs

INENC_PROTOCOL_o <= INENC_PROTOCOL;
INENC_PROTOCOL_WSTB_o <= INENC_PROTOCOL_WSTB;
OUTENC_PROTOCOL_o <= OUTENC_PROTOCOL;
OUTENC_PROTOCOL_WSTB_o <= OUTENC_PROTOCOL_WSTB;

OUTENC_CONN_OUT_o <= enable;

-- Input encoder connection status comes from either
--  * Dcard pin [12] for incremental, or
--  * link_up status for absolute in loopback mode
INENC_CONN_OUT_o <= STATUS(0);

-- Certain parameter changes must initiate a block reset.
reset <= reset_i or OUTENC_PROTOCOL_WSTB or OUTENC_BITS_WSTB or INENC_PROTOCOL_WSTB
         or OUTENC_ENCODING_WSTB or INENC_ENCODING_WSTB
         or CLK_PERIOD_WSTB or FRAME_PERIOD_WSTB or INENC_BITS_WSTB;

DCARD_TYPE <= x"0000000" & '0' & DCARD_MODE_i(3 downto 1);

--------------------------------------------------------------------------
-- Control System Interface
--------------------------------------------------------------------------
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
    ENCODING            => OUTENC_ENCODING,
    ENCODING_WSTB       => OUTENC_ENCODING_WSTB,
    DCARD_TYPE          => DCARD_TYPE,
    BITS                => OUTENC_BITS,
    BITS_WSTB           => OUTENC_BITS_WSTB,
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => QPERIOD_WSTB,
    HEALTH              => OUTENC_HEALTH,
    QSTATE              => QSTATE
);

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
    ENCODING            => INENC_ENCODING,
    ENCODING_WSTB       => INENC_ENCODING_WSTB,
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

--
-- Core instantiation
--

encoders_inst : entity work.pandabrick_encoders
port map(
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset,
    -- Encoder inputs from Bitbus
    a_ext_i             => a_ext,
    b_ext_i             => b_ext,
    z_ext_i             => z_ext,
    data_ext_i          => data_ext,
    posn_i              => posn,
    enable_i            => enable,
    -- Encoder I/O Pads
    INENC_A_o           => INENC_A_o,
    INENC_B_o           => INENC_B_o,
    INENC_Z_o           => INENC_Z_o,
    INENC_DATA_o        => INENC_DATA_o,
    --
    clk_out_ext_i       => clk_ext,
    clk_int_o           => clk_int_o,
    --
    pin_ENC_A_in        => pin_ENC_A_in,
    pin_ENC_B_in        => pin_ENC_B_in,
    pin_ENC_Z_in        => pin_ENC_Z_in,
    pin_ENC_A_out       => pin_ENC_A_out,
    pin_ENC_B_out       => pin_ENC_B_out,
    pin_ENC_Z_out       => pin_ENC_Z_out,
    
    pin_PMAC_SCLK_RX        => pin_PMAC_SCLK_RX,
    pin_ENC_SDA_RX          => pin_ENC_SDA_RX,
    pin_PMAC_SDA_RX         => pin_PMAC_SDA_RX,
    pin_ENC_SCLK_RX         => pin_ENC_SCLK_RX,

    pin_ENC_SCLK_TX         => pin_ENC_SCLK_TX,
    pin_ENC_SDA_TX          => pin_ENC_SDA_TX,
    pin_ENC_SDA_TX_EN       => pin_ENC_SDA_TX_EN,
    pin_PMAC_SDA_TX         => pin_PMAC_SDA_TX,
    pin_PMAC_SDA_TX_EN      => pin_PMAC_SDA_TX_EN,
   
    
    -- Block parameters
    GENERATOR_ERROR_i   => GENERATOR_ERROR(0),
    OUTENC_PROTOCOL_i   => OUTENC_PROTOCOL(2 downto 0),
    OUTENC_ENCODING_i   => OUTENC_ENCODING(1 downto 0),
    OUTENC_BITS_i       => OUTENC_BITS(7 downto 0),
    QPERIOD_i           => QPERIOD,
    QPERIOD_WSTB_i      => QPERIOD_WSTB,
    OUTENC_HEALTH_o     => OUTENC_HEALTH,
    QSTATE_o            => QSTATE,

    DCARD_MODE_i        => DCARD_MODE_i,
    INENC_PROTOCOL_i    => INENC_PROTOCOL(2 downto 0),
    INENC_ENCODING_i    => INENC_ENCODING(1 downto 0),
    CLK_SRC_i           => CLK_SRC(0),
    CLK_PERIOD_i        => CLK_PERIOD,
    FRAME_PERIOD_i      => FRAME_PERIOD,
    INENC_BITS_i        => INENC_BITS(7 downto 0),
    LSB_DISCARD_i       => LSB_DISCARD(4 downto 0),
    MSB_DISCARD_i       => MSB_DISCARD(4 downto 0),
    SETP_i              => SETP,
    SETP_WSTB_i         => SETP_WSTB,
    RST_ON_Z_i          => RST_ON_Z,
    STATUS_o            => STATUS,
    INENC_HEALTH_o      => INENC_HEALTH,
    HOMED_o             => HOMED,
    --
    -- Block Outputs
    posn_o              => posn_o
);

end rtl;
