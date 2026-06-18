library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

entity pulse is
port (
    -- Clock and Reset
    clk_i : in  std_logic;
    -- Block Input and Outputs
    trig_i : in  std_logic;
    enable_i : in  std_logic;
    out_o : out std_logic;
    -- Block Parameters
    TRIG_EDGE : in  std_logic_vector(31 downto 0) := (others => '0');
    TRIG_EDGE_WSTB : in  std_logic;
    DELAY_L : in  std_logic_vector(31 downto 0);
    DELAY_L_WSTB : in  std_logic;
    DELAY_H : in  std_logic_vector(31 downto 0);
    DELAY_H_WSTB : in  std_logic;
    WIDTH_L : in  std_logic_vector(31 downto 0);
    WIDTH_L_WSTB : in  std_logic;
    WIDTH_H : in  std_logic_vector(31 downto 0);
    WIDTH_H_WSTB : in  std_logic;
    PULSES : in  std_logic_vector(31 downto 0) := (others => '0');
    PULSES_WSTB : in  std_logic;
    STEP_L : in  std_logic_vector(31 downto 0);
    STEP_L_WSTB : in  std_logic;
    STEP_H : in  std_logic_vector(31 downto 0);
    STEP_H_WSTB : in  std_logic;
    -- Block Status
    QUEUED : out std_logic_vector(31 downto 0);
    DROPPED : out std_logic_vector(31 downto 0)
);
end;

architecture rtl of pulse is

signal is_enabled : std_logic := '0';
signal is_enabled_prev : std_logic := '0';
signal enabled_rise : std_logic := '0';

signal delay : unsigned(47 downto 0) := (others => '0');
signal width : unsigned(47 downto 0) := (others => '0');
signal npulses : unsigned(31 downto 0) := (others => '0');
signal step : unsigned(47 downto 0) := (others => '0');

-- Wires from timestamp_queue
signal pulse_start : std_logic;
signal queue_pulse_value : std_logic;
signal pulse_override : std_logic;
signal missed_pulses : unsigned(31 downto 0);
signal pulse_queued_data_count : std_logic_vector(8 downto 0);

-- Wires from pulse_train
signal pulse : std_logic;

-- Clamp v to a minimum of 5; passes through when v = 0 (disabled)
function clamp_min5(v : unsigned) return unsigned is
begin
    if v /= 0 and v < 5 then
        return to_unsigned(5, v'length);
    else
        return v;
    end if;
end function;

begin

ts_queue_inst : entity work.timestamp_queue port map (
    clk_i => clk_i,
    rst_i => enabled_rise,
    enable_i => is_enabled,
    trig_i => trig_i,
    trig_edge_i => TRIG_EDGE(1 downto 0),
    delay_i => delay,
    width_i => width,
    step_i => step,
    pulses_i => npulses,
    queue_pulse_value_o => queue_pulse_value,
    pulse_start_o => pulse_start,
    pulse_override_o => pulse_override,
    missed_pulses_o => missed_pulses,
    data_count_o => pulse_queued_data_count
);

pulse_train_inst : entity work.pulse_train port map (
    clk_i => clk_i,
    rst_i => enabled_rise,
    enable_i => is_enabled,
    pulse_start_i => pulse_start,
    queue_pulse_value_i => queue_pulse_value,
    width_i => width,
    delay_i => delay,
    step_i => step,
    pulses_i => npulses,
    pulse_o => pulse
);

-- Block output assignments
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

-- Previous-signal latching
process(clk_i)
begin
    if rising_edge(clk_i) then
        is_enabled_prev <= is_enabled;
    end if;
end process;

-- Parameter validation
process(clk_i)
    variable width_clamped : unsigned(47 downto 0);
    variable step_val : unsigned(47 downto 0);
begin
    if rising_edge(clk_i) then
        width_clamped := clamp_min5(unsigned(WIDTH_H(15 downto 0)) & unsigned(WIDTH_L));
        step_val := unsigned(STEP_H(15 downto 0)) & unsigned(STEP_L);

        width <= width_clamped;
        delay <= clamp_min5(unsigned(DELAY_H(15 downto 0)) & unsigned(DELAY_L));

        if step_val > width_clamped then
            step <= step_val;
        else
            step <= width_clamped + 1;
        end if;

        if unsigned(PULSES) = 0 then
            npulses <= to_unsigned(1, 32);
        else
            npulses <= unsigned(PULSES);
        end if;
    end if;
end process;

end;
