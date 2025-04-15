library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sequencer_defines is
    -- sequencer states
    constant c_state_idle           : std_logic_vector(2 downto 0) := "000";
    constant c_state_wait_enable    : std_logic_vector(2 downto 0) := "001";
    constant c_state_wait_trigger   : std_logic_vector(2 downto 0) := "010";
    constant c_state_phase1         : std_logic_vector(2 downto 0) := "011";
    constant c_state_phase2         : std_logic_vector(2 downto 0) := "100";
    constant c_state_resetting      : std_logic_vector(2 downto 0) := "101";

    -- table errors
    constant c_table_error_ok        : std_logic_vector(1 downto 0) := "00";
    constant c_table_error_underrun  : std_logic_vector(1 downto 0) := "01";
    constant c_table_error_overrun   : std_logic_vector(1 downto 0) := "10";

    -- trigger options
    constant c_immediately          : unsigned(3 downto 0) := "0000";
    constant c_bita_0               : unsigned(3 downto 0) := "0001";
    constant c_bita_1               : unsigned(3 downto 0) := "0010";
    constant c_bitb_0               : unsigned(3 downto 0) := "0011";
    constant c_bitb_1               : unsigned(3 downto 0) := "0100";
    constant c_bitc_0               : unsigned(3 downto 0) := "0101";
    constant c_bitc_1               : unsigned(3 downto 0) := "0110";
    constant c_posa_gt_position     : unsigned(3 downto 0) := "0111";
    constant c_posa_lt_position     : unsigned(3 downto 0) := "1000";
    constant c_posb_gt_position     : unsigned(3 downto 0) := "1001";
    constant c_posb_lt_position     : unsigned(3 downto 0) := "1010";
    constant c_posc_gt_position     : unsigned(3 downto 0) := "1011";
    constant c_posc_lt_position     : unsigned(3 downto 0) := "1100";
end sequencer_defines;

