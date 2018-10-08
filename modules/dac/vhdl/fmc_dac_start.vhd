--Scott Robson <scott.robson@d-tacq.co.uk>
--11:59:51 Fri 19 Jan 2018
--Order of operations to begin data output on ACQ427 DAC Module
--
--  Set a suitable clock divider.
--    We divide PandA clk_0 by 2 to get the source clock for 427 DAC logic. Max sample rate of DAC is 1 MHz.
--    
--    Example of clock configuration
--    
--    Target update rate of 1 MHz
--    Internal ACQ427 DAC clock = 62.5 MHz
--    Set DAC clock divide to 62, 62.5M / 62 ~= 1 MHz
--    
--  Source DAC data from counter
--    Set clock A period to 1e-6 and connect to counters block TRIG port
--    Set FMC Channel Data to "COUNTER1.OUT"
--    Set a sensible counter STEP
--    
--  Set configuration bits in the following order
--    Set MODULE_ENABLE
--    Set DAC_CLKDIV (62)
--    --N.B. The following 4 steps are required on every power cycle. The act of asserting and de-asserting reset performs some initialisation SPI writes to the DACs
--    Ensure DAC_ENABLE is Disabled
--    Assert then Deassert DAC_RESET
--    Set DAC_ENABLE
--    Set DAC_FIFO_ENABLE
--
--  Data should now be updating on the ACQ427 outputs.

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity fmc_dac_start is
    port (clk_i             : in  std_logic;
          reset_i           : in  std_logic;
          MODULE_ENABLE     : out std_logic_vector(31 downto 0);
          DAC_CLKDIV        : out std_logic_vector(31 downto 0);
          DAC_FIFO_RESET    : out std_logic_vector(31 downto 0);
          DAC_FIFO_ENABLE   : out std_logic_vector(31 downto 0);
          DAC_RESET         : out std_logic_vector(31 downto 0);
          DAC_ENABLE        : out std_logic_vector(31 downto 0)
);
end fmc_dac_start;

architecture rtl of fmc_dac_start is

-- I know why on earth have i put such a long wait here but i tried smaller ones
-- and the block didn't work it did in simulation but not on the hardware there must be some
-- issue with the hardware that requires a long time period. 
--constant c_dac_reset_wait  : unsigned(26 downto 0) := to_unsigned(125000000,27);
--constant c_dac_enable_wait : unsigned(26 downto 0) := to_unsigned(125000000,27); 
constant c_dac_reset_wait  : unsigned(26 downto 0) := to_unsigned(10,27);
constant c_dac_enable_wait : unsigned(26 downto 0) := to_unsigned(125000000,27); 


type t_sm_dac_start is (state_dac_start, state_dac_module_enable ,state_dac_clkdiv, state_dac_reset_en, state_dac_reset_dis, state_dac_enable, state_dac_fifo_enable);

signal sm_dac_start : t_sm_dac_start;
signal wait_cnt     : unsigned(26 downto 0);
signal enable       : std_logic_vector(9 downto 0) := (others => '0');


begin


ps_start: process(clk_i)
begin
    if rising_edge(clk_i) then
        
        case sm_dac_start is
        
            -- Start by reseting everything 
            when state_dac_start => 
                wait_cnt <= (others => '0');
                MODULE_ENABLE <= (others => '0'); 
                DAC_CLKDIV <= (others => '0');
                DAC_FIFO_RESET <= (others => '0');
                DAC_FIFO_ENABLE <= (others => '0');
                DAC_RESET <= (others => '0');
                DAC_ENABLE  <= (others => '0'); 
                enable <= enable(8 downto 0) & '1';
                if enable(9) = '1' then
                    sm_dac_start <= state_dac_module_enable;
                end if;
                
            -- Enable the MODULE_ENABLE
            when state_dac_module_enable => 
                MODULE_ENABLE <= std_logic_vector(to_unsigned(1,32));
                sm_dac_start <= state_dac_clkdiv;                  
            
            -- Target update rate of 1 MHz
            -- Internal ACQ427 DAC clock = 62.5 MHz
            -- Set DAC clock divide to 62, 62.5M / 62 ~= 1 MHz
            when state_dac_clkdiv =>
                DAC_CLKDIV <= std_logic_vector(to_unsigned(62,32));
                sm_dac_start <= state_dac_reset_en; 
            
            -- Enable the DAC_RESET 
            when state_dac_reset_en => 
                DAC_RESET <= std_logic_vector(to_unsigned(1,32));
                wait_cnt <= wait_cnt +1;
                -- Allow the reset to be high for several clocks
                if wait_cnt = c_dac_reset_wait then
                    sm_dac_start <= state_dac_reset_dis;
                end if;
                
            -- Disable the DAC_RESET    
            when state_dac_reset_dis =>
                wait_cnt <= (others => '0'); 
                DAC_RESET <= (others => '0');
                sm_dac_start <= state_dac_enable;     
            
            -- Enable the DAC_ENABLE
            when state_dac_enable =>
                wait_cnt <= wait_cnt +1;
                -- Copied DTAC instruction but found i had to add in a delay before writting into the DAC_ENABLE register for a period of time
                --fmc_dac_spi.vhd -- lines 189, 190, 191, 192 and 193 below shows that the DAC_ENABLE = '0' needs to be held 
                --                -- off for a period of time before setting the DAC_ENABLE = '1' thats what the dac_en_wait_cnt 
                --                -- is for  
                --
                --if  DAC_ENABLE = '0' and CONTROL_WRITE = '1' then		-- Start the Sequence when software writes to the register
			    --    NEXT_CONTROL_STATE <= INIT_CNRL_WRITE;
		        --elsif  DAC_ENABLE = '0' and CONTROL_READ = '1' then	-- Start the Sequence when software writes to the register
			    --    NEXT_CONTROL_STATE <= INIT_CNRL_READ;
		        --end if;                
                if wait_cnt = c_dac_enable_wait then
                    DAC_ENABLE <= std_logic_vector(to_unsigned(1,32));
                    sm_dac_start <= state_dac_fifo_enable; 
                end if;
            
            -- Enable the DAC_FIFO_ENABLE
            when state_dac_fifo_enable =>
                DAC_FIFO_ENABLE <= std_logic_vector(to_unsigned(1,32));
            
            -- Default condition
            when others => 
                sm_dac_start <= state_dac_start;
           
        end case;           
    end if;            
end process ps_start;    
            
            


end rtl;           
