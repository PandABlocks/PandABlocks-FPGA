--------------------------------------------------------------------------------
--  File:       PID.vhd
--  Desc:       HDL implementation of a PID
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity PID is 
port (
    clk_i                : in  std_logic; -- Forced by PandA
    init_i               : in  std_logic;
    trig_i               : in  std_logic;

    -- Pass in constants externally
    Kp_i                 : in  std_logic_vector(31 downto 0);
    Ki_i                 : in  std_logic_vector(31 downto 0);
    Kd_i                 : in  std_logic_vector(31 downto 0);
    FF_i                 : in  std_logic_vector(31 downto 0);
    err_sign_i           : in  std_logic_vector(31 downto 0);

    setpoint_i           : in  std_logic_vector(31 downto 0); -- Desired value
    in_signal_i          : in  std_logic_vector(31 downto 0); -- Measured value
    out_signal_o         : out std_logic_vector(31 downto 0)  -- Output value
);
end entity PID;

architecture Basic_PID of PID is
    signal setpoint      : signed(25 downto 0) := (others => '0');
    signal in_error      : signed(25 downto 0) := (others => '0');
    signal prev_error    : signed(25 downto 0) := (others => '0');

    signal P_out         : signed(44 downto 0) := (others => '0');
    signal I_out         : signed(44 downto 0) := (others => '0');
    signal D_out         : signed(44 downto 0) := (others => '0');
    signal FF_out        : signed(44 downto 0) := (others => '0');

    signal Kp            : signed(18 downto 0) := (others => '0');
    signal Ki            : signed(18 downto 0) := (others => '0');
    signal Kd            : signed(18 downto 0) := (others => '0');
    signal FF            : signed(18 downto 0) := (others => '0');
    signal err_sign      : signed(1 downto 0) := (others => '0');

    signal in_signal     : signed(25 downto 0) := (others => '0');
    signal round_out     : signed(44 downto 0) := (others => '0');
    signal out_signal    : signed(31 downto 0) := (others => '0');
    signal out_sign      : signed(46 downto 0) := (others => '0');

    signal trigger       : std_logic;
    signal trigger_prev  : std_logic;

    signal I_out_current : signed(44 downto 0) := (others => '0');

begin

    process(clk_i)
        constant max_lim_final : signed(out_signal'range) := (out_signal'left => '0', others => '1');
        constant min_lim_final : signed(out_signal'range) := (out_signal'left => '1', others => '0');

        constant max_lim_err  : signed(out_signal'range) := (out_signal'left => '0', others => '1');
        constant min_lim_err  : signed(out_signal'range) := (out_signal'left => '1', others => '0');

    begin
        if rising_edge(clk_i) then
            -- PandA type conversions
            Kp             <= resize(signed(Kp_i), 19);
            Ki             <= resize(signed(Ki_i), 19);
            Kd             <= resize(signed(Kd_i), 19);
            FF             <= resize(signed(FF_i), 19);
            err_sign       <= resize(signed(err_sign_i), 2);
            setpoint       <= resize(signed(setpoint_i), 26);
            in_signal      <= resize(signed(in_signal_i), 26);

            trigger_prev   <= trig_i;

            I_out <= I_out_current;

            -- Error calc w/ overflow protection
            if setpoint - in_signal > max_lim_err then
                report "OVERFLOW HIGH";
                in_error  <= (in_error'left => '0', others => '1');
            elsif setpoint - in_signal < min_lim_err then
                in_error  <= (in_error'left => '1', others => '0');
                report "OVERFLOW LOW";
            else
                in_error     <= resize(setpoint - in_signal, 26);
            end if;

            if init_i = '1' then
                round_out  <= (others => '0');
                P_out      <= (others => '0');
                I_out      <= (others => '0');
                D_out      <= (others => '0');
                FF         <= (others => '0');
            elsif trigger = '1' then
                -- Proportional
                P_out    <= (Kp * in_error);

                -- Integral
                I_out_current <= (Ki * in_error);

                -- Derivative
                D_out    <= Kd * (in_error - prev_error);

                -- Feedforwards
                FF_out     <= (FF * setpoint);

                -- Update
                prev_error <= in_error;

                -- Protect against overflow
                if P_out + I_out + D_out + FF_out > max_lim_final then
                    report "OVERFLOW HIGH";
                    round_out  <= (round_out'left => '0', others => '1');
                elsif P_out + I_out + D_out + FF_out < min_lim_final then
                    round_out  <= (round_out'left => '1', others => '0');
                    report "OVERFLOW LOW";
                else
                    round_out  <= P_out + I_out + D_out + FF_out;
                end if;

            end if; -- Reset + Logic
        end if; -- Clock
    end process;

    -- trigger if clock is high and previous was not high
    -- only triggers for one clock period on rising edge
    trigger      <= trig_i and not trigger_prev;
    

    -- Output conversions
    out_sign     <= round_out * err_sign;
    out_signal   <= resize(out_sign, 32);
    out_signal_o <= std_logic_vector(out_signal);

end architecture Basic_PID;
