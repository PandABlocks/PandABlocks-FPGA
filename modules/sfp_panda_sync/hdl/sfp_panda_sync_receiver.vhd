library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sfp_panda_sync_receiver is

    port (clk_i             : in  std_logic;
          rxoutclk_i        : in  std_logic;   
          reset_i           : in  std_logic;
          rxdisperr_i       : in  std_logic_vector(3 downto 0);
          rxcharisk_i       : in  std_logic_vector(3 downto 0);
          rxdata_i          : in  std_logic_vector(31 downto 0);
          rxnotintable_i    : in  std_logic_vector(3 downto 0);
          rx_link_ok_o      : out std_logic;
          loss_lock_o       : out std_logic;
          rx_error_o        : out std_logic;
          BITIN_o           : out std_logic_vector(15 downto 0);   
          POSIN1_o          : out std_logic_vector(31 downto 0);
          POSIN2_o          : out std_logic_vector(31 downto 0);
          POSIN3_o          : out std_logic_vector(31 downto 0);
          POSIN4_o          : out std_logic_vector(31 downto 0)
          );

end sfp_panda_sync_receiver;


architecture rtl of sfp_panda_sync_receiver is


type t_STATE_DATA is (STATE_BITS_DATA, STATE_POSOUT1, STATE_POSOUT2, STATE_POSOUT3, STATE_POSOUT4);

type t_rxdata_pos is array(0 to 3) of std_logic_vector(31 downto 0);
type t_rxdata_bit is array(0 to 3) of std_logic_vector(15 downto 0);

constant c_kchar_byte_en    : std_logic_vector(3 downto 0) := "0001"
constant c_zeros            : std_logic_vector(3 downto 0) := "0000";
constant c_k28_0            : std_logic_vector(7 downto 0) := x"1C";
constant c_MGT_RX_PRESCALE  : unsigned(9 downto 0) := to_unsigned(1023,10);


signal STATE_DATA            : t_STATE_DATA;   
signal rxdata_pos            : t_rxdata_pos;
signal rxdata_bit            : t_rxdata_bit;   
signal rx_error              : std_logic;
signal loss_lock             : std_logic;
signal rx_link_ok            : std_logic := '0';
signal pktstart              : std_logic;
signal rx_error_count        : unsigned(5 downto 0);
signal prescaler             : unsigned(9 downto 0) := (others => '0');
signal disable_link          : std_logic := '1';
signal pkt_cnt               : unsigned(1 downto 0);
signal data_num              : unsigned(7 downto 0);
signal data_num_dly          : unsigned(7 downto 0);
signal data_stretched        : std_logic_vector(7 downto 0);             
signal BITIN                 : std_logic_vector(15 downto 0);
signal POSIN1                : std_logic_vector(31 downto 0);
signal POSIN2                : std_logic_vector(31 downto 0);
signal POSIN3                : std_logic_vector(31 downto 0);   
signal POSIN4                : std_logic_vector(31 downto 0);   
-- Metastable signals
signal rx_link_ok_meta1      : std_logic;
signal rx_link_ok_meta2      : std_logic; 
signal data_stretched_meta1  : std_logic_vector(7 downto 0);
signal data_stretched_meta2  : std_logic_vector(7 downto 0);  

attribute ASYNC_REG : string;
attribute ASYNC_REG of data_stretched_meta1 : signal is "TRUE";
attribute ASYNC_REG of data_stretched_meta2 : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok_meta1     : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok_meta2     : signal is "TRUE"; 

begin

loss_lock_o <= loss_lock;
rx_error_o <= rx_error;
rx_link_ok_o <= rx_link_ok;


-- This is a modified version of the code used in the open source event receiver
-- It is hard to know when the link is up as the only way of doing this is to use
-- rxnotintable and rxdisperr signals.
-- rxnotintable and rxdisperr errors do occur when the link is up, I run the the event
-- receiver for four days counting the number of times these two errors happened the
-- error rate was days 4 error count 12272
ps_link_lost:process(rxoutclk_i)
begin
    if rising_edge(rxoutclk_i) then
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



-- Received data          Packet Start          Alignment           data_num(7 downto 0) 
-- BITIN1 and K28              1                   0                   1      0   
-- POSIN1                      0                   0                  16      4
-- BITIN2 and zero             0                   0                   2      1
-- POSIN2                      0                   0                  32      5
-- BITIN3 and zero             0                   0                   4      2
-- POSIN3                      0                   0                  64      6
-- BITIN4 and K28.5            0                   1                   8      3
-- POSIN4                      0                   0                 128      7
-- BITIN1 and K28              1                   0                   1      0  
-- POSIN1                      0                   0                  16      4
-- BITIN2 and zero             0                   0                   2      1


-- Capture the data
ps_data: process(rxoutclk_i)
begin
    if rising_edge(rxoutclk_i) then
        if (rx_link_ok = '1') then
            data_num_dly <= data_num;
            case STATE_DATA is
            
                -- Change the code so it uses ping pong buffers
                when STATE_BITS_DATA => 
                    -- Packet start 16 bits                    
                    if (rxcharisk_i = c_kchar_byte_en and rxdata_i(7 downto 0) = c_k28_0) then
                        pktstart <= '1';
                        data_num <= to_unsigned(1,8);
                        rxdata_bit(0) <= rxdata_i(31 downto 16);
                        STATE_DATA <= STATE_POSOUT1;
                    -- 16 bits
                    elsif (pkt_cnt = 1) then
                        data_num <= to_unsigned(2,8);
                        rxdata_bit(1) <= rxdata_i(31 downto 16);
                        STATE_DATA <= STATE_POSOUT2;
                    -- 16 bits
                    elsif (pkt_cnt = 2) then
                        data_num <= to_unsigned(4,8);                    
                        rxdata_bit(2) <= rxdata_i(31 downto 16);
                        STATE_DATA <= STATE_POSOUT3;
                    -- 16 bits
                    elsif (pkt_cnt = 3) then
                        data_num <= to_unsigned(8,8);                    
                        rxdata_bit(3) <= rxdata_i(31 downto 16);
                        STATE_DATA <= STATE_POSOUT4;         
                    end if;
                    
                -- POSOUT1    
                when STATE_POSOUT1 => 
                    data_num <= to_unsigned(16,8);
                    pktstart <= '0';
                    rxdata_pos(0) <= rxdata_i;
                    pkt_cnt <= to_unsigned(1,2);
                    STATE_DATA <= STATE_BITS_DATA;
                
                -- POSOUT2
                when STATE_POSOUT2 => 
                    data_num <= to_unsigned(32,8);                
                    pktstart <= '0';
                    rxdata_pos(1) <= rxdata_i;
                    pkt_cnt <= to_unsigned(2,2);
                    STATE_DATA <= STATE_BITS_DATA;
                
                -- POSOUT3
                when STATE_POSOUT3 => 
                    data_num <= to_unsigned(64,8);                
                    pktstart <= '0';
                    rxdata_pos(2) <= rxdata_i;
                    pkt_cnt <= to_unsigned(3,2);
                    STATE_DATA <= STATE_BITS_DATA;
                
                -- POSOUT4
                when STATE_POSOUT4 => 
                    data_num <= to_unsigned(128,8);
                    pktstart <= '0';
                    rxdata_pos(3) <= rxdata_i;
                    pkt_cnt <= to_unsigned(0,2);
                    STATE_DATA <= STATE_BITS_DATA;
                
                -- Others     
                when others => 
                    STATE_DATA <= STATE_BITS_DATA;
            end case;                         
        else
            pktstart <= '0';
            pkt_cnt <= (others => '0');
            data_num <= (others => '0');
            STATE_DATA <= STATE_BITS_DATA;
        end if;
    end if;
end process ps_data;    
    

-- Stretch the data valid signal 
data_stretched <= std_logic_vector(data_num_dly) or std_logic_vector(data_num);


BITIN_o  <= BITIN;
POSIN1_o <= POSIN1;
POSIN2_o <= POSIN2;
POSIN3_o <= POSIN3;
POSIN4_o <= POSIN4; 



-- BITIN(start packet k character), POSIN1, BITIN, POSIN2, BITIN, POSIN3, BITIN(alignment k character), POSIN4

-- RXDATA  data_stretched_meta2    8   7   6   5   4   3   2   1   
-- BITIN1                          0   0   0   0   0   0   0   1
-- POSIN1                          0   0   0   0   0   0   1   0                      
-- BITIN2                          0   0   0   0   0   1   0   0 
-- POSIN2                          0   0   0   0   1   0   0   0 
-- BITIN3                          0   0   0   1   0   0   0   0
-- POSOUT3                         0   0   1   0   0   0   0   0
-- BITIN4                          0   1   0   0   0   0   0   0          
-- POSOUT4                         1   0   0   0   0   0   0   0  

ps_meta_data: process(clk_i)
begin
    if rising_edge(clk_i) then
        rx_link_ok_meta1 <= rx_link_ok;
        rx_link_ok_meta2 <= rx_link_ok_meta1;    
        if (rx_link_ok_meta2 = '1') then
            -- The receuver is up and running 
            -- Meta the stretched data valid signal 
            data_stretched_meta1 <= data_stretched;    
            data_stretched_meta2 <= data_stretched_meta1;
            -- Pass out the BITIN 16 bits data
            lp_meta: for i in 0 to 3 loop
                if data_stretched_meta2(i) = '1' then
                    BITIN <= rxdata_bit(i);
--                elsif data_stretched_meta2(3 downto 0) = "0000" then
--                    BITIN <= BITIN;
                end if;
            end loop lp_meta;    
            
            -- Pass out the POS 1 data
            if data_stretched_meta2(4) = '1' then
                POSIN1 <= rxdata_pos(0);
            else
                POSIN1 <= POSIN1;
            end if;        
            
            -- Pass out the POS 2 data
            if data_stretched_meta2(5) = '1' then
                POSIN2 <= rxdata_pos(1);
            else
                POSIN2 <= POSIN2;
            end if;    
            
            -- Pass out the POS 3 data
            if data_stretched_meta2(6) = '1' then
                POSIN3 <= rxdata_pos(2);
            else
                POSIN3 <= POSIN3;
            end if;
            
            -- Pass out the POS 4 data
            if data_stretched_meta2(7) = '1' then
                POSIN4 <= rxdata_pos(3);
            else
                POSIN4 <= POSIN4;
            end if;                        
        else
            data_stretched_meta1 <= (others => '0');
            data_stretched_meta2 <= (others => '0');
        end if;
    end if;
end process ps_meta_data;    
    
    

end rtl;
