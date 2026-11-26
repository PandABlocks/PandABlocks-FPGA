--------------------------------------------------------------------------------
--  PandA Motion Project
--      Diamond Light Source, Oxford, UK
--------------------------------------------------------------------------------
--
--  Description : Test wrapper for the encoders entity on a PandABox encoder
--                daughter card. The daughter card data transceivers are
--                modelled: each is driven from the A pad, switched between
--                transmit and receive by the Z pad, and its receiver reads
--                an undriven line as high (the SN65HVD05 is failsafe).
--                With ext_drive_i low the INENC lines are looped back to the
--                OUTENC lines as with a control card and a loopback cable,
--                which cable_i low unplugs at the OUTENC end.
--                With ext_drive_i high an external EnDat bus, a master's
--                clock on ext_sck_i and the data line on ext_dat_i, is
--                connected instead, as seen by a monitor card.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity encoders_endat_loopback is
port (
    clk_i : in  std_logic;
    reset_i : in  std_logic;
    -- INENC parameters
    INENC_PROTOCOL : in  std_logic_vector(2 downto 0);
    INENC_ENCODING : in  std_logic_vector(1 downto 0);
    CLK_PERIOD : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD : in  std_logic_vector(31 downto 0);
    DELAY_COMP : in  std_logic_vector(15 downto 0);
    INENC_BITS : in  std_logic_vector(7 downto 0);
    -- OUTENC parameters
    OUTENC_PROTOCOL : in  std_logic_vector(2 downto 0);
    OUTENC_BITS : in  std_logic_vector(7 downto 0);
    GENERATOR_ERROR : in  std_logic;
    posn_i : in  std_logic_vector(31 downto 0);
    -- Daughter card mode and protocol readback
    DCARD_MODE : in  std_logic_vector(31 downto 0);
    -- Loopback cable connected
    cable_i : in  std_logic;
    -- External EnDat bus replacing the loopback
    ext_drive_i : in  std_logic;
    ext_sck_i : in  std_logic;
    ext_dat_i : in  std_logic;
    -- INENC outputs
    posn_o : out std_logic_vector(31 downto 0);
    STATUS_o : out std_logic_vector(31 downto 0);
    INENC_HEALTH_o : out std_logic_vector(31 downto 0);
    HOMED_o : out std_logic_vector(31 downto 0);
    -- OUTENC outputs
    OUTENC_HEALTH_o : out std_logic_vector(31 downto 0);
    -- The data line, Z when released and X when driven from both ends
    data_line_o : out std_logic;
    -- The clock line
    clk_line_o : out std_logic
);
end;

architecture rtl of encoders_endat_loopback is

constant ZERO32 : std_logic_vector(31 downto 0) := (others => '0');
constant ZERO5 : std_logic_vector(4 downto 0) := (others => '0');

-- Encoder pads
signal Am0, Bm0, Zm0 : std_logic;
signal As0, Bs0, Zs0 : std_logic;

-- Data transceivers transmitting
signal m_tx : boolean;
signal s_tx : boolean;
signal data_line : std_logic;

begin

encoders_inst : entity work.encoders
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    a_ext_i             => '0',
    b_ext_i             => '0',
    z_ext_i             => '0',
    data_ext_i          => '0',
    posn_i              => posn_i,
    enable_i            => '1',
    INENC_A_o           => open,
    INENC_B_o           => open,
    INENC_Z_o           => open,
    INENC_DATA_o        => open,
    clk_out_ext_i       => '0',
    clk_int_o           => open,
    Am0_pad_io          => Am0,
    Bm0_pad_io          => Bm0,
    Zm0_pad_io          => Zm0,
    As0_pad_io          => As0,
    Bs0_pad_io          => Bs0,
    Zs0_pad_io          => Zs0,
    GENERATOR_ERROR_i   => GENERATOR_ERROR,
    OUTENC_PROTOCOL_i   => OUTENC_PROTOCOL,
    OUTENC_ENCODING_i   => "00",
    OUTENC_BITS_i       => OUTENC_BITS,
    QPERIOD_i           => ZERO32,
    QPERIOD_WSTB_i      => '0',
    OUTENC_HEALTH_o     => OUTENC_HEALTH_o,
    QSTATE_o            => open,
    DCARD_MODE_i        => DCARD_MODE,
    INENC_PROTOCOL_i    => INENC_PROTOCOL,
    INENC_ENCODING_i    => INENC_ENCODING,
    CLK_SRC_i           => '0',
    CLK_PERIOD_i        => CLK_PERIOD,
    FRAME_PERIOD_i      => FRAME_PERIOD,
    DELAY_COMP_i        => DELAY_COMP,
    INENC_BITS_i        => INENC_BITS,
    LSB_DISCARD_i       => ZERO5,
    MSB_DISCARD_i       => ZERO5,
    SETP_i              => ZERO32,
    SETP_WSTB_i         => '0',
    RST_ON_Z_i          => ZERO32,
    STATUS_o            => STATUS_o,
    INENC_HEALTH_o      => INENC_HEALTH_o,
    HOMED_o             => HOMED_o,
    posn_o              => posn_o
);

-- Clock output transceiver to clock input transceiver, or the external
-- master's clock. The clock input receiver reads high when unplugged.
Bs0 <= ext_sck_i when ext_drive_i = '1' else
       to_X01(Bm0) when cable_i = '1' else '1';
clk_line_o <= to_X01(Bm0);

-- Data transceivers drive the line while their Z pad is high, the OUTENC
-- one only reaches the line while the cable is connected
m_tx <= to_X01(Zm0) = '1';
s_tx <= to_X01(Zs0) = '1';
data_line <= to_X01(Am0) when m_tx else 'Z';
data_line <= to_X01(As0) when s_tx and cable_i = '1' else 'Z';
data_line <= ext_dat_i when ext_drive_i = '1' else 'Z';
data_line_o <= data_line;

-- Their receivers drive the A pads while not transmitting, high when the
-- line is not driven or not connected (failsafe)
Am0 <= 'Z' when m_tx else '1' when data_line = 'Z' else data_line;
As0 <= 'Z' when s_tx else
       '1' when data_line = 'Z' or cable_i = '0' else data_line;

end;
