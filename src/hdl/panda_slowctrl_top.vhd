--------------------------------------------------------------------------------
--  File:       panda_slowctrl_top.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_slowctrl_top is
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
    -- Block Input and Outputs
    inenc_tlp_i         : in  slow_packet;
    outenc_tlp_i        : in  slow_packet;
    busy_o              : out std_logic;
    -- Serial Physical interface
    spi_sclk_o          : out std_logic;
    spi_dat_o           : out std_logic;
    spi_sclk_i          : in  std_logic;
    spi_dat_i           : in  std_logic
);
end panda_slowctrl_top;

architecture rtl of panda_slowctrl_top is

begin
--
--
--
slowctrl_block_inst : entity work.panda_slowctrl_block
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,

    mem_cs_i        => mem_cs_i,
    mem_wstb_i      => mem_wstb_i,
    mem_addr_i      => mem_addr_i,
    mem_dat_i       => mem_dat_i,
    mem_dat_o       => mem_dat_o,

    inenc_tlp_i     => inenc_tlp_i,
    outenc_tlp_i    => outenc_tlp_i,
    busy_o          => busy_o,

    spi_sclk_o      => spi_sclk_o,
    spi_dat_o       => spi_dat_o,
    spi_sclk_i      => spi_sclk_i,
    spi_dat_i       => spi_dat_i
);

end rtl;

