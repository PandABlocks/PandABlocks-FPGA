library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity mmcm_clkmux is
port (fclk_clk0_ps_i      : in  std_logic;
      sma_clk_i           : in  std_logic;
      rxoutclk_i          : in  std_logic;
      clk_sel_i           : in  std_logic_vector(1 downto 0);
      linkup_i            : in  std_logic;
      sma_pll_locked_o    : out std_logic;
      clk_sel_stat_o      : out std_logic_vector(1 downto 0);
      fclk_clk0_o         : out std_logic
      );

end mmcm_clkmux;



architecture rtl of mmcm_clkmux is

constant c_wait_reset       : natural := 1000;

signal sma_pll_reset_cnt    : unsigned(9 downto 0) := (others => '0');
signal sma_pll_reset        : std_logic;
signal sma_pll_locked       : std_logic;
signal sma_clkfbout         : std_logic;
signal sma_clkfbout_buf     : std_logic;
signal sma_clk_out1         : std_logic;
signal enable_sma_clk     : std_logic;
signal enable_mgt_clk     : std_logic;
signal fclk_clk             : std_logic;
signal secondary_mux_out    : std_logic;
signal primary_mux_sel      : std_logic;


begin

---------------------------------------------------------------------------
-- SMA (external clock) PLL reset
---------------------------------------------------------------------------

ps_sma_reset_pll: process(fclk_clk)
begin
    if rising_edge(fclk_clk) then
        -- Enable the MMCM reset
        if sma_pll_reset_cnt /= c_wait_reset and sma_pll_locked = '0' then
            sma_pll_reset_cnt <= sma_pll_reset_cnt +1;
        -- Reset the MMCM reset when it goes out of lock
        elsif sma_pll_locked = '1' then
            sma_pll_reset_cnt <= (others => '0');
        end if;
        -- Enable the reset for 32, 125MHz clocks
        if sma_pll_locked = '0' then
            if sma_pll_reset_cnt = c_wait_reset then
                sma_pll_reset <= '0';
            else
                sma_pll_reset <= '1';
            end if;
        end if;
    end if;
end process ps_sma_reset_pll;


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

clkf_buf : BUFG
    port map
        (O => sma_clkfbout_buf,
         I => sma_clkfbout
);

---------------------------------------------------------------------------
-- Panda clock switching
---------------------------------------------------------------------------


-- Primary mux switches between primary clock (PS FCLK 125 MHz) and 
-- output form the secondary clock mux
-- MUX sel checks for PLL lock and MGT link-up

enable_sma_clk <= sma_pll_locked and clk_sel_i(0);
enable_mgt_clk <= linkup_i and clk_sel_i(1);
primary_mux_sel <= enable_sma_clk or enable_mgt_clk;

primary_clkmux: BUFGMUX
    port map (
        O => fclk_clk,
        I0 => fclk_clk0_ps_i,
        I1 => secondary_mux_out,
        S => primary_mux_sel
);

-- Secondary mux switches between external sma clock and mgt recovered clock.
-- Secondary MUX select checks for MGT link-up.

secondary_clkmux : BUFGMUX
    port map (
        O => secondary_mux_out,
        I0 => sma_clk_out1,
        I1 => rxoutclk_i,
        S => enable_mgt_clk
);

-- Assign outputs

clk_sel_stat_o <= enable_mgt_clk & enable_sma_clk;
fclk_clk0_o <= fclk_clk;
sma_pll_locked_o <= sma_pll_locked;

end architecture rtl;
