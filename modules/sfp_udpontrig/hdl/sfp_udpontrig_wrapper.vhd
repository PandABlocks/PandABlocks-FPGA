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

entity sfp_udpontrig_wrapper is
generic ( DEBUG : string := "FALSE" );
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- System Bus
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;

    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic := '1';

    -- SFP Interface
    SFP_i               : in SFP_input_interface;
    SFP_o               : out SFP_output_interface
);
end sfp_udpontrig_wrapper;

architecture rtl of sfp_udpontrig_wrapper is

component SFP_UDP_Complete
    generic (
    DEBUG               : string  := "FALSE";
    CLOCK_FREQ                  : integer := 125000000;  -- freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT                 : integer := 60;         -- ARP response timeout (s)
    ARP_MAX_PKT_TMO     : integer := 5;              -- wrong nwk pkts received before set error
    MAX_ARP_ENTRIES     : integer := 255         -- max entries in the ARP store
    );
    Port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    SOFT_RESET          : in  std_logic;
    -- Block inpout
    trig_i                     : in std_logic;
    SFP_START_COUNT            : in std_logic;
    SFP_STOP_COUNT             : in std_logic;
    -- Block register readouts
    udp_txi_trigger_rise_count : out std_logic_vector(31 downto 0);
    count_udp_tx_RESULT_ERR    : out unsigned(31 downto 0);
    SFP_STATUS_COUNT           : out std_logic_vector(31 downto 0);
    -- Block Parameters
    OUR_MAC_ADDRESS : in std_logic_vector(47 downto 0);
    dest_udp_port : in std_logic_vector(15 downto 0);
    our_udp_port  : in std_logic_vector(15 downto 0);
    dest_ip_address : in std_logic_vector(31 downto 0);
    our_ip_address  : in std_logic_vector(31 downto 0);
    -- GTX I/O
    gtrefclk         : in  std_logic;
    RXN_IN              : in  std_logic;
    RXP_IN              : in  std_logic;
    TXN_OUT             : out std_logic;
    TXP_OUT             : out std_logic
    );
end component;

signal trig                       : std_logic;
signal udp_txi_trigger_rise_count : std_logic_vector(31 downto 0);
signal count_udp_tx_RESULT_ERR_i  : unsigned(31 downto 0);

signal SFP_LOS_VEC      : std_logic_vector(31 downto 0) := (others => '0');

signal SFP_STATUS_COUNT           : std_logic_vector(31 downto 0);
signal SFP_START_COUNT            : std_logic;
signal SFP_STOP_COUNT             : std_logic;

signal MAC_LO                  : std_logic_vector(31 downto 0) := (others => '0');
signal MAC_HI                  : std_logic_vector(31 downto 0) := (others => '0');

signal dest_udp_port32         : std_logic_vector(31 downto 0);
signal our_udp_port32          : std_logic_vector(31 downto 0);
signal dest_udp_port           : std_logic_vector(15 downto 0);
signal our_udp_port            : std_logic_vector(15 downto 0);

signal dest_ip_address_byte1 : std_logic_vector(31 downto 0);
signal dest_ip_address_byte2 : std_logic_vector(31 downto 0);
signal dest_ip_address_byte3 : std_logic_vector(31 downto 0);
signal dest_ip_address_byte4 : std_logic_vector(31 downto 0);
signal dest_ip_address       : std_logic_vector(31 downto 0);

signal our_ip_address_byte1  : std_logic_vector(31 downto 0);
signal our_ip_address_byte2  : std_logic_vector(31 downto 0);
signal our_ip_address_byte3  : std_logic_vector(31 downto 0);
signal our_ip_address_byte4  : std_logic_vector(31 downto 0);
signal our_ip_address        : std_logic_vector(31 downto 0);

signal SOFT_RESET        : std_logic;
signal SOFT_RESET_prev   : std_logic;
signal SOFT_RESET_rise   : std_logic;
signal soft_reset_cpt    : unsigned(31 downto 0);
signal SOFT_RESET_holded : std_logic;

signal TXN                : std_logic;
signal TXP                : std_logic;

begin

txnobuf : obuf
port map (
    I => TXN,
    O => SFP_o.TXN_OUT
);

txpobuf : obuf
port map (
    I => TXP,
    O => SFP_o.TXP_OUT
);

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY_i     => RD_ADDR2ACK
    );

our_ip_address<=our_ip_address_byte1(7 downto 0)&our_ip_address_byte2(7 downto 0)&our_ip_address_byte3(7 downto 0)&our_ip_address_byte4(7 downto 0);
dest_ip_address<=dest_ip_address_byte1(7 downto 0)&dest_ip_address_byte2(7 downto 0)&dest_ip_address_byte3(7 downto 0)&dest_ip_address_byte4(7 downto 0);
our_udp_port<=dest_udp_port32(15 downto 0);
dest_udp_port<=dest_udp_port32(15 downto 0);



SFP_UDP_Complete_i : SFP_UDP_Complete
    generic map (
    DEBUG           => DEBUG,
    CLOCK_FREQ          => 125000000,   -- freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT         => 60,          -- ARP response timeout (s)
    ARP_MAX_PKT_TMO     => 5,           -- wrong nwk pkts received before set error
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
    OUR_MAC_ADDRESS =>SFP_i.MAC_ADDR,
    dest_udp_port  =>dest_udp_port,
    our_udp_port   =>our_udp_port,
    dest_ip_address=>dest_ip_address,
    our_ip_address =>our_ip_address,
    -- GTX I/O
    gtrefclk       => SFP_i.GTREFCLK,
    RXN_IN         => SFP_i.RXN_IN,
    RXP_IN         => SFP_i.RXP_IN,
    TXN_OUT        => TXN,
    TXP_OUT        => TXP
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

MAC_HI(23 downto 0) <= SFP_i.MAC_ADDR(47 downto 24);
MAC_LO(23 downto 0) <= SFP_i.MAC_ADDR(23 downto 0);

SFP_LOS_VEC <= (0 => SFP_i.SFP_LOS, others => '0');
---------------------------------------------------------------------------
-- SFP Control Interface
---------------------------------------------------------------------------
sfp_ctrl : entity work.sfp_udpontrig_ctrl
port map (
    -- Clock and Reset
    clk_i                       => clk_i,
    reset_i                     => reset_i,
    bit_bus_i                   => bit_bus_i,
    pos_bus_i                   => pos_bus_i,
    -- Block inpout
    sfp_trig_from_bus          => trig,
    SFP_START_COUNT            => open,
    SFP_STOP_COUNT             => open,
    SFP_START_COUNT_WSTB       => SFP_START_COUNT,
    SFP_STOP_COUNT_WSTB        => SFP_STOP_COUNT,
    -- Block register readouts
    sfp_trig_rise_count        => udp_txi_trigger_rise_count,
    SFP_COUNT_UDPTX_ERR        => std_logic_vector(count_udp_tx_RESULT_ERR_i),
    sfp_status_count           => SFP_STATUS_COUNT,
    -- Block Parameters
    SFP_LOS                    =>  SFP_LOS_VEC,
    SFP_MAC_LO                 => MAC_LO,
    SFP_MAC_HI                 => MAC_HI,
    SFP_DEST_UDP_PORT          => dest_udp_port32,
    SFP_OUR_UDP_PORT           => our_udp_port32,
    SFP_DEST_IP_AD_BYTE1       => dest_ip_address_byte1,
    SFP_DEST_IP_AD_BYTE2       => dest_ip_address_byte2,
    SFP_DEST_IP_AD_BYTE3       => dest_ip_address_byte3,
    SFP_DEST_IP_AD_BYTE4       => dest_ip_address_byte4,
    SFP_OUR_IP_AD_BYTE1        => our_ip_address_byte1,
    SFP_OUR_IP_AD_BYTE2        => our_ip_address_byte2,
    SFP_OUR_IP_AD_BYTE3        => our_ip_address_byte3,
    SFP_OUR_IP_AD_BYTE4        => our_ip_address_byte4,
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

