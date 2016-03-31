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

entity serial_comms is
port (
    -- 50MHz system clock
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Encoder Daughter Card Control
    enc_ctrl1_o     : out std_logic_vector(11 downto 0);
    enc_ctrl2_o     : out std_logic_vector(11 downto 0);
    enc_ctrl3_o     : out std_logic_vector(11 downto 0);
    enc_ctrl4_o     : out std_logic_vector(11 downto 0);
    -- Front-Panel Control
    ttlin_term_o    : out std_logic_vector(5 downto 0);
    ttl_leds_o      : out std_logic_vector(15 downto 0);
    status_leds_o   : out std_logic_vector(3 downto 0);
    -- Status Registers
    status_regs_i   : in  std32_array(REGS_NUM-1 downto 0);
    -- Serial Physical interface
    spi_sclk_i      : in  std_logic;
    spi_dat_i       : in  std_logic;
    spi_sclk_o      : out std_logic;
    spi_dat_o       : out std_logic
);
end serial_comms;

architecture rtl of serial_comms is

constant AW         : natural := 10;
constant DW         : natural := 32;

signal wr_req       : std_logic;
signal wr_dat       : std_logic_vector(DW-1 downto 0);
signal wr_adr       : std_logic_vector(AW-1 downto 0);
signal rd_adr       : std_logic_vector(AW-1 downto 0);
signal rd_dat       : std_logic_vector(DW-1 downto 0);
signal rd_val       : std_logic;
signal busy         : std_logic;

signal wr_start     : std_logic;
signal txadr_reg    : natural range 0 to (2**AW - 1);
signal status_index : natural range 0 to REGS_NUM-1;

begin

--
-- Serial Interface TX/RX Core IP
--
slow_engine_inst : entity work.slow_engine
generic map (
    AW              => AW,
    DW              => DW,
    CLKDIV          => 50
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,

    wr_rst_i        => '0',
    wr_req_i        => wr_req,
    wr_dat_i        => wr_dat,
    wr_adr_i        => wr_adr,
    rd_adr_o        => rd_adr,
    rd_dat_o        => rd_dat,
    rd_val_o        => rd_val,
    busy_o          => busy,

    spi_sclk_i      => spi_sclk_i,
    spi_dat_i       => spi_dat_i,
    spi_sclk_o      => spi_sclk_o,
    spi_dat_o       => spi_dat_o
);

--
-- Transmit Interface :
-- Continuously cycles and transmits the status registers, and transfer them
-- to the master at 100us rate.
write_trigger : entity work.prescaler
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    PERIOD          => TO_SVECTOR(5000, 32),
    pulse_o         => wr_start
);

WRITE_REGISTERS : process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            status_index <= 0;
            wr_req <= '0';
            wr_adr <= (others => '0');
            wr_dat <= (others => '0');
        else
            -- Cycle through registers contiuously.
--            if (busy = '0' and wr_req = '0') then
            if (busy = '0' and wr_start = '1') then
                wr_req <= '1';
                wr_adr <= TO_SVECTOR(status_index, AW);
                wr_dat <= status_regs_i(status_index);
                -- Keep track of registers
                if (status_index = REGS_NUM-1) then
                    status_index <= 0;
                else
                    status_index <= status_index + 1;
                end if;
            else
                wr_req <= '0';
                wr_adr <= wr_adr;
                wr_dat <= wr_dat;
            end if;
        end if;
    end if;
end process;

--
-- Receive Configuration Registers
--
enc_ctrl_inst : entity work.enc_ctrl
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    rx_addr_i       => rd_adr,
    rx_valid_i      => rd_val,
    rx_data_i       => rd_dat,
    enc_ctrl1_o     => enc_ctrl1_o,
    enc_ctrl2_o     => enc_ctrl2_o,
    enc_ctrl3_o     => enc_ctrl3_o,
    enc_ctrl4_o     => enc_ctrl4_o
);

ttl_ctrl_inst : entity work.ttl_ctrl
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    rx_addr_i       => rd_adr,
    rx_valid_i      => rd_val,
    rx_data_i       => rd_dat,
    ttlin_term_o    => ttlin_term_o
);

leds_ctrl_inst : entity work.leds_ctrl
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    rx_addr_i       => rd_adr,
    rx_valid_i      => rd_val,
    rx_data_i       => rd_dat,
    ttl_leds_o      => ttl_leds_o,
    status_leds_o   => status_leds_o
);

end rtl;
