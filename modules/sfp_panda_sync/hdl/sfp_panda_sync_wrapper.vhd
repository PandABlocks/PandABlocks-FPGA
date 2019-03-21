library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.top_defines.all;

library unisim;
use unisim.vcomponents.all;


entity sfp_panda_sync_wrapper is
    port (        
        clk_i            : in  std_logic;
        reset_i          : in  std_logic;
        bit_bus_i        : in  bit_bus_t;
        pos_bus_i        : in  pos_bus_t;
        -- Data Out
        BITIN1_o         : out std_logic_vector(0 downto 0);
        BITIN2_o         : out std_logic_vector(0 downto 0);
        BITIN3_o         : out std_logic_vector(0 downto 0);
        BITIN4_o         : out std_logic_vector(0 downto 0);
        BITIN5_o         : out std_logic_vector(0 downto 0);
        BITIN6_o         : out std_logic_vector(0 downto 0);
        BITIN7_o         : out std_logic_vector(0 downto 0);
        BITIN8_o         : out std_logic_vector(0 downto 0);
        BITIN9_o         : out std_logic_vector(0 downto 0);
        BITIN10_o        : out std_logic_vector(0 downto 0);
        BITIN11_o        : out std_logic_vector(0 downto 0);
        BITIN12_o        : out std_logic_vector(0 downto 0);
        BITIN13_o        : out std_logic_vector(0 downto 0);
        BITIN14_o        : out std_logic_vector(0 downto 0);
        BITIN15_o        : out std_logic_vector(0 downto 0);
        BITIN16_o        : out std_logic_vector(0 downto 0);
        POSIN1_o         : out std32_array(0 downto 0);
        POSIN2_o         : out std32_array(0 downto 0);
        POSIN3_o         : out std32_array(0 downto 0);
        POSIN4_o         : out std32_array(0 downto 0);
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
        write_ack_o      : out std_logic;

        SFP_i            : in  SFP_input_interface;
        SFP_o            : out SFP_output_interface
        );
end sfp_panda_sync_wrapper;


architecture rtl of sfp_panda_sync_wrapper is

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


BITIN16_o(0) <= BITIN(15);
BITIN15_o(0) <= BITIN(14);
BITIN14_o(0) <= BITIN(13);
BITIN13_o(0) <= BITIN(12);
BITIN12_o(0) <= BITIN(11);
BITIN11_o(0) <= BITIN(10);
BITIN10_o(0) <= BITIN(9);
BITIN9_o(0) <= BITIN(8);
BITIN8_o(0) <= BITIN(7);
BITIN7_o(0) <= BITIN(6);
BITIN6_o(0) <= BITIN(5);
BITIN5_o(0) <= BITIN(4);
BITIN4_o(0) <= BITIN(3);
BITIN3_o(0) <= BITIN(2);
BITIN2_o(0) <= BITIN(1);
BITIN1_o(0) <= BITIN(0);
  


rxoutclk_bufg : BUFG
port map(
    O => rxoutclk_i,
    I => rxoutclk_o
);


txoutclk_bufg : BUFG
port map(
    O => txoutclk_i,
    I => txoutclk_o
);


-- Must be driven high when the txusrclk and rxusrclk are valid
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
        POSIN1_o          => POSIN1_o(0),
        POSIN2_o          => POSIN2_o(0),
        POSIN3_o          => POSIN3_o(0),
        POSIN4_o          => POSIN4_o(0)
        );


-- txouttclk is the recomended clock for the FPGA frabric 
sfp_panda_sync_mgt_interface_inst : entity work.sfp_panda_sync_mgt_interface 

    port map(
        GTREFCLK          => SFP_i.GTREFCLK,        
        SYNC_RESET_i      => SYNC_RESET,       
        clk_i             => clk_i, 
        rxoutclk_i        => rxoutclk_i,
        txoutclk_i        => txoutclk_i,          
        rxp_i             => SFP_i.RXP_IN,             
        rxn_i             => SFP_i.RXN_IN,             
        txp_o             => SFP_o.TXP_OUT,             
        txn_o             => SFP_o.TXN_OUT,             
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
