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
    data_count          : out std_logic_vector(8 downto 0)
);
end component;

-- Function and proceedure declarations used within this architecture

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


-- Standard logic vector signals

signal pulse_queued_din         : std_logic_vector(48 downto 0);
signal pulse_queued_dout        : std_logic_vector(48 downto 0);
signal pulse_queued_data_count  : std_logic_vector(8 downto 0);


-- Unsigned integer signals

signal delay_i                  : unsigned(47 downto 0) := (others => '0');

signal gap_i                    : unsigned(47 downto 0) := (others => '0');

signal missed_pulses            : unsigned(31 downto 0) := (others => '0');

signal pulses_i                 : unsigned(31 downto 0) := (others => '0');

signal queued_din               : unsigned(47 downto 0) := (others => '0');
signal queue_pulse_ts           : unsigned(47 downto 0) := (others => '0');

signal step_i                   : unsigned(47 downto 0) := (others => '0');
signal min_input_spacing        : unsigned(47 downto 0) := (others => '0');
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


-- Input vector logic

process(clk_i)

variable delay_vector  : std_logic_vector(47 downto 0);
variable step_vector   : std_logic_vector(47 downto 0);
variable width_vector  : std_logic_vector(47 downto 0);

variable step_integer  : unsigned(47 downto 0) := (others => '0');
variable width_integer : unsigned(47 downto 0) := (others => '0');

begin
    if (rising_edge(clk_i)) then
        -- Second clock tick, calc the minimum distance between rising edges
        min_input_spacing <= resize(step_i * pulses_i, 48) - gap_i;

        -- Take 48-bit time as combination of two for:
        delay_vector(31 downto 0) := DELAY_L;
        delay_vector(47 downto 32) := DELAY_H(15 downto 0);

        step_vector(31 downto 0) := STEP_L;
        step_vector(47 downto 32) := STEP_H(15 downto 0);

        width_vector(31 downto 0) := WIDTH_L;
        width_vector(47 downto 32) := WIDTH_H(15 downto 0);

        if  (unsigned(PULSES) /= 0) then
            pulses_i <= unsigned(PULSES);
        else
            pulses_i <= to_unsigned(1, 32);
        end if;

        if ((unsigned(width_vector) > 5) or (unsigned(width_vector) = 0)) then
            width_integer := unsigned(width_vector);
        else
            width_integer := to_unsigned(6, 48);
        end if;

        if (((unsigned(delay_vector) > 5) or ((width_integer /=0) and (unsigned(delay_vector) = 0)))
           ) then
            delay_i <= unsigned(delay_vector);
        else
            delay_i <= to_unsigned(6, 48);
        end if;

        if ((unsigned(step_vector) > unsigned(width_vector)) or (unsigned(step_vector) = 0)) then
            step_integer := unsigned(step_vector);
        else
            step_integer := width_integer + 1;
        end if;

        if ((signed(step_integer) - signed(width_integer)) > 1) then
            gap_i <= step_integer - width_integer;
        else
            gap_i <= to_unsigned(1, 48);
        end if;

        step_i <= step_integer;
        width_i <= width_integer;
    end if;
end process;


-- Free running global timestamp counter
process(clk_i)
begin
    if (rising_edge(clk_i)) then
        if (enable_i = '0') then
            timestamp <= (others => '0');
        elsif (enable_i = '1') then
            timestamp <= timestamp + 1;
        end if;
    end if;
end process;


-- Free running edge watcher
process(clk_i)

variable trig_i_prev              : std_logic := '0';
variable next_acceptable_pulse_ts : unsigned(47 downto 0) := (others => '0');
variable override_ends_ts         : unsigned(47 downto 0) := (others => '0');

variable fall_trig                : std_logic :='0';
variable rise_trig                : std_logic :='0';
variable same_trig                : std_logic :='1';

begin
    if (rising_edge(clk_i)) then
        if (enable_i = '1') then
            if (enable_i_prev = '0') then
                dropped_flag <= '0';
                pulse_override <= '0';
                next_acceptable_pulse_ts := (others => '0');
                override_ends_ts := (others => '0');
            end if;

            dropped_flag <= '0';
            fall_trig := '0';
            rise_trig := '0';
            same_trig := '0';

            -- Detect the current edge state, if differrent
            if ((trig_i = '0') and (trig_i /= trig_i_prev)) then
                fall_trig := '1';

            elsif ((trig_i = '1') and (trig_i /= trig_i_prev)) then
                rise_trig := '1';
            
            elsif (trig_i = trig_i_prev) then
                same_trig := '1';
            end if;
            
            if (same_trig /= '1') then
                if (edge_validation(rise_trig, fall_trig, TRIG_EDGE(1 downto 0))) then
                    if (timestamp < next_acceptable_pulse_ts) then
                        dropped_flag <= '1';
                    else
                        if (delay_i = 0) then
                            pulse_override <= '1';
                            override_ends_ts := timestamp + width_i;
                        end if;
                        next_acceptable_pulse_ts := timestamp + min_input_spacing;
                    end if;
                end if;
            end if;

            if (timestamp = override_ends_ts) then
                pulse_override <= '0';
            end if;
        end if;

        trig_i_prev := trig_i;
        enable_i_prev <= enable_i;

        trig_fall <= fall_trig;
        trig_rise <= rise_trig;
        trig_same <= same_trig;
    end if;
end process;


-- Filling the queue
process(clk_i)

variable timestamp_to_queue : unsigned(47 downto 0) := (others => '0');

begin
    if(rising_edge(clk_i)) then
        if (enable_i = '1') then
            if (enable_i_prev = '0') then
                -- In case of a reset we'll need to reset these values from this process
                missed_pulses <= (others => '0');
                
                pulse_queued_din <= (others => '0');
                pulse_queued_reset <= '1';
                pulse_queued_wstb <= '0';

                timestamp_to_queue := (others => '0');
                
            else
                -- Bits that need resetting every clock cycle
                pulse_queued_reset <= '0';
                pulse_queued_wstb <= '0';

                if (dropped_flag = '1') then
                    missed_pulses <= missed_pulses + 1;
                -- If check to make sure that we should be storing this event at all
                elsif (trig_same /= '1') then
                    -- A little calculation first
                    timestamp_to_queue := timestamp + delay_i - 2;

                    -- First up, event rejection criteria:
                    if (pulse_queued_full = '1') then
                        missed_pulses <= missed_pulses + 1;

                    -- If we have no width we're acting as a fancy delay line
                    elsif (width_i = 0) then
                        if (trig_rise = '1') then
                            pulse_queued_din <= '1' & std_logic_vector(timestamp_to_queue);
                        else
                            pulse_queued_din <= '0' & std_logic_vector(timestamp_to_queue);
                        end if;

                        pulse_queued_wstb <= '1';

                    -- Next, if we have a width we'll pass the timestamp that we got the trigger
                    else
                        if (edge_validation(trig_rise, trig_fall, TRIG_EDGE(1 downto 0))) then
                                pulse_queued_din <= '1' & std_logic_vector(timestamp_to_queue);
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

variable edges_remaining : unsigned(31 downto 0) := (others => '0');
variable pulse_ts        : unsigned(47 downto 0) := (others => '0');

begin
    if(rising_edge(clk_i)) then
        if (enable_i = '1') then
            if (enable_i_prev = '0') then
                edges_remaining := (others => '0');
                
                pulse <= '0';
                pulse_queued_rstb <= '0';
                pulse_ts := (others => '0');
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
                        if (delay_i = 0) then
                            pulse_queued_rstb <= '1';

                        elsif ((timestamp = queue_pulse_ts) and (queue_pulse_ts /= 0)) then
                            pulse <= '1';
                            pulse_queued_rstb <= '1';
                            pulse_ts := timestamp + width_i;

                        elsif (timestamp = pulse_ts) then
                            pulse <= '0';
                        end if;
                    else
                        if (edges_remaining /= 0) then
                            if (timestamp = pulse_ts) then
                                if (unsigned(edges_remaining mod 2) = 0) then
                                    edges_remaining := edges_remaining - 1;
                                    pulse_ts := timestamp + width_i;
                                    pulse <= not pulse;

                                else
                                    edges_remaining := edges_remaining - 1;
                                    pulse_ts := timestamp + gap_i;
                                    pulse <= not pulse;
                                end if;
                            end if;

                            if (edges_remaining = 1) then
                                pulse_queued_rstb <= '1';
                            end if;

                        else
                            if (queue_pulse_ts /= 0) then
                                if ((delay_i = 0)  and ((timestamp - 6) = queue_pulse_ts)) then
                                    pulse_ts := timestamp + step_i - 5;
                                    edges_remaining := pulses_i + pulses_i - 2;

                                elsif (timestamp = queue_pulse_ts) then
                                    pulse <= '1';
                                    pulse_ts := timestamp + width_i;
                                    edges_remaining := pulses_i + pulses_i - 1;
                                end if;
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