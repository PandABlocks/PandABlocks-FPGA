library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;
use work.support.all;

entity pandabrick_encoders is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder inputs from Bitbus
    a_ext_i             : in  std_logic;
    b_ext_i             : in  std_logic;
    z_ext_i             : in  std_logic;

    data_ext_i          : in  std_logic;
    posn_i              : in  std_logic_vector(31 downto 0);
    enable_i            : in  std_logic;
    -- Encoder I/O Pads
    -- INCENC_A_o          : out std_logic;
    -- INCENC_B_o          : out std_logic;
    -- INCENC_Z_o          : out std_logic;
    ABSENC_DATA_o       : out std_logic;
    --
    clk_out_ext_i       : in  std_logic;
    clk_int_o           : out std_logic;
    --
    pin_ENC_A_in        : in  std_logic;
    pin_ENC_B_in        : in  std_logic;
    pin_ENC_Z_in        : in  std_logic;
    pin_ENC_A_out       : out std_logic;
    pin_ENC_B_out       : out std_logic;
    pin_ENC_Z_out       : out std_logic;

    pin_PMAC_SCLK_RX    : in std_logic;
    pin_ENC_SDA_RX      : in std_logic;
    pin_PMAC_SDA_RX     : in std_logic; --dangling
    pin_ENC_SCLK_RX     : in std_logic; --dangling

    pin_ENC_SCLK_TX     : out std_logic;
    pin_ENC_SDA_TX      : out std_logic; --dangling
    pin_ENC_SDA_TX_EN   : out std_logic; --dangling
    pin_PMAC_SDA_TX     : out std_logic;
    pin_PMAC_SDA_TX_EN  : out std_logic;

    -- Block parameters
    GENERATOR_ERROR_i   : in  std_logic;
    PMACENC_PROTOCOL_i  : in  std_logic_vector(2 downto 0);
    PMACENC_ENCODING_i  : in  std_logic_vector(1 downto 0);
    PMACENC_BITS_i      : in  std_logic_vector(7 downto 0);
    QPERIOD_i           : in  std_logic_vector(31 downto 0);
    QPERIOD_WSTB_i      : in  std_logic;
    PMACENC_HEALTH_o    : out std_logic_vector(31 downto 0);
    QSTATE_o            : out std_logic_vector(31 downto 0);

    INCENC_PROTOCOL_i   : in  std_logic_vector(2 downto 0);
    INCENC_ENCODING_i   : in  std_logic_vector(1 downto 0);
    INCENC_BITS_i       : in  std_logic_vector(7 downto 0);
    LSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    MSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    SETP_i              : in  std_logic_vector(31 downto 0);
    SETP_WSTB_i         : in  std_logic;
    RST_ON_Z_i          : in  std_logic_vector(31 downto 0);
    STATUS_o            : out std_logic_vector(31 downto 0);
    INCENC_HEALTH_o     : out std_logic_vector(31 downto 0);
    HOMED_o             : out std_logic_vector(31 downto 0);

    ABSENC_PROTOCOL_i   : in  std_logic_vector(2 downto 0);
    ABSENC_ENCODING_i   : in  std_logic_vector(1 downto 0);
    CLK_SRC_i           : in  std_logic;
    CLK_PERIOD_i        : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD_i      : in  std_logic_vector(31 downto 0);
    ABSENC_BITS_i       : in  std_logic_vector(7 downto 0);
    ABSENC_LSB_DISCARD_i   : in  std_logic_vector(4 downto 0);
    ABSENC_MSB_DISCARD_i   : in  std_logic_vector(4 downto 0);
    ABSENC_STATUS_o        : out std_logic_vector(31 downto 0);
    ABSENC_HEALTH_o     : out std_logic_vector(31 downto 0);
    ABSENC_HOMED_o      : out std_logic_vector(31 downto 0);
    ABSENC_ENABLED_o    : out std_logic_vector(31 downto 0);

    UVWT_o              : out std_logic;

    -- Block Outputs
    abs_posn_o          : out std_logic_vector(31 downto 0);
    inc_posn_o          : out std_logic_vector(31 downto 0)
);
end entity;


architecture rtl of pandabrick_encoders is

-- constant c_ABZ_PASSTHROUGH  : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(4,3));
-- constant c_DATA_PASSTHROUGH : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(5,3));
constant c_BISS             : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(5,3));
-- constant c_enDat            : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(3,3));

signal quad_a               : std_logic;
signal quad_b               : std_logic;
signal PASSTHROUGH          : std_logic;

signal clk_out_encoder_biss : std_logic;
signal posn                 : std_logic_vector(31 downto 0);
signal posn_prev            : std_logic_vector(31 downto 0);

signal PROTOCOL_FOR_ABSENC  : std_logic_vector(2 downto 0) := "000";
signal ABSENC_ENABLED       : std_logic_vector(31 downto 0);

signal Am0_ipad             : std_logic;
signal Bm0_ipad             : std_logic;
signal Zm0_ipad             : std_logic;
signal clkin_ipad           : std_logic;
signal datain_ipad          : std_logic;

signal As0_opad             : std_logic;
signal Bs0_opad             : std_logic;
signal Zs0_opad             : std_logic;

signal A_IN                 : std_logic;
signal B_IN                 : std_logic;
signal Z_IN                 : std_logic;
signal DATA_IN              : std_logic;

signal A_OUT                : std_logic;
signal B_OUT                : std_logic;
signal Z_OUT                : std_logic;
signal DATA_OUT             : std_logic;

signal CLK_OUT              : std_logic;

signal CLK_IN               : std_logic;

begin

-----------------------------INCENC---------------------------------------------
incenc_inst : entity work.incenc
port map(

    clk_i               => clk_i,
    reset_i             => reset_i,
    posn_i              => posn_i,
    enable_i            => enable_i,
    QPERIOD_i           => QPERIOD_i,
    QPERIOD_WSTB_i      => QPERIOD_WSTB_i,
    QSTATE_o            => QSTATE_o,
    INCENC_BITS_i       => INCENC_BITS_i,
    LSB_DISCARD_i       => LSB_DISCARD_i,
    MSB_DISCARD_i       => MSB_DISCARD_i,
    INCENC_PROTOCOL_i   => INCENC_PROTOCOL_i,
    SETP_i              => SETP_i,
    SETP_WSTB_i         => SETP_WSTB_i,
    RST_ON_Z_i          => RST_ON_Z_i,
    STATUS_o            => STATUS_o,
    INCENC_HEALTH_o     => INCENC_HEALTH_o,
    HOMED_o             => HOMED_o,
    A_IN_i              => A_IN,
    B_IN_i              => B_IN,
    Z_IN_i              => Z_IN,
    quad_a_o            => quad_a,
    quad_b_o            => quad_b,
    inc_posn_o          => inc_posn_o
);

-----------------------------ABSENC---------------------------------------------

absenc_inst : entity work.absenc
port map(
    clk_i                   => clk_i,
    reset_i                 => reset_i,
    clk_out_ext_i           => clk_out_ext_i,
    ABSENC_PROTOCOL_i       => ABSENC_PROTOCOL_i,
    ABSENC_ENCODING_i       =>  ABSENC_ENCODING_i,
    CLK_SRC_i               => CLK_SRC_i,
    CLK_PERIOD_i            => CLK_PERIOD_i,
    FRAME_PERIOD_i          => FRAME_PERIOD_i,
    ABSENC_BITS_i           => ABSENC_BITS_i,
    ABSENC_LSB_DISCARD_i    => ABSENC_LSB_DISCARD_i,
    ABSENC_MSB_DISCARD_i    => ABSENC_MSB_DISCARD_i,
    ABSENC_STATUS_o         => ABSENC_STATUS_o,
    ABSENC_HEALTH_o         => ABSENC_HEALTH_o,
    ABSENC_HOMED_o          => ABSENC_HOMED_o,
    ABSENC_ENABLED_i        => ABSENC_ENABLED,
    abs_posn_o              => abs_posn_o,
    PROTOCOL_FOR_ABSENC_i   => PROTOCOL_FOR_ABSENC,
    PASSTHROUGH_i           => PASSTHROUGH,
    DATA_IN_i               => DATA_IN,
    CLK_IN_i                => CLK_IN,
    CLK_OUT_o               => CLK_OUT,
    clk_out_encoder_biss_o  => clk_out_encoder_biss
);

-----------------------------PMACENC---------------------------------------------

ABSENC_ENABLED_o <= ABSENC_ENABLED;

pmacenc_inst : entity work.pmacenc
port map(
    clk_i                 => clk_i,
    reset_i               => reset_i,
    a_ext_i               => a_ext_i,
    b_ext_i               => b_ext_i,
    z_ext_i               => z_ext_i,
    data_ext_i            => data_ext_i,
    posn_i                => posn_i,
    enable_i              => enable_i,
    GENERATOR_ERROR_i     => GENERATOR_ERROR_i,
    PMACENC_PROTOCOL_i    => PMACENC_PROTOCOL_i,
    PMACENC_ENCODING_i    => PMACENC_ENCODING_i,
    PMACENC_BITS_i        => PMACENC_BITS_i,
    PMACENC_HEALTH_o      => PMACENC_HEALTH_o,
    ABSENC_ENABLED_o      => ABSENC_ENABLED,
    UVWT_o                => UVWT_o,
    CLK_IN_i              => CLK_IN,
    quad_a_i              => quad_a,
    quad_b_i              => quad_b,
    A_OUT_o               => A_OUT,
    B_OUT_o               => B_OUT,
    Z_OUT_o               => Z_OUT,
    DATA_OUT_o            => DATA_OUT,
    PASSTHROUGH_O         => PASSTHROUGH,
    PROTOCOL_FOR_ABSENC_o => PROTOCOL_FOR_ABSENC
);
-------------------dcard_interface----------------------------------------------
--------------------------------------------------------------------------------

-- ensure this is packed in IOB?? Check synth settings + chip viewer!
REG_INPUTS: process(clk_i)
begin
    if rising_edge(clk_i) then
        Am0_ipad <= pin_ENC_A_in;
        Bm0_ipad <= pin_ENC_B_in;
        Zm0_ipad <= pin_ENC_Z_in;
        clkin_ipad <= pin_PMAC_SCLK_RX;
        datain_ipad <= pin_ENC_SDA_RX;
    end if;
end process;

a_filt : entity work.delay_filter port map(
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => Am0_ipad,
    filt_o  => A_IN
);

b_filt : entity work.delay_filter port map(
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => Bm0_ipad,
    filt_o  => B_IN
);

z_filt : entity work.delay_filter port map(
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => Zm0_ipad,
    filt_o  => Z_IN
);

datain_filt : entity work.delay_filter port map(
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => datain_ipad,
    filt_o  => DATA_IN
);

-- ensure this is packed in IOB?? Check synth settings + chip viewer!
REG_OUTPUTS: process(clk_i)
begin
    if rising_edge(clk_i) then
        pin_ENC_A_out <= As0_opad;
        pin_ENC_B_out <= Bs0_opad;
        pin_ENC_Z_out <= Zs0_opad;
        pin_ENC_SCLK_TX <= CLK_OUT;
        pin_PMAC_SDA_TX <= DATA_OUT;
    end if;
end process;

As0_opad <= A_OUT;
Bs0_opad <= B_OUT;
Zs0_opad <= Z_OUT;

-- INCENC_A_o <= A_IN;
-- INCENC_B_o <= B_IN;
-- INCENC_Z_o <= Z_IN;

ABSENC_DATA_o <= DATA_IN;

clk_int_o <= CLK_IN;

pin_PMAC_SDA_TX_EN <= '0';

clkin_filt : entity work.delay_filter port map (
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => clkin_ipad,
    filt_o  => CLK_IN
);
end rtl;

