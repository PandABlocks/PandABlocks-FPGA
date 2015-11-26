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
    STATE               : out std_logic_vector(31 downto 0);
    MISSED_CNT          : out std_logic_vector(31 downto 0)
);
end panda_pulse;

architecture rtl of panda_pulse is

component pulse_queue
port (
    clk                 : in std_logic;
    rst                 : in std_logic;
    din                 : in std_logic_vector(47 DOWNTO 0);
    wr_en               : in std_logic;
    rd_en               : in std_logic;
    dout                : out std_logic_vector(47 DOWNTO 0);
    full                : out std_logic;
    empty               : out std_logic;
    data_count          : out std_logic_vector(9 downto 0)
);
end component;

type pulse_fsm_t is (FSM_IDLE, FSM_LATCH_TS, FSM_DELAY, FSM_WIDTH);
signal pulse_fsm                : pulse_fsm_t;

signal reset                    : std_logic;
signal inp_prev                 : std_logic;
signal inp_rise                 : std_logic;

signal timestamp                : unsigned(47 downto 0);
signal timestamp_prev           : unsigned(47 downto 0);
signal pulse_ts                 : unsigned(47 downto 0);

signal pulse_queue_wstb         : std_logic;
signal pulse_queue_rstb         : std_logic;
signal pulse_queue_full         : std_logic;
signal pulse_queue_empty        : std_logic;
signal pulse_queue_din          : unsigned(47 downto 0);
signal pulse_queue_dout         : std_logic_vector(47 downto 0);
signal pulse_queue_data_count   : std_logic_vector(9 downto 0);

signal delta_T                  : unsigned(47 downto 0);
signal missed_pulses            : unsigned(15 downto 0);

begin

-- Hard or Soft Reset combined
reset <= rst_i or FORCE_RST;

MISSED_CNT <= X"0000" & std_logic_vector(missed_pulses);

-- Detect rising edge input pulse for time stamp registering.
process(clk_i)
begin
    if rising_edge(clk_i) then
        inp_prev <= inp_i;
    end if;
end process;

inp_rise  <= inp_i and not inp_prev;

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

-- Keep track of current period of incoming pulse train
-- In pulse train mode, it must be " T > WIDTH + 3", otherwise
-- incoming pulse is ignored.
delta_T <= timestamp - timestamp_prev;

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            timestamp_prev <= (others => '0');
            missed_pulses <= (others => '0');
            perr_o <= '0';
            STATE <= (others => '0');
        else
            STATE(25 downto 16) <= pulse_queue_data_count;
            -- Input rising edge detected.
            if (inp_rise = '1') then
                -- Check whether queue is available;
                if (pulse_queue_full = '1') then
                    missed_pulses <= missed_pulses + 1;
                    perr_o <= '1';
                    STATE(0) <= '1';
                -- Check if pulse period matches WIDTH;
                elsif (delta_T > (unsigned(WIDTH) + 3)) then
                    timestamp_prev <= timestamp;
                -- Pulse period error.
                else
                    missed_pulses <= missed_pulses + 1;
                    perr_o <= '1';
                    STATE(1) <= '1';
                end if;
            end if;
        end if;
    end if;
end process;


-- Capture timestamp of incoming pulse, and add DELAY offset before
-- storing in the queue.
--
-- DELAY=0 is special case, doesn't go through queue since
-- pulse train can not be supported in this mode.
pulse_queue_wstb <= '0' when (unsigned(DELAY) = 0)
                    else (inp_rise and not pulse_queue_full)
                        when (delta_T > (unsigned(WIDTH) + 3))
                            else '0';
pulse_queue_din <= timestamp + unsigned(DELAY);

-- Pulse Queue keeps track of timestamps of incoming pulses.
pulse_queue_inst : pulse_queue
port map (
    clk         => clk_i,
    rst         => reset,
    din         => std_logic_vector(pulse_queue_din),
    wr_en       => pulse_queue_wstb,
    rd_en       => pulse_queue_rstb,
    dout        => pulse_queue_dout,
    full        => pulse_queue_full,
    empty       => pulse_queue_empty,
    data_count  => pulse_queue_data_count
);

--
-- Main state machine
--

-- Generate read strobe from queue when there is pulse to produce.
pulse_queue_rstb <= '1' when (pulse_fsm = FSM_IDLE and pulse_queue_empty = '0')
                    else '0';

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            pulse_fsm <= FSM_IDLE;
        else
            case pulse_fsm is
                -- Wait for pulse to be available in the queue.
                -- Data in the queue is the start time of output Pulse.
                -- DELAY=0 pulses do not go through the queue, and
                -- processed immediately.
                when FSM_IDLE =>
                    out_o <= '0';
                    if (inp_rise = '1' and unsigned(DELAY) = 0) then
                        pulse_ts <= timestamp;
                        pulse_fsm <= FSM_WIDTH;
                        out_o <= '1';
                    elsif (pulse_queue_empty = '0') then
                        pulse_fsm <= FSM_LATCH_TS;
                    end if;

                -- Latch queue output for start of Pulse.
                when FSM_LATCH_TS =>
                    pulse_ts <= unsigned(pulse_queue_dout)-1;
                    pulse_fsm <= FSM_DELAY;

                -- Wait until timestamp reaches for start time.
                when FSM_DELAY =>
                    if (timestamp = pulse_ts) then
                        pulse_fsm <= FSM_WIDTH;
                        out_o <= '1';
                    end if;

                -- Wait for WIDTH to complete.
                when FSM_WIDTH =>
                    if (timestamp = pulse_ts + unsigned(WIDTH)) then
                        out_o <= '0';
                        pulse_fsm <= FSM_IDLE;
                    end if;

                when others =>
                    pulse_fsm <= FSM_IDLE;
                    out_o <= '0';
            end case;
        end if;
    end if;
end process;

end rtl;
