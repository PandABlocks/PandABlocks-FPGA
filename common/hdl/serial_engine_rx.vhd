--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface Synchronous Recevier core.
--                Manages link status, and receives incoming SPI transaction,
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity serial_engine_rx is
generic (
    SYNCPERIOD      : natural
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Transaction interface
    rd_adr_o        : out std_logic_vector(9 downto 0);
    rd_dat_o        : out std_logic_vector(31 downto 0);
    rd_val_o        : out std_logic;
    -- Serial Physical interface
    spi_sclk_i      : in  std_logic;
    spi_dat_i       : in  std_logic
);
end serial_engine_rx;

architecture rtl of serial_engine_rx is

-- Ticks in terms of internal serial clock period.
constant BITS               : natural := 42;

signal serial_data          : std_logic;
signal serial_clock         : std_logic;
signal serial_clock_prev    : std_logic;
signal shift_counter        : unsigned(5 downto 0);
signal link_up              : std_logic;
signal shift_enabled        : std_logic;
signal shift_clock          : std_logic;
signal shift_data           : std_logic;
signal shift_in             : std_logic_vector(BITS-1 downto 0);
signal shift_in_valid       : std_logic;

begin

--
-- Register inputs and detect rise/fall edges.
--
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        serial_clock <= spi_sclk_i;
        serial_clock_prev <= serial_clock;
        serial_data <= spi_dat_i;
    end if;
end process;

-- Shift source synchronous data on the Falling egde of clock
shift_clock <= not serial_clock and serial_clock_prev;

serial_link_detect_inst : entity work.serial_link_detect
generic map (
    SYNCPERIOD          => SYNCPERIOD
)
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    clock_i             => serial_clock,
    active_i            => shift_enabled,
    link_up_o           => link_up
);

--
-- Serial Receive State Machine
--
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1' or link_up = '0') then
            shift_counter <= (others => '0');
            shift_enabled <= '0';
        else
            -- Following link_up, wait for first falling egde of
            -- clock to enable shifting.
            if (shift_clock = '1' and shift_enabled = '0') then
                shift_enabled <= '1';
            elsif (shift_clock = '1' and shift_counter = BITS-1) then
                shift_enabled <= '0';
            end if;

            -- Once enabled, shift data into the register.
            if (shift_enabled = '1') then
                if (shift_clock = '1') then
                    shift_counter <= shift_counter + 1;
                end if;
            else
                shift_counter <= (others => '0');
            end if;
        end if;
    end if;
end process;

-- Shift data into a register once enabled.
shift_data <= serial_data;

shifter_in_inst : entity work.shifter_in
generic map (
    DW              => BITS
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    ENCODING        => "00",
    enable_i        => shift_enabled,
    clock_i         => shift_clock,
    data_i          => shift_data,
    data_o          => shift_in,
    data_valid_o    => shift_in_valid
);

-- Assign register interface outputs to upper level.
rd_adr_o <= shift_in(BITS-1 downto 32);
rd_dat_o <= shift_in(31 downto 0);
rd_val_o <= shift_in_valid;

end rtl;
