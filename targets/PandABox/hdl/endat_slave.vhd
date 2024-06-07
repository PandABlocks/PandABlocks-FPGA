library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;


entity endat_slave is

generic (g_endat2_1     : integer := 0); 

port ( 
    -- Global system and reset interface.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Configuration interface.
    BITS                : in  std_logic_vector(7 downto 0);
    link_up_o           : out std_logic;
    enable_i            : in  std_logic;
    GENERATOR_ERROR     : in  std_logic;
    health_o            : out std_logic_vector(31 downto 0);
    -- Block Input and Outputs.
    posn_i              : in  std_logic_vector(31 downto 0);
    endat_sck_i         : in  std_logic;
    endat_dat_o         : out std_logic
   );     
   
end entity;


architecture rtl of endat_slave is   


signal MODE_COMMAND          : std_logic_vector(9 downto 0) := "0000011100";

constant c_data_size         : unsigned(5 downto 0) := to_unsigned(32,6);   

type t_SM_DATA is (STATE_MODE_START, STATE_CAL_POS, STATE_START, STATE_ERR1, STATE_ERR2, STATE_DATA, STATE_CRC, STATE_OUTPUT_HIGH, STATE_OUTPUT_LOW);

-- 10 to 30us to 1.25 to 3.75us (fc > 1 MHz)    
constant c_tm_cnt               : unsigned(9 downto 0) := to_unsigned(128,10);     
-- Max 500 ns
constant c_tr_cnt               : unsigned(9 downto 0) := to_unsigned(20,10);
-- Mode command plus four bits
constant c_mc_plus_four         : unsigned(4 downto 0) := to_unsigned(10,5);
-- CRC bit number
constant c_crc_value            : unsigned(2 downto 0) := to_unsigned(5,3); 

signal SM_DATA                  : t_SM_DATA;
signal reset                    : std_logic;
signal link_up                  : std_logic;
signal crc_reset                : std_logic;     
signal endat_dat                : std_logic;
signal crc_enable               : std_logic;
signal crc_enabled              : std_logic;
signal endat_sck_dly            : std_logic;
signal endat_sck_rising_edge    : std_logic;
signal endat_sck_falling_edge   : std_logic; 
signal endat_err                : std_logic;      
signal data_cnt                 : unsigned(5 downto 0); 
signal tcal_tm_cnt              : unsigned(9 downto 0);
signal crc_dat                  : std_logic_vector(4 downto 0);
signal health_endat             : std_logic_vector(31 downto 0);    


begin


health_o <= health_endat;


-- Alarm or F1 and F2
endat_err <= GENERATOR_ERROR;


-- EnDat serial data
endat_dat_o <= endat_dat;


-- Link up indicator
link_up_o <= link_up;


ps_prev: process(clk_i)
begin
    if rising_edge(clk_i) then
        endat_sck_dly <= endat_sck_i;   
    end if;
end process ps_prev;

    
-- Rising edge
endat_sck_rising_edge <= not endat_sck_dly and endat_sck_i; 

-- Falling edge 
endat_sck_falling_edge <= endat_sck_dly and not endat_sck_i;




--        |--------------------- Tcal Typical of ENDat 2.2 encoders < 5 us ----------------------|

-- '''''''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\

--        /'''''X'''''X            MODE COMMAD            X'''''X'''''\________________________    

-- ################################################################################################### --


--                                                                                                                   |------tm------|    
-- /''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''''''''''''''\_______

--  START F1 F2 Alarm  LSB  LSB+1  LSB+2 LSB+3 LSB+4 LSB+5 LSB+6 LSB+7 LSB+8 LSB+9 MSB   CRC1  CRC2  CRC3  CRC4  CRC5  
-- /'''''\___________/'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X''''''''''''''\_______



ps_state: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            crc_reset <= '0';  
            crc_enable <= '0';
            data_cnt <= (others => '0');    
            tcal_tm_cnt <= (others => '0'); 
            health_endat <= (others => '0');
        else
        
            case SM_DATA is 
            
                -- T2 (two clocks) + mode command (six clocks) + T2 (two clocks) = ten clocks
                -- Mode command is 6 bits
                when STATE_MODE_START =>
                    -- Enable slave
                    if (enable_i = '1') then
                        -- Falling edge
                        if (endat_sck_falling_edge = '1') then
                            link_up <= '1';
                            data_cnt <= data_cnt +1;
                            if data_cnt = c_mc_plus_four-1 then 
                                data_cnt <= (others => '0');
                                SM_DATA <= STATE_CAL_POS;
                            end if;
                        end if;
                    else
                        link_up <= '0';
                    end if;
                     
                -- tcal minus mode command time      
                when STATE_CAL_POS =>          
                    -- Falling edge            
                    if (endat_sck_falling_edge = '1') then
                        endat_dat <= '0';  
                        -- tcal Typical of EnDat 2.2 encoders <= 5us
                        SM_DATA <= STATE_START;
                    end if;
                    
                -- Start bits                
                when STATE_START => 
                    -- Rising edge
                    if (endat_sck_rising_edge = '1') then
                        endat_dat <= '1';
                        SM_DATA <= STATE_ERR1;
                    end if;    
                    
                -- Error bit 0
                when STATE_ERR1 => 
                    -- Rising edge
                    if (endat_sck_rising_edge = '1') then
                        endat_dat <= endat_err;
                        -- EnDat 2.2 two status bits
                        if g_endat2_1 = 0 then     
                            SM_DATA <= STATE_ERR2;
                        -- EnDat 2.1 one status bit
                        else 
                            SM_DATA <= STATE_DATA;
                        end if;
                    end if;    

                -- Error bit 1                    
                when STATE_ERR2 => 
                    -- Rising edge
                    if (endat_sck_rising_edge = '1') then
                        endat_dat <= endat_err;
                        SM_DATA <= STATE_DATA;
                    end if;
                    
                -- Send the positional data    
                when STATE_DATA =>                   
                    if (endat_sck_rising_edge = '1') then
                        crc_enable <= '1';
                        data_cnt <= data_cnt +1;
                        endat_dat <= posn_i(to_integer(data_cnt));
                        if data_cnt = c_data_size-1 then
                            data_cnt <= (others => '0');
                            SM_DATA <= STATE_CRC;
                        end if; 
                    end if;            
                    
                -- Send the calculated CRC (5 bits)
                when STATE_CRC =>
                    -- Rising edge
                    if (endat_sck_rising_edge = '1') then
                        crc_enable <= '0';
                        data_cnt <= data_cnt +1;
                        endat_dat <= crc_dat(to_integer(data_cnt)); 
                        -- 5 bits
                        if data_cnt = c_crc_value-1 then
                            data_cnt <= (others => '0');
                            SM_DATA <= STATE_OUTPUT_HIGH;
                        end if;
                    end if;
                    
                -- High for EnDat 2.1: 10 to 30 us, 
                -- High for EnDat 2.2: 10 to 30 us or 1.25 to 3.75us (fc > 1MHz)    
                when STATE_OUTPUT_HIGH =>
                    -- Rising edge                 
                    if (endat_sck_falling_edge = '1') then
                        endat_dat <= '1';
                    end if;
                    tcal_tm_cnt <= tcal_tm_cnt +1;           
                    -- tm counter reached
                    if tcal_tm_cnt = c_tm_cnt then
                        crc_reset <= '1';
                        tcal_tm_cnt <= (others => '0');
                        SM_DATA <= STATE_OUTPUT_LOW;
                    end if;
                    
                -- tR Max 500 ns
                when STATE_OUTPUT_LOW =>
                    crc_reset <= '0';
                    endat_dat <= '1';
                    tcal_tm_cnt <= tcal_tm_cnt +1;  -- not needed 
                    -- tR count    
                    if tcal_tm_cnt = c_tr_cnt then
                        endat_dat <= '0';
                        tcal_tm_cnt <= (others => '0');
                        SM_DATA <= STATE_MODE_START;
                    end if;
                                  
            end case;
        end if;
    end if;
end process ps_state;    




crc_enabled <= crc_enable and endat_sck_falling_edge;  


reset <= reset_i or crc_reset;

-- calculate the actual crc value
endat_crc_inst: entity work.endat_crc
port map(
    clk_i         => clk_i,
    reset_i       => reset,
    bitval_i      => endat_dat,
    bitstrb_i     => crc_enabled,
    crc_o         => crc_dat
);



end rtl;
