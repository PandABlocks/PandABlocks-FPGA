library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity sfp_panda_sync_transmit is

    port (
        clk_i           : in  std_logic;
        txoutclk_i      : in  std_logic;
        reset_i         : in  std_logic;
        rx_link_ok_i    : in  std_logic; 
        txcharisk_o     : out std_logic_vector(3 downto 0) := (others => '0');
        POSOUT1_i       : in  std_logic_vector(31 downto 0);
        POSOUT2_i       : in  std_logic_vector(31 downto 0);
        POSOUT3_i       : in  std_logic_vector(31 downto 0);
        POSOUT4_i       : in  std_logic_vector(31 downto 0);
        BITOUT_i        : in  std_logic_vector(15 downto 0); 
        txdata_o        : out std_logic_vector(31 downto 0) := (others => '0')
        );

end sfp_panda_sync_transmit;        



architecture rtl of sfp_panda_sync_transmit is

type t_SM_DATA_IN is (STATE_IDLE, STATE_BITOUT, STATE_POSOUT13, STATE_POSOUT24);

type t_SM_DATA is (STATE_IDLE, STATE_BITIN, STATE_POSIN13, STATE_POSIN24);

type t_data is array(2 downto 0) of std_logic_vector(31 downto 0);

constant c_k28_5                     : std_logic_vector(7 downto 0) := x"BC";
constant c_k28_0                     : std_logic_vector(7 downto 0) := x"1C";   
constant c_zeros                     : std_logic_vector(7 downto 0) := x"00";
constant c_kchar                     : std_logic_vector(3 downto 0) := x"1";

signal SM_DATA                       : t_SM_DATA;
signal SM_DATA_IN                    : t_SM_DATA_IN; 
signal data_buf1                     : t_data := (others => (others => '0'));
signal data_buf2                     : t_data := (others => (others => '0'));  
signal buf_to_use                    : std_logic;
signal buf                           : std_logic;  
signal bitout_ored                   : std_logic_vector(15 downto 0) := (others => '0'); 

signal not_reg6                      : std_logic := '0';
signal xored_clk                     : std_logic;
signal start_clk                     : std_logic;
signal xored_txoutclk                : std_logic;
signal start_txoutclk                : std_logic;
signal reg_clk_dly                   : std_logic;
signal reg_txoutclk_dly              : std_logic; 

signal rx_link_ok1_meta1             : std_logic;
signal rx_link_ok1_meta2             : std_logic;
signal rx_link_ok2_meta1             : std_logic;
signal rx_link_ok2_meta2             : std_logic;
signal reg1_meta1                    : std_logic := '0';
signal reg2_meta2                    : std_logic := '0';
signal reg3_meta1                    : std_logic := '0';
signal reg4_meta2                    : std_logic := '0';
signal not_reg4                      : std_logic := '0';   

attribute ASYNC_REG : string;
attribute ASYNC_REG of rx_link_ok1_meta1    : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok1_meta2    : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok2_meta1    : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok2_meta2    : signal is "TRUE";
attribute ASYNC_REG of reg1_meta1           : signal is "TRUE";
attribute ASYNC_REG of reg2_meta2           : signal is "TRUE";
attribute ASYNC_REG of reg3_meta1           : signal is "TRUE";
attribute ASYNC_REG of reg4_meta2           : signal is "TRUE";




begin

    
-- DATA                                               
-- BITOUT(PKT_START)        Store       TX     
-- POSOUT1                  Store       TX    
-- BITOUT                   Store       TX
-- POSOUT2                  Store       Tx
-- BITOUT                               Store          
-- POSOUT3                              Store                     
-- BITOUT                               Store
-- POSOUT4                              Store
-- BITOUT(PKT_START)                                TX           
-- POSOUT1                                          TX
-- BITOUT                                           TX
-- POSOUT2                                          TX
-- BITOUT                                           Store

    

ps_data_in: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- The receiver is up    
        rx_link_ok1_meta1 <= rx_link_ok_i;
        rx_link_ok1_meta2 <= rx_link_ok1_meta1;   
        
        if rx_link_ok1_meta2 = '1' then            
                                                   
            case SM_DATA_IN is
                
                when STATE_IDLE => 
                    if start_clk = '1' then
                        SM_DATA_IN <= STATE_BITOUT;
                    end if;    
                
                -- Capture the BITIN first time
                when STATE_BITOUT =>
--                    if start_clk = '1' then
                    bitout_ored <= (others => '0');
                    if buf = '0' then
                        -- Start packet K character    
                        data_buf1(0)(31 downto 16) <= bitout_ored or BITOUT_i;
                        data_buf1(0)(15 downto 0)  <=  x"00" & c_k28_0;
                    else
                        data_buf2(0)(31 downto 16) <= bitout_ored or BITOUT_i;
                        data_buf2(0)(15 downto 0)  <= x"00" & c_k28_5;
                    end if;
                            SM_DATA_IN <= STATE_POSOUT13;
--                    end if;
                
                -- Capture the POSOUT1 or POSOUT3                                    
                when STATE_POSOUT13 => 
                    bitout_ored <= bitout_ored or BITOUT_i;
                    if buf = '0' then 
                        data_buf1(1) <= POSOUT1_i;
                    else
                        data_buf2(1) <= POSOUT3_i;
                    end if;
                    SM_DATA_IN <= STATE_POSOUT24;       
                                          
                -- Capture the POSOUT2 or POSOUT4            
                when STATE_POSOUT24 => 
                    bitout_ored <= bitout_ored or BITOUT_i;
                    if buf = '0' then
                        data_buf1(2) <= POSOUT2_i;
                    else
                        data_buf2(2) <= POSOUT4_i;
                    end if;        
                    if start_clk = '1' then
                        if buf = '0' then
                            buf <= '1';
                        else
                            buf <= '0';
                        end if;        
                        SM_DATA_IN <= STATE_BITOUT;
                    end if;
                    
                when others => 
                    buf <= '0';
                    SM_DATA_IN <= STATE_IDLE;
            
            end case;
        else
            buf <= '0';
            SM_DATA_IN <= STATE_IDLE;
        end if;                    
    end if;
end process ps_data_in;        



ps_data_out: process(txoutclk_i)
begin
    if rising_edge(txoutclk_i) then
        rx_link_ok2_meta1 <= rx_link_ok_i;
        rx_link_ok2_meta2 <= rx_link_ok2_meta1;
        
        -- PKT sync not required      
        if rx_link_ok2_meta2 = '1' then
                
            case SM_DATA is
                    
                -- 16 bits plus the k character or just zeros
                when STATE_BITIN =>
                    if start_txoutclk = '1' then
                        txcharisk_o <= c_kchar;
                        -- Packet start bit
                        if buf_to_use = '0' then
                            txdata_o <= data_buf1(0);
                        else
                            txdata_o <= data_buf2(0);
                        end if;    
                        SM_DATA <= STATE_POSIN13;
                    end if;    
                        
                -- POSOUT1
                when STATE_POSIN13 => 
                    txcharisk_o <= (others => '0');
                    if buf_to_use = '0' then
                        txdata_o <= data_buf1(1); 
                    else
                        txdata_o <= data_buf2(1);
                    end if;        
                    SM_DATA <= STATE_POSIN24;
                    
                -- POSOUT2     
                when STATE_POSIN24 => 
                    txcharisk_o <= (others => '0');
                    if buf_to_use = '0' then
                        buf_to_use <= '1';
                        txdata_o <= data_buf1(2);
                    else
                        buf_to_use <= '0';
                        txdata_o <= data_buf2(2);
                    end if;            
                    SM_DATA <= STATE_BITIN;
        
                -- Others         
                when others => 
                    buf_to_use <= '0';
                    SM_DATA <= STATE_BITIN;
            end case;                             
        else
            buf_to_use <= '0';
            SM_DATA <= STATE_BITIN;
        end if;      
    end if;
end process ps_data_out;    
        

xored_clk <= reg_clk_dly xor reg2_meta2; 


-- Ring buffer reg1, reg2 and reg3
ps_ring_buf1: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rx_link_ok1_meta2 = '1' then
            reg1_meta1 <= not_reg4;
            reg2_meta2 <= reg1_meta1; 
            reg_clk_dly <= reg2_meta2;
            -- Xor the edge for edge detection
            if xored_clk = '1' then
                start_clk <= '1';
            else
                start_clk <= '0';
            end if;
        end if;        
    end if;
end process ps_ring_buf1;    



xored_txoutclk <= reg_txoutclk_dly xor reg4_meta2;

-- Ringer buffer reg4, reg5 and reg6
ps_ring_buf2: process(txoutclk_i) 
begin
    if rising_edge(txoutclk_i) then
        if rx_link_ok2_meta2 = '1' then
            reg3_meta1 <= reg2_meta2;
            reg4_meta2 <= reg3_meta1;
            not_reg4 <= not reg4_meta2;
            reg_txoutclk_dly <= reg4_meta2;
            -- Xor the for edge detection
            if xored_txoutclk = '1' then
                start_txoutclk <= '1';
            else
                start_txoutclk <= '0';
            end if;
        end if;        
    end if;
end process ps_ring_buf2;    


end rtl;
