
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;


entity endat_master is

generic (g_endat2_1  : integer := 0);

port ( 
      clk_i          : in  std_logic;
      reset_i        : in  std_logic;
      BITS           : in  std_logic_vector(7 downto 0);
      link_up_o      : out std_logic;
      health_o       : out std_logic_vector(31 downto 0);
      CLK_PERIOD_i   : in  std_logic_vector(31 downto 0);
      FRAME_PERIOD_i : in  std_logic_vector(31 downto 0);
      endat_sck_o    : out std_logic;
      endat_dat_i    : in  std_logic;
      endat_dat_o    : out std_logic;   
      posn_o         : out std_logic_vector(31 downto 0);
      posn_valid_o   : out std_logic
     );               

end endat_master;


architecture rtl of endat_master is
 

constant c_tm_wait_cnt        : unsigned(10 downto 0) := to_unsigned(1500,11); 


type t_SM_DATA is (STATE_IDLE, STATE_T2_MC_T2, STATE_START, STATE_F1_ALARM, STATE_F2, 
                   STATE_POSIT_VAL, STATE_CRC, STATE_RECOVER, STATE_FINISHED); 


signal SM_DATA                : t_SM_DATA;  

signal uMC_BITS               : unsigned(4 downto 0);
signal uCRC_BITS              : unsigned(4 downto 0);  
signal uBITS                  : unsigned(7 downto 0);
signal uSTATUS                : unsigned(1 downto 0);     
signal DATA_BITS              : std_logic_vector(7 downto 0);     
signal MODE_COMMAND           : std_logic_vector(9 downto 0);    
signal crc_rst                : std_logic;  
signal crc_reset              : std_logic;  
signal cm_enable              : std_logic;    
signal pv_enable              : std_logic;
signal crc_enable             : std_logic;  
signal calc_enable            : std_logic;
signal enable_cnt             : std_logic;  
signal frame_pulse            : std_logic;
signal data_valid             : std_logic;
signal endat_sck              : std_logic;
signal endat_clk_reset        : std_logic;
signal reset_endat_clk        : std_logic;          
signal enable_rising          : std_logic;  
signal endat_sck_dly          : std_logic;  
signal endat_sck_falling_edge : std_logic;
signal endat_sck_rising_edge  : std_logic;  
signal err_data               : std_logic_vector(1 downto 0);  
signal data_cnt               : unsigned(5 downto 0);
signal crc_calc               : std_logic_vector(4 downto 0);  
signal wait_cnt               : unsigned(10 downto 0);  
signal data                   : std_logic_vector(31 downto 0); 
signal crc_valid              : std_logic;   
signal crc                    : std_logic_vector(4 downto 0);
signal crc_data_enable        : std_logic;  



begin
    

posn_valid_o <= data_valid;


MODE_COMMAND <= "0000011100";


-- 2MHz = .0000005 - 500ns;
endat_sck_o <= endat_sck;

  
uMC_BITS <= "01010";
uCRC_BITS <= "00101";
uBITS <= unsigned(BITS);
uSTATUS <= "11" when g_endat2_1 = 0 else "10"; 

DATA_BITS <= std_logic_vector(uMC_BITS + uSTATUS + uBITS + uCRC_BITS-1); --- must fix this 


ps_clk: process(clk_i)
begin
    if rising_edge(clk_i) then
        endat_sck_dly <= endat_sck;
    end if;
end process ps_clk;    
    
    
-- Rising edge signal
endat_sck_rising_edge <= not endat_sck_dly and endat_sck;     
    
    
-- Falling edge signal    
endat_sck_falling_edge <= endat_sck_dly and not endat_sck;


-- tm - EnDat 2.1: 10 to 30us
-- tm - EnDat 2.2: 10 to 30us or 1.25 to 3.75u (fc > 1 MHz) 

-- tR - Max 12ms

--                                                                                          |     tm     |  tR |         

--''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/'''''''''''''\______  Clock


--       S    F1    F2    LSB                           MSB   CRC   CRC   CRC   CRC   CRC                              -- EnDat 2.2
--_____/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/'''''''''''''\__/''   Data

--       S    AL    LSB                           MSB   CRC   CRC   CRC   CRC   CRC                                    -- EnDat 2.1
--_____/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/'''''''''''''\__/''         Data



ps_state: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            crc_rst <= '0';  
            cm_enable <= '0';
            pv_enable <= '0';
            crc_enable <= '0';
            enable_cnt <= '0';
            enable_rising <= '0';
            endat_clk_reset <= '1'; 
            err_data <= (others => '0');
            data_cnt <= (others => '0');      
            wait_cnt <= (others => '0');  
        else
                        
            case SM_DATA is
                
                when STATE_IDLE => 
                    crc_rst <= '1';
                    endat_clk_reset <= '0';
                    -- Wait for the start of the falling edge of the clock 
                    if endat_sck_falling_edge = '1' then
                        link_up_o <= '1'; 
                        crc_rst <= '0';
                        data_cnt <= data_cnt +1;
                        endat_dat_o <= MODE_COMMAND(to_integer(data_cnt));
                        SM_DATA <= STATE_T2_MC_T2;
                    else
                        link_up_o <= '0';    
                    end if;
                                    
                -- T2 + Mode Command + T2
                -- 2  +      6       + 2 = 10 bits       
                when STATE_T2_MC_T2 => 
                    -- Capture the data on the falling edge
                    if endat_sck_falling_edge = '1' then
                        enable_cnt <= '1';
                        cm_enable <= '1';
                        endat_dat_o <= MODE_COMMAND(to_integer(data_cnt));
                        data_cnt <= data_cnt +1;
                        -- Terminal value reached 10 
                        if data_cnt = uMC_BITS-1 then
                            cm_enable <= '0';
                            data_cnt <= (others => '0');
                            SM_DATA <= STATE_START;
                        end if;
                    end if;             
                
                -- Start bit active                    
                when STATE_START => 
                    -- Turn on the capturing of the transmitted data
                    if endat_sck_falling_edge = '1' and endat_dat_i = '1' then    
                        SM_DATA <= STATE_F1_ALARM;
                    end if;     
                    
                -- F1 - endat2.2 ALARM - endat2.1     
                when STATE_F1_ALARM => 
                    if endat_sck_falling_edge = '1' then    
                        err_data(0) <= endat_dat_i;                    
                        if g_endat2_1 = 0 then 
                            SM_DATA <= STATE_F2;
                        else    
                            pv_enable <= '1';
                            SM_DATA <= STATE_POSIT_VAL;
                        end if;
                    end if;
                
                -- F2 endat2.2
                when STATE_F2 => 
                    if endat_sck_falling_edge = '1' then    
                        pv_enable <= '1';
                        err_data(1) <= endat_dat_i;
                        SM_DATA <= STATE_POSIT_VAL;
                    end if;    
                    
                -- Position value    
                when STATE_POSIT_VAL => 
                    if endat_sck_falling_edge = '1' then         
                        data_cnt <= data_cnt +1;
                        if data_cnt = uBITS-1 then
                            pv_enable <= '0';
                            crc_enable <= '1';
                            data_cnt <= (others => '0');
                            SM_DATA <= STATE_CRC;
                        end if;
                    end if;   
                                      
                -- CRC                       
                when STATE_CRC =>                 
                    if endat_sck_rising_edge = '1' then
                        crc_data_enable <= '1'; 
                    end if;
                    if endat_sck_falling_edge = '1' then    
                        data_cnt <= data_cnt +1;
                        if data_cnt = uCRC_BITS-1 then
                            crc_enable <= '0';
                            data_cnt <= (others => '0');
                            SM_DATA <= STATE_RECOVER;
                        end if;
                    end if;
                    
                -- Recover tm                                 
                when STATE_RECOVER => 
                    enable_cnt <= '0';
                    if endat_sck = '1' then
                        crc_data_enable <= '0';
                    end if;
                    wait_cnt <= wait_cnt +1;
                    if wait_cnt = c_tm_wait_cnt then --- not needed 
                        SM_DATA <= STATE_FINISHED;
                    end if;
                        
                when STATE_FINISHED => 
                    if endat_sck_rising_edge = '1' then
                        enable_rising <= '1';
                    elsif endat_dat_i = '0' then
                        enable_rising <= '0';
                        SM_DATA <= STATE_IDLE;     
                    end if;          

            end case;
        end if;                                
    end if;                        
end process ps_state;                                                        
                            
                            
                            
ps_err: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i='1' then
            posn_o <= (others => '0');
            health_o <= (others => '0');
        else
            -- Check the crc value
            if crc_valid = '1' then
                if crc /= crc_calc then
                    health_o <= std_logic_vector(to_unsigned(1,32));
                end if;
            else    
                -- LSB sent first so need to swap the bits
                for i in data'range loop
                    posn_o(data'high-i) <= data(i); 
                end loop;
            end if;        
        end if;
    end if;
end process ps_err;
                                        
      
      
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => FRAME_PERIOD_i,
    pulse_o     => frame_pulse
    );      
                   
                   
                   
reset_endat_clk <= reset_i or endat_clk_reset;
                        

clock_train_inst : entity work.endat_clock_gen
generic map (
    DEAD_PERIOD     => (20000/8)   
            )
port map (
    clk_i           => clk_i,
    reset_i         => reset_endat_clk,
    N               => DATA_BITS,
    CLK_PERIOD      => CLK_PERIOD_i,
    start_i         => frame_pulse,
    enable_cnt_i    => enable_cnt,
    clock_pulse_o   => endat_sck,
    active_o        => open,
    busy_o          => open
    );



--calc_enable <= (cm_enable or pv_enable) and endat_sck_rising_edge;
calc_enable <= pv_enable and endat_sck_falling_edge;    

crc_reset <= reset_i or crc_rst;

-- calculate the actual crc value
endat_crc_inst: entity work.endat_crc
port map(
    clk_i         => clk_i,
    reset_i       => crc_reset,
    bitval_i      => endat_dat_i,
    bitstrb_i     => calc_enable,
    crc_o         => crc_calc
    );


-- Capture the data value
shifter_data_in_inst : entity work.shifter_in
generic map (
     DW              => (data'length)            
            )
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enable_i        => pv_enable,
    clock_i         => endat_sck_falling_edge,
    data_i          => endat_dat_i,
    data_o          => data,
    data_valid_o    => data_valid
    );


-- Capture the crc value
shifter_CRC_in_inst : entity work.shifter_in
generic map (
    DW              => (crc'length)
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enable_i        => crc_data_enable,
    clock_i         => endat_sck_falling_edge,
    data_i          => endat_dat_i,
    data_o          => crc,
    data_valid_o    => crc_valid
);




    
end rtl;    
