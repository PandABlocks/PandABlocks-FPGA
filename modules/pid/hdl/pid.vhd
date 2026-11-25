--------------------------------------------------------------------------------
--  File:       pid.vhd
--  Desc:       Implementation of an outer PID loop which controls position.
--------------------------------------------------------------------------------

-- We assume the input rate of the data will always be greater than the servo-rate of the PID.


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;
use work.cascaded_consts.all;

entity pid is 
port (
    clk_i : in std_logic;
    init_i : in std_logic;

    pid_period_i : in std_logic_vector(31 downto 0);

    kp_i : in std_logic_vector(31 downto 0) := (others => '0');
    ki_i : in std_logic_vector(31 downto 0);
    kd_i : in std_logic_vector(31 downto 0);
    kff_i : in std_logic_vector(31 downto 0);
    dir_toggle_i : in std_logic_vector(31 downto 0);

    dt_i : in std_logic_vector(31 downto 0);
    dt_inverse_i : in std_logic_vector(31 downto 0);
    use_vel_der_i : in std_logic_vector(31 downto 0);

    max_integral_i : in std_logic_vector(31 downto 0);
    max_output_i : in std_logic_vector(31 downto 0);
    max_following_err_i : in std_logic_vector(31 downto 0) := (others => '0');

    real_input_i : in std_logic_vector(31 downto 0); -- Measured value
    setpoint_i : in std_logic_vector(31 downto 0); -- Desired value
    real_output_o : out std_logic_vector(31 downto 0) := (others => '0') -- Output value
);
end entity pid;

architecture rtl of pid is
    -- 200 kHz target
    -- 25 x 18 multipliers

    signal kp_prev : std_logic_vector(31 downto 0) := (others => '0');
    signal ki_prev : std_logic_vector(31 downto 0) := (others => '0');
    signal kd_prev : std_logic_vector(31 downto 0) := (others => '0');
    signal kff_prev : std_logic_vector(31 downto 0) := (others => '0');
    signal dt_prev : std_logic_vector(31 downto 0) := (others => '0');
    signal dt_inv_prev : std_logic_vector(31 downto 0) := (others => '0');
    signal input_changed : std_logic;

    signal round_out : signed(real_output_o'range) := (others => '0');

    signal err_full : signed(31 downto 0) := (others => '0');
    signal err_buffered : signed(31 downto 0) := (others => '0');
    signal err_prev : signed(31 downto 0) := (others => '0');
    signal err_diff : signed(31 downto 0) := (others => '0');

    signal p_mul : signed(P_MUL_SIZE - 1 downto 0) := (others => '0');
    signal p_scaled : signed(P_SCALED_SIZE - 1 downto 0) := (others => '0');

    signal i_mul_frac_parts : signed(I_MUL_FRAC_SIZE - 1 downto 0) := (others => '0');
    signal i_mul_err : signed(I_MUL_ERR_SIZE - 1 downto 0) := (others => '0');
    signal i_round : signed(i_mul_err'length - 1 downto 0) := (others => '0');
    signal i_scaled_frac : signed(I_SCALED_FRAC_SIZE - 1 downto 0) := (others => '0');
    signal i_scaled : signed(I_SCALED_SIZE - 1 downto 0) := (others => '0');

    signal max_integral_shifted : signed(i_scaled'length - 1 downto 0) := (others => '0');

    signal d_mul : signed(D_MUL_SIZE -1 downto 0) := (others => '0');
    signal d_mul_err : signed(D_MUL_ERR_SIZE -1 downto 0) := (others => '0');
    signal d_scaled : signed(D_SCALED_SIZE - 1 downto 0) := (others => '0');

    signal prev_position : std_logic_vector(31 downto 0) := (others => '0');

    signal ff_mul : signed(FF_MUL_SIZE - 1 downto 0) := (others => '0');
    signal ff_scaled : signed(FF_SCALED_SIZE - 1 downto 0) := (others => '0');

    signal sum_scaled : signed(SUM_SCALED_SIZE - 1 downto 0) := (others => '0');
    signal sum_rounded : signed(SUM_SCALED_SIZE - 1 downto 0) := (others => '0');
    signal sum_integer : signed(SUM_SCALED_SIZE - DT_FRAC - 1 downto 0) := (others => '0');

    signal pipeline_counter : unsigned(3 downto 0) := (others => '0');
    signal enable_pipeline  : std_logic := '0';

    signal clk_count : unsigned(31 downto 0) := (others => '0'); -- 625 is ~200kHz
    signal trigger : std_logic;

begin

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if init_i = '1' then
                trigger <= '0';
                clk_count <= (others => '0');
            else
                if clk_count = unsigned(pid_period_i) - 1 then
                    trigger <= '1';
                    clk_count <= (others => '0');
                else
                    trigger <= '0';
                    clk_count <= clk_count + 1;
                end if; -- Update count
            end if; -- Process reset
        end if; -- Clock
    end process;

    process(clk_i)
    begin
        if rising_edge(clk_i) then

            -- -- Check if inputs have changed
            -- if kp_i /= kp_prev or
            -- ki_i /= ki_prev or
            -- kd_i /= kd_prev or
            -- dt_i /= dt_prev or
            -- dt_inverse_i /= dt_inv_prev then
            --     input_changed <= '1';
            -- else
            --     input_changed <= '0';
            -- end if;

            -- -- Update input buffer
            -- kp_prev <= kp_i;
            -- ki_prev <= ki_i;
            -- kd_prev <= kd_i;
            -- dt_prev <= dt_i;
            -- dt_inv_prev <= dt_inverse_i;

            -- Scale integral limit to fixed point
            max_integral_shifted <= shift_left(resize(signed(max_integral_i), max_integral_shifted'length), DT_FRAC);
            
            -- Calculate the setpoint error
            err_full <= signed(setpoint_i) - signed(real_input_i);

            -- -- Caclulate velocity
            -- vel_o <= std_logic_vector(resize(signed(real_input_i) - signed(prev_position), vel_o'length));

            -- Reset/following error protection
            -- if init_i = '1' or 
            -- signed(real_input_i) > signed(max_following_err_i) or 
            -- signed(real_input_i) < signed(-max_following_err_i) or
            -- input_changed = '1' then

            if init_i = '1' then
                err_full <= (others => '0');
                err_prev <= (others => '0');
                err_buffered <= (others => '0');
                err_diff <= (others => '0');
                
                sum_scaled <= (others => '0');
                sum_rounded <= (others => '0');
                sum_integer <= (others => '0');

                p_mul <= (others => '0');
                p_scaled <= (others => '0');

                i_mul_frac_parts <= (others => '0');
                i_mul_err <= (others => '0');
                i_round <= (others => '0');
                i_scaled_frac <= (others => '0');
                i_scaled <= (others => '0');

                d_mul <= (others => '0');
                d_mul_err <= (others => '0');
                d_scaled <= (others => '0');

                prev_position <= (others => '0');

                ff_mul <= (others => '0');
                ff_scaled <= (others => '0');

                round_out <= (others => '0');
                real_output_o <= (others => '0');

                pipeline_counter <= "0000";
                enable_pipeline <= '0';

            elsif trigger = '1' then
                -- Output value and process next
                real_output_o <= std_logic_vector(round_out);
                enable_pipeline <= '1';

            elsif enable_pipeline = '1' then
                case pipeline_counter is
                    when "0000" =>
                        i_mul_frac_parts <= resize(signed(ki_i), K_INT + K_FRAC) * resize(signed(dt_i), DT_INT + DT_FRAC);
                        d_mul <= resize(signed(kd_i), K_INT + K_FRAC) * resize(signed(dt_inverse_i), D_DT_SIZE);

                        if use_vel_der_i(0) = '1' then
                            err_diff <= signed(real_input_i) - signed(prev_position);
                        else
                            err_diff <= signed(err_prev) - signed(err_full);
                        end if;
                        pipeline_counter <= "0001";

                    when "0001" =>
                        p_mul <= resize(signed(kp_i), K_INT + K_FRAC) * resize(signed(err_full), P_ERR_INT);
                        i_mul_err <= resize(signed(err_full), ID_ERR_INT) * i_mul_frac_parts;
                        ff_mul <= resize(signed(kff_i), K_INT + K_FRAC) * resize(signed(setpoint_i), FF_SETPOINT_SIZE);
                        pipeline_counter <= "0010";

                    when "0010" =>
                        p_scaled <= p_mul & (DT_FRAC - K_FRAC - 1 downto 0 => '0');
                        i_scaled_frac <= resize(shift_right(i_mul_err + shift_right(i_mul_err, DT_FRAC - 1), K_FRAC), i_scaled_frac'length);
                        d_mul_err <= resize(signed(err_diff), P_ERR_INT) * d_mul;
                        ff_scaled <= ff_mul & (DT_FRAC - K_FRAC - 1 downto 0 => '0');
                        pipeline_counter <= "0011";

                    when "0011" =>
                        if (i_scaled + i_scaled_frac) > max_integral_shifted then
                            i_scaled <= max_integral_shifted;
                        elsif (i_scaled + i_scaled_frac) < -max_integral_shifted then
                            i_scaled <= -max_integral_shifted;
                        else
                            i_scaled <= i_scaled + i_scaled_frac;
                        end if;

                        d_scaled <= d_mul_err & (DT_FRAC - K_FRAC - 1 downto 0 => '0');
                        pipeline_counter <= "0100";

                    when "0100" =>
                        sum_scaled <= resize((p_scaled + i_scaled + d_scaled + ff_scaled), sum_scaled'length);
                        pipeline_counter <= "0101";

                    when "0101" =>
                        sum_integer <= resize(shift_right(sum_scaled + shift_right(sum_scaled, DT_FRAC - 1), DT_FRAC), sum_integer'length);
                        pipeline_counter <= "0110";

                    when "0110" =>
                        -- Control output clamp
                        if sum_integer > resize(signed(max_output_i), sum_integer'length) then
                            round_out <= resize(signed(max_output_i), round_out'length);
                        elsif sum_integer < resize(signed(-max_output_i), sum_integer'length) then
                            round_out <= resize(signed(-max_output_i), round_out'length);
                        else
                            -- Toggle Direction
                            if dir_toggle_i(0) = '1' then
                                round_out <= resize(-sum_integer, round_out'length);
                            else
                                round_out <= resize(sum_integer, round_out'length);
                            end if;
                        end if;

                        -- Update previous error
                        err_prev <= err_full;

                        -- Update previous position for velocity
                        prev_position <= real_input_i;

                        pipeline_counter <= "0000";
                        enable_pipeline <= '0';

                    when others =>
                        pipeline_counter <= "0000";
                        enable_pipeline <= '0';

                end case;

            end if; -- Reset + Trigger

        end if; -- Clock

    end process;

end rtl;
