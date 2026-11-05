library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Two-stage up counter: precounter counts 0..prescaler_rollover_i, counter
-- advances each time it rolls over and counts 0..timer_rollover_i. The timer
-- expires for one tick when both have reached their rollover values, which
-- takes (prescaler_rollover_i + 1) * (timer_rollover_i + 1) ticks. The
-- rollover values are compared, not latched, so they may change while the
-- timer runs; a change on the expiry tick applies to the next period.
--
-- out_o is a waveform derived from the counter: set on expiry, cleared when
-- counter = low_i (with the prescaler rolled). Leave it open to use the timer
-- as a plain expiry strobe.
entity prescaled_timer is
    generic (
        -- true: while disabled hold the counters at their rollover values so
        -- the timer expires on the first enabled tick (CLOCK).
        -- false: reset them to zero so the first expiry is a period away (SEQ).
        EXPIRE_ON_ENABLE : boolean := false
    );
    port (
        clk_i : in std_logic;
        enable_i : in std_logic;
        prescaler_rollover_i : in std_logic_vector(31 downto 0);
        timer_rollover_i : in std_logic_vector(31 downto 0);
        -- the default never clears out_o
        low_i : in std_logic_vector(31 downto 0) := (others => '1');
        expired_o : out std_logic;
        out_o : out std_logic := '0'
    );
end;

architecture rtl of prescaled_timer is
    signal counter : unsigned(31 downto 0) := (others => '0');
    signal precounter : unsigned(31 downto 0) := (others => '0');
    signal counter_rolled : std_logic := '0';
    signal precounter_rolled : std_logic := '0';
    signal expired : std_logic;
begin
    precounter_rolled <=
        '1' when precounter = unsigned(prescaler_rollover_i) else '0';
    counter_rolled <=
        '1' when counter = unsigned(timer_rollover_i) else '0';
    expired <= precounter_rolled and counter_rolled and enable_i;
    expired_o <= expired;
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if enable_i then
                if precounter_rolled then
                    precounter <= (others => '0');
                    if counter_rolled then
                        counter <= (others => '0');
                    else
                        counter <= counter + 1;
                    end if;
                else
                    precounter <= precounter + 1;
                end if;
                if expired then
                    out_o <= '1';
                elsif precounter_rolled = '1' and counter = unsigned(low_i) then
                    out_o <= '0';
                end if;
            else
                if EXPIRE_ON_ENABLE then
                    counter <= unsigned(timer_rollover_i);
                    precounter <= unsigned(prescaler_rollover_i);
                else
                    counter <= (others => '0');
                    precounter <= (others => '0');
                end if;
                out_o <= '0';
            end if;
        end if;
    end process;
end;
