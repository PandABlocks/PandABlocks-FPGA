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

entity serial_ctrl is
generic (
    -- Serial Clock Divider : 50/(2*50) = 0.5MHz
    CLKDIV          : natural := 50;
    AW              : natural := 10;
    DW              : natural := 32
);
port (
    -- 50MHz system clock
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Encoder Daughter Card Control interface
    enc_ctrl1_o     : out std_logic_vector(11 downto 0);
    enc_ctrl2_o     : out std_logic_vector(11 downto 0);
    enc_ctrl3_o     : out std_logic_vector(11 downto 0);
    enc_ctrl4_o     : out std_logic_vector(11 downto 0);
    -- Front-Panel Control Values
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
end serial_ctrl;

architecture rtl of serial_ctrl is

signal wr_req       : std_logic;
signal wr_dat       : std_logic_vector(DW-1 downto 0);
signal wr_adr       : std_logic_vector(AW-1 downto 0);
signal rd_adr       : std_logic_vector(AW-1 downto 0);
signal rd_dat       : std_logic_vector(DW-1 downto 0);
signal rd_val       : std_logic;
signal busy         : std_logic;

signal txadr_reg    : natural range 0 to (2**AW - 1);
signal rxadr_reg    : natural range 0 to (2**AW - 1);
signal status_index  : natural range 0 to REGS_NUM-1;
signal wr_rst  : std_logic;

begin

rxadr_reg <= to_integer(unsigned(rd_adr));

--
-- Serial Interface TX/RX Core IP
--
slowctrl_inst : entity work.slowctrl
generic map (
    AW              => AW,
    DW              => DW,
    CLKDIV          => CLKDIV
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,

    wr_rst_i        => wr_rst,
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
-- Write Register Interface : Continuously cycle through the status registers,
-- and transfer them to the master.
--
WRITE_REGISTERS : process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            status_index <= 0;
            wr_req <= '0';
            wr_adr <= (others => '0');
            wr_dat <= (others => '0');
            wr_rst <= '0';
        else
            -- Cycle through registers contiuously.
            if (busy = '0' and wr_req = '0') then
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


---- Slow Controller Control Registers
--wr_rst <= '0';
--
--if (rd_val = '1' and rxadr_reg = WRITE_RESET) then
--    wr_rst <= '1';
--end if;

end rtl;
