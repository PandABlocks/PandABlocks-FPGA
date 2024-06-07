library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;



entity endat_tb is
end entity;


architecture rtl of endat_tb is

--constant c_endat2_1      : integer := 1; 
constant c_endat2_1         : integer := 0; 


--constant c_BITS             : natural := 32;
constant c_BITS             : integer := 32;


type t_SM_MASTER is (STATE_IDLE, STATE_MC, STATE_START, STATE_F1_F2_ALARM, STATE_F2, 
                     STATE_POSITION_VAL, STATE_CRC, STATE_TM_RECOVER, STATE_TR_RECOVER);    


signal SM_MASTER            : t_SM_MASTER;    
signal clk_i                : std_logic := '0';
signal reset_i              : std_logic;
signal BITS_m               : std_logic_vector(7 downto 0);
signal link_up              : std_logic;
signal health_m             : std_logic_vector(31 downto 0);
signal CLK_PERIOD           : std_logic_vector(31 downto 0);
signal FRAME_PERIOD         : std_logic_vector(31 downto 0);
signal endat_dat_m          : std_logic; 
signal posn_m               : std_logic_vector(31 downto 0);
signal posn_m_valid         : std_logic;
signal posn_m_valid_dly     : std_logic;
signal BITS_s               : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(32,8));
signal enable               : std_logic;
signal GENERATOR_ERROR      : std_logic := '0';
signal health_s             : std_logic_vector(31 downto 0) := (others => '0');
signal posn_s               : std_logic_vector(31 downto 0);
signal endat_sck            : std_logic;
signal endat_dat_s          : std_logic; 
signal crc_rst              : std_logic;
signal crc_reset            : std_logic;
signal crc_enable           : std_logic;
signal crc_enabled          : std_logic;   
signal endat_dat_tb         : std_logic;   
signal endat_sck_dly        : std_logic;     
signal endat_sck_rising     : std_logic;
signal endat_sck_rising_dly : std_logic;
signal endat_sck_falling    : std_logic;
signal mc_data              : std_logic_vector(9 downto 0);   
signal data_cnt             : unsigned(5 downto 0) := (others => '0');     
signal tmtr_cnt             : unsigned(10 downto 0);
signal data                 : unsigned(31 downto 0) := x"12345678";   
signal crc_calc             : std_logic_vector(4 downto 0);   
signal datas_cnt            : unsigned(5 downto 0) := (others => '0');   
signal slave_data           : std_logic_vector(49 downto 0);        
signal enable_cnt           : std_logic;
signal strobe               : std_logic;
signal slave_start          : std_logic;
signal slave_alarm          : std_logic;
signal slave_f12            : std_logic_vector(1 downto 0);
signal slave_datapv         : std_logic_vector(31 downto 0);
signal slave_crc            : std_logic_vector(4 downto 0); 
signal posit_val            : unsigned(31 downto 0) := x"a5a5a5a5";
signal crc_reset_s          : std_logic;
signal crc_enabled_s        : std_logic;
signal crc_enable_s         : std_logic;
signal crc_calc_s           : std_logic_vector(4 downto 0); 
signal offset               : integer;


begin



clk_i <= not clk_i after 4 ns;


-- Reset 
ps_rst: process
begin
    enable <= '0';
    reset_i <= '1';
    wait for 256 ns;  
    enable <= '1';
    reset_i <= '0';
    wait;
end process ps_rst;


-- Delay version of the clock signal
ps_dly: process(clk_i) 
begin
    if rising_edge(clk_i) then
        endat_sck_dly <= endat_sck;
    end if;
end process ps_dly;    


--############################################### EnDat Master ############################################### --

-- Kick off the master
FRAME_PERIOD <= std_logic_vector(to_unsigned(10240,32));

-- Clock period
CLK_PERIOD <= std_logic_vector(to_unsigned(64,32));

-- Master BITS 
BITS_m <= std_logic_vector(to_unsigned(c_BITS,8));

-- Rising edge of the clock indicator  
endat_sck_rising <= not endat_sck_dly and endat_sck;

-- 
endat_sck_falling <= endat_sck_dly and not endat_sck;


ps_master: process(clk_i)
begin
    if rising_edge(clk_i) then
        endat_sck_dly <= endat_sck;
        endat_sck_rising_dly <= endat_sck_rising; 
        case SM_MASTER is
        
            when STATE_IDLE => 
                crc_rst <= '1';
                crc_enabled <= '0';
                data_cnt <= (others => '0');
                tmtr_cnt <= (others => '0');
                if endat_sck_rising = '1' then
                    data <= data +1;
                    SM_MASTER <= STATE_MC;
                end if;    
            
            when STATE_MC => 
                crc_rst <= '0';
                -- Falling edge for the mode commands
                if endat_sck_falling = '1' then                         
                    data_cnt <= data_cnt +1;
                    mc_data(to_integer(data_cnt)) <= endat_dat_m;
                    -- Data count 0 to 9 = 10
                    -- 0 and 1 - zeros (T2)
                    -- 2 to 7  - Mode command 
                    -- 8 to 9  - zeros (T2)
                    if data_cnt = 9 then
                        data_cnt <= (others => '0');
                        SM_MASTER <= STATE_START;
                    end if;
                end if;             
            
            -- Start active high
            when STATE_START => 
                if endat_sck_rising = '1' then
                    endat_dat_tb <= '1';
                    SM_MASTER <= STATE_F1_F2_ALARM;
                end if;
                
            -- EnDat2.1 - ALARM
            -- ENDat2.2 - F1    
            when STATE_F1_F2_ALARM =>
                if endat_sck_rising = '1' then
                    endat_dat_tb <= '0';        
                    -- EnDat2.2 enabled
                    if c_endat2_1 = 0 then
                        SM_MASTER <= STATE_F2;
                    -- EnDat2.1
                    else
                        SM_MASTER <= STATE_POSITION_VAL;
                    end if;
                end if;            
            
            -- EnDat2.2 - F2
            when STATE_F2 => 
                if endat_sck_rising = '1' then
                    endat_dat_tb <= '0';
                    SM_MASTER <= STATE_POSITION_VAL;
                end if;    
            
            --Position Value
            when STATE_POSITION_VAL => 
                if endat_sck_rising = '1' then
                    crc_enabled <= '1';
                    data_cnt <= data_cnt +1;
                    endat_dat_tb <= data(to_integer(data_cnt));
                    if data_cnt = c_BITS-1 then    
                        data_cnt <= (others => '0');
                        SM_MASTER <= STATE_CRC;
                    end if;
                end if;         
            
            -- CRC only five bits
            when STATE_CRC => 
                if endat_sck_falling = '1' then
                    crc_enabled <= '0';
                end if;
                if endat_sck_rising = '1' then 
                    data_cnt <= data_cnt +1;
                    endat_dat_tb <= crc_calc(to_integer(4-data_cnt));
                    if data_cnt = 4 then
                        SM_MASTER <= STATE_TM_RECOVER;
                    end if;
                end if;
            
            -- TM recover time
            when STATE_TM_RECOVER =>
                    if endat_sck_falling = '1' then
                        endat_dat_tb <= '1';
                    end if;
                    tmtr_cnt <= tmtr_cnt +1; 
                    if tmtr_cnt = 1500 then
                        data_cnt <= (others => '0'); 
                        tmtr_cnt <= (others => '0');
                        SM_MASTER <= STATE_TR_RECOVER;
                    end if;
           
            -- TR recover time 
            when STATE_TR_RECOVER => 
                endat_dat_tb <= '0';
                tmtr_cnt <= tmtr_cnt +1;
                if tmtr_cnt = 25 then
                    tmtr_cnt <= (others => '0');
                    SM_MASTER <= STATE_IDLE;
                end if;                          
                            
        end case;             
    end if;
end process ps_master;



ps_check_mdata: process(clk_i)
begin
    if rising_edge(clk_i) then
        posn_m_valid_dly <= posn_m_valid;
        if posn_m_valid_dly = '1' then
            -- Check received data with expect data
            if unsigned(posn_m) /= data then
                report "Master data miss match" severity error; 
            end if; 
        end if;        
        -- Check the crc sent and calculated
        if health_m /= x"00000000" and reset_i = '0' then
            report "Master CRC dont match" severity error;
        end if;      
    end if;
end process ps_check_mdata;    

     
     
crc_reset <= reset_i or crc_rst;     

crc_enable <= endat_sck_rising_dly and crc_enabled; 

-- calculate the actual crc value
endat_m_crc_inst: entity work.endat_crc
    port map (
              clk_i         => clk_i,
              reset_i       => crc_reset,
              bitval_i      => endat_dat_tb,
              bitstrb_i     => crc_enable,
              crc_o         => crc_calc
             );

         
-- Master generates the clocks and mode command 
endat_master_inst: entity work.endat_master

    generic map (g_endat2_1 => c_endat2_1)

    port map ( 
              clk_i           => clk_i,
              reset_i         => reset_i,
              BITS            => BITS_m,
              link_up_o       => link_up,
              health_o        => health_m,
              CLK_PERIOD_i    => CLK_PERIOD,
              FRAME_PERIOD_i  => FRAME_PERIOD,
              endat_sck_o     => endat_sck,
              endat_dat_i     => endat_dat_tb,
              endat_dat_o     => endat_dat_m,
              posn_o          => posn_m,
              posn_valid_o    => posn_m_valid
             );  

--############################################### EnDat Slave ############################################### --


-- Slave BITS
BITS_s <= std_logic_vector(to_unsigned(C_BITS,8));

GENERATOR_ERROR <= '0';


offset <= 32 - c_BITS;


ps_slave: process(clk_i)
begin
    if rising_edge(clk_i) then
        --Pos Bus
        posn_s <= std_logic_vector(posit_val);
        if endat_sck_falling = '1' then
            enable_cnt <= '1'; 
            if enable_cnt = '1' then
                datas_cnt <= datas_cnt +1;  
                if datas_cnt >= 10 then   
                    slave_data(to_integer(datas_cnt-10)) <= endat_dat_s;            
                end if;
            end if;
        elsif tmtr_cnt = 34 then
            strobe <= '1'; 
            posit_val <= posit_val +1;
            enable_cnt <= '0'; 
            datas_cnt <= (others => '0');
            slave_start <= slave_data(0);
            if c_endat2_1 = 1 then 
                slave_alarm <= slave_data(1);
                slave_datapv(31-offset downto 0) <= slave_data(33-offset downto 2);
                slave_crc <= slave_data(38-offset downto 34-offset); 
                slave_f12 <= (others => '0');
            else  
                slave_f12 <= slave_data(2 downto 1);
                slave_datapv(31-offset downto 0) <= slave_data(34-offset downto 3);
                slave_crc <= slave_data(39-offset downto 35-offset);
                slave_alarm <= '0'; 
            end if;
        else
            strobe <= '0';
        end if;
        if datas_cnt >= 12 and datas_cnt <= 43-offset and c_endat2_1 = 1 then
            crc_enable_s <= '1';
        elsif datas_cnt >= 13 and datas_cnt <= 44-offset and c_endat2_1 = 0 then  
            crc_enable_s <= '1'; 
        else 
            crc_enable_s <= '0';    
        end if; 
    end if;
end process ps_slave;    



ps_check_sdata: process(clk_i)
begin
    if rising_edge(clk_i) then 
        if strobe = '1' then
            if posn_s /= slave_datapv then
                report "Slave data error" severity error;
            end if;
            if slave_crc /= crc_calc_s then
                report "Slave CRC error" severity error;
            end if;    
        end if;                
    end if;
end process ps_check_sdata;



crc_reset_s <= reset_i or strobe;


crc_enabled_s <= endat_sck_falling and crc_enable_s; 


-- calculate the actual crc value
endat_s_crc_inst: entity work.endat_crc
    port map (
              clk_i         => clk_i,
              reset_i       => crc_reset_s,
              bitval_i      => endat_dat_s,
              bitstrb_i     => crc_enabled_s,
              crc_o         => crc_calc_s
             );


-- Slave responsed with the start, alarm or f1 and f2, data and crc 
endat_slave_inst: entity work.endat_slave

    generic map (g_endat2_1 => c_endat2_1)    
    
    port map ( 
              clk_i           => clk_i,
              reset_i         => reset_i,
              BITS            => BITS_s,
              enable_i        => enable,
              GENERATOR_ERROR => GENERATOR_ERROR,
              health_o        => health_s,
              posn_i          => posn_s,
              endat_sck_i     => endat_sck,
              endat_dat_o     => endat_dat_s
             );     


end rtl;
