library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sfp_receiver is

    port (clk_i              : in  std_logic;
          reset_i            : in  std_logic;
          CLEAR_REG          : in  std_logic;
          CLEAR_REGS_WSTB    : in  std_logic;                 
          rxcharisk_i        : in  std_logic_vector(1 downto 0);
          rxdisperr_i        : in  std_logic_vector(1 downto 0);
          rxdata_i           : in  std_logic_vector(15 downto 0);
          dischar_o          : out std_logic_vector(3 downto 0);
          event_codes_o      : out std_logic_vector(5 downto 0);
          kchar_o            : out std_logic_vector(11 downto 0);
          event_codes_data_o : out std_logic_vector(7 downto 0);
          databuf_data_o     : out std_logic_vector(7 downto 0)   
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
        


ps_dis_char: process(clk_i)
begin
    if rising_edge(clk_i) then        
        if CLEAR_REG = '1' and CLEAR_REGS_WSTB = '1' then
            dischar_o <= (others => '0');
        else
            -- K Characters
            if rxcharisk_i(0) = '1' then
                dischar_o(0) <= '1';
            end if;
            if rxcharisk_i(1) = '1' then
                dischar_o(1) <= '1';
            end if;    
            -- Disparity error 
            if rxdisperr_i(0) = '1' then
                dischar_o(2) <= '1';
            end if;
            if rxdisperr_i(1) = '1' then
                dischar_o(3) <= '1';
            end if;
        end if;
    end if;            
end process ps_dis_char;



ps_dec_event_codes: process(clk_i)
begin
    if rising_edge(clk_i) then
        if CLEAR_REG = '1' and CLEAR_REGS_WSTB = '1' then
            event_codes_o <= (others => '0');    
        else
            -- heartbeat resets a counter to (1599999, 22)
            if rxdata_i(15 downto 8) = c_code_heartbeat then
                event_codes_o(0) <= '1';
                event_codes_data_o <= rxdata_i(15 downto 8);
            -- resets prescaler
            elsif rxdata_i(15 downto 8) = c_code_reset_presc then
                event_codes_o(1) <= '1';
                event_codes_data_o <= rxdata_i(15 downto 8);
            -- code_event_clk
            elsif rxdata_i(15 downto 8) = c_code_event_code then
                event_codes_o(2) <= '1';
                event_codes_data_o <= rxdata_i(15 downto 8);
            -- resets and counter := prescaler
            elsif rxdata_i(15 downto 8) = c_code_reset_event then
                event_codes_o(3) <= '1';
                event_codes_data_o <= rxdata_i(15 downto 8);
            -- second 0
            elsif rxdata_i(15 downto 8) = c_code_seconds_0 then
                event_codes_o(4) <= '1';
                event_codes_data_o <= rxdata_i(15 downto 8);
            -- second 1
            elsif rxdata_i(15 downto 8) = c_code_seconds_1 then       
                event_codes_o(5) <= '1';
                event_codes_data_o <= rxdata_i(15 downto 8);
            end if;
        end if;    
    end if;
end process ps_dec_event_codes;    


ps_dec_data: process(clk_i)
begin
    if rising_edge(clk_i) then 
        if CLEAR_REG = '1' and CLEAR_REGS_WSTB = '1' then
            kchar_o <= (others => '0');
            databuf_data_o <= (others => '0'); 
        else
            if rxcharisk_i(0) = '1' or rxcharisk_i(1) = '1' then 
                databuf_data_o <= rxdata_i(7 downto 0);
            end if;
            if rxdata_i(7 downto 0) = c_K28_0 then
                kchar_o(0) <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_1 then
                kchar_o(1) <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_2 then
                kchar_o(2) <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_3 then
                kchar_o(3) <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_4 then
                kchar_o(4) <= '1';        
            elsif rxdata_i(7 downto 0) = c_K28_5 then
                kchar_o(5) <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_6 then
                kchar_o(6) <= '1';
            elsif rxdata_i(7 downto 0) = c_K28_7 then
                kchar_o(7) <= '1';
            elsif rxdata_i(7 downto 0) = c_K23_7 then
                kchar_o(8) <= '1';
            elsif rxdata_i(7 downto 0) = c_K27_7 then
                kchar_o(9) <= '1';
            elsif rxdata_i(7 downto 0) = c_K29_7 then
                kchar_o(10) <= '1';
            elsif rxdata_i(7 downto 0) = c_K30_7 then 
                kchar_o(11) <= '1';
            else
                kchar_o <= (others => '0');
            end if;
        end if;
    end if;    
end process ps_dec_data;


end rtl;
