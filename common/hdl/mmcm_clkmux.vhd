library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

use work.top_defines.all;


entity mmcm_clkmux is
port (fclk_clk0_ps_i      : in  std_logic;
      sma_clk_i           : in  std_logic;
      mgt_rec_clk_i          : in  std_logic;
      clk_sel_i           : in  std_logic_vector(1 downto 0);
      linkup_i            : in  std_logic;
      sma_pll_locked_o    : out std_logic;
      fclk_locked_o       : out std_logic;
      clk_sel_stat_o      : out std_logic_vector(1 downto 0);
      fclk_clk0_o         : out std_logic;
      fclk_clk0_2x_o      : out std_logic
      );

end mmcm_clkmux;



architecture rtl of mmcm_clkmux is

signal sma_pll_reset        : std_logic;
signal pll2_reset           : std_logic;
signal sma_pll_locked       : std_logic;
signal sma_clkfbout         : std_logic;
signal sma_clkfbout_buf     : std_logic;
signal pll2_locked          : std_logic;
signal pll2_clkfbout        : std_logic;
signal pll2_clkfbout_buf    : std_logic;
signal sma_clk_out1         : std_logic;
signal enable_sma_clk     : std_logic;
signal enable_mgt_clk     : std_logic;
signal fclk_clk             : std_logic;
signal fclk_clk_2x          : std_logic;
signal fclk_clk_buf         : std_logic;
signal fclk_clk_2x_buf      : std_logic := '0';
signal secondary_mux_out    : std_logic;
signal primary_mux_sel      : std_logic;
signal ps_fclk_bufh            : std_logic;

begin

---------------------------------------------------------------------------
-- SMA (external clock) PLL reset
---------------------------------------------------------------------------

pll_autoreset_inst1 : entity work.pll_autoreset port map (
    clk_i => ps_fclk_bufh,
    pll_locked_i => sma_pll_locked,
    pll_reset_o => sma_pll_reset
);

-- PLL Clocking PRIMITIVE
--------------------------------------

plle2_adv_inst : PLLE2_ADV
    generic map
        (BANDWIDTH           => "OPTIMIZED",
        COMPENSATION         => "ZHOLD",
        DIVCLK_DIVIDE        => 1,
        CLKFBOUT_MULT        => 7,
        CLKFBOUT_PHASE       => 0.000,
        CLKOUT0_DIVIDE       => 7,
        CLKOUT0_PHASE        => 0.000,
        CLKOUT0_DUTY_CYCLE   => 0.500,
        CLKIN1_PERIOD        => 8.005)
    port map
        -- Output clocks
        (
        CLKFBOUT            => sma_clkfbout,
        CLKOUT0             => sma_clk_out1,
        CLKOUT1             => open,
        CLKOUT2             => open,
        CLKOUT3             => open,
        CLKOUT4             => open,
        CLKOUT5             => open,
        -- Input clock control
        CLKFBIN             => sma_clkfbout_buf,
        CLKIN1              => sma_clk_i,
        CLKIN2              => '0',
        -- Tied to always select the primary input clock
        CLKINSEL            => '1',
        -- Ports for dynamic reconfiguration
        DADDR               => (others => '0'),
        DCLK                => '0',
        DEN                 => '0',
        DI                  => (others => '0'),
        DO                  => open,
        DRDY                => open,
        DWE                 => '0',
        -- Other control and status signals
        LOCKED              => sma_pll_locked,
        PWRDWN              => '0',
        RST                 => sma_pll_reset
);

---------------------------------------------------------------------------
  -- Output buffering
---------------------------------------------------------------------------

sma_clkf_buf : BUFG
    port map
        (O => sma_clkfbout_buf,
         I => sma_clkfbout
);

fclk_buf1 : BUFG
    port map
        (O => fclk_clk_buf,
         I => fclk_clk
);

CLK_2X_GEN_1 : if FINE_DELAY_OPTION = '1' generate
begin
    plle2_adv_inst2 : PLLE2_ADV
        generic map (
            DIVCLK_DIVIDE        => 1,
            CLKFBOUT_MULT        => 8,
            CLKOUT0_DIVIDE       => 8,
            CLKOUT1_DIVIDE       => 4,
            CLKIN1_PERIOD        => 8.000,
            CLKIN2_PERIOD        => 8.000)
        port map (
            -- Output clocks
            CLKFBOUT            => pll2_clkfbout,
            CLKOUT0             => fclk_clk,
            CLKOUT1             => fclk_clk_2x,
            CLKOUT2             => open,
            CLKOUT3             => open,
            CLKOUT4             => open,
            CLKOUT5             => open,
            -- Input clock control
            CLKFBIN             => pll2_clkfbout_buf,
            CLKIN1              => secondary_mux_out,
            CLKIN2              => ps_fclk_bufh,
            CLKINSEL            => primary_mux_sel,
            -- Ports for dynamic reconfiguration
            DADDR               => (others => '0'),
            DCLK                => '0',
            DEN                 => '0',
            DI                  => (others => '0'),
            DO                  => open,
            DRDY                => open,
            DWE                 => '0',
            -- Other control and status signals
            LOCKED              => pll2_locked,
            PWRDWN              => '0',
            RST                 => pll2_reset
    );

    clkf_buf : BUFG port map
            (O => pll2_clkfbout_buf,
             I => pll2_clkfbout
    );

    flck_buf2 : BUFG port map (
            O => fclk_clk_2x_buf,
            I => fclk_clk_2x
        );

    ---------------------------------------------------------------------------
    -- fclk 2X PLL reset
    ---------------------------------------------------------------------------
    pll_autoreset_inst2 : entity work.pll_autoreset port map (
        clk_i => ps_fclk_bufh,
        pll_locked_i => pll2_locked,
        pll_reset_o => pll2_reset
    );

end generate;

NO_CLK_2X_GEN_1 : if FINE_DELAY_OPTION = '0' generate
begin
    primary_clkmux: BUFGMUX port map (
        O => fclk_clk,
        I0 => ps_fclk_bufh,
        I1 => secondary_mux_out,
        S => primary_mux_sel
    );
end generate;

---------------------------------------------------------------------------
-- Panda clock switching
---------------------------------------------------------------------------


-- Primary mux switches between primary clock (PS FCLK 125 MHz) and 
-- output form the secondary clock mux
-- MUX sel checks for PLL lock and MGT link-up

enable_sma_clk <= sma_pll_locked and clk_sel_i(0);
enable_mgt_clk <= linkup_i and clk_sel_i(1);
primary_mux_sel <= enable_sma_clk or enable_mgt_clk;

clk_mux_bufh: BUFH
    port map (
        O => ps_fclk_bufh,
        I => fclk_clk0_ps_i
);

-- Secondary mux switches between external sma clock and mgt recovered clock.
-- Secondary MUX select checks for MGT link-up.

secondary_clkmux : BUFGMUX_CTRL
    port map (
        O => secondary_mux_out,
        I0 => sma_clk_out1,
        I1 => mgt_rec_clk_i,
        S => enable_mgt_clk
);

-- Assign outputs

clk_sel_stat_o <= enable_mgt_clk & enable_sma_clk;
fclk_clk0_o <= fclk_clk_buf;
fclk_clk0_2x_o <= fclk_clk_2x_buf;
sma_pll_locked_o <= sma_pll_locked;
fclk_locked_o <= pll2_locked;

end architecture rtl;
