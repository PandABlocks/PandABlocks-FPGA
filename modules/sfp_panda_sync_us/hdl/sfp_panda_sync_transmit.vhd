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


type t_SM_DATA is (STATE_BITIN, STATE_POSIN13, STATE_POSIN24);

type t_data is array(5 downto 0) of std_logic_vector(31 downto 0);

constant c_k28_5                      : std_logic_vector(7 downto 0) := x"BC";
constant c_k28_0                      : std_logic_vector(7 downto 0) := x"1C";   
constant c_zeros                      : std_logic_vector(7 downto 0) := x"00";
constant c_kchar                      : std_logic_vector(3 downto 0) := x"1";

signal SM_DATA                        : t_SM_DATA;
signal data_buf                       : t_data := (others => (others => '0'));
signal start_in                       : std_logic := '0';
signal start_in_meta1                 : std_logic;
signal start_in_meta2                 : std_logic;
signal start_in_dly                   : std_logic;
signal start_in_xored                 : std_logic;
signal start_in_xored_pos12           : std_logic;
signal start_in_xored_pos34           : std_logic;    
signal bit_ored                       : std_logic_vector(15 downto 0);  
signal txdata                         : std_logic_vector(31 downto 0);  

signal probe1                         : std_logic_vector(31 downto 0);
signal probe2                         : std_logic_vector(31 downto 0);
signal probe3                         : std_logic_vector(31 downto 0);
signal probe4                         : std_logic_vector(31 downto 0);
signal probe5                         : std_logic_vector(31 downto 0);
signal probe6                         : std_logic_vector(5 downto 0);  
signal probe7                         : std_logic_vector(31 downto 0);

attribute ASYNC_REG : string;
attribute ASYNC_REG of start_in_meta1  : signal is "TRUE";
attribute ASYNC_REG of start_in_meta2  : signal is "TRUE";
attribute ASYNC_REG of start_in_dly    : signal is "TRUE"; 


begin

    
-- Store              start_in    meta1   meta2   dly   xor   xor12   xor34     TX                                    
--                       0          0       0      0     0      0       0      POSOUT3 
--                       1          0       0      0     0      0       0      POSOUT4 
--                       1          1       0      0     0      0       0      BITOUT(PKT ALIGN)  
-- BITOUT(PKT START)     1          1       1      0     1      0       0      POSOUT1                       
-- POSOUT1               0          1       1      1     0      1       0      POSOUT2
-- POSOUT2               0          0       1      1     0      0       1      BITOUT(PKT START)
-- BITOUT(PKT ALIGN)     0          0       0      1     1      0       0      POSOUT3
-- POSOUT3               1          0       0      0     0      1       0      POSOUT4     
-- POSOUT4               1          1       0      0     0      0       1      BITOUT(PKT SLIGN) 
-- BITOUT(PKT START)     1          1       1      0     1      0       0      POSOUT1                                   

-- XOR for edge detection find both edges 
start_in_xored <= start_in_dly xor start_in_meta2;
    
    
ps_data_in: process(clk_i)
begin
    if rising_edge(clk_i) then
          -- Synchronous the signal from the other clock domain  
          start_in_meta1 <= start_in;
          start_in_meta2 <= start_in_meta1;          
          start_in_dly <= start_in_meta2;
          start_in_xored_pos12 <= start_in_xored;
          start_in_xored_pos34 <= start_in_xored_pos12;
        -- Detect the edges BIT              
        if (start_in_xored = '1') then
            bit_ored <= (others => '0');                
            data_buf(0) <= (bit_ored or BITOUT_i) & x"0000";
        else
            bit_ored <= bit_ored or BITOUT_i;              
        end if;                
        -- POSOUT13                           
        if (start_in_xored_pos12 = '1') then
            data_buf(1) <= POSOUT1_i;
            data_buf(3) <= POSOUT3_i;
        end if;
        -- POSOUT24
        if (start_in_xored_pos34 = '1') then    
            data_buf(2) <= POSOUT2_i;                 
            data_buf(4) <= POSOUT4_i;
        end if;
    end if;
end process ps_data_in;        


 -- 
 -- probe1 <= (others => '0'); 
 -- probe2 <= (others => '0');
 -- probe3 <= (others => '0');
 -- probe4 <= (others => '0');
 -- probe5 <= (others => '0'); 
 -- probe6 <= (others => '0');
 -- probe7 <= (others => '0');
 -- 
 -- 
 -- -- Chipscope
 -- ila_tx_inst : ila_0
 -- port map (
 --       clk     => txoutclk_i,
 --       probe0  => txdata,
 --       probe1  => probe1,
 --       probe2  => probe2,
 --       probe3  => probe3,
 --       probe4  => probe4,
 --       probe5  => probe5,
 --       probe6  => probe6,
 --       probe7  => probe7
 -- );
 -- 


txdata_o <= txdata;


ps_data_out: process(txoutclk_i)
begin
    if rising_edge(txoutclk_i) then
                
        case SM_DATA is
                    
            -- 16 bits plus the k character or just zeros
            when STATE_BITIN =>
                txcharisk_o <= c_kchar;
                -- Packet start bit
                if (start_in = '0') then
                    txdata <= data_buf(0)(31 downto 16) & x"00" & c_k28_0;     
                -- Packet Alignment
                else
                    txdata <= data_buf(0)(31 downto 16) & x"00" & c_k28_5;
                end if;        
                SM_DATA <= STATE_POSIN13;
                        
            -- POSOUT1 or POSOUT3
            when STATE_POSIN13 => 
                txcharisk_o <= (others => '0');
                if (start_in = '0') then
                    txdata <= data_buf(1); 
                else
                    txdata <= data_buf(3);
                end if;                    
                SM_DATA <= STATE_POSIN24;
                    
            -- POSOUT2 or POSOUT     
            when STATE_POSIN24 => 
                start_in <= not start_in;
                txcharisk_o <= (others => '0');
                if (start_in = '0') then                
                    txdata <= data_buf(2);
                else
                    txdata <= data_buf(4);
                end if;        
                SM_DATA <= STATE_BITIN;
                        
        end case;                             
    end if;
end process ps_data_out;    
        
        
        


end rtl;
