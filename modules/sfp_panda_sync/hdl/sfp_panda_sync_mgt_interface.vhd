library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;


entity sfp_panda_sync_mgt_interface is

    port (GTREFCLK          : in  std_logic;
          SYNC_RESET_i      : in  std_logic;
          sysclk_i             : in  std_logic;
          rxoutclk_i        : in  std_logic;
          txoutclk_i        : in  std_logic;
          rxp_i             : in  std_logic;
          rxn_i             : in  std_logic;
          txp_o             : out std_logic;
          txn_o             : out std_logic;
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
          txcharisk_i       : in  std_logic_vector(3 downto 0);
          cpll_lock_o       : out std_logic
          );

end sfp_panda_sync_mgt_interface;



architecture rtl of sfp_panda_sync_mgt_interface is

COMPONENT PICXO_FRACXO
  PORT (
    RESET_I : IN STD_LOGIC;
    REF_CLK_I : IN STD_LOGIC;
    TXOUTCLK_I : IN STD_LOGIC;
    DRPEN_O : OUT STD_LOGIC;
    DRPWEN_O : OUT STD_LOGIC;
    DRPDO_I : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    DRPDATA_O : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    DRPADDR_O : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    DRPRDY_I : IN STD_LOGIC;
    RSIGCE_I : IN STD_LOGIC;
    VSIGCE_I : IN STD_LOGIC;
    VSIGCE_O : OUT STD_LOGIC;
    ACC_STEP : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    G1 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    G2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    R : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    V : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    CE_DSP_RATE : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    C_I : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    P_I : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    N_I : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    OFFSET_PPM : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
    OFFSET_EN : IN STD_LOGIC;
    HOLD : IN STD_LOGIC;
    DON_I : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    DRP_USER_REQ_I : IN STD_LOGIC;
    DRP_USER_DONE_I : IN STD_LOGIC;
    DRPEN_USER_I : IN STD_LOGIC;
    DRPWEN_USER_I : IN STD_LOGIC;
    DRPADDR_USER_I : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    DRPDATA_USER_I : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    DRPDATA_USER_O : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    DRPRDY_USER_O : OUT STD_LOGIC;
    DRPBUSY_O : OUT STD_LOGIC;
    ACC_DATA : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    ERROR_O : OUT STD_LOGIC_VECTOR(20 DOWNTO 0);
    VOLT_O : OUT STD_LOGIC_VECTOR(21 DOWNTO 0);
    DRPDATA_SHORT_O : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    CE_PI_O : OUT STD_LOGIC;
    CE_PI2_O : OUT STD_LOGIC;
    CE_DSP_O : OUT STD_LOGIC;
    OVF_PD : OUT STD_LOGIC;
    OVF_AB : OUT STD_LOGIC;
    OVF_VOLT : OUT STD_LOGIC;
    OVF_INT : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT picxo_ila
  PORT (
    clk    : IN STD_LOGIC;
    probe0 : IN STD_LOGIC_VECTOR(20 DOWNTO 0);
    probe1 : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
    probe2 : IN STD_LOGIC_VECTOR(7  DOWNTO 0);
    probe3 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe4 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe5 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe6 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe7 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe8 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe9 : IN STD_LOGIC_VECTOR(0  DOWNTO 0)
  );
END COMPONENT;

COMPONENT picxo_vio
  PORT (
    clk : IN STD_LOGIC;
    probe_out0  : OUT STD_LOGIC_VECTOR(4  DOWNTO 0);
    probe_out1  : OUT STD_LOGIC_VECTOR(4  DOWNTO 0);
    probe_out2  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe_out3  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe_out4  : OUT STD_LOGIC_VECTOR(3  DOWNTO 0);
    probe_out5  : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    probe_out6  : OUT STD_LOGIC_VECTOR(21 DOWNTO 0);
    probe_out7  : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe_out8  : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe_out9  : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe_out10 : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe_out11 : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
    probe_out12 : OUT STD_LOGIC_VECTOR(6  DOWNTO 0);
    probe_out13 : OUT STD_LOGIC_VECTOR(9  DOWNTO 0);
    probe_out14 : OUT STD_LOGIC_VECTOR(9  DOWNTO 0)
  );
END COMPONENT;



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

signal GT0_TX_FSM_RESET_DONE_OUT_sync   : std_logic;
signal GT0_RX_FSM_RESET_DONE_OUT_sync   : std_logic;
signal gt0_txresetdone_out_sync         : std_logic;
signal gt0_rxresetdone_out_sync         : std_logic;

-- PICXO signals

signal gt0_drpen_i : std_logic;
signal gt0_drpwe_i : std_logic;
signal gt0_drpdi_i : std_logic_vector(15 downto 0);
signal gt0_drpaddr_i : std_logic_vector(8 downto 0);

signal  G1                              : STD_LOGIC_VECTOR (4 downto 0) ;
signal  G2                              : STD_LOGIC_VECTOR (4 downto 0) ;
signal  R                               : STD_LOGIC_VECTOR (15 downto 0);
signal  V                               : STD_LOGIC_VECTOR (15 downto 0);
signal  ce_dsp_rate                     : std_logic_vector (23 downto 0);
signal  C                               : STD_LOGIC_VECTOR (6 downto 0) ;
signal  P                               : STD_LOGIC_VECTOR (9 downto 0) ;
signal  N                               : STD_LOGIC_VECTOR (9 downto 0) ;
signal  don                             : STD_LOGIC_VECTOR (0 downto 0) ;

signal  Offset_ppm                      : std_logic_vector (21 downto 0);
signal  Offset_en                       : std_logic                     ;
signal  hold                            : std_logic                     ;
signal  acc_step                        : STD_LOGIC_VECTOR (3 downto 0);

signal error_o                          : STD_LOGIC_VECTOR (20 downto 0) ;
signal volt_o                           : STD_LOGIC_VECTOR (21 downto 0) ;
signal drpdata_short_o                  : STD_LOGIC_VECTOR (7  downto 0) ;
signal ce_pi_o                          : STD_LOGIC ;
signal ce_pi2_o                         : STD_LOGIC ;
signal ce_dsp_o                         : STD_LOGIC ;
signal ovf_pd                           : STD_LOGIC ;
signal ovf_ab                           : STD_LOGIC ;
signal ovf_volt                         : STD_LOGIC ;
signal ovf_int                          : STD_LOGIC ;

signal    picxo_rst                     : std_logic_vector(7 downto 0) := (others =>'0');
attribute shreg_extract                 : string;
attribute equivalent_register_removal   : string;
attribute shreg_extract of picxo_rst                  : signal is "no";
attribute equivalent_register_removal of picxo_rst    : signal is "no"; 

begin

cpll_lock_o <= gt0_cplllock_out;

--synchronise signals from MGT clock domains
TX_FSM_RST_sync : entity work.sync_bit
    port map(
     clk_i => sysclk_i,
     bit_i => GT0_TX_FSM_RESET_DONE_OUT,
     bit_o => GT0_TX_FSM_RESET_DONE_OUT_sync
);

RX_FSM_RST_sync : entity work.sync_bit
    port map(
     clk_i => sysclk_i,
     bit_i => GT0_RX_FSM_RESET_DONE_OUT,
     bit_o => GT0_RX_FSM_RESET_DONE_OUT_sync
);

txreset_sync : entity work.sync_bit
    port map(
     clk_i => sysclk_i,
     bit_i => gt0_txresetdone_out,
     bit_o => gt0_txresetdone_out_sync
);

rxreset_sync : entity work.sync_bit
    port map(
     clk_i => sysclk_i,
     bit_i => gt0_rxresetdone_out,
     bit_o => gt0_rxresetdone_out_sync
);


-- Indicates when the link is up when the rx and tx reset have finished
ps_linkup: process(sysclk_i)
begin
    if rising_edge(sysclk_i) then  
        if ( GT0_TX_FSM_RESET_DONE_OUT_sync and GT0_RX_FSM_RESET_DONE_OUT_sync and
             gt0_rxresetdone_out_sync and gt0_txresetdone_out_sync) = '1' then
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
        gt0_cplllockdetclk_in           => sysclk_i,
        gt0_cpllreset_in                => '0',
        -------------------------- Channel - Clocking Ports ------------------------
        gt0_gtrefclk0_in                => '0',
        gt0_gtrefclk1_in                => GTREFCLK,
        ---------------------------- Channel - DRP Ports  --------------------------
        gt0_drpaddr_in                  => gt0_drpaddr_i,
        gt0_drpclk_in                   => txoutclk_i,
        gt0_drpdi_in                    => gt0_drpdi_i,
        gt0_drpdo_out                   => gt0_drpdo_out,
        gt0_drpen_in                    => gt0_drpen_i,
        gt0_drprdy_out                  => gt0_drprdy_out,
        gt0_drpwe_in                    => gt0_drpwe_i,
        --------------------------- Digital Monitor Ports --------------------------
        gt0_dmonitorout_out             => gt0_dmonitorout_out,
        --------------------- RX Initialization and Reset Ports --------------------
        gt0_eyescanreset_in             => '0',
        gt0_rxuserrdy_in                => '0',
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
        gt0_gtrxreset_in                => '0',
        gt0_rxpmareset_in               => '0',
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        gt0_rxcharisk_out               => rxcharisk_o,
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        gt0_rxresetdone_out             => gt0_rxresetdone_out,
        --------------------- TX Initialization and Reset Ports --------------------
        gt0_gttxreset_in                => '0',
        gt0_txuserrdy_in                => '0',
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

    process (txoutclk_i, picxo_rst, gt0_cplllock_out)
    begin
       if(picxo_rst(0) = '1' or not gt0_cplllock_out ='1') then
            picxo_rst (7 downto 1)     <= (others=>'1');
       elsif rising_edge (txoutclk_i) then
            picxo_rst (7 downto 1)     <=  picxo_rst(6 downto 0);
    end if;
    end process;  

sfp_sync_PICXO : PICXO_FRACXO
  PORT MAP (
    RESET_I => picxo_rst(7),
    REF_CLK_I => sysclk_i,
    TXOUTCLK_I => txoutclk_i,
    DRPEN_O => gt0_drpen_i,
    DRPWEN_O => gt0_drpwe_i,
    DRPDO_I => gt0_drpdo_out,
    DRPDATA_O => gt0_drpdi_i,
    DRPADDR_O => gt0_drpaddr_i,
    DRPRDY_I => gt0_drprdy_out,
    RSIGCE_I => '1',
    VSIGCE_I => '1',
    VSIGCE_O => open,
    ACC_STEP => acc_step,
    G1 => G1,
    G2 => G2,
    R => R,
    V => V,
    CE_DSP_RATE => ce_dsp_rate,
    C_I => C,
    P_I => P,
    N_I => N,
    OFFSET_PPM => Offset_ppm,
    OFFSET_EN => Offset_en,
    HOLD => hold,
    DON_I => don,

    DRP_USER_REQ_I => '0',
    DRP_USER_DONE_I => picxo_rst(7),
    DRPEN_USER_I => '0',
    DRPWEN_USER_I => '0',
    DRPADDR_USER_I => (others => '1'),
    DRPDATA_USER_I => (others => '1'),
    DRPDATA_USER_O => open,
    DRPRDY_USER_O => open,
    DRPBUSY_O => open,

    ACC_DATA => open,
    ERROR_O => error_o,
    VOLT_O => volt_o,
    DRPDATA_SHORT_O => drpdata_short_o,
    CE_PI_O => ce_pi_o,
    CE_PI2_O => ce_pi2_o,
    CE_DSP_O => ce_dsp_o,
    OVF_PD => ovf_pd,
    OVF_AB => ovf_ab,
    OVF_VOLT => ovf_volt,
    OVF_INT => ovf_int
  );

picxo_ila_i : picxo_ila
  PORT MAP (
    clk         => txoutclk_i   ,
    probe0      => error_o          ,
    probe1      => volt_o           ,
    probe2      => drpdata_short_o  ,
    probe3(0)   => ce_pi_o          ,
    probe4(0)   => ce_pi2_o         ,
    probe5(0)   => ce_dsp_o         ,  
    probe6(0)   => ovf_pd           , 
    probe7(0)   => ovf_ab           ,
    probe8(0)   => ovf_volt         ,
    probe9(0)   => ovf_int        
  );
  

picxo_vio_i : picxo_vio
  PORT MAP (
    clk            => sysclk_i         ,
    probe_out0     => G1,
    probe_out1     => G2,
    probe_out2     => R               ,
    probe_out3     => V               ,
    probe_out4     => acc_step        ,
    probe_out5     => ce_dsp_rate     ,
    probe_out6     => Offset_ppm      ,
    probe_out7(0)  => Offset_en       ,
    probe_out8(0)  => hold            ,
    probe_out9(0)  => picxo_rst(0)    ,
    probe_out10(0) => open     ,
    probe_out11    => don             ,
    probe_out12    => C               ,
    probe_out13    => P               ,
    probe_out14    => N               
  );                                

end rtl;
