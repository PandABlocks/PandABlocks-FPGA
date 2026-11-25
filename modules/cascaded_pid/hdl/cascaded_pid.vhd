library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.position_control;
use work.velocity_control;

entity cascaded_pid is
    port (
        clk_i : in std_logic;
        init_i : in std_logic;
        trig_slo_i : in std_logic;
        trig_fst_i : in std_logic;
        kp_pos_i : in std_logic_vector(31 downto 0) := (others => '0');
        ki_pos_i : in std_logic_vector(31 downto 0) := (others => '0');
        kd_pos_i : in std_logic_vector(31 downto 0) := (others => '0');
        ff_pos_i : in std_logic_vector(31 downto 0) := (others => '0');
        kp_vel_i : in std_logic_vector(31 downto 0) := (others => '0');
        ki_vel_i : in std_logic_vector(31 downto 0) := (others => '0');
        kd_vel_i : in std_logic_vector(31 downto 0) := (others => '0');
        ff_vel_i : in std_logic_vector(31 downto 0) := (others => '0');
        dir_toggle_i : in std_logic_vector(31 downto 0) := (others => '0');
        
        -- clk_rate_i : in std_logic_vector(31 downto 0) := (others => '0');
        -- sample_rate_i : in std_logic_vector(31 downto 0) := (others => '0');
        -- velocity_target_i : in std_logic_vector(31 downto 0) := (others => '0');

        real_input_i : in std_logic_vector(31 downto 0) := (others => '0');
        setpoint_i : in std_logic_vector(31 downto 0) := (others => '0');
        real_output_o : out std_logic_vector(31 downto 0)
    );
end cascaded_pid;


architecture rtl of cascaded_pid is
    signal position_out : signed(31 downto 0) := (others => '0');

begin
    network : entity work.position_control port map (
        clk => clk_i,
        reset => init_i,
        trig => trig_slo_i,
        kp_pos => kp_pos_i,
        ki_pos => ki_pos_i,
        kd_pos => kd_pos_i,
        ff_pos => ff_pos_i,
        dir_toggle => dir_toggle_i,
        setpoint => setpoint_i,
        real_input => real_input_i,
        position_out => position_out
    );

    model_output : entity work.velocity_control port map (
        clk => clk_i,
        reset => init_i,
        trig => trig_fst_i,
        kp_vel => kp_vel_i,
        ki_vel => ki_vel_i,
        kd_vel => kd_vel_i,
        ff_vel => ff_vel_i,
        current_position => real_input_i,
        dir_toggle => dir_toggle_i,
        -- sample_rate => sample_rate_i,
        -- clock_rate => clk_rate_i,
        velocity_setpoint => position_out,
        velocity_out => real_output_o
    );

end rtl;
