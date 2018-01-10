library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

library unisim;
use unisim.vcomponents.all;

entity sfp_top is
port (
    -- Clock and Reset
    clk_i             : in  std_logic;
    reset_i           : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i     : in  std_logic;
    read_address_i    : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o       : out std_logic_vector(31 downto 0);
    read_ack_o        : out std_logic;

    write_strobe_i    : in  std_logic;
    write_address_i   : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i      : in  std_logic_vector(31 downto 0);
    write_ack_o       : out std_logic;
    -- Event Receiver PLL locked
    eventr_pll_locked : in  std_logic;
    -- Event Receiver recovered clock
    rxoutclk_o        : out std_logic;  
    -- Event Receiver PLL clock
    EVENTR_CLK_OUT1   : in  std_logic;    
    -- GTX I/O
    GTREFCLK_N        : in  std_logic;
    GTREFCLK_P        : in  std_logic;
    RXN_IN            : in  std_logic_vector(2 downto 0);
    RXP_IN            : in  std_logic_vector(2 downto 0);
    TXN_OUT           : out std_logic_vector(2 downto 0);
    TXP_OUT           : out std_logic_vector(2 downto 0)
);
end sfp_top;

architecture rtl of sfp_top is

signal rxn_i                 : std_logic;
signal rxp_i                 : std_logic;
signal txn_o                 : std_logic;
signal txp_o                 : std_logic;
signal linkup_o              : std_logic;
signal EVENTR_CLK            : std_logic;
signal kchar_linkup_o        : std_logic;
signal event_code_linkup_o   : std_logic;   
signal rx_link_ok_o          : std_logic;   
signal rxcharisk             : std_logic_vector(1 downto 0);   
signal rxdisperr             : std_logic_vector(1 downto 0); 
signal rxdata                : std_logic_vector(15 downto 0); 
signal LINKUP                : std_logic_vector(31 downto 0);
signal EVENT_CODEHB          : std_logic_vector(31 downto 0);
signal EVENT_CODERP          : std_logic_vector(31 downto 0);
signal EVENT_CODEEC          : std_logic_vector(31 downto 0);
signal EVENT_CODERE          : std_logic_vector(31 downto 0);
signal EVENT_CODES0          : std_logic_vector(31 downto 0);
signal EVENT_CODES1          : std_logic_vector(31 downto 0);
signal EC_DATA               : std_logic_vector(31 downto 0);
signal KCHAR_DATA            : std_logic_vector(31 downto 0);
signal UTIME                 : std_logic_vector(31 downto 0);   
signal dischar_o             : std_logic_vector(5 downto 0);     
signal event_codes_datahb_o  : std_logic_vector(7 downto 0); 
signal event_codes_datarp_o  : std_logic_vector(7 downto 0);
signal event_codes_dataec_o  : std_logic_vector(7 downto 0);
signal event_codes_datare_o  : std_logic_vector(7 downto 0);
signal event_codes_datas0_o  : std_logic_vector(7 downto 0);
signal event_codes_datas1_o  : std_logic_vector(7 downto 0);
signal kchar_o               : std_logic_vector(11 downto 0);
signal databuf_data_o        : std_logic_vector(7 downto 0);
signal debug_data_o          : std_logic_vector(3 downto 0);   
signal rxnotintable          : std_logic_vector(1 downto 0);
signal utime_o               : std_logic_vector(31 downto 0);

signal EVENT_RESET           : std_logic_vector(31 downto 0) := (others => '0');
signal ER_RESET              : std_logic;   
signal rxoutclk              : std_logic;

signal prescaler_o           : std_logic_vector(9 downto 0);
signal count_o               : std_logic_vector(9 downto 0);
signal loss_lock_o           : std_logic;  
signal rx_error_count_o      : std_logic_vector(5 downto 0);   
signal hbcnt_o               : std_logic_vector(15 downto 0);
signal rpcnt_o               : std_logic_vector(15 downto 0);
signal eccnt_o               : std_logic_vector(15 downto 0);
signal recnt_o               : std_logic_vector(15 downto 0);
signal s0cnt_o               : std_logic_vector(15 downto 0);
signal s1cnt_o               : std_logic_vector(15 downto 0);

signal sim_reset             : std_logic;    

begin

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


-- MGT RX
rxn_i <= RXN_IN(0);
rxp_i <= RXP_IN(0);

-- MGT TX
TXN_OUT(0) <= txn_o;
TXP_OUT(0) <= txp_o;

-- Unused MGT TX's
TXN_OUT(1 downto 2) <= (others => '0');
TXP_OUT(1 downto 2) <= (others => '0');


-- Event Receiver clock buffer
rxoutclk_bufg : BUFG
    port map
        (O => EVENTR_CLK,
         I => EVENTR_CLK_OUT1
         
);         


sfp_receiver_inst: entity work.sfp_receiver
port map(
    clk_i                => clk_i,
    reset_i              => ER_RESET,
    rxcharisk_i          => rxcharisk,
    rxdisperr_i          => rxdisperr,
    rxdata_i             => rxdata,
    dischar_o            => dischar_o,
    kchar_o              => kchar_o,
    rxnotintable_i       => rxnotintable,  
    rx_link_ok_o         => rx_link_ok_o,   
    event_codes_datahb_o => event_codes_datahb_o, 
    event_codes_datarp_o => event_codes_datarp_o,
    event_codes_dataec_o => event_codes_dataec_o,
    event_codes_datare_o => event_codes_datare_o,
    event_codes_datas0_o => event_codes_datas0_o,
    event_codes_datas1_o => event_codes_datas1_o,
    databuf_data_o       => databuf_data_o,
    kchar_linkup_o       => kchar_linkup_o,
    event_code_linkup_o  => event_code_linkup_o,
    prescaler_o          => prescaler_o,
    count_o              => count_o,
    loss_lock_o          => loss_lock_o, 
    rx_error_count_o     => rx_error_count_o,
    hbcnt_o              => hbcnt_o,
    rpcnt_o              => rpcnt_o,
    eccnt_o              => eccnt_o,
    recnt_o              => recnt_o,   
    s0cnt_o              => s0cnt_o,
    s1cnt_o              => s1cnt_o,       
    utime_o              => utime_o         
);
 

sfpgtx_event_receiver_inst: entity work.sfp_event_receiver
port map(
    GTREFCLK_P         => GTREFCLK_P,
    GTREFCLK_N         => GTREFCLK_N, 
    ER_RESET           => ER_RESET,
    EVENTR_CLK         => EVENTR_CLK,
    eventr_pll_locked  => eventr_pll_locked,
    rxp_i              => rxp_i,
    rxn_i              => rxn_i,
    txp_o              => txp_o, 
    txn_o              => txn_o,    
    rxdata_o           => rxdata, 
    rxoutclk_o         => rxoutclk,
    rxcharisk_o        => rxcharisk, 
    rxdisperr_o        => rxdisperr, 
    linkup_o           => linkup_o,
    debug_data_o       => debug_data_o,
    rxnotintable_o     => rxnotintable  
); 


rxoutclk_o <= rxoutclk;    

-- Do it this way for simulation purpose
ps_er_en: process(clk_i)
begin
    if rising_edge(clk_i) then
--        if EVENT_RESET(0) = '1' or sim_reset = '1' then    
        if EVENT_RESET(0) = '1' then    
            ER_RESET <= '0';
        else
            ER_RESET <= '1';
        end if;    
    end if;
end process ps_er_en;                
  
  
--ps_sim_reset: process
--begin
--    sim_reset <= '0';
--    wait for 132 ns;
--    sim_reset <= '1';
--    wait;
--end process ps_sim_reset;      
  
  
  
LINKUP(0) <= linkup_o and rx_link_ok_o;
LINKUP(1) <= rx_link_ok_o;
LINKUP(2) <= linkup_o;
LINKUP(12 downto 3) <= prescaler_o;
LINKUP(22 downto 13) <= count_o;
LINKUP(23) <= loss_lock_o;
LINKUP(29 downto 24) <= rx_error_count_o; 
LINKUP(30) <= '0'; 
LINKUP(31) <= eventr_pll_locked; 
EVENT_CODEHB(7 downto 0) <= event_codes_datahb_o;
EVENT_CODEHB(15 downto 8) <= (others => '0'); 
EVENT_CODEHB(31 downto 16) <= hbcnt_o; 
EVENT_CODERP(7 downto 0) <= event_codes_datarp_o;
EVENT_CODERP(15 downto 8) <= (others => '0');
EVENT_CODERP(31 downto 16) <= rpcnt_o;
EVENT_CODEEC(7 downto 0) <= event_codes_dataec_o;
EVENT_CODEEC(15 downto 8) <= (others => '0');
EVENT_CODEEC(31 downto 16) <= eccnt_o;
EVENT_CODERE(7 downto 0) <= event_codes_datare_o;
EVENT_CODERE(15 downto 8) <= (others => '0');
EVENT_CODERE(31 downto 16) <= recnt_o;
EVENT_CODES0(7 downto 0) <= event_codes_datas0_o;
EVENT_CODES0(15 downto 8) <= (others => '0');
EVENT_CODES0(31 downto 16) <= s0cnt_o;
EVENT_CODES1(7 downto 0) <= event_codes_datas1_o;
EVENT_CODES1(15 downto 8) <= (others => '0');
EVENT_CODES1(31 downto 16) <= s1cnt_o;
EC_DATA(7 downto 0) <= databuf_data_o;
EC_DATA(31 downto 8) <= (others => '0');
KCHAR_DATA(11 downto 0) <= kchar_o;
KCHAR_DATA(15 downto 12) <= (others => '0');
KCHAR_DATA(21 downto 16) <= dischar_o; 
KCHAR_DATA(31 downto 22) <= (others => '0');
UTIME <= utime_o;

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
sfp_ctrl : entity work.sfp_ctrl
port map (
    -- Clock and Reset
    clk_i                       => clk_i,
    reset_i                     => reset_i,
    sysbus_i                    => (others => '0'),
    posbus_i                    => (others => (others => '0')),

    LINKUP                      => LINKUP,
    EVENT_CODEHB                => EVENT_CODEHB,
    EVENT_CODERP                => EVENT_CODERP,
    EVENT_CODEEC                => EVENT_CODEEC,
    EVENT_CODERE                => EVENT_CODERE,
    EVENT_CODES0                => EVENT_CODES0,
    EVENT_CODES1                => EVENT_CODES1,
    EC_DATA                     => EC_DATA,
    KCHAR_DATA                  => KCHAR_DATA,
    UTIME                       => UTIME,
    EVENT_RESET                 => EVENT_RESET,

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

