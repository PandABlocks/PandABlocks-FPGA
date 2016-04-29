--------------------------------------------------------------------------------
--  File:       slowctrl_top.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity slowctrl_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Serial Physical interface
    spi_sclk_o          : out std_logic;
    spi_dat_o           : out std_logic;
    spi_sclk_i          : in  std_logic;
    spi_dat_i           : in  std_logic;
    -- Block Input and Outputs
    registers_tlp_i     : in  slow_packet;
    leds_tlp_i          : in  slow_packet;
    busy_o              : out std_logic;
    SLOW_FPGA_VERSION   : out std_logic_vector(31 downto 0);
    DCARD_MODE          : out std32_array(ENC_NUM-1 downto 0)
);
end slowctrl_top;

architecture rtl of slowctrl_top is

signal TEMP_MON         : std32_array(4 downto 0);
signal VOLT_MON         : std32_array(7 downto 0);

begin

--
-- Slow controller interface
--
slow_interface : entity work.slow_interface
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    spi_sclk_o          => spi_sclk_o,
    spi_dat_o           => spi_dat_o,
    spi_sclk_i          => spi_sclk_i,
    spi_dat_i           => spi_dat_i,

    registers_tlp_i     => registers_tlp_i,
    leds_tlp_i          => leds_tlp_i,
    busy_o              => busy_o,
    SLOW_FPGA_VERSION   => SLOW_FPGA_VERSION,
    DCARD_MODE          => DCARD_MODE,
    TEMP_MON            => TEMP_MON,
    VOLT_MON            => VOLT_MON
);

--
-- Slow controller status readback
--
slow_ctrl_inst : entity work.slow_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => (others => '0'),
    posbus_i            => (others => (others => '0')),
    -- Block Parameters
    TEMP1_VAL           => TEMP_MON(0),
    TEMP2_VAL           => TEMP_MON(1),
    TEMP3_VAL           => TEMP_MON(2),
    TEMP4_VAL           => TEMP_MON(3),
    TEMP5_VAL           => TEMP_MON(4),
    FMC_12V             => VOLT_MON(0),
    ENC_24V             => VOLT_MON(1),
    FMC_15VP            => VOLT_MON(2),
    FMC_15VN            => VOLT_MON(3),
    SFP_3V3             => VOLT_MON(4),
    IO_5V0              => VOLT_MON(5),
    PICO_5V0            => VOLT_MON(6),
    ALIM_12V0           => VOLT_MON(7),
    -- Memory Bus Interface
    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_dat_o
);

end rtl;

