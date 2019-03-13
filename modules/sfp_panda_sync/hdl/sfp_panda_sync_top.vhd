library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.top_defines.all;

library unisim;
use unisim.vcomponents.all;


entity sfp_panda_sync_top is
    port (        
        clk_i            : in  std_logic;
        reset_i          : in  std_logic;
        bit_bus_i        : in  sysbus_t;
        pos_bus_i        : in  posbus_t;
        GTREFCLK_P       : in  std_logic;
        GTREFCLK_N       : in  std_logic;
        -- MGT Rx Tx
        rxp_i            : in  std_logic;
        rxn_i            : in  std_logic;
        txp_o            : out std_logic;
        txn_o            : out std_logic;
        --
        ext_clock_i      : in  std_logic_vector(1 downto 0);
        -- Data Out
        BITIN1_o         : out std_logic;
        BITIN2_o         : out std_logic;
        BITIN3_o         : out std_logic;
        BITIN4_o         : out std_logic;
        BITIN5_o         : out std_logic;
        BITIN6_o         : out std_logic;
        BITIN7_o         : out std_logic;
        BITIN8_o         : out std_logic;
        BITIN9_o         : out std_logic;
        BITIN10_o        : out std_logic;
        BITIN11_o        : out std_logic;
        BITIN12_o        : out std_logic;
        BITIN13_o        : out std_logic;
        BITIN14_o        : out std_logic;
        BITIN15_o        : out std_logic;
        BITIN16_o        : out std_logic;
        POSIN1_o         : out std_logic_vector(31 downto 0);
        POSIN2_o         : out std_logic_vector(31 downto 0);
        POSIN3_o         : out std_logic_vector(31 downto 0);
        POSIN4_o         : out std_logic_vector(31 downto 0);
        -- Memory Bus Interface
        -- Read 
        read_strobe_i    : in  std_logic;
        read_address_i   : in  std_logic_vector(PAGE_AW-1 downto 0);
        read_data_o      : out std_logic_vector(31 downto 0);
        read_ack_o       : out std_logic;
        -- Write
        write_strobe_i   : in  std_logic;
        write_address_i  : in  std_logic_vector(PAGE_AW-1 downto 0);
        write_data_i     : in  std_logic_vector(31 downto 0);
        write_ack_o      : out std_logic

        );
end sfp_panda_sync_top;


architecture rtl of sfp_panda_sync_top is

signal rxuserrdy_i        : std_logic;
signal txuserrdy_i        : std_logic;    
signal rx_link_ok         : std_logic;
signal rxbyteisaligned_o  : std_logic;
signal rxbyterealign_o    : std_logic;
signal rxcommadet_o       : std_logic;
signal loss_lock_o        : std_logic;
signal rx_error_o         : std_logic;
signal rxoutclk_o         : std_logic;
signal txoutclk_o         : std_logic;
signal rxoutclk_i         : std_logic;
signal txoutclk_i         : std_logic;   
signal rxoutclk           : std_logic;
signal txoutclk           : std_logic;      
signal rxdata_o           : std_logic_vector(31 downto 0); 
signal rxcharisk_o        : std_logic_vector(3 downto 0); 
signal rxdisperr_o        : std_logic_vector(3 downto 0); 
signal mgt_ready_o        : std_logic;
signal rxnotintable_o     : std_logic_vector(3 downto 0); 
signal txdata_i           : std_logic_vector(31 downto 0); 
signal txcharisk_i        : std_logic_vector(3 downto 0);
signal POSIN1             : std_logic_vector(31 downto 0); 
signal POSIN2             : std_logic_vector(31 downto 0);
signal POSIN3             : std_logic_vector(31 downto 0);  
signal POSIN4             : std_logic_vector(31 downto 0);  
signal BITIN              : std_logic_vector(15 downto 0);  
--
signal BITOUT1            : std_logic;  
signal BITOUT2            : std_logic;  
signal BITOUT3            : std_logic;  
signal BITOUT4            : std_logic;  
signal BITOUT5            : std_logic;  
signal BITOUT6            : std_logic;  
signal BITOUT7            : std_logic;  
signal BITOUT8            : std_logic;  
signal BITOUT9            : std_logic;  
signal BITOUT10           : std_logic;  
signal BITOUT11           : std_logic;  
signal BITOUT12           : std_logic;  
signal BITOUT13           : std_logic;  
signal BITOUT14           : std_logic;  
signal BITOUT15           : std_logic;  
signal BITOUT16           : std_logic;  
signal POSOUT1            : std_logic_vector(31 downto 0);
signal POSOUT2            : std_logic_vector(31 downto 0);
signal POSOUT3            : std_logic_vector(31 downto 0);
signal POSOUT4            : std_logic_vector(31 downto 0);
signal BITOUT             : std_logic_vector(15 downto 0);  
signal LINKUP             : std_logic_vector(31 downto 0);   
signal SYNC_RESET         : std_logic;        
  

begin

read_ack_o <= '1';
write_ack_o <= '1';


BITIN16_o <= BITIN(15);
BITIN15_o <= BITIN(14);
BITIN14_o <= BITIN(13);
BITIN13_o <= BITIN(12);
BITIN12_o <= BITIN(11);
BITIN11_o <= BITIN(10);
BITIN10_o <= BITIN(9);
BITIN9_o <= BITIN(8);
BITIN8_o <= BITIN(7);
BITIN7_o <= BITIN(6);
BITIN6_o <= BITIN(5);
BITIN5_o <= BITIN(4);
BITIN4_o <= BITIN(3);
BITIN3_o <= BITIN(2);
BITIN2_o <= BITIN(1);
BITIN1_o <= BITIN(0);
  


BUFGMUX_RX_inst :BUFGMUX
    port map (
        O   => rxoutclk_i,
        I0  => rxoutclk_o,
        I1  => clk_i,
        S   => ext_clock_i(1) 
);


BUFGMUX_TX_inst :BUFGMUX
    port map (
        O   => txoutclk_i,
        I0  => txoutclk_o,
        I1  => clk_i,
        S   => ext_clock_i(1)
);


-- Must be driven high when the txusrclk and rxusrclk are valid
--rxuserrdy_i <= not SYNC_RESET;
--txuserrdy_i <= not SYNC_RESET; 
rxuserrdy_i <= rx_link_ok;
txuserrdy_i <= rx_link_ok; 


-- Transmitter 
-- 1. BITOUT1 and pkt_start indicator 2. POSOUT1 
-- 3. BITOUT2 and zero                4. POSOUT2
-- 5. BITOUT3 and zero                6. POSOUT3
-- 7. BITOUT4 and pkt sync            8. POSOUT4
sfp_panda_sync_transmitter_inst : entity work.sfp_panda_sync_transmit

    port map (
        clk_i             => clk_i,
        txoutclk_i        => txoutclk_i,   
        reset_i           => reset_i,
        rx_link_ok_i      => rx_link_ok, 
        txcharisk_o       => txcharisk_i,
        txdata_o          => txdata_i,
        POSOUT1_i         => POSOUT1,
        POSOUT2_i         => POSOUT2,
        POSOUT3_i         => POSOUT3,
        POSOUT4_i         => POSOUT4,
        BITOUT_i          => BITOUT
        );  
         
-- Receiver
-- Will not start until the data has been aligned and first packet has been received
sfp_panda_sync_receiver_inst : entity work.sfp_panda_sync_receiver

    port map (
        clk_i             => clk_i, 
        rxoutclk_i        => rxoutclk_i,     
        reset_i           => reset_i,
        rxdisperr_i       => rxdisperr_o,
        rxcharisk_i       => rxcharisk_o,
        rxdata_i          => rxdata_o,
        rxnotintable_i    => rxnotintable_o,
        rx_link_ok_o      => rx_link_ok,
        loss_lock_o       => loss_lock_o,
        rx_error_o        => rx_error_o,
        BITIN_o           => BITIN,   
        POSIN1_o          => POSIN1_o,
        POSIN2_o          => POSIN2_o,
        POSIN3_o          => POSIN3_o,
        POSIN4_o          => POSIN4_o
        );



-- txouttclk is the recomended clock for the FPGA frabric 
sfp_panda_sync_mgt_interface_inst : entity work.sfp_panda_sync_mgt_interface 

    port map(
        GTREFCLK_P        => GTREFCLK_P,        
        GTREFCLK_N        => GTREFCLK_N,        
        SYNC_RESET_i      => SYNC_RESET,       
        clk_i             => clk_i, 
        rxoutclk_i        => rxoutclk_i,
        txoutclk_i        => txoutclk_i,          
        rxp_i             => rxp_i,             
        rxn_i             => rxn_i,             
        txp_o             => txp_o,             
        txn_o             => txn_o,             
        rxuserrdy_i       => rxuserrdy_i,
        txuserrdy_i       => txuserrdy_i,        
        rxbyteisaligned_o => rxbyteisaligned_o, 
        rxbyterealign_o   => rxbyterealign_o,   
        rxcommadet_o      => rxcommadet_o,      
        rxdata_o          => rxdata_o,           
        rxoutclk_o        => rxoutclk_o,            -- RX Recovered clock        
        rxcharisk_o       => rxcharisk_o,        
        rxdisperr_o       => rxdisperr_o,        
        mgt_ready_o       => mgt_ready_o,       
        rxnotintable_o    => rxnotintable_o, 
        txoutclk_o        => txoutclk_o,            -- TX GTREFCLK0_PN 
        txdata_i          => txdata_i,           
        txcharisk_i       => txcharisk_i        
        );



BITOUT <= BITOUT16 & BITOUT15 & BITOUT14 & BITOUT13 & BITOUT12 & BITOUT11 & BITOUT10 & BITOUT9 & 
          BITOUT8  & BITOUT7  & BITOUT6  & BITOUT5  & BITOUT4  & BITOUT3  & BITOUT2  & BITOUT1; 



LINKUP(0) <= mgt_ready_o and rx_link_ok;
LINKUP(31 downto 1) <= (others => '0');  

sfp_panda_sync_ctrl_inst : entity work.sfp_panda_sync_ctrl
    port map (
        -- Clock and Reset
        clk_i             => clk_i,
        reset_i           => reset_i,
        bit_bus_i         => bit_bus_i,
        pos_bus_i         => pos_bus_i,
        -- Block Parameters
        LINKUP            => LINKUP,
        SYNC_RESET        => open,
        SYNC_RESET_wstb   => SYNC_RESET,  
        BITOUT1_from_bus  => BITOUT1,
        BITOUT2_from_bus  => BITOUT2,
        BITOUT3_from_bus  => BITOUT3,
        BITOUT4_from_bus  => BITOUT4,
        BITOUT5_from_bus  => BITOUT5,
        BITOUT6_from_bus  => BITOUT6,
        BITOUT7_from_bus  => BITOUT7,
        BITOUT8_from_bus  => BITOUT8,
        BITOUT9_from_bus  => BITOUT9,
        BITOUT10_from_bus => BITOUT10,
        BITOUT11_from_bus => BITOUT11,
        BITOUT12_from_bus => BITOUT12,
        BITOUT13_from_bus => BITOUT13,
        BITOUT14_from_bus => BITOUT14,
        BITOUT15_from_bus => BITOUT15,
        BITOUT16_from_bus => BITOUT16,
        POSOUT1_from_bus  => POSOUT1,
        POSOUT2_from_bus  => POSOUT2,
        POSOUT3_from_bus  => POSOUT3,
        POSOUT4_from_bus  => POSOUT4,
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
