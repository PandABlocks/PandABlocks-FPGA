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

begin

slowctrl_block_inst : entity work.slowctrl_block
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_dat_o,

    spi_sclk_o          => spi_sclk_o,
    spi_dat_o           => spi_dat_o,
    spi_sclk_i          => spi_sclk_i,
    spi_dat_i           => spi_dat_i,

    registers_tlp_i     => registers_tlp_i,
    leds_tlp_i          => leds_tlp_i,
    busy_o              => busy_o,
    SLOW_FPGA_VERSION   => SLOW_FPGA_VERSION,
    DCARD_MODE          => DCARD_MODE
);

end rtl;

