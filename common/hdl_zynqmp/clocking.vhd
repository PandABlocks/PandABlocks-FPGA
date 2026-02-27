library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

use work.top_defines.all;

entity clocking is
port (
    clk_i : in  std_logic;
    clk300_i : in  std_logic;
    clk_o : out std_logic;
    clk_4x_o : out std_logic;
    calibration_ready_o : out std_logic;
    locked_o : out std_logic
);
end;

architecture rtl of clocking is
    signal reset : std_logic;
    signal locked : std_logic;
    signal clkfbout : std_logic;
    signal clkfbout_buf : std_logic;
    signal clk : std_logic;
    signal clk_4x : std_logic;
    signal calibration_ready : std_logic;
    signal idelayctrl_reset : std_logic;
begin
    mmcm_inst1 : MMCME4_ADV
        generic map (
            DIVCLK_DIVIDE => 1,
            CLKFBOUT_MULT_F => 8.000,
            CLKOUT0_DIVIDE_F => 8.000,
            CLKOUT1_DIVIDE => 2,
            CLKIN1_PERIOD => 8.000
        ) port map (
            -- Output clocks
            CLKFBOUT => clkfbout,
            CLKFBIN => clkfbout_buf,
            CLKOUT0 => clk,
            CLKOUT1 => clk_4x,
            -- Input clock control
            CLKINSEL => '1',
            CLKIN1 => clk_i,
            CLKIN2 => '0',
            -- Ports for dynamic reconfiguration
            DADDR => (others => '0'),
            DCLK => '0',
            DEN => '0',
            DI => (others => '0'),
            DO => open,
            DRDY => open,
            DWE => '0',
            PSCLK => '0',
            PSEN => '0',
            PSINCDEC => '0',
            -- Other control and status signals
            LOCKED => locked,
            PWRDWN => '0',
            CDDCREQ => '0',
            RST => reset
    );

    clkf_buf_inst : BUFG port map (
        O => clkfbout_buf,
        I => clkfbout
    );

    clk_buf_inst : BUFG port map (
        O => clk_o,
        I => clk
    );

    clk_4x_buf_inst : BUFG port map (
        O => clk_4x_o,
        I => clk_4x
    );

    pll_autoreset_inst2 : entity work.pll_autoreset port map (
        clk_i => clk_i,
        pll_locked_i => locked,
        pll_reset_o => reset
    );

    idelayctrl_autoreset_inst : entity work.idelayctrl_autoreset port map (
        clk_i => clk300_i,
        rdy_i => calibration_ready,
        idelayctrl_reset_o => idelayctrl_reset
    );

    locked_o <= locked;

    idelayctrl_inst : IDELAYCTRL generic map (
        SIM_DEVICE => "ULTRASCALE"
    ) port map (
        RDY => calibration_ready,
        REFCLK => clk300_i,
        RST => idelayctrl_reset
    );

    calibration_ready_o <= calibration_ready;
end;
