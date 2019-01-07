--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface Synchronous Trasmitter core.
--                Generates SPI transactions (Data + Clock) with clock rate
--                at SPI_CLK = 125MHz / (2 * CLKDIV)
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity serial_engine_tx is
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
    wr_dat_i        : in  std_logic_vector(31 downto 0);
    wr_adr_i        : in  std_logic_vector(9 downto 0);
    busy_o          : out std_logic;
    -- Serial Physical interface
    spi_sclk_o      : out std_logic;
    spi_dat_o       : out std_logic
);
end serial_engine_tx;

architecture rtl of serial_engine_tx is

-- Ticks in terms of internal serial clock period.
constant BITS               : natural := 42;

signal serial_clk           : std_logic;
signal serial_clk_prev      : std_logic;
signal serial_clk_rise      : std_logic;
signal shift_reg            : std_logic_vector(BITS downto 0);
signal active               : std_logic;

begin

clock_train_inst : entity work.ssi_clock_gen
generic map (
    DEAD_PERIOD     => DEAD_PERIOD
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    N               => std_logic_vector(to_unsigned(BITS, 8)),
    CLK_PERIOD      => std_logic_vector(to_unsigned(CLK_PERIOD, 32)),
    start_i         => wr_req_i,
    clock_pulse_o   => serial_clk,
    active_o        => active,
    busy_o          => busy_o
);

--
-- Presclaed clock to be used internally.
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
                shift_reg <= '0' & wr_adr_i & wr_dat_i;
            elsif (active = '1' and serial_clk_rise = '1') then
                shift_reg <= shift_reg(shift_reg'length - 2 downto 0) & '0';
            end if;
        end if;
    end if;
end process;

-- Connect outputs
spi_sclk_o  <= serial_clk;
spi_dat_o <= shift_reg(shift_reg'length - 1);

end rtl;
