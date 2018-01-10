library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sfp_receiver is

    port (clk_i                 : in  std_logic;
          reset_i               : in  std_logic;
          rxcharisk_i           : in  std_logic_vector(1 downto 0);
          rxdisperr_i           : in  std_logic_vector(1 downto 0);
          rxdata_i              : in  std_logic_vector(15 downto 0);
          rxnotintable_i        : in  std_logic_vector(1 downto 0);   
          rx_link_ok_o          : out std_logic;      
          dischar_o             : out std_logic_vector(5 downto 0);
          kchar_o               : out std_logic_vector(11 downto 0);
          event_codes_datahb_o  : out std_logic_vector(7 downto 0);
          event_codes_datarp_o  : out std_logic_vector(7 downto 0);
          event_codes_dataec_o  : out std_logic_vector(7 downto 0);
          event_codes_datare_o  : out std_logic_vector(7 downto 0);
          event_codes_datas0_o  : out std_logic_vector(7 downto 0);
          event_codes_datas1_o  : out std_logic_vector(7 downto 0);
          databuf_data_o        : out std_logic_vector(7 downto 0);
          kchar_linkup_o        : out std_logic;
          event_code_linkup_o   : out std_logic;
          prescaler_o           : out std_logic_vector(9 downto 0);
          count_o               : out std_logic_vector(9 downto 0);
          loss_lock_o           : out std_logic;  
          rx_error_count_o      : out std_logic_vector(5 downto 0); 
          hbcnt_o               : out std_logic_vector(15 downto 0);
          rpcnt_o               : out std_logic_vector(15 downto 0); 
          eccnt_o               : out std_logic_vector(15 downto 0);
          recnt_o               : out std_logic_vector(15 downto 0);    
          s0cnt_o               : out std_logic_vector(15 downto 0);
          s1cnt_o               : out std_logic_vector(15 downto 0);  
          utime_o               : out std_logic_vector(31 downto 0)            
          );

end sfp_receiver;


architecture rtl of sfp_receiver is          

-- Event Receiver codes  
constant c_code_heartbeat   : std_logic_vector(7 downto 0) := X"7A";
constant c_code_reset_presc : std_logic_vector(7 downto 0) := X"7B";
constant c_code_event_code  : std_logic_vector(7 downto 0) := X"7C";
constant c_code_reset_event : std_logic_vector(7 downto 0) := X"7D";
constant c_code_seconds_0   : std_logic_vector(7 downto 0) := X"70";
constant c_code_seconds_1   : std_logic_vector(7 downto 0) := X"71";  

-- K characters 
constant c_K28_0 : std_logic_vector(7 downto 0) := X"1C";           
constant c_K28_1 : std_logic_vector(7 downto 0) := X"3C";
constant c_K28_2 : std_logic_vector(7 downto 0) := X"5C";
constant c_K28_3 : std_logic_vector(7 downto 0) := X"7C";
constant c_K28_4 : std_logic_vector(7 downto 0) := X"9C"; 
constant c_K28_5 : std_logic_vector(7 downto 0) := X"BC"; 
constant c_K28_6 : std_logic_vector(7 downto 0) := X"DC"; 
constant c_K28_7 : std_logic_vector(7 downto 0) := X"FC"; 
constant c_K23_7 : std_logic_vector(7 downto 0) := X"F7";
constant c_K27_7 : std_logic_vector(7 downto 0) := X"FB";
constant c_K29_7 : std_logic_vector(7 downto 0) := X"FD";
constant c_K30_7 : std_logic_vector(7 downto 0) := X"FE";  

constant c_zeros : std_logic_vector(1 downto 0) := "00";    

constant c_MGT_RX_LOCK_ACQ  : unsigned(9 downto 0) := to_unsigned(1023,10); 
constant c_MGT_RX_PRESCALE  : unsigned(9 downto 0) := to_unsigned(1023,10);

signal rx_error           : std_logic;
signal loss_lock          : std_logic;
signal rx_link_ok         : std_logic; 
signal rx_error_count     : unsigned(5 downto 0);
signal prescaler          : unsigned(9 downto 0);
signal count              : unsigned(9 downto 0);
signal utime_shift_reg    : std_logic_vector(31 downto 0);

signal hbcnt              : unsigned(15 downto 0);
signal rpcnt              : unsigned(15 downto 0); 
signal eccnt              : unsigned(15 downto 0);
signal recnt              : unsigned(15 downto 0);    
signal s0cnt              : unsigned(15 downto 0);
signal s1cnt              : unsigned(15 downto 0);  

begin

-- Valid Control K Characters
  ---------------------------------------------------------
--| Special Code|   Bits    | CURRENT RD - | CURRENT RD + |  
--|     Name    | HGF EDCBA | abcdei fghj  | abcdei fghj  |     
--|_____________|___________|______________|______________|    
--|     K28.0   | 000 11100 | 001111 0100  | 110000 1011  |
--|_____________|___________|______________|______________| 
--|     K28.1   | 001 11100 | 001111 1001  | 110000 0110  |
--|_____________|___________|______________|______________|
--|     K28.2   | 010 11100 | 001111 0101  | 110000 1010  |
--|_____________|___________|______________|______________|
--|     K28.3   | 011 11100 | 001111 0011  | 110000 1100  |
--|_____________|___________|______________|______________|
--|     K28.4   | 100 11100 | 001111 0010  | 110000 1101  |
--|_____________|___________|______________|______________|
--|     K28.5   | 101 11100 | 001111 1010  | 110000 0101  |
--|_____________|___________|______________|______________|
--|     K28.6   | 110 11100 | 001111 0110  | 110000 1001  |
--|_____________|___________|______________|______________|
--|     K28.7   | 111 11100 | 001111 1000  | 110000 0111  |
--|_____________|___________|______________|______________|
--|     K23.7   | 111 10111 | 111010 1000  | 000101 0111  |
--|_____________|___________|______________|______________|
--|     K27.7   | 111 11011 | 110110 1000  | 001001 0111  |
--|_____________|___________|______________|______________|
--|     K29.7   | 111 11101 | 101110 1000  | 010001 0111  |
--|_____________|___________|______________|______________|
--|     K30.7   | 111 11110 | 011110 1000  | 100001 0111  |
--|_____________|___________|______________|______________|
        
-- K28.0 - 000 11100 - 0001 1100 = X"1C"
-- K28.1 - 001 11100 - 0011 1100 = X"3C"
-- K28.2 - 010 11100 - 0101 1100 = X"5C"
-- K28.3 - 011 11100 - 0111 1100 = X"7C"
-- K28.4 - 100 11100 - 1001 1100 = X"9C"
-- K28.5 - 101 11100 - 1011 1100 = X"BC"
-- K28.6 - 110 11100 - 1101 1100 = X"DC"
-- K28.7 - 111 11100 - 1111 1100 = X"FC"
-- K23.7 - 111 10111 - 1111 0111 = X"F7"
-- K27.7 - 111 11011 - 1111 1011 = X"FB"
-- K29.7 - 111 11101 - 1111 1101 = X"FD"
-- K30.7 - 111 11110 - 1111 1110 = X"FE"   
        

hbcnt_o <= std_logic_vector(hbcnt);
rpcnt_o <= std_logic_vector(rpcnt); 
eccnt_o <= std_logic_vector(eccnt);
recnt_o <= std_logic_vector(recnt);    
s0cnt_o <= std_logic_vector(s0cnt);
s1cnt_o <= std_logic_vector(s1cnt);



rx_link_ok_o <= rx_link_ok;


ps_dis_char: process(clk_i)
begin
    if rising_edge(clk_i) then        
        if reset_i = '1' then
            dischar_o <= (others => '0');
        else   
            -- Capture the K character and disparity 
            -- error when the link is up  
            -- K Characters active and Disparity error            
            dischar_o(1 downto 0) <= rxdisperr_i;
            dischar_o(3 downto 2) <= rxcharisk_i;
            dischar_o(5 downto 4) <= rxnotintable_i;
        end if;
    end if;            
end process ps_dis_char;



ps_dec_event_codes: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            event_code_linkup_o <= '0';
            event_codes_datahb_o <= (others => '0');
            event_codes_datarp_o <= (others => '0'); 
            event_codes_dataec_o <= (others => '0');
            event_codes_datare_o <= (others => '0');
            event_codes_datas0_o <= (others => '0');
            event_codes_datas1_o <= (others => '0');
        else
            if rxdata_i(15 downto 12) = X"7" then 
                event_code_linkup_o <= '1';
            end if;
            -- heartbeat resets a counter to (1599999, 22)
            if rxdata_i(15 downto 8) = c_code_heartbeat then
                event_codes_datahb_o <= rxdata_i(15 downto 8);
                hbcnt <= hbcnt +1;
            end if;
            -- resets prescaler
            if rxdata_i(15 downto 8) = c_code_reset_presc then
                event_codes_datarp_o <= rxdata_i(15 downto 8);
                rpcnt <= rpcnt +1;
            end if;
            -- code_event_clk
            if rxdata_i(15 downto 8) = c_code_event_code then
                event_codes_dataec_o <= rxdata_i(15 downto 8);
                eccnt <= eccnt +1;
            end if;
            -- resets and counter := prescaler
            if rxdata_i(15 downto 8) = c_code_reset_event then
                event_codes_datare_o <= rxdata_i(15 downto 8);
                recnt <= recnt +1;    
            end if;
            -- second 0
            if rxdata_i(15 downto 8) = c_code_seconds_0 then
                event_codes_datas0_o <= rxdata_i(15 downto 8);
                s0cnt <= s0cnt +1;
            end if;
            -- second 1
            if rxdata_i(15 downto 8) = c_code_seconds_1 then       
                event_codes_datas1_o <= rxdata_i(15 downto 8);
                s1cnt <= s1cnt +1;
            end if;
        end if;
    end if;
end process ps_dec_event_codes;    



ps_dec_data: process(clk_i)
begin
    if rising_edge(clk_i) then 
        if reset_i = '1' then
            databuf_data_o <= (others => '0');
        else
            if rxcharisk_i(0) = '1' or rxcharisk_i(1) = '1' then 
                databuf_data_o <= rxdata_i(7 downto 0);
            end if;
            if rxdata_i(7 downto 0) = c_K28_0 then
                kchar_o(0) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_1 then
                kchar_o(1) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_2 then
                kchar_o(2) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_3 then
                kchar_o(3) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_4 then
                kchar_o(4) <= '1';        
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_5 then
                kchar_o(5) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_6 then
                kchar_o(6) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_7 then
                kchar_o(7) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K23_7 then
                kchar_o(8) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K27_7 then
                kchar_o(9) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K29_7 then
                kchar_o(10) <= '1';
                kchar_linkup_o <= '1';
            elsif rxdata_i(7 downto 0) = c_K30_7 then 
                kchar_o(11) <= '1';
                kchar_linkup_o <= '1';
            else
                kchar_o <= (others => '0');
            end if;
        end if;
    end if;    
end process ps_dec_data;



ps_shift_reg: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            utime_shift_reg <= (others => '0');
            utime_o <= (others => '0');
        else
            if rxdata_i(15 downto 8) = c_code_seconds_0 then
                utime_shift_reg <= utime_shift_reg(30 downto 0) & '0';
            elsif rxdata_i(15 downto 8) = c_code_seconds_1 then
                utime_shift_reg <= utime_shift_reg(30 downto 0) & '1';
            elsif rxdata_i(15 downto 8) = c_code_reset_event then
                utime_shift_reg <= (others => '0');
                utime_o <= utime_shift_reg;
            end if;
        end if;            
    end if;
end process ps_shift_reg;    
    
    
    
prescaler_o <= std_logic_vector(prescaler);
count_o <= std_logic_vector(count);
loss_lock_o <= loss_lock;
rx_error_count_o <= std_logic_vector(rx_error_count);    
    
   
    
    
ps_link_lost:process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            prescaler <= (others => '0');
            count <= c_MGT_RX_PRESCALE;
        else
            -- 
            if prescaler = 0 then
                -- 0.008441037ms
                if count = 0 then
                    rx_link_ok <= '1';
                else
                    rx_link_ok <= '0';  
                end if;
            
                if count /= 0 then
                    count <= count +1;
                end if;        
            end if;
            
            if count < c_MGT_RX_LOCK_ACQ then
                if loss_lock = '1' then
                    count <= c_MGT_RX_LOCK_ACQ;
                end if;
            end if;
            
            if rx_link_ok = '0' then
                loss_lock <= rx_error;
            else
                loss_lock <= rx_error_count(5);
            end if;
            
            if rx_link_ok = '1' then
                if rx_error = '1' then
                    if rx_error_count(5) = '0' then
                        rx_error_count <= rx_error_count -1;
                    end if;
                else
                    if prescaler = 0 and (rx_error_count(5) = '1' or rx_error_count(4) = '0') then
                        rx_error_count <= rx_error_count +1;
                    end if;
                end if;
            else
                rx_error_count <= "011111";                                
            end if;          
        
            -- rxnotintable_i :- Indicates that the corresponding byte isnt a valid 8B/10B character
            -- rxdisperr_i    :- Indicates that received data is corrupted or tx of a invalid control character      
            if (rxnotintable_i /= c_zeros or rxdisperr_i /= c_zeros or 
               -- K charater present 
               -- K23.7 = F7 = 1111 0111 
               -- K27.7 = FB = 1111 1011 
               -- K29.7 = FD = 1111 1101
               -- K28.0 to K28.7 OK
               -- What about K30.7 = FE = 1111 1110 
               (rxcharisk_i(0) = '1' and rxdata_i(7) = '1')) then
                rx_error <= '1';   
            else
                rx_error <= '0';
            end if;
        
            -- 1023 clock count down
            if prescaler = c_MGT_RX_PRESCALE -1 then
                prescaler <= (others => '0');
            else
                prescaler <= prescaler +1;
            end if;
        end if;            
    end if;
end process ps_link_lost;  
        
                                   
    

end rtl;
