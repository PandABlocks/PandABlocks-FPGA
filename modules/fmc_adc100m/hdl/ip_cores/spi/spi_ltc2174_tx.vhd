--------------------------------------------------------------------------------
--  NAMC Project - 2021
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Arthur Mariano (arthur.mariano@synchrotron-soleil.fr)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface Synchronous Transmitter core.
--                Generates SPI transactions (Data + Clock) with clock rate
--                at SPI_CLK = 125MHz / ((DIVIDER+1)*2 =~ 620kHz with DIVIDER=100
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity spi_ltc2174_tx is
generic (
    CLK_PERIOD      : natural;
    DEAD_PERIOD     : natural
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Transaction interface
    wr_rst_i        : in  std_logic;
    wr_req_i        : in  std_logic;
    wr_dat_i        : in  std_logic_vector(7 downto 0);
    wr_adr_i        : in  std_logic_vector(6 downto 0);
    busy_o          : out std_logic;
    -- Serial Physical interface
    spi_sclk_o      : out std_logic;
    spi_dat_o       : out std_logic
);
end spi_ltc2174_tx;

architecture rtl of spi_ltc2174_tx is

-- Ticks in terms of internal serial clock period.
constant BITS               : natural := 16-1;

signal serial_clk           : std_logic;
signal serial_clk_prev      : std_logic;
signal serial_clk_rise      : std_logic;
signal shift_reg            : std_logic_vector(BITS downto 0);
signal active               : std_logic;

begin

clock_train_inst : entity work.spi_clock_gen
generic map (
    DEAD_PERIOD     => DEAD_PERIOD
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    N               => std_logic_vector(to_unsigned(BITS, 8)), -- std_logic_vector(to_unsigned(input_1, output_1a'length));
    CLK_PERIOD      => std_logic_vector(to_unsigned(CLK_PERIOD, 32)),
    start_i         => wr_req_i,
    clock_pulse_o   => serial_clk,
    active_o        => active,
    busy_o          => busy_o
);

--
-- Prescaled clock to be used internally.
--
serial_clk_rise <= serial_clk and not serial_clk_prev;

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            shift_reg <= (others => '0');
            serial_clk_prev <= '0';
        else
            serial_clk_prev <= serial_clk;

            -- Latch write data, and shift out on the rising edge of serial clock
            if (wr_req_i = '1') then
                shift_reg <= '0' & wr_adr_i & wr_dat_i; -- wr='0' + addr[6:0] + dat[7:0]
            elsif (active = '1' and serial_clk_rise = '1') then
                shift_reg <= shift_reg(shift_reg'length - 2 downto 0) & '0';
            end if;
        end if;
    end if;
end process;

-- Connect outputs
spi_sclk_o  <= not serial_clk; -- output data on the falling edge of serial clock
spi_dat_o   <= shift_reg(shift_reg'length - 1);

end rtl;
