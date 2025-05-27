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
    clk_i             : in  std_logic; -- Forced by PandA
    init_i            : in  std_logic;
    slo_clk_i         : in  std_logic;

    -- Pass in constants externally
    Kp_i              : in  std_logic_vector(31 downto 0);
    Ki_i              : in  std_logic_vector(31 downto 0);
    Kd_i              : in  std_logic_vector(31 downto 0);
    FF_i              : in  std_logic_vector(31 downto 0);
     
    setpoint_i        : in  std_logic_vector(31 downto 0); -- Desired value
    in_signal_i       : in  std_logic_vector(31 downto 0); -- Measured value
    out_signal_o      : out std_logic_vector(31 downto 0)  -- Output value
);
end entity PID;

architecture Basic_PID of PID is
    signal in_error   : signed(31 downto 0) := (others => '0');
    signal prev_error : signed(31 downto 0) := (others => '0'); -- Start from zero
    signal integral   : signed(63 downto 0) := (others => '0'); -- Start from zero
    signal derivative : signed(31 downto 0) := (others => '0');
    signal P_out      : signed(63 downto 0) := (others => '0');
    signal I_out      : signed(63 downto 0) := (others => '0');
    signal D_out      : signed(63 downto 0) := (others => '0');
    signal FF_out     : signed(63 downto 0) := (others => '0');
    signal round_out  : signed(63 downto 0) := (others => '0');

    -- For type conversion
    signal Kp         : signed(31 downto 0) := (others => '0');
    signal Ki         : signed(31 downto 0) := (others => '0');
    signal Kd         : signed(31 downto 0) := (others => '0');
    signal FF         : signed(31 downto 0) := (others => '0'); -- Feed Forward
    signal setpoint   : signed(31 downto 0) := (others => '0');
    signal in_signal  : signed(31 downto 0) := (others => '0');
    signal out_signal : signed(31 downto 0) := (others => '0');

begin

    -- Conversions forced by FPGA weirdness
    Kp            <= signed(Kp_i);
    Ki            <= signed(Ki_i);
    Kd            <= signed(Kd_i);
    FF            <= signed(FF_i);
    setpoint      <= signed(setpoint_i);
    in_signal     <= signed(in_signal_i);

    process(slo_clk_i)
        constant max_lim : signed(out_signal'range) := (out_signal'left => '0', others => '1');
        constant min_lim : signed(out_signal'range) := (out_signal'left => '1', others => '0');

    begin
        if rising_edge(slo_clk_i) then
            if init_i = '1' then
                round_out  <= (others => '0');
                P_out      <= (others => '0');
                I_out      <= (others => '0');
                D_out      <= (others => '0');
                FF         <= (others => '0');
            else
                -- Proportional
                P_out      <= (Kp * in_error);

                -- Integral
                I_out      <= I_out + (Ki * in_error);

                -- Derivative
                D_out      <= Kd * (in_error - prev_error);

                -- Feedforwards
                FF_out     <= FF * setpoint;

                -- Update
                prev_error <= in_error;

                -- Protect against overflow
                if P_out + I_out + D_out + FF_out > max_lim then
                    report "OVERFLOW HIGH";
                    round_out  <= (round_out'left => '0', others => '1');
                elsif P_out + I_out + D_out + FF_out < min_lim then
                    round_out  <= (round_out'left => '1', others => '0');
                    report "OVERFLOW LOW";
                else
                    round_out  <= P_out + I_out + D_out + FF_out;
                end if;

            end if; -- Reset + Logic
        end if; -- Clock
    end process;

    -- Error calc
    in_error     <= setpoint - in_signal;

    -- Output conversions
    out_signal   <= resize(round_out, 32);
    out_signal_o <= std_logic_vector(out_signal);

end architecture Basic_PID;
