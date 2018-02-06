library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity sfp_mmcm_clkmux is

    generic (no_ibufg    : integer := 0);
         
    port (FCLK_CLK0_PS        : in  std_logic;
          EXTCLK_P            : in  std_logic; 
          EXTCLK_N            : in  std_logic;
          RXOUTCLK            : in  std_logic;
          ext_clock           : in  std_logic_vector(1 downto 0);
          eventr_pll_locked_o : out std_logic; 
          sma_pll_locked_o    : out std_logic;  
          FCLK_CLK0           : out std_logic    
          );
                
end sfp_mmcm_clkmux;



architecture rtl of sfp_mmcm_clkmux is

constant c_wait_reset       : natural := 1000;

signal sma_pll_reset_cnt    : unsigned(9 downto 0) := (others => '0');
signal sma_pll_reset        : std_logic;
signal sma_pll_locked       : std_logic;
signal eventr_pll_locked    : std_logic;
signal sma_clk_in1          : std_logic; 
signal sma_clkfbout         : std_logic;
signal sma_clkfbout_buf     : std_logic;
signal sma_clk_out1         : std_logic;
signal enable_sma_clock     : std_logic;
signal sma_fclk             : std_logic;
signal FCLK_CLK             : std_logic;    
signal enable_eventr_clock  : std_logic;
signal eventr_clkfbout      : std_logic;   
signal eventr_clk_in1       : std_logic;
signal eventr_clkfbout_buf  : std_logic; 
signal eventr_clk_out1      : std_logic;


begin
    

FCLK_CLK0 <= FCLK_CLK;

sma_pll_locked_o <= sma_pll_locked;
eventr_pll_locked_o <= eventr_pll_locked;


---------------------------------------------------------------------------
-- SMA (external clock) PLL reset 
---------------------------------------------------------------------------

ps_sma_reset_pll: process(FCLK_CLK)
begin
    if rising_edge(FCLK_CLK) then
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


--clkin1_ibufgds : IBUFDS
clkin1_ibufgds : IBUFGDS
generic map (
    DIFF_TERM  => FALSE,
    IOSTANDARD => "LVDS_25"
)    
    port map
        (O  => SMA_CLK_IN1,
         I  => EXTCLK_P,
         IB => EXTCLK_N
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
        CLKFBOUT            => SMA_CLKFBOUT,
        CLKOUT0             => SMA_CLK_OUT1,
        CLKOUT1             => open,
        CLKOUT2             => open,
        CLKOUT3             => open,
        CLKOUT4             => open,
        CLKOUT5             => open,
        -- Input clock control
        CLKFBIN             => SMA_CLKFBOUT_BUF,
        CLKIN1              => SMA_CLK_IN1,
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
        (O => SMA_CLKFBOUT_BUF,
         I => SMA_CLKFBOUT
);
    
---------------------------------------------------------------------------
-- Panda clock switching
---------------------------------------------------------------------------
            
BUFGMUX_inst :BUFGMUX
    port map (
        O   => SMA_FCLK,         
        I0  => FCLK_CLK0_PS,     
        I1  => SMA_CLK_OUT1,      
        S   => enable_sma_clock  
);
  

---------------------------------------------------------------------------

ps_sma_clk: process(FCLK_CLK0_PS)
begin
    if rising_edge(FCLK_CLK0_PS)then
        if ext_clock(0) = '1' and sma_pll_locked = '1' then
            enable_sma_clock <= '1';
        else
            enable_sma_clock <= '0';    
        end if;    
    end if;
end process ps_sma_clk;
  
---------------------------------------------------------------------------
-- Event Receiver PLL   
---------------------------------------------------------------------------

-- Generate an input bufg
gen_ibufg : if no_ibufg = 0 generate
    clkin1_ibufg : bufg
        port map
            (O  => EVENTR_CLK_IN1,
             I  => RXOUTCLK
        );
end generate gen_ibufg;        

-- Don't generate an input bufg
gen_no_ibufg : if no_ibufg = 1 generate
    EVENTR_CLK_IN1 <= RXOUTCLK;
end generate gen_no_ibufg;  


-- Event Receiver PLL Clocking PRIMITIVE
--------------------------------------

eventr_plle2_adv_inst : PLLE2_ADV
    generic map
        (BANDWIDTH           => "OPTIMIZED",
        COMPENSATION         => "ZHOLD",
        DIVCLK_DIVIDE        => 1,
        CLKFBOUT_MULT        => 7,
        CLKFBOUT_PHASE       => 0.000,
        CLKOUT0_DIVIDE       => 7,
        CLKOUT0_PHASE        => 0.000,
        CLKOUT0_DUTY_CYCLE   => 0.500,
        CLKIN1_PERIOD        => 8.000)
    port map
        -- Output clocks
        (
        CLKFBOUT            => EVENTR_CLKFBOUT,
        CLKOUT0             => EVENTR_CLK_OUT1,
        CLKOUT1             => open,
        CLKOUT2             => open,
        CLKOUT3             => open,
        CLKOUT4             => open,
        CLKOUT5             => open,
        -- Input clock control
        CLKFBIN             => EVENTR_CLKFBOUT_BUF,
        CLKIN1              => EVENTR_CLK_IN1,
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
        LOCKED              => eventr_pll_locked,
        PWRDWN              => '0',
        RST                 => '0'
);
  
  
---------------------------------------------------------------------------
  -- Output buffering
---------------------------------------------------------------------------

eventr_clkf_buf : BUFG
    port map
        (O => EVENTR_CLKFBOUT_BUF,
         I => EVENTR_CLKFBOUT
);
  

---------------------------------------------------------------------------
-- Panda  event receiver clock switching
---------------------------------------------------------------------------

eventr_BUFGMUX_inst :BUFGMUX
    port map (
        O   => FCLK_CLK,            
        I0  => SMA_FCLK,            
        I1  => EVENTR_CLK_OUT1,      
        S   => enable_eventr_clock  
);
  
---------------------------------------------------------------------------

ps_eventr_clk: process(FCLK_CLK0_PS)
begin
    if rising_edge(FCLK_CLK0_PS)then
        if ext_clock(1) = '1' and eventr_pll_locked = '1' then
            enable_eventr_clock <= '1';
        else
            enable_eventr_clock <= '0';    
        end if;    
    end if;
end process ps_eventr_clk;
 


end architecture rtl;
