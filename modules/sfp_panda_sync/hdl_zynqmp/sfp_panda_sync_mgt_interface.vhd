library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

library unisim;
use unisim.vcomponents.all;

entity sfp_panda_sync_mgt_interface is

    port (
        GTREFCLK_i        : in  std_logic;
        SYNC_RESET_i      : in  std_logic;
        sysclk_i          : in  std_logic;
        rxp_i             : in  std_logic;
        rxn_i             : in  std_logic;
        txp_o             : out std_logic;
        txn_o             : out std_logic;
        rxdata_o          : out std_logic_vector(31 downto 0); 
        rxoutclk_o        : out std_logic;
        rxcharisk_o       : out std_logic_vector(3 downto 0); 
        rxdisperr_o       : out std_logic_vector(3 downto 0); 
        mgt_ready_o       : out std_logic;
        rxnotintable_o    : out std_logic_vector(3 downto 0); 
        txoutclk_o        : out std_logic;    
        txdata_i          : in  std_logic_vector(31 downto 0); 
        txcharisk_i       : in  std_logic_vector(3 downto 0);
        rx_link_ok_i      : in  std_logic
    );

end sfp_panda_sync_mgt_interface;

architecture rtl of sfp_panda_sync_mgt_interface is

constant DELAY_3ms : natural := 375_000; -- 3 ms at 125 MHz

signal TX_PMA_RESET_DONE_OUT        : std_logic;
signal RX_PMA_RESET_DONE_OUT        : std_logic;
signal gtwiz_reset_rx_done_out      : std_logic;
signal gtwiz_reset_tx_done_out      : std_logic;

signal TX_PMA_RESET_DONE_OUT_sync   : std_logic;
signal RX_PMA_RESET_DONE_OUT_sync   : std_logic;
signal gtwiz_reset_rx_done_out_sync : std_logic;
signal gtwiz_reset_tx_done_out_sync : std_logic;
signal init_rst                     : std_logic;

signal rxctrl0_int                  : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal rxctrl1_int                  : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal rxctrl2_int                  : std_logic_vector(7 DOWNTO 0);
signal rxctrl3_int                  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
begin

-- Assign outputs

rxcharisk_o    <= rxctrl0_int(3 downto 0);
rxdisperr_o    <= rxctrl1_int(3 downto 0);
rxnotintable_o <= rxctrl3_int(3 downto 0);

--synchronise signals from MGT clock domains
TX_FSM_RST_sync : entity work.sync_bit
    port map(
     clk_i => sysclk_i,
     bit_i => TX_PMA_RESET_DONE_OUT,
     bit_o => TX_PMA_RESET_DONE_OUT_sync
);

RX_FSM_RST_sync : entity work.sync_bit
    port map(
     clk_i => sysclk_i,
     bit_i => RX_PMA_RESET_DONE_OUT,
     bit_o => RX_PMA_RESET_DONE_OUT_sync
);

txreset_sync : entity work.sync_bit
    port map(
     clk_i => sysclk_i,
     bit_i => gtwiz_reset_rx_done_out,
     bit_o => gtwiz_reset_rx_done_out_sync
);

rxreset_sync : entity work.sync_bit
    port map(
     clk_i => sysclk_i,
     bit_i => gtwiz_reset_tx_done_out,
     bit_o => gtwiz_reset_tx_done_out_sync
);

-- Indicates when the link is up when the rx and tx reset have finished
ps_linkup: process(sysclk_i)
begin
    if rising_edge(sysclk_i) then
        if ( TX_PMA_RESET_DONE_OUT_sync and RX_PMA_RESET_DONE_OUT_sync and
             gtwiz_reset_rx_done_out_sync and gtwiz_reset_tx_done_out_sync) = '1' then
            mgt_ready_o <= '1';
        else
            mgt_ready_o <= '0';
        end if;
     end if;
 end process ps_linkup;

-- Hold MGT in reset for 3 ms after startup
-- See Xilinx AR#65199
startup_rst: process(sysclk_i)
  variable startup_ctr : unsigned(LOG2(DELAY_3ms) downto 0) := (others => '0');
begin
    if rising_edge(sysclk_i) then
        if startup_ctr = DELAY_3ms then
            init_rst <= '0';
        else
            init_rst <= '1';
            startup_ctr := startup_ctr + 1;
        end if;
    end if;
end process;

--======================================================================
--   CORE INSTANCE
--======================================================================


sfp_panda_sync_us_i : entity work.sfp_panda_sync_us
  PORT MAP (
    gtwiz_userclk_tx_reset_in(0) => '0',                                    -- Should be high until the source clock input is known to be stable.
    gtwiz_userclk_tx_srcclk_out => open,
    gtwiz_userclk_tx_usrclk_out(0) => txoutclk_o,
    gtwiz_userclk_tx_usrclk2_out => open,
    gtwiz_userclk_tx_active_out => open,
    gtwiz_userclk_rx_reset_in(0) => '0',                                    -- Should be high until the source clock input is known to be stable.
    gtwiz_userclk_rx_srcclk_out => open,
    gtwiz_userclk_rx_usrclk_out(0) => rxoutclk_o,
    gtwiz_userclk_rx_usrclk2_out => open,
    gtwiz_userclk_rx_active_out => open,
    gtwiz_reset_clk_freerun_in(0) => sysclk_i,
    gtwiz_reset_all_in(0) => SYNC_RESET_i,
    gtwiz_reset_tx_pll_and_datapath_in(0) => '0',
    gtwiz_reset_tx_datapath_in(0) => '0',
    gtwiz_reset_rx_pll_and_datapath_in(0) => '0',
    gtwiz_reset_rx_datapath_in(0) => init_rst,
    gtwiz_reset_rx_cdr_stable_out => open,
    gtwiz_reset_tx_done_out(0) => gtwiz_reset_tx_done_out,
    gtwiz_reset_rx_done_out(0) => gtwiz_reset_rx_done_out,
    gtwiz_userdata_tx_in => txdata_i,
    gtwiz_userdata_rx_out => rxdata_o,
    drpclk_in => "0",
    gthrxn_in(0) => rxn_i,
    gthrxp_in(0) => rxp_i,
    gtrefclk0_in(0) => GTREFCLK_i,
    rx8b10ben_in(0) => '1',
    rxcommadeten_in(0) => '1',
    rxmcommaalignen_in(0) => '1',
    rxpcommaalignen_in(0) => '1',
    tx8b10ben_in(0) => '1',
    txctrl0_in => (others => '0'),
    txctrl1_in => (others => '0'), 
    txctrl2_in(7 downto 4) => b"0000",
    txctrl2_in(3 downto 0) => txcharisk_i,
    gthtxn_out(0) => txn_o,
    gthtxp_out(0) => txp_o,
    gtpowergood_out => open,
    rxbyteisaligned_out(0) => open,
    rxbyterealign_out(0) => open,
    rxcommadet_out(0) => open,
    rxctrl0_out => rxctrl0_int,                     -- K character detect
    rxctrl1_out => rxctrl1_int,                     -- Rx data disparity error
    rxctrl2_out => rxctrl2_int,                     -- Comma detect (per byte)
    rxctrl3_out => rxctrl3_int,                     -- Char not valid in 8B/10B table
    rxpmaresetdone_out(0) => RX_PMA_RESET_DONE_OUT,
    txpmaresetdone_out(0) => TX_PMA_RESET_DONE_OUT
  );

end rtl;
