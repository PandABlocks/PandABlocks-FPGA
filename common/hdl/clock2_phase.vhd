-- Compute clock2x phase from main clock and main 2x clock.  Essentially
-- this mirrors the main clock as a signal.  We can't take the main clock as a
-- signal because that causes awful timing problems.
--
--             _     ___     ___     ___     ___     ___     ___     ___
--  clk_2x_     \___/   \___/   \___/   \___/   \___/   \___/   \___/
--                   _______         _______         _______         ___
--  clk_i      _____/       \_______/       \_______/       \_______/
--                   _______________                 _______________
--  phase_0    _____/               \_______________/               \___
--                           _______________                 ___________
--  phase_90   _____________/               \_______________/
--                           _______________                 ___________
--  phase_0_2x   ___________/               \_______________/
--               ___                 _______________                 ___
--  phase_90_2x     \_______________/               \_______________/
--                   _______         _______         _______         ___
--  phase_o     ____/       \_______/       \_______/       \_______/
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock2_phase is
    port (
        clk_i : in std_ulogic;
        clk_2x_i : in std_ulogic;
        phase_o : out std_ulogic := '0'
    );
end;

architecture arch of clock2_phase is
    signal phase_0 : std_ulogic := '0';
    signal phase_90 : std_ulogic := '0';
    -- We need to bring the main clock phase signals over to the main 2x
    -- clock domain before attempting any logic, as otherwise the timing
    -- becomes potentially *very* challenging.
    signal phase_0_2x : std_ulogic := '0';
    signal phase_90_2x : std_ulogic := '0';

begin
    process (clk_i) begin
        if rising_edge(clk_i) then
            phase_0 <= not phase_0;
        end if;
    end process;

    process (clk_i) begin
        if falling_edge(clk_i) then
            phase_90 <= phase_0;
        end if;
    end process;

    process (clk_2x_i) begin
        if rising_edge(clk_2x_i) then
            phase_0_2x <= phase_0;
            phase_90_2x <= phase_90;
            phase_o <= phase_0_2x xor phase_90_2x;
        end if;
    end process;
end;

