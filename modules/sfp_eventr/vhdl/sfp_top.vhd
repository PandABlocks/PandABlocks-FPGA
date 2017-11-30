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

signal rxn_i            : std_logic;
signal rxp_i            : std_logic;
signal txn_o            : std_logic;
signal txp_o            : std_logic;
signal linkup_o         : std_logic;
signal EVENTR_CLK       : std_logic;
signal CLEAR_REGS_WSTB  : std_logic;
signal rxcharisk        : std_logic_vector(1 downto 0);   
signal rxdisperr        : std_logic_vector(1 downto 0); 
signal rxdata           : std_logic_vector(15 downto 0); 
signal LINKUP           : std_logic_vector(31 downto 0);
signal EVENT_CODES      : std_logic_vector(31 downto 0);  
signal CLEAR_REGS       : std_logic_vector(31 downto 0);  
signal dischar_o        : std_logic_vector(3 downto 0);     
signal event_codes_o    : std_logic_vector(5 downto 0);
signal kchar_o          : std_logic_vector(11 downto 0);
signal event_codes_data : std_logic_vector(7 downto 0);
signal databuf_data     : std_logic_vector(7 downto 0);
signal ECDATA_REGS      : std_logic_vector(31 downto 0);


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
    clk_i              => clk_i,
    reset_i            => reset_i,
    CLEAR_REG          => CLEAR_REGS(0),
    CLEAR_REGS_WSTB    => CLEAR_REGS_WSTB,        
    rxcharisk_i        => rxcharisk,
    rxdisperr_i        => rxdisperr,
    rxdata_i           => rxdata,
    dischar_o          => dischar_o, 
    event_codes_o      => event_codes_o,
    kchar_o            => kchar_o,
    event_codes_data_o => event_codes_data,
    databuf_data_o     => databuf_data  
);
 

sfpgtx_event_receiver_inst: entity work.sfp_event_receiver
port map(
    GTREFCLK_P         => GTREFCLK_P,
    GTREFCLK_N         => GTREFCLK_N, 
    reset_i            => reset_i,
    EVENTR_CLK         => EVENTR_CLK,
    eventr_pll_locked  => eventr_pll_locked,
    rxp_i              => rxp_i,
    rxn_i              => rxn_i,
    txp_o              => txp_o, 
    txn_o              => txn_o, 
    rxdata_o           => rxdata, 
    rxoutclk_o         => rxoutclk_o,
    rxcharisk_o        => rxcharisk, 
    rxdisperr_o        => rxdisperr, 
    linkup_o           => linkup_o
); 


LINKUP(0) <= linkup_o;
LINKUP(31 downto 1) <= (others => '0');

EVENT_CODES(21 downto 0) <= dischar_o & event_codes_o & kchar_o;
EVENT_CODES(31 downto 22) <= (others => '0'); 

ECDATA_REGS(7 downto 0) <= event_codes_data;
ECDATA_REGS(15 downto 8) <= databuf_data;
ECDATA_REGS(31 downto 16) <= (others => '0'); 

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
    EVENT_CODES                 => EVENT_CODES,
    ECDATA_REGS                 => ECDATA_REGS,
    CLEAR_REGS                  => CLEAR_REGS,
    CLEAR_REGS_WSTB             => CLEAR_REGS_WSTB,    

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

