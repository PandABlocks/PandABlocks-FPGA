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

type t_Sm_DATA_IN is (STATE_DATA1, STATE_DATA2, STATE_DATA3, STATE_DATA4, STATE_DATA5, STATE_DATA6, STATE_DATA7, STATE_DATA8);

type t_SM_DATA is (STATE_BITIN1, STATE_BITIN2, STATE_BITIN3, STATE_BITIN4, STATE_POSIN1, STATE_POSIN2, STATE_POSIN3, STATE_POSIN4);

type t_data is array(7 downto 0) of std_logic_vector(31 downto 0);

constant c_k28_5           : std_logic_vector(7 downto 0) := x"BC";
constant c_k28_0           : std_logic_vector(7 downto 0) := x"1C";   
constant c_zeros           : std_logic_vector(7 downto 0) := x"00";
constant c_kchar           : std_logic_vector(3 downto 0) := x"1";

signal SM_DATA             : t_SM_DATA;
signal SM_DATA_IN          : t_SM_DATA_IN; 
signal data_buf1           : t_data := (others => (others => '0'));
signal data_buf2           : t_data := (others => (others => '0'));  
signal input_done          : std_logic;
signal output_ready        : std_logic;  
signal buf_to_use          : std_logic;
signal buf                 : std_logic;  
signal data_stored         : std_logic_vector(15 downto 0); 

-- Metastable signals
signal output_ready_meta1  : std_logic;
signal output_ready_meta2  : std_logic;
signal input_done_meta1    : std_logic;
signal input_done_meta2    : std_logic; 
signal rx_link_ok1_meta1   : std_logic;
signal rx_link_ok1_meta2   : std_logic;
signal rx_link_ok2_meta1   : std_logic;
signal rx_link_ok2_meta2   : std_logic;

attribute ASYNC_REG : string;
attribute ASYNC_REG of output_ready_meta1 : signal is "TRUE";
attribute ASYNC_REG of output_ready_meta2 : signal is "TRUE";
attribute ASYNC_REG of input_done_meta1   : signal is "TRUE";
attribute ASYNC_REG of input_done_meta2   : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok1_meta1  : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok1_meta2  : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok2_meta1  : signal is "TRUE";
attribute ASYNC_REG of rx_link_ok2_meta2  : signal is "TRUE";


begin

-- DATA         
-- REG1  |        |
-- REG2  |  REG1  |                                  REG2 ored REG1     clock 1   
-- REG3  |  REG2  |  REG1                                               clock 2
-- REG4  |  REG3  |  REG2    REG1                    REG4 ored REG3     clock 1
-- REG5  |  REG4  |  REG3    REG2    REG1                               clock 2
-- REG6  |  REG5  |  REG4    REG3    REG2    REG1    REG6 ored REG5     clock 1
    

-- DATA         STORE         OR            POSOUT1     POSOUT2     POSOUT3     POSOUT4     TX         
--  1            0            0                1          1            1           1          
--  2            1         2 ored 1            1          1            1           1                  
--  3            1                             1          1            1           1    transmit(1 ored 2)            
--  4            3         4 ored 3            1          1            1           1    transmit(POSOUT1)     
--  5            3                             1          1            1           1    transmit(3 ored 4)         
--  6            5         6 ored 5            1          1            1           1    transmit(POSOUT2)
--  7            5                             1          1            1           1    transmit(6 ored 5)         
--  8            7         8 ored 7            1          1            1           1    transmit(POSOUT3)
--  1            7                             2          2            2           2    transmit(7 ored 8)
--  2            1         2 ored 1            2          2            2           2    transmit(POSOUT4)
--  3            1                             2          2            2           2    transmit(1 ored 2)
--  4            3         4 ored 3            2          2            2           2    transmit(POSOUT1)                        


ps_data_in: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- The receiver is up    
        rx_link_ok1_meta1 <= rx_link_ok_i;
        rx_link_ok1_meta2 <= rx_link_ok1_meta1;
        -- The output state machine is ready for data;
        output_ready_meta1 <= output_ready;
        output_ready_meta2 <= output_ready_meta1;
        
        
        --  
        if rx_link_ok1_meta2 = '1' then
                    
            data_stored <= BITOUT_i;
            
            case SM_DATA_IN is
                
                -- Capture the BITIN first time
                when STATE_DATA1 =>

                    if output_ready_meta2 = '1' then
                        input_done <= '0';
                        if buf = '0' then
                            data_buf1(0)(31 downto 16) <= (data_stored or BITOUT_i);
                            data_buf1(0)(15 downto 0)  <=  x"00" & c_k28_0;
                        else
                            data_buf2(0)(31 downto 16) <= (data_stored or BITOUT_i);
                            data_buf2(0)(15 downto 0)  <= x"00" & c_k28_0;
                        end if;
                        SM_DATA_IN <= STATE_DATA2;
                    end if;    
                
                -- Capture the POSOUT1                                    
                when STATE_DATA2 => 
                    input_done <= '0';                
                    if buf = '0' then 
                        data_buf1(1) <= POSOUT1_i;
                    else
                        data_buf2(1) <= POSOUT1_i;
                    end if;
                    SM_DATA_IN <= STATE_DATA3;         
                
                -- Capture the BITIN second tiem             
                when STATE_DATA3 => 
                    input_done <= '0';                
                    if buf = '0' then
                        data_buf1(2)(31 downto 16) <= (data_stored or BITOUT_i);
                        data_buf1(2)(15 downto 0)  <= x"0000";
                    else
                        data_buf2(2)(31 downto 16) <= (data_stored or BITOUT_i);
                        data_buf2(2)(15 downto 0)  <= x"0000";
                    end if;        
                    SM_DATA_IN <= STATE_DATA4;
                
                -- Capture the POSOUT2
                when STATE_DATA4 =>
                    input_done <= '0';                
                    if buf = '0' then
                        data_buf1(3) <= POSOUT2_i;
                    else
                        data_buf2(3) <= POSOUT2_i;
                    end if;        
                    SM_DATA_IN <= STATE_DATA5;
                
                -- Capture the BITIN third time
                when STATE_DATA5 =>
                    input_done <= '0';                
                    if buf = '0' then
                        data_buf1(4)(31 downto 16) <= (data_stored or BITOUT_i);
                        data_buf1(4)(15 downto 0)  <= x"0000";
                    else
                        data_buf2(4)(31 downto 16) <= (data_stored or BITOUT_i);
                        data_buf2(4)(15 downto 0)  <= x"0000";
                    end if;          
                    SM_DATA_IN <= STATE_DATA6;
                
                -- Capture the POSOUT3 
                when STATE_DATA6 => 
                    input_done <= '1';
                    if buf = '0' then
                        data_buf1(5) <= POSOUT3_i;
                    else
                        data_buf2(5) <= POSOUT3_i;
                    end if;        
                    SM_DATA_IN <= STATE_DATA7;
                
                -- Capture the BITIN fourth time
                when STATE_DATA7 => 
                    input_done <= '1';
                    if buf = '0' then
                        data_buf1(6)(31 downto 16) <= (data_stored or BITOUT_i);
                        data_buf1(6)(15 downto 0)  <= x"00" & c_k28_5;
                    else
                        data_buf2(6)(31 downto 16) <= (data_stored or BITOUT_i);
                        data_buf2(6)(15 downto 0)  <= x"00" & c_k28_5;
                    end if;         
                    SM_DATA_IN <= STATE_DATA8;
                
                -- Capture the POSOUT4
                when STATE_DATA8 => 
                    input_done <= '1';                    
                    -- Select other buffers
                    if buf = '0' then
                        buf <= '1';
                        data_buf1(7) <= POSOUT4_i;
                    else
                        buf <= '0';
                        data_buf2(7) <= POSOUT4_i;
                    end if;        
                    SM_DATA_IN <= STATE_DATA1;
                    
                when others => 
                    buf <= '0';
                    input_done <= '0';
                    SM_DATA_IN <= STATE_DATA1;
            
            end case;
        else
            buf <= '0';
            input_done <= '0';
            data_stored <= (others => '0');
            SM_DATA_IN <= STATE_DATA1;
        end if;
    end if;
end process ps_data_in;        



ps_data_out: process(txoutclk_i)
begin
    if rising_edge(txoutclk_i) then
        rx_link_ok2_meta1 <= rx_link_ok_i;
        rx_link_ok2_meta2 <= rx_link_ok2_meta1;
        -- Input data ready
        input_done_meta1 <= input_done;
        input_done_meta2 <= input_done_meta1;
        
        -- PKT sync not required      
        if rx_link_ok2_meta2 = '1' then
            case SM_DATA is
            
                -- 16 bits plus the k character or just zeros
                when STATE_BITIN1 =>
                    -- Packet start bit
                    if input_done_meta2 = '1' then
                        output_ready <= '0';            
                        txcharisk_o <= c_kchar;
                        if buf_to_use = '0' then
                            txdata_o <= data_buf1(0);
                        else
                            txdata_o <= data_buf2(0);
                        end if;    
                        SM_DATA <= STATE_POSIN1;
                    end if;
                        
                -- POSOUT1
                when STATE_POSIN1 => 
                    output_ready <= '0';
                    txcharisk_o <= (others => '0');
                    if buf_to_use = '0' then
                        txdata_o <= data_buf1(1); 
                    else
                        txdata_o <= data_buf2(1);
                    end if;        
                    SM_DATA <= STATE_BITIN2;

                -- BITIN2     
                when STATE_BITIN2 => 
                    output_ready <= '0';
                    txcharisk_o <= (others => '0');
                    if buf_to_use = '0' then
                        txdata_o <= data_buf1(2);
                    else
                        txdata_o <= data_buf2(2);
                    end if;            
                    SM_DATA <= STATE_POSIN2;

                -- POSOUT2    
                when STATE_POSIN2 => 
                    output_ready <= '0';
                    txcharisk_o <= (others => '0');
                    if buf_to_use = '0' then 
                        txdata_o <= data_buf1(3);
                    else
                        txdata_o <= data_buf2(3);
                    end if;        
                    SM_DATA <= STATE_BITIN3;

                -- BITIN3
                when STATE_BITIN3 =>
                    output_ready <= '0';
                    txcharisk_o <= (others => '0');
                    if buf_to_use = '0' then
                        txdata_o <= data_buf1(4);
                    else
                        txdata_o <= data_buf2(4);
                    end if;
                    SM_DATA <= STATE_POSIN3;
                
                -- POSOUT3    
                when STATE_POSIN3 => 
                    output_ready <= '1';
                    txcharisk_o <= (others => '0');
                    if buf_to_use = '0' then
                        txdata_o <= data_buf1(5);
                    else
                        txdata_o <= data_buf2(5);
                    end if;    
                    SM_DATA <= STATE_BITIN4;
                 
                -- BITIN4 and k character data alignment                                
                when STATE_BITIN4 =>      
                    -- Data synch k character
                    output_ready <= '1';
                    txcharisk_o <= c_kchar;
                    if buf_to_use = '0' then
                        txdata_o <= data_buf1(6);
                    else
                        txdata_o <= data_buf2(6);
                    end if;        
                    SM_DATA <= STATE_POSIN4;                
                    
                -- POSOUT4          
                when STATE_POSIN4 => 
                    output_ready <= '1';
                    txcharisk_o <= (others => '0');
                    if buf_to_use = '0' then
                        buf_to_use <= '1';    
                        txdata_o <= data_buf1(7);
                    else
                        buf_to_use <= '0';
                        txdata_o <= data_buf2(7);
                    end if;       
                    SM_DATA <= STATE_BITIN1;
        
                -- Others         
                when others => 
                    buf_to_use <= '0';
                    output_ready <= '1';
                    SM_DATA <= STATE_BITIN1;
            end case;                             
        else
            buf_to_use <= '0';
            output_ready <= '1';
            SM_DATA <= STATE_BITIN1;
        end if;      
    end if;
end process ps_data_out;    
        

end rtl;
