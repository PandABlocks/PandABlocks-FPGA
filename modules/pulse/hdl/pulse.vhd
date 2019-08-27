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

constant c_fifo_error_value     : std_logic_vector(2 downto 0) := "100";

constant c_number_zero          : std_logic_vector(1 downto 0) := "00";
constant c_number_one           : std_logic_vector(1 downto 0) := "01";
constant c_number_two           : std_logic_vector(1 downto 0) := "10";

constant c_timestamp_max        : unsigned(47 downto 0) := (others => '1');
constant c_timestamp_min        : unsigned(47 downto 0) := (others => '0');


-- Standard logic signals

signal enable_i_prev            : std_logic := '0';
signal enable_rise              : std_logic := '0';

signal full_pulse_program       : std_logic := '0';
signal full_ts_calculations     : std_logic := '0';

signal got_pulse_program        : std_logic := '0';

signal had_falling_trigger      : std_logic := '0';
signal had_rising_trigger       : std_logic := '0';
signal had_trigger              : std_logic := '0';

signal partial_ts_calculations  : std_logic := '0';
signal pulse                    : std_logic := '0';
signal pulse_queued_empty       : std_logic := '0';
signal pulse_queued_full        : std_logic := '0';
signal pulse_queued_rstb        : std_logic := '0';
signal pulse_queued_wstb        : std_logic := '0';
signal pulse_value              : std_logic := '0';

signal queue_pulse_value        : std_logic := '0';

signal reset                    : std_logic := '0';

signal start_delay_countdown    : std_logic := '0';

signal timestamp_latch          : std_logic := '0';

signal trig_fall_prev           : std_logic := '0';
signal trig_i_prev              : std_logic := '0';
signal trig_rise_prev           : std_logic := '0';
signal trig_same_prev           : std_logic := '0';

signal trig_fall                : std_logic := '0';
signal trig_rise                : std_logic := '0';
signal trig_same                : std_logic := '0';

signal value                    : std_logic := '0';

signal waiting_for_delay        : std_logic := '1';


-- Standard logic vector signals

signal program_progress         : std_logic_vector(1 downto 0) := (others => '0');

signal pulse_queued_din         : std_logic_vector(48 downto 0);
signal pulse_queued_dout        : std_logic_vector(48 downto 0);
signal pulse_queued_data_count  : std_logic_vector(10 downto 0);


-- Unsigned integer signals

signal delay_i                  : unsigned(47 downto 0) := (others => '0');
signal delay_i_prev             : unsigned(47 downto 0) := (others => '0');
signal delay_remaining          : unsigned(47 downto 0) := (others => '0');

signal edge_width               : unsigned(47 downto 0) := (others => '0');
signal edges_remaining          : unsigned(31 downto 0) := (others => '0');

signal fifo_error               : unsigned(2 downto 0)  := "100";
signal fifo_error_prev          : unsigned(2 downto 0)  := "100";

signal gap_i                    : unsigned(47 downto 0) := (others => '0');

signal initial_program_timestamp: unsigned(47 downto 0) := (others => '0');

signal missed_pulses            : unsigned(31 downto 0) := (others => '0');

signal programmed_step          : unsigned(47 downto 0) := (others => '0');
signal programmed_width         : unsigned(47 downto 0) := (others => '0');
signal pulses_i                 : unsigned(31 downto 0) := (others => '0');
signal pulse_ts                 : unsigned(47 downto 0) := (others => '0');

signal queued_din               : unsigned(47 downto 0) := (others => '0');
signal queue_pulse_ts           : unsigned(47 downto 0) := (others => '0');

signal step_i                   : unsigned(47 downto 0) := (others => '0');
signal step_i_prev              : unsigned(47 downto 0) := (others => '0');

signal timestamp                : unsigned(47 downto 0) := (others => '0');
signal timestamp_fall           : unsigned(47 downto 0) := (others => '0');
signal timestamp_prev           : unsigned(47 downto 0) := (others => '0');
signal timestamp_rise           : unsigned(47 downto 0) := (others => '0');

signal width_i                  : unsigned(47 downto 0) := (others => '0');
signal width_i_prev             : unsigned(47 downto 0) := (others => '0');

begin

-- The pulse queue; keeps track of the timestamps of incoming pulses, maps to component above, attached to this architecture
pulse_queue_inst : pulse_queue
port map (
    clk         => clk_i,
    srst        => reset,
    din         => pulse_queued_din,
    wr_en       => pulse_queued_wstb,
    rd_en       => pulse_queued_rstb,
    dout        => pulse_queued_dout,
    full        => pulse_queued_full,
    empty       => pulse_queued_empty,
    data_count  => pulse_queued_data_count
);

-- Code that runs outside of a process architecture (i.e. not executed in sequence, all executed in parallel)

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


-- If 0 < DELAY < 4, it should be set to 4
delay_i <=  (unsigned(DELAY) - 2) when (unsigned(DELAY) > 6) else
            (2 => '1', others => '0');

-- If Delay is zero and WIDTH is between 0 and 4 WIDTH should be 4
width_i <=  unsigned(WIDTH) when (not(unsigned(DELAY) = 0 and (unsigned(WIDTH) > 0) and unsigned(WIDTH) < 4)) else
            (2 => '1', others => '0');

-- Make sure that if we recieve a pulse and the PULSE variable is accidentally set to zero we don't punish a hapless user
pulses_i <= unsigned(PULSES) when (unsigned(PULSES) /= 0) else
            (0 => '1', others => '0');

-- For those requiring mathematics
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (width_i /= width_i_prev) then
            if (unsigned(STEP) > width_i) then
                step_i <= unsigned(STEP);
            else
                step_i <= unsigned(STEP) + width_i + 1;
            end if;
        elsif (partial_ts_calculations = '1') then
            if (unsigned(STEP) > programmed_width) then
                step_i <= unsigned(STEP);
            else
                step_i <= unsigned(STEP) + programmed_width + 1;
            end if;
        elsif (full_ts_calculations = '1') then
            if (programmed_step > programmed_width) then
                step_i <= programmed_step;
            else
                step_i <= programmed_step + programmed_width + 1;
            end if;
        end if;
    end if;
end process;

process(clk_i)
begin
    if rising_edge(clk_i) then
        if ((width_i /= width_i_prev) or (step_i /= step_i_prev)) then
            if (width_i /= 0) then
                if ((signed(step_i) - signed(width_i)) > 1) then
                    gap_i <= step_i - width_i;
                else
                    gap_i <= (0 => '1', others => '0');
                end if;
            end if;
        elsif (partial_ts_calculations = '1') then
            if ((signed(STEP) - signed(programmed_width)) > 1) then
                gap_i <= unsigned(STEP) - programmed_width;
            else
                gap_i <= (1 => '1', others => '0');
            end if;
        elsif (full_ts_calculations = '1') then
            if ((signed(programmed_step) - signed(programmed_width)) > 1) then
                gap_i <= programmed_step - programmed_width;
            else
                gap_i <= (1 => '1', others => '0');
            end if;
        end if;
    end if;
end process;


-- Are we reading the queue?
queue_pulse_ts <= unsigned(pulse_queued_dout(47 downto 0));
queue_pulse_value <= pulse_queued_dout(48);

-- Assign the pulse value to the externally facing port
out_o <= pulse;


-- Other output assignments
DROPPED <= std_logic_vector(missed_pulses);
QUEUED <= ZEROS(32-pulse_queued_data_count'length) &  pulse_queued_data_count;


-- Ignore period error for the first pulse in the train and any fifo based anomolies.
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            fifo_error <= unsigned(c_fifo_error_value);
        else
            if (pulse_queued_wstb = '1') then
                fifo_error <= unsigned(c_fifo_error_value);
            elsif (fifo_error /= 0) then
                fifo_error <= fifo_error - 1;
            end if;
        end if;
    end if;
end process;


-- Code that runs inside process structures (i.e. code that runs in sequence with the blocks running in parallel)

-- Free running global timestamp counter
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            timestamp <= (others => '0');
        else
            timestamp <= timestamp + 1;
        end if;
    end if;
end process;


-- Enable rise signal
process(clk_i) begin
    if rising_edge(clk_i) then
        if (enable_i = '1' and (enable_i /= enable_i_prev)) then
            enable_rise <= '1';
        else
            enable_rise <= '0';
        end if;
    end if;
end process;


-- Free running edge watcher
process(clk_i)
begin
    if rising_edge(clk_i) then
        trig_fall <= '0';
        trig_rise <= '0';
        trig_same <= '0';

        -- Detect the current edge state, if differrent
        if ((trig_i = '0') and (trig_i /= trig_i_prev)) then
            trig_fall <= '1';
        elsif ((trig_i = '1') and (trig_i /= trig_i_prev)) then
            trig_rise <= '1';
        elsif (trig_i = trig_i_prev) then
            trig_same <= '1';
        end if;
    end if;
end process;


-- Free running delay countdown block
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (delay_remaining /= 0) then
            delay_remaining <= delay_remaining - 1;
        elsif ((start_delay_countdown = '1') and (pulse_queued_empty = '1')) then
            delay_remaining <= delay_i - 2;
        end if;
    end if;
end process;


-- Variable storage for comparison next clock cycle
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            delay_i_prev      <= (others => '0');
            enable_i_prev     <= '0';
            fifo_error_prev   <= (others => '0');
            step_i_prev       <= (others => '0');
            timestamp_prev    <= (others => '0');
            trig_fall_prev    <= '0';
            trig_i_prev       <= '0';
            trig_rise_prev    <= '0';
            trig_same_prev    <= '0';
            width_i_prev      <= (others => '0');
        else
            delay_i_prev      <= delay_i;
            enable_i_prev     <= enable_i;
            fifo_error_prev   <= fifo_error;
            step_i_prev       <= step_i;
            timestamp_prev    <= timestamp;
            trig_fall_prev    <= trig_fall;
            trig_i_prev       <= trig_i;
            trig_rise_prev    <= trig_rise;
            trig_same_prev    <= trig_same;
            width_i_prev      <= width_i;
        end if;
    end if;
end process;


-- Filling the queue
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            missed_pulses <= (others => '0');
        end if;

        if (reset = '1' or rising_edge(enable_i)) then
            -- In case of a reset we'll need to reset these values from this process
            had_rising_trigger <= '0';
            had_falling_trigger <= '0';
            missed_pulses <= (others => '0');
            pulse_queued_wstb <= '0';
            queued_din <= (others => '0');
            full_ts_calculations <= '0';
            partial_ts_calculations <= '0';
            start_delay_countdown <= '0';

        elsif (enable_i = '1') then
            -- Bits that need resetting every clock cycle
            partial_ts_calculations <= '0';
            full_ts_calculations <= '0';
            pulse_queued_wstb <= '0';
            value <= '0';
            start_delay_countdown <= '0';

            if (trig_rise = '1') then
                timestamp_rise <= timestamp;
                had_rising_trigger <= '1';
            elsif (trig_fall = '1') then
                timestamp_fall <= timestamp;
                had_falling_trigger <= '1';
            end if;

            -- If check to make sure that we should be storing this event at all
            if (trig_same /= '1') then
                -- First up, event rejection criteria:
                -- 1)   Queue full condition flags an error, and ticks missing pulse counter
                -- 2)   Pulse period must obey Xilinx FIFO IP latency following the first pulse
                -- 3)   Can't accept more pulses if we're processing them already
                if (pulse_queued_full = '1' or waiting_for_delay = '0' or edges_remaining /= 0) then
                    if(((TRIG_EDGE(1 downto 0) = c_number_zero) and (trig_rise = '1')) or
                       ((TRIG_EDGE(1 downto 0) = c_number_one) and (trig_fall = '1')) or
                        (TRIG_EDGE(1 downto 0) = c_number_two)) then
                            missed_pulses <= missed_pulses + 1;
                    end if;
                -- Next, if we have a width (i.e. no timestamp maths required)
                elsif (width_i /= 0) then
                    if(((TRIG_EDGE(1 downto 0) = c_number_zero) and (trig_rise = '1')) or
                       ((TRIG_EDGE(1 downto 0) = c_number_one) and (trig_fall = '1')) or
                        (TRIG_EDGE(1 downto 0) = c_number_two)) then
                            pulse_queued_wstb <= '1';
                            queued_din <= width_i;
                            pulse_queued_din <= '1' & std_logic_vector(width_i);
                            start_delay_countdown <= '1';
                    end if;

                -- If we have a step but no width
                elsif ((width_i = 0) and (unsigned(STEP) /= 0)) then
                    -- We can do what we did in the previous statement with a different assignment
                    if (TRIG_EDGE(1 downto 0) = c_number_zero) then
                        if ((trig_rise = '1') and (program_progress = c_number_zero)) then
                            program_progress <= c_number_one;
                            pulse_queued_wstb <= '1';
                            queued_din <= unsigned(c_timestamp_min);
                            pulse_queued_din <= '0' & std_logic_vector(c_timestamp_min);
                            start_delay_countdown <= '1';
                        elsif ((trig_fall = '1') and (had_rising_trigger = '1') and (program_progress = c_number_one)) then
                            program_progress <= c_number_zero;
                            pulse_queued_wstb <= '1';
                            programmed_width <= timestamp - timestamp_rise;
                            queued_din <= timestamp - timestamp_rise;
                            pulse_queued_din <= '0' & std_logic_vector(timestamp - timestamp_rise);
                            partial_ts_calculations <= '1';
                        end if;
                    end if;

                    if ((TRIG_EDGE(1 downto 0) = c_number_one) and (program_progress = c_number_zero)) then
                        if (trig_fall = '1') then
                            program_progress <= c_number_one;
                            pulse_queued_wstb <= '1';
                            queued_din <= unsigned(c_timestamp_min);
                            pulse_queued_din <= '0' & std_logic_vector(c_timestamp_min);
                            start_delay_countdown <= '1';
                        elsif ((trig_rise = '1') and (had_falling_trigger = '1') and (program_progress = c_number_one)) then
                            program_progress <= c_number_zero;
                            pulse_queued_wstb <= '1';
                            programmed_width <= timestamp - timestamp_fall;
                            queued_din <= timestamp - timestamp_fall;
                            pulse_queued_din <= '0' & std_logic_vector(timestamp - timestamp_fall);
                            partial_ts_calculations <= '1';
                        end if;
                    end if;

                -- If we have no step and no width
                elsif ((width_i = 0) and (unsigned(STEP) = 0)) then
                    -- We can do what we did in the previous statement with a different assignment
                    if (TRIG_EDGE(1 downto 0) = c_number_zero) then
                        if ((trig_rise = '1') and (program_progress = c_number_zero)) then
                            program_progress <= c_number_one;
                            pulse_queued_wstb <= '1';
                            pulse_queued_din <= '0' & std_logic_vector(c_timestamp_min);
                            start_delay_countdown <= '1';
                        elsif ((trig_fall = '1') and (had_rising_trigger = '1') and (program_progress = c_number_one)) then
                            program_progress <= c_number_two;
                            pulse_queued_wstb <= '1';
                            programmed_width <= timestamp - timestamp_rise;
                            queued_din <= unsigned(c_timestamp_max);
                            pulse_queued_din <= '0' & std_logic_vector(c_timestamp_max);
                        elsif ((trig_rise = '1') and (had_rising_trigger = '1') and (program_progress = c_number_two)) then
                            program_progress <= c_number_zero;
                            pulse_queued_wstb <= '1';
                            programmed_step <= timestamp - timestamp_rise;
                            queued_din <= timestamp_fall - timestamp_rise;
                            pulse_queued_din <= '0' & std_logic_vector(timestamp_fall - timestamp_rise);
                            full_ts_calculations <= '1';
                        end if;
                    end if;

                    if (TRIG_EDGE(1 downto 0) = c_number_one) then
                        if ((trig_fall = '1') and (program_progress = c_number_zero)) then
                            program_progress <= c_number_one;
                            pulse_queued_wstb <= '1';
                            pulse_queued_din <= '0' & std_logic_vector(c_timestamp_min);
                            start_delay_countdown <= '1';
                        elsif ((trig_rise = '1') and (had_falling_trigger = '1') and (program_progress = c_number_one)) then
                            program_progress <= c_number_two;
                            pulse_queued_wstb <= '1';
                            programmed_width <= timestamp - timestamp_fall;
                            queued_din <= unsigned(c_timestamp_max);
                            pulse_queued_din <= '0' & std_logic_vector(c_timestamp_max);
                        elsif ((trig_fall = '1') and (had_falling_trigger = '1') and (program_progress = c_number_two)) then
                            program_progress <= c_number_zero;
                            pulse_queued_wstb <= '1';
                            programmed_step <= timestamp - timestamp_fall;
                            queued_din <= timestamp_rise - timestamp_fall;
                            pulse_queued_din <= '0' & std_logic_vector(timestamp_rise - timestamp_fall);
                            full_ts_calculations <= '1';
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
    if rising_edge(clk_i) then
        if (enable_i = '1') then
            if (reset = '1' or rising_edge(enable_i)) then
                edges_remaining <= (others => '0');
                edge_width <= (others => '0');
                waiting_for_delay <= '1';
                full_pulse_program <= '1';
                pulse_queued_rstb <= '0';
                pulse_ts <= (others => '0');
                edge_width <= (others => '0');
                pulse <= '0';
                timestamp_latch <= '0';
            end if;

            pulse_queued_rstb <= '0';

            if (delay_remaining = 1) then
                waiting_for_delay <= '0';
                pulse_queued_rstb <= '1';
            else
                if (pulse_queued_empty = '1' and (timestamp >= pulse_ts)) then
                    waiting_for_delay <= '1';
                end if;
            end if;

            if (edges_remaining = 0) then
                if (waiting_for_delay = '0' and (timestamp >= pulse_ts)) then
                        if (queue_pulse_value = '1') then
                            edge_width <= queue_pulse_ts;
                            pulse_ts <= timestamp + queue_pulse_ts;
                            pulse <= queue_pulse_value;
                            edges_remaining <= unsigned(pulses_i) + unsigned(pulses_i) - 1;
                        else
                            if (queue_pulse_ts = 0) then
                                pulse <= '1';
                                
                                if (timestamp_latch = '0') then
                                    initial_program_timestamp <= timestamp;
                                    timestamp_latch <= '1';
                                end if;

                                full_pulse_program <= '0';

                            elsif (queue_pulse_ts = unsigned(c_timestamp_max)) then
                                edge_width <= programmed_width;
                                pulse_ts <= initial_program_timestamp + programmed_width;
                                
                                if (timestamp = (initial_program_timestamp + programmed_width)) then
                                    pulse <= '0';
                                    edges_remaining <= unsigned(pulses_i) + unsigned(pulses_i) - 2;
                                else
                                    edges_remaining <= unsigned(pulses_i) + unsigned(pulses_i) - 1;
                                end if;

                                timestamp_latch <= '0';
                                full_pulse_program <= '1';
                            else
                                if (full_pulse_program = '0') then
                                    edge_width <= queue_pulse_ts;
                                    pulse_ts <= initial_program_timestamp + queue_pulse_ts;
                                    edges_remaining <= unsigned(pulses_i) + unsigned(pulses_i) - 1;

                                    timestamp_latch <= '0';
                                    full_pulse_program <= '1';
                                end if;
                            end if;
                        end if;
                end if;
            else
                if (timestamp = pulse_ts) then
                    if (unsigned(edges_remaining mod 2) = 0) then
                        pulse_ts <= timestamp + edge_width;
                        pulse <= not pulse;
                        edges_remaining <= edges_remaining - 1;
                    else
                        pulse_ts <= timestamp + gap_i;
                        pulse <= not pulse;
                        edges_remaining <= edges_remaining - 1;
                    end if;

                    if (edges_remaining = 1) then
                        pulse_queued_rstb <= '1';
                    end if;
                end if;
            end if;
        else
            pulse <= '0';
        end if;
    end if;
end process;

end rtl;