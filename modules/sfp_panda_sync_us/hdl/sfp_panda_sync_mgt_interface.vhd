library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity sfp_panda_sync_mgt_interface is

    port (
        GTREFCLK          : in  std_logic;
        SYNC_RESET_i      : in  std_logic;
        clk_i             : in  std_logic;
        rxoutclk_i        : in  std_logic;
        txoutclk_i        : in  std_logic;
        rxp_i             : in  std_logic;
        rxn_i             : in  std_logic;
        txp_o             : out std_logic;
        txn_o             : out std_logic;
        rxdatapathreset_i : in  std_logic;
        rxbyteisaligned_o : out std_logic;
        rxbyterealign_o   : out std_logic;
        rxcommadet_o      : out std_logic;
        rxdata_o          : out std_logic_vector(31 downto 0); 
        rxoutclk_o        : out std_logic;
        rxcharisk_o       : out std_logic_vector(3 downto 0); 
        rxdisperr_o       : out std_logic_vector(3 downto 0); 
        mgt_ready_o       : out std_logic;
        rxnotintable_o    : out std_logic_vector(3 downto 0); 
        txoutclk_o        : out std_logic;    
        txdata_i          : in  std_logic_vector(31 downto 0); 
        txcharisk_i       : in  std_logic_vector(3 downto 0)
    );

end sfp_panda_sync_mgt_interface;

architecture rtl of sfp_panda_sync_mgt_interface is

COMPONENT sfp_panda_sync_us
  PORT (
    gtwiz_userclk_tx_reset_in           : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_srcclk_out         : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_usrclk_out         : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_usrclk2_out        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_tx_active_out         : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_reset_in           : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_srcclk_out         : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_usrclk_out         : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_usrclk2_out        : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_active_out         : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_clk_freerun_in          : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_all_in                  : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_pll_and_datapath_in  : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_datapath_in          : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_pll_and_datapath_in  : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_datapath_in          : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_cdr_stable_out       : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_done_out             : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_done_out             : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userdata_tx_in                : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    gtwiz_userdata_rx_out               : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    drpclk_in                           : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthrxn_in                           : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthrxp_in                           : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtrefclk0_in                        : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rx8b10ben_in                        : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcommadeten_in                     : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxmcommaalignen_in                  : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpcommaalignen_in                  : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    tx8b10ben_in                        : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
    txctrl0_in                          : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    txctrl1_in                          : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    txctrl2_in                          : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    gthtxn_out                          : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthtxp_out                          : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtpowergood_out                     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxbyteisaligned_out                 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxbyterealign_out                   : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcommadet_out                      : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxctrl0_out                         : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rxctrl1_out                         : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rxctrl2_out                         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rxctrl3_out                         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rxpmaresetdone_out                  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpmaresetdone_out                  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;

signal TX_PMA_RESET_DONE_OUT     : std_logic;
signal RX_PMA_RESET_DONE_OUT     : std_logic;
signal gtwiz_reset_rx_done_out   : std_logic;
signal gtwiz_reset_tx_done_out   : std_logic;

signal rxctrl0_int          : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal rxctrl1_int          : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal rxctrl2_int          : std_logic_vector(7 DOWNTO 0);
signal rxctrl3_int          : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
begin

-- Indicates when the link is up when the rx and tx reset have finished
ps_linkup: process(clk_i)
begin
    if rising_edge(clk_i) then
        if ( TX_PMA_RESET_DONE_OUT and RX_PMA_RESET_DONE_OUT and
             gtwiz_reset_rx_done_out and gtwiz_reset_tx_done_out) = '1' then
            mgt_ready_o <= '1';
        else
            mgt_ready_o <= '0';
        end if;
     end if;
 end process ps_linkup;

rxcharisk_o    <= rxctrl0_int(3 downto 0);
rxdisperr_o    <= rxctrl1_int(3 downto 0);
rxnotintable_o <= rxctrl3_int(3 downto 0);

--======================================================================
--   CORE INSTANCE
--======================================================================


sfp_panda_sync_us_i : sfp_panda_sync_us
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
    gtwiz_reset_clk_freerun_in(0) => clk_i,
    gtwiz_reset_all_in(0) => SYNC_RESET_i,
    gtwiz_reset_tx_pll_and_datapath_in(0) => '0',
    gtwiz_reset_tx_datapath_in(0) => '0',
    gtwiz_reset_rx_pll_and_datapath_in(0) => '0',
    gtwiz_reset_rx_datapath_in(0) => rxdatapathreset_i,
    gtwiz_reset_rx_cdr_stable_out => open,
    gtwiz_reset_tx_done_out(0) => gtwiz_reset_tx_done_out,
    gtwiz_reset_rx_done_out(0) => gtwiz_reset_rx_done_out,
    gtwiz_userdata_tx_in => txdata_i,
    gtwiz_userdata_rx_out => rxdata_o,
    drpclk_in => "0",
    gthrxn_in(0) => rxn_i,
    gthrxp_in(0) => rxp_i,
    gtrefclk0_in(0) => GTREFCLK,
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
    rxbyteisaligned_out(0) => rxbyteisaligned_o,
    rxbyterealign_out(0) => rxbyterealign_o,
    rxcommadet_out(0) => rxcommadet_o,
    rxctrl0_out => rxctrl0_int,                     -- K character detect
    rxctrl1_out => rxctrl1_int,                     -- Rx data disparity error
    rxctrl2_out => rxctrl2_int,                     -- Comma detect (per byte)
    rxctrl3_out => rxctrl3_int,                     -- Char not valid in 8B/10B table
    rxpmaresetdone_out(0) => RX_PMA_RESET_DONE_OUT,
    txpmaresetdone_out(0) => TX_PMA_RESET_DONE_OUT
  );

end rtl;
