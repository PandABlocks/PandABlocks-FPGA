library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity outenc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder inputs from Bitbus
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    z_i                 : in  std_logic;
    posn_i              : in  std_logic_vector(31 downto 0);
    enable_i            : in  std_logic;
    -- Encoder I/O Pads
    a_o                 : out std_logic;
    b_o                 : out std_logic;
    z_o                 : out std_logic;
    sclk_i              : in  std_logic;
    sdat_i              : in  std_logic;
    sdat_o              : out std_logic;
    -- Block parameters
    PROTOCOL            : in  std_logic_vector(2 downto 0);
    BITS                : in  std_logic_vector(7 downto 0);
    QPERIOD             : in  std_logic_vector(31 downto 0);
    QPERIOD_WSTB        : in  std_logic;
    QSTATE              : out std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of outenc is

signal quad_a           : std_logic;
signal quad_b           : std_logic;

begin

-- Assign outputs
a_o <= a_i when (PROTOCOL = "100") else quad_a;
b_o <= b_i when (PROTOCOL = "100") else quad_b;
z_o <= z_i when (PROTOCOL = "100") else '0';

--
-- INCREMENTAL OUT
--
qenc_inst : entity work.qenc
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    QPERIOD         => QPERIOD,
    QPERIOD_WSTB    => QPERIOD_WSTB,
    QSTATE          => QSTATE,
    enable_i        => enable_i,
    posn_i          => posn_i,
    a_o             => quad_a,
    b_o             => quad_b
);

--
-- SSI SLAVE
--
ssi_slave_inst : entity work.ssi_slave
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    posn_i          => posn_i,
    ssi_sck_i       => sclk_i,
    ssi_dat_o       => sdat_o
);

end rtl;

