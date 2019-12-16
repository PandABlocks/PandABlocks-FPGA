library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.addr_defines.all;

entity inenc_top_tb is
    generic( bits0 : integer := 31;
             bits1 : integer := 9;
             bits2 : integer := 15;
             bits3 : integer := 7);
end inenc_top_tb;


architecture rtl of inenc_top_tb is


constant c_num_addr      : positive := 16;                                                                               -- Add register increase count value

type t_data_array is array(0 to c_num_addr-1) of natural;
type t_addr_array is array(0 to c_num_addr-1) of natural;
type t_bit_bus_clk is array(0 to ENC_NUM-1) of natural;
type t_data_length is array(0 to ENC_NUM-1) of natural;
type t_test_data is array(ENC_NUM-1 downto 0) of std_logic_vector(31 downto 0);
type t_enc is array(ENC_NUM-1 downto 0) of natural;
type t_bits_slv is array(ENC_NUM-1 downto 0) of std_logic_vector(7 downto 0);

type t_rand is array(ENC_NUM-1 downto 0) of real;
type t_seed is array(ENC_NUM-1 downto 0) of positive;
type t_int_rand is array(ENC_NUM-1 downto 0) of integer;


-- ################################################################################################### --
-- Data Size
signal enc_bits          : t_enc := (bits0,bits1,bits2,bits3);
-- Test DATA
constant c_test_data     : t_test_data   := (x"18181818", x"AAAAAAAA", x"A5A5A5A5", x"55555555"); 
-- ################################################################################################### --

constant c_protocol      : natural := 2;

constant c_pass          : natural := 1;

-- Address 4,68,132,196 - BITS  
-- Address 0,64,128,192 - PROTOCOL
-- Address 9,73,137,201 - CLK
-- Address 1,65,129,193 - BYPASS
constant c_BiSS_data_array  : t_data_array  := (enc_bits(0),c_protocol,25,c_pass,
                                                enc_bits(1),c_protocol,26,c_pass,
                                                enc_bits(2),c_protocol,27,c_pass,
                                                enc_bits(3),c_protocol,28,c_pass);                                   -- Add data here 
                                                               
constant c_BiSS_addr_array  : t_addr_array  := (INENC_BITS,     INENC_PROTOCOL,     INENC_CLK,     INENC_BYPASS,               
                                                INENC_BITS+64,  INENC_PROTOCOL+64,  INENC_CLK+64,  INENC_BYPASS+64, 
                                                INENC_BITS+128, INENC_PROTOCOL+128, INENC_CLK+128, INENC_BYPASS+128, 
                                                INENC_BITS+192, INENC_PROTOCOL+192, INENC_CLK+192, INENC_BYPASS+192);  -- Add address here

-- bit_bus clocks programmed (Addr-9,Data-25|Addr-73,Data-26|Addr-137,Data-27|Addr-201,Data-28)
constant c_bit_bus_clk  : t_bit_bus_clk  := (25,26,27,28);  

type t_SM_WR is (STATE_READY, STATE_BiSS_WR_DATA);

signal SM_WR              : t_SM_WR;
signal test_data          : t_test_data := c_test_data; 
signal data_result        : t_test_data; 
signal bits_slv           : t_bits_slv; 
signal biss_clk           : std_logic:='1';     
signal clk_i              : std_logic:='0';
signal reset_i            : std_logic;
signal read_strobe_i      : std_logic;
signal read_address_i     : std_logic_vector(PAGE_AW-1 downto 0);
signal read_data_o        : std_logic_vector(31 downto 0);
signal read_ack_o         : std_logic;

signal write_strobe_i     : std_logic;
signal write_address_i    : std_logic_vector(PAGE_AW-1 downto 0);
signal write_data_i       : std_logic_vector(31 downto 0);
signal write_ack_o        : std_logic;

signal A_IN               : std_logic_vector(ENC_NUM-1 downto 0);
signal B_IN               : std_logic_vector(ENC_NUM-1 downto 0);
signal Z_IN               : std_logic_vector(ENC_NUM-1 downto 0);
signal CLK_OUT            : std_logic_vector(ENC_NUM-1 downto 0);
signal DATA_IN            : std_logic_vector(ENC_NUM-1 downto 0);
signal CLK_IN             : std_logic_vector(ENC_NUM-1 downto 0);
signal CONN_OUT           : std_logic_vector(ENC_NUM-1 downto 0);

signal a_int_o            : std_logic_vector(ENC_NUM-1 downto 0);
signal b_int_o            : std_logic_vector(ENC_NUM-1 downto 0);
signal z_int_o            : std_logic_vector(ENC_NUM-1 downto 0);
signal data_int_o         : std_logic_vector(ENC_NUM-1 downto 0);

signal bit_bus_i          : bit_bus_t;
signal pos_bus_i          : pos_bus_t;
signal DCARD_MODE         : std32_array(ENC_NUM-1 downto 0);
signal PROTOCOL           : std3_array(ENC_NUM-1 downto 0);
signal posn_o             : std32_array(ENC_NUM-1 downto 0);

signal index              : natural := 0;

signal test_result        : std_logic;
signal test_result_prev   : std_logic;
signal test_result_strobe : std_logic;
signal data_match         : std_logic_vector(ENC_NUM-1 downto 0);  
signal clk_o              : std_logic_vector(ENC_NUM-1 downto 0); 


begin



-- Main clock 125MHz
clk_i <= not clk_i after 4 ns;

--biss_clk <= not biss_clk after 7000 ns;

-- Need to start the block up using this clock schedule otherwise
-- linkup in the inenc_top_inst\INENC_GEN(0-3)\inenc_block_inst\inenc_inst\biss_sniffer_inst\link_detected_inst 
-- does work
bclk: process
begin
    wait for 7000 ns;
        biss_clk <= not biss_clk;
        loop
            biss_clk <= not biss_clk;
            wait for 2.4 us;
        end loop;
    wait;
end process bclk;        
                 

-- Reset
ps_reset: process
begin
    reset_i <= '1';
    wait for 256 ns;
    reset_i <= '0';
    wait;
end process ps_reset;     


-- Random number generator
ps_rand_num: process(clk_i)
    variable seed1      : t_seed := (2,3,5,9);
    variable seed2      : t_seed := (6,7,1,2);
    variable rand       : t_rand;
    variable int_rand   : t_int_rand;
begin
    if rising_edge(clk_i) then    
        lp_rand: for i in ENC_NUM-1 downto 0 loop    
            --Random Data 
            uniform(seed1(i), seed2(i), rand(i));
            int_rand(i) := integer(trunc(rand(i)*2147483647.0));
            -- Data 
            if (test_result_strobe = '1') then
                -- Test data
                test_data(i) <= std_logic_vector(to_unsigned(int_rand(i),32));
            end if;
        end loop lp_rand;
    end if;
end process ps_rand_num;


ps_strobe: process(clk_i)
begin
    if rising_edge(clk_i) then
        test_result_prev <= test_result;
        if test_result_prev = '0' and test_result = '1' then
            test_result_strobe <= '1';
        else
            test_result_strobe <= '0';    
        end if;
    end if;
end process ps_strobe;    
            

-- Posbus 
ps_pos_bus: process(clk_i)
begin
    if rising_edge(clk_i) then
        for i in 0 to (pos_bus_i'length)-1 loop
            pos_bus_i(i) <= std_logic_vector(to_unsigned(i,32));
        end loop;
   end if;         
end process ps_pos_bus;


-- DCARD MODE 
-- If i see it into DCARD_MODE then i can check the received output
ps_DCARD: process(clk_i)
begin
    if rising_edge(clk_i) then
        for i in ENC_NUM-1 downto 0 loop
            DCARD_MODE(i) <= std_logic_vector(to_unsigned(2,32));
        end loop;
    end if;     
end process ps_DCARD;
             


ps_write_data: process(clk_i)
begin
    if rising_edge(clk_i) then
        case (SM_WR) is
            -- State idle only write to the registers once
            when STATE_READY =>
                if (reset_i = '0') then
                    write_strobe_i <= '0';
                    -- All registers have been written to
                    if (index /= c_num_addr) then 
                        SM_WR <= STATE_BiSS_WR_DATA;
                    end if;
                end if;
            -- Write to registers    
            when STATE_BiSS_WR_DATA => 
                write_strobe_i <= '1';
                -- Write to the required registers
                write_address_i <= std_logic_vector(to_unsigned((c_BiSS_addr_array(index)),PAGE_AW)); 
                write_data_i <= std_logic_vector(to_unsigned((c_BiSS_data_array(index)),32));    
                if (write_ack_o = '1') then
                    index <= index +1; 
                    SM_WR <= STATE_READY;
                end if;
            -- Default state    
            when others => 
                SM_WR <= STATE_READY;
        end case;
    end if;        
end process ps_write_data;                         



ps_check_result: process(clk_i)
begin
    if rising_edge(clk_i) then
        for enc in 0 to ENC_NUM-1 loop   
            for bits in 31 downto 0 loop         
                --Gnerate the expected data               
                -- Sign bit or not depending on BITS parameter.
                if (bits < enc_bits(enc)) then
                    data_result(enc)(bits) <= test_data(enc)(bits);
                else
                    data_result(enc)(bits) <= test_data(enc)(enc_bits(enc)-1);
                end if;                                                     
                -- Compare expected data with received data 
                if (data_result(enc) = posn_o(enc) and reset_i = '0') then
                    data_match(enc) <= '1';
                else
                    data_match(enc) <= '0';
                end if;
            end loop;    
            -- If the data matches then stop the simulation 
            if (data_match = "1111" ) then
                test_result <= '1';
            else
                test_result <= '0';
            end if;
            -- Print message
            if (test_result_strobe = '1') then    
                report " Test has passed " severity failure;
--                report " Test has passed " severity note;
            end if;              
        end loop;
    end if;
end process ps_check_result;
                 
                  

-- Generate the 4 separate ENC slave modules
gen: for i in 0  to ENC_NUM-1 generate
    
    -- Sysbus clocks
--    bit_bus_i(c_bit_bus_clk(i)) <= clk_o(i);
    bit_bus_i(c_bit_bus_clk(i)) <= biss_clk;
    
    bits_slv(i) <= std_logic_vector(to_unsigned(enc_bits(i),8));
    
    CLK_IN(i) <= CLK_OUT(i);
            
    biss_slave_inst: entity work.biss_slave
    port map(
        clk_i       => clk_i,
        reset_i     => reset_i,
        BITS        => bits_slv(i),            
        posn_i      => test_data(i),    
        biss_sck_i  => CLK_IN(i),         
        biss_dat_o  => DATA_IN(i)         
        );
       
end generate gen;    


-- INENC_TOP instantance
inenc_top_inst: entity work.inenc_top
port map(
    -- Clock and Reset
    clk_i           => clk_i,
    reset_i         => reset_i,
    -- Memory Bus Interface
    read_strobe_i   => read_strobe_i,
    read_address_i  => read_address_i,
    read_data_o     => read_data_o,
    read_ack_o      => read_ack_o,

    write_strobe_i  => write_strobe_i,
    write_address_i => write_address_i,
    write_data_i    => write_data_i,
    write_ack_o     => write_ack_o,
    -- Encoder I/O Pads
    A_IN            => A_IN,
    B_IN            => B_IN,
    Z_IN            => Z_IN,
    CLK_OUT         => CLK_OUT,
    DATA_IN         => DATA_IN,
    CLK_IN          => CLK_IN,
    CONN_OUT        => CONN_OUT,
    -- Signals passed to internal bus
    a_int_o         => a_int_o,
    b_int_o         => b_int_o,
    z_int_o         => z_int_o,
    data_int_o      => data_int_o,
    -- Block Input and Outputs
    bit_bus_i       => bit_bus_i,
    pos_bus_i       => pos_bus_i,
    DCARD_MODE      => DCARD_MODE,
    PROTOCOL        => PROTOCOL,
    posn_o          => posn_o
);

end rtl;
