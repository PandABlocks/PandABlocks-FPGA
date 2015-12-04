--------------------------------------------------------------------------------
--  File:       panda_pulse.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity panda_pulse is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    inp_i               : in  std_logic;
    rst_i               : in  std_logic;
    out_o               : out std_logic;
    perr_o              : out std_logic;
    -- Block Parameters
    DELAY               : in  std_logic_vector(47 downto 0);
    WIDTH               : in  std_logic_vector(47 downto 0);
    FORCE_RST           : in  std_logic;
    -- Block Status
    ERR_OVERFLOW        : out std_logic;
    ERR_PERIOD          : out std_logic;
    QUEUE               : out std_logic_vector(10 downto 0);
    MISSED_CNT          : out std_logic_vector(31 downto 0)
);
end panda_pulse;

architecture rtl of panda_pulse is

component pulse_queue
port (
    clk                 : in std_logic;
    rst                 : in std_logic;
    din                 : in std_logic_vector(48 DOWNTO 0);
    wr_en               : in std_logic;
    rd_en               : in std_logic;
    dout                : out std_logic_vector(48 DOWNTO 0);
    full                : out std_logic;
    empty               : out std_logic;
    data_count          : out std_logic_vector(10 downto 0)
);
end component;

type pulse_fsm_t is (FSM_IDLE, FSM_LATCH_TS, FSM_DELAY, FSM_WIDTH);
signal pulse_fsm                : pulse_fsm_t;

signal pulse_queue_wstb         : std_logic;
signal pulse_queue_rstb         : std_logic;
signal pulse_queue_full         : std_logic;
signal pulse_queue_empty        : std_logic;
signal pulse_queue_din          : std_logic_vector(48 downto 0);
signal pulse_queue_dout         : std_logic_vector(48 downto 0);
signal pulse_queue_data_count   : std_logic_vector(10 downto 0);

signal inp_rise                 : std_logic;
signal inp_fall                 : std_logic;
signal ongoing_pulse            : std_logic := '0';

signal reset                    : std_logic;
signal pulse                    : std_logic := '0';

signal DELAY_prev               : std_logic_vector(47 downto 0);
signal WIDTH_prev               : std_logic_vector(47 downto 0);

signal config_reset             : std_logic;
signal inp_prev                 : std_logic;
signal inp_rise_prev            : std_logic;

signal timestamp                : unsigned(47 downto 0);
signal timestamp_prev           : unsigned(47 downto 0);
signal pulse_ts                 : unsigned(47 downto 0);

signal delta_T                  : unsigned(47 downto 0);
signal missed_pulses            : unsigned(15 downto 0);

signal is_first_pulse           : std_logic := '1';
signal period_error             : std_logic := '0';
signal value                    : std_logic := '0';

signal is_DELAY_zero            : std_logic := '0';
signal queue_din                : unsigned(47 downto 0);
signal pulse_value              : std_logic;

begin

-- Input registering
process(clk_i)
begin
    if rising_edge(clk_i) then
        inp_prev <= inp_i;
        DELAY_prev <= DELAY;
        WIDTH_prev <= WIDTH;
    end if;
end process;

-- Hard/Soft/Config Reset combined
config_reset <= '1' when (DELAY /= DELAY_prev or WIDTH /= WIDTH_prev)
                    else '0';
reset <= rst_i or FORCE_RST or config_reset;

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

-- Capture timestamp of incoming pulse, and add DELAY offset before
-- storing in the queue.
--
-- DELAY=0 is special case, doesn't go through queue since
-- pulse train can not be supported in this mode.

-- Pulse Queue keeps track of timestamps of incoming pulses.
pulse_queue_inst : pulse_queue
port map (
    clk         => clk_i,
    rst         => reset,
    din         => pulse_queue_din,
    wr_en       => pulse_queue_wstb,
    rd_en       => pulse_queue_rstb,
    dout        => pulse_queue_dout,
    full        => pulse_queue_full,
    empty       => pulse_queue_empty,
    data_count  => pulse_queue_data_count
);

pulse_queue_din <= value & std_logic_vector(queue_din);
pulse_value <= pulse_queue_dout(48);
pulse_ts <= unsigned(pulse_queue_dout(47 downto 0));

--
-- Main state machine
--

-- Keep track of current period of incoming pulse train
-- In pulse train mode, it must be " T > WIDTH + 3", otherwise
-- incoming pulse is ignored.
delta_T <= timestamp - timestamp_prev;

is_DELAY_zero <= '1' when (unsigned(DELAY) = 0) else '0';

period_error <= '1' when (delta_T < (unsigned(WIDTH) + 4))
                    else '0';

-- Detect rising edge input pulse for time stamp registering.
inp_rise  <= inp_i and not inp_prev;
inp_fall  <= not inp_i and inp_prev;

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            ongoing_pulse <= '0';
            pulse_queue_wstb <= '0';
            inp_rise_prev <= '0';
            ERR_OVERFLOW <= '0';
            ERR_PERIOD <= '0';
            missed_pulses <= (others => '0');
            timestamp_prev <= (others => '0');
            queue_din <= (others => '0');
            is_first_pulse <= '1';
            perr_o <= '0';
        else
            pulse_queue_wstb <= '0';
            inp_rise_prev <= inp_rise;
            value <= '0';

            -- Flag ongoing pulse capture to be used for timestamp capturing
            if (inp_rise = '1' and pulse_queue_full = '0') then
                ongoing_pulse <= '1';
            elsif (inp_fall = '1') then
                ongoing_pulse <= '0';
            end if;

            --
            -- Timestamp information for both rising and falling-edge of the
            -- incoming pulse is stored in the queue along with pulse value.
            --

            -- Queue full confition flags an error, and ticks missing pulse counter.
            if (inp_rise = '1' and pulse_queue_full = '1') then
                ERR_OVERFLOW <= '1';
                missed_pulses <= missed_pulses + 1;
                perr_o <= '1';
            -- Pulse period must obey Xilinx FIFO IP latency following first the
            -- pulse.
            elsif (inp_rise = '1' and period_error = '1' and is_first_pulse = '0') then
                ERR_PERIOD <= '1';
                missed_pulses <= missed_pulses + 1;
                perr_o <= '1';
            -- Capture timestamp for rising edge of the ongoing pulse, and add
            -- DELAY before writing into the queue.
            elsif (inp_rise = '1' and ongoing_pulse = '0') then
                timestamp_prev <= timestamp;
                is_first_pulse <= '0';
                pulse_queue_wstb <= not is_DELAY_zero;
                queue_din <= timestamp + unsigned(DELAY) + 1;
                value <= '1';
            -- Capturing falling edge is split into two conditions.
            -- 1./ When WIDTH is not 0, capture timestamp, and add WIDTH before 
            -- writing immediately into the queue.
            elsif (inp_rise_prev = '1' and ongoing_pulse = '1' and unsigned(WIDTH) /= 0) then
                pulse_queue_wstb <= not is_DELAY_zero;
                queue_din <= queue_din + unsigned(WIDTH);
            -- 2./ When WIDTH=0, we need pass incoming pulse with DELAY. So, we
            -- need to wait until actual falling edge of the pulse for capturing
            -- timestamp.
            elsif (inp_fall = '1' and ongoing_pulse = '1' and unsigned(WIDTH) = 0) then
                pulse_queue_wstb <= not is_DELAY_zero;
                queue_din <= timestamp + unsigned(DELAY) + 1;
            end if;
        end if;
    end if;
end process;

--
-- Process pulse output.
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            pulse <= '0';
        else
            pulse_queue_rstb <= '0';
            -- Both Delay and Width are set to 0, pass-through input pulse.
            if (unsigned(DELAY) = 0 and unsigned(WIDTH) = 0) then
                pulse <= inp_i;
            -- Delay set to 0 case bypasses the pulse queue.
            elsif (unsigned(DELAY) = 0 and unsigned(WIDTH) /= 0) then
                if (inp_rise = '1') then
                    pulse <= '1';
                elsif (pulse = '1' and timestamp = timestamp_prev + unsigned(WIDTH)) then
                    pulse <= '0';
                end if;
            -- Delay /= 0, pulses go through pulse queue.
            else
                if (pulse_queue_empty = '0' and timestamp = unsigned(pulse_ts) - 1) then
                    pulse <= pulse_value;
                    pulse_queue_rstb <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

out_o <= pulse;

-- Output assignments.
MISSED_CNT <= X"0000" & std_logic_vector(missed_pulses);
QUEUE <= pulse_queue_data_count;

end rtl;
