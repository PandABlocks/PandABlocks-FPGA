--
--
-- 1/30/26: from George (Faraday Motion Controls)
--
-- 1/15/26: Test with the Power PMAC and EnDat 25 bit Encoder configuration
--          Test with the EnDat master and Sniffer
--   HEIDENHAIN ECN 425 2048
--   ECN 425 EnDat 2.2(EnDat22) interface 
--   Singleturn 25bit(33,554,432 pos/rev), 
--
--   added ENDAT_S_SCLKDLY_CNT for adjust delay, default was 5, however with hardware need to set 4
--   added "crc_calc_reg" for CRC calculation monitoring



library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.support.all;

entity endat_slave is
generic (
    MAX_DATA_WIDTH      : integer := 32;
    SYS_CLOCK_FREQ_MHz  : integer := 125;
    STOP_TIME_uS        : integer := 2;
    TIMEOUT_mS          : integer := 10;
    ENDAT_S_SCLKDLY_CNT : integer := 4    -- was 5, Power with PMAC and EnDat encoder it works with 4, total 46 clocks from master
);
port (
    -- Global system and reset interface.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Configuration interface.
    ENCODING            : in  std_logic_vector(1 downto 0); -- Currently ignored.
    BITS                : in  std_logic_vector(7 downto 0);
    enable_i            : in  std_logic;
    GENERATOR_ERROR     : in  std_logic;
    health_o            : out std_logic_vector(31 downto 0);
    -- Block Input and Outputs.
    posn_i              : in  std_logic_vector(31 downto 0);
    endat_clk_i         : in  std_logic;
    endat_data_i        : in  std_logic;
    endat_data_o        : out std_logic;
    endat_wr_nrd_o      : out std_logic
);
end entity;


architecture rtl of endat_slave is


    constant STOP_TIME_CYCLES    : integer := STOP_TIME_uS * SYS_CLOCK_FREQ_MHz;
    constant TIMEOUT_CLK_CYCLES  : integer := TIMEOUT_mS * SYS_CLOCK_FREQ_MHz *1000;

    type endat_state_t is
    (
        ENDAT_IDLE,
        ENDAT_CMD,
        
        ENDAT_P,
        
        ENDAT_S,
        ENDAT_F1,
        ENDAT_DATA,
        ENDAT_CRC,
	
	ENDAT_STOP
    );

    signal clk_in       : std_logic;
    signal data_in      : std_logic;
    signal data_out     : std_logic;
	signal data_rd      : std_logic;
    
    signal clk_prev     : std_logic;

    signal state        : endat_state_t;

    signal cmd_val      : std_logic_vector(5 downto 0);
    signal data_sr      : std_logic_vector(MAX_DATA_WIDTH downto 0);
    signal error_flag   : std_logic;
    signal timeout_flag : std_logic;

    -- Checksum Flipflops
    signal FF0          : std_logic;
    signal FF1          : std_logic;
    signal FF2          : std_logic;
    signal FF3          : std_logic;
    signal FF4          : std_logic;
    signal S            : std_logic;
    signal cs1          : std_logic;
    signal cs2          : std_logic;
    
    
    
    signal crc_calc_reg : std_logic_vector(4 downto 0) := (others => '0');
  ----------------------------------------------------------------------------
  -- Vivado ILA Debug Attributes
  ----------------------------------------------------------------------------
  attribute mark_debug : string;

  attribute mark_debug of error_flag      : signal is "true";
  attribute mark_debug of timeout_flag    : signal is "true"; 
  attribute mark_debug of cmd_val         : signal is "true"; 
  attribute mark_debug of data_sr         : signal is "true";
  attribute mark_debug of state           : signal is "true";               
  attribute mark_debug of crc_calc_reg    : signal is "true";
  
  
begin

-- Data in/out and direction signals...
-- (Bidirectional switching done in higher level)
data_in        <= endat_data_i;
endat_data_o   <= data_out;
endat_wr_nrd_o <= not data_rd when enable_i = '1' else '0';

-- Health signal...
-- (0 is OK, 2 is EnDat Command Error, 3 is EnDat Timeout)
health_o <= std_logic_vector(to_unsigned(3,32)) when timeout_flag = '1' else
            std_logic_vector(to_unsigned(2,32)) when error_flag = '1' else 
            std_logic_vector(to_unsigned(0,32)); 

-- Sync clk input to FPGA clock...
process (clk_i)
begin
    if (rising_edge (clk_i)) then
        clk_in <= endat_clk_i;
    end if;
end process;


-- Main State Machine...
process (clk_i)
    variable bit_count      : integer range 0 to 63 := 0;
    variable timeout        : integer range 0 to TIMEOUT_CLK_CYCLES := 0;
    variable clk_high_timer : integer range 0 to STOP_TIME_CYCLES := 0;
begin
    if (rising_edge(clk_i)) then
        
        -- Detect edge of endat clock...
        if clk_prev /= clk_in  then

            clk_prev <= clk_in;
            timeout := 0;
            timeout_flag <= '0';

            -- process according to rising or falling edge...
            if clk_in = '0' then
            
                case state is       -- FALLING EDGE
                                      
                    when ENDAT_IDLE =>
                        bit_count := 0;
                        state <= ENDAT_CMD;
                        data_rd <= '1';
                        data_sr <= posn_i & '0';
                        
                    when ENDAT_CMD =>
                        if bit_count = 8 then
                            state <= ENDAT_P;
                            bit_count := 0;
                        elsif bit_count = 7 then
                            if cmd_val(5 downto 0) = "000111" then
                                error_flag <= '0';
                            else
                                error_flag <= '1';
                            end if;
                            data_sr(0) <= error_flag;
                            data_rd <= '0';
                            data_out <= '0';
                            bit_count := bit_count + 1;
                        else
                            bit_count := bit_count + 1;
                        end if; 
                                        
                    when ENDAT_P =>     null;
                    when ENDAT_S =>     null;
                    when ENDAT_F1 =>    null;
                    when ENDAT_DATA =>  null;
                    when ENDAT_CRC =>   null;
                    when ENDAT_STOP =>  null;
                    when others =>      null;
                    
                end case;
            
            else                    -- RISING EDGE

                case state is

                    when ENDAT_IDLE =>  null;
                    
                    when ENDAT_CMD =>
                        cmd_val <= cmd_val(4 downto 0) & data_in;

                    when ENDAT_P =>
                        --if bit_count = 5 then     
                        if bit_count = ENDAT_S_SCLKDLY_CNT then -- Power PMAC and EnDat encoder test setup  
                                       
                            state <= ENDAT_S;
                        else
                            bit_count := bit_count +1;
                        end if;
                        
                    when ENDAT_S =>
                        data_out <= '1';
                        FF0 <= '1';
                        FF1 <= '1';
                        FF2 <= '1';
                        FF3 <= '1';
                        FF4 <= '1';
                        S <= '1';
                        bit_count := 0;
                        state <= ENDAT_F1;
                                                
                    when ENDAT_F1 =>
                        data_out <= data_sr(0);
                        data_sr <= '0' & data_sr(MAX_DATA_WIDTH downto 1);
                        state <= ENDAT_DATA;
                        
                    when ENDAT_DATA =>
                        --if bit_count = MAX_DATA_WIDTH-1 then
                        if bit_count = to_integer(unsigned(BITS))-1 then
                            data_out <= data_sr(0);
                            S <= '0';
                            bit_count := 0;
                            state <= ENDAT_CRC;
                        else
                            data_out <= data_sr(0);
                            data_sr <= '0' & data_sr(MAX_DATA_WIDTH downto 1);
                            bit_count := bit_count +1;
                        end if;
                        
                    when ENDAT_CRC =>
                        -- Latch the computed CRC (before the CRC shift-out starts)
                        if bit_count = 0 then
                            crc_calc_reg <= (not FF4) & (not FF3) & (not FF2) & (not FF1) & (not FF0);
                        end if;

                        if bit_count = 5 then
                            data_out <= '1';
                            state <= ENDAT_STOP;
                          --It was (VHDL-2008 style)  
--                        else
--                            -- output CRC bit or force CRC error
--                            data_out <= not FF4 when GENERATOR_ERROR = '0' else '1'; 
--                            bit_count := bit_count +1;
--                        end if;

                        else
                            -- output CRC bit or force CRC error (VHDL-2001 style)
                            if GENERATOR_ERROR = '0' then
                                data_out <= not FF4;
                            else
                                data_out <= '1';
                            end if;                    
                            bit_count := bit_count + 1;
                        end if;

                    when ENDAT_STOP =>  null;

                    when others =>      null;

                end case;
                
                -- Checksum calculation...
                if (state = ENDAT_F1) or (state = ENDAT_DATA) or (state = ENDAT_CRC) then
                    FF0 <= cs1;
                    FF1 <= FF0 xor cs2;
                    FF2 <= FF1;
                    FF3 <= FF2 xor cs2;
                    FF4 <= FF3;
                end if;
                
            end if;

        end if;

        -- Stop Timer... Time how low the clock has been high...
        if  clk_in = '1' and state /= ENDAT_IDLE then
            if clk_high_timer = STOP_TIME_CYCLES then
                state <= ENDAT_IDLE;
                data_rd <= '0';
                data_out <= '0';
            else
                clk_high_timer := clk_high_timer + 1;
            end if;
        else
            clk_high_timer := 0;
        end if;
        
        
        -- Power-On Reset or Timeout if no clock edges detected...
        if reset_i = '1' or timeout = TIMEOUT_CLK_CYCLES then
            state <= ENDAT_IDLE;
            data_rd <= '0';
            data_out <= '0';
            timeout_flag <= '1';
        else
            timeout := timeout + 1;
        end if;
        
    end if;

end process;

-- Checksum intermediate signals...
cs1 <= (FF4 and S) xor (data_sr(0) and S);
cs2 <= cs1 and S;


end rtl;
