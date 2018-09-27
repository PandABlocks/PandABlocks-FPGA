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
    inp_i               : in  std_logic_vector(31 downto 0); --INP
    -- Block inputs
    --
    PRE_START           : in  std_logic_vector(31 downto 0);
    START               : in  std_logic_vector(31 downto 0);
    WIDTH               : in  std_logic_vector(31 downto 0);
    STEP                : in  std_logic_vector(31 downto 0);
    PULSES              : in  std_logic_vector(31 downto 0);
    RELATIVE            : in  std_logic_vector(1 downto 0);
    DIR                 : in  std_logic_vector(1 downto 0);
    health              : out std_logic_vector(1 downto 0);
    produced            : out std_logic_vector(31 downto 0);
    state               : out std_logic_vector(2 downto 0);
    -- Output pulse
    active_o            : out std_logic;
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
signal pcomp_fsm               : fsm_t;

signal enable_prev             : std_logic;
signal enable_rise             : std_logic;
signal enable_fall             : std_logic;
signal posn_latched            : signed(31 downto 0);
signal posn_relative           : signed(31 downto 0);
signal posn                    : signed(31 downto 0);
signal pulse_start_pos         : signed(31 downto 0);
signal pulse_start_neg         : signed(31 downto 0);
signal pulse_start             : signed(31 downto 0);
signal pulse_width_pos         : signed(31 downto 0);
signal pulse_width_neg         : signed(31 downto 0);
signal pulse_width             : signed(31 downto 0);
signal pulse_step_pos          : signed(31 downto 0);
signal pulse_step_neg          : signed(31 downto 0);
signal pulse_step              : signed(31 downto 0);
signal pulse_counter           : unsigned(31 downto 0);
signal next_crossing           : signed(31 downto 0);
signal last_crossing           : signed(31 downto 0);
signal dir_pos                 : std_logic;

signal exceeded_prestart_pos   : std_logic;
signal exceeded_prestart_neg   : std_logic;
signal exceeded_prestart       : std_logic;

signal reached_last_pos        : std_logic;
signal reached_last_neg        : std_logic;
signal too_far_crossing        : signed(31 downto 0);
signal reached_last_crossing   : std_logic;
signal guess_dir_thresh        : signed(31 downto 0);

signal too_far_pos             : std_logic;
signal too_far_neg             : std_logic;
signal jumped_more_than_step   : std_logic;

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

pulse_start_pos <= signed(START);
pulse_start_neg <= signed(not unsigned(START) + 1);
pulse_start <= pulse_start_pos when (RELATIVE(0) = '0' or dir_pos = '1') else pulse_start_neg;

pulse_width_pos <= signed(WIDTH);
pulse_width_neg <= signed(not unsigned(WIDTH) + 1);
pulse_width <= pulse_width_pos when (dir_pos = '1') else pulse_width_neg;

pulse_step_pos <= signed(STEP);
pulse_step_neg <= signed(not unsigned(STEP) + 1);
pulse_step <= pulse_step_pos when (dir_pos = '1') else pulse_step_neg;

---------------------------------------------------------------------------
-- Latch position on the rising edge of enable_i input, and calculate
-- relative position
---------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
        if (enable_rise = '1') then
            posn_latched <= signed(inp_i);
        end if;
    end if;
end process;

posn_relative <= signed(inp_i) - posn_latched;
posn <= signed(inp_i) when (RELATIVE(0) = '0') else posn_relative;

---------------------------------------------------------------------------
-- Generate prestart and position compare crossing pulses to be used in FSM
---------------------------------------------------------------------------
-- Positive start trigger event (less then)
exceeded_prestart_pos <= '1' when (dir_pos = '1'
                             and posn < pulse_start - signed(PRE_START)) else '0';
-- Negative start trigger event (greater than)  
exceeded_prestart_neg <= '1' when (dir_pos = '0' 
                             and posn > pulse_start + signed(PRE_START)) else '0';

exceeded_prestart <= exceeded_prestart_pos or exceeded_prestart_neg;

  
-- INP date is positive direction 
reached_last_pos <= '1' when (next_crossing >= last_crossing
                        and posn >= next_crossing) else '0';                              
-- INP data is negative direction
reached_last_neg <= '1' when (next_crossing < last_crossing
                        and posn <= next_crossing) else '0';                

reached_last_crossing <= reached_last_pos or reached_last_neg;


-- INP data is greater than or equal to next crossing
too_far_crossing <= last_crossing + pulse_step;

too_far_pos <= '1' when (last_crossing <= next_crossing
                   and next_crossing <= too_far_crossing
                   and too_far_crossing <= posn) else '0';
                     
-- INP data is less than or equal to next crossing                     
too_far_neg <= '1' when (last_crossing >= next_crossing
                   and next_crossing >= too_far_crossing
                   and too_far_crossing >= posn) else '0';

jumped_more_than_step <= too_far_pos or too_far_neg;                                                            
                             
---------------------------------------------------------------------------
-- Pulse generator state machine
-- A window by DELTAP parameter is defined around the start position. The
-- encoder first needs to pass through START-DELTAP before START point.
---------------------------------------------------------------------------


state <= c_state1 when pcomp_fsm = WAIT_DIR else
           c_state2 when pcomp_fsm = WAIT_PRE_START else
           c_state3 when pcomp_fsm = WAIT_RISING else
           c_state4 when pcomp_fsm = WAIT_FALLING else
           c_state0; 


produced <= std_logic_vector(pulse_counter);
            

guess_dir_thresh <= signed(START) + signed(PRE_START);


outp_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Reset state machine on falling edge of enable signal.
        if (reset_i = '1') then
            -- reset to starting conditions
            out_o <= '0';
            active_o <= '0';
            dir_pos <= '0';
            pcomp_fsm <= WAIT_ENABLE;
            last_crossing <= (others => '0');            
            next_crossing <= (others => '0'); 
            health <= (others => '0');
            pulse_counter <= (others => '0');
        elsif (enable_fall = '1') then
            out_o <= '0';
            active_o <= '0';
            pcomp_fsm <= WAIT_ENABLE;
        else
            
            case pcomp_fsm is
            
                -- State 0
                when WAIT_ENABLE => 
                    if enable_rise = '1' then
                        active_o <= '1';
                        health <= (others => '0');
                        pulse_counter <= (others => '0');
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
                    if RELATIVE(0) = '1' then  
                        -- guess_dir_thresh = START + PRE_START
                        if guess_dir_thresh > 0 then
                            -- abs posn   - latched(posn)  
                            if abs(posn) >= guess_dir_thresh then
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
                                        last_crossing <= pulse_start_pos;
                                        next_crossing <= pulse_start_pos + pulse_width_pos;        
                                    else               
                                        dir_pos <= '0';                                             
                                        last_crossing <= pulse_start_neg;
                                        next_crossing <= pulse_start_neg + pulse_width_neg;
                                    end if;                                                                      
                                    out_o <= '1';
                                    active_o <= '1';
                                    pulse_counter <= pulse_counter + 1;
                                    pcomp_fsm <= WAIT_FALLING;
                                end if;     
                            end if;
                        -- Can't guess DIR    
                        else
                            active_o <= '0';
                            health <= c_err_guess;
                            pcomp_fsm <= WAIT_ENABLE;
                        end if;    
                    -- RELATIVE = 0 (DIR calculate)
                    elsif pulse_start_pos /= posn then        
                        if posn > pulse_start_pos then
                            dir_pos <= '0';
                        else
                            dir_pos <= '1';    
                        end if;    
                        pcomp_fsm <= WAIT_PRE_START;
                    end if;    
                    
                -- State 2 PRE START    
                when WAIT_PRE_START => 
                    -- < PRE_START
                    if (exceeded_prestart = '1') then
                        if dir_pos = '1' then
                            last_crossing <= pulse_start - 1;
                        else
                            last_crossing <= pulse_start + 1;
                        end if;                                     
                        next_crossing <= pulse_start;
                        -- Jittering at the start  
                        pcomp_fsm <= WAIT_RISING;
                    end if;                        
                    
                -- State 3 RISING   
                when WAIT_RISING => 
                    -- >= pulse
                    -- Need to know the direction of the data so we don't false trigger
                    if reached_last_crossing = '1' then
                        -- Have we passed the next crossing
                        -- jump > WIDTH + STEP
                        -- reached the next cross but missed the current crossing
                        if jumped_more_than_step = '1' then
                            active_o <= '0';
                            health <= c_err_pjump;
                            pcomp_fsm <= WAIT_ENABLE;
                        else
                            out_o <= '1';
                            pulse_counter <= pulse_counter + 1;
                            last_crossing <= next_crossing;
                            next_crossing <= next_crossing + pulse_width;
                            pcomp_fsm <= WAIT_FALLING;
                        end if;
                    end if;
                
                -- State 4 FALLING   
                when WAIT_FALLING => 
                    if reached_last_crossing = '1' then
                        out_o <= '0';
                        if (pulse_counter = unsigned(PULSES)) then
                            -- Finished  
                            active_o <= '0';
                            pcomp_fsm <= WAIT_ENABLE;
                        elsif jumped_more_than_step = '1' then                                            
                            -- Jump > WIDTH + STEP 
                            active_o <= '0';
                            health <= c_err_pjump;
                            pcomp_fsm <= WAIT_ENABLE;
                        else
                            -- >= pulse + WIDTH                                     
                            last_crossing <= next_crossing;
                            next_crossing <= last_crossing + pulse_step;
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

