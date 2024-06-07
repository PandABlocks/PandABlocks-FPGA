library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity endat_sniffer_tb is
end endat_sniffer_tb;


architecture rtl of endat_sniffer_tb is


constant c_wait_cnt  : unsigned(10 downto 0) := to_unsigned(2047,11);


constant c_term_tcal : unsigned(10 downto 0) := to_unsigned(4,11);     


constant c_term_tm   : unsigned(11 downto 0) := to_unsigned(3750,12);   


constant c_term_tr   : unsigned(10 downto 0) := to_unsigned(61,11);   

 
constant c_2mc2      : unsigned(9 downto 0) := "0000011100";   


constant c_term_data : unsigned(5 downto 0) := to_unsigned(23,6);


constant c_term_crc  : unsigned(5 downto 0) := to_unsigned(5,6);   


constant c_endat2_1  : natural := 1;


type t_SM_ENDAT is (STATE_IDLE, STATE_TWO_MC_TWO, STATE_WAIT, STATE_START, STATE_ERR, STATE_DATA, STATE_CRC, STATE_CRC_DUMMY, STATE_TM, STATE_TR);



type t_pwm_mask is array(7 downto 0) of std_logic_vector(7 downto 0);

constant c_pwm_mask : t_pwm_mask := ("11111100", "11111110", "11111110", "11111110", "11111110", "11111110", "11111110", "11111111");


signal SM_ENDAT      : t_SM_ENDAT;   
signal clk           : std_logic := '0';
signal reset         : std_logic;
signal BITS          : std_logic_vector(7 downto 0);
signal link_up       : std_logic;
signal health        : std_logic_vector(31 downto 0);
signal err           : std_logic;
signal endat_ck      : std_logic := '0';
signal endat_sck     : std_logic := '0';
signal endat_sck_dly : std_logic;   
signal endat_dat     : std_logic := '0';
signal posn          : std_logic_vector(31 downto 0);
signal endat_re      : std_logic;
signal endat_fe      : std_logic;
signal data          : unsigned(to_integer(c_term_data-1) downto 0);         
signal crc_valid     : std_logic;   
signal endat_err     : std_logic_vector(1 downto 0) := "10";   
signal wait_cnt      : unsigned(11 downto 0) := (others => '0');   
signal data_cnt      : unsigned(5 downto 0) := (others => '0');   
signal crc_reset     : std_logic;
signal crc_bitstrb   : std_logic;      
signal crc_enabled   : std_logic;
signal crc_calc      : std_logic_vector(4 downto 0);   
signal data_check    : std_logic_vector(to_integer(c_term_data-1) downto 0);   
signal data_err      : std_logic;   
signal data_enable   : std_logic;  
signal now           : std_logic := '0'; 

signal enable        : std_logic := '1';
signal pwm_fb_tr     : std_logic := '0';
signal pwm_cnt       : unsigned(2 downto 0) := (others => '0');
signal uns_pwm_cnt   : unsigned(2 downto 0) := (others => '0');
signal cnt           : unsigned(7 downto 0) := (others => '0'); 
signal pwm_mask      : std_logic_vector(7 downto 0) := (others => '0');



type t_SM_TEST_ENDAT is (STATE_RESET, STATE_START, STATE_ERR, STATE_DATA, STATE_CHECK_DATA);

signal Sm_TEST_ENDAT : t_Sm_TEST_ENDAT;   
signal crc_rst       : std_logic;   
signal crc_dat       : std_logic;
signal crc_strb      : std_logic;
signal crc_val       : std_logic_vector(4 downto 0);
signal test_cnt      : integer := 0;
signal test_data     : std_logic_vector(22 downto 0);   


begin


clk <= not clk after 4ns;

endat_ck <= not endat_ck after 1us;



ps_rst: process
begin
    reset <= '1';
    wait for 256 ns;
    reset <= '0';
    wait;
end process ps_rst;



ps_re_fe: process(clk)
begin
    if rising_edge(clk) then
        endat_sck_dly <= endat_sck;
    end if;
end process ps_re_fe;    


-- 
endat_re <= not endat_sck_dly and endat_sck;

endat_fe <= endat_sck_dly and not endat_sck;
 

BITS <= std_logic_vector("00" & c_term_data);


-- 23 bits
-- MODE = 000111 --> EnDat 2.1 & 2.2 1 Error bit (2.1 and 2.2 command)   
-- MODE = 111000 --> EnDat 2.2       2 Error bits (2.2 command)   

-- tCAL Typical of EnDat 2.2 encoders < 5us
-- tm EnDat 2.1: 10 to 30 us
-- tm EnDat 2.2: 10 to 30 us or 1.25 to 3.75 us (fc > 1 MHz)


------------|                                tCAL                               |                                                                             |    tm   |       
-- '''''''''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\     __/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''\__/''''''''''

--            T2 1  T2 2   CM    CM    CM    CM    CM    CM   T2 3  T2 4        START    F1    F2   LSB  LSB+1 LSB+2 LSB+3  MSB   CRC   CRC   CRC   CRC   CRC               EnDat 2.2
--            T2 1  T2 2   CM    CM    CM    CM    CM    CM   T2 3  T2 4        START    F1   LSB  LSB+1 LSB+2 LSB+3 LSB+4  MSB   CRC   CRC   CRC   CRC   CRC               EnDat 2.1
--__________/'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''X'''''\       /'''''X_____X_____X_____X_____X_____X_____X_____X_____X_____X_____X_____X_____/''''''''''\

--                      DATA               CRC    SIM CRC
--data <= to_unsigned(2319479,23); -- crc 00110   00110     OK
data <= to_unsigned(2319450,23); -- crc 01000   11010
--data <= to_unsigned(2320025,23); -- crc 01010   10010
--data <= to_unsigned(2317715,23); -- crc 10101   11010   
--data <= to_unsigned(230806,23);  -- crc 01000   00100     OK
--data <= to_unsigned(2041629,23); -- crc 11110   00000       
--data <= to_unsigned(1980310,23); -- crc 10010   11001
--data <= to_unsigned(1224444,23); -- crc 01001   00110
--data <= to_unsigned(828527,23);  -- crc 10111   10111     OK
--data <= to_unsigned(503130,23);  -- crc 10101   10111
--data <= to_unsigned(252118,23);  -- crc 10010   11001  
--data <= to_unsigned(8264901,23); -- crc 01111   10000
--data <= to_unsigned(7853940,23); -- crc 01011   10110 


ps_test: process(clk)
begin
    if rising_edge(clk) then
        case SM_TEST_ENDAT is
        
            when STATE_RESET =>
                crc_rst <= '1';
                test_cnt <= test_cnt +1;
                test_data <= std_logic_vector(data);
                if test_cnt = 32 then
                    test_cnt <= 0;
                    crc_rst <= '0';
--                    SM_TEST_ENDAT <= STATE_START;
--                    SM_TEST_ENDAT <= START_ERR;
                    SM_TEST_ENDAT <= STATE_DATA;
                end if;
                
            when STATE_START => 
                crc_dat <= '1'; -- START
                crc_strb <= '1';
                SM_TEST_ENDAT <= STATE_ERR;
                
            when STATE_ERR => 
                crc_dat <= '1'; -- ERROR
                crc_strb <= '1';
                SM_TEST_ENDAT <= STATE_DATA;            
            
            when STATE_DATA => 
                crc_strb <= '1';
                test_cnt <= test_cnt +1;
                if test_cnt < 23 then 
                    crc_dat <= test_data(test_cnt);
                end if;
                if test_cnt = 23 then
                    test_cnt <= 0;
                    crc_strb <= '0'; 
                    SM_TEST_ENDAT <= STATE_CHECK_DATA;
                end if;     
            
            when STATE_CHECK_DATA => 
            
           
        end case;
    end if;
end process ps_test;    


-- Calculate the crc value
test_test_crc_inst : entity work.endat_test_crc
    port map (
             clk_i           => clk,
             reset_i         => crc_rst,
             bitval_i        => crc_dat,
             bitstrb_i       => crc_strb,
             crc_o           => crc_val
             );



ps_endat: process(clk)
begin
    if rising_edge(clk) then
        
        case SM_ENDAT is
        
            when STATE_IDLE =>
                crc_reset <= '1';
                endat_sck <= '1';
                endat_dat <= '1'; ---------------------------------
                data_enable <= '0';
                -- wait cnt 
                wait_cnt <= wait_cnt +1;
                if wait_cnt = c_wait_cnt then
                    wait_cnt <= (others => '0');
                    SM_ENDAT <= STATE_TWO_MC_TWO;                    
                end if;
            
            -- 2T clocks + mode command + 2T clocks 
            when STATE_TWO_MC_TWO =>
                crc_reset <= '0';
                endat_sck <= endat_ck;
                if endat_fe = '1' then
                    data_cnt <= data_cnt +1;
                    endat_dat <= c_2mc2(to_integer(9-data_cnt));
                    if data_cnt = 9 then
                        data_cnt <= (others => '0');
                        SM_ENDAT <= STATE_WAIT;
                    end if;
                end if;        
            
            -- tcal            
            when STATE_WAIT => 
                endat_sck <= endat_ck;
                if endat_re = '1' then
                    wait_cnt <= wait_cnt +1;
                    if wait_cnt >= c_term_tcal then
-------                        crc_valid <= '1'; -----------------------------------------------------------------------------------------
                        endat_dat <= '1';
                        wait_cnt <= (others => '0');
                        SM_ENDAT <= STATE_START;
                    end if;
                end if;    
                   
            -- START        
            when STATE_START => 
                endat_sck <= endat_ck;
                if endat_re = '1' then
                    crc_valid <= '1'; ---------------------------------------------------------------------------------------------
                    endat_dat <= endat_err(1);
                    SM_ENDAT <= STATE_ERR;
                end if;
            
            -- Error        
            when STATE_ERR =>
                endat_sck <= endat_ck;
                -- EnDat 2.2 has 2 status bits F1 and F2 
                if endat_re = '1' and c_endat2_1 = 0 then
                    data_enable <= '1';    
--------------------------------------                    crc_valid <= '1'; -------------------------------------------------------
                    endat_dat <= endat_err(0);
                    if data_enable = '1' then  
                        crc_valid <= '1';
                        data_cnt <= data_cnt +1;
                        endat_dat <= data(to_integer(data_cnt));
                        -- DATA CHECK
                        data_check(to_integer(data_cnt)) <= data(to_integer(data_cnt));
                        -- DATA CHECK
                        SM_ENDAT <= STATE_DATA;
                    end if;
                elsif endat_re = '1' and c_endat2_1 = 1 then
                    crc_valid <= '1';
                    data_cnt <= data_cnt +1;
                    endat_dat <= data(to_integer(data_cnt));
                    -- DATA CHECK
                    data_check(to_integer(data_cnt)) <= data(to_integer(data_cnt));
                    -- DATA CHECK
                    SM_ENDAT <= STATE_DATA;
                end if;
                
            -- Data     
            when STATE_DATA =>
                endat_sck <= endat_ck;
                if endat_re = '1' then
                    data_cnt <= data_cnt +1;
                    endat_dat <= data(to_integer(data_cnt));
                    -- DATA CHECK
                    data_check(to_integer(data_cnt)) <= data(to_integer(data_cnt));
                    -- DATA CHECK
                    if data_cnt = c_term_data-1 then
------------------------                        crc_valid <= '0';
                        endat_dat <= data(data'high);
                        -- DATA CHECK
                        data_check(to_integer(data_cnt)) <= data(to_integer(data_cnt));
                        -- DATA CHECK
                        data_cnt <= (others => '0');
                        SM_ENDAT <= STATE_CRC;
                    end if;
                end if;     
                        
            -- CRC             
            when STATE_CRC => 
                endat_sck <= endat_ck;
                if endat_re = '1' then
                    crc_valid <= '0';
                    crc_enabled <= '1';
                    data_cnt <= data_cnt +1;
                    endat_dat <= crc_calc(to_integer(4-data_cnt));    
                    if data_cnt = c_term_crc-1 then                     
                        endat_dat <= crc_calc(to_integer(4-data_cnt)); 
                        data_cnt <= (others => '0');
                        SM_ENDAT <= STATE_CRC_DUMMY;
                    end if;
                end if;
                  
            when STATE_CRC_DUMMY => 
                endat_sck <= endat_ck;
                if endat_re = '1' then
                    crc_enabled <= '0';
                    SM_ENDAT <= STATE_TM;
                end if;  
                  
            -- Recovery time (tm)             
            when STATE_TM => 
                crc_reset <= '1';
                endat_sck <= '1';
                endat_dat <= '1';
                wait_cnt <= wait_cnt +1;
                if wait_cnt = c_term_tm then
                    endat_dat <= '0';
                    wait_cnt <= (others => '0');
                    SM_ENDAT <= STATE_TR;
                end if;
               
            -- Recovery time (tR)   
            when STATE_TR => 
                endat_sck <= '1';
                endat_dat <= '0';
                wait_cnt <= wait_cnt +1;
                if wait_cnt = c_term_tr -1 then
                    -- Check the data sent with the data received
                    if data /= unsigned(posn) then
                        data_err <= '1';
                    else 
                        data_err  <= '0';
                    end if; 
                end if;
                if wait_cnt = c_term_tr then
                    endat_sck <= '1';
                    endat_dat <= '1';
                    -- Increment the data sent
--------------------                    data <= data +1;
                    wait_cnt <= (others => '0');
                    SM_ENDAT <= STATE_IDLE;
                end if;                                                
 
        end case;                           
    end if;                       
end process ps_endat;                       
    


-- Error generated in the EnDat sniffer 
ps_err: process(clk)    
begin
    if rising_edge(clk) then
        if err = '1' then
            report "ERROR " severity error;
        end if;        
    end if;
end process ps_err;   
   
   
   
crc_bitstrb <= '1' when crc_valid = '1' and endat_fe = '1' else '0';    
    
-- Calculate the crc value
endat_crc_inst : entity work.endat_crc
    port map (
             clk_i           => clk,
             reset_i         => crc_reset,
             bitval_i        => endat_dat,
             bitstrb_i       => crc_bitstrb,
             crc_o           => crc_calc
             );

    

endat_sniffer_inst: entity work.endat_sniffer
    generic map (g_endat2_1 => c_endat2_1)
    port map (
             clk_i       => clk,
             reset_i     => reset,
             -- Configuration interface
             BITS        => BITS,
             link_up_o   => link_up,
             health_o    => health,
             error_o     => err,
             -- Physical EnDat interface
             endat_sck_i => endat_sck,
             endat_dat_i => endat_dat,
             -- Block outputs
             posn_o      => posn
             );


process(clk)
    variable v_pwm_cnt : unsigned(2 downto 0) := (others => '0');
begin
    if rising_edge(clk) then
        if enable = '1' then
            if cnt = 7 then
                cnt <= (others => '0');
            else
                cnt <= cnt +1;
            end if;
        end if;
        pwm_mask <= c_pwm_mask(to_integer(cnt));
        if enable = '1' then
            enable <= '0';
            -- pwm_mask'range = 6.   
            for I in pwm_mask'range loop    
                -- count the number of unmasked faulty feedback signals                                      
                if pwm_mask(i) = '0' then                                               
                    v_pwm_cnt := v_pwm_cnt +1;
                    pwm_cnt <= pwm_cnt +1;
                end if;
            end loop;
        else
            enable <= '1';
            v_pwm_cnt := (others => '0');
            -- trip if the number of failures is two or more.           
            if uns_pwm_cnt >= 2 then
                pwm_fb_tr <= '0';
            else
                pwm_fb_tr <= '1';
            end if;
        end if;       
        uns_pwm_cnt <= v_pwm_cnt;
    end if;
end process; 
  


end rtl;
