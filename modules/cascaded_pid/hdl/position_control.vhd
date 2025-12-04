--------------------------------------------------------------------------------
--  File:       position_control.vhd
--  Desc:       Implementation of an outer PID loop which controls position.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity position_control is 
port (
    clk : in std_logic;
    reset : in std_logic;
    trig : in std_logic; -- 10 us clock

    kp_pos : in std_logic_vector(31 downto 0);
    ki_pos : in std_logic_vector(31 downto 0);
    kd_pos : in std_logic_vector(31 downto 0);
    ff_pos : in std_logic_vector(31 downto 0);
    dir_toggle : in std_logic_vector(31 downto 0);

    real_input : in std_logic_vector(31 downto 0); -- Measured value
    setpoint : in std_logic_vector(31 downto 0); -- Desired value
    position_out : out signed(31 downto 0) := (others => '0') -- Output value
);
end entity position_control;

architecture rtl of position_control is
    signal in_error : signed(24 downto 0) := (others => '0');
    signal prev_error : signed(24 downto 0) := (others => '0');
    signal round_out : signed(position_out'range) := (others => '0');

    signal in_tmp_error : signed(31 downto 0) := (others => '0');
    signal i_tmp : signed(44 downto 0) := (others => '0');
    signal sum_tmp : signed(42 downto 0) := (others => '0');

    signal p_val : signed(42 downto 0) := (others => '0');
    signal i_val : signed(42 downto 0) := (others => '0');
    signal d_val : signed(42 downto 0) := (others => '0');
    signal ff_val : signed(42 downto 0) := (others => '0');

    signal dir_toggle_prev : std_logic_vector(31 downto 0);
    signal trigger : std_logic;
    signal trig_prev : std_logic;
    
    constant max_lim : signed(position_out'range) := (position_out'left => '0', others => '1');
    constant min_lim : signed(position_out'range) := (position_out'left => '1', others => '0');
    constant max_integral_lim : signed(position_out'range) := (position_out'left => '0', others => '1');
    constant min_integral_lim : signed(position_out'range) := (position_out'left => '1', others => '0');

begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            -- trigger
            trig_prev <= trig;
            dir_toggle_prev <= dir_toggle;
            trigger <= trig and not trig_prev;

            if reset = '1' then
                in_error <= (others => '0');
                prev_error <= (others => '0');
                round_out <= (others => '0');
                position_out <= (others => '0');
                in_tmp_error <= (others => '0');
                i_tmp <= (others => '0');
                sum_tmp <= (others => '0');
                p_val <= (others => '0');
                i_val <= (others => '0');
                d_val <= (others => '0');
                ff_val <= (others => '0');

            elsif trigger = '1' then
                    -- Calculate error and clamp diff
                    in_tmp_error <= signed(setpoint) - signed(real_input);
                    if in_tmp_error > max_lim then
                        in_error <= (in_error'left => '0', others => '1');
                    elsif in_tmp_error < min_lim then
                        in_error <= (in_error'left => '1', others => '0');
                    else
                        in_error <= resize(in_tmp_error, in_error'length);
                    end if;

                    -- Store previous error
                    prev_error <= in_error;

                    -- Proportional
                    p_val <= (resize(signed(kp_pos), 18) * in_error);

                    -- Integral
                    i_tmp <= i_tmp + (resize(signed(ki_pos), 18) * in_error);
                    if i_tmp > max_integral_lim then
                        i_val <= (i_val'left => '0', others => '1');
                    elsif i_tmp < min_integral_lim then
                        i_val <= (i_val'left => '1', others => '0');
                    else
                        i_val <= resize(i_tmp, i_val'length);
                    end if;

                    -- Derivative
                    d_val <= resize(signed(kd_pos), 18) * (in_error - prev_error);

                    -- Feedforwards
                    ff_val <= (resize(signed(ff_pos), 18) * resize(signed(setpoint), 25));

                    -- Sum terms
                    sum_tmp <= p_val + i_val + d_val + ff_val;
                    if sum_tmp > max_lim then
                        round_out <= (round_out'left => '0', others => '1');
                    elsif sum_tmp < min_lim then
                        round_out <= (round_out'left => '1', others => '0');
                    else
                        round_out <= resize(sum_tmp, round_out'length);
                    end if;

                    -- Toggle direction if requested
                    if unsigned(dir_toggle) /= 0 and dir_toggle /= dir_toggle_prev then
                        if not round_out = to_signed(0, round_out'length) then
                            round_out <= not round_out; -- apparently not 0 is -1
                        end if;
                    end if;

                    -- Return value
                    position_out <= round_out;

            end if; -- Reset
        end if; -- Clock

    end process;

end rtl;
