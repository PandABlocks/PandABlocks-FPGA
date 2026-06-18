library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

entity timestamp_queue is
port (
    clk_i : in std_logic;
    rst_i : in std_logic;
    -- Control
    enable_i : in std_logic;
    -- Trigger inputs
    trig_i : in std_logic;
    trig_edge_i : in std_logic_vector(1 downto 0);
    -- Parameters
    delay_i : in unsigned(47 downto 0);
    width_i : in unsigned(47 downto 0);
    step_i : in unsigned(47 downto 0);
    pulses_i : in unsigned(31 downto 0);
    -- Outputs
    queue_pulse_value_o : out std_logic;
    pulse_override_o : out std_logic := '0';
    pulse_start_o : out std_logic := '0';
    missed_pulses_o : out unsigned(31 downto 0);
    data_count_o : out std_logic_vector(8 downto 0)
);
end;

architecture rtl of timestamp_queue is

signal read_valid : std_logic := '1';
signal write_ready : std_logic := '1';
signal pulse_queued_full : std_logic := '0';
signal pulse_queued_reset : std_logic := '0';
signal pulse_queued_rstb : std_logic := '0';
signal pulse_queued_wstb : std_logic := '0';
signal pulse_queued_din : std_logic_vector(48 downto 0);
signal pulse_queued_dout : std_logic_vector(48 downto 0);
signal pulse_queued_data_count : std_logic_vector(8 downto 0);

signal trig_i_prev : std_logic := '0';
signal trig_rise : std_logic;
signal trig_fall : std_logic;
signal got_trigger : std_logic;

signal timestamp : unsigned(47 downto 0) := (others => '0');
signal missed_pulses : unsigned(31 downto 0) := (others => '0');
signal override_ends_ts : unsigned(47 downto 0) := (others => '0');
signal next_trigger_allowed_ts : unsigned(47 downto 0) := (others => '0');
signal collision_window : unsigned(47 downto 0) := (others => '0');
signal queue_pulse_ts : unsigned(47 downto 0);

begin

queue_pulse_ts <= unsigned(pulse_queued_dout(47 downto 0));
queue_pulse_value_o <= pulse_queued_dout(48);
missed_pulses_o <= missed_pulses;
data_count_o <= pulse_queued_data_count;
pulse_start_o <= '1' when timestamp = queue_pulse_ts and read_valid = '1' else '0';

-- Trigger edge detection
trig_rise <= trig_i and not trig_i_prev;
trig_fall <= not trig_i and trig_i_prev;
got_trigger <=
    trig_rise or trig_fall when (trig_edge_i = "10" or width_i = 0) else
    trig_fall when trig_edge_i = "01" else
    trig_rise when trig_edge_i = "00" else '0';

pulse_queue_inst : entity work.fifo generic map (
    DATA_WIDTH => 49,
    FIFO_BITS => 8
) port map (
    clk_i => clk_i,
    reset_fifo_i => pulse_queued_reset,
    write_data_i => pulse_queued_din,
    write_valid_i => pulse_queued_wstb,
    read_ready_i => pulse_queued_rstb,
    read_data_o => pulse_queued_dout,
    write_ready_o => write_ready,
    read_valid_o => read_valid,
    std_logic_vector(fifo_depth_o) => pulse_queued_data_count
);

pulse_queued_full <= not write_ready;
pulse_queued_reset <= not enable_i;
pulse_queued_rstb <= pulse_start_o;

-- Delayed signals
process(clk_i)
begin
    if rising_edge(clk_i) then
        trig_i_prev <= trig_i;
    end if;
end process;

-- Global timestamp counter
process(clk_i)
begin
    if rising_edge(clk_i) then
        if not enable_i then
            timestamp <= (others => '0');
        else
            timestamp <= timestamp + 1;
        end if;
    end if;
end process;

-- Queue filling process
process(clk_i)
    variable timestamp_to_queue : unsigned(47 downto 0) := (others => '0');
begin
    if rising_edge(clk_i) then
        pulse_queued_din <= (others => '0');
        pulse_queued_wstb <= '0';
        collision_window <= resize(pulses_i * step_i, 48);

        if rst_i then
            -- Reset on rising enable
            missed_pulses <= (others => '0');
            override_ends_ts <= (others => '0');
            next_trigger_allowed_ts <= (others => '0');
        elsif enable_i and got_trigger then
            timestamp_to_queue := timestamp + delay_i;
            if width_i /= 0 and timestamp < next_trigger_allowed_ts then
                -- Collision: new trigger before previous pulse train completes
                missed_pulses <= missed_pulses + 1;
            elsif pulse_queued_full then
                -- Can't process trigger
                missed_pulses <= missed_pulses + 1;
            elsif width_i = 0 then
                -- Delay=0 case means passthrough
                if delay_i = 0 then
                    pulse_override_o <= trig_i;
                else
                    -- If we have no width we're acting as a fancy delay line
                    pulse_queued_din <= trig_rise & std_logic_vector(timestamp_to_queue);
                    pulse_queued_wstb <= '1';
                end if;
            else
                -- Delay=0 case means we need to override for 3 clock ticks
                if delay_i = 0 then
                    pulse_override_o <= '1';
                    override_ends_ts <= timestamp + 4;
                    pulse_queued_din <= '1' & std_logic_vector(timestamp_to_queue + 4);
                else
                    pulse_queued_din <= '1' & std_logic_vector(timestamp_to_queue);
                end if;
                pulse_queued_wstb <= '1';
                next_trigger_allowed_ts <= timestamp + collision_window;
            end if;
        end if;

        -- If disabled or we reached the end of the override ts then reset override
        if enable_i = '0' or timestamp = override_ends_ts then
            pulse_override_o <= '0';
        end if;
    end if;
end process;

end;
