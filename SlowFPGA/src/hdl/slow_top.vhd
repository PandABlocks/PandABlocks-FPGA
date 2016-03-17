--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface core is used to handle communication between
--                Zynq and Slow Control FPGA.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.slow_defines.all;
use work.type_defines.all;

library unisim;
use unisim.vcomponents.all;

entity slow_top is
port (
    -- 50MHz system clock
    clk_i               : in    std_logic;
    -- Encoder Daughter Card Control interface
    enc_ctrl1_io        : inout std_logic_vector(15 downto 0);
    enc_ctrl2_io        : inout std_logic_vector(15 downto 0);
    enc_ctrl3_io        : inout std_logic_vector(15 downto 0);
    enc_ctrl4_io        : inout std_logic_vector(15 downto 0);
    -- Serial Physical interface
    spi_sclk_i          : in    std_logic;
    spi_dat_i           : in    std_logic;
    spi_sclk_o          : out   std_logic;
    spi_dat_o           : out   std_logic
);
end slow_top;

architecture rtl of slow_top is

signal FPGA_VERSION     : std_logic_vector(31 downto 0);
signal ENC_CONN         : std_logic_vector(31 downto 0);

signal reset_n      : std_logic;
signal reset        : std_logic;

signal enc_ctrl1    : std_logic_vector(11 downto 0);
signal enc_ctrl2    : std_logic_vector(11 downto 0);
signal enc_ctrl3    : std_logic_vector(11 downto 0);
signal enc_ctrl4    : std_logic_vector(11 downto 0);
signal ttlin_term   : std_logic_vector(5 downto 0);
signal ttl_leds     : std_logic_vector(15 downto 0);
signal status_leds  : std_logic_vector(3 downto 0);

signal status_regs  : std32_array(REGS_NUM-1 downto 0);

signal enc_connected: std_logic_vector(3 downto 0);

begin

--
-- Startup Reset
--
reset_inst : SRL16
port map (
    Q       => reset_n,
    A0      => '1',
    A1      => '1',
    A2      => '1',
    A3      => '1',
    CLK     => clk_i,
    D       => '1'
);

reset <= not reset_n;

-- Assign outputs
enc_ctrl1_io(11 downto 0) <= enc_ctrl1;
enc_ctrl2_io(11 downto 0) <= enc_ctrl2;
enc_ctrl3_io(11 downto 0) <= enc_ctrl3;
enc_ctrl4_io(11 downto 0) <= enc_ctrl4;

enc_connected <=    enc_ctrl1_io(15) &
                    enc_ctrl2_io(15) &
                    enc_ctrl3_io(15) &
                    enc_ctrl4_io(15);

serial_if_inst : entity work.serial_ctrl
port map (
    clk_i           => clk_i,
    reset_i         => reset,

    enc_ctrl1_o     => enc_ctrl1(11 downto 0),
    enc_ctrl2_o     => enc_ctrl2(11 downto 0),
    enc_ctrl3_o     => enc_ctrl3(11 downto 0),
    enc_ctrl4_o     => enc_ctrl4(11 downto 0),

    ttlin_term_o    => ttlin_term,
    ttl_leds_o      => ttl_leds,
    status_leds_o   => status_leds,
    status_regs_i   => status_regs,

    spi_sclk_i      => spi_sclk_i,
    spi_dat_i       => spi_dat_i,
    spi_sclk_o      => spi_sclk_o,
    spi_dat_o       => spi_dat_o
);

--
-- Assemble STATUS REGISTERS
--
FPGA_VERSION <= X"12345678";
ENC_CONN <= ZEROS(32-enc_connected'length) & enc_connected;

status_regs(0) <= FPGA_VERSION;
status_regs(1) <= ENC_CONN;
status_regs(REGS_NUM-1 downto 2) <= (others => (others => '0'));

end rtl;
