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


-- Variable declarations

-- Standard logic signals
signal is_enabled               : std_logic := '0';
signal is_enabled_prev          : std_logic := '0';
signal trig_i_prev              : std_logic := '0';
signal enabled_rise              : std_logic := '0';
signal trig_rise                : std_logic := '0';
signal trig_fall                : std_logic := '0';
signal got_trigger              : std_logic := '0';
signal pulse                    : std_logic := '0';
signal pulse_override           : std_logic := '0';
signal pulse_queued_empty       : std_logic := '0';
signal read_valid_o             : std_logic := '1';
signal pulse_queued_full        : std_logic := '0';
signal write_ready_o            : std_logic := '1';
signal pulse_queued_reset       : std_logic := '0';
signal pulse_queued_rstb        : std_logic := '0';
signal pulse_queued_wstb        : std_logic := '0';
signal queue_pulse_value        : std_logic := '0';


-- Standard logic vector signals
signal trig_edge_i              : std_logic_vector(1 downto 0);
signal pulse_queued_din         : std_logic_vector(48 downto 0);
signal pulse_queued_dout        : std_logic_vector(48 downto 0);
signal pulse_queued_data_count  : std_logic_vector(8 downto 0);


-- Unsigned integer signals
signal delay_i                  : unsigned(47 downto 0) := (others => '0');
signal width_i                  : unsigned(47 downto 0) := (others => '0');
signal pulses_i                 : unsigned(31 downto 0) := (others => '0');
signal step_i                   : unsigned(47 downto 0) := (others => '0');
signal step_times_pulses        : unsigned(47 downto 0) := (others => '0');
signal missed_pulses            : unsigned(31 downto 0) := (others => '0');
signal queued_din               : unsigned(47 downto 0) := (others => '0');
signal queue_pulse_ts           : unsigned(47 downto 0) := (others => '0');
signal timestamp                : unsigned(47 downto 0) := (others => '0');
signal drop_for                 : unsigned(47 downto 0) := (others => '0');
signal override_ends_ts         : unsigned(47 downto 0) := (others => '0');
signal edge_ts                  : unsigned(47 downto 0) := (others => '0');
signal edges_remaining          : unsigned(31 downto 0) := (others => '0');


-- Assignments complete, next up is the main functional code of the block
begin

-- The pulse queue; keeps track of the timestamps of incoming pulses, maps to component above, attached to this architecture
pulse_queue_inst : entity work.fifo generic map(
    DATA_WIDTH => 49,
    FIFO_BITS  => 8
) port map (
    clk_i          => clk_i,
    reset_fifo_i   => pulse_queued_reset,
    write_data_i   => pulse_queued_din,
    write_valid_i  => pulse_queued_wstb,
    read_ready_i   => pulse_queued_rstb,
    read_data_o    => pulse_queued_dout,
    write_ready_o  => write_ready_o,
    read_valid_o   => read_valid_o,
    std_logic_vector(fifo_depth_o)   => pulse_queued_data_count
);


-- Bits relating to the FIFO queue
pulse_queued_full <= not write_ready_o;
pulse_queued_empty <= not read_valid_o;
queue_pulse_ts <= unsigned(pulse_queued_dout(47 downto 0));
queue_pulse_value <= pulse_queued_dout(48);
pulse_queued_reset <= not is_enabled;
pulse_queued_rstb <= '1' when
    (width_i = 0 and timestamp = queue_pulse_ts) or
    (edges_remaining = 1 and timestamp = edge_ts) else '0';


-- Block output assignments
trig_edge_i <= TRIG_EDGE(1 downto 0);
DROPPED <= std_logic_vector(missed_pulses);
QUEUED <= ZEROS(32-pulse_queued_data_count'length) & pulse_queued_data_count;
out_o <= pulse_override or pulse;

-- Calculation of enable signal
is_enabled <= enable_i and not
    TRIG_EDGE_WSTB and not
    DELAY_L_WSTB and not
    DELAY_H_WSTB and not
    WIDTH_L_WSTB and not
    WIDTH_H_WSTB and not
    PULSES_WSTB and not
    STEP_L_WSTB and not
    STEP_H_WSTB;
enabled_rise <= is_enabled and not is_enabled_prev;

-- Calculation of
trig_rise <= trig_i and not trig_i_prev;
trig_fall <= not trig_i and trig_i_prev;
got_trigger <=
    trig_rise or trig_fall when (trig_edge_i = "10" or width_i = 0) else
    trig_fall when trig_edge_i = "01" else
    trig_rise when trig_edge_i = "00" else '0';

-- Parameter validation
process(clk_i)

    variable delay_vector  : std_logic_vector(47 downto 0);
    variable step_vector   : std_logic_vector(47 downto 0);
    variable width_vector  : std_logic_vector(47 downto 0);
    variable width_integer : unsigned(47 downto 0) := (others => '0');

begin
    if (rising_edge(clk_i)) then
        -- Second clock tick, calc the minimum distance between rising edges
        step_times_pulses <= resize(step_i * pulses_i, 48);

        -- Take 48-bit time as combination of two for:
        width_vector(31 downto 0) := WIDTH_L;
        width_vector(47 downto 32) := WIDTH_H(15 downto 0);

        delay_vector(31 downto 0) := DELAY_L;
        delay_vector(47 downto 32) := DELAY_H(15 downto 0);

        step_vector(31 downto 0) := STEP_L;
        step_vector(47 downto 32) := STEP_H(15 downto 0);

        if unsigned(width_vector) /= 0 and unsigned(width_vector) < 5 then
            width_integer := to_unsigned(5, 48);
        else
            width_integer := unsigned(width_vector);
        end if;
        width_i <= width_integer;

        if unsigned(delay_vector) /= 0 and unsigned(delay_vector) < 5 then
            delay_i <= to_unsigned(5, 48);
        else
            delay_i <= unsigned(delay_vector);
        end if;

        if unsigned(step_vector) > unsigned(width_integer) then
            step_i <= unsigned(step_vector);
        else
            step_i <= width_integer + 1;
        end if;

        if unsigned(PULSES) = 0 then
            pulses_i <= to_unsigned(1, 32);
        else
            pulses_i <= unsigned(PULSES);
        end if;

    end if;
end process;


-- Global timestamp counter
process(clk_i)
begin
    if (rising_edge(clk_i)) then
        if (is_enabled = '0') then
            timestamp <= (others => '0');
        elsif (is_enabled = '1') then
            timestamp <= timestamp + 1;
        end if;
    end if;
end process;


-- Latch previous versions of enable and trig
process(clk_i)
begin
    if (rising_edge(clk_i)) then
        is_enabled_prev <= is_enabled;
        trig_i_prev <= trig_i;
    end if;
end process;


-- Queue filling process
process(clk_i)

    variable timestamp_to_queue       : unsigned(47 downto 0) := (others => '0');

begin
    if (rising_edge(clk_i)) then
        -- Default is do nothing with the queue
        pulse_queued_din <= (others => '0');
        pulse_queued_wstb <= '0';

        -- If we were counting down how long to drop pulses for the decrement
        if (drop_for > 0) then
            drop_for <= drop_for - 1;
        end if;

        if (enabled_rise = '1') then
            -- Reset on rising enable
            missed_pulses <= (others => '0');
            drop_for <= (others => '0');
            override_ends_ts <= (others => '0');
        elsif (is_enabled = '1' and got_trigger = '1') then
            -- The time we might put on the queue
            timestamp_to_queue := timestamp + delay_i;
            if (drop_for > 0 or pulse_queued_full = '1') then
                -- Can't process trigger
                missed_pulses <= missed_pulses + 1;
            elsif (width_i = 0) then
                -- Delay=0 case means passthrough
                if (delay_i = 0) then
                    pulse_override <= trig_i;
                else
                    -- If we have no width we're acting as a fancy delay line
                    pulse_queued_din <= trig_rise & std_logic_vector(timestamp_to_queue);
                    pulse_queued_wstb <= '1';
                end if;
            else
                -- Delay=0 case means we need to override for 3 clock ticks
                if (delay_i = 0) then
                    pulse_override <= '1';
                    override_ends_ts <= timestamp + 4;
                    pulse_queued_din <= '1' & std_logic_vector(timestamp_to_queue + 4);
                else
                    pulse_queued_din <= '1' & std_logic_vector(timestamp_to_queue);
                end if;
                pulse_queued_wstb <= '1';
                drop_for <= step_times_pulses - step_i + width_i;
            end if;
        end if;

        -- If disabled or we reached the end of the override ts then reset override
        if (is_enabled = '0' or timestamp = override_ends_ts) then
            pulse_override <= '0';
        end if;
    end if;
end process;


-- Process to pass edges
process(clk_i)
begin
    if rising_edge(clk_i) then
        if enabled_rise = '1' then
            -- Reset ts on enable, don't do anything else otherwise we will
            -- false trigger as timestamp = queue_pulse_ts = edge_ts = 0
            edge_ts <= (others => '0');
        elsif is_enabled = '1' and edges_remaining > 0 then
            -- Some edges remaining to produce
            if (timestamp = edge_ts) then
                if (unsigned(edges_remaining mod 2) = 1) then
                    pulse <= '0';
                    edge_ts <= timestamp + step_i - width_i;
                else
                    pulse <= '1';
                    edge_ts <= timestamp + width_i;
                end if;
                edges_remaining <= edges_remaining - 1;
            end if;
        elsif is_enabled = '1' and timestamp = queue_pulse_ts then
            if width_i = 0 then
                -- We're running as a fancy delay line
                pulse <= queue_pulse_value;
            else
                -- We are making a the rising edge of a pulse with defined width
                pulse <= '1';
                edges_remaining <= pulses_i + pulses_i - 1;
                if delay_i = 0 then
                    -- We added 4 ticks to account for queue delays, subtract it
                    edge_ts <= timestamp + width_i - 4;
                else
                    edge_ts <= timestamp + width_i;
                end if;
            end if;
        elsif is_enabled = '0' then
            -- Halt on disable
            pulse <= '0';
            -- Zero edges so we don't trigger a read strobe
            edges_remaining <= (others => '0');
        end if;
    end if;
end process;

end rtl;
