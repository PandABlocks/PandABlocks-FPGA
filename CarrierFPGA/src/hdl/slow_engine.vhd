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

entity slow_engine is
generic (
    AW              : natural := 10;
    DW              : natural := 32;
    CLKDIV          : natural := 125
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Transaction interface
    wr_rst_i        : in  std_logic;
    wr_req_i        : in  std_logic;
    wr_dat_i        : in  std_logic_vector(DW-1 downto 0);
    wr_adr_i        : in  std_logic_vector(AW-1 downto 0);
    rd_adr_o        : out std_logic_vector(AW-1 downto 0);
    rd_dat_o        : out std_logic_vector(DW-1 downto 0);
    rd_val_o        : out std_logic;
    busy_o          : out std_logic;
    -- Serial Physical interface
    spi_sclk_o      : out std_logic;
    spi_dat_o       : out std_logic;
    spi_sclk_i      : in  std_logic;
    spi_dat_i       : in  std_logic
);
end slow_engine;

architecture rtl of slow_engine is

begin

slow_engine_tx_inst : entity work.slow_engine_tx
generic map (
    AW              => AW,
    DW              => DW,
    CLKDIV          => CLKDIV
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

slow_engine_rx_inst : entity work.slow_engine_rx
generic map (
    AW              => AW,
    DW              => DW,
    CLKDIV          => CLKDIV
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    -- Transaction interface
    rd_adr_o        => rd_adr_o,
    rd_dat_o        => rd_dat_o,
    rd_val_o        => rd_val_o,
    -- Serial Physical interface
    spi_sclk_i      => spi_sclk_i,
    spi_dat_i       => spi_dat_i
);

end rtl;
