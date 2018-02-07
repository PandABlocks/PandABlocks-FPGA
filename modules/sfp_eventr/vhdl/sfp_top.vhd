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
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;

    FCLK_CLK0_PS        : in  std_logic;
    EXTCLK_P            : in  std_logic;
    EXTCLK_N            : in  std_logic;
    FCLK_CLK0           : out std_logic; 
  
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;

    -- SMA PLL locked
    sma_pll_locked_o    : out std_logic;    
    -- Event Receiver PLL locked
    eventr_pll_locked_o : out std_logic;
    -- sma and event receiver clock enables
    ext_clock             : in  std_logic_vector(1 downto 0);

    -- Bits out
    bit0_o              : out std_logic;
    bit1_o              : out std_logic;
    bit2_o              : out std_logic;
    bit3_o              : out std_logic;        

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

component ila_0

    port (
    	clk     : in  std_logic;
    	probe0  : in  std_logic_vector(0 downto 0); 
    	probe1  : in  std_logic_vector(0 downto 0); 
    	probe2  : in  std_logic_vector(0 downto 0); 
    	probe3  : in  std_logic_vector(0 downto 0); 
    	probe4  : in  std_logic_vector(1 downto 0); 
    	probe5  : in  std_logic_vector(1 downto 0); 
    	probe6  : in  std_logic_vector(15 downto 0); 
    	probe7  : in  std_logic_vector(0 downto 0); 
    	probe8  : in  std_logic_vector(0 downto 0); 
    	probe9  : in  std_logic_vector(0 downto 0); 
    	probe10 : in  std_logic_vector(3 downto 0); 
    	probe11 : in  std_logic_vector(1 downto 0); 
    	probe12 : in  std_logic_vector(7 downto 0) 
    );
    
end component;

signal rxn_i                 : std_logic;
signal rxp_i                 : std_logic;
signal txn_o                 : std_logic;
signal txp_o                 : std_logic;
signal mgt_ready_o           : std_logic;
signal eventr_clk            : std_logic;
signal rx_link_ok_o          : std_logic;   
signal rxcharisk             : std_logic_vector(1 downto 0);   
signal rxdisperr             : std_logic_vector(1 downto 0); 
signal rxdata                : std_logic_vector(15 downto 0); 
signal LINKUP                : std_logic_vector(31 downto 0);
signal UTIME                 : std_logic_vector(31 downto 0);   
signal rxnotintable          : std_logic_vector(1 downto 0);
signal utime_o               : std_logic_vector(31 downto 0);
signal ER_RESET              : std_logic;   
signal EVENT_RESET           : std_logic_vector(31 downto 0);   
signal rxbyteisaligned_o     : std_logic;
signal rxbyterealign_o       : std_logic;
signal rxcommadet_o          : std_logic;    
signal rxoutclk              : std_logic;
signal EVENT0                : std_logic_vector(31 downto 0);   
signal EVENT0_WSTB           : std_logic;   
signal EVENT1                : std_logic_vector(31 downto 0);
signal EVENT1_WSTB           : std_logic;       
signal EVENT2                : std_logic_vector(31 downto 0);   
signal EVENT2_WSTB           : std_logic;   
signal EVENT3                : std_logic_vector(31 downto 0);   
signal EVENT3_WSTB           : std_logic;   
signal eventr_pll_locked     : std_logic;

signal sim_reset             : std_logic;

-- ILA stuff
signal mgt_ready_slv         : std_logic_vector(0 downto 0);
signal rx_link_ok_slv        : std_logic_vector(0 downto 0);
signal eventr_pll_locked_slv : std_logic_vector(0 downto 0);
signal rxbyteisaligned_slv   : std_logic_vector(0 downto 0);     
signal rxbyterealign_slv     : std_logic_vector(0 downto 0);
signal rxcommadet_slv        : std_logic_vector(0 downto 0);
   

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

eventr_pll_locked_o <= eventr_pll_locked;

-- Event Receiver clock buffer
rxoutclk_bufg : BUFG
port map(
    O => eventr_clk,
    I => rxoutclk
);         


sfp_mmcm_clkmux_inst: entity work.sfp_mmcm_clkmux 
generic map (no_ibufg    => 0)
         
port map(
    FCLK_CLK0_PS        => FCLK_CLK0_PS,
    EXTCLK_P            => EXTCLK_P, 
    EXTCLK_N            => EXTCLK_N,
    RXOUTCLK            => eventr_clk,
    ext_clock           => ext_clock,
    sma_pll_locked_o    => sma_pll_locked_o,    
    eventr_pll_locked_o => eventr_pll_locked,
    FCLK_CLK0           => FCLK_CLK0   
);


sfp_receiver_inst: entity work.sfp_receiver
port map(
    clk_i             => clk_i,
    reset_i           => reset_i, 	
    rxcharisk_i       => rxcharisk,
    rxdisperr_i       => rxdisperr,
    rxdata_i          => rxdata,
    rxnotintable_i    => rxnotintable,  
    EVENT0            => EVENT0,
    EVENT0_WSTB       => EVENT0_WSTB,
    EVENT1            => EVENT1,
    EVENT1_WSTB       => EVENT1_WSTB,
    EVENT2            => EVENT2,
    EVENT2_WSTB       => EVENT2_WSTB,        
    EVENT3            => EVENT3,
    EVENT3_WSTB       => EVENT3_WSTB,
    bit0_o            => bit0_o,
    bit1_o            => bit1_o,
    bit2_o            => bit2_o,
    bit3_o            => bit3_o,    
    rx_link_ok_o      => rx_link_ok_o,  
    utime_o           => utime_o
);
 

sfpgtx_event_receiver_inst: entity work.sfp_event_receiver
port map(
    GTREFCLK_P         => GTREFCLK_P,
    GTREFCLK_N         => GTREFCLK_N, 
    ER_RESET           => ER_RESET,
    eventr_clk         => eventr_clk,
    eventr_pll_locked  => eventr_pll_locked,
    rxp_i              => rxp_i,
    rxn_i              => rxn_i,
    txp_o              => txp_o, 
    txn_o              => txn_o,    
    
    rxbyteisaligned_o  => rxbyteisaligned_o,
    rxbyterealign_o    => rxbyterealign_o,
    rxcommadet_o       => rxcommadet_o, 
    rxdata_o           => rxdata, 
    rxoutclk_o         => rxoutclk,
    rxcharisk_o        => rxcharisk, 
    rxdisperr_o        => rxdisperr, 
    mgt_ready_o        => mgt_ready_o,
    rxnotintable_o     => rxnotintable  
); 


-- Do it this way for simulation purpose
ps_er_en: process(clk_i)
begin
    if rising_edge(clk_i) then
        if EVENT_RESET(0) = '1' or sim_reset = '1' then    
--        if EVENT_RESET(0) = '1' then    
            ER_RESET <= '0';
        else
            ER_RESET <= '1';
        end if;    
    end if;
end process ps_er_en;                
  
  
ps_sim_reset: process
begin
    sim_reset <= '0';
    wait for 132 ns;
    sim_reset <= '1';
    wait;
end process ps_sim_reset;      
 
 
mgt_ready_slv(0) <= mgt_ready_o;
rx_link_ok_slv(0) <= rx_link_ok_o;
eventr_pll_locked_slv(0) <= eventr_pll_locked;
rxbyteisaligned_slv(0) <= rxbyteisaligned_o;     
rxbyterealign_slv(0) <= rxbyterealign_o;
rxcommadet_slv(0) <= rxcommadet_o;


ila_inst : ila_0
port map (
	clk     => clk_i,
   	probe0  => mgt_ready_slv and rx_link_ok_slv, 
	probe1  => rx_link_ok_slv, 
	probe2  => mgt_ready_slv, 
	probe3  => eventr_pll_locked_slv, 
	probe4  => rxdisperr, 
	probe5  => rxnotintable, 
	probe6  => rxdata, 
	probe7  => rxbyteisaligned_slv, 
	probe8  => rxbyterealign_slv, 
	probe9  => rxcommadet_slv, 	
	probe10 => (others => '0'), 
    probe11 => rxcharisk,
	probe12 => (others => '0')
);
  
-- MGT ready and link is up  
LINKUP(0) <= mgt_ready_o and rx_link_ok_o;
-- Link is up
LINKUP(1) <= rx_link_ok_o;
-- MGT ready 
LINKUP(2) <= mgt_ready_o;
LINKUP(31 downto 3) <= (others => '0');
UTIME <= utime_o;

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
sfp_ctrl : entity work.sfp_ctrl
port map (
    -- Clock and Reset
    clk_i             => clk_i,
    reset_i           => reset_i,
    sysbus_i          => (others => '0'),
    posbus_i          => (others => (others => '0')),

    LINKUP            => LINKUP,
    UTIME             => UTIME,
    EVENT_RESET       => EVENT_RESET,  
    EVENT0            => EVENT0,
    EVENT0_WSTB       => EVENT0_WSTB,
    EVENT1            => EVENT1,
    EVENT1_WSTB       => EVENT1_WSTB,
    EVENT2            => EVENT2,
    EVENT2_WSTB       => EVENT2_WSTB,        
    EVENT3            => EVENT3,
    EVENT3_WSTB       => EVENT3_WSTB,

    -- Memory Bus Interface
    read_strobe_i     => read_strobe_i,
    read_address_i    => read_address_i(BLK_AW-1 downto 0),
    read_data_o       => read_data_o,
    read_ack_o        => open,

    write_strobe_i    => write_strobe_i,
    write_address_i   => write_address_i(BLK_AW-1 downto 0),
    write_data_i      => write_data_i,
    write_ack_o       => open
);

end rtl;

