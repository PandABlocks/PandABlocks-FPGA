library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.env.finish;

library work;


entity finedelay_tb is
end finedelay_tb;


architecture rtl of finedelay_tb is
    signal fclk_clk0_ps : std_logic := '1';
    signal fclk_clk0_ps_2x : std_logic := '1';
    signal q_delay : std_logic_vector(1 downto 0) := (others => '0');
    signal o_delay : std_logic_vector(4 downto 0) := (others => '0');
    signal o_delay_strobe : std_logic := '0';
    signal input_signal : std_logic := '0';
    signal output_signal : std_logic;
    procedure clk_wait(count : in natural :=1) is
    begin
        for i in 0 to count-1 loop
            wait until rising_edge(fclk_clk0_ps);
        end loop;
    end procedure;
begin

-- 125MHz clock from PS interface
fclk_clk0_ps <= not fclk_clk0_ps after 4ns;
fclk_clk0_ps_2x <= not fclk_clk0_ps_2x after 2ns;

finedelay_inst: entity work.finedelay port map (
    clk_i => fclk_clk0_ps,
    clk_2x_i => fclk_clk0_ps_2x,
    q_delay_i => q_delay,
    o_delay_i => o_delay,
    o_delay_strobe_i => o_delay_strobe,
    signal_i => input_signal,
    signal_o => output_signal
);

process
begin
    input_signal <= not input_signal;
    clk_wait(4);
end process;

process
    variable o_delay_val : integer := 0;
    variable q_delay_val : integer := 0;
begin
    for o_delay_val in 0 to 31 loop
        o_delay <= std_logic_vector(to_unsigned(o_delay_val, 5));
        o_delay_strobe <= '1';
        clk_wait(1);
        o_delay_strobe <= '0';
        for q_delay_val in 0 to 3 loop
            q_delay <= std_logic_vector(to_unsigned(q_delay_val, 2));
            clk_wait(32);
        end loop;
    end loop;
    finish;
end process;

end rtl;
