--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Control register interface for INENC block.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity inenc_block is
port (
    -- Clock and Reset.
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
    -- Encoder I/O Pads.
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    z_i                 : in  std_logic;
    clk_out_o           : out std_logic;
    data_in_i           : in  std_logic;
    clk_in_i            : in  std_logic;
    conn_o              : out std_logic;
    -- Block Outputs.
    DCARD_MODE          : in  std_logic_vector(31 downto 0);
    PROTOCOL            : out std_logic_vector(2 downto 0);
    posn_o              : out std_logic_vector(31 downto 0);
    posn_trans_o        : out std_logic
);
end entity;

architecture rtl of inenc_block is

-- Block Configuration Registers
signal PROTOCOL_i       : std_logic_vector(31 downto 0);
signal PROTOCOL_WSTB    : std_logic;
signal CLK_PERIOD       : std_logic_vector(31 downto 0);
signal CLK_PERIOD_WSTB  : std_logic;
signal FRAME_PERIOD     : std_logic_vector(31 downto 0);
signal FRAME_PERIOD_WSTB: std_logic;
signal BITS             : std_logic_vector(31 downto 0);
signal BITS_WSTB        : std_logic;
signal STATUS_BITS      : std_logic_vector(31 downto 0);
signal STATUS_BITS_WSTB : std_logic;
signal CRC_BITS         : std_logic_vector(31 downto 0);
signal CRC_BITS_WSTB    : std_logic;
signal SETP             : std_logic_vector(31 downto 0);
signal SETP_WSTB        : std_logic;
signal RST_ON_Z         : std_logic_vector(31 downto 0);
signal EXTENSION        : std_logic_vector(31 downto 0);
signal ERR_FRAME        : std_logic_vector(31 downto 0);
signal ERR_RESPONSE     : std_logic_vector(31 downto 0);
signal ENC_STATUS       : std_logic_vector(31 downto 0);

signal reset            : std_logic;
signal slow             : slow_packet;

begin

-- Assign outputs
PROTOCOL <= PROTOCOL_i(2 downto 0);

-- Certain parameter changes must initiate a block reset.
reset <= reset_i or PROTOCOL_WSTB or CLK_PERIOD_WSTB or
            FRAME_PERIOD_WSTB or BITS_WSTB or
                STATUS_BITS_WSTB or CRC_BITS_WSTB;

--
-- Control System Interface
--
inenc_ctrl : entity work.inenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => (others => '0'),
    posbus_i            => (others => (others => '0')),

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    PROTOCOL            => PROTOCOL_i,
    PROTOCOL_WSTB       => PROTOCOL_WSTB,
    CLK_PERIOD          => CLK_PERIOD,
    CLK_PERIOD_WSTB     => CLK_PERIOD_WSTB,
    FRAME_PERIOD        => FRAME_PERIOD,
    FRAME_PERIOD_WSTB   => FRAME_PERIOD_WSTB,
    BITS                => BITS,
    BITS_WSTB           => BITS_WSTB,
    STATUS_BITS         => STATUS_BITS,
    STATUS_BITS_WSTB    => STATUS_BITS_WSTB,
    CRC_BITS            => CRC_BITS,
    CRC_BITS_WSTB       => CRC_BITS_WSTB,
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z,
    RST_ON_Z_WSTB       => open,
    EXTENSION           => EXTENSION,
    ERR_FRAME           => ERR_FRAME,
    ERR_RESPONSE        => ERR_RESPONSE,
    ENC_STATUS          => ENC_STATUS,
    DCARD_MODE          => DCARD_MODE
);

inenc_inst : entity work.inenc
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset,

    a_i                 => a_i,
    b_i                 => b_i,
    z_i                 => z_i,
    clk_out_o           => clk_out_o,
    data_in_i           => data_in_i,
    clk_in_i            => clk_in_i,
    conn_o              => conn_o,

    DCARD_MODE          => DCARD_MODE,
    PROTOCOL            => PROTOCOL_i(2 downto 0),
    CLK_PERIOD          => CLK_PERIOD,
    FRAME_PERIOD        => FRAME_PERIOD,
    BITS                => BITS(7 downto 0),
    STATUS_BITS         => STATUS_BITS(7 downto 0),
    CRC_BITS            => CRC_BITS(7 downto 0),
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z(0),

    posn_o              => posn_o,
    posn_trans_o        => posn_trans_o
);

end rtl;
