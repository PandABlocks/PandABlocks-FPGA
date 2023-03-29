--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : PandABox FPGA
-- Design name    : sfp_udpontrig
-- Module name    : sfp_udp_complete.vhd
-- Purpose        : top-level of SFP_UDP_complete design
-- Author         : Thierry GARREL (ELSYS-Design)
-- Synthesizable  : YES
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2021 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------

--==============================================================================
-- Libraries Declaration
--==============================================================================
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.axi_types.all;
  use work.ipv4_types.all;
  use work.arp_types.all;
  use work.top_defines.all;
  use work.sfp_udp_component_pkg.all; -- components declarations package

library UNISIM;
  use UNISIM.vcomponents.all;


--==============================================================================
-- Entity Declaration
--==============================================================================
entity SFP_UDP_Complete is
  generic (
    ILA_DEBUG                   : boolean := FALSE;
    CLOCK_FREQ                  : integer := 125000000;         -- freq of data_in_clk needed to timout cntr
    ARP_TIMEOUT                 : integer := 60;                -- ARP response timeout (s)
    ARP_MAX_PKT_TMO             : integer := 5;                 -- wrong nwk pkts received before set error
    MAX_ARP_ENTRIES             : integer := 255                -- max entries in the ARP store
  );
  port (
    -- Clock and Reset
    clk_i                       : in  std_logic;
    reset_i                     : in  std_logic;
    SOFT_RESET                  : in  std_logic;
    -- Block inpout
    trig_i                      : in std_logic;
    SFP_START_COUNT             : in std_logic;
    SFP_STOP_COUNT              : in std_logic;
    -- Block register readouts
    udp_txi_trigger_rise_count  : out std_logic_vector(31 downto 0);
    count_udp_tx_RESULT_ERR     : out unsigned(31 downto 0);
    SFP_STATUS_COUNT            : out std_logic_vector(31 downto 0);
    -- Block Parameters
    our_mac_address             : in std_logic_vector(47 downto 0);
    our_ip_address              : in std_logic_vector(31 downto 0);
    our_udp_port                : in std_logic_vector(15 downto 0);
    dest_ip_address             : in std_logic_vector(31 downto 0);
    dest_udp_port               : in std_logic_vector(15 downto 0);
    -- GTX I/O
    gtrefclk                    : in  std_logic;
    RXN_IN                      : in  std_logic;
    RXP_IN                      : in  std_logic;
    TXN_OUT                     : out std_logic;
    TXP_OUT                     : out std_logic
  );
end SFP_UDP_Complete;


--==============================================================================
-- Architcture Declaration
--==============================================================================
architecture structural of SFP_UDP_Complete is

  ------------------------------------------------------------------------------
  -- Component Declaration for UDP complete no mac
  ------------------------------------------------------------------------------
  -- see sfp_udp_component_pkg.vhd

  -- ILA IP used for debugging purpose
  component ila_32x8k
  port (
    clk     : in std_logic;
    probe0  : in std_logic_vector(31 downto 0)
  );
  end component;

  -------------------
  -- Constants
  -------------------
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

  constant C_RX_CONFIGURATION_VECTOR : std_logic_vector(79 DOWNTO 0) := C_RX_PAUSE_ADDR &
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

  constant C_TX_CONFIGURATION_VECTOR : std_logic_vector(79 DOWNTO 0)  :=  C_TX_PAUSE_ADDR &
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
  constant  C_CONFIGURATION_VECTOR  : std_logic_vector(4 downto 0) := '0'&    -- (4) Enable AN
                                                                      '0'&    -- (3) Disable ISOLATE
                                                                      '0'&    -- (2) Disable POWERDOWN
                                                                      "00";   -- (1 downto 0) Disable Loopback

  ---------------------------
  -- Signals
  ---------------------------

  -- MAC RX bus
  signal rx_axis_mac_tdata            : std_logic_vector(7 downto 0);
  signal rx_axis_mac_tvalid           : std_logic;
  signal rx_axis_mac_tready           : std_logic;
  signal rx_axis_mac_tlast            : std_logic;
  signal rx_mac_aclk                  : std_logic;
  -- MAC TX bus
  signal tx_axis_mac_tready_int       : std_logic;
  signal tx_axis_mac_tvalid           : std_logic;
  signal tx_axis_mac_tfirst           : std_logic;
  signal tx_axis_mac_tlast            : std_logic;
  signal tx_axis_mac_tdata            : std_logic_vector(7 downto 0);
  signal tx_mac_aclk                  : std_logic;
  signal tx_fifo_overflow             : std_logic;
  signal tx_fifo_status               : std_logic_vector(3 downto 0);

  -- GMII Interface MAC <> ETH
  signal gmii_txd                     : std_logic_vector(7 downto 0);       -- Transmit data from client MAC.
  signal gmii_tx_en                   : std_logic;                          -- Transmit control signal from client MAC.
  signal gmii_tx_er                   : std_logic;                          -- Transmit control signal from client MAC.
  signal gmii_rxd                     : std_logic_vector(7 downto 0);       -- Received Data to client MAC.
  signal gmii_rx_dv                   : std_logic;                          -- Received control signal to client MAC.
  signal gmii_rx_er                   : std_logic;                          -- Received control signal to client MAC.
  --signal gmii_isolate : std_logic_vector(2 downto 0);             -- Tristate control to electrically isolate GMII.
  signal gmii_tx_clk                  : std_logic;
  signal gmii_rx_clk                  : std_logic;

  -- control signals
  --type udp_control_type_array is array(natural range <>) of udp_control_type;
  signal control                      : udp_control_type;

  signal udp_tx_result_int            : std_logic_vector(1 downto 0);   -- tx status (changes during transmission)
  signal udp_tx_data_out_ready_int    : std_logic;                      -- indicates udp_tx is ready to take data
  signal udp_txi_data_data_out        : std_logic_vector(7 downto 0);
  signal udp_txi_data_data_out_last   : std_logic;

  --type udp_tx_type_array is array(natural range <>) of udp_tx_type;
  signal udp_txi                      : udp_tx_type;-- UDP tx cxns

  signal count_udp_txi_data_byte      : unsigned(3 downto 0);   -- count data byte number to be sent
  signal count_udp_txi_trigger_rise   : unsigned(31 downto 0);  -- count number of trigger

  signal enable_count                 : std_logic;              -- enable counting trigger and UDP send

  signal udp_tx_start                 : std_logic;              -- indicates receipt of udp header
  signal trig_prev                    : std_logic;              -- indicates receipt of udp header registered
  signal trigger_rise                 : std_logic;

  signal count_udp_tx_RESULT_ERR_i    : unsigned(31 downto 0);

  -- UDP RX signals
  signal udp_rx_start                 : std_logic; -- indicates receipt of udp header

  --type udp_rx_type_array is array(natural range <>) of udp_rx_type;
  signal udp_rxo                      : udp_rx_type;

-- IP RX signals
--type ipv4_rx_header_type_array is array(natural range <>) of ipv4_rx_header_type;
--signal ip_rx_hdr                    : ipv4_rx_header_type;

  signal glbl_rstn                : std_logic;
  signal rx_axi_rstn              : std_logic;
  signal tx_axi_rstn              : std_logic;
  signal rx_reset                 : std_logic;
  signal tx_ifg_delay             : std_logic_vector(7 DOWNTO 0);--iter frame gap delay
  signal tx_reset                 : std_logic;
  signal pause_req                : std_logic;
  signal pause_val                : std_logic_vector(15 DOWNTO 0);


  -- Transceiver Interface
  ------------------------

  signal txp                      : std_logic;  -- Differential +ve of serial transmission from PMA to PMD.
  signal txn                      : std_logic;  -- Differential -ve of serial transmission from PMA to PMD.
  signal rxp                      : std_logic;  -- Differential +ve for serial reception from PMD to PMA.
  signal rxn                      : std_logic;  -- Differential -ve for serial reception from PMD to PMA.

  signal gtx_clk_bufg             : std_logic;
  --signal rxuserclk2_out           : std_logic_vector(2 downto 0);
  signal userclk2_out             : std_logic;
  signal independent_clock_bufg   : std_logic;
  signal gtrefclk_bufg            : std_logic;
  signal txoutclk                 : std_logic;
  signal rxoutclk                 : std_logic;
  signal resetdone                : std_logic;-- The GT transceiver has completed its reset cycle
  signal cplllock                 : std_logic;
  signal mmcm_reset               : std_logic;
  --signal mmcm_reset0              : std_logic;
  signal mmcm_locked              : std_logic;-- Locked indication from MMCM
  signal userclk                  : std_logic;
  signal userclk2                 : std_logic;
  signal rxuserclk                : std_logic;
  signal rxuserclk2               : std_logic;
  signal pma_reset                : std_logic;-- transceiver PMA reset signal
  signal gt0_qplloutclk           : std_logic;
  signal gt0_qplloutrefclk        : std_logic;

  -- General IO's
  ---------------
  signal status_vector            :  std_logic_vector(15 downto 0); -- Core status.

  signal signal_detect            : std_logic; -- Input from PMD to indicate presence of optical input.

  -- CHIPSCOPE ILA probes
  signal probe0                   : std_logic_vector(31 downto 0);
  signal probe1                   : std_logic_vector(31 downto 0);
  signal probe2                   : std_logic_vector(31 downto 0);
  signal probe3                   : std_logic_vector(31 downto 0);
  signal probe4                   : std_logic_vector(31 downto 0);

  attribute keep : string;--keep name for ila probes
  attribute keep of tx_axis_mac_tdata           : signal is "true";
  attribute keep of tx_axis_mac_tvalid          : signal is "true";
  attribute keep of tx_axis_mac_tready_int      : signal is "true";
  attribute keep of tx_axis_mac_tlast           : signal is "true";
  attribute keep of gmii_txd                    : signal is "true";
  attribute keep of gmii_tx_en                  : signal is "true";
  attribute keep of gmii_tx_er                  : signal is "true";
  attribute keep of gmii_tx_clk                 : signal is "true";
  attribute keep of udp_tx_start                : signal is "true";
  attribute keep of udp_tx_result_int           : signal is "true";
  attribute keep of udp_tx_data_out_ready_int   : signal is "true";
  attribute keep of udp_txi_data_data_out       : signal is "true";
  attribute keep of udp_txi_data_data_out_last  : signal is "true";
  attribute keep of clk_i                       : signal is "true";
  attribute keep of glbl_rstn                   : signal is "true";
  attribute keep of rx_axis_mac_tdata           : signal is "true";
  attribute keep of rx_axis_mac_tvalid          : signal is "true";
  attribute keep of rx_axis_mac_tready          : signal is "true";
  attribute keep of rx_axis_mac_tlast           : signal is "true";
  attribute keep of gmii_rxd                    : signal is "true";
  attribute keep of gmii_rx_dv                  : signal is "true";
  attribute keep of gmii_rx_er                  : signal is "true";
  attribute keep of gmii_rx_clk                 : signal is "true";
  attribute keep of tx_fifo_overflow            : signal is "true";
  attribute keep of tx_fifo_status              : signal is "true";

--==============================================================================
-- Beginning of Code
--==============================================================================
begin


glbl_rstn<=not(SOFT_RESET);
rx_axi_rstn<=not(SOFT_RESET);
tx_axi_rstn<=not(SOFT_RESET);
pause_req<='0';
pause_val<=(others=>'0');

tx_ifg_delay<=(others=>'0');
signal_detect<='1';


--SFP_gen: for I in 0 to 2 generate

--   begin
   SFP_STATUS_COUNT(0)<=enable_count; --sfp status
   SFP_STATUS_COUNT(31 downto 1)<=(others=>'0');

   TXN_OUT <= txn;
   TXP_OUT <= txp;
   rxn <= RXN_IN;
   rxp <= RXP_IN;

   control.ip_controls.arp_controls.clear_cache <= SOFT_RESET;

   udp_txi.hdr.dst_ip_addr    <= dest_ip_address; -- destination ip
   udp_txi.hdr.dst_port       <= dest_udp_port;   -- udp destination port
   udp_txi.hdr.src_port       <= our_udp_port;    -- udp source port
   udp_txi.hdr.data_length    <= x"0004";         -- user data size, bytes
   udp_txi.hdr.checksum       <= x"0000";

   process(clk_i)
   begin
       if rising_edge(clk_i) then
           if (SOFT_RESET= '1') then --reset_i = '1') then
              enable_count<='0';
           else
              if SFP_STOP_COUNT='1' then
                enable_count<='0';
              elsif SFP_START_COUNT='1' then
                enable_count<='1';
              end if;
           end if;
       end if;
   end process;


   process(clk_i)
   begin
       if rising_edge(clk_i) then
           if (SOFT_RESET= '1') then
              trig_prev <= trig_i;
              udp_tx_start<='0';
           else
              trig_prev <= trig_i;
              if enable_count='1' then
                 if (trigger_rise = '1') then
                     udp_tx_start<='1';
                 elsif udp_tx_result_int = UDPTX_RESULT_NONE or udp_tx_result_int = UDPTX_RESULT_SENDING then--blocage udp_tx_result_int=UDPTX_RESULT_ERR faire traitement
                     udp_tx_start<='0';
                 else
                     udp_tx_start<=udp_tx_start;
                 end if;
              else
                  udp_tx_start<='0';
              end if;
           end if;
       end if;
   end process;

   trigger_rise <= trig_i and not(trig_prev);
   UDP_little_endian: if C_LITTLE_ENDIAN=TRUE generate-- Little endian
   begin
      process (clk_i)
      begin
      if (rising_edge(clk_i)) then
          if (SOFT_RESET = '1') then
               udp_txi_data_data_out_last<='0';
               udp_txi_data_data_out<=(others=>'0');
               count_udp_txi_data_byte<=(others=>'0');
               count_udp_txi_trigger_rise<=(others=>'0');
               count_udp_tx_RESULT_ERR_i<=(others=>'0');
          else
               if SFP_START_COUNT='1' then
                  count_udp_txi_trigger_rise<=(others=>'0');
               elsif trigger_rise='1' and enable_count='1' then
                      count_udp_txi_trigger_rise<=count_udp_txi_trigger_rise+1;
               end if;

               if enable_count='1' then
                  if udp_tx_data_out_ready_int='1' then
                      count_udp_txi_data_byte<=count_udp_txi_data_byte+1;
                      case count_udp_txi_data_byte is
                          when x"0" =>udp_txi_data_data_out_last<='0';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(15 downto 8));
                          when x"1" =>udp_txi_data_data_out_last<='0';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(23 downto 16));
                          when x"2" =>udp_txi_data_data_out_last<='1';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(31 downto 24));
                          when x"3" =>udp_txi_data_data_out_last<='1';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(7 downto 0));
                          when others =>udp_txi_data_data_out_last<='0';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(7 downto 0));
                      end case;
                  elsif udp_tx_result_int=UDPTX_RESULT_ERR then --traitement si blocage udp_tx_result_int=UDPTX_RESULT_ERR
                      count_udp_txi_data_byte<=(others=>'0');
                      udp_txi_data_data_out_last<='1';
                      udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(7 downto 0));
                      count_udp_tx_RESULT_ERR_i<=count_udp_tx_RESULT_ERR_i+1;
                  else
                      count_udp_txi_data_byte<=(others=>'0');
                      udp_txi_data_data_out_last<='0';
                      udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(7 downto 0));
                  end if;
               else
                  if SFP_START_COUNT='1' then--reset error cpt on start_count
                     count_udp_tx_RESULT_ERR_i<=(others=>'0');
                  end if;
                  count_udp_txi_data_byte<=(others=>'0');
                  udp_txi_data_data_out_last<='0';
                  udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(7 downto 0));
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
               udp_txi_data_data_out_last<='0';
               udp_txi_data_data_out<=(others=>'0');
               count_udp_txi_data_byte<=(others=>'0');
               count_udp_txi_trigger_rise<=(others=>'0');
               count_udp_tx_RESULT_ERR_i<=(others=>'0');
          else
               if SFP_START_COUNT='1' then
                  count_udp_txi_trigger_rise<=(others=>'0');
               elsif trigger_rise='1' and enable_count='1' then
                      count_udp_txi_trigger_rise<=count_udp_txi_trigger_rise+1;
               end if;

               if enable_count='1' then
                  if udp_tx_data_out_ready_int='1' then
                      count_udp_txi_data_byte<=count_udp_txi_data_byte+1;
                      case count_udp_txi_data_byte is
                          when x"0" =>udp_txi_data_data_out_last<='0';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(23 downto 16));
                          when x"1" =>udp_txi_data_data_out_last<='0';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(15 downto 8));
                          when x"2" =>udp_txi_data_data_out_last<='1';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(7 downto 0));
                          when x"3" =>udp_txi_data_data_out_last<='1';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(31 downto 24));
                          when others =>udp_txi_data_data_out_last<='0';
                                   udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(31 downto 24));
                      end case;
                  elsif udp_tx_result_int=UDPTX_RESULT_ERR then --traitement si blocage udp_tx_result_int=UDPTX_RESULT_ERR
                      count_udp_txi_data_byte<=(others=>'0');
                      udp_txi_data_data_out_last<='1';
                      udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(31 downto 24));
                      count_udp_tx_RESULT_ERR_i<=count_udp_tx_RESULT_ERR_i+1;
                  else
                      count_udp_txi_data_byte<=(others=>'0');
                      udp_txi_data_data_out_last<='0';
                      udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(31 downto 24));
                  end if;
               else
                  if SFP_START_COUNT='1' then--reset error cpt on start_count
                     count_udp_tx_RESULT_ERR_i<=(others=>'0');
                  end if;
                  count_udp_txi_data_byte<=(others=>'0');
                  udp_txi_data_data_out_last<='0';
                  udp_txi_data_data_out<=std_logic_vector(count_udp_txi_trigger_rise(31 downto 24));
               end if;
          end if;
      end if;
      end process;
   end generate;

   udp_txi_trigger_rise_count     <= std_logic_vector(count_udp_txi_trigger_rise);
   udp_txi.data.data_out_valid    <= udp_tx_data_out_ready_int;
   udp_txi.data.data_out_last     <= udp_txi_data_data_out_last;
   udp_txi.data.data_out          <= udp_txi_data_data_out;
   count_udp_tx_RESULT_ERR        <= count_udp_tx_RESULT_ERR_i;

  ------------------------------------------------------------------------------
  -- Instantiate the UDP layer with PING
  ------------------------------------------------------------------------------
  udp_block: udp_complete_ping_nomac
    generic map (
      CLOCK_FREQ              => CLOCK_FREQ,
      ARP_TIMEOUT             => ARP_TIMEOUT,
      ARP_MAX_PKT_TMO         => ARP_MAX_PKT_TMO,
      MAX_ARP_ENTRIES         => MAX_ARP_ENTRIES,
      NB_TX_CHANNELS          => 2                -- number of ip_tx_artitrator input channels
    )
    port map (
      -- System signals (in)
      rx_clk                  => clk_i,
      tx_clk                  => clk_i,
      reset                   => SOFT_RESET,
      our_ip_address          => our_ip_address,
      our_mac_address         => our_mac_address,
      control                 => control,
      -- Status signals (out)
      arp_pkt_count           => open,
      ip_pkt_count            => open,
      icmp_pkt_count          => open,
      icmp_pkt_err            => open,
      icmp_pkt_err_count      => open,
      -- UDP TX signals (in)
      udp_tx_start            => udp_tx_start,
      udp_txi                 => udp_txi,
      udp_tx_result           => udp_tx_result_int,             -- out
      udp_tx_data_out_ready   => udp_tx_data_out_ready_int,     -- out
      -- UDP RX signals (out)
      udp_rx_start            => udp_rx_start,
      udp_rxo                 => udp_rxo,
      -- IP RX signals (out) // DEBUG
      ip_rx_start_o           => open,
      ip_rx_hdr_o             => open,
      ip_rx_data_o            => open,
      -- IP TX status (out) // DEBUG
      ip_tx_start_o           => open,
      ip_tx_result_o          => open,
      -- MAC Receiver (in)
      mac_rx_tready           => rx_axis_mac_tready,        -- out
      mac_rx_tdata            => rx_axis_mac_tdata,
      mac_rx_tvalid           => rx_axis_mac_tvalid,
      mac_rx_tlast            => rx_axis_mac_tlast,
      -- MAC Transmitter (out)
      mac_tx_tready           => tx_axis_mac_tready_int,      -- in
      mac_tx_tvalid           => tx_axis_mac_tvalid,
      mac_tx_tfirst           => tx_axis_mac_tfirst,
      mac_tx_tlast            => tx_axis_mac_tlast,
      mac_tx_tdata            => tx_axis_mac_tdata
    );


     ------------------------------------------------------------------------------
     -- Instantiate the MAC layer
     ------------------------------------------------------------------------------
   eth_mac_fifo_i : tri_mode_ethernet_mac_0_fifo_block
     port map (
       gtx_clk                    => gtx_clk_bufg,
       -- asynchronous reset
       glbl_rstn                  => glbl_rstn,
       rx_axi_rstn                => rx_axi_rstn,
       tx_axi_rstn                => tx_axi_rstn,

       -- Receiver Statistics Interface
       -----------------------------------------
       rx_mac_aclk                => rx_mac_aclk,
       rx_reset                   => rx_reset,
       rx_statistics_vector       => open,
       rx_statistics_valid        => open,

       -- Receiver (AXI-S) Interface
       ------------------------------------------
       rx_fifo_clock              => clk_i,
       rx_fifo_resetn             => glbl_rstn,
       rx_axis_fifo_tdata         => rx_axis_mac_tdata,
       rx_axis_fifo_tvalid        => rx_axis_mac_tvalid,
       rx_axis_fifo_tready        => rx_axis_mac_tready,
       rx_axis_fifo_tlast         => rx_axis_mac_tlast,

       -- Transmitter Statistics Interface
       --------------------------------------------
       tx_mac_aclk                => tx_mac_aclk,
       tx_reset                   => tx_reset,
       tx_ifg_delay               => tx_ifg_delay,
       tx_statistics_vector       => open,
       tx_statistics_valid        => open,

       -- Transmitter (AXI-S) Interface
       ---------------------------------------------
       tx_fifo_clock              => clk_i,
       tx_fifo_resetn             => glbl_rstn,
       tx_axis_fifo_tdata         => tx_axis_mac_tdata,
       tx_axis_fifo_tvalid        => tx_axis_mac_tvalid,
       tx_axis_fifo_tready        => tx_axis_mac_tready_int,        -- out
       tx_axis_fifo_tlast         => tx_axis_mac_tlast,
       tx_fifo_overflow           => tx_fifo_overflow,
       tx_fifo_status             => tx_fifo_status,

       -- MAC Control Interface
       --------------------------
       pause_req                  => pause_req,
       pause_val                  => pause_val,

       -- GMII Interface
       -------------------
       gmii_txd                  => gmii_txd,
       gmii_tx_en                => gmii_tx_en,
       gmii_tx_er                => gmii_tx_er,
       gmii_tx_clk               => gmii_tx_clk,
       gmii_rxd                  => gmii_rxd,
       gmii_rx_dv                => gmii_rx_dv,
       gmii_rx_er                => gmii_rx_er,
       gmii_rx_clk               => gmii_rx_clk,

       -- Configuration Vector
       -------------------------
       rx_configuration_vector   => C_RX_CONFIGURATION_VECTOR,
       tx_configuration_vector   => C_TX_CONFIGURATION_VECTOR
       );

   userclk2_out <= userclk2;
   gmii_tx_clk  <= userclk2_out;
   gmii_rx_clk  <= userclk2_out;
   gtx_clk_bufg <= gtrefclk_bufg;

     ------------------------------------------------------------------------------
     -- Instantiate the PHY layer
     ------------------------------------------------------------------------------

   eth_phy_i : gig_ethernet_pcs_pma_0_example_design
     port map (
       --An independent clock source used as the reference clock for an
       --IDELAYCTRL (if present) and for the main GT transceiver reset logic.
       --This example design assumes that this is of frequency 200MHz.
       independent_clock_bufg    => independent_clock_bufg,

       gtrefclk           => gtrefclk,
       gtrefclk_bufg      => gtrefclk_bufg,

       txoutclk           => txoutclk,
       rxoutclk           => rxoutclk,
       resetdone          => resetdone,     -- The GT transceiver has completed its reset cycle
       cplllock           => cplllock,
       mmcm_reset         => mmcm_reset,
       mmcm_locked        => mmcm_locked,   -- Locked indication from MMCM
       userclk            => userclk,
       userclk2           => userclk2,
       rxuserclk          => rxuserclk,
       rxuserclk2         => rxuserclk2,
       pma_reset          => pma_reset,     -- transceiver PMA reset signal
       gt0_qplloutclk     => gt0_qplloutclk,
       gt0_qplloutrefclk  => gt0_qplloutrefclk,

       -- Tranceiver Interface
       -----------------------
       txp                  => txp,    -- Differential +ve of serial transmission from PMA to PMD.
       txn                  => txn,    -- Differential -ve of serial transmission from PMA to PMD.
       rxp                  => rxp,    -- Differential +ve for serial reception from PMD to PMA.
       rxn                  => rxn,    -- Differential -ve for serial reception from PMD to PMA.

       -- GMII Interface (client MAC <=> PCS)
       --------------------------------------
       gmii_tx_clk          => gmii_tx_clk,--: in  -- Transmit clock from client MAC.
       gmii_rx_clk          => open,          --: out -- Receive clock to client MAC.
       gmii_txd             => gmii_txd,   --: in -- Transmit data from client MAC.
       gmii_tx_en           => gmii_tx_en, --: in -- Transmit control signal from client MAC.
       gmii_tx_er           => gmii_tx_er, --: in -- Transmit control signal from client MAC.
       gmii_rxd             => gmii_rxd,   --: out -- Received Data to client MAC.
       gmii_rx_dv           => gmii_rx_dv, --: out -- Received control signal to client MAC.
       gmii_rx_er           => gmii_rx_er, --: out -- Received control signal to client MAC.
       -- Management: Alternative to MDIO Interface
       --------------------------------------------

       configuration_vector => C_CONFIGURATION_VECTOR,--: in  -- Alternative to MDIO interface.

       -- General IO's
       ---------------
       status_vector => status_vector, --: out -- Core status.
       reset => SOFT_RESET,               --: in -- Asynchronous reset for entire core.
       signal_detect=> signal_detect      --: in -- Input from PMD to indicate presence of optical input.
       );

--end generate;

---------------------------------------------------------------------------
-- PHY layer gt transceiver clock support
---------------------------------------------------------------------------
 -----------------------------------------------------------------------------
 -- An independent clock source used as the reference clock for an
 -- IDELAYCTRL (if present) and for the main GT transceiver reset logic.
 -----------------------------------------------------------------------------

-- BUFG bypassed as build would fail with new clocking scheme
-- GBC:20190405

 -- Route independent_clock input through a BUFG
--bufg_independent_clock : BUFG
--  port map (
--    I         => clk_i,--independent_clock,
--    O         => independent_clock_bufg
--    );
independent_clock_bufg <= clk_i;

core_clocking_i : gig_ethernet_pcs_pma_0_clocking
  port map (
    gtrefclk              => gtrefclk,
    txoutclk              => txoutclk,
    rxoutclk              => rxoutclk,
    mmcm_reset            => mmcm_reset,
    gtrefclk_bufg         => gtrefclk_bufg,
    mmcm_locked           => mmcm_locked,
    userclk               => userclk,
    userclk2              => userclk2,
    rxuserclk             => rxuserclk,
    rxuserclk2            => rxuserclk2
    );

--mmcm_reset0<=mmcm_reset(0);

core_resets_i : gig_ethernet_pcs_pma_0_resets
  port map (
    reset                   => SOFT_RESET,
    independent_clock_bufg  => independent_clock_bufg,
    pma_reset               => pma_reset
    );


core_gt_common_i : gig_ethernet_pcs_pma_0_gt_common
  port map (
    GTREFCLK0_IN            => gtrefclk ,
    QPLLLOCK_OUT            => open,
    QPLLLOCKDETCLK_IN       => independent_clock_bufg,
    QPLLOUTCLK_OUT          => gt0_qplloutclk,
    QPLLOUTREFCLK_OUT       => gt0_qplloutrefclk,
    QPLLREFCLKLOST_OUT      => open,
    QPLLRESET_IN            => pma_reset
    );


  ---------------------------------------------------------------------------
  -- Chipscope ILA Debug purpose
  ---------------------------------------------------------------------------
  ILA_GEN : if ILA_DEBUG generate

    -- ILA probe 0
    My_chipscope_ila_probe_0 : ila_32x8K
    port map (
      clk => clk_i,
      probe0 => probe0
    );

    probe0(31 downto 27) <= (others=>'0');
    probe0(26 downto 0)  <= tx_axis_mac_tdata &
                            tx_axis_mac_tvalid &
                            tx_axis_mac_tfirst &
                            tx_axis_mac_tready_int &
                            tx_axis_mac_tlast &
                            tx_fifo_overflow &
                            tx_fifo_status &
                            gmii_txd &
                            gmii_tx_en &
                            gmii_tx_er;


    -- ILA probe 1
    My_chipscope_ila_probe_1 : ila_32x8K
    port map (
      clk => clk_i,
      probe0 => probe1
    );

    probe1(31 downto 0) <= std_logic_vector(count_udp_txi_trigger_rise(31 downto 0));

    -- ILA probe 2
    My_chipscope_ila_probe_2 : ila_32x8K
    port map (
      clk => clk_i,
      probe0 => probe2
    );

    probe2(31 downto 13) <= (others=>'0');
    probe2(12 downto 8)  <= udp_tx_start &
                            udp_tx_result_int &
                            udp_tx_data_out_ready_int &
                            udp_txi_data_data_out_last;
    probe2(7 downto 0)   <= udp_txi_data_data_out;

    -- ILA probe 3
    My_chipscope_ila_probe_3 : ila_32x8K
    port map (
      clk => gmii_rx_clk,
      probe0 => probe3
    );

    probe3(31 downto 10) <= (others=>'0');
    probe3(9 downto 0)   <= gmii_rxd &
                            gmii_rx_dv &
                            gmii_rx_er;

    -- ILA probe 4
    My_chipscope_ila_probe_4 : ila_32x8K
    port map (
      clk => clk_i,
      probe0 => probe4
    );

    probe4(31 downto 11) <= (others=>'0');
    probe4(10 downto 0)  <= rx_axis_mac_tdata &
                            rx_axis_mac_tvalid &
                            rx_axis_mac_tready &
                            rx_axis_mac_tlast;

  end generate; -- ILA_GEN

end structural;
--==============================================================================
-- End of Code
--==============================================================================


