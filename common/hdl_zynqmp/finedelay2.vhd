library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity finedelay2 is
port (
    -- Main clock
    clk_i : in std_logic;
    clk_4x_i : in std_logic;
    calibration_ready_i : in std_logic;
    oct_delay_i : in std_logic_vector(2 downto 0);
    fine_delay_i : in std_logic_vector(8 downto 0);
    fine_delay_wstb_i : in std_logic;
    fine_delay_compensated_o : out std_logic_vector(8 downto 0);
    signal_i : in std_logic;
    signal_o : out std_logic
);
end;

architecture rtl of finedelay2 is
    signal signal_oct : std_logic := '0';
begin
    oct_finedelay_inst : entity work.oct_finedelay port map (
        clk_i => clk_i,
        clk_4x_i => clk_4x_i,
        oct_delay_i => oct_delay_i,
        signal_i => signal_i,
        signal_o => signal_oct
    );

    o_finedelay_inst : entity work.o_finedelay port map (
        clk_i => clk_i,
        calibration_ready_i => calibration_ready_i,
        fine_delay_i => fine_delay_i,
        fine_delay_wstb_i => fine_delay_wstb_i,
        fine_delay_compensated_o => fine_delay_compensated_o,
        signal_i => signal_oct,
        signal_o => signal_o
    );
end;
