--------------------------------------------------------------------------------
--  File:       pid.vhd
--  Desc:       Implementation of an outer PID loop which controls position.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

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

    max_integral_i : in std_logic_vector(31 downto 0);
    max_output_i : in std_logic_vector(31 downto 0);

    real_input_i : in std_logic_vector(31 downto 0); -- Measured value
    setpoint_i : in std_logic_vector(31 downto 0); -- Desired value
    real_output_o : out std_logic_vector(31 downto 0) := (others => '0') -- Output value
);
end entity pid;

architecture rtl of pid is
    -- 200 kHz target
    -- 25 x 18 multipliers
    constant ERR_CLIPPED_LIM : natural := 131070;

    constant K_INT : natural := 10 + 1; -- Includes signed
    constant K_FRAC : natural := 7;
    constant P_ERR_INT : natural := 24 + 1; -- Includes signed
    constant ID_ERR_INT : natural := 17 + 1; -- Includes signed
    constant FF_SETPOINT_SIZE : natural := 24 + 1; -- Includes signed
    constant CLIPPED_ERR_INT : natural := 17 + 1; -- Includes signed
    constant I_ACCUM_BUFFER : natural := 8;
    constant D_DT_SIZE : natural := 24 + 1; -- Includes signed

    constant DT_INT : natural := 0 + 1; -- Includes signed
    constant DT_FRAC : natural := 21; -- 5e-6 @ 10% error

    -- constant DT_VAL : std_logic_vector(DT_INT + DT_FRAC - 1 downto 0) := "0000000000000000001011"; --Q1.21 5e-6

    constant P_MUL_SIZE : natural := P_ERR_INT + K_INT + K_FRAC;
    constant P_SCALED_SIZE : natural := P_MUL_SIZE + DT_FRAC - K_FRAC;

    constant I_MUL_FRAC_SIZE : natural := K_INT + DT_INT + K_FRAC + DT_FRAC;
    constant I_MUL_ERR_SIZE : natural := I_MUL_FRAC_SIZE + ID_ERR_INT;
    constant I_SCALED_FRAC_SIZE : natural := K_INT + DT_INT + ID_ERR_INT + DT_FRAC; --11+1+18.21
    constant I_SCALED_SIZE : natural := I_ACCUM_BUFFER + I_SCALED_FRAC_SIZE; --30+8.21

    constant D_MUL_SIZE : natural := K_INT + D_DT_SIZE + K_FRAC;
    constant D_MUL_ERR_SIZE : natural := D_MUL_SIZE + ID_ERR_INT;
    constant D_SCALED_SIZE : natural := D_MUL_ERR_SIZE + DT_FRAC - K_FRAC;

    constant FF_MUL_SIZE : natural := FF_SETPOINT_SIZE + K_INT + K_FRAC;
    constant FF_SCALED_SIZE : natural := FF_MUL_SIZE + DT_FRAC - K_FRAC;

    constant SUM_OVERFLOW_SIZE : natural := 4;
    constant SUM_SCALED_SIZE : natural := D_SCALED_SIZE + SUM_OVERFLOW_SIZE;

    signal prev_error : signed(31 downto 0) := (others => '0');
    signal round_out : signed(real_output_o'range) := (others => '0');
    signal err_clipped : signed(ID_ERR_INT - 1 downto 0) := (others => '0');

    signal err_full : signed(31 downto 0) := (others => '0');
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

    signal ff_mul : signed(FF_MUL_SIZE - 1 downto 0) := (others => '0');
    signal ff_scaled : signed(FF_SCALED_SIZE - 1 downto 0) := (others => '0');

    signal sum_scaled : signed(SUM_SCALED_SIZE - 1 downto 0) := (others => '0');
    signal sum_rounded : signed(sum_scaled'length - 1 downto 0) := (others => '0');
    signal sum_integer : signed(sum_scaled'length - DT_FRAC - 1 downto 0) := (others => '0');

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

            -- Scale integral limit to Q38.21
            max_integral_shifted <= shift_left(resize(signed(max_integral_i), max_integral_shifted'length), DT_FRAC); -- Q38.21
            
            -- Reduce error for Integral and Derivative terms
            if err_full > ERR_CLIPPED_LIM then
                err_clipped <= (err_clipped'left => '0', others => '1');
            elsif err_full < -ERR_CLIPPED_LIM then
                err_clipped <= (err_clipped'left => '1', others => '0');
            else
                err_clipped <= resize(err_full, err_clipped'length);
            end if;

            if init_i = '1' then
                err_full <= (others => '0');
                prev_error <= (others => '0');
                
                sum_scaled <= (others => '0');
                sum_rounded <= (others => '0');
                sum_integer <= (others => '0');

                ff_mul <= (others => '0');
                ff_scaled <= (others => '0');

                p_mul <= (others => '0');
                p_scaled <= (others => '0');

                i_mul_frac_parts <= (others => '0');
                i_mul_err <= (others => '0');
                i_round <= (others => '0');
                i_scaled_frac <= (others => '0');
                i_scaled <= (others => '0');

                round_out <= (others => '0');
                real_output_o <= (others => '0');
                err_full <= (others => '0');

                pipeline_counter <= "0000";
                enable_pipeline <= '0';

            elsif enable_pipeline = '1' then
                case pipeline_counter is
                    when "0000" =>
                        p_mul <= resize(signed(kp_i), K_INT + K_FRAC) * resize(signed(err_full), P_ERR_INT); --Q25+11.7 = Q36.7 = 43 bits
                        i_mul_frac_parts <= resize(signed(ki_i), K_INT + K_FRAC) * resize(signed(dt_i), DT_INT + DT_FRAC); --Q11+1.21+7 = Q12.28
                        d_mul <= resize(signed(kd_i), K_INT + K_FRAC) * resize(signed(dt_inverse_i), D_DT_SIZE); --Q11+25.7 = Q36.7
                        pipeline_counter <= "0001";

                    when "0001" =>
                        ff_mul <= resize(signed(kff_i), K_INT + K_FRAC) * resize(signed(setpoint_i), FF_SETPOINT_SIZE); --Q25+11.7 = Q36.7 = 43 bits
                        i_mul_err <= resize(signed(err_clipped), ID_ERR_INT) * i_mul_frac_parts; --Q18+11+1.28 = Q30.28
                        d_mul_err <= resize(signed(err_clipped), ID_ERR_INT) * d_mul; -- Q36+18.7 = Q54.7 = 61 bits
                        pipeline_counter <= "0010";

                    when "0010" =>
                        p_scaled <= p_mul & (DT_FRAC - K_FRAC - 1 downto 0 => '0'); --Q36.21 = 57 bits
                        ff_scaled <= ff_mul & (DT_FRAC - K_FRAC - 1 downto 0 => '0'); -- Q36.21 = 57 bits
                        i_round <= i_mul_err + shift_right(i_mul_err, DT_FRAC - 1); --Q18+11+1.28 = Q30.28
                        d_scaled <= d_mul_err & (DT_FRAC - K_FRAC - 1 downto 0 => '0'); -- Q54.21 = 75 bits
                        pipeline_counter <= "0011";

                    when "0011" =>
                        i_scaled_frac <= resize(shift_right(i_round, K_FRAC), i_scaled_frac'length); --Q30.21 = 51 bits
                        pipeline_counter <= "0100";

                    when "0100" =>
                        if (i_scaled + i_scaled_frac) > max_integral_shifted then
                            i_scaled <= max_integral_shifted;
                        elsif (i_scaled + i_scaled_frac) < -max_integral_shifted then
                            i_scaled <= -max_integral_shifted;
                        else
                            i_scaled <= i_scaled + i_scaled_frac; --Q8+11+1+18.21 = Q38.21 = 59 bits
                        end if;
                        pipeline_counter <= "0101";

                    when "0101" => -- process sum
                        sum_scaled <= resize((p_scaled + i_scaled + d_scaled + ff_scaled), sum_scaled'length); --Q11+25+18+4.21 = 79 bits
                        pipeline_counter <= "0110";

                    when "0110" =>
                        sum_rounded <= sum_scaled + shift_right(sum_scaled, DT_FRAC - 1); --Q58.21 = 79 bits
                        pipeline_counter <= "0111";

                    when "0111" =>
                        sum_integer <= resize(shift_right(sum_rounded, DT_FRAC), sum_integer'length); --Q58.0 = 58 bits
                        pipeline_counter <= "1000";

                    when "1000" =>
                        -- Control output clamp
                        if sum_integer > signed(max_output_i) then
                            round_out <= resize(signed(max_output_i), round_out'length); --Q32.0
                        elsif sum_integer < signed(-max_output_i) then
                            round_out <= resize(signed(-max_output_i), round_out'length); --Q32.0
                        else
                            -- Toggle Direction
                            if dir_toggle_i(0) = '1' then
                                round_out <= resize(-sum_integer, round_out'length); --Q32.0
                            else
                                round_out <= resize(sum_integer, round_out'length); --Q32.0
                            end if;
                        end if;
                        pipeline_counter <= "0000";
                        enable_pipeline <= '0';

                    when others =>
                        pipeline_counter <= "0000";
                        enable_pipeline <= '0';

                end case;

            elsif trigger = '1' and (dt_i /= (dt_i'range => '0')) then
                -- Handle error
                err_full <= signed(setpoint_i) - signed(real_input_i);
                prev_error <= err_full;

                -- Return value
                real_output_o <= std_logic_vector(round_out);
                enable_pipeline <= '1';

            end if; -- Reset + Trigger

        end if; -- Clock

    end process;

end rtl;
