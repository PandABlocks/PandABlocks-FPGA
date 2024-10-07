----------------------------------------------------------------------------------
--
--  Single Axis quDIS HSSL Decoder.
--
--  G.Francis, August 2024.
-- 
-- 
-- quDIS Settings:
--
--      Timings below are for 32 bits (for PandABrick)
-- 
--      quDIS absolute maximum update rate is about 25kHz...
--
--      Example quDIS Daisy Settings (frequencies approximate):
--
--          25kHz  :  Clock: 1uS, Gap: 8, Average 80nS.
--
--          10kHz  :  Clock: 2uS, Gap: 18, Average 160nS.
-- 
--      Slowest mode is Clock 2.48uS, Gap 63, which gives 4.24kHz.
--
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity hssl_axis_decoder is
generic (
    DATA_LEN            : natural := 32
);
Port ( 
    
    clk_i               : in  std_logic;                                -- 125MHz Clock 
    
    clk_bit_i           : in  std_logic;                                -- HSSL Interface
    data_bit_i          : in  std_logic;
    
    hssl_val_o          : out std_logic_vector(DATA_LEN-1 downto 0);    -- Position Output
    health_bit_o        : out std_logic
    
);
end hssl_axis_decoder;


architecture arch_hssl of hssl_axis_decoder is


signal clk_bit          : std_logic := '0';
signal clk_bit_b        : std_logic := '0';
signal clk_prev         : std_logic := '0';

signal rx_shift_reg     : std_logic_vector(DATA_LEN-1 downto 0);

signal health_bit       : std_logic := '0';

signal clk_timer        : unsigned(15 downto 0);
signal bit_count        : unsigned(5 downto 0);
signal threshold        : unsigned(15 downto 0);



begin


-- Synchronize the hssl clock input
process (clk_i) is
begin
    if rising_edge(clk_i) then
        clk_bit   <= clk_bit_b;
        clk_bit_b <= clk_bit_i;
    end if;
end process;



-- Decoder State Machine
process (clk_i) is

    variable timeout : natural := 0;

begin
    if rising_edge(clk_i) then

        if clk_bit /= clk_prev then         -- Clock bit has changed...

            if clk_bit = '1' then                -- rising edge...
                          
                if clk_timer > threshold then         -- If finished,
                
                    if bit_count = DATA_LEN then
                        hssl_val_o <= rx_shift_reg;        -- output value,
                        health_bit <= '1';                 -- and flag good data.
                    else
                        health_bit <= '0';                 -- or flag bad data if the bit count is wrong.
                    end if;
                    
                    bit_count <= (others => '0');          -- reset bit counter
                                        
                end if;
                
            else                                 -- falling edge...    
                
                rx_shift_reg <= rx_shift_reg(rx_shift_reg'high-1 downto 0) & data_bit_i;   -- sample bit,
                bit_count    <=  bit_count + 1;                                            -- increment bit counter
                threshold    <= clk_timer + clk_timer/2;                                   -- Set threshold to 1.5 * (measured clock-low width)
                clk_timer    <= (others => '0');                                           -- and reset clk-low width counter. 
                                          
            end if;
            
            timeout := 0;

        else
        
            if clk_bit = '0' then 
                clk_timer <= clk_timer + 1;       -- Clock bit has not changed (and is low), so increment timer.
            end if;
            
        end if;
        
        clk_prev  <= clk_bit;                       -- (store new clock level)

        
        if timeout > 1250000 then                   -- 10mS timeout on clock bit input.
            health_bit_o <= '0';
        else
            health_bit_o <= health_bit;
            timeout := timeout + 1;
        end if;

    end if;
    
end process;



end arch_hssl;
