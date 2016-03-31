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

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;

entity slow_engine_tx is
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
    busy_o          : out std_logic;
    -- Serial Physical interface
    spi_sclk_o      : out std_logic;
    spi_dat_o       : out std_logic
);
end slow_engine_tx;

architecture rtl of slow_engine_tx is

-- Ticks in terms of internal serial clock period.
constant DEADPERIOD             : natural := 10;    -- 10usec

type sh_states is (idle, sync, shifting, deadtime);
signal sh_state                 : sh_states;

signal sclk                     : std_logic;
signal sclk_ce                  : std_logic;
signal shift_out                : std_logic_vector(AW+DW downto 0);
signal sh_counter               : unsigned(5 downto 0);

begin

--
-- Presclaed clock to be used internally.
--
shift_clk: entity work.prescaler
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    PERIOD          => TO_SVECTOR(CLKDIV, 32),
    pulse_o         => sclk_ce
);

--
-- Serial Transmit State Machine
--
-- SPI Clock output is 2*prescaled clock.
--
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1' or wr_rst_i = '1') then
            sh_state <= idle;
            sh_counter <= (others => '0');
            sclk <= '1';
            shift_out <= (others => '0');
        else
            -- Main state machine
            case sh_state is
                -- Wait for write request
                when idle =>
                    sclk <= '1';
                    sh_counter <= (others => '0');
                    if (wr_req_i = '1') then
                        shift_out <= '0' & wr_adr_i & wr_dat_i;
                        sh_state <= sync;
                    end if;

                -- Sync to next internal SPI clock
                when sync =>
                    if (sclk_ce = '1') then
                        sclk <= '0';
                        sh_state <= shifting;
                    end if;

                -- Keep track of clock outputs and shift data out
                when shifting =>
                    if (sclk_ce = '1') then
                        sclk <= not sclk;
                    end if;

                    -- sclk_ce is ticking twice the sclk, so make sure
                    -- to count sclk pulses correctly
                    if (sclk_ce = '1' and sclk = '0') then
                        sh_counter <= sh_counter + 1;

                        shift_out <= shift_out(shift_out'length - 2 downto 0) & '0';
                        if (sh_counter = AW+DW) then
                            sh_counter <= (others => '0');
                            sh_state <= deadtime;
                        end if;
                    end if;

                when deadtime =>
                    -- Wait for DEADPERIOD.
                    if (sclk_ce = '1') then
                        if (sh_counter = DEADPERIOD) then
                            sh_state <= idle;
                        else
                            sh_counter <= sh_counter + 1;
                        end if;
                    end if;

                when others =>
                    sh_state <= idle;
            end case;
        end if;
    end if;
end process;

-- Serial interface busy
busy_o <= '0' when (sh_state = idle) else '1';

-- Connect outputs
spi_sclk_o  <= sclk;
spi_dat_o <= shift_out(shift_out'length - 1);


end rtl;
