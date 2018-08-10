library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;


entity biss_master_slave_tb is
end biss_master_slave_tb;

architecture rtl of biss_master_slave_tb is


signal clk_i                : std_logic := '0';
signal reset_i              : std_logic;
signal BITS                 : std_logic_vector(7 downto 0)  := std_logic_vector(to_unsigned(30,8));  
signal test_bits            : std_logic_vector(7 downto 0);  
signal CLK_PERIOD           : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(150,32));
signal FRAME_PERIOD         : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(200,32));

signal biss_sck_o           : std_logic;
signal biss_sck_i           : std_logic;
signal biss_dat_i           : std_logic;
signal biss_dat_o           : std_logic;

signal posn_valid_o         : std_logic;
signal posn_valid2_o        : std_logic;
signal posn_o               : std_logic_vector(31 downto 0);
signal posn_i               : std_logic_vector(31 downto 0) := X"AAAAAAAA";
signal posn_expected        : std_logic_vector(31 downto 0); 
signal err                  : std_logic;
signal biss_sck_prev        : std_logic;
signal biss_sck_rising_edge : std_logic;
signal test_cnt             : natural := 0;
signal test_result          : std_logic;

signal stop                 : std_logic := '0';

begin
 

process
begin
    -- Stop the clock after 100 tests have run
    -- doing this allows the tcl script to run 
    -- and stop and not run forever      
    while stop = '0' loop
        clk_i <= not clk_i;
        wait for 4 ns;
        clk_i <= not clk_i;
        wait for 4 ns;
    end loop;
    wait;
end process;
    


ps_reset: process
begin
    reset_i <= '1';
    wait for 256 ns;
    reset_i <= '0';
    wait;
end process ps_reset;     



-- Random number of samples generator
ps_rand_num: process(clk_i)
    variable seed1      : positive; 
    variable seed2      : positive;      
    variable seed1_2    : positive := 30;
    variable seed2_2    : positive := 10;
    variable seed1_3    : positive := 27;
    variable seed2_3    : positive := 12;    
    variable rand       : real;     
    variable rand_2     : real;
    variable rand_3     : real;
    variable int_rand   : integer;
    variable int_rand_2 : integer;
    variable int_rand_3 : integer;
                
begin
    if rising_edge(clk_i) then        
        uniform(seed1, seed2, rand);
        uniform(seed1_2, seed2_2, rand_2);   
        int_rand   := integer(trunc(rand*2147483647.0));
        int_rand_2 := integer(trunc(rand_2*32.0));
        -- Data transmitted
        if (posn_valid_o = '1') then
            -- posn_i data in
            posn_i <= std_logic_vector(to_unsigned(int_rand,posn_i'length));
        end if;
        -- BITS to uses
        if (posn_valid_o = '1') then
            test_bits <= BITS;
            -- Check to see if the rand generator has set the value to zero (could i use a floor value?) 
            if (int_rand_2 /= 0) then 
                BITS <= std_logic_vector(to_unsigned(int_rand_2,BITS'length));
            -- Else BITS is set to one
            else
                BITS <= std_logic_vector(to_unsigned(1,BITS'length)); 
            end if;            
        end if;
    end if;
end process ps_rand_num;



biss_sck_rising_edge <= not biss_sck_prev and biss_sck_o;

-- Trying to find the rising edge as above
ps_prev: process(clk_i)
begin
    if rising_edge(clk_i) then
        biss_sck_prev <= biss_sck_o;
    end if;
end process ps_prev;        



expect_data: process(clk_i)
begin
    if rising_edge(clk_i) then
        if (posn_valid_o = '1') then
            for i in posn_i'range loop
                -- Sign bit or not depending on BITS parameter.
                if (i < unsigned(BITS)) then
                    posn_expected(i) <= posn_i(i);
                else
                    posn_expected(i) <= posn_i(to_integer(unsigned(BITS))-1);
                end if;
            end loop;
        end if;
    end if;
end process expect_data;



ps_check_data: process(clk_i)
begin
    if rising_edge(clk_i) then
        posn_valid2_o <= posn_valid_o;
        if (posn_valid2_o = '1') then
            test_cnt <= test_cnt +1; 
            -- Checked the received data with the expected data if they arent the same rise an error
            if (posn_o /= posn_expected) then
                report " ERROR Data receiver is " & integer'image(to_integer(unsigned(posn_o))) & 
                       " and data expeceted is " & integer'image(to_integer(unsigned(posn_expected))) severity error;
                err <= '1';
                test_result <= '1';
            else
                report " Test " & integer'image(test_cnt) & " has passed using " & integer'image(to_integer(unsigned(test_bits))) & " number of bits" severity note; 
                err <= '0';    
            end if;
        end if;        
        -- Kill the sim after 100 tests have run    
        if test_cnt = 100 then
            stop <= '1';
        else
            stop <= '0';
        end if;        
    end if;
end process ps_check_data;
    


-- Clock and Data
biss_sck_i <= biss_sck_o;
biss_dat_i <= biss_dat_o;

biss_master_inst: entity work.biss_master

port map(
    clk_i        => clk_i,
    reset_i      => reset_i, 
    BITS         => BITS,
    CLK_PERIOD   => CLK_PERIOD,
    FRAME_PERIOD => FRAME_PERIOD,
    biss_sck_o   => biss_sck_o,
    biss_dat_i   => biss_dat_i,
    posn_o       => posn_o,        
    posn_valid_o => posn_valid_o  
    );



biss_slave_inst: entity work.biss_slave
port map(
    clk_i       => clk_i,
    reset_i     => reset_i,
    BITS        => BITS,
    posn_i      => posn_i,
    biss_sck_i  => biss_sck_i,
    biss_dat_o  => biss_dat_o
    );


end rtl;
