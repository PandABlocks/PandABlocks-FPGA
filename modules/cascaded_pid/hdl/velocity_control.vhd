--------------------------------------------------------------------------------
--  File:       velocity_control.vhd
--  Desc:       Implementation of an inner PID loop which controls velocity.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity velocity_control is 
port (
    clk : in std_logic;
    reset : in std_logic;
    trig : in std_logic; -- 1 us clock

    kp_vel : in std_logic_vector(31 downto 0);
    ki_vel : in std_logic_vector(31 downto 0);
    kd_vel : in std_logic_vector(31 downto 0);
    ff_vel : in std_logic_vector(31 downto 0);
    dir_toggle : in std_logic_vector(31 downto 0);

    -- sample_rate : in std_logic_vector(31 downto 0);
    -- clock_rate : in std_logic_vector(31 downto 0);

    current_position : in std_logic_vector(31 downto 0); -- Used for current velocity calculation
    velocity_setpoint : in signed(31 downto 0) := (others => '0'); -- Desired value, passed in from outer PID
    velocity_out : out std_logic_vector(31 downto 0)  -- Output value
);
end entity velocity_control;

architecture rtl of velocity_control is
    signal combined_val : signed(42 downto 0) := (others => '0');
    signal position_diff : signed(31 downto 0) := (others => '0');
    signal in_error : signed(24 downto 0) := (others => '0');
    signal prev_error : signed(24 downto 0) := (others => '0');
    signal round_out : signed(velocity_out'range) := (others => '0');

    signal in_tmp_error : signed(31 downto 0) := (others => '0');
    signal i_tmp : signed(44 downto 0) := (others => '0');
    signal sum_tmp : signed(42 downto 0) := (others => '0');

    signal p_val : signed(42 downto 0) := (others => '0');
    signal i_val : signed(42 downto 0) := (others => '0');
    signal d_val : signed(42 downto 0) := (others => '0');
    signal ff_val : signed(42 downto 0) := (others => '0');
    
    -- constant scale_factor : real := clock_rate / sample_rate; -- 1/dt, can't precompute due to PandA input constaints
    -- constant scaled_int : integer := integer(scale_factor * 256.0); -- Q.8

    signal current_velocity : signed(31 downto 0) := (others => '0');
    signal previous_position : signed(31 downto 0) := (others => '0');

    signal dir_toggle_prev : std_logic_vector(31 downto 0);
    signal trigger : std_logic;
    signal trig_prev : std_logic;

    constant max_lim : signed(velocity_out'range) := (velocity_out'left => '0', others => '1');
    constant min_lim : signed(velocity_out'range) := (velocity_out'left => '1', others => '0');
    constant max_integral_lim : signed(velocity_out'range) := (velocity_out'left => '0', others => '1');
    constant min_integral_lim : signed(velocity_out'range) := (velocity_out'left => '1', others => '0');

begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- trigger
            trig_prev <= trig;
            dir_toggle_prev <= dir_toggle;
            trigger <= trig and not trig_prev;

            if reset = '1' then
                combined_val <= (others => '0');
                in_error <= (others => '0');
                prev_error <= (others => '0');

                in_tmp_error <= (others => '0');
                i_tmp <= (others => '0');
                sum_tmp <= (others => '0');

                p_val <= (others => '0');
                i_val <= (others => '0');
                d_val <= (others => '0');
                ff_val <= (others => '0');
                velocity_out <= (others => '0');

            elsif trigger = '1' then
                -- Determine the current value of the velocity
                position_diff <= signed(current_position) - previous_position; -- Let 1/dt = 1
                current_velocity <= position_diff; -- Assume 1/dt is 1

                -- Calculate error and clamp diff
                in_tmp_error <= velocity_setpoint - signed(current_velocity);
                if in_tmp_error > max_lim then
                    in_error <= (in_error'left => '0', others => '1');
                elsif in_tmp_error < min_lim then
                    in_error <= (in_error'left => '1', others => '0');
                else
                    in_error <= resize((in_tmp_error), in_error'length);
                end if;

                -- Proportional
                p_val <= (resize(signed(kp_vel), 18) * in_error);

                -- Integral
                i_tmp <= i_tmp + (resize(signed(ki_vel), 18) * in_error);
                if to_integer(signed(i_tmp)) > to_integer(signed(max_integral_lim)) then
                    i_val <= (i_val'left => '0', others => '1');
                elsif to_integer(signed(i_tmp)) < to_integer(signed(min_integral_lim)) then
                    i_val <= (i_val'left => '1', others => '0');
                else
                    i_val <= resize(i_tmp, i_val'length);
                end if;

                -- Derivative
                d_val <= resize(signed(kd_vel), 18) * (in_error - prev_error);

                -- Feedforwards
                ff_val <= (resize(signed(ff_vel), 18) * resize(velocity_setpoint, 25));

                -- Update past error
                prev_error <= in_error;
                previous_position <= signed(current_position);

                -- Sum terms
                sum_tmp <= p_val + i_val + d_val + ff_val;
                if to_integer(signed(sum_tmp)) > to_integer(resize(signed(max_lim), sum_tmp'length)) then
                    round_out <= (round_out'left => '0', others => '1');
                elsif to_integer(signed(sum_tmp)) < to_integer(resize(signed(min_lim), sum_tmp'length)) then
                    round_out <= (round_out'left => '1', others => '0');
                else
                    round_out <= resize(sum_tmp, round_out'length);
                end if;

                -- Toggle direction if requested
                if unsigned(dir_toggle) /= 0 and dir_toggle_prev /= dir_toggle then
                    if not round_out = to_signed(0, round_out'length) then
                        round_out <= not round_out; -- apparently not 0 is -1
                    end if;
                end if;

                -- Return value
                velocity_out <= std_logic_vector(round_out);

            end if; -- Reset
        end if; -- Clock

    end process;

end rtl;
