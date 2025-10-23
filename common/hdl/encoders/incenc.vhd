library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity incenc is
port(
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;

    posn_i              : in  std_logic_vector(31 downto 0);
    enable_i            : in  std_logic;

    INCENC_PROTOCOL_i   : in  std_logic_vector(2 downto 0);
    SETP_i              : in  std_logic_vector(31 downto 0);
    SETP_WSTB_i         : in  std_logic;
    RST_ON_Z_i          : in  std_logic_vector(31 downto 0);
    STATUS_o            : out std_logic_vector(31 downto 0);
    INCENC_HEALTH_o     : out std_logic_vector(31 downto 0);

    A_IN_i              : in  std_logic;
    B_IN_i              : in  std_logic;
    Z_IN_i              : in  std_logic;

    inc_posn_o          : out std_logic_vector(31 downto 0)
);
end entity;


architecture rtl of incenc is

signal A_IN                 : std_logic;
signal B_IN                 : std_logic;
signal Z_IN                 : std_logic;

signal inc_bits_not_used    : unsigned(4 downto 0);
signal posn_incr            : std_logic_vector(31 downto 0);
signal linkup_incr          : std_logic;
signal linkup_incr_std32    : std_logic_vector(31 downto 0);
signal step                 : std_logic;
signal dir                  : std_logic;
signal homed_qdec           : std_logic_vector(31 downto 0);


begin
--------------------------------------------------------------------------
-- Position Data and STATUS readback multiplexer
--
--  Link status information is valid only for loopback configuration
--------------------------------------------------------------------------
STATUS_o(0) <= linkup_incr;
INCENC_HEALTH_o(0) <= not(linkup_incr);
INCENC_HEALTH_o(31 downto 1)<= (others=>'0');
--------------------------------------------------------------------------
-- Incremental Encoder Instantiation :
--------------------------------------------------------------------------
qdec : entity work.qdec
port map (
    clk_i           => clk_i,
--  reset_i         => reset_i,
    LINKUP_INCR     => linkup_incr_std32,
    a_i             => A_IN_i,
    b_i             => B_IN_i,
    z_i             => Z_IN_i,
    SETP            => SETP_i,
    SETP_WSTB       => SETP_WSTB_i,
    RST_ON_Z        => RST_ON_Z_i,
    HOMED           => homed_qdec,
    out_o           => inc_posn_o
);

linkup_incr <= '1';
linkup_incr_std32 <= x"0000000"&"000"&linkup_incr;

end rtl;
