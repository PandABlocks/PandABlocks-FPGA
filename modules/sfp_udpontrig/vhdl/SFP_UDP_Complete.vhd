----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:51:18 15/06/2017 
-- Design Name: 
-- Module Name:    UDP_Complete - Behavioral 
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
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;
use work.top_defines.all;

entity SFP_UDP_Complete is
    generic (
    CLOCK_FREQ			: integer := 125000000;	-- freq of data_in_clk needed to timout cntr
    ARP_TIMEOUT			: integer := 60;		-- ARP response timeout (s)
    ARP_MAX_PKT_TMO		: integer := 5;			-- wrong nwk pkts received before set error
    MAX_ARP_ENTRIES 	: integer := 255		-- max entries in the ARP store
    );
    Port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    SOFT_RESET          : in  std_logic;
    -- Block inpout
    trig_i                     : in std_logic_vector(2 downto 0);
    SFP_START_COUNT            : in std_logic_vector(2 downto 0);
    SFP_STOP_COUNT             : in std_logic_vector(2 downto 0);
    -- Block register readouts 
    udp_txi_trigger_rise_count : out std32_array(2 downto 0);
    count_udp_tx_RESULT_ERR    : out unsigned32_array(2 downto 0);
    SFP_STATUS_COUNT           : out std32_array(2 downto 0);
    -- Block Parameters
    OUR_MAC_ADDRESS : in std48_array(2 downto 0);
    dest_udp_port : in std16_array(2 downto 0);
    our_udp_port  : in std16_array(2 downto 0); 
    dest_ip_address : in std32_array(2 downto 0);
    our_ip_address  : in std32_array(2 downto 0);
    -- GTX I/O
    gtrefclk_n          : in  std_logic;
    gtrefclk_p          : in  std_logic;
    
    RXN_IN              : in  std_logic_vector(2 downto 0);
    RXP_IN              : in  std_logic_vector(2 downto 0);
    TXN_OUT             : out std_logic_vector(2 downto 0);
    TXP_OUT             : out std_logic_vector(2 downto 0)
    );
end SFP_UDP_Complete;

architecture structural of SFP_UDP_Complete is

  ------------------------------------------------------------------------------
  -- Component Declaration for UDP complete no mac
  ------------------------------------------------------------------------------

COMPONENT UDP_Complete_nomac
  generic (
    CLOCK_FREQ			: integer := 125000000;	-- freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT			: integer := 60;		-- ARP response timeout (s)
    ARP_MAX_PKT_TMO		: integer := 5;			-- # wrong nwk pkts received before set error
    MAX_ARP_ENTRIES 	: integer := 255		-- max entries in the ARP store
    );
  Port (
    -- UDP TX signals
    udp_tx_start			: in std_logic;						-- indicates req to tx UDP
    udp_txi					: in udp_tx_type;					-- UDP tx cxns
    udp_tx_result			: out std_logic_vector (1 downto 0);-- tx status (changes during transmission)
    udp_tx_data_out_ready	: out std_logic;					-- indicates udp_tx is ready to take data
    -- UDP RX signals
    udp_rx_start			: out std_logic;					-- indicates receipt of udp header
    udp_rxo					: out udp_rx_type;
    -- IP RX signals
    ip_rx_hdr				: out ipv4_rx_header_type;
    -- system signals
    rx_clk					: in  STD_LOGIC;
    tx_clk					: in  STD_LOGIC;
    reset 					: in  STD_LOGIC;
    our_ip_address 			: in STD_LOGIC_VECTOR (31 downto 0);
    our_mac_address 		: in std_logic_vector (47 downto 0);
    control					: in udp_control_type;
    -- status signals
    arp_pkt_count			: out STD_LOGIC_VECTOR(7 downto 0);		-- count of arp pkts received
    ip_pkt_count			: out STD_LOGIC_VECTOR(7 downto 0);		-- number of IP pkts received for us
    -- MAC Transmitter
    mac_tx_tdata         : out  std_logic_vector(7 downto 0);	-- data byte to tx
    mac_tx_tvalid        : out  std_logic;						-- tdata is valid
    mac_tx_tready        : in std_logic;						-- mac is ready to accept data
    mac_tx_tfirst        : out  std_logic;						-- indicates first byte of frame
    mac_tx_tlast         : out  std_logic;						-- indicates last byte of frame
    -- MAC Receiver
    mac_rx_tdata         : in std_logic_vector(7 downto 0);	-- data byte received
    mac_rx_tvalid        : in std_logic;					-- indicates tdata is valid
    mac_rx_tready        : out std_logic;					-- tells mac that we are ready to take data
    mac_rx_tlast         : in std_logic						-- indicates last byte of the trame
  );
END COMPONENT;


component tri_mode_ethernet_mac_0_fifo_block
   port(
      gtx_clk                    : in  std_logic;
      -- asynchronous reset
      glbl_rstn                  : in  std_logic;
      rx_axi_rstn                : in  std_logic;
      tx_axi_rstn                : in  std_logic;

      -- Receiver Statistics Interface
      -----------------------------------------
      rx_mac_aclk                : out std_logic;
      rx_reset                   : out std_logic;
      rx_statistics_vector       : out std_logic_vector(27 downto 0);
      rx_statistics_valid        : out std_logic;

      -- Receiver (AXI-S) Interface
      ------------------------------------------
      rx_fifo_clock              : in  std_logic;
      rx_fifo_resetn             : in  std_logic;
      rx_axis_fifo_tdata         : out std_logic_vector(7 downto 0);
      rx_axis_fifo_tvalid        : out std_logic;
      rx_axis_fifo_tready        : in  std_logic;
      rx_axis_fifo_tlast         : out std_logic;

      -- Transmitter Statistics Interface
      --------------------------------------------
      tx_mac_aclk                : out std_logic;
      tx_reset                   : out std_logic;
      tx_ifg_delay               : in  std_logic_vector(7 downto 0);
      tx_statistics_vector       : out std_logic_vector(31 downto 0);
      tx_statistics_valid        : out std_logic;

      -- Transmitter (AXI-S) Interface
      ---------------------------------------------
      tx_fifo_clock              : in  std_logic;
      tx_fifo_resetn             : in  std_logic;
      tx_axis_fifo_tdata         : in  std_logic_vector(7 downto 0);
      tx_axis_fifo_tvalid        : in  std_logic;
      tx_axis_fifo_tready        : out std_logic;
      tx_axis_fifo_tlast         : in  std_logic;
      tx_fifo_overflow           : out std_logic;
      tx_fifo_status             : out std_logic_vector(3 downto 0);

      -- MAC Control Interface
      --------------------------
      pause_req                  : in  std_logic;
      pause_val                  : in  std_logic_vector(15 downto 0);

      -- GMII Interface
      -------------------
      gmii_txd                  : out std_logic_vector(7 downto 0);
      gmii_tx_en                : out std_logic;
      gmii_tx_er                : out std_logic;
      gmii_tx_clk               : out std_logic;
      gmii_rxd                  : in  std_logic_vector(7 downto 0);
      gmii_rx_dv                : in  std_logic;
      gmii_rx_er                : in  std_logic;
      gmii_rx_clk               : in  std_logic;

      -- Configuration Vector
      -------------------------
      rx_configuration_vector    : in  std_logic_vector(79 downto 0);
      tx_configuration_vector    : in  std_logic_vector(79 downto 0)
   );
   end component;
   


COMPONENT gig_ethernet_pcs_pma_0_example_design
      port(
     -- Tranceiver Interface
      -----------------------
      gtrefclk             : in std_logic;                    
      gtrefclk_bufg        : in std_logic; 

      txoutclk             : out std_logic;                   
      rxoutclk             : out std_logic;                   
      resetdone            : out std_logic;                    -- The GT transceiver has completed its reset cycle
      cplllock             : out std_logic;                    
      mmcm_reset           : out std_logic;                    
      mmcm_locked          : in std_logic;                     -- Locked indication from MMCM
      userclk              : in std_logic;                    
      userclk2             : in std_logic;                    
      rxuserclk              : in std_logic;                  
      rxuserclk2             : in std_logic;                  
      independent_clock_bufg : in std_logic;                  
      pma_reset            : in std_logic;                     -- transceiver PMA reset signal
      -- Tranceiver Interface
      -----------------------
 
      txp                  : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
      txn                  : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
      rxp                  : in std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
      rxn                  : in std_logic;                     -- Differential -ve for serial reception from PMD to PMA.

      -- GMII Interface (client MAC <=> PCS)
      --------------------------------------
      gmii_tx_clk          : in std_logic;                     -- Transmit clock from client MAC.
      gmii_rx_clk          : out std_logic;                    -- Receive clock to client MAC.
      gmii_txd             : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
      gmii_tx_en           : in std_logic;                     -- Transmit control signal from client MAC.
      gmii_tx_er           : in std_logic;                     -- Transmit control signal from client MAC.
      gmii_rxd             : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
      gmii_rx_dv           : out std_logic;                    -- Received control signal to client MAC.
      gmii_rx_er           : out std_logic;                    -- Received control signal to client MAC.
      -- Management: Alternative to MDIO Interface
      --------------------------------------------

      configuration_vector : in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.

      -- General IO's
      ---------------
      status_vector        : out std_logic_vector(15 downto 0); -- Core status.
      reset                : in std_logic;                      -- Asynchronous reset for entire core.
      signal_detect        : in std_logic;                      -- Input from PMD to indicate presence of optical input.
      gt0_qplloutclk        : in   std_logic;
      gt0_qplloutrefclk     : in   std_logic
      
      );
end COMPONENT;

component gig_ethernet_pcs_pma_0_clocking
   port (
      gtrefclk_p              : in  std_logic;                -- Differential +ve of reference clock for MGT
      gtrefclk_n              : in  std_logic;                -- Differential -ve of reference clock for MGT
      txoutclk                : in  std_logic;                -- txoutclk from GT transceiver.
      rxoutclk                : in  std_logic;                -- txoutclk from GT transceiver.
      mmcm_reset              : in  std_logic;                -- MMCM Reset
      gtrefclk                : out std_logic;                -- gtrefclk routed through an IBUFDS.
      gtrefclk_bufg           : out std_logic;
      mmcm_locked             : out std_logic;                -- MMCM locked
      userclk                 : out std_logic;                -- for GT PMA reference clock
      userclk2                : out std_logic;                 
      rxuserclk               : out std_logic;                -- for GT PMA reference clock
      rxuserclk2              : out std_logic                 
   );
end component;

component gig_ethernet_pcs_pma_0_resets
   port (
    reset                    : in  std_logic;                -- Asynchronous reset for entire core.
    independent_clock_bufg   : in  std_logic;                -- System clock 
    pma_reset                : out std_logic                 -- Synchronous transcevier PMA reset
   );
end component;

component gig_ethernet_pcs_pma_0_gt_common
  port(
    GTREFCLK0_IN         : in std_logic;
    QPLLLOCK_OUT         : out std_logic;
    QPLLLOCKDETCLK_IN    : in std_logic;
    QPLLOUTCLK_OUT       : out std_logic;
    QPLLOUTREFCLK_OUT    : out std_logic;
    QPLLREFCLKLOST_OUT   : out std_logic;    
    QPLLRESET_IN         : in std_logic
  );
end component;
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

-- MAC RX bus
signal rx_axis_mac_tdata  : std8_array(2 downto 0);
signal rx_axis_mac_tvalid : std_logic_vector(2 DOWNTO 0);
signal rx_axis_mac_tready : std_logic_vector(2 DOWNTO 0);
signal rx_axis_mac_tlast  : std_logic_vector(2 DOWNTO 0);
signal rx_mac_aclk        : std_logic_vector(2 DOWNTO 0);


-- MAC TX bus
signal tx_axis_mac_tready_i : std_logic_vector(2 DOWNTO 0);
signal tx_axis_mac_tvalid   : std_logic_vector(2 DOWNTO 0);
signal tx_axis_mac_tfirst   : std_logic_vector(2 DOWNTO 0);
signal tx_axis_mac_tlast    : std_logic_vector(2 DOWNTO 0);
signal tx_axis_mac_tdata    : std8_array(2 downto 0);
signal tx_mac_aclk          : std_logic_vector(2 DOWNTO 0);
signal tx_fifo_overflow     : std_logic_vector(2 downto 0);
signal tx_fifo_status       : std4_array(2 downto 0);


-- GMII Interface MAC <> ETH
signal gmii_txd     : std8_array(2 downto 0);        -- Transmit data from client MAC.
signal gmii_tx_en   : std_logic_vector(2 downto 0);  -- Transmit control signal from client MAC.
signal gmii_tx_er   : std_logic_vector(2 downto 0);  -- Transmit control signal from client MAC.
signal gmii_rxd     : std8_array(2 downto 0);        -- Received Data to client MAC.
signal gmii_rx_dv   : std_logic_vector(2 downto 0);  -- Received control signal to client MAC.
signal gmii_rx_er   : std_logic_vector(2 downto 0);  -- Received control signal to client MAC.
signal gmii_isolate : std_logic_vector(2 downto 0);  -- Tristate control to electrically isolate GMII.
signal gmii_tx_clk  : std_logic_vector(2 downto 0);
signal gmii_rx_clk  : std_logic_vector(2 downto 0);

-- control signals
type udp_control_type_array is array(natural range <>) of udp_control_type;
signal control                   : udp_control_type_array(2 downto 0);

signal udp_tx_result_i           : std2_array(2 downto 0);-- tx status (changes during transmission)
signal udp_tx_data_out_ready_i   : std_logic_vector(2 downto 0);-- indicates udp_tx is ready to take data
signal udp_txi_data_data_out     : std8_array(2 downto 0);
signal udp_txi_data_data_out_last: std_logic_vector(2 downto 0);

type udp_tx_type_array is array(natural range <>) of udp_tx_type;
signal udp_txi                   : udp_tx_type_array(2 downto 0);-- UDP tx cxns

signal count_udp_txi_data_byte    : unsigned4_array(2 downto 0);--count data byte number to be sent
signal count_udp_txi_trigger_rise : unsigned32_array(2 downto 0);-- count number of trigger 

signal enable_count : std_logic_vector(2 downto 0); -- enable counting trigger and UDP send

signal udp_tx_start : std_logic_vector(2 downto 0); -- indicates receipt of udp header
signal trig_prev    : std_logic_vector(2 downto 0); -- indicates receipt of udp header registered
signal trigger_rise : std_logic_vector(2 downto 0);

signal count_udp_tx_RESULT_ERR_i : unsigned32_array(2 downto 0);

-- UDP RX signals
signal udp_rx_start			: std_logic_vector(2 downto 0); -- indicates receipt of udp header

type udp_rx_type_array is array(natural range <>) of udp_rx_type;
signal udp_rxo					: udp_rx_type_array(2 downto 0);

-- IP RX signals
type ipv4_rx_header_type_array is array(natural range <>) of ipv4_rx_header_type;
signal ip_rx_hdr				: ipv4_rx_header_type_array(2 downto 0);  

signal glbl_rstn    : std_logic;
signal rx_axi_rstn  : std_logic;
signal tx_axi_rstn  : std_logic;
signal rx_reset     : std_logic_vector(2 downto 0);
signal tx_ifg_delay : std_logic_vector(7 DOWNTO 0);--iter frame gap delay
signal tx_reset     : std_logic_vector(2 downto 0);
signal pause_req    : std_logic;
signal pause_val    : std_logic_vector(15 DOWNTO 0);


-- Transceiver Interface
------------------------

signal txp   : std_logic_vector(2 downto 0);  -- Differential +ve of serial transmission from PMA to PMD.
signal txn   : std_logic_vector(2 downto 0);  -- Differential -ve of serial transmission from PMA to PMD.
signal rxp   : std_logic_vector(2 downto 0);  -- Differential +ve for serial reception from PMD to PMA.
signal rxn   : std_logic_vector(2 downto 0);  -- Differential -ve for serial reception from PMD to PMA.

signal gtx_clk_bufg         : std_logic_vector(2 downto 0);
signal rxuserclk2_out       : std_logic_vector(2 downto 0);
signal userclk2_out         : std_logic_vector(2 downto 0);
signal independent_clock_bufg : std_logic;
signal gtrefclk            : std_logic;
signal gtrefclk_bufg       : std_logic;
signal txoutclk            : std_logic_vector(2 downto 0);
signal rxoutclk            : std_logic_vector(2 downto 0);
signal resetdone           : std_logic_vector(2 downto 0);-- The GT transceiver has completed its reset cycle
signal cplllock            : std_logic_vector(2 downto 0);
signal mmcm_reset          : std_logic_vector(2 downto 0);
signal mmcm_reset0         : std_logic;
signal mmcm_locked         : std_logic;-- Locked indication from MMCM
signal userclk             : std_logic;
signal userclk2            : std_logic;
signal rxuserclk           : std_logic;
signal rxuserclk2          : std_logic;
signal pma_reset           : std_logic;-- transceiver PMA reset signal
signal gt0_qplloutclk      : std_logic;
signal gt0_qplloutrefclk   : std_logic;

-- General IO's
---------------
signal status_vector :  std16_array(2 downto 0); -- Core status.
    
signal signal_detect : std_logic; -- Input from PMD to indicate presence of optical input.
    
-- CHIPSCOPE ILA probes
signal probe0               : std_logic_vector(31 downto 0);
signal probe1               : std_logic_vector(31 downto 0);
signal probe2               : std_logic_vector(31 downto 0);
signal probe3               : std_logic_vector(31 downto 0);
signal probe4               : std_logic_vector(31 downto 0);

attribute keep : string;--keep name for ila probes
attribute keep of tx_axis_mac_tdata       : signal is "true";
attribute keep of tx_axis_mac_tvalid      : signal is "true";
attribute keep of tx_axis_mac_tready_i    : signal is "true";
attribute keep of tx_axis_mac_tlast       : signal is "true";
attribute keep of gmii_txd                : signal is "true";
attribute keep of gmii_tx_en              : signal is "true";
attribute keep of gmii_tx_er              : signal is "true";
attribute keep of gmii_tx_clk             : signal is "true";
attribute keep of udp_tx_start            : signal is "true";
attribute keep of udp_tx_result_i         : signal is "true";
attribute keep of udp_tx_data_out_ready_i : signal is "true";
attribute keep of udp_txi_data_data_out   : signal is "true";
attribute keep of udp_txi_data_data_out_last   : signal is "true";
attribute keep of clk_i                   : signal is "true";
attribute keep of glbl_rstn               : signal is "true";
attribute keep of rx_axis_mac_tdata       : signal is "true";
attribute keep of rx_axis_mac_tvalid      : signal is "true";
attribute keep of rx_axis_mac_tready      : signal is "true";
attribute keep of rx_axis_mac_tlast       : signal is "true";
attribute keep of gmii_rxd                : signal is "true";
attribute keep of gmii_rx_dv              : signal is "true";
attribute keep of gmii_rx_er              : signal is "true";
attribute keep of gmii_rx_clk             : signal is "true";
attribute keep of tx_fifo_overflow        : signal is "true";
attribute keep of tx_fifo_status          : signal is "true";

begin


glbl_rstn<=not(SOFT_RESET);
rx_axi_rstn<=not(SOFT_RESET);
tx_axi_rstn<=not(SOFT_RESET);
pause_req<='0';
pause_val<=(others=>'0');

tx_ifg_delay<=(others=>'0');
signal_detect<='1';


SFP_gen: for I in 0 to 2 generate

   begin
   SFP_STATUS_COUNT(I)(0)<=enable_count(I); --sfp status
   SFP_STATUS_COUNT(I)(31 downto 1)<=(others=>'0');
   
   TXN_OUT(I) <= txn(I);
   TXP_OUT(I) <= txp(I);
   rxn(I) <= RXN_IN(I);
   rxp(I) <= RXP_IN(I);
   
   control(I).ip_controls.arp_controls.clear_cache <= SOFT_RESET;
   
   udp_txi(I).hdr.dst_ip_addr <=dest_ip_address(I);--destination ip
   udp_txi(I).hdr.dst_port<=dest_udp_port(I);--udp destination port
   udp_txi(I).hdr.src_port<=our_udp_port(I);--udp source port
   udp_txi(I).hdr.data_length<=x"0004";	-- user data size, bytes
   udp_txi(I).hdr.checksum<=x"0000";
   
   process(clk_i)
   begin
       if rising_edge(clk_i) then
           if (SOFT_RESET= '1') then --reset_i = '1') then
              enable_count(I)<='0';
           else
              if SFP_STOP_COUNT(I)='1' then
                enable_count(I)<='0';
              elsif SFP_START_COUNT(I)='1' then
                enable_count(I)<='1';
              end if;
           end if;
       end if;
   end process;
   
   
   process(clk_i)
   begin
       if rising_edge(clk_i) then
           if (SOFT_RESET= '1') then
              trig_prev(I) <= trig_i(I);
              udp_tx_start(I)<='0';
           else
              trig_prev(I) <= trig_i(I);
              if enable_count(I)='1' then
                 if (trigger_rise(I) = '1') then
                     udp_tx_start(I)<='1';
                 elsif udp_tx_result_i(I) = UDPTX_RESULT_NONE or udp_tx_result_i(I) = UDPTX_RESULT_SENDING then--blocage udp_tx_result_i=UDPTX_RESULT_ERR faire traitement
                     udp_tx_start(I)<='0';
                 else
                     udp_tx_start(I)<=udp_tx_start(I);
                 end if;
              else
                  udp_tx_start(I)<='0';
              end if;
           end if;
       end if;
   end process;
   
   trigger_rise(I) <= trig_i(I) and not(trig_prev(I));
   UDP_little_endian: if C_LITTLE_ENDIAN=TRUE generate-- Little endian
   begin
      process (clk_i)
      begin
      if (rising_edge(clk_i)) then 
          if (SOFT_RESET = '1') then 
               udp_txi_data_data_out_last(I)<='0';
               udp_txi_data_data_out(I)<=(others=>'0');
               count_udp_txi_data_byte(I)<=(others=>'0');
               count_udp_txi_trigger_rise(I)<=(others=>'0');
               count_udp_tx_RESULT_ERR_i(I)<=(others=>'0');
          else
               if SFP_START_COUNT(I)='1' then
                  count_udp_txi_trigger_rise(I)<=(others=>'0');
               elsif trigger_rise(I)='1' and enable_count(I)='1' then 
                      count_udp_txi_trigger_rise(I)<=count_udp_txi_trigger_rise(I)+1;
               end if;
               
               if enable_count(I)='1' then
                  if udp_tx_data_out_ready_i(I)='1' then
                      count_udp_txi_data_byte(I)<=count_udp_txi_data_byte(I)+1;
                      case count_udp_txi_data_byte(I) is
                          when x"0" =>udp_txi_data_data_out_last(I)<='0';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(15 downto 8));
                          when x"1" =>udp_txi_data_data_out_last(I)<='0';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(23 downto 16));
                          when x"2" =>udp_txi_data_data_out_last(I)<='1';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(31 downto 24));
                          when x"3" =>udp_txi_data_data_out_last(I)<='1';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(7 downto 0));
                          when others =>udp_txi_data_data_out_last(I)<='0';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(7 downto 0));
                      end case;
                  elsif udp_tx_result_i(I)=UDPTX_RESULT_ERR then --traitement si blocage udp_tx_result_i=UDPTX_RESULT_ERR
                      count_udp_txi_data_byte(I)<=(others=>'0');
                      udp_txi_data_data_out_last(I)<='1';
                      udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(7 downto 0));
                      count_udp_tx_RESULT_ERR_i(I)<=count_udp_tx_RESULT_ERR_i(I)+1;
                  else 
                      count_udp_txi_data_byte(I)<=(others=>'0');
                      udp_txi_data_data_out_last(I)<='0';
                      udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(7 downto 0));
                  end if;
               else
                  if SFP_START_COUNT(I)='1' then--reset error cpt on start_count
                     count_udp_tx_RESULT_ERR_i(I)<=(others=>'0');
                  end if;
                  count_udp_txi_data_byte(I)<=(others=>'0');
                  udp_txi_data_data_out_last(I)<='0';
                  udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(7 downto 0));
               end if;
          end if;
      end if;   
      end process;
   end generate;
   
   UDP_big_endian: if C_LITTLE_ENDIAN=False generate-- Big endian
   begin
      process (clk_i)
      begin
      if (rising_edge(clk_i)) then 
          if (SOFT_RESET = '1') then 
               udp_txi_data_data_out_last(I)<='0';
               udp_txi_data_data_out(I)<=(others=>'0');
               count_udp_txi_data_byte(I)<=(others=>'0');
               count_udp_txi_trigger_rise(I)<=(others=>'0');
               count_udp_tx_RESULT_ERR_i(I)<=(others=>'0');
          else
               if SFP_START_COUNT(I)='1' then
                  count_udp_txi_trigger_rise(I)<=(others=>'0');
               elsif trigger_rise(I)='1' and enable_count(I)='1' then 
                      count_udp_txi_trigger_rise(I)<=count_udp_txi_trigger_rise(I)+1;
               end if;
               
               if enable_count(I)='1' then
                  if udp_tx_data_out_ready_i(I)='1' then
                      count_udp_txi_data_byte(I)<=count_udp_txi_data_byte(I)+1;
                      case count_udp_txi_data_byte(I) is
                          when x"0" =>udp_txi_data_data_out_last(I)<='0';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(23 downto 16));
                          when x"1" =>udp_txi_data_data_out_last(I)<='0';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(15 downto 8));
                          when x"2" =>udp_txi_data_data_out_last(I)<='1';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(7 downto 0));
                          when x"3" =>udp_txi_data_data_out_last(I)<='1';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(31 downto 24));
                          when others =>udp_txi_data_data_out_last(I)<='0';
                                   udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(31 downto 24));
                      end case;
                  elsif udp_tx_result_i(I)=UDPTX_RESULT_ERR then --traitement si blocage udp_tx_result_i=UDPTX_RESULT_ERR
                      count_udp_txi_data_byte(I)<=(others=>'0');
                      udp_txi_data_data_out_last(I)<='1';
                      udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(31 downto 24));
                      count_udp_tx_RESULT_ERR_i(I)<=count_udp_tx_RESULT_ERR_i(I)+1;
                  else 
                      count_udp_txi_data_byte(I)<=(others=>'0');
                      udp_txi_data_data_out_last(I)<='0';
                      udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(31 downto 24));
                  end if;
               else
                  if SFP_START_COUNT(I)='1' then--reset error cpt on start_count
                     count_udp_tx_RESULT_ERR_i(I)<=(others=>'0');
                  end if;
                  count_udp_txi_data_byte(I)<=(others=>'0');
                  udp_txi_data_data_out_last(I)<='0';
                  udp_txi_data_data_out(I)<=std_logic_vector(count_udp_txi_trigger_rise(I)(31 downto 24));
               end if;
          end if;
      end if;   
      end process;
   end generate;
   
   udp_txi_trigger_rise_count(I)<=std_logic_vector(count_udp_txi_trigger_rise(I));
   udp_txi(I).data.data_out_valid<=udp_tx_data_out_ready_i(I);
   udp_txi(I).data.data_out_last<=udp_txi_data_data_out_last(I);
   udp_txi(I).data.data_out<=udp_txi_data_data_out(I);
   count_udp_tx_RESULT_ERR(I)<=count_udp_tx_RESULT_ERR_i(I);
     ------------------------------------------------------------------------------
     -- Instantiate the UDP layer
     ------------------------------------------------------------------------------
   
   udp_block: UDP_Complete_nomac 
     generic map (
       CLOCK_FREQ		=> CLOCK_FREQ,
       ARP_TIMEOUT		=> ARP_TIMEOUT,
       ARP_MAX_PKT_TMO	=> ARP_MAX_PKT_TMO,
       MAX_ARP_ENTRIES	=> MAX_ARP_ENTRIES
       )
     port map( 
       -- UDP TX signals
       udp_tx_start 			=> udp_tx_start(I),
       udp_txi 					=> udp_txi(I),
       udp_tx_result			=> udp_tx_result_i(I),
       udp_tx_data_out_ready	=> udp_tx_data_out_ready_i(I),
       -- UDP RX signals
       udp_rx_start 			=> udp_rx_start(I),
       udp_rxo 					=> udp_rxo(I),
       -- IP RX signals
       ip_rx_hdr 				=> ip_rx_hdr(I),
       -- system signals
       rx_clk					=> clk_i,
       tx_clk					=> clk_i,
       reset 					=> SOFT_RESET,
       our_ip_address 			=> our_ip_address(I),
       our_mac_address 			=> OUR_MAC_ADDRESS(I),
       -- status signals
       arp_pkt_count 		=> open,
       ip_pkt_count 		=> open,
       control				=> control(I),
       -- MAC Transmitter
       mac_tx_tready 		=> tx_axis_mac_tready_i(I),
       mac_tx_tvalid 		=> tx_axis_mac_tvalid(I),
       mac_tx_tfirst		=> tx_axis_mac_tfirst(I),
       mac_tx_tlast 		=> tx_axis_mac_tlast(I),
       mac_tx_tdata 		=> tx_axis_mac_tdata(I),
       -- MAC Receiver
       mac_rx_tdata 			=> rx_axis_mac_tdata(I),
       mac_rx_tvalid		 	=> rx_axis_mac_tvalid(I),
       mac_rx_tready			=> rx_axis_mac_tready(I),
       mac_rx_tlast 			=> rx_axis_mac_tlast(I)
       );
     ------------------------------------------------------------------------------
     -- Instantiate the MAC layer
     ------------------------------------------------------------------------------
   eth_mac_fifo_i : tri_mode_ethernet_mac_0_fifo_block
     port map(
       gtx_clk                    => gtx_clk_bufg(I),
       -- asynchronous reset
       glbl_rstn                  => glbl_rstn,
       rx_axi_rstn                => rx_axi_rstn,
       tx_axi_rstn                => tx_axi_rstn,
       
       -- Receiver Statistics Interface
       -----------------------------------------
       rx_mac_aclk                => rx_mac_aclk(I),
       rx_reset                   => rx_reset(I),
       rx_statistics_vector       => open,
       rx_statistics_valid        => open,
       
       -- Receiver (AXI-S) Interface
       ------------------------------------------
       rx_fifo_clock              => clk_i,
       rx_fifo_resetn             => glbl_rstn,
       rx_axis_fifo_tdata         => rx_axis_mac_tdata(I),
       rx_axis_fifo_tvalid        => rx_axis_mac_tvalid(I),
       rx_axis_fifo_tready        => rx_axis_mac_tready(I),
       rx_axis_fifo_tlast         => rx_axis_mac_tlast(I),
       
       -- Transmitter Statistics Interface
       --------------------------------------------
       tx_mac_aclk                => tx_mac_aclk(I),
       tx_reset                   => tx_reset(I),
       tx_ifg_delay               => tx_ifg_delay,
       tx_statistics_vector       => open,
       tx_statistics_valid        => open,
       
       -- Transmitter (AXI-S) Interface
       ---------------------------------------------
       tx_fifo_clock              => clk_i,
       tx_fifo_resetn             => glbl_rstn,
       tx_axis_fifo_tdata         => tx_axis_mac_tdata(I),
       tx_axis_fifo_tvalid        => tx_axis_mac_tvalid(I),
       tx_axis_fifo_tready        => tx_axis_mac_tready_i(I),
       tx_axis_fifo_tlast         => tx_axis_mac_tlast(I),
       tx_fifo_overflow           => tx_fifo_overflow(I),
       tx_fifo_status             => tx_fifo_status(I),
       
       -- MAC Control Interface
       --------------------------
       pause_req                  => pause_req,
       pause_val                  => pause_val,
       
       -- GMII Interface
       -------------------
       gmii_txd                  => gmii_txd(I),
       gmii_tx_en                => gmii_tx_en(I),
       gmii_tx_er                => gmii_tx_er(I),
       gmii_tx_clk               => gmii_tx_clk(I),
       gmii_rxd                  => gmii_rxd(I),
       gmii_rx_dv                => gmii_rx_dv(I),
       gmii_rx_er                => gmii_rx_er(I),
       gmii_rx_clk               => gmii_rx_clk(I),
       
       -- Configuration Vector
       -------------------------
       rx_configuration_vector   => C_RX_CONFIGURATION_VECTOR,
       tx_configuration_vector   => C_TX_CONFIGURATION_VECTOR
       );
   
   userclk2_out(I)<=userclk2;      
   gmii_tx_clk(I)<=userclk2_out(I);      
   gmii_rx_clk(I)<=userclk2_out(I);
   gtx_clk_bufg(I)<=gtrefclk_bufg;
   
     ------------------------------------------------------------------------------
     -- Instantiate the PHY layer
     ------------------------------------------------------------------------------
   
   eth_phy_i : gig_ethernet_pcs_pma_0_example_design
     port map(
       --An independent clock source used as the reference clock for an
       --IDELAYCTRL (if present) and for the main GT transceiver reset logic.
       --This example design assumes that this is of frequency 200MHz.
       independent_clock_bufg    => independent_clock_bufg,
       
       gtrefclk       =>gtrefclk      ,                    
       gtrefclk_bufg  =>gtrefclk_bufg , 
       
       txoutclk   =>txoutclk(I)    ,
       rxoutclk   =>rxoutclk(I)    ,
       resetdone  =>resetdone(I)   ,-- The GT transceiver has completed its reset cycle
       cplllock   =>cplllock(I)    ,
       mmcm_reset =>mmcm_reset(I)  ,
       mmcm_locked=>mmcm_locked ,-- Locked indication from MMCM
       userclk    =>userclk     ,
       userclk2   =>userclk2    ,
       rxuserclk  =>rxuserclk   ,
       rxuserclk2 =>rxuserclk2  ,
       pma_reset  =>pma_reset   ,-- transceiver PMA reset signal
       gt0_qplloutclk   =>gt0_qplloutclk     ,
       gt0_qplloutrefclk=>gt0_qplloutrefclk  ,
       
       -- Tranceiver Interface
       -----------------------
       txp                  => txp(I),    -- Differential +ve of serial transmission from PMA to PMD.
       txn                  => txn(I),    -- Differential -ve of serial transmission from PMA to PMD.
       rxp                  => rxp(I),    -- Differential +ve for serial reception from PMD to PMA.
       rxn                  => rxn(I),    -- Differential -ve for serial reception from PMD to PMA.
       
       -- GMII Interface (client MAC <=> PCS)
       --------------------------------------
       gmii_tx_clk          => gmii_tx_clk(I),--: in  -- Transmit clock from client MAC.
       gmii_rx_clk          => open,          --: out -- Receive clock to client MAC.
       gmii_txd             => gmii_txd(I),   --: in -- Transmit data from client MAC.
       gmii_tx_en           => gmii_tx_en(I), --: in -- Transmit control signal from client MAC.
       gmii_tx_er           => gmii_tx_er(I), --: in -- Transmit control signal from client MAC.
       gmii_rxd             => gmii_rxd(I),   --: out -- Received Data to client MAC.
       gmii_rx_dv           => gmii_rx_dv(I), --: out -- Received control signal to client MAC.
       gmii_rx_er           => gmii_rx_er(I), --: out -- Received control signal to client MAC.
       -- Management: Alternative to MDIO Interface
       --------------------------------------------
       
       configuration_vector => C_CONFIGURATION_VECTOR,--: in  -- Alternative to MDIO interface.
       
       -- General IO's
       ---------------
       status_vector => status_vector(I), --: out -- Core status.
       reset => SOFT_RESET,               --: in -- Asynchronous reset for entire core.
       signal_detect=> signal_detect      --: in -- Input from PMD to indicate presence of optical input.
       );
       
end generate;

---------------------------------------------------------------------------
-- PHY layer gt transceiver clock support
---------------------------------------------------------------------------
 -----------------------------------------------------------------------------
 -- An independent clock source used as the reference clock for an
 -- IDELAYCTRL (if present) and for the main GT transceiver reset logic.
 -----------------------------------------------------------------------------

 -- Route independent_clock input through a BUFG
bufg_independent_clock : BUFG
  port map (
    I         => clk_i,--independent_clock,
    O         => independent_clock_bufg
    );

core_clocking_i : gig_ethernet_pcs_pma_0_clocking
  port map(
    gtrefclk_p                => gtrefclk_p,
    gtrefclk_n                => gtrefclk_n,
    txoutclk                  => txoutclk(0),
    rxoutclk                  => rxoutclk(0),
    mmcm_reset                => mmcm_reset0,
    gtrefclk                   =>  gtrefclk,
    gtrefclk_bufg              =>  gtrefclk_bufg,
    mmcm_locked                =>  mmcm_locked,
    userclk                    =>  userclk,
    userclk2                   =>  userclk2,
    rxuserclk                  =>  rxuserclk,
    rxuserclk2                 =>  rxuserclk2
    );
 
mmcm_reset0<=mmcm_reset(0);

core_resets_i : gig_ethernet_pcs_pma_0_resets
  port map (
    reset                     => SOFT_RESET, 
    independent_clock_bufg    => independent_clock_bufg,
    pma_reset                 => pma_reset
    );


core_gt_common_i : gig_ethernet_pcs_pma_0_gt_common
  port map(
    GTREFCLK0_IN                => gtrefclk ,
    QPLLLOCK_OUT                => open,
    QPLLLOCKDETCLK_IN           => independent_clock_bufg,
    QPLLOUTCLK_OUT              => gt0_qplloutclk,
    QPLLOUTREFCLK_OUT           => gt0_qplloutrefclk,
    QPLLREFCLKLOST_OUT          => open,    
    QPLLRESET_IN                => pma_reset 
    );




---------------------------------------------------------------------------
-- Chipscope ILA Debug purpose
---------------------------------------------------------------------------
ILA_GEN : IF True GENERATE--false GENERATE--
   My_chipscope_ila_probe_0 : entity work.ila_32x8K
     PORT MAP(
       clk => clk_i,
       probe0 => probe0
       );
    
   probe0(26 downto 0)<=tx_axis_mac_tdata(1)&
                        tx_axis_mac_tvalid(1)&
                        tx_axis_mac_tfirst(1)&
                        tx_axis_mac_tready_i(1)&
                        tx_axis_mac_tlast(1)&
                        tx_fifo_overflow(1)&
                        tx_fifo_status(1)&  
                        gmii_txd(1)&
                        gmii_tx_en(1)&
                        gmii_tx_er(1);
                        
   probe0(31 downto 27)<=(others=>'0');
   
   My_chipscope_ila_probe_1 : entity work.ila_32x8K
     PORT MAP(
       clk => clk_i,
       probe0 => probe1
       );
   probe1(31 downto 0)<=std_logic_vector(count_udp_txi_trigger_rise(1)(31 downto 0)); 
   
   My_chipscope_ila_probe_2 : entity work.ila_32x8K
     PORT MAP(
       clk => clk_i,
       probe0 => probe2
       );
   
   probe2(12 downto 8)<=udp_tx_start(1)&
                        udp_tx_result_i(1)&
                        udp_tx_data_out_ready_i(1)&
                        udp_txi_data_data_out_last(1);
                        
   probe2(7 downto 0) <=udp_txi_data_data_out(1);
    
   probe2(31 downto 13)<=(others=>'0');
   
   My_chipscope_ila_probe_3 : entity work.ila_32x8K
     PORT MAP(
       clk => gmii_rx_clk(1),
       probe0 => probe3
       );
   
   probe3(9 downto 0)<=gmii_rxd(1)&
                       gmii_rx_dv(1)&
                       gmii_rx_er(1);
                       
   probe3(31 downto 10)<=(others=>'0');
   
   My_chipscope_ila_probe_4 : entity work.ila_32x8K
     PORT MAP(
       clk => clk_i,
       probe0 => probe4
       );
   
   probe4(10 downto 0)<=rx_axis_mac_tdata(1)&
                        rx_axis_mac_tvalid(1)&
                        rx_axis_mac_tready(1)&
                        rx_axis_mac_tlast(1);
                        
   probe4(31 downto 11)<=(others=>'0');
   

END GENERATE;

end structural;

