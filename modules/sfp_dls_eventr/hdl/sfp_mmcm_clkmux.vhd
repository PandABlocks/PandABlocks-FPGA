library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity sfp_mmcm_clkmux is

    generic (no_ibufg    : integer := 0);

    port (fclk_clk0_ps_i      : in  std_logic;
          sma_clk_in1            : in  std_logic;
          rxoutclk_i          : in  std_logic;
          ext_clock_i         : in  std_logic_vector(1 downto 0);
          sma_pll_locked_o    : out std_logic;
          fclk_clk0_o         : out std_logic
          );

end sfp_mmcm_clkmux;



architecture rtl of sfp_mmcm_clkmux is

constant c_wait_reset       : natural := 1000;

signal sma_pll_reset_cnt    : unsigned(9 downto 0) := (others => '0');
signal sma_pll_reset        : std_logic;
signal sma_pll_locked       : std_logic;
signal sma_clkfbout         : std_logic;
signal sma_clkfbout_buf     : std_logic;
signal sma_clk_out1         : std_logic;
signal enable_sma_clock     : std_logic;
signal sma_fclk             : std_logic;
signal fclk_clk             : std_logic;


begin


fclk_clk0_o <= fclk_clk;

sma_pll_locked_o <= sma_pll_locked;


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
        CLKIN1              => sma_clk_in1,
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

-- enable_sma_clock (ext_clock(0)) = 0 fclk_clk0_ps_i (PS 125MHz clock)
-- enable_sma_clock (ext_clock(0)) = 1 sma_clk (external clock)
BUFGMUX_inst :BUFGMUX
    port map (
        O   => sma_fclk,
        I0  => fclk_clk0_ps_i,
        I1  => sma_clk_out1,
        S   => enable_sma_clock
);


---------------------------------------------------------------------------

-- Enable the selection of the external clock only if the PLL
-- is locked on to the external clock
-- ext_clock and sma_pll_locked crossing clock domains but they
-- aren't dynamically changing so didn't bother with double registering
ps_sma_clk: process(fclk_clk0_ps_i)
begin
    if rising_edge(fclk_clk0_ps_i)then
        if ext_clock_i(0) = '1' and sma_pll_locked = '1' then
            enable_sma_clock <= '1';
        else
            enable_sma_clock <= '0';
        end if;
    end if;
end process ps_sma_clk;


---------------------------------------------------------------------------
-- Panda  event receiver clock switching
---------------------------------------------------------------------------

-- ext_clock(1) = 0 sma_fclk (either sma or ps 125MHz clocks)
-- ext_clock(1) = 1 rxoutclk (mgt data recovered clock)
eventr_BUFGMUX_inst :BUFGMUX
    port map (
        O   => fclk_clk,
        I0  => sma_fclk,
        I1  => rxoutclk_i,
        S   => ext_clock_i(1)
);


end architecture rtl;
