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
    -- Memory Bus Interface.
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
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
    posn_upper_o        : out std_logic_vector(31 downto 0)
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
signal SETP             : std_logic_vector(31 downto 0);
signal SETP_WSTB        : std_logic;
signal RST_ON_Z         : std_logic_vector(31 downto 0);
signal EXTENSION        : std_logic_vector(31 downto 0);
signal ERR_FRAME        : std_logic_vector(31 downto 0);
signal ERR_RESPONSE     : std_logic_vector(31 downto 0);
signal ENC_STATUS       : std_logic_vector(31 downto 0);

signal reset            : std_logic;
signal slow             : slow_packet;

signal mem_addr : natural range 0 to (2**mem_addr_i'length - 1);

begin

-- Assign outputs
PROTOCOL <= PROTOCOL_i(2 downto 0);

mem_addr <= to_integer(unsigned(mem_addr_i));

-- Certain parameter changes must initiate a block reset.
reset <= reset_i or PROTOCOL_WSTB or CLK_PERIOD_WSTB or
            FRAME_PERIOD_WSTB or BITS_WSTB;

--
-- Control System Interface
--
inenc_ctrl : entity work.inenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => (others => '0'),
    posbus_i            => (others => (others => '0')),

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => open,

    PROTOCOL            => PROTOCOL_i,
    PROTOCOL_WSTB       => PROTOCOL_WSTB,
    CLK_PERIOD          => CLK_PERIOD,
    CLK_PERIOD_WSTB     => CLK_PERIOD_WSTB,
    FRAME_PERIOD        => FRAME_PERIOD,
    FRAME_PERIOD_WSTB   => FRAME_PERIOD_WSTB,
    BITS                => BITS,
    BITS_WSTB           => BITS_WSTB,
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
    -- Encoder I/O Pads
    a_i                 => a_i,
    b_i                 => b_i,
    z_i                 => z_i,
    clk_out_o           => clk_out_o,
    data_in_i           => data_in_i,
    clk_in_i            => clk_in_i,
    conn_o              => conn_o,
    -- Block Parameters
    DCARD_MODE          => DCARD_MODE,
    PROTOCOL            => PROTOCOL_i(2 downto 0),
    CLKRATE             => CLK_PERIOD,
    FRAMERATE           => FRAME_PERIOD,
    BITS                => BITS(7 downto 0),
    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z(0),
    -- Status
    posn_o              => posn_o,
    posn_upper_o        => posn_upper_o
);

end rtl;
