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

-- component ila_0
-- 
--     port (
--           clk     : std_logic;
--           probe0  : std_logic_vector(31 downto 0);
--           probe1  : std_logic_vector(31 downto 0);
--           probe2  : std_logic_vector(31 downto 0);
--           probe3  : std_logic_vector(31 downto 0);
--           probe4  : std_logic_vector(31 downto 0);
--           probe5  : std_logic_vector(31 downto 0);
--           probe6  : std_logic_vector(5 downto 0);
--           probe7  : std_logic_vector(31 downto 0)
-- );
-- 
-- end component;


type t_STATE_DATA is (STATE_BITS_START_ALIGN, STATE_POSOUT13, STATE_POSOUT24);

type t_rxdata_bitpos is array(0 to 4) of std_logic_vector(31 downto 0);
--type t_rxdata_bit is array(0 to 1) of std_logic_vector(15 downto 0); 

constant c_kchar_byte_en    : std_logic_vector(3 downto 0) := "0001";
constant c_zeros            : std_logic_vector(3 downto 0) := "0000";
-- Packet start 
constant c_k28_0            : std_logic_vector(7 downto 0) := x"1C";
-- Word alignment
constant c_k28_5            : std_logic_vector(7 downto 0) := x"BC";
constant c_MGT_RX_PRESCALE  : unsigned(9 downto 0) := to_unsigned(1023,10);


signal STATE_DATA            : t_STATE_DATA;   
signal rxdata_bitpos         : t_rxdata_bitpos := (others => (others => '0'));   
signal rx_error              : std_logic;
signal loss_lock             : std_logic;
signal rx_link_ok            : std_logic := '0';
signal rx_error_count        : unsigned(5 downto 0);
signal prescaler             : unsigned(9 downto 0) := (others => '0');
signal disable_link          : std_logic := '1';
signal BITIN                 : std_logic_vector(15 downto 0);
signal POSIN1                : std_logic_vector(31 downto 0);
signal POSIN2                : std_logic_vector(31 downto 0);
signal POSIN3                : std_logic_vector(31 downto 0);   
signal POSIN4                : std_logic_vector(31 downto 0);   
signal startpkt              : std_logic;
signal start_nalignment      : std_logic;   
-- Metastable signals
signal rx_link_ok_meta1      : std_logic;
signal rx_link_ok_meta2      : std_logic; 
signal pktstart              : std_logic;
signal pktstart_xored        : std_logic;
signal pktstart_xored_pos12  : std_logic;
signal pktstart_xored_pos34  : std_logic; 
signal pktstart_meta1        : std_logic;
signal pktstart_meta2        : std_logic;  
signal pktstart_dly          : std_logic;

attribute ASYNC_REG : string;
attribute ASYNC_REG of pktstart_meta1   : signal is "TRUE";
attribute ASYNC_REG of pktstart_meta2   : signal is "TRUE";
attribute ASYNC_REG of pktstart_dly     : signal is "TRUE";   
attribute ASYNC_REG of rx_link_ok_meta1 : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok_meta2 : signal is "TRUE"; 

signal probe1                : std_logic_vector(31 downto 0);

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


-- probe1(3 downto 0) <= rxdisperr_i;
-- probe1(7 downto 4) <= rxnotintable_i;
-- probe1(8) <= rx_link_ok;
-- probe1(9) <= rx_error;
-- probe1(10) <= loss_lock; 
-- probe1(31 downto 11) <= (others => '0');
-- 
-- -- Chipscope
-- ila_rx_inst : ila_0
-- port map (
--       clk     => rxoutclk_i,
--       probe0  => rxdata_i,
--       probe1  => probe1,
--       probe2  => rxdata_bitpos(0),
--       probe3  => rxdata_bitpos(1),
--       probe4  => rxdata_bitpos(2),
--       probe5  => rxdata_bitpos(3),
--       probe6  => (others => '0'),
--       probe7  => rxdata_bitpos(4)
-- );
-- 


-- Received data          start_nalignment       pktstart 
-- BITIN1 and K28_0             x                   0         
-- POSIN1                       1                   0        
-- POSIN2                       1                   0        
-- BITIN3 and K28_5             x                   1        
-- POSIN3                       0                   1         
-- POSIN4                       0                   1         
-- BITIN1 and K28_o             x                   0      
-- POSIN1                       1                   0        
-- POSIN2                       1                   0        

-- Capture the data
ps_data: process(rxoutclk_i)
begin
    if rising_edge(rxoutclk_i) then
        if (rx_link_ok = '1') then

            case STATE_DATA is
            
                -- Packet Start
                when STATE_BITS_START_ALIGN => 
                    -- Packet start 16 bits         
                    -- K28 0 - Packet Start 
                    -- K28 5 - Packet Alignment          
                    if (rxcharisk_i = c_kchar_byte_en and rxdata_i(7 downto 0) = c_k28_0) then
                        start_nalignment <= '1';
                        rxdata_bitpos(0) <= rxdata_i;
                        STATE_DATA <= STATE_POSOUT13;                    
                    elsif                                         
                       (rxcharisk_i = c_kchar_byte_en and rxdata_i(7 downto 0) = c_k28_5) then 
                        start_nalignment <= '0';
                        rxdata_bitpos(0) <= rxdata_i;
                        STATE_DATA <= STATE_POSOUT13;
                    end if;
                    
                -- POSOUT1 or POSOUT3   
                when STATE_POSOUT13 =>
                    if (start_nalignment = '1') then                     
                        rxdata_bitpos(1) <= rxdata_i;
                    else
                        rxdata_bitpos(3) <= rxdata_i;
                    end if;    
                    STATE_DATA <= STATE_POSOUT24;
                                    
                -- POSOUT2 or POSOUT4
                when STATE_POSOUT24 =>
                    if (start_nalignment = '1') then 
                        rxdata_bitpos(2) <= rxdata_i;
                    else
                        rxdata_bitpos(4) <= rxdata_i;
                    end if;    
                    pktstart <= not pktstart;                    
                    STATE_DATA <= STATE_BITS_START_ALIGN;     
                                     
            end case;                         
        else
            pktstart <= '0';
            STATE_DATA <= STATE_BITS_START_ALIGN;
        end if;
    end if;
end process ps_data;    
    


BITIN_o  <= BITIN;
POSIN1_o <= POSIN1;
POSIN2_o <= POSIN2;
POSIN3_o <= POSIN3;
POSIN4_o <= POSIN4; 



-- BITIN(start packet k character), POSIN1, BITIN, POSIN2, BITIN, POSIN3, BITIN(alignment k character), POSIN4

-- BITIN                           1   0   0   0   0   
-- POSIN1                          0   1   0   0   0                         
-- POSIN2                          0   0   1   0   0    
-- BITIN                           1   0   0   0   0            
-- POSOUT3                         0   0   0   1   0   
-- POSOUT4                         0   0   0   0   1     


--pktstart_xored <= pktstart_dly xor pktstart_meta2;


ps_meta_data: process(clk_i)
begin
    if rising_edge(clk_i) then
        rx_link_ok_meta1 <= rx_link_ok;
        rx_link_ok_meta2 <= rx_link_ok_meta1;    
        -- The receuver is up and running 
        pktstart_meta1 <= pktstart;    
        pktstart_meta2 <= pktstart_meta1;
        pktstart_dly <= pktstart_meta2;
        pktstart_xored <= pktstart_dly xor pktstart_meta2;
        pktstart_xored_pos12 <= pktstart_xored;
        pktstart_xored_pos34 <= pktstart_xored_pos12;
        -- Link up 
        if (rx_link_ok_meta2 = '1') then
            -- Pass out the BITIN 16 bits data
            if pktstart_xored = '1' then
                -- Need to know if POS1 and POS2 or POS3 and POS4 are ready
                -- POS1 and POS2 
                if pktstart_meta2 = '1' then
                    startpkt <= '1';
                -- POS3 and POS4
                else
                    startpkt <= '0';
                end if;         
                BITIN <= rxdata_bitpos(0)(31 downto 16);
            end if;
            -- Pass out the POSIN1
            if pktstart_xored_pos12 = '1' and startpkt = '1' then    
                POSIN1 <= rxdata_bitpos(1);
            end if;
            -- Pass out the POSIN2
            if pktstart_xored_pos34 = '1' and startpkt = '1' then    
                POSIN2 <= rxdata_bitpos(2);
                
            end if;    
            -- Pass out the POSIN3
            if pktstart_xored_pos12 = '1' and startpkt = '0' then                
                POSIN3 <= rxdata_bitpos(3);
            end if;
            -- Pass out the POSIN4
            if pktstart_xored_pos34 = '1' and startpkt = '0' then    
                POSIN4 <= rxdata_bitpos(4);
            end if;                        
        else
            startpkt <= '0';
        end if;
    end if;
end process ps_meta_data;    
    
    

end rtl;
