--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Position compare output pulse generator.
--                Supports regular and table-based comparison.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity pcomp is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block inputs
    enable_i            : in  std_logic;
    posn_i              : in  std_logic_vector(31 downto 0); --INP
    -- Block inputs
    --
    PRE_START           : in  std_logic_vector(31 downto 0);
    START               : in  std_logic_vector(31 downto 0);
    WIDTH               : in  std_logic_vector(31 downto 0);
    STEP                : in  std_logic_vector(31 downto 0);
    PULSES              : in  std_logic_vector(31 downto 0);
    RELATIVE            : in  std_logic;
    DIR                 : in  std_logic_vector(1 downto 0);
    health_o            : out std_logic_vector(1 downto 0);  
    produced_o          : out std_logic_vector(31 downto 0);
    state_o             : out std_logic_vector(2 downto 0);
    -- Output pulse
    act_o               : out std_logic;
    out_o               : out std_logic
);
end pcomp;

architecture rtl of pcomp is

constant c_positive     : std_logic_vector(1 downto 0) := "00"; 
constant c_negative     : std_logic_vector(1 downto 0) := "01";
constant c_either       : std_logic_vector(1 downto 0) := "10";

constant c_err_pjump    : std_logic_vector(1 downto 0) := "01";
constant c_err_guess    : std_logic_vector(1 downto 0) := "10";

constant c_state0       : std_logic_vector(2 downto 0) := "000";
constant c_state1       : std_logic_vector(2 downto 0) := "001";
constant c_state2       : std_logic_vector(2 downto 0) := "010";
constant c_state3       : std_logic_vector(2 downto 0) := "011";
constant c_state4       : std_logic_vector(2 downto 0) := "100";

type fsm_t is (WAIT_ENABLE, WAIT_DIR, WAIT_PRE_START, WAIT_RISING, WAIT_FALLING);
signal pcomp_fsm            : fsm_t;

signal enable_prev          : std_logic;
signal enable_rise          : std_logic;
signal enable_fall          : std_logic;
signal posn_latched         : signed(31 downto 0);
signal posn_relative        : signed(31 downto 0);
signal posn                 : signed(31 downto 0);
signal puls_start_pos       : signed(31 downto 0);
signal puls_start_neg       : signed(31 downto 0);
signal puls_start           : signed(31 downto 0);
signal puls_width_pos       : signed(31 downto 0);
signal puls_width_neg       : signed(31 downto 0);
signal puls_width           : signed(31 downto 0);
signal puls_step_pos        : signed(31 downto 0);
signal puls_step_neg        : signed(31 downto 0);
signal puls_step            : signed(31 downto 0);
signal puls_counter         : unsigned(31 downto 0);
signal current_crossing     : signed(31 downto 0);
signal next_crossing        : signed(31 downto 0);

--signal current_crossing_pos : signed(31 downto 0);
signal dir_pos              : std_logic;

signal prestart_pos_cross         : std_logic;
signal prestart_neg_cross         : std_logic;
signal prestart_cross         : std_logic;

signal pos_cross            : std_logic;
signal neg_cross            : std_logic;
signal posn_cross           : std_logic;
signal dir_cal              : signed(31 downto 0);

signal pos_next_cross       : std_logic;     
signal neg_next_cross       : std_logic;                
signal posn_next_cross      : std_logic;

begin

-- PRE_START - INP must be this far from START before waiting for START
-- START     - Pulse absolute/relative start positive value
-- WIDTH     - The relative distance between a rising and falling edge
-- STEP      - The relative distance between successive rising edges
-- PULSES    - The number of pulses to produce, 0 means infinite
-- RELATIVE  - If 1 then START is relative to the positive of INP at enable
--           - 0 Absolute
--           - 1 Relative
-- DIR       - Direction to apply all relative offsets to 
--           - 0 Positive
--           - 1 Negative
--           - 2 Either
-- ENABLE    - Stop on falling edge, reset and enable on rising edge
-- INP       - Positive data from positive-data bus
-- ACTIVE    - Active output is high while block is in operation
-- OUT       - Output pulse train
-- HEALTH    - 0 - OK, 1 - Error Position jumped by more than STEP     
-- PRODUCED  - The number of pulses produced
-- STATE     - The internal statemachine state
--           - 0 - WAIT_ENABLE
--           - 1 - WAIT_DIR   
--           - 2 - WAIT_PRE_START
--           - 3 - WAIT_RISING
--           - 4 - WAIT_FALLING 
 
---------------------------------------------------------------------------
-- Register inputs and detect rising/falling edges
---------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_i;
    end if;
end process;

enable_rise <= enable_i and not enable_prev;
enable_fall <= not enable_i and enable_prev;

---------------------------------------------------------------------------
-- Invert parameters' sign based on encoder direction
---------------------------------------------------------------------------

puls_start_pos <= signed(START);
puls_start_neg <= signed(not unsigned(START) + 1);
puls_start <= puls_start_pos when (RELATIVE = '0' or dir_pos = '1') else puls_start_neg;

puls_width_pos <= signed(WIDTH);
puls_width_neg <= signed(not unsigned(WIDTH) + 1);
puls_width <= puls_width_pos when (dir_pos = '1') else puls_width_neg;

puls_step_pos <= signed(STEP);
puls_step_neg <= signed(not unsigned(STEP) + 1);
puls_step <= puls_step_pos when (dir_pos = '1') else puls_step_neg;

---------------------------------------------------------------------------
-- Latch position on the rising edge of enable_i input, and calculate
-- relative position
---------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
        if (enable_rise = '1') then
            posn_latched <= signed(posn_i);
        end if;
    end if;
end process;

posn_relative <= signed(posn_i) - posn_latched;
posn <= signed(posn_i) when (RELATIVE = '0') else posn_relative;

---------------------------------------------------------------------------
-- Generate prestart and position compare crossing pulses to be used in FSM
---------------------------------------------------------------------------
-- Positive start trigger event (less then)
prestart_pos_cross <= '1' when (dir_pos = '1'
                and posn < puls_start - signed(PRE_START)) else '0';
-- Negative start trigger event (greater than)  
prestart_neg_cross <= '1' when (dir_pos = '0' 
                and posn > puls_start + signed(PRE_START)) else '0';

prestart_cross <= prestart_pos_cross or prestart_neg_cross;

  
-- INP date is positive direction 
pos_cross <= '1' when (dir_pos = '1'
                 and posn >= current_crossing) else '0';                              
-- INP data is negative direction
neg_cross <= '1' when (dir_pos = '0'
                 and posn <= current_crossing) else '0';                

posn_cross <= pos_cross or neg_cross;


-- INP data is greater than or equal to next crossing
pos_next_cross <= '1' when (dir_pos = '1'
                      and posn >= next_crossing) else '0';
                     
-- INP data is less than or equal to next crossing                     
neg_next_cross <= '1' when (dir_pos = '0'
                      and posn <= next_crossing) else '0';
                      
posn_next_cross <= pos_next_cross or neg_next_cross;                                                            
                             
---------------------------------------------------------------------------
-- Pulse generator state machine
-- A window by DELTAP parameter is defined around the start position. The
-- encoder first needs to pass through START-DELTAP before START point.
---------------------------------------------------------------------------


state_o <= c_state1 when pcomp_fsm = WAIT_DIR else
           c_state2 when pcomp_fsm = WAIT_PRE_START else
           c_state3 when pcomp_fsm = WAIT_RISING else
           c_state4 when pcomp_fsm = WAIT_FALLING else
           c_state0; 


produced_o <= std_logic_vector(puls_counter);
            

dir_cal <= signed(START) + signed(PRE_START);


outp_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Reset state machine on falling edge of enable signal.
        if (reset_i = '1') then
            -- reset to starting conditions
            out_o <= '0';
            act_o <= '0';
            dir_pos <= '0';
            pcomp_fsm <= WAIT_ENABLE;
            next_crossing <= (others => '0');            
            current_crossing <= (others => '0'); 
            health_o <= (others => '0');
            puls_counter <= (others => '0');
        elsif (enable_fall = '1') then
            out_o <= '0';
            act_o <= '0';
            pcomp_fsm <= WAIT_ENABLE;
        else
            
            case pcomp_fsm is
            
                -- State 0
                when WAIT_ENABLE => 
                    if enable_rise = '1' then
                        act_o <= '1';
                        health_o <= (others => '0');
                        puls_counter <= (others => '0');
                        if DIR = c_either then    
                            pcomp_fsm <= WAIT_DIR;
                        else
                            if DIR = c_positive then
                                dir_pos <= '1';
                            else
                                dir_pos <= '0';
                            end if;          
                            pcomp_fsm <= WAIT_PRE_START;
                        end if;    
                    end if;
                        
                -- State 1 DIR        
                when WAIT_DIR =>                 
                    -- Relative DIR calculated (RELATIVE = 1 - Then START is relative to the position of INP when enabled)
                    if RELATIVE = '1' then  
                        -- dir_cal = START + PRE_START
                        if dir_cal > 0 then
                            -- abs posn   - latched(posn)  
                            if abs(posn_relative) >= dir_cal then
                                if signed(PRE_START) > 0 then    
                                    if posn > 0 then
                                        dir_pos <= '0';
                                    else
                                        dir_pos <= '1';
                                    end if;                                            
                                    pcomp_fsm <= WAIT_PRE_START;                        
                                -- Relative DIR calculated no PRE_START
                                else 
                                    if posn > 0 then
                                        dir_pos <= '1';                                           
                                        next_crossing <= puls_start_pos + puls_step_pos;            
                                        current_crossing <= puls_start_pos + puls_width_pos;        
                                    else               
                                        dir_pos <= '0';                                             
                                        next_crossing <= puls_start_neg + puls_step_neg;
                                        current_crossing <= puls_start_neg + puls_width_neg;
                                    end if;                                                                      
                                    out_o <= '1';
                                    act_o <= '1';
                                    puls_counter <= puls_counter + 1;
                                    pcomp_fsm <= WAIT_FALLING;
                                end if;     
                            end if;
                        -- Can't guess DIR    
                        else
                            act_o <= '0';
                            health_o <= c_err_guess;
                            pcomp_fsm <= WAIT_ENABLE;
                        end if;    
                    -- RELATIVE = 0 (DIR calculate)
                    elsif puls_start_pos /= posn then        
                        if posn > puls_start_pos then
                            dir_pos <= '0';
                        else
                            dir_pos <= '1';    
                        end if;    
                        pcomp_fsm <= WAIT_PRE_START;
                    end if;    
                    
                -- State 2 PRE START    
                when WAIT_PRE_START => 
                    -- < PRE_START
                    if (prestart_cross = '1') then       
                        current_crossing <= puls_start;
                        next_crossing <= puls_start + puls_width;
                        -- Jittering at the start  
                        pcomp_fsm <= WAIT_RISING;
                    end if;                        
                    
                -- State 3 RISING   
                when WAIT_RISING => 
                    -- >= pulse
                    -- Need to know the direction of the data so we don't false trigger
                    if posn_cross = '1' and posn_next_cross = '0' then                                                 
                        out_o <= '1';     
                        puls_counter <= puls_counter + 1;                            
                        current_crossing <= next_crossing;
                        next_crossing <= current_crossing + puls_step;
                        pcomp_fsm <= WAIT_FALLING;
                    
                    -- Have we passed the next crossing  
                    -- jump > WIDTH + STEP
                    -- reached the next cross but missed the current crossing
                    elsif posn_next_cross = '1' then
                        act_o <= '0';
                        health_o <= c_err_pjump; 
                        pcomp_fsm <= WAIT_ENABLE;
                    end if;
                
                -- State 4 FALLING   
                when WAIT_FALLING => 
                    if posn_cross = '1' then
                        if (puls_counter = unsigned(PULSES)) then
                            -- Finished  
                            out_o <= '0';
                            act_o <= '0';
                            pcomp_fsm <= WAIT_ENABLE;
                        elsif posn_next_cross = '1' then                                            
                            -- Jump > WIDTH + STEP 
                            out_o <= '0';
                            act_o <= '0';  
                            health_o <= c_err_pjump;                             
                            pcomp_fsm <= WAIT_ENABLE;
                        else
                            -- >= pulse + WIDTH                                     
                            out_o <= '0';    
                            current_crossing <= next_crossing;
                            next_crossing <= current_crossing + puls_step;
                            pcomp_fsm <= WAIT_RISING;                                                
                        end if;
                    end if;    
                                        
                -- OTHERS     
                when others =>
                    pcomp_fsm <= WAIT_ENABLE;            
                
            end case;  
        end if;
    end if;
end process;

end rtl;

