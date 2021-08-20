--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Generate N clock pulse with CLK_PERIOD and DEAD_PERIOD at
--                the end of the clock train.
--                Active flag starts with the first rising-edge of the clock.
--                Busy flag starts with the falling of clock and end with dead
--                period.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity ssi_clock_gen is
generic (
    DEAD_PERIOD     : natural := 125 * 20
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    N               : in  std_logic_vector(7 downto 0);
    CLK_PERIOD      : in  std_logic_vector(31 downto 0);
    start_i         : in  std_logic;
    clock_pulse_o   : out std_logic;
    active_o        : out std_logic;
    busy_o          : out std_logic
);
end ssi_clock_gen;

architecture rtl of ssi_clock_gen is

-- Signal declarations
type fsm_state_t is (WAIT_START, SYNC_TO_CLK, GEN_MCLK, DEADTIME);
signal fsm_state        : fsm_state_t;

signal serial_clk_2x    : std_logic;
signal serial_clk       : std_logic;
signal CLK_PERIOD_2x    : std_logic_vector(31 downto 0);
signal clock_counter    : natural range 0 to (2**N'length -1 );
signal dead_counter     : natural range 0 to DEAD_PERIOD;

begin

-- Connect outputs
clock_pulse_o <= serial_clk;

-- Generate Internal SSI Clock (@2x freq) from system clock
CLK_PERIOD_2x <= '0' & CLK_PERIOD(31 downto 1);

serial_clk_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => CLK_PERIOD_2x,
    pulse_o     => serial_clk_2x
);

ssi_fsm_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            serial_clk <= '1';
            clock_counter <= 0;
            dead_counter <= 0;
            active_o <= '0';
            fsm_state<=WAIT_START;
        else
            -- SSI Clock Generator FSM
            case (fsm_state) is
                -- Wait for SSI frame trigger
                when WAIT_START =>
                    serial_clk <= '1';
                    clock_counter <= 0;
                    dead_counter <= 0;

                    if (start_i = '1') then
                        fsm_state <= SYNC_TO_CLK;
                    end if;

                -- Sync to next internal SSI clock
                when SYNC_TO_CLK =>
                    if (serial_clk_2x = '1') then
                        fsm_state <= GEN_MCLK;
                        serial_clk <= '0';
                    end if;

                -- Generate N clock pulses.
                -- Active flag is asserted with the first-rising edge of
                -- the serial clock.
                when GEN_MCLK =>
                    if (serial_clk_2x = '1') then
                        active_o <= '1';
                        serial_clk <= not serial_clk;
                    end if;

                    -- Keep track of number of BITS received
                    if (serial_clk_2x = '1' and serial_clk = '0') then
                        clock_counter <= clock_counter + 1;
                        if (clock_counter = to_integer(unsigned(N)))then
                            fsm_state <= DEADTIME;
                            active_o <= '0';
                        end if;
                    end if;

                -- Wait for DEADTIME
                when DEADTIME =>
                    dead_counter <= dead_counter + 1;

                    if (dead_counter = DEAD_PERIOD - 1) then
                        fsm_state <= WAIT_START;
                    end if;

                when others =>
            end case;
        end if;
    end if;
end process;

-- Serial interface busy
busy_o <= '0' when (fsm_state = WAIT_START) else '1';

end rtl;
