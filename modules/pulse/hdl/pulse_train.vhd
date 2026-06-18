library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_train is
port (
    clk_i : in std_logic;
    rst_i : in std_logic;
    enable_i : in std_logic;
    pulse_start_i : in std_logic;
    queue_pulse_value_i : in  std_logic;
    width_i : in unsigned(47 downto 0);
    delay_i : in unsigned(47 downto 0);
    step_i : in unsigned(47 downto 0);
    pulses_i : in unsigned(31 downto 0);
    pulse_o : out std_logic
);
end;

architecture rtl of pulse_train is

signal pulse : std_logic := '0';
signal pulse_counter : unsigned(47 downto 0) := (others => '0');
signal edges_remaining : unsigned(31 downto 0) := (others => '0');

begin

pulse_o <= pulse;

process(clk_i)
begin
    if rising_edge(clk_i) then
        if enable_i then
            if edges_remaining /= 0 then
                if pulse_counter = 0 then
                    if pulse then
                        pulse_counter <= step_i - width_i - 1;
                    else
                        pulse_counter <= width_i - 1;
                    end if;
                    pulse <= not pulse;
                    edges_remaining <= edges_remaining - 1;
                else
                    pulse_counter <= pulse_counter - 1;
                end if;
            elsif pulse_start_i then
                if width_i = 0 then
                    -- We're running as a fancy delay line
                    pulse <= queue_pulse_value_i;
                else
                    -- We are making the rising edge of a pulse with defined width
                    pulse <= '1';
                    edges_remaining <= pulses_i + pulses_i - 1;
                    if delay_i = 0 then
                        -- Subtract 4 ticks to account for queue delays
                        pulse_counter <= width_i - 5;
                    else
                        pulse_counter <= width_i - 1;
                    end if;
                end if;
            end if;
        else
            -- Halt on disable
            pulse <= '0';
            -- Zero edges so we don't trigger a read strobe
            edges_remaining <= (others => '0');
            pulse_counter <= (others => '0');
        end if;
    end if;
end process;

end;
