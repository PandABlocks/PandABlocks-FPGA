--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Sequencer Core IP module generates triggered squence of frames
--                Frame configurations are stored, and read from sequencer table
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

Library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use unimacro.Vcomponents.all;

entity sequencer is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    enable_i            : in  std_logic;
    
    bita_i              : in  std_logic;                            
    bitb_i              : in  std_logic;                            
    bitc_i              : in  std_logic;                                
    
    posa_i              : in  std_logic_vector(31 downto 0);
    posb_i              : in  std_logic_vector(31 downto 0);
    posc_i              : in  std_logic_vector(31 downto 0);
    
    outa_o              : out std_logic;
    outb_o              : out std_logic;
    outc_o              : out std_logic;
    outd_o              : out std_logic;
    oute_o              : out std_logic;
    outf_o              : out std_logic;
    active_o            : out std_logic;
    -- Block Parameters
    PRESCALE            : in  std_logic_vector(31 downto 0);
    TABLE_START         : in  std_logic;
    TABLE_DATA          : in  std_logic_vector(31 downto 0);
    TABLE_WSTB          : in  std_logic;
    REPEATS             : in  std_logic_vector(31 downto 0);
    TABLE_LENGTH        : in  std_logic_vector(15 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic;
    -- Block Status
    table_line_o        : out std_logic_vector(31 downto 0);        
    line_repeat_o       : out std_logic_vector(31 downto 0);        
    table_repeat_o      : out std_logic_vector(31 downto 0);
    state_o             : out std_logic_vector(2 downto 0)         
);
end sequencer;

architecture rtl of sequencer is

----constant SEQ_FRAMES         : positive := 1024;
constant SEQ_FRAMES         : positive := 4096;

constant c_immediately          : unsigned(3 downto 0) := "0000";
constant c_bita_0               : unsigned(3 downto 0) := "0001";
constant c_bita_1               : unsigned(3 downto 0) := "0010";
constant c_bitb_0               : unsigned(3 downto 0) := "0011";
constant c_bitb_1               : unsigned(3 downto 0) := "0100";
constant c_bitc_0               : unsigned(3 downto 0) := "0101";
constant c_bitc_1               : unsigned(3 downto 0) := "0110";
constant c_posa_gt_position     : unsigned(3 downto 0) := "0111";
constant c_posa_lt_position     : unsigned(3 downto 0) := "1000";
constant c_posb_gt_position     : unsigned(3 downto 0) := "1001";
constant c_posb_lt_position     : unsigned(3 downto 0) := "1010";
constant c_posc_gt_position     : unsigned(3 downto 0) := "1011";
constant c_posc_lt_position     : unsigned(3 downto 0) := "1100";          

constant c_state_wait_enable    : std_logic_vector(2 downto 0) := "000";
constant c_state_load_table     : std_logic_vector(2 downto 0) := "001";
constant c_state_wait_trigger   : std_logic_vector(2 downto 0) := "010";
constant c_state_phase1         : std_logic_vector(2 downto 0) := "011";
constant c_state_phase2         : std_logic_vector(2 downto 0) := "100";


signal TABLE_FRAMES         : std_logic_vector(15 downto 0);

signal current_frame        : seq_t;
signal next_frame           : seq_t;
signal load_next            : std_logic;

signal tframe_counter       : unsigned(31 downto 0);
signal repeat_count         : unsigned(31 downto 0);
signal frame_count          : unsigned(15 downto 0);
signal table_count          : unsigned(31 downto 0);
signal frame_length         : unsigned(31 downto 0);

type state_t is (WAIT_ENABLE, LOAD_TABLE, PHASE_1, PHASE_2, WAIT_TRIGGER);
signal seq_sm               : state_t;

signal next_inp_val         : std_logic_vector(2 downto 0); 
signal current_inp_val      : std_logic_vector(2 downto 0); 
signal out_val              : std_logic_vector(5 downto 0);
signal active               : std_logic := '0';
signal current_trig_valid   : std_logic;
signal next_trig_valid      : std_logic;

signal presc_reset          : std_logic;
signal presc_ce             : std_logic;
signal enable_val           : std_logic;
signal enable_prev          : std_logic;
signal enable_fall          : std_logic;
signal enable_rise          : std_logic;
signal table_ready          : std_logic;
signal fsm_reset            : std_logic;

signal last_frame           : std_logic := '0';
signal last_fcycle          : std_logic := '0';
signal last_tcycle          : std_logic := '0';

--signal next_immediate       : std_logic;
signal current_pos_en       : std_logic_vector(2 downto 0);
signal next_pos_en          : std_logic_vector(2 downto 0);

signal current_pos_inp      : std_logic;
signal next_pos_inp         : std_logic;

signal table_ready_dly      : std_logic;

signal reset_mem            : std_logic;


begin

-- Block inputs.
enable_val <= enable_i and table_ready;

-- Input register and edge detection.
Registers : process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_val;
    end if;
end process;

enable_fall <= not enable_val and enable_prev;
enable_rise <= enable_val and not enable_prev;

-- Table length is written in terms of DWORDs, and a frame is composed
-- of 4x DWORDs
TABLE_FRAMES <= "00" & TABLE_LENGTH(15 downto 2);

--------------------------------------------------------------------------
-- Sequencer TABLE keeps frame configuration data
--------------------------------------------------------------------------
sequencer_table : entity work.sequencer_table
generic map (
    SEQ_LEN             => SEQ_FRAMES
)
port map (
    clk_i               => clk_i,
    reset_i             => fsm_reset,

    reset_mem           => reset_mem,

    load_next_i         => load_next,
    table_ready_o       => table_ready,
    next_frame_o        => next_frame,

    TABLE_START         => TABLE_START,
    TABLE_DATA          => TABLE_DATA,
    TABLE_WSTB          => TABLE_WSTB,
    TABLE_LENGTH        => TABLE_FRAMES,
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB
);

--------------------------------------------------------------------------
-- Trigger management
--------------------------------------------------------------------------

-- next_frame.trigger(19 downto 16)  = 0 - Immediate
--                                     1 - BITA = 0
--                                     2 - BITA = 1
--                                     3 - BITB = 0
--                                     4 - BITB = 1
--                                     5 - BITC = 0
--                                     6 - BITC = 1
--                                     7 - POSA >= POSITION   POSA(Input)
--                                     8 - POSA <= POSITION   POSA(Input)
--                                     9 - POSB >= POSITION   POSB(Input)
--                                    10 - POSB <= POSITION   POSB(Input)
--                                    11 - POSC >= POSITION   POSC(Input)
--                                    12 - POSC <= POSITION   POSC(Input)                                            
--

-- XNOR
-- A|B|C
-- 0|0|1
-- 0|1|0
-- 1|0|0
-- 1|1|1
-- BITA next trigger events
next_inp_val <= ("000") xnor ("00" & bita_i) when next_frame.trigger = c_bita_0 else
                ("001") xnor ("00" & bita_i) when next_frame.trigger = c_bita_1 else
                ("000") xnor ('0' & bitb_i & '0') when next_frame.trigger = c_bitb_0 else
                ("010") xnor ('0' & bitb_i & '0') when next_frame.trigger = c_bitb_1 else
                ("000") xnor (bitc_i & "00") when next_frame.trigger = c_bitc_0 else
                ("100") xnor (bitc_i & "00") when next_frame.trigger = c_bitc_1 else
                ("000");

next_pos_en(0) <= '1' when (next_frame.trigger = c_posa_gt_position and signed(posa_i) >= next_frame.position) or
                           (next_frame.trigger = c_posa_lt_position and signed(posa_i) <= next_frame.position) else '0';
next_pos_en(1) <= '1' when (next_frame.trigger = c_posb_gt_position and signed(posb_i) >= next_frame.position) or                            
                           (next_frame.trigger = c_posb_lt_position and signed(posb_i) <= next_frame.position) else '0';
next_pos_en(2) <= '1' when (next_frame.trigger = c_posc_gt_position and signed(posc_i) >= next_frame.position) or
                           (next_frame.trigger = c_posc_lt_position and signed(posc_i) <= next_frame.position) else '0';                            

next_pos_inp <= '1' when (next_inp_val = "111") or (next_pos_en /= "000") else '0';

next_trig_valid <= '1' when ((next_frame.trigger = c_immediately) or (next_pos_inp = '1')) else '0';


current_inp_val <= ("000") xnor ("00" & bita_i) when current_frame.trigger = c_bita_0 else
                   ("001") xnor ("00" & bita_i) when current_frame.trigger = c_bita_1 else
                   ("000") xnor ('0' & bitb_i & '0') when current_frame.trigger = c_bitb_0 else
                   ("010") xnor ('0' & bitb_i & '0') when current_frame.trigger = c_bitb_1 else
                   ("000") xnor (bitc_i & "00") when current_frame.trigger = c_bitc_0 else
                   ("100") xnor (bitc_i & "00") when current_frame.trigger = c_bitc_1 else
                   ("000");

current_pos_en(0) <= '1' when (current_frame.trigger = c_posa_gt_position and signed(posa_i) >= current_frame.position) or
                              (current_frame.trigger = c_posa_lt_position and signed(posa_i) <= current_frame.position) else '0'; 
current_pos_en(1) <= '1' when (current_frame.trigger = c_posb_gt_position and signed(posb_i) >= current_frame.position) or
                              (current_frame.trigger = c_posb_lt_position and signed(posb_i) <= current_frame.position) else '0';
current_pos_en(2) <= '1' when (current_frame.trigger = c_posc_gt_position and signed(posc_i) >= current_frame.position) or
                              (current_frame.trigger = c_posc_lt_position and signed(posc_i) <= current_frame.position) else '0';                                  

current_pos_inp <= '1' when (current_inp_val = "111") or (current_pos_en /= "000") else '0';

current_trig_valid <= '1' when ((current_frame.trigger = c_immediately) or (current_pos_inp = '1')) else '0';  


-- Total frame length
frame_length <= current_frame.time1 + current_frame.time2;

--------------------------------------------------------------------------
-- Sequencer State Machine
-------------------------------------------------------------------------
-- Reset condition for state machine.
fsm_reset <= '1' when (reset_i = '1' or enable_fall = '1') else '0';


state_o <= c_state_load_table when seq_sm = LOAD_TABLE else
           c_state_wait_trigger when seq_sm = WAIT_TRIGGER else
           c_state_phase1 when seq_sm = PHASE_1 else
           c_state_phase2 when seq_sm = phase_2 else
           c_state_wait_enable;
                    

SEQ_FSM : process(clk_i)
begin
if rising_edge(clk_i) then
    --
    -- Sequencer State Machine
    --
    load_next <= '0';

    -- Reset all registers and state machine.
    if (fsm_reset = '1') then
        seq_sm <= WAIT_ENABLE;
        out_val <= (others => '0');        
        reset_mem <= '0';
        active <= '0';
        repeat_count <= (others => '0');
        frame_count <= (others => '0');
        table_count <= (others => '0');
    else
            
        table_ready_dly <= table_ready;
                
        -- Need to do this due to the time it takes for the data to be valid on the memory output        
        if table_ready_dly = '0' and table_ready = '1' then
            current_frame <= next_frame;
        end if;

        case seq_sm is
                
            -- State 0
            when WAIT_ENABLE =>
                -- TABLE load_started
                if TABLE_START = '1' then
                    seq_sm <= LOAD_TABLE;
                elsif enable_rise = '1' then    
                    load_next <= '1';                       
                    repeat_count <= repeat_count + 1; --
                    frame_count <= frame_count + 1;   --
                    table_count <= table_count + 1;   --
                    -- rising ENABLE and trigger not met 
                    if (next_trig_valid  = '0') then   
                        seq_sm <= WAIT_TRIGGER;                        
                    -- rising ENABLE and trigger met phase1
                    elsif (next_frame.time1 /= to_unsigned(0,32)) then    
                        active <= '1';                   
                        out_val <= current_frame.out1;     
                        seq_sm <= PHASE_1;            
                    -- rising ENABLE and trigger met and no phase 1
                    else
                        active <= '1';
                        out_val <= next_frame.out2;    
                        seq_sm <= PHASE_2;
                    end if;    
                end if;    
                       
            -- State 1
            when LOAD_TABLE =>                                       
                -- TABLE load complete
                if table_ready = '1' then
                    seq_sm <= WAIT_ENABLE;
                end if;

            -- State 2
            when WAIT_TRIGGER => 
                -- TABLE load started 
                if TABLE_START = '1' then
                    seq_sm <= LOAD_TABLE;
                -- trigger met
                elsif (current_trig_valid = '1') then
                    -- trigger met
                    if (current_frame.time1 /= to_unsigned(0,32)) then  ---------------self.current_line.time1 ??
                        out_val <= current_frame.out1;
                        active <= '1';                    
                        seq_sm <= PHASE_1;
                    -- trigger met and no phase 1
                    else
                        active <= '1';
                        out_val <= current_frame.out2;
                        seq_sm <= PHASE_2;        
                    end if;
                end if;            
                                
            -- State 3
            when PHASE_1 =>       
                -- TABLE load_started
                if TABLE_START = '1' then
                    seq_sm <= LOAD_TABLE;
                --time 1 elapsed                     
                elsif (presc_ce = '1' and tframe_counter = current_frame.time1-1) then
                    out_val <= current_frame.out2;
                    seq_sm <= PHASE_2;
                end if;                 
                
            -- State 4
            when PHASE_2 => 
                if (presc_ce = '1' and tframe_counter = frame_length - 1) then                                                                           
----------------------------------------------------------------------------------
                    -- TABLE load started 
                    -- Table Repeat is finished 
                    -- = last_fcycle, last_frame, last_tcycle
                    if (last_tcycle = '1') then 
                        out_val <= (others => '0');
                        active <= '0';
                        seq_sm <= WAIT_ENABLE;
                    elsif (last_fcycle = '1') then
                        repeat_count <= to_unsigned(1,32);
                        if (last_frame = '1') then
                            repeat_count <= to_unsigned(1,32);
                            table_count <= table_count + 1;
                            frame_count <= to_unsigned(1,32);  
                        else
                            table_count <= to_unsigned(1,32);
                            frame_count <= frame_count + 1;
                        end if;
                        --
                        if next_trig_valid = '0' then
                            seq_sm <= WAIT_TRIGGER;
                        elsif (next_frame.time1 /= to_unsigned(0,32)) then
                            out_val <= next_frame.out1;
                            seq_sm <= PHASE_1;    
                        else
                            out_val <= next_frame.out2;
                            reset_mem <= '1';
                            current_frame <= next_frame;            -- HERE
                            -- Don't need it but here it is any way
                            seq_sm <= PHASE_2;
                        end if;
                        current_frame <= next_frame;
                        load_next <= '1';
                    else
                        repeat_count <= repeat_count + 1;
                        if (current_trig_valid = '0') then
                            seq_sm <= WAIT_TRIGGER;
                        elsif (current_frame.time1 /= to_unsigned(0,32)) then
                            out_val <= current_frame.out1;
                            seq_sm <= PHASE_1;
                        else
                            out_val <= current_frame.out2;
                            reset_mem <= '1';
                            current_frame <= next_frame;            -- HERE
                            -- Don't need it but here it is any way
                            seq_sm <= PHASE_2;
                        end if;                                                 
                    end if;            
----------------------------------------------------------------------------------
--                    -- TABLE load started 
--                    -- Table Repeat is finished 
--                    -- = last_fcycle, last_frame, last_tcycle
--                    if (last_tcycle = '1') then
--                        out_val <= (others => '0');
--                        active <= '0';
--                        seq_sm <= WAIT_ENABLE;
--                    -- Last frame, but table cycle is not finished, so start over.
--                    elsif (last_frame = '1') then
--                        table_count <= table_count + 1;
--                        current_frame <= next_frame;
--                        load_next <= '1';
--                        if (next_trig_valid = '1') then                  
--                            seq_sm <= PHASE_1;
--                            out_val <= next_frame.out1;
--                            repeat_count <= to_unsigned(1,32);
--                            frame_count <= to_unsigned(1, 16);
--                        else
--                            seq_sm <= WAIT_TRIGGER;
--                        end if;
--                    -- Current Frame Repeat finished, move to next frame. ---- HERE
--                    elsif (last_fcycle = '1') then
--                        current_frame <= next_frame;
--                        load_next <= '1';
--                        if (current_trig_valid = '0') then
--                            seq_sm <= WAIT_TRIGGER;
--                        elsif (next_trig_valid = '1') then
--                            seq_sm <= PHASE_1;
--                            out_val <= next_frame.out1;
--                            frame_count <= frame_count + 1;
--                            repeat_count <= to_unsigned(1,32);
--                        end if;
--                    -- Frame cycle ongoing.
--                    else
--                        if (current_trig_valid = '1') then
--                            seq_sm <= PHASE_1;
--                            out_val <= current_frame.out1;
--                            repeat_count <= repeat_count + 1;
--                        else
--                            repeat_count <= repeat_count + 1;
--                            seq_sm <= WAIT_TRIGGER;
--                        end if;
--                    end if;
                end if;        

            when others =>
                seq_sm <= WAIT_ENABLE;                    
        end case;                    
    end if;
end if;    
end process;

-- Repeats count equals the number of repeats
last_fcycle <= '1' when (current_frame.repeats /= 0 and repeat_count = current_frame.repeats) else '0';
-- Number of frames memory depth
last_frame <= last_fcycle when (frame_count = unsigned(TABLE_FRAMES)) else '0';
-- 
last_tcycle <= last_frame when (REPEATS /= X"0000_0000" and table_count = unsigned(REPEATS)) else '0';

--------------------------------------------------------------------------
-- Prescaler:
--  On a trigger event, a reset is applied to synchronise CE pulses with the
--  trigger input.
--  clk_cnt := (0=>'1', others => '0');
--------------------------------------------------------------------------

--------------------presc_reset <= '1' when (seq_sm = WAIT_TRIGGER and current_trig_valid = '1') else '0';
presc_reset <= '1' when (seq_sm = WAIT_TRIGGER and current_trig_valid = '1') or 
                        (seq_sm = WAIT_ENABLE and current_trig_valid = '1') or 
                        (seq_sm = LOAD_TABLE) else '0';

seq_presc : entity work.sequencer_prescaler
port map (
    clk_i       => clk_i,
    reset_i     => presc_reset,
    PERIOD      => PRESCALE, 
    pulse_o     => presc_ce
);

--------------------------------------------------------------------------
-- Frame counter :
--  On a trigger event, a reset is applied to synchronise counter with the
--  trigger input. Counter stays synchronous during Phase 1 + Phase 2 states
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            tframe_counter <= (others => '0');
        else
            if (presc_reset = '1') then
                tframe_counter <= (others => '0');
            elsif (presc_ce = '1') then 
                if (tframe_counter = frame_length - 1) then
                    tframe_counter <= (others => '0');
                else
                    tframe_counter <= tframe_counter + 1;
                end if;
            end if;
        end if;
    end if;
end process;

-- Block Status
table_line_o   <= X"0000" & std_logic_vector(frame_count);
line_repeat_o <= std_logic_vector(repeat_count);
table_repeat_o  <= std_logic_vector(table_count);

-- Gated Block Outputs.
outa_o <= out_val(0);
outb_o <= out_val(1);
outc_o <= out_val(2);
outd_o <= out_val(3);
oute_o <= out_val(4);
outf_o <= out_val(5);
active_o <= active;


end rtl;

