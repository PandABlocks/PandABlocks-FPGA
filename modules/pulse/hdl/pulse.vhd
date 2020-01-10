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

-- Functions declarations used within this architecture

function edge_validation (rise_value : std_logic; 
                          fall_value : std_logic; 
                          edge_value : std_logic_vector(1 downto 0)
                         ) return boolean is
begin
    if(((edge_value = "00") and (rise_value = '1')) or
       ((edge_value = "01") and (fall_value = '1')) or
        (edge_value = "10")) then
        return true;
    else
        return false;
    end if;
end;


-- Variable declarations

-- Attached to architecture inputs

signal DELAY            : std_logic_vector(47 downto 0);
signal DELAY_wstb       : std_logic;
signal STEP             : std_logic_vector(47 downto 0);
signal STEP_wstb        : std_logic;
signal WIDTH            : std_logic_vector(47 downto 0);
signal WIDTH_wstb       : std_logic;


-- Standard logic signals

signal dropped_flag             : std_logic := '0';

signal enable_i_prev            : std_logic := '0';

signal pulse                    : std_logic := '0';
signal pulse_override           : std_logic := '0';
signal pulse_queued_empty       : std_logic := '0';
signal pulse_queued_full        : std_logic := '0';
signal pulse_queued_reset       : std_logic := '0';
signal pulse_queued_rstb        : std_logic := '0';
signal pulse_queued_wstb        : std_logic := '0';

signal queue_pulse_value        : std_logic := '0';

signal trig_fall                : std_logic := '0';
signal trig_rise                : std_logic := '0';
signal trig_same                : std_logic := '1';
signal trig_i_prev              : std_logic := '0';


-- Standard logic vector signals

signal pulse_queued_din         : std_logic_vector(48 downto 0);
signal pulse_queued_dout        : std_logic_vector(48 downto 0);
signal pulse_queued_data_count  : std_logic_vector(10 downto 0);


-- Unsigned integer signals

signal delay_i                  : unsigned(47 downto 0) := (others => '0');

signal edges_remaining          : unsigned(31 downto 0) := (others => '0');

signal gap_i                    : unsigned(47 downto 0) := (others => '0');

signal missed_pulses            : unsigned(31 downto 0) := (others => '0');

signal next_acceptable_pulse_ts : unsigned(47 downto 0) := (others => '0');

signal override_ends_ts         : unsigned(47 downto 0) := (others => '0');

signal pulses_i                 : unsigned(31 downto 0) := (others => '0');
signal pulse_gap                : unsigned(47 downto 0) := (others => '0');
signal pulse_ts                 : unsigned(47 downto 0) := (others => '0');

signal queued_din               : unsigned(47 downto 0) := (others => '0');
signal queue_pulse_ts           : unsigned(47 downto 0) := (others => '0');

signal step_i                   : unsigned(47 downto 0) := (others => '0');

signal timestamp                : unsigned(47 downto 0) := (others => '0');

signal width_i                  : unsigned(47 downto 0) := (others => '0');


-- Assignments complete, next up is the main functional code of the block
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
QUEUED <= ZEROS(32-pulse_queued_data_count'length) & pulse_queued_data_count;


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


-- Now we have the 48 bit value, we can convert these to unsigned integers performing some checking along the way

delay_i <=  (unsigned(DELAY)) when (unsigned(DELAY) > 5 or unsigned(DELAY) = 0) else to_unsigned(6, 48);

gap_i <=    step_i - width_i when ((signed(step_i) - signed(width_i)) > 1) else to_unsigned(1, 48);

pulses_i <= unsigned(PULSES) when (unsigned(PULSES) /= 0) else to_unsigned(1, 32);

step_i <=   unsigned(STEP) when (unsigned(STEP) > unsigned(WIDTH) or unsigned(STEP) = 0) else
            unsigned(STEP) + width_i + 1;

width_i <=  (unsigned(WIDTH)) when (unsigned(WIDTH) > 5 or unsigned(WIDTH) = 0) else to_unsigned(6, 48);
          

-- Free running global timestamp counter
process(clk_i)
begin
    if (rising_edge(clk_i)) then
        if (enable_i = '1') then
            if (enable_i_prev = '0') then
                timestamp <= (others => '0');
            else
                timestamp <= timestamp + 1;
            end if;            
        end if;
    end if;
end process;


-- Free running edge watcher
process(clk_i)
begin
    if (rising_edge(clk_i)) then
        trig_i_prev <= trig_i;
        enable_i_prev <= enable_i;

        if (enable_i = '1') then
            if (enable_i_prev = '0') then
                dropped_flag <= '0';
                pulse_override <= '0';
                next_acceptable_pulse_ts <= (others => '0');
            else
                dropped_flag <= '0';
                trig_fall <= '0';
                trig_rise <= '0';
                trig_same <= '0';

                -- Detect the current edge state, if differrent and not in timing violation
                if (trig_i = trig_i_prev) then
                    trig_same <= '1';
                else
                    if (timestamp < next_acceptable_pulse_ts) then
                        dropped_flag <= '1';
                        trig_same <= '1';

                    elsif ((trig_i = '0') and (trig_i /= trig_i_prev)) then
                        trig_fall <= '1';

                        if ((delay_i = 0) and edge_validation('0', '1', TRIG_EDGE(1 downto 0))) then
                            pulse_override <= '1';
                            override_ends_ts <= width_i;
                        end if;

                        if (pulses_i = 1) then
                            next_acceptable_pulse_ts <= timestamp + width_i;
                        else
                            next_acceptable_pulse_ts <= timestamp + (step_i * pulses_i) - gap_i;
                        end if;

                    elsif ((trig_i = '1') and (trig_i /= trig_i_prev)) then
                        trig_rise <= '1';

                        if ((delay_i = 0) and edge_validation('1', '0', TRIG_EDGE(1 downto 0))) then
                            pulse_override <= '1';
                            override_ends_ts <= width_i;
                        end if;

                        if (pulses_i = 1) then
                            next_acceptable_pulse_ts <= timestamp + width_i;
                        else
                            next_acceptable_pulse_ts <= timestamp + (step_i * pulses_i) - gap_i;
                        end if;
                    end if;
                end if;

                if (timestamp = override_ends_ts) then
                    pulse_override <= '0';
                end if;
            end if;
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
                missed_pulses <= (others => '0');
                
                pulse_queued_din <= (others => '0');
                pulse_queued_reset <= '1';
                pulse_queued_wstb <= '0';
                
            else
                -- Bits that need resetting every clock cycle
                pulse_queued_reset <= '0';
                pulse_queued_wstb <= '0';

                if (dropped_flag = '1') then
                    missed_pulses <= missed_pulses + 1;
                end if;

                -- If check to make sure that we should be storing this event at all
                if (trig_same /= '1') then
                    -- First up, event rejection criteria:
                    if (pulse_queued_full = '1') then
                        missed_pulses <= missed_pulses + 1;

                    -- If we have no width we're acting as a fancy delay line
                    elsif (width_i = 0) then
                        if (trig_rise = '1') then
                            pulse_queued_din <= '1' & std_logic_vector(timestamp + delay_i - 1);
                        elsif (trig_fall = '1') then
                            pulse_queued_din <= '0' & std_logic_vector(timestamp + delay_i - 1);
                        end if;

                        pulse_queued_wstb <= '1';

                    -- Next, if we have a width we'll pass the timestamp that we got the trigger
                    elsif (width_i /= 0) then
                        if (edge_validation(trig_rise, trig_fall, TRIG_EDGE(1 downto 0))) then
                                pulse_queued_din <= '1' & std_logic_vector(timestamp + delay_i - 1);
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
                edges_remaining <= (others => '0');
                
                pulse <= '0';
                pulse_queued_rstb <= '0';
                pulse_ts <= (others => '0');
            else
                pulse_queued_rstb <= '0';

                --- If we're running as a fancy delay line
                if (width_i = 0) then
                    if (timestamp = queue_pulse_ts) then
                        pulse <= queue_pulse_value;
                        pulse_queued_rstb <= '1';
                    end if;

                --- Otherwise let's process some pulses
                else
                    if (pulses_i = 1) then
                        if ((delay_i /= 0) and (timestamp = queue_pulse_ts)) then
                            pulse <= '1';
                            pulse_queued_rstb <= '1';
                            pulse_ts <= timestamp + width_i;

                        elsif (timestamp = pulse_ts) then
                            pulse <= '0';
                        end if;
                    else
                        if (edges_remaining /= 0) then
                            if (timestamp = pulse_ts) then
                                if (unsigned(edges_remaining mod 2) = 0) then
                                    edges_remaining <= edges_remaining - 1;
                                    pulse_ts <= timestamp + width_i;
                                    pulse <= not pulse;

                                else
                                    edges_remaining <= edges_remaining - 1;
                                    pulse_ts <= timestamp + gap_i;
                                    pulse <= not pulse;
                                end if;
                            end if;

                            if (edges_remaining = 1) then
                                pulse_queued_rstb <= '1';
                            end if;

                        else
                            if ((delay_i /= 0) and (timestamp = queue_pulse_ts)) then
                                pulse <= '1';
                                pulse_ts <= timestamp + width_i;
                                edges_remaining <= (pulses_i * 2) - 1;
                            elsif ((delay_i = 0) and (timestamp = queue_pulse_ts)) then
                                pulse_ts <= timestamp + step_i;
                                edges_remaining <= (pulses_i - 1) * 2;
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

out_o <= pulse_override or pulse;

end rtl;