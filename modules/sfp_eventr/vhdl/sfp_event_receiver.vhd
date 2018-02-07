library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;


entity sfp_event_receiver is
    port (GTREFCLK_P        : in  std_logic;
          GTREFCLK_N        : in  std_logic;    
          ER_RESET          : in  std_logic;
          eventr_clk        : in  std_logic;
          eventr_pll_locked : in  std_logic;
          rxp_i             : in  std_logic;
          rxn_i             : in  std_logic;
          txp_o             : out std_logic; 
          txn_o             : out std_logic; 
          rxbyteisaligned_o : out std_logic;
          rxbyterealign_o   : out std_logic;
          rxcommadet_o      : out std_logic;
          rxdata_o          : out std_logic_vector(15 downto 0);
          rxoutclk_o        : out std_logic;
          rxcharisk_o       : out std_logic_vector(1 downto 0);
          rxdisperr_o       : out std_logic_vector(1 downto 0);
          mgt_ready_o       : out std_logic;
          rxnotintable_o    : out std_logic_vector(1 downto 0)     
          );

end sfp_event_receiver;



architecture rtl of sfp_event_receiver is
 

component event_receiver_mgt 
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
    gt0_rxdata_out                          : out  std_logic_vector(15 downto 0);
    ------------------ Receive Ports - RX 8B/10B Decoder Ports
    gt0_rxdisperr_out                       : out  std_logic_vector(1 downto 0);
    gt0_rxnotintable_out                    : out  std_logic_vector(1 downto 0); 
    --------------------------- Receive Ports - RX AFE -------------------------
    gt0_gtxrxp_in                           : in   std_logic;
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt0_gtxrxn_in                           : in   std_logic;
    -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
    gt0_rxbyteisaligned_out                 : out std_logic;                        -- new
    gt0_rxbyterealign_out                   : out std_logic;                        -- new
    gt0_rxcommadet_out                      : out std_logic; 
    gt0_rxmcommaalignen_in                  : in  std_logic;                        -- new    
    gt0_rxpcommaalignen_in                  : in  std_logic;                        -- new
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt0_rxdfelpmreset_in                    : in   std_logic;
    gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt0_rxoutclk_out                        : out  std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt0_gtrxreset_in                        : in   std_logic;
    gt0_rxpmareset_in                       : in   std_logic;
    ---------------------- Receive Ports - RX gearbox ports --------------------
--    gt0_rxslide_in                          : in   std_logic;
    ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
    gt0_rxcharisk_out                       : out  std_logic_vector(1 downto 0);       
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt0_rxresetdone_out                     : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt0_gttxreset_in                        : in   std_logic;
    gt0_txuserrdy_in                        : in   std_logic;
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
    gt0_txusrclk_in                         : in   std_logic;
    gt0_txusrclk2_in                        : in   std_logic;
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt0_txdata_in                           : in   std_logic_vector(15 downto 0);
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt0_gtxtxn_out                          : out  std_logic;
    gt0_gtxtxp_out                          : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt0_txoutclk_out                        : out  std_logic;
    gt0_txoutclkfabric_out                  : out  std_logic;
    gt0_txoutclkpcs_out                     : out  std_logic;
    -------------------- Transmit Ports - TX Gearbox Ports ---------------------
    gt0_txcharisk_in                        : in   std_logic_vector(1 downto 0);
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt0_txresetdone_out                     : out  std_logic;
    --____________________________COMMON PORTS________________________________
     GT0_QPLLOUTCLK_IN  : in std_logic;
     GT0_QPLLOUTREFCLK_IN : in std_logic
    );

end component; 

ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
ATTRIBUTE SYN_BLACK_BOX OF event_receiver_mgt : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;
ATTRIBUTE BLACK_BOX_PAD_PIN OF event_receiver_mgt : COMPONENT IS "SYSCLK_IN,SOFT_RESET_TX_IN,SOFT_RESET_RX_IN,DONT_RESET_ON_DATA_ERROR_IN,GT0_TX_FSM_RESET_DONE_OUT,GT0_RX_FSM_RESET_DONE_OUT,GT0_DATA_VALID_IN,gt0_cpllfbclklost_out,gt0_cplllock_out, gt0_cplllockdetclk_in,gt0_cpllreset_in,gt0_gtrefclk0_in,gt0_gtrefclk1_in,gt0_drpaddr_in,gt0_drpclk_in,gt0_drpdi_in,gt0_drpdo_out,gt0_drpen_in,gt0_drprdy_out,gt0_drpwe_in,gt0_dmonitorout_out, gt0_eyescanreset_in,gt0_rxuserrdy_in,gt0_eyescandataerror_out,gt0_eyescantrigger_in,gt0_rxusrclk_in,gt0_rxusrclk2_in,gt0_rxdata_out,gt0_rxdisperr_out,gt0_rxnotintable_out,gt0_gtxrxp_in, gt0_gtxrxn_in,    gt0_rxbyteisaligned_out,gt0_rxbyterealign_out,gt0_rxcommadet_out,gt0_rxmcommaalignen_in,gt0_rxpcommaalignen_in,gt0_rxdfelpmreset_in,gt0_rxmonitorout_out,gt0_rxmonitorsel_in,gt0_rxoutclk_out, gt0_gtrxreset_in,gt0_rxpmareset_in,gt0_rxcharisk_out,gt0_rxresetdone_out,gt0_gttxreset_in,gt0_txuserrdy_in,gt0_txusrclk_in,gt0_txusrclk2_in,gt0_txdata_in,gt0_gtxtxn_out,gt0_gtxtxp_out,gt0_txoutclk_out, gt0_txoutclkfabric_out,gt0_txoutclkpcs_out, gt0_txcharisk_in gt0_txresetdone_out,GT0_QPLLOUTCLK_IN,GT0_QPLLOUTREFCLK_IN";
      

signal GT0_TX_FSM_RESET_DONE_OUT     : std_logic;
signal GT0_RX_FSM_RESET_DONE_OUT     : std_logic;
signal data_valid                    : std_logic;    
signal gt0_cpllfbclklost_out         : std_logic;
signal gt0_cplllock_out              : std_logic;
signal gt0_drpdo_out                 : std_logic_vector(15 downto 0);
signal gt0_drprdy_out                : std_logic;
signal gt0_dmonitorout_out           : std_logic_vector(7 downto 0);
signal gt0_eyescandataerror_out      : std_logic;
signal gt0_rxdata_out                : std_logic_vector(15 downto 0);
signal gt0_rxdisperr_out             : std_logic_vector(1 downto 0);
signal gt0_rxnotintable_out          : std_logic_vector(1 downto 0);
signal gt0_rxmonitorout_out          : std_logic_vector(6 downto 0);
signal gt0_rxcharisk_out             : std_logic_vector(1 downto 0);
signal gt0_rxresetdone_out           : std_logic;
signal gt0_txdata_in                 : std_logic_vector(15 downto 0);
signal gt0_txoutclk_out              : std_logic;
signal gt0_txoutclkfabric_out        : std_logic;
signal gt0_txoutclkpcs_out           : std_logic;
signal gt0_txresetdone_out           : std_logic;
signal gt0_rxbyteisaligned_out       : std_logic;
signal gt0_rxbyterealign_out         : std_logic;
signal gt0_rxcommadet_out            : std_logic;
signal gt0_qplloutclk_in             : std_logic;
signal gt0_qplloutrefclk_in          : std_logic;
signal txcharisk_i                   : std_logic_vector(1 downto 0);   
signal tied_to_ground_i              : std_logic;

attribute syn_noclockbuf             : boolean;
signal GTREFCLK                      : std_logic;
attribute syn_noclockbuf of GTREFCLK : signal is true;


begin

rxcharisk_o <= gt0_rxcharisk_out;
rxdisperr_o <= gt0_rxdisperr_out;

-- Comma detection signals for debug
rxbyteisaligned_o <= gt0_rxbyteisaligned_out;
rxbyterealign_o <= gt0_rxbyterealign_out;
rxcommadet_o <= gt0_rxcommadet_out;

rxdata_o <= gt0_rxdata_out; 

rxnotintable_o <= gt0_rxnotintable_out;


txcharisk_i <= (others => '0');

tied_to_ground_i <= '0';

-- IBUFDS_GTE2  MGT differential clock
gtrefclk_ibufgds : IBUFDS_GTE2
    port map
        (O     => GTREFCLK,
         ODIV2 => open,
         CEB   => tied_to_ground_i,
         I     => GTREFCLK_P,
         IB    => GTREFCLK_N
);


-- Indicates when the link is up when the rx and tx reset have finished 
ps_linkup: process(GTREFCLK)
begin
    if rising_edge(GTREFCLK) then
        if ( GT0_TX_FSM_RESET_DONE_OUT and GT0_RX_FSM_RESET_DONE_OUT and 
             gt0_rxresetdone_out and gt0_txresetdone_out and eventr_pll_locked) = '1' then
            mgt_ready_o <= '1';
        else
            mgt_ready_o <= '0';
        end if;
     end if;
 end process ps_linkup;               
  

-- Must be set high 
data_valid <= '1';


-- TX data
gt0_txdata_in <= (others => '0');


-- If connected causes build to fail
gt0_qplloutclk_in <= '0';
gt0_qplloutrefclk_in <= '0';


event_receiver_mgt_inst : event_receiver_mgt
    port map
        (
        SYSCLK_IN                   => GTREFCLK,
        SOFT_RESET_TX_IN            => ER_RESET,
        SOFT_RESET_RX_IN            => ER_RESET,
        DONT_RESET_ON_DATA_ERROR_IN => '0',
        GT0_TX_FSM_RESET_DONE_OUT   => GT0_TX_FSM_RESET_DONE_OUT,
        GT0_RX_FSM_RESET_DONE_OUT   => GT0_RX_FSM_RESET_DONE_OUT,
        GT0_DATA_VALID_IN           => data_valid,
        --_________________________________________________________________________
        --GT0  (X0Y1)
        --____________________________CHANNEL PORTS________________________________
        --------------------------------- CPLL Ports -------------------------------
        gt0_cpllfbclklost_out       => gt0_cpllfbclklost_out,
        gt0_cplllock_out            => gt0_cplllock_out,
        gt0_cplllockdetclk_in       => '0',
        gt0_cpllreset_in            => ER_RESET,                                         
        -------------------------- Channel - Clocking Ports ------------------------
        gt0_gtrefclk0_in            => '0',
        gt0_gtrefclk1_in            => GTREFCLK,
        ---------------------------- Channel - DRP Ports  --------------------------
        gt0_drpaddr_in              => (others => '0'),
        gt0_drpclk_in               => '0',
        gt0_drpdi_in                => (others => '0'),
        gt0_drpdo_out               => gt0_drpdo_out,
        gt0_drpen_in                => '0',
        gt0_drprdy_out              => gt0_drprdy_out,
        gt0_drpwe_in                => '0',
        --------------------------- Digital Monitor Ports --------------------------
        gt0_dmonitorout_out         => gt0_dmonitorout_out,
        --------------------- RX Initialization and Reset Ports --------------------
        gt0_eyescanreset_in         => '0',
        gt0_rxuserrdy_in            => eventr_pll_locked,  
        -------------------------- RX Margin Analysis Ports ------------------------
        gt0_eyescandataerror_out    => gt0_eyescandataerror_out,
        gt0_eyescantrigger_in       => '0',
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        gt0_rxusrclk_in             => eventr_clk,
        gt0_rxusrclk2_in            => eventr_clk,
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        gt0_rxdata_out              => gt0_rxdata_out,
        ----------------- Receiver Ports - RX 8B/10B Decoder Ports -----------------
        gt0_rxdisperr_out           => gt0_rxdisperr_out,                                                              
        gt0_rxnotintable_out        => gt0_rxnotintable_out,                                                             
        --------------------------- Receive Ports - RX AFE -------------------------
        gt0_gtxrxp_in               => rxp_i,
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        gt0_gtxrxn_in               => rxn_i,
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        gt0_rxbyteisaligned_out     => gt0_rxbyteisaligned_out,
        gt0_rxbyterealign_out       => gt0_rxbyterealign_out,       
        gt0_rxcommadet_out          => gt0_rxcommadet_out,
        gt0_rxmcommaalignen_in      => '1',
        gt0_rxpcommaalignen_in      => '1',
        --------------------- Receive Ports - RX Equalizer Ports -------------------
        gt0_rxdfelpmreset_in        => '0',                            
        gt0_rxmonitorout_out        => gt0_rxmonitorout_out,
        gt0_rxmonitorsel_in         => (others => '0'),
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        gt0_rxoutclk_out            => rxoutclk_o,
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        gt0_gtrxreset_in            => ER_RESET,
        gt0_rxpmareset_in           => '0',
        ---------------------- Receive Ports - RX gearbox ports --------------------
--        gt0_rxslide_in              => '0',
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        gt0_rxcharisk_out           => gt0_rxcharisk_out,        
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        gt0_rxresetdone_out         => gt0_rxresetdone_out,
        --------------------- TX Initialization and Reset Ports --------------------
        gt0_gttxreset_in            => ER_RESET,
        gt0_txuserrdy_in            => eventr_pll_locked,
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        gt0_txusrclk_in             => eventr_clk,
        gt0_txusrclk2_in            => eventr_clk,
        ------------------ Transmit Ports - TX Data Path interface -----------------
        gt0_txdata_in               => gt0_txdata_in,
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        gt0_gtxtxn_out              => txn_o,
        gt0_gtxtxp_out              => txp_o,
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        gt0_txoutclk_out            => gt0_txoutclk_out,
        gt0_txoutclkfabric_out      => gt0_txoutclkfabric_out,
        gt0_txoutclkpcs_out         => gt0_txoutclkpcs_out,
        ----------------- Transmit Port - TX Gearbox Port
        gt0_txcharisk_in            => txcharisk_i,                                                                 
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        gt0_txresetdone_out         => gt0_txresetdone_out,
        --____________________________COMMON PORTS________________________________
        GT0_QPLLOUTCLK_IN           => gt0_qplloutclk_in,
        GT0_QPLLOUTREFCLK_IN        => gt0_qplloutrefclk_in 
        );

end rtl;
