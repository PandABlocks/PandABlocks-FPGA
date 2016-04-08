--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Generate N clock pulse with CLK_PERIOD.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity clock_train_gen is
generic (
    DEAD_PERIOD     : natural := 125 * 20
)
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    N               : in  std_logic_vector(7 downto 0);
    CLK_PERIOD      : in  std_logic_vector(31 downto 0);
    start_i         : in  std_logic;
    clock_pulse_o   : out std_logic
);
end clock_train_gen;

architecture rtl of clock_train_gen is

-- Signal declarations
type fsm_state_t is (WAIT_START, SYNC_TO_CLK, GEN_MCLK, DATA_OUT);
signal fsm_state        : fsm_state_t;

signal serial_clk_2x    : std_logic;
signal serial_clk       : std_logic;
signal CLK_PERIOD_2x    : std_logic_vector(31 downto 0);
signal dead_counter     : natural range 0 to DEAD_PERIOD;
signal mclk_cnt         : natural range 0 to (2**N'length -1 );

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

-- SSI Master FSM
ssi_fsm_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            serial_clk <= '1';
            mclk_cnt <= 0;
            dead_counter <= 0;
        else
            case (fsm_state) is
                -- Wait for SSI frame trigger
                when WAIT_START =>
                    serial_clk <= '1';
                    mclk_cnt <= 0;
                    dead_counter <= 0;

                    if (frame_pulse = '1') then
                        fsm_state <= SYNC_TO_CLK;
                    end if;

                -- Sync to next internal SSI clock
                when SYNC_TO_CLK =>
                    if (serial_clk_2x = '1') then
                        fsm_state <= GEN_MCLK;
                        serial_clk <= '0';
                    end if;

                -- Generate N clock pulses
                when GEN_MCLK =>
                    if (serial_clk_2x = '1') then
                        serial_clk <= not serial_clk;
                    end if;

                    -- Keep track of number of BITS received
                    if (serial_clk_2x = '1' and serial_clk = '0') then
                        mclk_cnt <= mclk_cnt + 1;
                        if (mclk_cnt = to_integer(unsigned(N)))then
                            fsm_state <= DEADTIME;
                        end if;
                    end if;

                -- Output strobe
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


end rtl;
