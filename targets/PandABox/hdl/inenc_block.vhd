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
use work.addr_defines.all;
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
    A_IN                : in  std_logic;
    B_IN                : in  std_logic;
    Z_IN                : in  std_logic;
    CLK_OUT             : out std_logic;
    DATA_IN             : in  std_logic;
    CLK_IN              : in  std_logic;
    CONN_OUT            : out std_logic;
    -- Block Outputs.
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    DCARD_MODE          : in  std_logic_vector(31 downto 0);
    PROTOCOL            : out std_logic_vector(2 downto 0);
    posn_o              : out std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of inenc_block is


signal clk_ext          : std_logic;
-- Block Configuration Registers
signal PROTOCOL_i       : std_logic_vector(31 downto 0);
signal PROTOCOL_WSTB    : std_logic;
signal CLK_SRC          : std_logic_vector(31 downto 0);
signal CLK_PERIOD       : std_logic_vector(31 downto 0);
signal CLK_PERIOD_WSTB  : std_logic;
signal FRAME_PERIOD     : std_logic_vector(31 downto 0);
signal FRAME_PERIOD_WSTB: std_logic;
signal BITS             : std_logic_vector(31 downto 0);
signal BITS_WSTB        : std_logic;
signal SETP             : std_logic_vector(31 downto 0);
signal SETP_WSTB        : std_logic;
signal RST_ON_Z         : std_logic_vector(31 downto 0);
signal STATUS           : std_logic_vector(31 downto 0);
signal read_ack         : std_logic;
signal LSB_DISCARD      : std_logic_vector(31 downto 0);
signal MSB_DISCARD      : std_logic_vector(31 downto 0);
signal HEALTH           : std_logic_vector(31 downto 0);
signal DCARD_TYPE       : std_logic_vector(31 downto 0);
signal HOMED            : std_logic_vector(31 downto 0);

signal reset            : std_logic;
signal slow             : slow_packet;

signal read_addr        : natural range 0 to (2**read_address_i'length - 1);

begin

-- Assign outputs
PROTOCOL <= PROTOCOL_i(2 downto 0);

-- Input encoder connection status comes from either
--  * Dcard pin [12] for incremental, or
--  * link_up status for absolute in loopback mode
CONN_OUT <= STATUS(0);

-- Certain parameter changes must initiate a block reset.
reset <= PROTOCOL_WSTB or CLK_PERIOD_WSTB or
            FRAME_PERIOD_WSTB or BITS_WSTB;

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
    CLK_SRC             => CLK_SRC,
    CLK_SRC_WSTB        => open,
    CLK_PERIOD          => CLK_PERIOD,
    CLK_PERIOD_WSTB     => CLK_PERIOD_WSTB,
    FRAME_PERIOD        => FRAME_PERIOD,
    FRAME_PERIOD_WSTB   => FRAME_PERIOD_WSTB,
    BITS                => BITS,
    BITS_WSTB           => BITS_WSTB,
    LSB_DISCARD         => LSB_DISCARD,
    LSB_DISCARD_WSTB    => open,
    MSB_DISCARD         => MSB_DISCARD,
    MSB_DISCARD_WSTB    => open,
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z,
    RST_ON_Z_WSTB       => open,
    HEALTH              => HEALTH,
    HOMED               => HOMED,
    DCARD_TYPE          => DCARD_TYPE
);

-- Only read back the DCARD MODE
DCARD_TYPE <= x"0000000" & '0' & DCARD_MODE(3 downto 1);


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
    A_IN                => A_IN,
    B_IN                => B_IN,
    Z_IN                => Z_IN,
    CLK_OUT             => CLK_OUT,
    DATA_IN             => DATA_IN,
    CLK_IN              => CLK_IN,
    --
    clk_out_ext_i       => clk_ext,
    --
    DCARD_MODE          => DCARD_MODE,
    PROTOCOL            => PROTOCOL_i(2 downto 0),
    CLK_SRC             => CLK_SRC(0),
    CLK_PERIOD          => CLK_PERIOD,
    FRAME_PERIOD        => FRAME_PERIOD,
    BITS                => BITS(7 downto 0),
    LSB_DISCARD         => LSB_DISCARD(4 downto 0),
    MSB_DISCARD         => MSB_DISCARD(4 downto 0),
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z,
    STATUS              => STATUS,
    HEALTH              => HEALTH,
    HOMED               => HOMED,
    --
    posn_o              => posn_o
);

end rtl;
