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

library work;
use work.slow_defines.all;

library unisim;
use unisim.vcomponents.all;

entity slow_top is
generic (
    STATUS_PERIOD       : natural := 10_000_000;-- 10ms
    SYS_PERIOD          : natural := 20         -- 20ns
);
port (
    -- 50MHz system clock
    clk50_i             : in    std_logic;
    clk125_i            : in    std_logic;
    -- Zynq Tx/Rx Serial Interface
    spi_sclk_i          : in    std_logic;
    spi_dat_i           : in    std_logic;
    spi_sclk_o          : out   std_logic;
    spi_dat_o           : out   std_logic;
    -- Encoder Daughter Card Control Interface
    dcard_ctrl1_io      : inout std_logic_vector(15 downto 0);
    dcard_ctrl2_io      : inout std_logic_vector(15 downto 0);
    dcard_ctrl3_io      : inout std_logic_vector(15 downto 0);
    dcard_ctrl4_io      : inout std_logic_vector(15 downto 0);
    -- Misc control
    SEL_GTXCLK1         : out  std_logic; -- 0: Si570, 1: FMC
    ENC_LED             : out  std_logic_vector(3 downto 0);
    -- Front Panel Shift Register Interface
    shift_reg_sdata_o   : out   std_logic;
    shift_reg_sclk_o    : out   std_logic;
    shift_reg_latch_o   : out   std_logic;
    shift_reg_oe_n_o    : out   std_logic;
    -- I2C SFP Interface
    --i2c_sfp_sda         : inout std_logic;
    --i2c_sfp_scl         : inout std_logic;
    -- I2C Si570 XO Interface
    --i2c_clock_sda       : inout std_logic;
    --i2c_clock_scl       : inout std_logic;
    -- I2C Temperature Sensor Interface
    i2c_temp_sda        : inout std_logic;
    i2c_temp_scl        : inout std_logic;
    -- I2C Voltage Sensor Interface
    i2c_vmon_sda        : inout std_logic;
    i2c_vmon_scl        : inout std_logic
);
end slow_top;

architecture rtl of slow_top is

signal DATA                 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal TRIG0                : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal CONTROL0             : STD_LOGIC_VECTOR(35 DOWNTO 0);

signal OUTENC_CONN          : std_logic_vector(3 downto 0);
signal INENC_PROTOCOL       : std3_array(3 downto 0);
signal OUTENC_PROTOCOL      : std3_array(3 downto 0);
signal DCARD_MODE           : std4_array(3 downto 0);
signal TEMP_MON             : std32_array(4 downto 0);
signal VOLT_MON             : std32_array(7 downto 0);
signal reset_n              : std_logic;
signal reset                : std_logic;
signal ttlin_term           : std_logic_vector(5 downto 0);
signal ttl_leds             : std_logic_vector(15 downto 0);
signal status_leds          : std_logic_vector(3 downto 0);
signal enc_leds             : std_logic_vector(3 downto 0);
signal clk50_pad            : std_logic;
signal clk50_pll            : std_logic;
signal sysclk               : std_logic;
signal spi_sclk             : std_logic;
signal spi_dat              : std_logic;

begin

spi_sclk_o <= spi_sclk;
spi_dat_o <= spi_dat;

--SEL_GTXCLK1 <= '1'; -- FMC as clock source
SEL_GTXCLK1 <= '0'; -- Si570 as clock source

-- Encoder LEDs (D5-D8)
ENC_LED <= enc_leds;

--------------------------------------------------------------------------
-- Clock PLL and Startup Reset
--------------------------------------------------------------------------
clk50_buf : BUFG
port map (
    O           => clk50_pad,
    I           => clk50_i
);

clkgen_inst : entity work.clkgen
port map (
  CLK_IN1       => clk125_i,
  CLK_OUT1      => clk50_pll,
  RESET         => '0',
  LOCKED        => reset_n
 );

reset <= not reset_n;

sysclk <= clk50_pad;    -- clk50_pll;

--
-- Data Send/Receive Engine to Zynq
--
zynq_interface_inst : entity work.zynq_interface
generic map (
    STATUS_PERIOD   => STATUS_PERIOD,
    SYS_PERIOD      => SYS_PERIOD
)
port map (
    clk_i               => sysclk,
    reset_i             => reset,

    spi_sclk_i          => spi_sclk_i,
    spi_dat_i           => spi_dat_i,
    spi_sclk_o          => spi_sclk,
    spi_dat_o           => spi_dat,

    ttlin_term_o        => ttlin_term,
    ttl_leds_o          => ttl_leds,
    status_leds_o       => status_leds,
    enc_leds_o          => enc_leds,
    outenc_conn_o       => OUTENC_CONN,

    INENC_PROTOCOL_o      => INENC_PROTOCOL,
    OUTENC_PROTOCOL_o     => OUTENC_PROTOCOL,
    DCARD_MODE          => DCARD_MODE,
    TEMP_MON            => TEMP_MON,
    VOLT_MON            => VOLT_MON
);

--
-- Daughter Card Control Interface
--
dcard_ctrl_inst  : entity work.dcard_ctrl
port map (
    clk_i               => sysclk,
    reset_i             => reset,
    -- Encoder Daughter Card Control Interface
    dcard_ctrl1_io      => dcard_ctrl1_io,
    dcard_ctrl2_io      => dcard_ctrl2_io,
    dcard_ctrl3_io      => dcard_ctrl3_io,
    dcard_ctrl4_io      => dcard_ctrl4_io,
    -- Front Panel Shift Register Interface
    OUTENC_CONN         => OUTENC_CONN,
    INENC_PROTOCOL      => INENC_PROTOCOL,
    OUTENC_PROTOCOL     => OUTENC_PROTOCOL,
    DCARD_MODE          => DCARD_MODE
);

--
-- Front Panel Shift Register Interface
--
fpanel_if_inst : entity work.fpanel_if
port map (
    clk_i               => sysclk,
    reset_i             => reset,
    ttlin_term_i        => ttlin_term,
    ttl_leds_i          => ttl_leds,
    status_leds_i       => status_leds,
    shift_reg_sdata_o   => shift_reg_sdata_o,
    shift_reg_sclk_o    => shift_reg_sclk_o,
    shift_reg_latch_o   => shift_reg_latch_o,
    shift_reg_oe_n_o    => shift_reg_oe_n_o
);

--------------------------------------------------------------------------
-- Temp sensor interface
--------------------------------------------------------------------------
temp_sensors_inst : entity work.temp_sensors
port map (
    clk_i               => sysclk,
    reset_i             => reset,
    sda                 => i2c_temp_sda,
    scl                 => i2c_temp_scl,
    TEMP_MON            => TEMP_MON
);

--------------------------------------------------------------------------
-- Voltage measurement interface
--------------------------------------------------------------------------
voltage_sensors_inst : entity work.voltage_sensors
port map (
    clk_i               => sysclk,
    reset_i             => reset,
    sda                 => i2c_vmon_sda,
    scl                 => i2c_vmon_scl,
    VOLT_MON            => VOLT_MON
);

end rtl;
