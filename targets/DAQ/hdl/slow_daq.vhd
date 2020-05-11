--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : G.THIBAUX (gauthier.thibaux@synchrotron-soleil.fr) 
--------------------------------------------------------------------------------
--
--  Description : Serial Interface core is used to handle communication between
--                Zynq slowcont_top and Slow Control i2c interface, shift_register, ... pins located on zync for DAQ plateform
--                slow_daq is based on slow_top in slowFPGA PandA plateform.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.slow_defines_daq.all;
use work.addr_defines.all;

library unisim;
use unisim.vcomponents.all;

entity slow_daq is
generic (
    STATUS_PERIOD       : natural := 10_000_000;-- 10ms
    SYS_PERIOD          : natural := 8         -- 8ns
);
port (
    -- 125MHz system clock
    clk_i            : in    std_logic;
    reset_i    : in    std_logic;
    -- Zynq Tx/Rx Serial Interface
    spi_sclk_i          : in    std_logic;
    spi_dat_i           : in    std_logic;
    spi_sclk_o          : out   std_logic;
    spi_dat_o           : out   std_logic;
    -- Misc control
    SEL_GTXCLK1         : out  std_logic; -- 0: Si570, 1: FMC
    -- Front Panel Shift Register Interface
    shift_reg_sdata_o   : out   std_logic;
    shift_reg_sclk_o    : out   std_logic;
    shift_reg_latch_o   : out   std_logic;
    shift_reg_oe_n_o    : out   std_logic;
    -- I2C SFP Interface
    i2c_sfp_sda         : inout std_logic;
    i2c_sfp_scl         : inout std_logic;
    -- I2C Si570 XO Interface
    i2c_clock_sda       : inout std_logic;
    i2c_clock_scl       : inout std_logic;
    -- I2C Temperature Sensor Interface
    i2c_temp_sda        : inout std_logic;
    i2c_temp_scl        : inout std_logic;
    -- I2C Voltage Sensor Interface
    i2c_vmon_sda        : inout std_logic;
    i2c_vmon_scl        : inout std_logic
);
end slow_daq;

architecture rtl of slow_daq is

signal TEMP_MON             : std32_array(2 downto 0);
constant CONST_TEMP_MON_0 : std_logic_vector(31 downto 0) := x"00000001";
constant CONST_TEMP_MON_1 : std_logic_vector(31 downto 0) := x"00000002";
constant CONST_TEMP_MON_2 : std_logic_vector(31 downto 0) := x"00000003";
constant CONST_TEMP_MON : std32_array(2 downto 0) := (CONST_TEMP_MON_2,CONST_TEMP_MON_1,CONST_TEMP_MON_0);
signal VOLT_MON             : std32_array(7 downto 0);
constant CONST_VOLT_MON_0 : std_logic_vector(31 downto 0) := x"00000001";
constant CONST_VOLT_MON_1 : std_logic_vector(31 downto 0) := x"00000002";
constant CONST_VOLT_MON_2 : std_logic_vector(31 downto 0) := x"00000003";
constant CONST_VOLT_MON_3 : std_logic_vector(31 downto 0) := x"00000004";
constant CONST_VOLT_MON_4 : std_logic_vector(31 downto 0) := x"00000005";
constant CONST_VOLT_MON_5 : std_logic_vector(31 downto 0) := x"00000006";
constant CONST_VOLT_MON_6 : std_logic_vector(31 downto 0) := x"00000007";
constant CONST_VOLT_MON_7 : std_logic_vector(31 downto 0) := x"00000008";
constant CONST_VOLT_MON             : std32_array(7 downto 0):= (CONST_VOLT_MON_7,CONST_VOLT_MON_6,CONST_VOLT_MON_5,CONST_VOLT_MON_4,CONST_VOLT_MON_3,CONST_VOLT_MON_2,CONST_VOLT_MON_1,CONST_VOLT_MON_0);
signal reset                : std_logic;
signal ttlin_term           : std_logic_vector(1 downto 0);
signal ttl_leds             : std_logic_vector(3 downto 0);
signal status_leds          : std_logic_vector(3 downto 0);

signal sysclk               : std_logic;
signal spi_sclk             : std_logic;
signal spi_dat              : std_logic;

begin

spi_sclk_o <= spi_sclk;
spi_dat_o <= spi_dat;

--SEL_GTXCLK1 <= '1'; -- FMC as clock source
SEL_GTXCLK1 <= '0'; -- Si570 as clock source

reset <= reset_i;
sysclk <= clk_i;

--
-- Data Send/Receive Engine to Zynq
--
zynq_interface_daq_inst : entity work.zynq_interface_daq
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

    TEMP_MON            => TEMP_MON,
    VOLT_MON            => VOLT_MON 
);

--
-- Front Panel Shift Register Interface
--
fpanel_if_daq_inst : entity work.fpanel_if_daq
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
temp_sensors_inst : entity work.temp_sensors_daq
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
voltage_sensors_inst : entity work.voltage_sensors_daq
port map (
    clk_i               => sysclk,
    reset_i             => reset,
    sda                 => i2c_vmon_sda,
    scl                 => i2c_vmon_scl,
    VOLT_MON            => VOLT_MON
);



end rtl;
