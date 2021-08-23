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

entity serial_engine is
generic (
    SYS_PERIOD      : natural := 8;     -- Sys clock [ns]
    CLK_PERIOD      : natural := 2000;  -- 2 us
    SYNC_PERIOD     : natural := 5000;  -- 5 us
    DEAD_PERIOD     : natural := 10000  -- 10 us
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Transaction interface
    wr_rst_i        : in  std_logic;
    wr_req_i        : in  std_logic;
    wr_adr_i        : in  std_logic_vector(9 downto 0);
    wr_dat_i        : in  std_logic_vector(31 downto 0);
    rd_adr_o        : out std_logic_vector(9 downto 0);
    rd_dat_o        : out std_logic_vector(31 downto 0);
    rd_val_o        : out std_logic;
    busy_o          : out std_logic;
    -- Serial Physical interface
    spi_sclk_o      : out std_logic;
    spi_dat_o       : out std_logic;
    spi_sclk_i      : in  std_logic;
    spi_dat_i       : in  std_logic
);
end serial_engine;

architecture rtl of serial_engine is

begin

serial_engine_tx_inst : entity work.serial_engine_tx
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

serial_engine_rx_inst : entity work.serial_engine_rx
generic map (
    SYNCPERIOD      => (SYNC_PERIOD/SYS_PERIOD)
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
