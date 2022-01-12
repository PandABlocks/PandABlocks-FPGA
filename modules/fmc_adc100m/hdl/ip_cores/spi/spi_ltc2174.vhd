--------------------------------------------------------------------------------
--  NAMC Project - 2021
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Arthur Mariano (arthur.mariano@synchrotron-soleil.fr)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface core is used to handle communication between
--                Zynq and Slow Control FPGA.
--
--                TX Engine sends data at 2usec clock rate on a write request,
--                and asserts busy flag.
--                RX Engine has an internal 1usec clock to Sync and monitor
--                link status.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity spi_ltc2174 is
generic (
    SYS_PERIOD      : natural := 8;    -- Sys clock [ns]
    CLK_PERIOD      : natural := 1612; -- 620kHz = 1.6us     --2000;  -- 2 us
    DEAD_PERIOD     : natural := 30000 --          30us -- 10 us
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Transaction interface
    wr_rst_i        : in  std_logic;
    wr_req_i        : in  std_logic;
    wr_adr_i        : in  std_logic_vector(6 downto 0);
    wr_dat_i        : in  std_logic_vector(7 downto 0);
    busy_o          : out std_logic;
    -- Serial Physical interface
    spi_sclk_o      : out std_logic;
    spi_dat_o       : out std_logic;
    spi_sclk_i      : in  std_logic;
    spi_dat_i       : in  std_logic
    );
end spi_ltc2174;

architecture rtl of spi_ltc2174 is

begin

spi_ltc2174_tx_inst : entity work.spi_ltc2174_tx
generic map (
    CLK_PERIOD      => (CLK_PERIOD/SYS_PERIOD),
    DEAD_PERIOD     => (DEAD_PERIOD/SYS_PERIOD)
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    -- Transaction interface
    wr_rst_i        => wr_rst_i,
    wr_req_i        => wr_req_i,
    wr_dat_i        => wr_dat_i,
    wr_adr_i        => wr_adr_i,
    busy_o          => busy_o,
    -- Serial Physical interface
    spi_sclk_o      => spi_sclk_o,
    spi_dat_o       => spi_dat_o
);


end rtl;
