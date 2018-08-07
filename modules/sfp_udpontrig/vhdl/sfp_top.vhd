--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Gauthier THIBAUX (gauthier.thibaux@synchrotron-soleil.fr)
--------------------------------------------------------------------------------
--
--  Description : UDP frame sends on trigger input top-level module. This block instantiates:
--
--                  * sfp_ctrl: Block control and status interface
--                  * SFP_UDP_Complete : UDP block using UDP_IP_Stack from opencores.org and eth MAC and PHY xilinx IP
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity sfp_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- System Bus
    sysbus_i            : in  std_logic_vector(SBUSW-1 downto 0);
    sfp_inputs_o        : out std_logic_vector(15 downto 0);
    sfp_data_o          : out std32_array(15 downto 0);
    
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- SFP Loss of signal
    SFP_LOS             : in   std_logic_vector(1 downto 0);
    -- GTX I/O
    GTREFCLK_N          : in  std_logic;
    GTREFCLK_P          : in  std_logic;
    RXN_IN              : in  std_logic_vector(2 downto 0);
    RXP_IN              : in  std_logic_vector(2 downto 0);
    TXN_OUT             : out std_logic_vector(2 downto 0);
    TXP_OUT             : out std_logic_vector(2 downto 0)
);
end sfp_top;

architecture rtl of sfp_top is

component SFP_UDP_Complete 
    generic (
    CLOCK_FREQ			: integer := 125000000;  -- freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT			: integer := 60;         -- ARP response timeout (s)
    ARP_MAX_PKT_TMO	: integer := 5;              -- wrong nwk pkts received before set error
    MAX_ARP_ENTRIES 	: integer := 255         -- max entries in the ARP store
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
end component;

signal trig                       : std_logic_vector(2 downto 0);
signal udp_txi_trigger_rise_count : std32_array(2 downto 0);
signal count_udp_tx_RESULT_ERR_i  : unsigned32_array(2 downto 0);

signal SFP2_LOS                   : std_logic_vector(31 downto 0);
signal SFP1_LOS                   : std_logic_vector(31 downto 0);

signal SFP_STATUS_COUNT           : std32_array(2 downto 0);
signal SFP_START_COUNT            : std_logic_vector(2 downto 0);
signal SFP_STOP_COUNT             : std_logic_vector(2 downto 0);

signal OUR_MAC_ADDRESS         : std48_array(2 downto 0);
signal MAC_LO                  : std32_array(2 downto 0);
signal MAC_HI                  : std32_array(2 downto 0);

signal dest_udp_port32         : std32_array(2 downto 0);
signal our_udp_port32          : std32_array(2 downto 0);
signal dest_udp_port           : std16_array(2 downto 0);
signal our_udp_port            : std16_array(2 downto 0);

signal dest_ip_address_byte1 : std32_array(2 downto 0);
signal dest_ip_address_byte2 : std32_array(2 downto 0);
signal dest_ip_address_byte3 : std32_array(2 downto 0);
signal dest_ip_address_byte4 : std32_array(2 downto 0);
signal dest_ip_address       : std32_array(2 downto 0);

signal our_ip_address_byte1  : std32_array(2 downto 0);
signal our_ip_address_byte2  : std32_array(2 downto 0);
signal our_ip_address_byte3  : std32_array(2 downto 0);
signal our_ip_address_byte4  : std32_array(2 downto 0);
signal our_ip_address        : std32_array(2 downto 0); 

signal SOFT_RESET        : std_logic;
signal SOFT_RESET_prev   : std_logic;
signal SOFT_RESET_rise   : std_logic;
signal soft_reset_cpt    : unsigned(31 downto 0);
signal SOFT_RESET_holded : std_logic;

begin
--unused signals
sfp_inputs_o<=(others=>'0');
sfp_data_o <=(others=>(others=>'0')); 

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY       => RD_ADDR2ACK
    );

our_ip_address(0)<=our_ip_address_byte1(0)(7 downto 0)&our_ip_address_byte2(0)(7 downto 0)&our_ip_address_byte3(0)(7 downto 0)&our_ip_address_byte4(0)(7 downto 0);
our_ip_address(1)<=our_ip_address_byte1(1)(7 downto 0)&our_ip_address_byte2(1)(7 downto 0)&our_ip_address_byte3(1)(7 downto 0)&our_ip_address_byte4(1)(7 downto 0);
our_ip_address(2)<=our_ip_address_byte1(2)(7 downto 0)&our_ip_address_byte2(2)(7 downto 0)&our_ip_address_byte3(2)(7 downto 0)&our_ip_address_byte4(2)(7 downto 0);

dest_ip_address(0)<=dest_ip_address_byte1(0)(7 downto 0)&dest_ip_address_byte2(0)(7 downto 0)&dest_ip_address_byte3(0)(7 downto 0)&dest_ip_address_byte4(0)(7 downto 0);
dest_ip_address(1)<=dest_ip_address_byte1(1)(7 downto 0)&dest_ip_address_byte2(1)(7 downto 0)&dest_ip_address_byte3(1)(7 downto 0)&dest_ip_address_byte4(1)(7 downto 0);
dest_ip_address(2)<=dest_ip_address_byte1(2)(7 downto 0)&dest_ip_address_byte2(2)(7 downto 0)&dest_ip_address_byte3(2)(7 downto 0)&dest_ip_address_byte4(2)(7 downto 0);

our_udp_port(0)<=dest_udp_port32(0)(15 downto 0);
our_udp_port(1)<=dest_udp_port32(1)(15 downto 0);
our_udp_port(2)<=dest_udp_port32(2)(15 downto 0);
dest_udp_port(0)<=dest_udp_port32(0)(15 downto 0);
dest_udp_port(1)<=dest_udp_port32(1)(15 downto 0);
dest_udp_port(2)<=dest_udp_port32(2)(15 downto 0);

SFP_UDP_Complete_i : SFP_UDP_Complete 
    generic map (
    CLOCK_FREQ		=> 125000000,   -- freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT		=> 60,          -- ARP response timeout (s)
    ARP_MAX_PKT_TMO	=> 5,           -- wrong nwk pkts received before set error
    MAX_ARP_ENTRIES => 255          -- max entries in the ARP store
    )
    port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    SOFT_RESET          => SOFT_RESET_holded,
    -- Block inpout
    trig_i              => trig,--Rising edge to send UDP user-defined frame
    SFP_START_COUNT     => SFP_START_COUNT,
    SFP_STOP_COUNT      => SFP_STOP_COUNT, 
    -- Block register readouts 
    udp_txi_trigger_rise_count=> udp_txi_trigger_rise_count,
    count_udp_tx_RESULT_ERR   => count_udp_tx_RESULT_ERR_i, 
    SFP_STATUS_COUNT          => SFP_STATUS_COUNT,
    -- Block Parameters
    OUR_MAC_ADDRESS =>OUR_MAC_ADDRESS,
    dest_udp_port  =>dest_udp_port,
    our_udp_port   =>our_udp_port,
    dest_ip_address=>dest_ip_address,
    our_ip_address =>our_ip_address,
    -- GTX I/O
    gtrefclk_n          => GTREFCLK_N,
    gtrefclk_p          => GTREFCLK_P,
    
    RXN_IN(0)           => RXN_IN(0),
    RXN_IN(1)           => RXN_IN(1),
    RXN_IN(2)           => RXN_IN(2),
    
    RXP_IN(0)           => RXP_IN(0),
    RXP_IN(1)           => RXP_IN(1),
    RXP_IN(2)           => RXP_IN(2),
    
    TXN_OUT(0)          => TXN_OUT(0),
    TXN_OUT(1)          => TXN_OUT(1),
    TXN_OUT(2)          => TXN_OUT(2),
    
    TXP_OUT(0)          => TXP_OUT(0),
    TXP_OUT(1)          => TXP_OUT(1),
    TXP_OUT(2)          => TXP_OUT(2)
    );

---------------------------------------------------------------------------
-- SFP Clocks Frequency Counter
---------------------------------------------------------------------------



process(clk_i)
constant SOFT_RESET_HOLDED_CLK_NUMBER : unsigned(soft_reset_cpt'high downto 0) := to_unsigned(100,soft_reset_cpt'length);
begin
if (falling_edge(clk_i)) then
   if (reset_i='1') then
      soft_reset_cpt<=SOFT_RESET_HOLDED_CLK_NUMBER;
      SOFT_RESET_prev<=SOFT_RESET;
      SOFT_RESET_holded<='1';
   else
     SOFT_RESET_prev<=SOFT_RESET;
     if soft_reset_cpt=to_unsigned(0,soft_reset_cpt'length) then 
        SOFT_RESET_holded<='0';
        if SOFT_RESET_rise='1' then
           soft_reset_cpt<=SOFT_RESET_HOLDED_CLK_NUMBER;
        end if;
     else 
        SOFT_RESET_holded<='1';
        soft_reset_cpt<=soft_reset_cpt-1;
     end if;
   end if;
end if;
end process;

SOFT_RESET_rise<=SOFT_RESET and not(SOFT_RESET_prev);

OUR_MAC_ADDRESS(2)(23 downto 0) <=MAC_LO(2)(23 downto 0);
OUR_MAC_ADDRESS(2)(47 downto 24)<=MAC_HI(2)(23 downto 0);
OUR_MAC_ADDRESS(1)(23 downto 0) <=MAC_LO(1)(23 downto 0);
OUR_MAC_ADDRESS(1)(47 downto 24)<=MAC_HI(1)(23 downto 0);
OUR_MAC_ADDRESS(0)(23 downto 0) <=MAC_LO(0)(23 downto 0);
OUR_MAC_ADDRESS(0)(47 downto 24)<=MAC_HI(0)(23 downto 0);

SFP2_LOS(31 downto 1)<= (others=>'0');
SFP1_LOS(31 downto 1)<= (others=>'0');
SFP2_LOS(0)<= SFP_LOS(1);
SFP1_LOS(0)<= SFP_LOS(0);
---------------------------------------------------------------------------
-- SFP Control Interface
---------------------------------------------------------------------------
sfp_ctrl : entity work.sfp_ctrl
port map (
    -- Clock and Reset
    clk_i                       => clk_i,
    reset_i                     => reset_i,
    sysbus_i                    => sysbus_i,
    posbus_i                    => (others => (others => '0')),
    -- Block inpout
    --#SFP3_rx !front SFP1
    sfp1_trig_o                 => trig(0),
    SFP1_START_COUNT            => open,
    SFP1_STOP_COUNT             => open,
    SFP1_START_COUNT_WSTB       => SFP_START_COUNT(0),
    SFP1_STOP_COUNT_WSTB        =>  SFP_STOP_COUNT(0),
    -- Block register readouts 
    sfp1_trig_rise_count        => udp_txi_trigger_rise_count(0),
    SFP1_COUNT_UDPTX_ERR        =>std_logic_vector(count_udp_tx_RESULT_ERR_i(0)), 
    sfp1_status_count           => SFP_STATUS_COUNT(0),
    -- Block Parameters  
    SFP1_LOS                    =>  SFP1_LOS,
    SFP1_MAC_LO                 => MAC_LO(0),
    SFP1_MAC_HI                 => MAC_HI(0),      
    SFP1_DEST_UDP_PORT          => dest_udp_port32(0),
    SFP1_OUR_UDP_PORT           =>  our_udp_port32(0),
    SFP1_DEST_IP_AD_BYTE1  =>dest_ip_address_byte1(0),
    SFP1_DEST_IP_AD_BYTE2  =>dest_ip_address_byte2(0),
    SFP1_DEST_IP_AD_BYTE3  =>dest_ip_address_byte3(0),
    SFP1_DEST_IP_AD_BYTE4  =>dest_ip_address_byte4(0),
    SFP1_OUR_IP_AD_BYTE1   => our_ip_address_byte1(0),
    SFP1_OUR_IP_AD_BYTE2   => our_ip_address_byte2(0),
    SFP1_OUR_IP_AD_BYTE3   => our_ip_address_byte3(0),
    SFP1_OUR_IP_AD_BYTE4   => our_ip_address_byte4(0),
    -- Block inpout            
    sfp2_trig_o                 => trig(1),
    SFP2_START_COUNT            => open,
    SFP2_STOP_COUNT             => open,
    SFP2_START_COUNT_WSTB       => SFP_START_COUNT(1),
    SFP2_STOP_COUNT_WSTB        =>  SFP_STOP_COUNT(1),
    -- Block register readouts 
    sfp2_trig_rise_count        => udp_txi_trigger_rise_count(1),
    SFP2_COUNT_UDPTX_ERR        =>std_logic_vector(count_udp_tx_RESULT_ERR_i(1)), 
    sfp2_status_count           => SFP_STATUS_COUNT(1),
    -- Block Parameters        
    SFP2_LOS                    =>  SFP2_LOS,
    SFP2_MAC_LO                 => MAC_LO(1),
    SFP2_MAC_HI                 => MAC_HI(1),
    SFP2_DEST_UDP_PORT          => dest_udp_port32(1),
    SFP2_OUR_UDP_PORT           =>  our_udp_port32(1),
    SFP2_DEST_IP_AD_BYTE1  =>dest_ip_address_byte1(1),
    SFP2_DEST_IP_AD_BYTE2  =>dest_ip_address_byte2(1),
    SFP2_DEST_IP_AD_BYTE3  =>dest_ip_address_byte3(1),
    SFP2_DEST_IP_AD_BYTE4  =>dest_ip_address_byte4(1),
    SFP2_OUR_IP_AD_BYTE1   => our_ip_address_byte1(1),
    SFP2_OUR_IP_AD_BYTE2   => our_ip_address_byte2(1),
    SFP2_OUR_IP_AD_BYTE3   => our_ip_address_byte3(1),
    SFP2_OUR_IP_AD_BYTE4   => our_ip_address_byte4(1),
    -- Block inpout            
    sfp3_trig_o                 => trig(2),
    SFP3_START_COUNT            => open,
    SFP3_STOP_COUNT             => open,
    SFP3_START_COUNT_WSTB       => SFP_START_COUNT(2),
    SFP3_STOP_COUNT_WSTB        =>  SFP_STOP_COUNT(2),
    -- Block register readouts 
    sfp3_trig_rise_count        => udp_txi_trigger_rise_count(2),
    SFP3_COUNT_UDPTX_ERR        =>std_logic_vector(count_udp_tx_RESULT_ERR_i(2)), 
    sfp3_status_count           => SFP_STATUS_COUNT(2),
    -- Block Parameters        
    SFP3_MAC_LO            =>     MAC_LO(2),
    SFP3_MAC_HI            =>     MAC_HI(2),
    SFP3_DEST_UDP_PORT          =>      dest_udp_port32(2),
    SFP3_OUR_UDP_PORT           =>       our_udp_port32(2),
    SFP3_DEST_IP_AD_BYTE1  =>dest_ip_address_byte1(2),
    SFP3_DEST_IP_AD_BYTE2  =>dest_ip_address_byte2(2),
    SFP3_DEST_IP_AD_BYTE3  =>dest_ip_address_byte3(2),
    SFP3_DEST_IP_AD_BYTE4  =>dest_ip_address_byte4(2),
    SFP3_OUR_IP_AD_BYTE1   => our_ip_address_byte1(2),
    SFP3_OUR_IP_AD_BYTE2   => our_ip_address_byte2(2),
    SFP3_OUR_IP_AD_BYTE3   => our_ip_address_byte3(2),
    SFP3_OUR_IP_AD_BYTE4   => our_ip_address_byte4(2),
    SOFT_RESET                  => open,
    SOFT_RESET_WSTB             => SOFT_RESET,
    -- Memory Bus Interface
    read_strobe_i               => read_strobe_i,
    read_address_i              => read_address_i(BLK_AW-1 downto 0),
    read_data_o                 => read_data_o,
    read_ack_o                  => open,

    write_strobe_i              => write_strobe_i,
    write_address_i             => write_address_i(BLK_AW-1 downto 0),
    write_data_i                => write_data_i,
    write_ack_o                 => open
);

end rtl;

