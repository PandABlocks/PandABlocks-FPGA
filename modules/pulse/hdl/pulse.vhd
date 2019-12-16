library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity pulse is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    trig_i              : in  std_logic;
    enable_i            : in  std_logic;
    out_o               : out std_logic;
    -- Block Parameters
    TRIG_EDGE           : in  std_logic_vector(31 downto 0) := (others => '0');
    TRIG_EDGE_WSTB      : in  std_logic;
    DELAY_L             : in  std_logic_vector(31 downto 0);
    DELAY_L_WSTB        : in  std_logic;
    DELAY_H             : in  std_logic_vector(31 downto 0);
    DELAY_H_WSTB        : in  std_logic;
    WIDTH_L             : in  std_logic_vector(31 downto 0);
    WIDTH_L_WSTB        : in  std_logic;
    WIDTH_H             : in  std_logic_vector(31 downto 0);
    WIDTH_H_WSTB        : in  std_logic;
    PULSES              : in  std_logic_vector(31 downto 0) := (others => '0');
    PULSES_WSTB         : in  std_logic;
    STEP_L              : in  std_logic_vector(31 downto 0);
    STEP_L_WSTB         : in  std_logic;
    STEP_H              : in  std_logic_vector(31 downto 0);
    STEP_H_WSTB         : in  std_logic;
    -- Block Status
    QUEUED              : out std_logic_vector(31 downto 0);
    DROPPED             : out std_logic_vector(31 downto 0)
);
end pulse;

architecture rtl of pulse is

-- The pulse queue; keeps track of the timestamps of incoming pulses
component pulse_queue
port (
    clk                 : in std_logic;
    srst                : in std_logic;
    din                 : in std_logic_vector(48 DOWNTO 0);
    wr_en               : in std_logic;
    rd_en               : in std_logic;
    dout                : out std_logic_vector(48 DOWNTO 0);
    full                : out std_logic;
    empty               : out std_logic;
    data_count          : out std_logic_vector(10 downto 0)
);
end component;

-- Variable declarations

-- Attached to architecture inputs

signal DELAY            : std_logic_vector(47 downto 0);
signal DELAY_wstb       : std_logic;
signal STEP             : std_logic_vector(47 downto 0);
signal STEP_wstb        : std_logic;
signal WIDTH            : std_logic_vector(47 downto 0);
signal WIDTH_wstb       : std_logic;


-- Constants

constant c_rising_edge_trigger  : std_logic_vector(1 downto 0) := "00";
constant c_falling_edge_trigger : std_logic_vector(1 downto 0) := "01";
constant c_both_edge_trigger    : std_logic_vector(1 downto 0) := "10";
constant c_two_ticks            : std_logic_vector(47 downto 0) := (1 => '1', others => '0');

-- Standard logic signals

signal dropped_flag             : std_logic := '0';

signal enable_i_prev            : std_logic := '0';

signal fancy_delay_line_started : std_logic := '0';

signal got_pulse                : std_logic := '0';

signal had_falling_trigger      : std_logic := '0';
signal had_rising_trigger       : std_logic := '0';

signal pulse                    : std_logic := '0';
signal pulse_assertion_override : std_logic := '0';
signal pulse_queued_empty       : std_logic := '0';
signal pulse_queued_full        : std_logic := '0';
signal pulse_queued_reset       : std_logic := '0';
signal pulse_queued_rstb        : std_logic := '0';
signal pulse_queued_wstb        : std_logic := '0';
signal pulse_value              : std_logic := '0';

signal queue_pulse_value        : std_logic := '0';

signal start_delay_countdown    : std_logic := '0';

signal trig_fall                : std_logic := '0';
signal trig_rise                : std_logic := '0';
signal trig_same                : std_logic := '1';
signal trig_i_prev              : std_logic := '0';

signal value                    : std_logic := '0';

signal waiting_for_delay        : std_logic := '1';


-- Standard logic vector signals

signal pulse_queued_din         : std_logic_vector(48 downto 0);
signal pulse_queued_dout        : std_logic_vector(48 downto 0);
signal pulse_queued_data_count  : std_logic_vector(10 downto 0);


-- Unsigned integer signals

signal delay_i                  : unsigned(47 downto 0) := (others => '0');
signal delay_remaining          : unsigned(47 downto 0) := (others => '0');

signal edges_remaining          : unsigned(31 downto 0) := (others => '0');
signal end_pulse_assertion_ts   : unsigned(47 downto 0) := (others => '0');

signal gap_i                    : unsigned(47 downto 0) := (others => '0');

signal missed_pulses            : unsigned(31 downto 0) := (others => '0');

signal pulses_i                 : unsigned(31 downto 0) := (others => '0');
signal pulse_gap                : unsigned(47 downto 0) := (others => '0');
signal pulse_ts                 : unsigned(47 downto 0) := (others => '0');
signal pulse_width              : unsigned(47 downto 0) := (others => '0');

signal queued_din               : unsigned(47 downto 0) := (others => '0');
signal queue_pulse_ts           : unsigned(47 downto 0) := (others => '0');

signal step_i                   : unsigned(47 downto 0) := (others => '0');
signal step_i_prev              : unsigned(47 downto 0) := (others => '1');
signal signal_ts                : unsigned(47 downto 0) := (others => '0');

signal timestamp                : unsigned(47 downto 0) := (others => '0');
signal timestamp_fall           : unsigned(47 downto 0) := (others => '0');
signal timestamp_rise           : unsigned(47 downto 0) := (others => '0');

signal width_i                  : unsigned(47 downto 0) := (others => '0');
signal width_i_prev             : unsigned(47 downto 0) := (others => '1');

begin

-- The pulse queue; keeps track of the timestamps of incoming pulses, maps to component above, attached to this architecture
pulse_queue_inst : pulse_queue
port map (
    clk         => clk_i,
    srst        => pulse_queued_reset,
    din         => pulse_queued_din,
    wr_en       => pulse_queued_wstb,
    rd_en       => pulse_queued_rstb,
    dout        => pulse_queued_dout,
    full        => pulse_queued_full,
    empty       => pulse_queued_empty,
    data_count  => pulse_queued_data_count
);

-- Code that runs outside of a process architecture (i.e. not executed in sequence, all executed in parallel)

-- Bits relating to the FIFO queue

queue_pulse_ts <= unsigned(pulse_queued_dout(47 downto 0));
queue_pulse_value <= pulse_queued_dout(48);


-- Other output assignments
DROPPED <= std_logic_vector(missed_pulses);
QUEUED <= ZEROS(32-pulse_queued_data_count'length) &  pulse_queued_data_count;


-- Bits relating to timings

-- Take 48-bit time as combination of two for:
-- 1) The delay width
DELAY_WSTB <= DELAY_L_WSTB or DELAY_H_WSTB;
DELAY(31 downto 0) <= DELAY_L;
DELAY(47 downto 32) <= DELAY_H(15 downto 0);

-- 2) The pulse width
WIDTH_WSTB <= WIDTH_L_WSTB or WIDTH_H_WSTB;
WIDTH(31 downto 0) <= WIDTH_L;
WIDTH(47 downto 32) <= WIDTH_H(15 downto 0);

-- 3) The overall step width
STEP_WSTB <= STEP_L_WSTB or STEP_H_WSTB;
STEP(31 downto 0) <= STEP_L;
STEP(47 downto 32) <= STEP_H(15 downto 0);


-- For those not requiring mathematics

-- If 0 < DELAY < 6, it should be set to 6
delay_i <=  (unsigned(DELAY)) when (unsigned(DELAY) > 5) else to_unsigned(6, 48);


gap_i <=    step_i - width_i when ((signed(step_i) - signed(width_i)) > 2) else to_unsigned(2, 48);


-- Make sure that if we recieve a pulse and the PULSE variable is accidentally set to zero we don't punish a hapless user
pulses_i <= unsigned(PULSES) when (unsigned(PULSES) /= 0) else to_unsigned(1, 32);


step_i <=   unsigned(STEP) when (unsigned(STEP) > unsigned(WIDTH) or unsigned(STEP) = 0) else
            unsigned(STEP) + width_i + 1;


-- Set an internal width value
width_i <=  (unsigned(WIDTH)) when (unsigned(WIDTH) > 5 or unsigned(WIDTH) = 0) else to_unsigned(6, 48);
          

-- Free running global timestamp counter
process(clk_i)
begin
    if (rising_edge(clk_i)) then
        if (enable_i = '1') then
            timestamp <= timestamp + 1;
        elsif ((enable_i_prev = '1') and (enable_i = '0')) then
            timestamp <= (others => '0');
        end if;
    end if;
end process;


-- Free running edge watcher

-- Nested, clocked, statements not supported - will have to revert to previous methodology
-- Comparing the status of the previous clock cycle!
process(clk_i)
begin
    if (rising_edge(clk_i)) then
        trig_i_prev <= trig_i;
        enable_i_prev <= enable_i;

        if (enable_i = '1') then
            trig_fall <= '0';
            trig_rise <= '0';
            trig_same <= '0';

            -- Detect the current edge state, if differrent
            if ((trig_i = '0') and (trig_i /= trig_i_prev)) then
                trig_fall <= '1';

                if( (unsigned(DELAY) = 0) and
                    (pulse_assertion_override = '0') and
                    (waiting_for_delay = '1') and
                    ((TRIG_EDGE(1 downto 0) = c_falling_edge_trigger) or
                    (TRIG_EDGE(1 downto 0) = c_both_edge_trigger))
                  ) then

                    pulse_assertion_override <= '1';
                    end_pulse_assertion_ts <= timestamp + 6;
                end if;

            elsif ((trig_i = '1') and (trig_i /= trig_i_prev)) then
                trig_rise <= '1';

                if( (unsigned(DELAY) = 0) and
                    (pulse_assertion_override = '0') and
                    (waiting_for_delay = '1') and
                    ((TRIG_EDGE(1 downto 0) = c_rising_edge_trigger) or
                    (TRIG_EDGE(1 downto 0) = c_both_edge_trigger))
                  ) then

                    pulse_assertion_override <= '1';
                    end_pulse_assertion_ts <= timestamp + 6;
                end if;

            elsif (trig_i = trig_i_prev) then
                trig_same <= '1';
            end if;

            if (timestamp = end_pulse_assertion_ts) then
                pulse_assertion_override <= '0';
            end if;
        end if;
    end if;
end process;


-- Free running delay countdown block
process(clk_i)
begin
    if (rising_edge(clk_i)) then
        if (enable_i = '1') then
            if (delay_remaining /= 0) then
                delay_remaining <= delay_remaining - 1;
            elsif ((start_delay_countdown = '1') and (pulse_queued_empty = '1')) then
                if (fancy_delay_line_started = '0') then
                    delay_remaining <= delay_i - 4;
                else
                    if (delay_remaining = 6) then
                        delay_remaining <= delay_i - 4;
                    else
                        delay_remaining <= delay_i - 3;
                    end if;
                end if;
            end if;
        else
            delay_remaining <= (others => '0');
        end if;
    end if;
end process;


-- Filling the queue
process(clk_i)
begin
    if(rising_edge(clk_i)) then
        if (enable_i = '1') then
            if (enable_i_prev = '0') then
                -- In case of a reset we'll need to reset these values from this process
                fancy_delay_line_started <= '0';

                had_rising_trigger <= '0';
                had_falling_trigger <= '0';

                missed_pulses <= (others => '0');
                
                pulse_queued_din <= (others => '0');
                pulse_queued_reset <= '1';
                pulse_queued_wstb <= '0';
                
                start_delay_countdown <= '0';

                timestamp_rise <= (others => '0');
                timestamp_fall <= (others => '0');

                value <= '0';
            else
                -- Bits that need resetting every clock cycle
                pulse_queued_reset <= '0';
                pulse_queued_wstb <= '0';
                value <= '0';
                start_delay_countdown <= '0';

                if (trig_rise = '1') then
                    timestamp_rise <= timestamp;
                elsif (trig_fall = '1') then
                    timestamp_fall <= timestamp;
                end if;

                if (waiting_for_delay = '0') then
                    had_falling_trigger <= '0';
                    had_rising_trigger <= '0';
                end if;

                if (dropped_flag = '1') then
                    missed_pulses <= missed_pulses + 1;
                end if;

                -- If check to make sure that we should be storing this event at all
                if (trig_same /= '1') then
                    -- First up, event rejection criteria:
                    -- 1)   Queue full condition flags an error, and ticks missing pulse counter
                    -- 2)   Pulse period must obey Xilinx FIFO IP latency following the first pulse
                    -- 3)   Can't accept more pulses if we're processing them already
                    if ((pulse_assertion_override = '0' and fancy_delay_line_started = '0' and (pulse_queued_full = '1' or waiting_for_delay = '0' or edges_remaining /= 0)) or
                        (pulse_assertion_override = '1' and timestamp /= end_pulse_assertion_ts - 5)) then
                        if(((TRIG_EDGE(1 downto 0) = c_rising_edge_trigger) and (trig_rise = '1')) or
                           ((TRIG_EDGE(1 downto 0) = c_falling_edge_trigger) and (trig_fall = '1')) or
                            (TRIG_EDGE(1 downto 0) = c_both_edge_trigger)) then
                                missed_pulses <= missed_pulses + 1;
                        end if;

                    -- Next, if we have a width (i.e. no timestamp maths required)
                    elsif (width_i /= 0) then
                        if(((TRIG_EDGE(1 downto 0) = c_rising_edge_trigger) and (trig_rise = '1')) or
                           ((TRIG_EDGE(1 downto 0) = c_falling_edge_trigger) and (trig_fall = '1')) or
                            (TRIG_EDGE(1 downto 0) = c_both_edge_trigger)) then
                                pulse_queued_din <= '1' & std_logic_vector(width_i);
                                pulse_queued_wstb <= '1';

                                start_delay_countdown <= '1';
                        end if;

                    -- If we have a step but no width
                    elsif (width_i = 0 and unsigned(STEP) /= 0) then
                        if (TRIG_EDGE(1 downto 0) = c_rising_edge_trigger) then
                            if (trig_rise = '1' and had_rising_trigger = '0') then
                                had_rising_trigger <= '1';
                            elsif (trig_fall = '1' and had_rising_trigger = '1') then
                                had_rising_trigger <= '0';

                                if (timestamp_fall - timestamp_rise > 2) then
                                    pulse_queued_din <= '0' & std_logic_vector(timestamp - timestamp_rise);
                                else
                                    pulse_queued_din <= '0' & std_logic_vector(c_two_ticks);
                                end if;

                                pulse_queued_wstb <= '1';
                                start_delay_countdown <= '1';
                            end if;
                        end if;

                        if (TRIG_EDGE(1 downto 0) = c_falling_edge_trigger) then
                            if (trig_fall = '1' and had_falling_trigger = '0') then
                                had_falling_trigger <= '1';
                            elsif (trig_rise = '1' and had_falling_trigger = '1') then
                                had_falling_trigger <= '0';

                                if (timestamp_rise - timestamp_fall > 2) then
                                    pulse_queued_din <= '0' & std_logic_vector(timestamp - timestamp_fall);
                                else
                                    pulse_queued_din <= '0' & std_logic_vector(c_two_ticks);
                                end if;

                                pulse_queued_wstb <= '1';
                                start_delay_countdown <= '1';
                            end if;
                        end if;

                    -- If we have no step and no width
                    elsif ((width_i = 0) and (unsigned(STEP) = 0)) then
                        if (fancy_delay_line_started = '0') then
                            start_delay_countdown <= '1';
                            fancy_delay_line_started <= '1';
                        end if;

                        if (trig_rise = '1') then
                            pulse_queued_din <= '1' & std_logic_vector(timestamp + delay_i - 2);
                            pulse_queued_wstb <= '1';
                        elsif (trig_fall = '1') then
                            pulse_queued_din <= '0' & std_logic_vector(timestamp + delay_i - 2);
                            pulse_queued_wstb <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;


-- Process to pass edges
process(clk_i)
begin
    if(rising_edge(clk_i)) then
        if (enable_i = '1') then
            if (enable_i_prev = '0') then
                dropped_flag <= '0';

                edges_remaining <= (others => '0');
                
                got_pulse <= '0';

                pulse <= '0';
                pulse_queued_rstb <= '0';
                pulse_ts <= (others => '0');
                pulse_width <= (others => '0');
                pulse_value <= '0';

                waiting_for_delay <= '1';
            else
                dropped_flag <= '0';
                pulse_queued_rstb <= '0';

                if (fancy_delay_line_started = '0') then
                    if (delay_remaining = 1) then
                        waiting_for_delay <= '0';
                        pulse_queued_rstb <= '1';
                    else
                        if (pulse_queued_empty = '1' and edges_remaining = 0 and (timestamp = pulse_ts - 1)) then
                            waiting_for_delay <= '1';
                        end if;
                    end if;
                end if;

                --- If we're running as a fancy delay line
                if ((width_i = 0) and (unsigned(STEP) = 0)) then
                    if (timestamp = queue_pulse_ts) then
                        pulse_ts <= queue_pulse_ts;
                        pulse_value <= queue_pulse_value;
                        pulse <= queue_pulse_value;

                        pulse_queued_rstb <= '1';
                    end if;

                --- Otherwise let's process some pulses
                else
                    if (edges_remaining = 0) then
                        if (waiting_for_delay = '0' and (timestamp >= pulse_ts)) then
                            if (width_i = 0 and unsigned(STEP) /= 0) then
                                if ((signed(step_i) - signed(queue_pulse_ts)) > 1) then
                                    pulse_gap <= step_i - queue_pulse_ts;
                                else
                                    pulse_gap <= to_unsigned(2, 48);
                                end if;

                                pulse_width <= queue_pulse_ts;
                            else
                                pulse_gap <= gap_i;
                                pulse_width <= queue_pulse_ts;
                            end if;

                            if ((unsigned(DELAY) = 0) and (pulse_assertion_override = '1')) then
                                pulse_ts <= timestamp + queue_pulse_ts - 5;
                                
                                if (timestamp >= (timestamp + queue_pulse_ts - 5)) then
                                    pulse <= '0';
                                    edges_remaining <= unsigned(pulses_i) + unsigned(pulses_i) - 2;
                                else
                                    pulse <= '1';
                                    edges_remaining <= unsigned(pulses_i) + unsigned(pulses_i) - 1;
                                end if;
                            else
                                edges_remaining <= unsigned(pulses_i) + unsigned(pulses_i) - 1;
                                pulse_ts <= timestamp + queue_pulse_ts;
                                pulse <= '1';
                            end if;
                        end if;
                    else
                        if (timestamp = pulse_ts) then
                            if (unsigned(edges_remaining mod 2) = 0) then
                                edges_remaining <= edges_remaining - 1;
                                pulse_ts <= timestamp + pulse_width;
                                pulse <= not pulse;
                            else
                                edges_remaining <= edges_remaining - 1;
                                pulse_ts <= timestamp + pulse_gap;
                                pulse <= not pulse;
                            end if;

                            if (edges_remaining = 1) then
                                pulse_queued_rstb <= '1';
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        else
            pulse <= '0';
        end if;
    end if;
end process;

out_o <= pulse_assertion_override or pulse;

end rtl;
