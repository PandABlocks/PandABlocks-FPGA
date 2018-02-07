library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sfp_receiver is

    generic (events         : natural := 4);

    port (clk_i              : in  std_logic;
          reset_i            : in  std_logic;
          rxcharisk_i        : in  std_logic_vector(1 downto 0);
          rxdisperr_i        : in  std_logic_vector(1 downto 0);
          rxdata_i           : in  std_logic_vector(15 downto 0);
          rxnotintable_i     : in  std_logic_vector(1 downto 0);
          EVENT0             : in  std_logic_vector(31 downto 0);
          EVENT0_WSTB        : in  std_logic;   
          EVENT1             : in  std_logic_vector(31 downto 0);
          EVENT1_WSTB        : in  std_logic;   
          EVENT2             : in  std_logic_vector(31 downto 0);
          EVENT2_WSTB        : in  std_logic;   
          EVENT3             : in  std_logic_vector(31 downto 0);
          EVENT3_WSTB        : in  std_logic;
          rx_link_ok_o       : out std_logic;
          bit0_o             : out std_logic;
          bit1_o             : out std_logic;
          bit2_o             : out std_logic;
          bit3_o             : out std_logic;
          utime_o            : out std_logic_vector(31 downto 0)
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


constant c_zeros : std_logic_vector(1 downto 0) := "00";    

constant c_MGT_RX_LOCK_ACQ  : unsigned(9 downto 0) := to_unsigned(1023,10); 
constant c_MGT_RX_PRESCALE  : unsigned(9 downto 0) := to_unsigned(1023,10);


type t_event_dbus is array(events-1 downto 0) of std_logic_vector(8 downto 0);    


signal event_dbus       : t_event_dbus;
signal rx_error         : std_logic;
signal loss_lock        : std_logic;
signal rx_link_ok       : std_logic; 
signal rx_error_count   : unsigned(5 downto 0);
signal prescaler        : unsigned(9 downto 0);
signal count            : unsigned(9 downto 0);
signal event_bits       : std_logic_vector(events-1 downto 0);    
--signal event_bits_reset : std_logic_vector(events-1 downto 0);
--signal rxdata           : std_logic_vector(15 downto 0);
signal utime_shift_reg  : std_logic_vector(31 downto 0);


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
--|     K28.5   | 101 11100 | 001111 1010  | 110000 0101  | -- THIS IS THE ONE THAT IS USED
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
  
      
-- 15                      8 7                       0 
--  --------------------------------------------------
--  |	     DBUS DATA	    | KCHAR And EVENT CODES  |
--  --------------------------------------------------	        



rx_link_ok_o <= rx_link_ok;


ps_shift_reg: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            utime_shift_reg <= (others => '0');
            utime_o <= (others => '0');
        else
            -- Shift a '0' into the shift register		
            if rxdata_i(7 downto 0) = c_code_seconds_0 then
                utime_shift_reg <= utime_shift_reg(30 downto 0) & '0';
            -- Shift a '1' into the shift register
            elsif rxdata_i(7 downto 0) = c_code_seconds_1 then
                utime_shift_reg <= utime_shift_reg(30 downto 0) & '1';
            -- Shift the unix time out 
            elsif rxdata_i(7 downto 0) = c_code_reset_event then
                utime_shift_reg <= (others => '0');
                utime_o <= utime_shift_reg;
            end if;
        end if;            
    end if;
end process ps_shift_reg;    
 	 
   

ps_event_dbus: process(clk_i)
begin
    if rising_edge(clk_i) then
--        rxdata <= rxdata_i;
--        event_bits_reset <= EVENT3_WSTB & EVENT2_WSTB & EVENT1_WSTB & EVENT0_WSTB;
        event_dbus(0) <= EVENT0(8 downto 0); 
        event_dbus(1) <= EVENT1(8 downto 0); 
        event_dbus(2) <= EVENT2(8 downto 0);
        event_dbus(3) <= EVENT3(8 downto 0);
        if rx_link_ok = '1' then 
            lp_events: for i in events-1 downto 0 loop    
                -- Top bit indicates which bus to use
                -- event_dbus(8) = '1' - RXDATA(15 downto 8)
                -- event_dbus(8) = '0' - RXDATA(7 downto 0) 
                -- DBUS         RXDATA(15 downto 8)     1 = DBUS
                -- EVENT_CODES  RXDATA(7 downto 0)     0 = EVENT_CODES
                if ((event_dbus(i)(8) = '1' and event_dbus(i)(7 downto 0) = rxdata_i(15 downto 8) and rxdata_i(15 downto 8) /= x"00") or
                    (event_dbus(i)(8) = '0' and event_dbus(i)(7 downto 0) = rxdata_i(7 downto 0) and rxdata_i(7 downto 0) /= x"00")) then
                    event_bits(i) <= '1';                                
                else
                    event_bits(i) <= '0';    
                end if;
            end loop lp_events;
        end if;
        bit0_o <= event_bits(0);
        bit1_o <= event_bits(1);
        bit2_o <= event_bits(2);
        bit3_o <= event_bits(3);
    end if;                                                    
end process ps_event_dbus;

    



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
        
            if (rxnotintable_i /= c_zeros or rxdisperr_i /= c_zeros) then 
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
