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
    PMACENC_read_strobe_i    : in  std_logic;
    PMACENC_read_data_o      : out std_logic_vector(31 downto 0);
    PMACENC_read_ack_o       : out std_logic;

    PMACENC_write_strobe_i   : in  std_logic;
    PMACENC_write_ack_o      : out std_logic;

    INCENC_read_strobe_i     : in  std_logic;
    INCENC_read_data_o       : out std_logic_vector(31 downto 0);
    INCENC_read_ack_o        : out std_logic;

    INCENC_write_strobe_i    : in  std_logic;
    INCENC_write_ack_o       : out std_logic;

    ABSENC_read_strobe_i     : in  std_logic;
    ABSENC_read_data_o       : out std_logic_vector(31 downto 0);
    ABSENC_read_ack_o        : out std_logic;

    ABSENC_write_strobe_i    : in  std_logic;
    ABSENC_write_ack_o       : out std_logic;

    read_address_i          : in  std_logic_vector(BLK_AW-1 downto 0);

    write_address_i         : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i            : in  std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    INCENC_A_o               : out std_logic;
    INCENC_B_o               : out std_logic;
    INCENC_Z_o               : out std_logic;
    
    ABSENC_DATA_o            : out std_logic;

    PMACENC_PROTOCOL_o       : out std_logic_vector(31 downto 0);
    PMACENC_PROTOCOL_WSTB_o  : out std_logic;
    INCENC_PROTOCOL_o        : out std_logic_vector(31 downto 0);
    INCENC_PROTOCOL_WSTB_o   : out std_logic;
    ABSENC_PROTOCOL_o        : out std_logic_vector(31 downto 0);
    ABSENC_PROTOCOL_WSTB_o   : out std_logic;

    PMACENC_CONN_OUT_o       : out std_logic;
    INCENC_CONN_OUT_o        : out std_logic;
    ABSENC_CONN_OUT_o        : out std_logic;

    UVWT_o                   : out std_logic;


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
    posn_o                  : out std_logic_vector(31 downto 0);
    abs_posn_o              : out std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of pandabrick_encoders_block is

signal reset            : std_logic;

-- Block Configuration Registers
signal GENERATOR_ERROR          : std_logic_vector(31 downto 0);
signal PMACENC_PROTOCOL         : std_logic_vector(31 downto 0);
signal PMACENC_PROTOCOL_WSTB    : std_logic;
signal PMACENC_ENCODING         : std_logic_vector(31 downto 0);
signal PMACENC_ENCODING_WSTB    : std_logic;
signal PMACENC_BITS             : std_logic_vector(31 downto 0);
signal PMACENC_BITS_WSTB        : std_logic;
signal QPERIOD                  : std_logic_vector(31 downto 0);
signal QPERIOD_WSTB             : std_logic;
signal QSTATE                   : std_logic_vector(31 downto 0);
signal DCARD_TYPE               : std_logic_vector(31 downto 0);
signal PMACENC_HEALTH           : std_logic_vector(31 downto 0);
signal a_ext, b_ext, z_ext, data_ext    : std_logic;
signal posn                     : std_logic_vector(31 downto 0);
signal enable                   : std_logic;

signal clk_ext                  : std_logic;
-- Block Configuration Registers
signal INCENC_PROTOCOL          : std_logic_vector(31 downto 0);
signal INCENC_PROTOCOL_WSTB     : std_logic;
signal INCENC_ENCODING          : std_logic_vector(31 downto 0);
signal INCENC_ENCODING_WSTB     : std_logic;
signal ABSENC_PROTOCOL          : std_logic_vector(31 downto 0);
signal ABSENC_PROTOCOL_WSTB     : std_logic;
signal ABSENC_ENCODING          : std_logic_vector(31 downto 0);
signal ABSENC_ENCODING_WSTB     : std_logic;
signal CLK_SRC                  : std_logic_vector(31 downto 0);
signal CLK_PERIOD               : std_logic_vector(31 downto 0);
signal CLK_PERIOD_WSTB          : std_logic;
signal FRAME_PERIOD             : std_logic_vector(31 downto 0);
signal FRAME_PERIOD_WSTB        : std_logic;
signal INCENC_BITS              : std_logic_vector(31 downto 0);
signal INCENC_BITS_WSTB         : std_logic;
signal ABSENC_BITS              : std_logic_vector(31 downto 0);
signal ABSENC_BITS_WSTB         : std_logic;
signal SETP                     : std_logic_vector(31 downto 0);
signal SETP_WSTB                : std_logic;
signal RST_ON_Z                 : std_logic_vector(31 downto 0);
signal STATUS                   : std_logic_vector(31 downto 0);
signal absenc_STATUS            : std_logic_vector(31 downto 0);
signal read_ack                 : std_logic;
signal LSB_DISCARD              : std_logic_vector(31 downto 0);
signal MSB_DISCARD              : std_logic_vector(31 downto 0);
signal ABSENC_LSB_DISCARD       : std_logic_vector(31 downto 0);
signal ABSENC_MSB_DISCARD       : std_logic_vector(31 downto 0);
signal INCENC_HEALTH            : std_logic_vector(31 downto 0);
signal ABSENC_HEALTH            : std_logic_vector(31 downto 0);
signal HOMED                    : std_logic_vector(31 downto 0);
signal ABSENC_ENABLED           : std_logic_vector(31 downto 0);
signal ABSENC_HOMED             : std_logic_vector(31 downto 0);

signal read_addr                : natural range 0 to (2**read_address_i'length - 1);

begin

-- Assign outputs

INCENC_PROTOCOL_o <= INCENC_PROTOCOL;
INCENC_PROTOCOL_WSTB_o <= INCENC_PROTOCOL_WSTB;
ABSENC_PROTOCOL_o <= ABSENC_PROTOCOL;
ABSENC_PROTOCOL_WSTB_o <= ABSENC_PROTOCOL_WSTB;
PMACENC_PROTOCOL_o <= PMACENC_PROTOCOL;
PMACENC_PROTOCOL_WSTB_o <= PMACENC_PROTOCOL_WSTB;

PMACENC_CONN_OUT_o <= enable;

-- Input encoder connection status comes from either
--  * Dcard pin [12] for incremental, or
--  * link_up status for absolute in loopback mode
INCENC_CONN_OUT_o <= STATUS(0);
ABSENC_CONN_OUT_o <= ABSENC_STATUS(0);
-- Certain parameter changes must initiate a block reset.
reset <= reset_i or PMACENC_PROTOCOL_WSTB or PMACENC_BITS_WSTB or INCENC_PROTOCOL_WSTB
         or PMACENC_ENCODING_WSTB or ABSENC_ENCODING_WSTB or ABSENC_PROTOCOL_WSTB
         or CLK_PERIOD_WSTB or FRAME_PERIOD_WSTB or INCENC_BITS_WSTB;

DCARD_TYPE <= x"0000000" & '0' & DCARD_MODE_i(3 downto 1);

--------------------------------------------------------------------------
-- Control System Interface
--------------------------------------------------------------------------
pmacenc_ctrl : entity work.pmacenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    data_from_bus       => data_ext,
    enable_from_bus     => enable,
    val_from_bus        => posn,

    read_strobe_i       => PMACENC_read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => PMACENC_read_data_o,
    read_ack_o          => PMACENC_read_ack_o,

    write_strobe_i      => PMACENC_write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => PMACENC_write_ack_o,

    -- Block Parameters
    GENERATOR_ERROR     => GENERATOR_ERROR,
    PROTOCOL            => PMACENC_PROTOCOL,
    PROTOCOL_WSTB       => PMACENC_PROTOCOL_WSTB,
    ENCODING            => PMACENC_ENCODING,
    ENCODING_WSTB       => PMACENC_ENCODING_WSTB,
    DCARD_TYPE          => DCARD_TYPE,
    BITS                => PMACENC_BITS,
    BITS_WSTB           => PMACENC_BITS_WSTB,
    HEALTH              => PMACENC_HEALTH
);

incenc_ctrl : entity work.incenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,

    read_strobe_i       => INCENC_read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => INCENC_read_data_o,
    read_ack_o          => INCENC_read_ack_o,

    write_strobe_i      => INCENC_write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => INCENC_write_ack_o,

    PROTOCOL            => INCENC_PROTOCOL,
    PROTOCOL_WSTB       => INCENC_PROTOCOL_WSTB,
    BITS                => INCENC_BITS,
    BITS_WSTB           => INCENC_BITS_WSTB,
    LSB_DISCARD         => LSB_DISCARD,
    LSB_DISCARD_WSTB    => open,
    MSB_DISCARD         => MSB_DISCARD,
    MSB_DISCARD_WSTB    => open,
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z,
    RST_ON_Z_WSTB       => open,
    HEALTH              => INCENC_HEALTH,
    HOMED               => HOMED,
    QPERIOD             => QPERIOD,
    QSTATE              => QSTATE
);

absenc_ctrl : entity work.absenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    clk_from_bus        => clk_ext,

    read_strobe_i       => ABSENC_read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => ABSENC_read_data_o,
    read_ack_o          => ABSENC_read_ack_o,

    write_strobe_i      => ABSENC_write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => ABSENC_write_ack_o,

    PROTOCOL            => ABSENC_PROTOCOL,
    PROTOCOL_WSTB       => ABSENC_PROTOCOL_WSTB,
    ENCODING            => ABSENC_ENCODING,
    ENCODING_WSTB       => ABSENC_ENCODING_WSTB,
    CLK_SRC             => CLK_SRC,
    CLK_SRC_WSTB        => open,
    CLK_PERIOD          => CLK_PERIOD,
    CLK_PERIOD_WSTB     => CLK_PERIOD_WSTB,
    FRAME_PERIOD        => FRAME_PERIOD,
    FRAME_PERIOD_WSTB   => FRAME_PERIOD_WSTB,
    BITS                => ABSENC_BITS,
    BITS_WSTB           => ABSENC_BITS_WSTB,
    LSB_DISCARD         => ABSENC_LSB_DISCARD,
    LSB_DISCARD_WSTB    => open,
    MSB_DISCARD         => ABSENC_MSB_DISCARD,
    MSB_DISCARD_WSTB    => open,
    HEALTH              => ABSENC_HEALTH,
    HOMED               => ABSENC_HOMED,
    ENABLED             => ABSENC_ENABLED,       -- TO BE CONNECTED THROUGH TO ENCODERS.VHD
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
    INCENC_A_o          => INCENC_A_o,
    INCENC_B_o          => INCENC_B_o,
    INCENC_Z_o          => INCENC_Z_o,
    ABSENC_DATA_o       => ABSENC_DATA_o,
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
    PMACENC_PROTOCOL_i  => PMACENC_PROTOCOL(2 downto 0),
    PMACENC_ENCODING_i  => PMACENC_ENCODING(1 downto 0),
    PMACENC_BITS_i      => PMACENC_BITS(7 downto 0),
    QPERIOD_i           => QPERIOD,
    QPERIOD_WSTB_i      => QPERIOD_WSTB,
    PMACENC_HEALTH_o    => PMACENC_HEALTH,
    QSTATE_o            => QSTATE,

    INCENC_PROTOCOL_i   => INCENC_PROTOCOL(2 downto 0),
    INCENC_ENCODING_i   => INCENC_ENCODING(1 downto 0),
    INCENC_BITS_i       => INCENC_BITS(7 downto 0),
    LSB_DISCARD_i       => LSB_DISCARD(4 downto 0),
    MSB_DISCARD_i       => MSB_DISCARD(4 downto 0),
    SETP_i              => SETP,
    SETP_WSTB_i         => SETP_WSTB,
    RST_ON_Z_i          => RST_ON_Z,
    STATUS_o            => STATUS,
    INCENC_HEALTH_o     => INCENC_HEALTH,
    HOMED_o             => HOMED,

    DCARD_MODE_i        => DCARD_MODE_i,
    ABSENC_PROTOCOL_i   => ABSENC_PROTOCOL(2 downto 0),
    ABSENC_ENCODING_i   => ABSENC_ENCODING(1 downto 0),
    CLK_SRC_i           => CLK_SRC(0),
    CLK_PERIOD_i        => CLK_PERIOD,
    FRAME_PERIOD_i      => FRAME_PERIOD,
    ABSENC_BITS_i       => ABSENC_BITS(7 downto 0),
    ABSENC_LSB_DISCARD_i => ABSENC_LSB_DISCARD(4 downto 0),
    ABSENC_MSB_DISCARD_i => ABSENC_MSB_DISCARD(4 downto 0),
    ABSENC_STATUS_o      => ABSENC_STATUS,
    ABSENC_HEALTH_o     => ABSENC_HEALTH,
    ABSENC_ENABLED_o    => ABSENC_ENABLED,
    ABSENC_HOMED_o      => ABSENC_HOMED,

    UVWT_o              => UVWT_o,
    --
    -- Block Outputs
    abs_posn_o          => abs_posn_o,
    inc_posn_o          => posn_o
);

end rtl;
