--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : 32-bit programmable counter
--
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    enable_i            : in  std_logic;
    trigger_i           : in  std_logic;
    dir_i               : in  std_logic;
    carry_o             : out std_logic;
    -- Block Parameters
    START               : in  std_logic_vector(31 downto 0);
    START_WSTB          : in  std_logic;
    STEP                : in  std_logic_vector(31 downto 0);
    STEP_WSTB           : in  std_logic;
    MAX                 : in  std_logic_vector(31 downto 0);
    MAX_WSTB            : in  std_logic;
    MIN                 : in  std_logic_vector(31 downto 0);
    MIN_WSTB            : in  std_logic;
    -- Block Status
    out_o               : out std_logic_vector(31 downto 0)
);
end counter;

architecture rtl of counter is

-- Maximum value = 17FFFFFFF ( 2**31-1 =  2147483647 dec, 7FFFFFFF) 
constant c_max_val       : unsigned(31 downto 0) := x"7fffffff";
-- Minimum value = 080000000 (-2**31   = -2147483648 dec, 80000000)
constant c_min_val       : unsigned(31 downto 0) := x"80000000";      


constant c_step_size_one : std_logic_vector(31 downto 0) := x"00000001";

signal step_enable      : std_logic;
signal trigger_prev     : std_logic;
signal trigger_rise     : std_logic;
signal enable_prev      : std_logic;
signal enable_rise      : std_logic;
signal enable_fall      : std_logic;
signal counter          : unsigned(31 downto 0) := (others => '0');
signal STEP_default     : std_logic_vector(31 downto 0);
signal MAX_VAL          : unsigned(31 downto 0) := c_max_val;
signal MIN_VAL          : unsigned(31 downto 0) := c_min_val;    
signal counter_carry    : std_logic;    


begin


--------------------------------------------------------------------------
-- Input registering
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        trigger_prev <= trigger_i;
        enable_prev <= enable_i;
    end if;
end process;

trigger_rise <= trigger_i and not trigger_prev;
enable_rise <= enable_i and not enable_prev;
enable_fall <= not enable_i and enable_prev;

--------------------------------------------------------------------------
-- Default counter STEP to 1
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if STEP_WSTB = '1' then
            step_enable <= '1';
        elsif (enable_fall = '1') then
            step_enable <= '0';
        end if;    
    end if;
end process;

STEP_default <= STEP when step_enable = '1' else c_step_size_one;

--------------------------------------------------------------------------
-- Up/Down Counter
-- Counter keeps its last value when it is disabled and it is re-loaded
-- on the rising edge of enable input.
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        -- The default value is used until Maximum value is written to
        if (MAX_WSTB = '1') then
            MAX_VAL <= unsigned(MAX);
        end if;    
        -- The default value is used until Minimum value is written to
        if (MIN_WSTB = '1') then
            MIN_VAL <= unsigned(MIN);
        end if;    

        -- Load the counter
        if (START_WSTB = '1' and enable_i = '1') then
            counter <= unsigned(START);
        -- Re-load on enable rising edge
        elsif (enable_rise = '1') then
            counter <= unsigned(START);
        -- Count up/down on trigger
        elsif (enable_i = '1' and trigger_rise = '1') then
           -- Crosssing from positive to negative with roll over when smaller than MAX default value  
-----------           if ((signed(counter) + signed(STEP_default)) > signed(MAX_VAL)) then 
            if ((counter + unsigned(STEP_default)) > MAX_VAL) and ((counter + unsigned(STEP_default)) < MIN_VAL) then 
                counter_carry <= '1';    
                counter <= counter + unsigned(STEP_default) - (MAX_VAL+1 - MIN_VAL);                
            elsif (dir_i = '0') then
                -- Check to see if we are crossing from the positive to negative or
                -- negative to positive boundaries if we do set the carry bit
                if (counter(31) = '0' and ((counter + unsigned(STEP_default) > MAX_VAL))) or
                   (counter(31) = '1' and ((counter + unsigned(STEP_default) < MIN_VAL))) then
                    counter_carry <= '1';
                else
                    counter_carry <= '0';    
                end if;
                -- Increment the counter
                counter <= counter + unsigned(STEP_default);            
            else
                -- Check to see if we are crossing from the negative to positive or
                -- positive to negative boundaries if we do set the carry bit
                if (counter(31) = '1' and ((counter - unsigned(STEP_default) < MIN_VAL))) or
                   (counter(31) = '0' and ((counter - unsigned(STEP_default) > MAX_VAL))) then                    
                    counter_carry <= '1';
                else 
                    counter_carry <= '0';
                end if;          
                -- Decrement the counter    
                counter <= counter - unsigned(STEP_default);
            end if;                
        else
            -- Need to stop the counter_carry when trigger_i is low
            -- this is what the python model does  
            if (trigger_i = '0') then
                counter_carry <= '0';
            end if;    
        end if;
    end if;
end process;

out_o <= std_logic_vector(counter);
carry_o <= counter_carry;



end rtl;
