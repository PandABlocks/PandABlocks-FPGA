library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;


entity sfp_panda_sync_mgt_interface is

    port (GTREFCLK          : in  std_logic;
          SYNC_RESET_i      : in  std_logic;
          clk_i             : in  std_logic;
          rxoutclk_i        : in  std_logic;
          txoutclk_i        : in  std_logic;
          rxp_i             : in  std_logic;
          rxn_i             : in  std_logic;
          txp_o             : out std_logic;
          txn_o             : out std_logic;
          rxuserrdy_i       : in  std_logic;
          txuserrdy_i       : in  std_logic;
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


component sfp_panda_sync 
port
    (
    SYSCLK_IN                               : in   std_logic;
    SOFT_RESET_TX_IN                        : in   std_logic;
    SOFT_RESET_RX_IN                        : in   std_logic;
    DONT_RESET_ON_DATA_ERROR_IN             : in   std_logic;
    GT0_TX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT0_RX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT0_DATA_VALID_IN                       : in   std_logic;
    --_________________________________________________________________________
    --GT0  (X0Y1)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt0_cpllfbclklost_out                   : out  std_logic;
    gt0_cplllock_out                        : out  std_logic;
    gt0_cplllockdetclk_in                   : in   std_logic;
    gt0_cpllreset_in                        : in   std_logic;
    -------------------------- Channel - Clocking Ports ------------------------
    gt0_gtrefclk0_in                        : in   std_logic;
    gt0_gtrefclk1_in                        : in   std_logic;
    ---------------------------- Channel - DRP Ports  --------------------------
    gt0_drpaddr_in                          : in   std_logic_vector(8 downto 0);
    gt0_drpclk_in                           : in   std_logic;
    gt0_drpdi_in                            : in   std_logic_vector(15 downto 0);
    gt0_drpdo_out                           : out  std_logic_vector(15 downto 0);
    gt0_drpen_in                            : in   std_logic;
    gt0_drprdy_out                          : out  std_logic;
    gt0_drpwe_in                            : in   std_logic;
    --------------------------- Digital Monitor Ports --------------------------
    gt0_dmonitorout_out                     : out  std_logic_vector(7 downto 0);
    --------------------- RX Initialization and Reset Ports --------------------
    gt0_eyescanreset_in                     : in   std_logic;
    gt0_rxuserrdy_in                        : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt0_eyescandataerror_out                : out  std_logic;
    gt0_eyescantrigger_in                   : in   std_logic;
    ------------------ Receive Ports - FPGA RX Interface Ports -----------------
    gt0_rxusrclk_in                         : in   std_logic;
    gt0_rxusrclk2_in                        : in   std_logic;
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt0_rxdata_out                          : out  std_logic_vector(31 downto 0);
    ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
    gt0_rxdisperr_out                       : out  std_logic_vector(3 downto 0);
    gt0_rxnotintable_out                    : out  std_logic_vector(3 downto 0);
    --------------------------- Receive Ports - RX AFE -------------------------
    gt0_gtxrxp_in                           : in   std_logic;
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt0_gtxrxn_in                           : in   std_logic;
    -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
    gt0_rxbyteisaligned_out                 : out  std_logic;
    gt0_rxbyterealign_out                   : out  std_logic;
    gt0_rxcommadet_out                      : out  std_logic;
    gt0_rxmcommaalignen_in                  : in   std_logic;
    gt0_rxpcommaalignen_in                  : in   std_logic;
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt0_rxdfelpmreset_in                    : in   std_logic;
    gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt0_rxoutclk_out                        : out  std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt0_gtrxreset_in                        : in   std_logic;
    gt0_rxpmareset_in                       : in   std_logic;
    ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
    gt0_rxcharisk_out                       : out  std_logic_vector(3 downto 0);
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt0_rxresetdone_out                     : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt0_gttxreset_in                        : in   std_logic;
    gt0_txuserrdy_in                        : in   std_logic;
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
    gt0_txusrclk_in                         : in   std_logic;
    gt0_txusrclk2_in                        : in   std_logic;
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt0_txdata_in                           : in   std_logic_vector(31 downto 0);
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt0_gtxtxn_out                          : out  std_logic;
    gt0_gtxtxp_out                          : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt0_txoutclk_out                        : out  std_logic;
    gt0_txoutclkfabric_out                  : out  std_logic;
    gt0_txoutclkpcs_out                     : out  std_logic;
    --------------------- Transmit Ports - TX Gearbox Ports --------------------
    gt0_txcharisk_in                        : in   std_logic_vector(3 downto 0);
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt0_txresetdone_out                     : out  std_logic;
    --____________________________COMMON PORTS________________________________
     GT0_QPLLOUTCLK_IN                      : in std_logic;
     GT0_QPLLOUTREFCLK_IN                   : in std_logic

);

end component;

ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
ATTRIBUTE SYN_BLACK_BOX OF sfp_panda_sync : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;
ATTRIBUTE BLACK_BOX_PAD_PIN OF sfp_panda_sync : COMPONENT IS 
"SYSCLK_IN,SOFT_RESET_TX_IN,SOFT_RESET_RX_IN,DONT_RESET_ON_DATA_ERROR_IN,GT0_TX_FSM_RESET_DONE_OUT,GT0_RX_FSM_RESET_DONE_OUT,GT0_DATA_VALID_IN,gt0_cpllfbclklost_out,gt0_cplllock_out,gt0_cplllockdetclk_in, gt0_cpllreset_in,gt0_gtrefclk0_in,gt0_gtrefclk1_in,gt0_drpaddr_in,gt0_drpclk_in,gt0_drpdi_in,gt0_drpdo_out,gt0_drpen_in,gt0_drprdy_out,gt0_drpwe_in,gt0_dmonitorout_out,gt0_eyescanreset_in,gt0_rxuserrdy_in, gt0_eyescandataerror_out,gt0_eyescantrigger_in,gt0_rxusrclk_in,gt0_rxusrclk2_in,gt0_rxdata_out,gt0_rxdisperr_out,gt0_rxnotintable_out,gt0_gtxrxp_in,gt0_gtxrxn_in,gt0_rxbyteisaligned_out,gt0_rxbyterealign_out, gt0_rxcommadet_out,gt0_rxmcommaalignen_in,gt0_rxpcommaalignen_in,gt0_rxdfelpmreset_in,gt0_rxmonitorout_out,gt0_rxmonitorsel_in,gt0_rxoutclk_out,gt0_gtrxreset_in,gt0_rxpmareset_in,gt0_rxcharisk_out, gt0_rxresetdone_out,gt0_gttxreset_in,gt0_txuserrdy_in,gt0_txusrclk_in,gt0_txusrclk2_in,gt0_txdata_in,gt0_gtxtxn_out,gt0_gtxtxp_out,gt0_txoutclk_out,gt0_txoutclkfabric_out,gt0_txoutclkpcs_out,gt0_txcharisk_in,          gt0_txresetdone_out,GT0_QPLLOUTCLK_IN,GT0_QPLLOUTREFCLK_IN";



signal GT0_TX_FSM_RESET_DONE_OUT     : std_logic;
signal GT0_RX_FSM_RESET_DONE_OUT     : std_logic;
signal gt0_cpllfbclklost_out         : std_logic;
signal gt0_cplllock_out              : std_logic;
signal gt0_drpdo_out                 : std_logic_vector(15 downto 0); 
signal gt0_drprdy_out                : std_logic;
signal gt0_dmonitorout_out           : std_logic_vector(7 downto 0);
signal gt0_eyescandataerror_out      : std_logic;
signal gt0_rxmonitorout_out          : std_logic_vector(6 downto 0);
signal gt0_rxresetdone_out           : std_logic;
signal gt0_txoutclkfabric_out        : std_logic;
signal gt0_txoutclkpcs_out           : std_logic;
signal gt0_txresetdone_out           : std_logic;

begin

-- Indicates when the link is up when the rx and tx reset have finished
ps_linkup: process(clk_i)
begin
    if rising_edge(clk_i) then
        if ( GT0_TX_FSM_RESET_DONE_OUT and GT0_RX_FSM_RESET_DONE_OUT and
             gt0_rxresetdone_out and gt0_txresetdone_out) = '1' then
            mgt_ready_o <= '1';
        else
            mgt_ready_o <= '0';
        end if;
     end if;
 end process ps_linkup;


-- ####################################################################################### --
-- clks
-- ####################################################################################### --
--
-- gt0_txusrclk_in  -> txoutclk [Derived from the MGTFRECLK0[P/N]
-- gt0_txursclk2_in -> txoutclk [Derived from the MGTFRECLK0[P/N]
--
-- gt0_rxusrclk_in  -> rxoutclk [Recovered clock]
-- gt0_rxusrclk2_in -> rxoutclk [Recovered clock]



sfp_panda_sync_i : sfp_panda_sync
    port map(
        SYSCLK_IN                       => GTREFCLK,
        SOFT_RESET_TX_IN                => SYNC_RESET_i,
        SOFT_RESET_RX_IN                => SYNC_RESET_i,
        DONT_RESET_ON_DATA_ERROR_IN     => '0',
        GT0_TX_FSM_RESET_DONE_OUT       => GT0_TX_FSM_RESET_DONE_OUT,
        GT0_RX_FSM_RESET_DONE_OUT       => GT0_RX_FSM_RESET_DONE_OUT,
        GT0_DATA_VALID_IN               => '1', -- The data valid has to be high for the receiver to come out of it reset startup 
        --_________________________________________________________________________
        --GT0  (X0Y1)
        --____________________________CHANNEL PORTS________________________________
        --------------------------------- CPLL Ports -------------------------------
        gt0_cpllfbclklost_out           => gt0_cpllfbclklost_out,
        gt0_cplllock_out                => gt0_cplllock_out,
        gt0_cplllockdetclk_in           => '0',
        gt0_cpllreset_in                => SYNC_RESET_i,
        -------------------------- Channel - Clocking Ports ------------------------
        gt0_gtrefclk0_in                => '0',
        gt0_gtrefclk1_in                => GTREFCLK,
        ---------------------------- Channel - DRP Ports  --------------------------
        gt0_drpaddr_in                  => (others => '0'),
        gt0_drpclk_in                   => '0',
        gt0_drpdi_in                    => (others => '0'),
        gt0_drpdo_out                   => gt0_drpdo_out,
        gt0_drpen_in                    => '0',
        gt0_drprdy_out                  => gt0_drprdy_out,
        gt0_drpwe_in                    => '0',
        --------------------------- Digital Monitor Ports --------------------------
        gt0_dmonitorout_out             => gt0_dmonitorout_out,
        --------------------- RX Initialization and Reset Ports --------------------
        gt0_eyescanreset_in             => '0',
        gt0_rxuserrdy_in                => rxuserrdy_i,
        -------------------------- RX Margin Analysis Ports ------------------------
        gt0_eyescandataerror_out        => gt0_eyescandataerror_out,
        gt0_eyescantrigger_in           => '0',
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        gt0_rxusrclk_in                 => rxoutclk_i,                           
        gt0_rxusrclk2_in                => rxoutclk_i,                           
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        gt0_rxdata_out                  => rxdata_o,
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        gt0_rxdisperr_out               => rxdisperr_o,
        gt0_rxnotintable_out            => rxnotintable_o,
        --------------------------- Receive Ports - RX AFE -------------------------
        gt0_gtxrxp_in                   => rxp_i,
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        gt0_gtxrxn_in                   => rxn_i,
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        gt0_rxbyteisaligned_out         => rxbyteisaligned_o,
        gt0_rxbyterealign_out           => rxbyterealign_o,
        gt0_rxcommadet_out              => rxcommadet_o,
        gt0_rxmcommaalignen_in          => '1',
        gt0_rxpcommaalignen_in          => '1',
        --------------------- Receive Ports - RX Equalizer Ports -------------------
        gt0_rxdfelpmreset_in            => '0',
        gt0_rxmonitorout_out            => gt0_rxmonitorout_out,
        gt0_rxmonitorsel_in             => (others => '0'),
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        gt0_rxoutclk_out                => rxoutclk_o,
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt0_gtrxreset_in                => SYNC_RESET_i,
        gt0_rxpmareset_in               => '0',
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        gt0_rxcharisk_out               => rxcharisk_o,
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        gt0_rxresetdone_out             => gt0_rxresetdone_out,
        --------------------- TX Initialization and Reset Ports --------------------
        gt0_gttxreset_in                => SYNC_RESET_i,
        gt0_txuserrdy_in                => txuserrdy_i,
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        gt0_txusrclk_in                 => txoutclk_i,                           -- transmit clk This port is used to provide a clock for the internal TX PCS datapath
        gt0_txusrclk2_in                => txoutclk_i,                           -- transmit clk This port is used to synchronzie the FPGA logic with the TX interface. 
                                                                                 -- This clock must be positive edge aligned to TXUSRCLK when TXUSRCLK is provided by the user
        ------------------ Transmit Ports - TX Data Path interface -----------------
        gt0_txdata_in                   => txdata_i,
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        gt0_gtxtxn_out                  => txn_o,
        gt0_gtxtxp_out                  => txp_o,
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        gt0_txoutclk_out                => txoutclk_o,                                  -- Derived from the GTFRECLK_P or GTFREFCLK_N recommmend clock to clock FPGA logic
        gt0_txoutclkfabric_out          => gt0_txoutclkfabric_out,
        gt0_txoutclkpcs_out             => gt0_txoutclkpcs_out,
        --------------------- Transmit Ports - TX Gearbox Ports --------------------
        gt0_txcharisk_in                => txcharisk_i,
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        gt0_txresetdone_out             => gt0_txresetdone_out,
        --____________________________COMMON PORTS________________________________
        GT0_QPLLOUTCLK_IN               => '0',
        GT0_QPLLOUTREFCLK_IN            => '0' 

);

end rtl;
