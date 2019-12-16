--------------------------------------------------------------------------------
--  File:       pulse.vhd
--  Desc:       Programmable Pulse Generator.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

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
    DELAY               : in  std_logic_vector(47 downto 0);
    DELAY_WSTB          : in  std_logic;
    WIDTH               : in  std_logic_vector(47 downto 0);
    WIDTH_WSTB          : in  std_logic;
    -- Block Status
    QUEUED              : out std_logic_vector(31 downto 0);
    DROPPED             : out std_logic_vector(31 downto 0)
);
end pulse;

architecture rtl of pulse is

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
    data_count          : out std_logic_vector(8 downto 0)
);
end component;


constant c_trig_edge_pos        : std_logic_vector(1 downto 0) := "00";
constant c_trig_edge_neg        : std_logic_vector(1 downto 0) := "01";
constant c_trig_edge_pos_neg    : std_logic_vector(1 downto 0) := "10";

constant c_sec_pulse            : unsigned(2 downto 0) := "100";

constant c_delay_one            : unsigned(1 downto 0) := "01";
constant c_delay_zero           : unsigned(1 downto 0) := "00";

signal pulse_queued_wstb        : std_logic;
signal pulse_queued_rstb        : std_logic;
signal pulse_queued_full        : std_logic;
signal pulse_queued_empty       : std_logic;
signal pulse_queued_din         : std_logic_vector(48 downto 0);
signal pulse_queued_dout        : std_logic_vector(48 downto 0);
signal pulse_queued_data_count  : std_logic_vector(8 downto 0);

signal trig_rise                : std_logic;
signal trig_fall                : std_logic;
signal ongoing_pulse            : std_logic;

signal enable                   : std_logic;
signal enable_rise              : std_logic;

signal reset                    : std_logic;
signal reset_err                : std_logic;
signal pulse                    : std_logic;

signal delay_i                  : std_logic_vector(47 downto 0);
signal width_i                  : std_logic_vector(47 downto 0);
signal DELAY_prev               : std_logic_vector(47 downto 0);
signal WIDTH_prev               : std_logic_vector(47 downto 0);

----signal config_reset             : std_logic;
signal trig_prev                 : std_logic;
signal trig_rise_prev            : std_logic;

signal timestamp                : unsigned(47 downto 0);
signal timestamp_prev           : unsigned(47 downto 0);
signal pulse_ts                 : unsigned(47 downto 0);

signal delta_T                  : unsigned(47 downto 0);
signal missed_pulses            : unsigned(31 downto 0);

signal is_first_pulse           : std_logic := '1';
signal period_error             : std_logic := '0';
signal period_error_prev        : std_logic := '0';
signal value                    : std_logic := '0';

signal is_DELAY_zero            : std_logic := '0';
signal queued_din               : unsigned(47 downto 0);
signal pulse_value              : std_logic;

signal enable_i_dly             : std_logic;
signal wait_cnt                 : unsigned(2 downto 0);

signal neg_pulse                : std_logic;
signal trig_i_neg                : std_logic;
signal trig_i_int                : std_logic;
signal enable_cnt               : std_logic;
signal bypass_en                : std_logic;
signal DELAY_NEG                : unsigned(1 downto 0);

signal pos_neg_act_err          : std_logic;


begin


-- DELAY        WDITH       Condtion        Action      trig to start of positive pulse   trig to start of negative pulse
--  0            0          Not Valid       Bypass              2 clocks                        3 clocks
--  0           Set         Valid                               2 clocks                        3 clocks
--  Set         0           Not Valid       Bypass              DELAY                           DELAY
--  Set         Set         Valid                               DELAY                           DELAY

-- If DELAY and WIDTH are set too low, the FIFO does not have time to process the data and queue it

-- If 0 < DELAY < 4, it should be set to 4
delay_i <= DELAY when (unsigned(DELAY) > 4 or unsigned(DELAY) = 0) else (2 => '1',
                                                                                                                                 others => '0');
-- If Delay is zero and WIDTH is between 0 and 4 WIDTH should be 4
width_i <= WIDTH when (not(unsigned(DELAY) = 0 and (unsigned(WIDTH) < 4 and unsigned(WIDTH) > 0))) else (2 => '1',
                                                                                                                                                                                                        others => '0');



-- Added enable_rise signal
process(clk_i) begin
    if rising_edge(clk_i) then
        enable <= enable_i;
    end if;
end process;

enable_rise <= enable_i and not enable;

process(clk_i)
begin
    if rising_edge(clk_i) then
       if reset = '1' then
            wait_cnt <= (others => '0');
       else
            -- Indicate when a negative edge pulse is to happen
            if (unsigned(width_i) /= 0 and (TRIG_EDGE(1 downto 0) = c_trig_edge_neg or TRIG_EDGE(1 downto 0) = c_trig_edge_pos_neg)) then
                neg_pulse <= trig_i;
            end if;

            -- Negative edge pulse
            if (neg_pulse = '1' and trig_i = '0' and unsigned(WIDTH) /= 0 and
                    (TRIG_EDGE(1 downto 0) = c_trig_edge_neg or TRIG_EDGE(1 downto 0) = c_trig_edge_pos_neg)) then
                trig_i_neg <= '1';
                enable_cnt <= '1';
                DELAY_NEG <= c_delay_zero;
            -- Pulse has to be move than 4 clocks long
            elsif enable_cnt = '1' and wait_cnt /= c_sec_pulse then
                trig_i_neg <= '1';
                wait_cnt <= wait_cnt + 1;
            -- Turn pulse off
            elsif wait_cnt = c_sec_pulse then
                wait_cnt <= (others => '0');
                enable_cnt <= '0';
            else
                wait_cnt <= (others => '0');
                trig_i_neg <= '0';
                DELAY_NEG <= c_delay_one;
            end if;

       end if;
    end if;
end process;

process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Indicate bypass mode for TRIG_EDGE = negative and WIDTH = 0 or pass the pulse in if its a positive or both positive and negative pulse
        if (unsigned(width_i) = 0 or (unsigned(width_i) /= 0 and (TRIG_EDGE(1 downto 0) = c_trig_edge_pos or TRIG_EDGE(1 downto 0) = c_trig_edge_pos_neg))) then
            bypass_en <= '1';
        else
            bypass_en <= '0';
        end if;
    end if;
end process;


-- Error if both trig_i and trig_i_neg active at the same time
trig_i_int <= (trig_i and bypass_en) or trig_i_neg;

pos_neg_act_err <= ((trig_i and bypass_en) and trig_i_neg);


-- Input registering
process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_i_dly <= enable_i;
        trig_prev <= trig_i_int;
        DELAY_prev <= delay_i;
        WIDTH_prev <= width_i;
    end if;
end process;

-- Initial/Bitbus/Config Reset combined
-- Changed reset to occur on enable rise
reset <= DELAY_WSTB or WIDTH_WSTB or enable_rise;

reset_err <= not enable_i_dly and enable_i;

-- Free running global timestamp counter, it will be the time resolution
-- for pulse generation.
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

-- Timestamps for rising and falling edges of the incloming pulses are
-- detected and DELAY offset (for asserting outp), and WIDTH (for de-asserting
-- outp) added to the timestamps and written into the Pulse Queued.
--
-- DELAY=0 is special case, only timestamp for falling edge of outp is written
-- into the queue.
--

-- Pulse Queued keeps track of timestamps of incoming pulses.
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

-- Queue data is composed of:
-- timestamp & outp_value @ the timestamp
pulse_queued_din <= value & std_logic_vector(queued_din);

-- Queue output is decomposed into timestamp & outp_value @ the timestamp
pulse_value <= pulse_queued_dout(48);
pulse_ts <= unsigned(pulse_queued_dout(47 downto 0));

--
-- Main state machine
--

-- Keep track of current period of incoming pulse train
-- In pulse train mode, it must be " T > WIDTH + 4", otherwise
-- incoming pulse is ignored.
delta_T <= timestamp - timestamp_prev;

-- Ignore period error for the first pulse in the train.
period_error <= not is_first_pulse when (delta_T < unsigned(width_i)+4) else '0';

-- DELAY=0 is a special case where outp is immediately asserted while
-- falling edge timestamp is written into the queue.
is_DELAY_zero <= '1' when (unsigned(delay_i) = 0) else '0';


-- Detect rising edge input pulse for time stamp registering.
trig_rise  <= trig_i_int and not trig_prev;
trig_fall  <= not trig_i_int and trig_prev;

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            ongoing_pulse <= '0';
            pulse_queued_wstb <= '0';
            trig_rise_prev <= '0';
            missed_pulses <= (others => '0');
            timestamp_prev <= (others => '0');
            queued_din <= (others => '0');
            is_first_pulse <= '1';
            period_error_prev <= '0';
        else
            period_error_prev <= period_error;
            pulse_queued_wstb <= '0';
            trig_rise_prev <= trig_rise;
            value <= '0';

            -- Ongoing pulse flag is used for timestamp capturing.
            if (trig_rise = '1' and pulse_queued_full = '0') then
                ongoing_pulse <= '1';
            elsif (trig_fall = '1') then
                ongoing_pulse <= '0';
            end if;

            --
            -- Timestamp information for both rising and falling-edge of the
            -- incoming pulse is stored in the queue along with pulse value.
            -- (DELAY=0 is special again).

            -- Queue full condition flags an error, and ticks missing pulse
            -- counter.
            if (trig_rise = '1' and pulse_queued_full = '1') then
                missed_pulses <= missed_pulses + 1;
            -- Pulse period must obey Xilinx FIFO IP latency following the first
            -- pulse.
            elsif (trig_rise = '1' and period_error = '1') then
                missed_pulses <= missed_pulses + 1;
            end if;

            -- Capture timestamp for rising edge of the ongoing pulse, and add
            -- DELAY before writing into the queue.
            -- Ignore if DELAY is set to 0, timestamp for falling edge is
            -- inserted since outp start can not afford queue latency.
            if (trig_rise = '1' and period_error = '0') then
                timestamp_prev <= timestamp;
                is_first_pulse <= '0';
                -- If WIDTH and DELAY are zero the queue is bypassed
                if (unsigned(width_i) /= 0 or unsigned(delay) /= 0) then
                    pulse_queued_wstb <= '1';
                end if;
                if (is_DELAY_zero = '1') then
                    queued_din <= timestamp + unsigned(width_i) + 1;
                else
                    queued_din <= timestamp + unsigned(delay_i) + DELAY_NEG;
                end if;
                value <= not is_DELAY_zero;
            -- Capturing falling edge is split into two conditions.
            -- 1./ When WIDTH is not 0, capture timestamp, add WIDTH and
            -- write immediately into the queue.
            elsif (trig_rise_prev = '1' and period_error_prev = '0' and unsigned(width_i) /= 0) then
                pulse_queued_wstb <= not is_DELAY_zero;
                queued_din <= queued_din + unsigned(width_i);
            -- 2./ When WIDTH=0, we need maintain incoming pulse witdth and
            -- apply DELAY.
            -- So, wait until actual falling edge of the pulse for capturing
            -- the timestamp.
            elsif (trig_fall = '1' and ongoing_pulse = '1' and unsigned(width_i) = 0) then
                pulse_queued_wstb <= not is_DELAY_zero;
                queued_din <= timestamp + unsigned(delay_i) + 1;
            end if;
        end if;
    end if;
end process;

--
-- Process pulse output.
--
pulse_queued_rstb <= '1' when (pulse_queued_empty = '0' and timestamp = unsigned(pulse_ts) - 1) else '0';

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            pulse <= '0';
        else
            -- Both Delay and Width are set to 0, pass-through input pulse.
            if (unsigned(delay_i) = 0 and unsigned(width_i) = 0) then
                pulse <= trig_i_int;
            -- Delay set to 0: assert pulse immediately
            elsif (unsigned(delay_i) = 0 and unsigned(width_i) /= 0
                and trig_rise = '1' and period_error = '0') then
                pulse <= '1';
            -- Consume pulse queue to assert and de-assert outp pulse.
            else
                if (pulse_queued_empty = '0' and
                        timestamp = unsigned(pulse_ts) - 1) then
                    pulse <= pulse_value;
                end if;
            end if;
        end if;
    end if;
end process;

out_o <= pulse;

-- Output assignments.
DROPPED <= std_logic_vector(missed_pulses);
QUEUED <= ZEROS(32-pulse_queued_data_count'length) &  pulse_queued_data_count;

end rtl;
