--------------------------------------------------------------------------------
--  NAMC Project - 2022
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Arthur Mariano (arthur.mariano@synchrotron-soleil.fr)
--                Thierry GARREL (ELSYS-Design) receiver part
--
--------------------------------------------------------------------------------
--
--  Description : Serial Interface Synchronous Transmitter & Receiver core.
--                Generates SPI transactions (Data + Clock) with clock rate
--                at SPI_CLK = 125MHz / ((DIVIDER+1)*2 =~ 620kHz with DIVIDER=100
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.support.all;

entity spi_ltc2174_tx_rx is
generic (
    CLK_PERIOD      : natural;
    DEAD_PERIOD     : natural
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Write transaction interface
    wr_req_i        : in  std_logic;
    wr_adr_i        : in  std_logic_vector(6 downto 0);
    wr_dat_i        : in  std_logic_vector(7 downto 0);
    -- Read transaction interface
    rd_req_i        : in  std_logic;
    rd_adr_i        : in  std_logic_vector(6 downto 0);
    rd_dat_o        : out std_logic_vector(7 downto 0);
    rd_val_o        : out std_logic;
    -- Status
    busy_o          : out std_logic;
    -- Serial Physical interface
    spi_sclk_o      : out std_logic;
    spi_dat_o       : out std_logic;
    spi_dat_i       : in  std_logic;
    -- debug outputs
    shift_counter_o : out std_logic_vector(3 downto 0);
    shift_enable_o  : out std_logic
);
end spi_ltc2174_tx_rx;


architecture rtl of spi_ltc2174_tx_rx is

-- Ticks in terms of internal serial clock period.
constant BITS             : natural := 16-1;
constant DW               : natural := 8;       -- read data width

-- Internal signals
signal wr_req_or_rd_req   : std_logic;

signal serial_clk         : std_logic;
signal serial_clk_prev    : std_logic;
signal serial_clk_rise    : std_logic;
signal serial_clk_fall    : std_logic;
signal shift_reg          : std_logic_vector(BITS downto 0);
signal active_flag        : std_logic;
signal active_prev        : std_logic;
signal active_fall        : std_logic;

signal shift_enable       : std_logic;
signal shift_counter      : unsigned(3 downto 0); -- 0 to 15
signal smpl_hold          : std_logic_vector(DW-1 downto 0);

signal rd_in_progress     : std_logic;
signal rd_data            : std_logic_vector(DW-1 downto 0);
signal rd_valid           : std_logic;


-- Begin of code
begin

wr_req_or_rd_req <= wr_req_i or rd_req_i;

clock_train_inst : entity work.spi_clock_gen
generic map (
    DEAD_PERIOD       => DEAD_PERIOD
)
port map (
    clk_i             => clk_i,
    reset_i           => reset_i,
    N                 => std_logic_vector(to_unsigned(BITS, 8)), -- std_logic_vector(to_unsigned(input_1, output_1a'length));
    CLK_PERIOD        => std_logic_vector(to_unsigned(CLK_PERIOD, 32)),
    start_i           => wr_req_or_rd_req,
    serial_clk_o      => serial_clk,
    serial_clk_rise_o => serial_clk_rise,
    serial_clk_fall_o => serial_clk_fall,
    active_o          => active_flag,     --  Active flag is asserted with the first-rising edge of the serial clock.
    busy_o            => busy_o
);


active_fall     <= not active_flag and active_prev;


p_spi : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            shift_reg       <= (others => '0');
            serial_clk_prev <= '0';
            active_prev     <= '0';
            shift_enable    <= '0';
            shift_counter   <= (others => '0');
            smpl_hold       <= (others=>'0');
            rd_in_progress  <= '0';
            rd_data         <= (others => '0');
            rd_valid        <= '0';

        else
            serial_clk_prev <= serial_clk;
            active_prev     <= active_flag;

             -- Latch write data, and shift out on the rising edge of serial clock

            if (wr_req_i = '1') then
                shift_reg <= '0' & wr_adr_i & wr_dat_i; -- wr='0' + addr[6:0] + dat[7:0]
                shift_counter <= (others => '0');
            elsif (rd_req_i = '1') then
                shift_reg <= '1' & rd_adr_i & x"00";    -- wr='1' + addr[6:0] + XX[7:0]
                shift_counter  <= (others => '0');
                rd_in_progress <= '1';
            elsif (active_flag = '1' and serial_clk_rise = '1') then
                shift_reg <= shift_reg(shift_reg'length - 2 downto 0) & '0';
                shift_counter <= shift_counter + 1;
            end if;

            -- Enable shifting spi data input
            if (shift_enable = '0' and rd_in_progress = '1' and shift_counter = DW) then
                shift_enable <= '1';
            elsif (active_fall = '1') then
                shift_enable <= '0';
                rd_in_progress <= '0';
            end if;

            -- Latch data output and clear shift register.
            rd_valid <= active_fall;

            if (active_fall = '1') then
                rd_data <= smpl_hold;
                smpl_hold <= (others => '0');

            -- Shift data when enabled.
            elsif (shift_enable = '1' ) then
                -- data is output by ltc2174 125 nx max (TDO) after the falling edge of spi_clk
                -- and latched on falling edge of serial clock
                if (serial_clk_fall = '1') then
                    smpl_hold <= smpl_hold(DW-2 downto 0) & spi_dat_i;
                end if;
            end if;
        end if;

    end if;
end process p_spi;

-- Connect outputs
spi_sclk_o  <= not serial_clk; -- output data on the falling edge of serial clock
spi_dat_o   <= shift_reg(shift_reg'length - 1);

rd_dat_o  <= rd_data;
rd_val_o  <= rd_valid;

-- Connect debug outputs
shift_counter_o <= std_logic_vector(shift_counter);
shift_enable_o  <= shift_enable;

end rtl;
-- End of code
