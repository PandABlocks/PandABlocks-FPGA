library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sfp_receiver is

    generic (events         : natural := 4);

    port (clk_i              : in  std_logic;
          reset_i            : in  std_logic;
          rxdisperr_i        : in  std_logic_vector(1 downto 0);
          rxdata_i           : in  std_logic_vector(15 downto 0);
          rxnotintable_i     : in  std_logic_vector(1 downto 0);
          EVENT1             : in  std_logic_vector(31 downto 0);
          EVENT2             : in  std_logic_vector(31 downto 0);
          EVENT3             : in  std_logic_vector(31 downto 0);
          EVENT4             : in  std_logic_vector(31 downto 0);
          rx_link_ok_o       : out std_logic;
          bit1_o             : out std_logic;
          bit2_o             : out std_logic;
          bit3_o             : out std_logic;
          bit4_o             : out std_logic;
          error_cnt_o        : out std_logic_vector(27 downto 0);
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

constant c_MGT_RX_PRESCALE  : unsigned(9 downto 0) := to_unsigned(1023,10);


type t_event is array(events-1 downto 0) of std_logic_vector(8 downto 0);    
type t_dbus_comp is array(events-1 downto 0) of std_logic_vector(7 downto 0);


signal event            : t_event;
signal dbus_comp        : t_dbus_comp;
signal rx_error         : std_logic;
signal loss_lock        : std_logic;
signal rx_link_ok       : std_logic; 
signal rx_error_count   : unsigned(5 downto 0);
signal prescaler        : unsigned(9 downto 0);
signal event_bits       : std_logic_vector(events-1 downto 0);    
signal utime_shift_reg  : std_logic_vector(31 downto 0);
signal disable_link     : std_logic;
signal error_cnt        : unsigned(27 downto 0);

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


error_cnt_o <= std_logic_vector(error_cnt);


-- Unix time 
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
 	 

-- Assign the array outputs individual bits
bit1_o <= event_bits(0);
bit2_o <= event_bits(1);
bit3_o <= event_bits(2);
bit4_o <= event_bits(3);

-- Assign the registers to an array      
event(0) <= EVENT1(8 downto 0);
event(1) <= EVENT2(8 downto 0);
event(2) <= EVENT3(8 downto 0);
event(3) <= EVENT4(8 downto 0);            

-- AND the EVENTs with the data coming in and do a bit comparison 
dbus_comp(0) <= EVENT1(7 downto 0) and rxdata_i(15 downto 8);
dbus_comp(1) <= EVENT2(7 downto 0) and rxdata_i(15 downto 8);
dbus_comp(2) <= EVENT3(7 downto 0) and rxdata_i(15 downto 8);
dbus_comp(3) <= EVENT4(7 downto 0) and rxdata_i(15 downto 8);

ps_event_dbus: process(clk_i)
begin
    if rising_edge(clk_i) then
        if rx_link_ok = '1' then 
            lp_events: for i in events-1 downto 0 loop            
                -- DBUS         bit comparison
                -- Event Codes  value comparison    
                -- Top bit indicates which bus to use
                -- event_dbus(8) = '1' - RXDATA(15 downto 8)
                -- event_dbus(8) = '0' - RXDATA(7 downto 0) 
                -- DBUS         RXDATA(15 downto 8)    1 = DBUS
                -- EVENT_CODES  RXDATA(7 downto 0)     0 = EVENT_CODES
                -- DBus these are bit comparisons
                if (event(i)(8) = '1' and dbus_comp(i) /= x"00") or
                   (event(i)(8) = '0' and (event(i)(7 downto 0) = rxdata_i(7 downto 0) and rxdata_i(7 downto 0) /= x"00")) then
                   if rxnotintable_i /= "00" and rxdisperr_i /= "00" then
                        error_cnt <= error_cnt +1;
                   end if;     
                     event_bits(i) <= '1';                                
                else
                    event_bits(i) <= '0';    
                end if;
            end loop lp_events;
        else
            error_cnt <= (others => '0');
        end if;
    end if;                                                    
end process ps_event_dbus;



-- This is a modified copy of the code used in the original event receiver 
-- It is hard to know when the link is up as the only way of doing this is to use
-- rxnotintable and rxdisperr signals.
-- rxnotintable and rxdisperr errors do occur when the link is up, I run the the event 
-- receiver for four days counting the number of times these two errors happened the 
-- error rate was days 4 error count 12272 
ps_link_lost:process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            prescaler <= (others => '0');
            disable_link <= '1';           
        else
            -- Check the status of the link every 1023 clocks 
            if prescaler = 0 then
                -- 0.008441037ms
                -- The link has gone down or is up
                if disable_link = '0' then          
                    rx_link_ok <= '1';
                else
                    rx_link_ok <= '0';  
                end if;
            
                if disable_link = '1' then
                    disable_link <= '0';
                end if;    
                
            end if;
            
            -- Check the link status loss_lock if 
            -- not set then set the signal disable_link
            if disable_link = '0' then
                if loss_lock = '1' then
                    disable_link <= '1';
                end if;
            end if;
            -- Link is down 
            if rx_link_ok = '0' then
                loss_lock <= rx_error;
            else
                loss_lock <= rx_error_count(5);
            end if;
            -- Error has occured 
            -- Check the link for errors
            if rx_link_ok = '1' then
                if rx_error = '1' then
                    -- Subtract one from error count (count down error count)
                    if rx_error_count(5) = '0' then
                        rx_error_count <= rx_error_count -1;
                    end if;
                else
                    -- Add one to the error count to handle occasional errors happening   
                    if prescaler = 0 and (rx_error_count(5) = '1' or rx_error_count(4) = '0') then
                        rx_error_count <= rx_error_count +1;
                    end if;
                end if;
            -- Link up set the count down error count to 31
            else
                rx_error_count <= "011111";                                
            end if;          
            -- RXNOTINTABLE :- The received data value is not a valid 10b/8b value
            -- RXDISPERR    :- Indicates data corruption or tranmission of a invalid control character 
            if (rxnotintable_i /= c_zeros or rxdisperr_i /= c_zeros) then 
                rx_error <= '1';   
            else
                rx_error <= '0';
            end if;
            -- 1023 clock count up
            if prescaler = c_MGT_RX_PRESCALE -1 then
                prescaler <= (others => '0');
            else
                prescaler <= prescaler +1;
            end if;
        end if;            
    end if;
end process ps_link_lost;  
        
                                   
    

end rtl;
