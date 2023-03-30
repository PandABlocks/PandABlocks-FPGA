----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    17:51:18 15/04/2020
-- Design Name:
-- Module Name:    eth_phy_to_phy - structural
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library unisim;
use unisim.vcomponents.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.top_defines.all;
use work.module_defines.all;

entity eth_phy_to_phy is
    Port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    SOFT_RESET          : in  std_logic;
    pma_reset_i         : in  std_logic;
    
    -- GTX I/O
    gtrefclk_i          : in  std_logic;
    eth_clk2phy_i       : in  Eth_clk2phy_interface;
    eth_phy2clk_o       : out Eth_phy2clk_interface;
    RXN_IN              : in  std_logic;
    RXP_IN              : in  std_logic;
    TXN_OUT             : out std_logic;
    TXP_OUT             : out std_logic;
    RESETDONE           : out std_logic;
    CPLLLOCK            : out std_logic;
    STATUS_VECTOR       : out std_logic_vector(15 downto 0);
    GMII_DATAIN_EN      : out std_logic;
    GMII_DATAIN_ER      : out std_logic;
   
    gtrefclk_2_i        : in  std_logic;
    eth_clk2phy_2_i     : in  Eth_clk2phy_interface;
    eth_phy2clk_2_o     : out Eth_phy2clk_interface;
    RXN2_IN             : in  std_logic;
    RXP2_IN             : in  std_logic;
    TXN2_OUT            : out std_logic;
    TXP2_OUT            : out std_logic;
    RESETDONE_2         : out std_logic;
    CPLLLOCK_2          : out std_logic;
    STATUS_VECTOR_2     : out std_logic_vector(15 downto 0);   
    GMII_DATAIN_EN_2    : out std_logic;
    GMII_DATAIN_ER_2    : out std_logic
    );
end eth_phy_to_phy;

architecture structural of eth_phy_to_phy is

  ------------------------------------------------------------------------------
  -- Component Declaration for UDP complete no mac
  ------------------------------------------------------------------------------

COMPONENT gig_ethernet_pcs_pma_0_example_design
      port(
      -- Tranceiver Interface
      -----------------------
      gtrefclk               : in std_logic;
      gtrefclk_bufg          : in std_logic;
     
      txoutclk               : out std_logic;
      rxoutclk               : out std_logic;
      resetdone              : out std_logic;                    -- The GT transceiver has completed its reset cycle
      cplllock               : out std_logic;
      mmcm_reset             : out std_logic;
      mmcm_locked            : in std_logic;                     -- Locked indication from MMCM
      userclk                : in std_logic;
      userclk2               : in std_logic;
      rxuserclk              : in std_logic;
      rxuserclk2             : in std_logic;
      independent_clock_bufg : in std_logic;
      pma_reset              : in std_logic;                     -- transceiver PMA reset signal

      -- Tranceiver Interface
      -----------------------
      txp                  	 : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
      txn                  	 : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
      rxp                  	 : in std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
      rxn                  	 : in std_logic;                     -- Differential -ve for serial reception from PMD to PMA.

      -- GMII Interface (client MAC <=> PCS)
      --------------------------------------
      gmii_tx_clk            : in std_logic;                     -- Transmit clock from client MAC.
      gmii_rx_clk            : out std_logic;                    -- Receive clock to client MAC.
      gmii_txd               : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
      gmii_tx_en             : in std_logic;                     -- Transmit control signal from client MAC.
      gmii_tx_er             : in std_logic;                     -- Transmit control signal from client MAC.
      gmii_rxd               : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
      gmii_rx_dv             : out std_logic;                    -- Received control signal to client MAC.
      gmii_rx_er             : out std_logic;                    -- Received control signal to client MAC.

      -- Management: Alternative to MDIO Interface
      --------------------------------------------
      configuration_vector   : in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.
	
      -- General IO's
      ---------------
      status_vector          : out std_logic_vector(15 downto 0); -- Core status.
      reset                  : in std_logic;                      -- Asynchronous reset for entire core.
      signal_detect          : in std_logic;                      -- Input from PMD to indicate presence of optical input.
      gt0_qplloutclk         : in std_logic;
      gt0_qplloutrefclk      : in std_logic
      );
end COMPONENT;

constant C_LITTLE_ENDIAN    : boolean := True;

--eth MAC configuration_vector
constant C_TX_RESET                   : std_logic:='0';
constant C_TX_ENABLE                  : std_logic:='1';
constant C_TX_VLAN_ENABLE             : std_logic:='0';
constant C_TX_FCS_ENABLE              : std_logic:='0';
constant C_TX_JUMBO_ENABLE            : std_logic:='0';
constant C_TX_FC_ENABLE               : std_logic:='0';--flow control enable
constant C_TX_HD_ENABLE               : std_logic:='0';--HALF_DUPLEX enable;
constant C_TX_IFG_ADJUST              : std_logic:='0';--enable iter frame gap adjustment
constant C_TX_SPEED                   : std_logic_vector(1 downto 0):="10";--'10'>1GB/s
constant C_TX_MAX_FRAME_ENABLE        : std_logic:='0';
constant C_TX_MAX_FRAME_LENGTH        : std_logic_vector(14 downto 0):=(others => '0');
constant C_TX_PAUSE_ADDR              : std_logic_vector(47 downto 0):=X"000000000000";--transmitter pause frame source address

constant C_RX_RESET                   : std_logic:='0';
constant C_RX_ENABLE                  : std_logic:='1';
constant C_RX_VLAN_ENABLE             : std_logic:='0';
constant C_RX_FCS_ENABLE              : std_logic:='0';
constant C_RX_JUMBO_ENABLE            : std_logic:='0';
constant C_RX_FC_ENABLE               : std_logic:='0';--flow control enable
constant C_RX_HD_ENABLE               : std_logic:='0';--HALF_DUPLEX enable;
constant C_RX_LEN_TYPE_CHK_DISABLE    : std_logic:='0';
constant C_RX_CONTROL_LEN_CHK_DIS     : std_logic:='0';
constant C_RX_PROMISCUOUS             : std_logic:='0';
constant C_RX_SPEED                   : std_logic_vector(1 downto 0):="10";--'10'>1GB/s
constant C_RX_MAX_FRAME_ENABLE        : std_logic:='0';
constant C_RX_MAX_FRAME_LENGTH        : std_logic_vector(14 downto 0):=(others => '0');
constant C_RX_PAUSE_ADDR              : std_logic_vector(47 downto 0):=X"000000000000";--receiver pause frame source address

constant C_RX_CONFIGURATION_VECTOR : std_logic_vector(79 DOWNTO 0):=C_RX_PAUSE_ADDR &
                                                                    '0' & C_RX_MAX_FRAME_LENGTH &
                                                                    '0' & C_RX_MAX_FRAME_ENABLE &
                                                                    C_RX_SPEED &
                                                                    C_RX_PROMISCUOUS &
                                                                    '0' & C_RX_CONTROL_LEN_CHK_DIS &
                                                                    C_RX_LEN_TYPE_CHK_DISABLE &
                                                                    '0' & C_RX_HD_ENABLE &
                                                                    C_RX_FC_ENABLE &
                                                                    C_RX_JUMBO_ENABLE &
                                                                    C_RX_FCS_ENABLE &
                                                                    C_RX_VLAN_ENABLE &
                                                                    C_RX_ENABLE &
                                                                    C_RX_RESET;

constant C_TX_CONFIGURATION_VECTOR : std_logic_vector(79 DOWNTO 0):=C_TX_PAUSE_ADDR &
                                                                    '0' & C_TX_MAX_FRAME_LENGTH &
                                                                    '0' & C_TX_MAX_FRAME_ENABLE &
                                                                    C_TX_SPEED &
                                                                    "000" & C_TX_IFG_ADJUST &
                                                                    '0' & C_TX_HD_ENABLE &
                                                                    C_TX_FC_ENABLE &
                                                                    C_TX_JUMBO_ENABLE &
                                                                    C_TX_FCS_ENABLE &
                                                                    C_TX_VLAN_ENABLE &
                                                                    C_TX_ENABLE &
                                                                    C_TX_RESET;

--eth PHY configuration_vector -- Alternative to MDIO interface.
constant  C_CONFIGURATION_VECTOR  : std_logic_vector(4 downto 0):='0'&    -- (4) Enable AN
                                                                  '0'&    -- (3) Disable ISOLATE
                                                                  '0'&    -- (2) Disable POWERDOWN
                                                                  "00";   -- (1 downto 0) Disable Loopback

---------------------------
-- Signals
---------------------------

-- GMII Interface MAC <> ETH
----------------------------
signal gmii_txd     : std_logic_vector(7 downto 0);     -- Transmit data from client MAC.
signal gmii_tx_en   : std_logic;  						-- Transmit control signal from client MAC.
signal gmii_tx_er   : std_logic;  						-- Transmit control signal from client MAC.
signal gmii_rxd     : std_logic_vector(7 downto 0);     -- Received Data to client MAC.
signal gmii_rx_dv   : std_logic;  						-- Received control signal to client MAC.
signal gmii_rx_er   : std_logic;  						-- Received control signal to client MAC.
signal gmii_tx_clk  : std_logic;
signal gmii_rx_clk  : std_logic;

-- General IO's
---------------
--signal status_vector : std_logic_vector(15 downto 0); -- Core status.
signal reset 	 	 : std_logic;  
signal signal_detect : std_logic;  -- Input from PMD to indicate presence of optical input.

attribute keep : string;
attribute keep of gmii_txd                : signal is "true";
attribute keep of gmii_tx_en              : signal is "true";
attribute keep of gmii_tx_er              : signal is "true";
attribute keep of gmii_tx_clk             : signal is "true";
attribute keep of gmii_rxd                : signal is "true";
attribute keep of gmii_rx_dv              : signal is "true";
attribute keep of gmii_rx_er              : signal is "true";
attribute keep of gmii_rx_clk             : signal is "true";

begin

signal_detect <= '1';
reset <= SOFT_RESET;

GMII_DATAIN_EN <= gmii_tx_en;
GMII_DATAIN_ER <= gmii_tx_er and gmii_tx_en;
GMII_DATAIN_EN_2 <= gmii_rx_dv;
GMII_DATAIN_ER_2 <= gmii_rx_er and gmii_rx_dv;
------------------------------------------------------------------------------
-- Instantiate the PHY layer
------------------------------------------------------------------------------
---------------
-- ETH 1
---------------
eth_phy_i : gig_ethernet_pcs_pma_0_example_design
     port map(
       independent_clock_bufg => clk_i,

       gtrefclk       	=> gtrefclk_i,
       gtrefclk_bufg  	=> eth_clk2phy_i.gtrefclk_bufg,

       txoutclk   		=> eth_phy2clk_o.txoutclk,
       rxoutclk   		=> eth_phy2clk_o.rxoutclk,
       resetdone  		=> RESETDONE,    -- The GT transceiver has completed its reset cycle
       cplllock   		=> CPLLLOCK,
       mmcm_reset 		=> eth_phy2clk_o.mmcm_reset,
       mmcm_locked		=> eth_clk2phy_i.mmcm_locked,  -- Locked indication from MMCM
       userclk    		=> eth_clk2phy_i.userclk,
       userclk2   		=> eth_clk2phy_i.userclk2,
       rxuserclk  		=> eth_clk2phy_i.rxuserclk,
       rxuserclk2 		=> eth_clk2phy_i.rxuserclk2,
       pma_reset  		=> pma_reset_i,  -- transceiver PMA reset signal
       gt0_qplloutclk   => eth_clk2phy_i.qplloutclk,
       gt0_qplloutrefclk=> eth_clk2phy_i.qplloutrefclk,

       -- Tranceiver Interface
       -----------------------
       txp              => TXP_OUT,   -- Differential +ve of serial transmission from PMA to PMD.
       txn              => TXN_OUT,   -- Differential -ve of serial transmission from PMA to PMD.
       rxp              => RXP_IN,    -- Differential +ve for serial reception from PMD to PMA.
       rxn              => RXN_IN,    -- Differential -ve for serial reception from PMD to PMA.

       -- GMII Interface (client MAC <=> PCS)
       --------------------------------------
       gmii_tx_clk      => gmii_tx_clk,--: in  -- Transmit clock from client MAC.
       gmii_rx_clk      => gmii_rx_clk,--: out -- Receive clock to client MAC.
       gmii_txd         => gmii_txd,   --: in  -- Transmit data from client MAC.
       gmii_tx_en       => gmii_tx_en, --: in  -- Transmit control signal from client MAC.
       gmii_tx_er       => gmii_tx_er, --: in  -- Transmit control signal from client MAC.
       gmii_rxd         => gmii_rxd,   --: out -- Received Data to client MAC.
       gmii_rx_dv       => gmii_rx_dv, --: out -- Received control signal to client MAC.
       gmii_rx_er       => gmii_rx_er, --: out -- Received control signal to client MAC.
       
       -- Management: Alternative to MDIO Interface
       --------------------------------------------
       configuration_vector => C_CONFIGURATION_VECTOR,--: in  -- Alternative to MDIO interface.

       -- General IO's
       ---------------
       status_vector	=> STATUS_VECTOR, --: out -- Core status.
       reset 			=> reset,         --: in  -- Asynchronous reset for entire core.
       signal_detect	=> signal_detect  --: in  -- Input from PMD to indicate presence of optical input.
       );

---------------
-- ETH 2
---------------
eth_phy_i2 : gig_ethernet_pcs_pma_0_example_design
     port map(
       --An independent clock source used as the reference clock for an
       --IDELAYCTRL (if present) and for the main GT transceiver reset logic.
       --This example design assumes that this is of frequency 200MHz.
       independent_clock_bufg => clk_i,

       gtrefclk       	=> gtrefclk_2_i,
       gtrefclk_bufg  	=> eth_clk2phy_2_i.gtrefclk_bufg,

       txoutclk   		=> eth_phy2clk_2_o.txoutclk,
       rxoutclk   		=> eth_phy2clk_2_o.rxoutclk,
       resetdone  		=> RESETDONE_2,  -- The GT transceiver has completed its reset cycle
       cplllock   		=> CPLLLOCK_2,
       mmcm_reset 		=> eth_phy2clk_2_o.mmcm_reset,
       mmcm_locked		=> eth_clk2phy_2_i.mmcm_locked,  -- Locked indication from MMCM
       userclk    		=> eth_clk2phy_2_i.userclk,
       userclk2   		=> eth_clk2phy_2_i.userclk2,
       rxuserclk  		=> eth_clk2phy_2_i.rxuserclk,
       rxuserclk2 		=> eth_clk2phy_2_i.rxuserclk2,
       pma_reset  		=> pma_reset_i,  -- transceiver PMA reset signal
       gt0_qplloutclk   => eth_clk2phy_2_i.qplloutclk,
       gt0_qplloutrefclk=> eth_clk2phy_2_i.qplloutrefclk,

       -- Tranceiver Interface
       -----------------------
       txp              => TXP2_OUT,    -- Differential +ve of serial transmission from PMA to PMD.
       txn              => TXN2_OUT,    -- Differential -ve of serial transmission from PMA to PMD.
       rxp              => RXP2_IN,     -- Differential +ve for serial reception from PMD to PMA.
       rxn              => RXN2_IN,     -- Differential -ve for serial reception from PMD to PMA.

       -- GMII Interface (client MAC <=> PCS)
       --------------------------------------
       -- crossover with eth_phy_i
       gmii_tx_clk      => gmii_rx_clk, --: in  -- Transmit clock from client MAC.
       gmii_rx_clk      => gmii_tx_clk, --: out -- Receive clock to client MAC.
       gmii_txd         => gmii_rxd,    --: in  -- Transmit data from client MAC.
       gmii_tx_en       => gmii_rx_dv,  --: in  -- Transmit control signal from client MAC.
       gmii_tx_er       => gmii_rx_er,  --: in  -- Transmit control signal from client MAC.
       gmii_rxd         => gmii_txd,    --: out -- Received Data to client MAC.
       gmii_rx_dv       => gmii_tx_en,  --: out -- Received control signal to client MAC.
       gmii_rx_er       => gmii_tx_er,  --: out -- Received control signal to client MAC.
       
       -- Management: Alternative to MDIO Interface
       --------------------------------------------
       configuration_vector => C_CONFIGURATION_VECTOR,  -- Alternative to MDIO interface.

       -- General IO's
       ---------------
       status_vector	=> STATUS_VECTOR_2, --: out -- Core status.
       reset 			=> reset,           --: in  -- Asynchronous reset for entire core.
       signal_detect	=> signal_detect    --: in  -- Input from PMD to indicate presence of optical input.
       );

end structural;

