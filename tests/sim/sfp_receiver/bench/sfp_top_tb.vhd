library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.support.all;
use work.top_defines.all;


entity sfp_top_tb is
end sfp_top_tb;


architecture rtl of sfp_top_tb is

-- Number of write registers
constant c_reg_writes    : natural := 5;                                                                                 -- ###################################################

constant c_enable_er_clk : std_logic_vector(1 downto 0) := "10";
constant c_enable_ps_clk : std_logic_vector(1 downto 0) := "00";

type t_SM_WR is (STATE_IDLE, STATE_REG_WR, STATE_FINISHED);

type t_reg_addr_array is array (c_reg_writes-1 downto 0) of std_logic_vector(PAGE_AW-1 downto 0);
type t_reg_data_array is array (c_reg_writes-1 downto 0) of std_logic_vector(31 downto 0);   

signal SM_WR               : t_SM_WR; 
signal clk_i               : std_logic;
signal reset_i             : std_logic;
signal fclk_clk0_ps_i      : std_logic := '0';
signal EXTCLK_P            : std_logic := '0';
signal EXTCLK_N            : std_logic := '0';
signal fclk_clk0_o         : std_logic; 
signal read_strobe_i       : std_logic;
signal read_address_i      : std_logic_vector(PAGE_AW-1 downto 0);
signal read_data_o         : std_logic_vector(31 downto 0);
signal read_ack_o          : std_logic;
signal write_strobe_i      : std_logic;
signal write_address_i     : std_logic_vector(PAGE_AW-1 downto 0);
signal write_data_i        : std_logic_vector(31 downto 0);
signal write_ack_o         : std_logic;
signal sma_pll_locked_o    : std_logic;    
signal ext_clock_i         : std_logic_vector(1 downto 0);
signal sfp_en              : std_logic; 
signal bit1_o              : std_logic;
signal bit2_o              : std_logic;
signal bit3_o              : std_logic;
signal bit4_o              : std_logic;        
signal GTREFCLK_N          : std_logic := '0';
signal GTREFCLK_P          : std_logic := '0';
signal RXN_IN              : std_logic_vector(2 downto 0);
signal RXP_IN              : std_logic_vector(2 downto 0);
signal TXN_OUT             : std_logic_vector(2 downto 0);
signal TXP_OUT             : std_logic_vector(2 downto 0);

signal reg_addr_array      : t_reg_addr_array := ("0000000010", "0000000011", "0000000100", "0000000101", "0000000110"); -- ################################################### 
-- Valid DBUS events 110, 120, 140 and 180
signal reg_data_array      : t_reg_data_array := (x"00000001", x"00000110", x"00000120", x"00000140", x"00000180");      -- ###################################################
-- Valid EVENT CODES 07A, 07B, 07C, 07D, 070 and 071 
--signal reg_data_array      : t_reg_data_array := (x"00000001", x"00000070", x"00000071", x"0000007A", x"0000007B");      -- ###################################################
--signal reg data array      : t_reg_data_array := (x"00000001", x"0000007A", x"0000007B", x"0000007C", x"0000007D");      -- ###################################################   
signal cnt_index           : natural;

signal rand_num            : integer := 0;

begin

-- 125MHz clock from PS interface
fclk_clk0_ps_i <= not fclk_clk0_ps_i after 4ns; 

-- Main clock (event receiver clock)
clk_i <= fclk_clk0_o;

-- External clock SMA
EXTCLK_P <= not EXTCLK_P after 4ns;
EXTCLK_N <= not EXTCLK_P; 

-- MGT reference clock 125MHz
GTREFCLK_P <= not GTREFCLK_P after 4ns;
GTREFCLK_N <= not GTREFCLK_P;


ps_reset: process
begin
    reset_i <= '1';
    wait for 128 ns;
    reset_i <= '0';
    wait;
end process ps_reset;    



ps_rand_num: process(clk_i)
    -- seed values for random generator
    variable seed1, seed2: positive;         
    -- random real-number value in range 0 to 1.0
    variable rand: real;                     
    -- the range of random values created will be 0 to +1000.  
    variable range_of_rand : real := 100.0;  
begin
    if rising_edge(clk_i) then
        -- generate random number
        uniform(seed1, seed2, rand);             
        -- rescale to 0..1000, convert integer part
        rand_num <= integer(rand*range_of_rand);  
    end if;
end process;


ps_er_clk_en: process
begin
    ext_clock_i <= c_enable_ps_clk;
    wait for 256 ns;
    ext_clock_i <= c_enable_er_clk;
    wait;
end process ps_er_clk_en;                             


-- test the link going up and down to see what happens
ps_enable_link: process
begin
    -- Link enabled
    sfp_en <= '1';
    wait for 29 us;
    -- Link disabled
    sfp_en <= '0';
    wait for 1280 ns;
    -- Link enabled
    sfp_en <= '1';
    wait for 20 us;
    -- Link disabled
    sfp_en <= '0';
    wait for 1000 ns;
    -- Link enabled
    sfp_en <= '1';
    wait for 25 us;
    -- Link disabled
    sfp_en <= '0';
    wait for 1234 ns;
    sfp_en <= '1';
    wait;
end process;    


-- Loopback RX <- TX
RXN_IN <= TXN_OUT when sfp_en = '1' else (others => '0');
RXP_IN <= TXP_OUT when sfp_en = '1' else (others => '0'); 



ps_wr_reg: process(clk_i)
begin
    if rising_edge(clk_i) then
        case SM_WR is
        
            when STATE_IDLE =>
                cnt_index <= 0;
                if (reset_i = '0') then
                    SM_WR <= STATE_REG_WR;
                end if;      
                
            -- Register Write
            when STATE_REG_WR => 
                write_strobe_i <= '1';
                -- Event receiver register writes   
                write_address_i <= reg_addr_array(cnt_index);
                write_data_i    <= reg_data_array(cnt_index);
                -- Write has been received 
                if write_ack_o = '1' then
                    -- Increment register index and count
                    cnt_index <= cnt_index +1;
                    -- If all of the register have been written too then stop
                    if cnt_index = c_reg_writes-1 then                
                        SM_WR <= STATE_FINISHED;
                    end if;
                end if;                    
            
            -- All register write have finished so stay in this state forever
            when STATE_FINISHED =>
                write_strobe_i <= '0'; 
            
            when others => 
                SM_WR <= STATE_IDLE;
                
        end case;        
    end if;
end process ps_wr_reg;    



sfp_top_inst: entity work.sfp_top
port map(
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- 
    fclk_clk0_ps_i      => fclk_clk0_ps_i,
    EXTCLK_P            => EXTCLK_P,
    EXTCLK_N            => EXTCLK_N,
    fclk_clk0_o         => fclk_clk0_o, 
    -- Memory Bus Interface
    -- Register Read
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,
    -- Register Write
    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,
    -- SMA PLL locked
    sma_pll_locked_o    => sma_pll_locked_o,    
    -- sma and event receiver clock enables
    ext_clock_i         => ext_clock_i,
    -- Bits out
    bit1_o              => bit1_o,
    bit2_o              => bit2_o,
    bit3_o              => bit3_o,
    bit4_o              => bit4_o,        
    -- GTX I/O
    GTREFCLK_N          => GTREFCLK_N,
    GTREFCLK_P          => GTREFCLK_P,
    RXN_IN              => RXN_IN,
    RXP_IN              => RXP_IN,
    TXN_OUT             => TXN_OUT,
    TXP_OUT             => TXP_OUT
);

end rtl;
