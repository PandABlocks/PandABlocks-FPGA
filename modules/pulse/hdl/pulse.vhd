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

constant c_trig_edge_pos        : std_logic_vector(1 downto 0) := "00";
constant c_trig_edge_neg        : std_logic_vector(1 downto 0) := "01";
constant c_trig_edge_pos_neg    : std_logic_vector(1 downto 0) := "10";


-- Standard logic signals

signal enable_i_prev            : std_logic := '0';
signal enable_rise              : std_logic := '0';

signal full_ts_calculations     : std_logic := '0';

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

signal pulse_queued_din         : std_logic_vector(48 downto 0);
signal pulse_queued_dout        : std_logic_vector(48 downto 0);
signal pulse_queued_data_count  : std_logic_vector(10 downto 0);


-- Unsigned integer signals

signal delay_i                  : unsigned(47 downto 0) := (others => '0');
signal delay_i_prev             : unsigned(47 downto 0) := (others => '0');
signal delay_remaining          : unsigned(47 downto 0) := (others => '0');

signal edge_width               : unsigned(47 downto 0) := (others => '0');
signal edges_remaining          : unsigned(31 downto 0) := (others => '0');

signal fifo_error               : unsigned(2 downto 0) := "100";
signal fifo_error_prev          : unsigned(2 downto 0) := "100";

signal gap_i                    : unsigned(47 downto 0) := (others => '0');

signal missed_pulses            : unsigned(31 downto 0) := (others => '0');

signal pulses_i                 : unsigned(31 downto 0) := (others => '0');
signal pulse_ts                 : unsigned(47 downto 0) := (others => '0');

signal queued_din               : unsigned(47 downto 0) := (others => '0');
signal queue_pulse_ts           : unsigned(47 downto 0) := (others => '0');

signal step_i                   : unsigned(47 downto 0) := (others => '0');
signal step_i_prev              : unsigned(47 downto 0) := (others => '0');

signal timestamp                : unsigned(47 downto 0) := (others => '0');
signal timestamp_diff_prev      : unsigned(47 downto 0) := (others => '0');
signal timestamp_fall           : unsigned(47 downto 0) := (others => '0');
signal timestamp_prev           : unsigned(47 downto 0) := (others => '0');
signal timestamp_rise           : unsigned(47 downto 0) := (others => '0');
signal timestamp_trig_prev      : unsigned(47 downto 0) := (others => '0');

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
delay_i <=  unsigned(DELAY) when (unsigned(DELAY) > 4 or unsigned(DELAY) = 0) else
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
            if (unsigned(STEP) >= unsigned(width_i)) then
                step_i <= unsigned(STEP);
            else
                step_i <= (2 => '1', others => '0');
            end if;
        elsif (full_ts_calculations = '1') then
            step_i <= timestamp - timestamp_trig_prev - 1;
        elsif (partial_ts_calculations = '1') then
            step_i <= unsigned(STEP);
        end if;
    end if;
end process;

process(clk_i)
begin
    if rising_edge(clk_i) then
        if ((width_i /= width_i_prev) or (step_i /= step_i_prev)) then
            if (width_i /= 0) then
                if ((signed(step_i) - signed(width_i)) > 4) then
                    gap_i <= step_i - width_i;
                else
                    gap_i <= (2 => '1', others => '0');
                end if;
            end if;
        elsif (full_ts_calculations = '1') then
            gap_i <= timestamp - (timestamp_trig_prev + timestamp_diff_prev) - 1;
        elsif (partial_ts_calculations = '1') then
            if ((signed(STEP) - signed(timestamp_diff_prev)) > 4) then
                gap_i <= unsigned(STEP) - timestamp_diff_prev;
            else
                gap_i <= (2 => '1', others => '0');
            end if;
        end if;
    end if;
end process;


-- Are we reading the queue?
queue_pulse_ts <= unsigned(pulse_queued_dout(47 downto 0));
queue_pulse_value <= pulse_queued_dout(48);


-- Ignore period error for the first pulse in the train and any fifo based anomolies.
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            fifo_error <= "100";
        else
            if (pulse_queued_wstb = '1') then
                fifo_error <= "100";
            elsif (fifo_error /= 0) then
                fifo_error <= fifo_error - 1;
            end if;
        end if;
    end if;
end process;

-- Assign the pulse value to the externally facing port
out_o <= pulse;


-- Other output assignments
DROPPED <= std_logic_vector(missed_pulses);
QUEUED <= ZEROS(32-pulse_queued_data_count'length) &  pulse_queued_data_count;

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
        elsif (enable_i = '1') then
            -- Bits that need resetting every clock cycle
            partial_ts_calculations <= '0';
            full_ts_calculations <= '0';
            pulse_queued_wstb <= '0';
            value <= '0';

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
                if (pulse_queued_full = '1' or fifo_error /= 0 or waiting_for_delay = '0' or edges_remaining /= 0) then
                    if(((TRIG_EDGE(1 downto 0) = c_trig_edge_pos) and (trig_rise = '1')) or
                       ((TRIG_EDGE(1 downto 0) = c_trig_edge_neg) and (trig_fall = '1')) or
                        (TRIG_EDGE(1 downto 0) = c_trig_edge_pos_neg)) then
                            missed_pulses <= missed_pulses + 1;
                    end if;
                -- Next, if we have a width (i.e. no timestamp maths required)
                elsif (width_i /= 0) then
                    if(((TRIG_EDGE(1 downto 0) = c_trig_edge_pos) and (trig_rise = '1')) or
                       ((TRIG_EDGE(1 downto 0) = c_trig_edge_neg) and (trig_fall = '1')) or
                        (TRIG_EDGE(1 downto 0) = c_trig_edge_pos_neg)) then
                            pulse_queued_wstb <= '1';
                            queued_din <= width_i;
                            pulse_queued_din <= '1' & std_logic_vector(width_i);

                            if (pulse_queued_empty = '1') then
                                if (delay_i = 0) then
                                    delay_remaining <= (1 downto 0 => '1', others => '0');
                                else
                                    delay_remaining <= delay_i - 1;
                                end if;
                            end if;
                    end if;

                -- Finally, if we can do some mathematics
                elsif ((width_i = 0) and (unsigned(STEP) = 0)) then
                    -- We can do what we did in the previous statement with a different assignment
                    if ((TRIG_EDGE(1 downto 0) = c_trig_edge_pos) and (trig_rise = '1') and (had_rising_trigger = '1')) then
                        pulse_queued_wstb <= '1';
                        timestamp_trig_prev <= timestamp_rise;
                        timestamp_diff_prev <= timestamp_fall - timestamp_rise;
                        queued_din <= timestamp_fall - timestamp_rise;
                        pulse_queued_din <= '1' & std_logic_vector(timestamp_fall - timestamp_rise);

                        full_ts_calculations <= '1';

                        if (pulse_queued_empty = '1') then
                            if (delay_i = 0) then
                                delay_remaining <= (1 downto 0 => '1', others => '0');
                            else
                                delay_remaining <= delay_i - 1;
                            end if;
                        end if;
                    end if;

                    if ((TRIG_EDGE(1 downto 0) = c_trig_edge_neg) and (trig_fall = '1') and (had_falling_trigger = '1')) then
                        pulse_queued_wstb <= '1';
                        timestamp_trig_prev <= timestamp_fall;
                        timestamp_diff_prev <= timestamp_rise - timestamp_fall;
                        queued_din <= timestamp_rise - timestamp_fall;
                        pulse_queued_din <= '1' & std_logic_vector(timestamp_rise - timestamp_fall);

                        full_ts_calculations <= '1';

                        if (pulse_queued_empty = '1') then
                            if (delay_i = 0) then
                                delay_remaining <= (1 downto 0 => '1', others => '0');
                            else
                                delay_remaining <= delay_i - 1;
                            end if;
                        end if;
                    end if;
                elsif ((width_i = 0) and (unsigned(STEP) /= 0)) then
                    -- We can do what we did in the previous statement with a different assignment
                    if ((TRIG_EDGE(1 downto 0) = c_trig_edge_pos) and (trig_fall = '1') and (had_rising_trigger = '1')) then
                        pulse_queued_wstb <= '1';
                        timestamp_diff_prev <= timestamp - timestamp_rise;
                        queued_din <= timestamp - timestamp_rise;
                        pulse_queued_din <= '1' & std_logic_vector(timestamp - timestamp_rise);

                        partial_ts_calculations <= '1';

                        if (pulse_queued_empty = '1') then
                            if (delay_i = 0) then
                                delay_remaining <= (1 downto 0 => '1', others => '0');
                            else
                                delay_remaining <= delay_i - 1;
                            end if;
                        end if;
                    end if;

                    if ((TRIG_EDGE(1 downto 0) = c_trig_edge_neg) and (trig_rise = '1') and (had_falling_trigger = '1')) then
                        pulse_queued_wstb <= '1';
                        timestamp_diff_prev <= timestamp - timestamp_fall;
                        queued_din <= timestamp - timestamp_fall;
                        pulse_queued_din <= '1' & std_logic_vector(timestamp - timestamp_fall);

                        partial_ts_calculations <= '1';

                        if (pulse_queued_empty = '1') then
                            if (delay_i = 0) then
                                delay_remaining <= (1 downto 0 => '1', others => '0');
                            else
                                delay_remaining <= delay_i - 1;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
            if (delay_remaining /= 0) then
                delay_remaining <= delay_remaining - 1;
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
                        edge_width <= queue_pulse_ts;
                        pulse_ts <= timestamp + queue_pulse_ts;
                        pulse <= queue_pulse_value;
                        edges_remaining <= unsigned(pulses_i) + unsigned(pulses_i) - 1;
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