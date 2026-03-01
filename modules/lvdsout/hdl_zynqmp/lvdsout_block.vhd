library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity lvdsout_block is
port (
    -- Clock and Reset
    clk_i : in std_logic;
    clk_4x_i : in std_logic;
    reset_i : in std_logic;
    calibration_ready_i : in std_logic;
    -- Registers
    OCT_DELAY : in std_logic_vector(31 downto 0);
    FINE_DELAY : in std_logic_vector(31 downto 0);
    FINE_DELAY_wstb : in std_logic;
    FINE_DELAY_COMPENSATED : out std_logic_vector(31 downto 0) := (others => '0');
    -- Inputs
    val : in std_logic;
    -- Output pulse
    pad_o : out std_logic
);
end;

architecture rtl of lvdsout_block is
    signal pad_iob : std_logic;
begin
    FINE_DELAY_GEN1: if FINE_DELAY_OPTION = '1' generate
    begin
        fd_inst : entity work.finedelay2 port map (
            clk_i => clk_i,
            clk_4x_i => clk_4x_i,
            calibration_ready_i => calibration_ready_i,
            oct_delay_i => oct_delay(2 downto 0),
            fine_delay_i => FINE_DELAY(8 downto 0),
            fine_delay_wstb_i => FINE_DELAY_wstb,
            fine_delay_compensated_o => FINE_DELAY_COMPENSATED(8 downto 0),
            signal_i => val,
            signal_o => pad_iob
        );
    else generate
        pad_iob <= val;
    end generate;

    pad_o <= pad_iob;
end;
