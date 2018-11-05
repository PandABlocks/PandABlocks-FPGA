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

entity seq is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
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
    TABLE_LENGTH        : in  std_logic_vector(31 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic;
    -- Block Status
    table_line          : out std_logic_vector(31 downto 0);        
    line_repeat         : out std_logic_vector(31 downto 0);        
    table_repeat        : out std_logic_vector(31 downto 0);
    state               : out std_logic_vector(2 downto 0)         
);
end seq;

architecture rtl of seq is

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

signal reset_i              : std_logic := '0';

signal TABLE_FRAMES         : std_logic_vector(15 downto 0);

signal current_frame        : seq_t;
signal next_frame           : seq_t;
signal load_next            : std_logic;

signal tframe_counter       : unsigned(31 downto 0);
signal LINE_REPEAT_o        : unsigned(31 downto 0);
signal TABLE_LINE_o         : unsigned(15 downto 0);
signal TABLE_REPEAT_o       : unsigned(31 downto 0);

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
signal reset_table          : std_logic;

signal last_table_line      : std_logic := '0';
signal last_line_repeat     : std_logic := '0';
signal last_table_repeat    : std_logic := '0';

signal current_pos_en       : std_logic_vector(2 downto 0);
signal next_pos_en          : std_logic_vector(2 downto 0);

signal current_pos_inp      : std_logic;
signal next_pos_inp         : std_logic;

signal enable_mem_reset     : std_logic;
signal table_ready_dly      : std_logic;

signal next_ts              : unsigned(31 downto 0);

begin

-- Block inputs.
----enable_val <= enable_i and table_ready;
enable_val <= enable_i and table_ready_dly;

delay : process(clk_i)
begin
    if rising_edge(clk_i) then
        table_ready_dly <= table_ready;
    end if;
end process;         

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
    reset_i             => reset_table,

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

-- Next triggers equal or greater than or less than   
next_pos_en(0) <= '1' when (next_frame.trigger = c_posa_gt_position and signed(posa_i) >= next_frame.position) or
                           (next_frame.trigger = c_posa_lt_position and signed(posa_i) <= next_frame.position) else '0';
next_pos_en(1) <= '1' when (next_frame.trigger = c_posb_gt_position and signed(posb_i) >= next_frame.position) or                            
                           (next_frame.trigger = c_posb_lt_position and signed(posb_i) <= next_frame.position) else '0';
next_pos_en(2) <= '1' when (next_frame.trigger = c_posc_gt_position and signed(posc_i) >= next_frame.position) or
                           (next_frame.trigger = c_posc_lt_position and signed(posc_i) <= next_frame.position) else '0';                            

-- Two next triggers 1 XNOR and 2 equal to or greater than or less than   
next_pos_inp <= '1' when (next_inp_val = "111") or (next_pos_en /= "000") else '0';

-- Three next triggers 1 2 and 3 next trigger immediately  
next_trig_valid <= '1' when ((next_frame.trigger = c_immediately) or (next_pos_inp = '1')) else '0';

-- Current xnor triggers
current_inp_val <= ("000") xnor ("00" & bita_i) when current_frame.trigger = c_bita_0 else
                   ("001") xnor ("00" & bita_i) when current_frame.trigger = c_bita_1 else
                   ("000") xnor ('0' & bitb_i & '0') when current_frame.trigger = c_bitb_0 else
                   ("010") xnor ('0' & bitb_i & '0') when current_frame.trigger = c_bitb_1 else
                   ("000") xnor (bitc_i & "00") when current_frame.trigger = c_bitc_0 else
                   ("100") xnor (bitc_i & "00") when current_frame.trigger = c_bitc_1 else
                   ("000");

-- current triggers equal or greater than or less than
current_pos_en(0) <= '1' when (current_frame.trigger = c_posa_gt_position and signed(posa_i) >= current_frame.position) or
                              (current_frame.trigger = c_posa_lt_position and signed(posa_i) <= current_frame.position) else '0'; 
current_pos_en(1) <= '1' when (current_frame.trigger = c_posb_gt_position and signed(posb_i) >= current_frame.position) or
                              (current_frame.trigger = c_posb_lt_position and signed(posb_i) <= current_frame.position) else '0';
current_pos_en(2) <= '1' when (current_frame.trigger = c_posc_gt_position and signed(posc_i) >= current_frame.position) or
                              (current_frame.trigger = c_posc_lt_position and signed(posc_i) <= current_frame.position) else '0';                                  

-- Two current triggers 1 XNOR and 2 equal to or greater than or less than
current_pos_inp <= '1' when (current_inp_val = "111") or (current_pos_en /= "000") else '0';

-- Three current triggers 1 2 and current trigger immediately
current_trig_valid <= '1' when ((current_frame.trigger = c_immediately) or (current_pos_inp = '1')) else '0';  


--------------------------------------------------------------------------
-- Sequencer State Machine
-------------------------------------------------------------------------


state   <= c_state_load_table when seq_sm = LOAD_TABLE else
           c_state_wait_trigger when seq_sm = WAIT_TRIGGER else
           c_state_phase1 when seq_sm = PHASE_1 else
           c_state_phase2 when seq_sm = phase_2 else
           c_state_wait_enable;
                    

enable_mem_reset <= '1' when (current_frame.time1 = x"00000000") else '0'; 


SEQ_FSM : process(clk_i)
begin
if rising_edge(clk_i) then
    --
    -- Sequencer State Machine
    --
    load_next <= '0';

    -- Reset all registers and state machine.
    if (reset_i = '1') then
        seq_sm <= WAIT_ENABLE;
        out_val <= (others => '0');        
        active <= '0';
        LINE_REPEAT_o <= (others => '0');
        TABLE_LINE_o <= (others => '0');
        TABLE_REPEAT_o <= (others => '0');
    elsif (TABLE_START = '1') then
        out_val <= (others => '0');
        seq_sm <= LOAD_TABLE;
    elsif (enable_fall = '1' and enable_i = '0') then
        out_val <= (others => '0');      
        active <= '0';  
        if seq_sm /= LOAD_TABLE then
            reset_table <= '1';
            seq_sm <= WAIT_ENABLE;            
        end if;
    else                    
        -- State Machine            
        case seq_sm is
                
            -- State 0
            when WAIT_ENABLE =>
                -- TABLE load_started
                reset_table <= '0';
                if enable_rise = '1' then    
                    -- rising ENABLE and trigger not met 
                    if (next_trig_valid  = '0') then   
                        seq_sm <= WAIT_TRIGGER;                        
                    -- rising ENABLE and trigger met phase1
                    elsif (next_frame.time1 /= to_unsigned(0,32)) then    
                        next_ts <= next_frame.time1;
                        out_val <= next_frame.out1;     
                        seq_sm <= PHASE_1;            
                    -- rising ENABLE and trigger met and no phase 1
                    else
                        next_ts <= next_frame.time2;
                        out_val <= next_frame.out2;    
                        seq_sm <= PHASE_2;
                    end if;    
                    TABLE_REPEAT_o <= to_unsigned(1,32);       
                    TABLE_LINE_o <= to_unsigned(1,16);     
                    LINE_REPEAT_o <= to_unsigned(1,32);   
                    current_frame <= next_frame;
                    load_next <= '1';
                    active <= '1'; 
                end if;    
                       
            -- State 1
            when LOAD_TABLE =>    
                -- TABLE load complete
                if table_ready = '1' then
                    seq_sm <= WAIT_ENABLE;
                end if;

            -- State 2
            when WAIT_TRIGGER => 
                -- trigger met
                if (current_trig_valid = '1') then
                    -- trigger met
                    if (current_frame.time1 /= to_unsigned(0,32)) then  
                        next_ts <= current_frame.time1;
                        out_val <= current_frame.out1;
                        active <= '1';                    
                        seq_sm <= PHASE_1;
                    -- trigger met and no phase 1
                    else
                        next_ts <= current_frame.time2;
                        active <= '1';
                        out_val <= current_frame.out2;
                        seq_sm <= PHASE_2;        
                    end if;
                end if;            
                                
            -- State 3
            when PHASE_1 =>   
                --time 1 elapsed                     
                if (presc_ce = '1' and tframe_counter = next_ts -1) then    
                    next_ts <= current_frame.time2;
                    out_val <= current_frame.out2;
                    seq_sm <= PHASE_2;
                end if;                 
                
            -- State 4
            when PHASE_2 => 
                if (presc_ce = '1' and tframe_counter = next_ts -1) then   
                    -- TABLE load started 
                    -- Table Repeat is finished 
                    -- = last_line_repeat, last_table_line, last_table_repeat
                    if (last_table_repeat = '1') then 
                        active <= '0';
                        out_val <= (others => '0');
                        reset_table <= '1';
                        seq_sm <= WAIT_ENABLE;
                    elsif (last_line_repeat = '1') then
                        LINE_REPEAT_o <= to_unsigned(1,32);
                        if (last_table_line = '1') then
                            TABLE_LINE_o <= to_unsigned(1,16);       
                            TABLE_REPEAT_o <= TABLE_REPEAT_o + 1;     
                        else
                            TABLE_LINE_o <= TABLE_LINE_o + 1;     
                        end if;
                        -- No trigger ready so go to the wait state
                        if next_trig_valid = '0' then
                            seq_sm <= WAIT_TRIGGER;
                        -- Trigger ready for PHASE 1     
                        elsif (next_frame.time1 /= to_unsigned(0,32)) then
                            next_ts <= next_frame.time1;
                            out_val <= next_frame.out1;
                            seq_sm <= PHASE_1;    
                        -- Stay in PHASE 2 state    
                        else
                            next_ts <= next_frame.time2;
                            out_val <= next_frame.out2;
                            -- Don't need it but here it is any way
                            seq_sm <= PHASE_2;
                        end if;
                        current_frame <= next_frame;
                        load_next <= '1';
                    else
                        LINE_REPEAT_o <= LINE_REPEAT_o + 1;
                        -- No trigger active so go and wait
                        if (current_trig_valid = '0') then
                            seq_sm <= WAIT_TRIGGER;
                        -- Trigger ready for PHASE 1     
                        elsif (current_frame.time1 /= to_unsigned(0,32)) then
                            next_ts <= current_frame.time1;
                            out_val <= current_frame.out1;
                            seq_sm <= PHASE_1;
                        -- Stay in PHASE 2 state    
                        else
                            next_ts <= current_frame.time2;
                            out_val <= current_frame.out2;
                            -- Don't need it but here it is any way
                            seq_sm <= PHASE_2;
                        end if;                                                 
                    end if;            
                end if;        

            when others =>
                seq_sm <= WAIT_ENABLE;                    
        end case;                    
    end if;
end if;    
end process;

-- Repeats count equals the number of repeats (Last Table Repeat)
last_line_repeat <= '1' when (current_frame.repeats /= 0 and LINE_REPEAT_o = current_frame.repeats) else '0';
-- Number of frames memory depth (Last Line )
last_table_line <= last_line_repeat when (TABLE_LINE_o = unsigned(TABLE_FRAMES)) else '0';
-- Last Table Repeat
last_table_repeat <= last_table_line when (REPEATS /= X"0000_0000" and TABLE_REPEAT_o = unsigned(REPEATS)) else '0';

--------------------------------------------------------------------------
-- Prescaler:
--  On a trigger event, a reset is applied to synchronise CE pulses with the
--  trigger input.
--  clk_cnt := (0=>'1', others => '0');
--------------------------------------------------------------------------

presc_reset <= '1' when (seq_sm = WAIT_TRIGGER) or (seq_sm = WAIT_ENABLE) or 
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
                if (tframe_counter = next_ts - 1) then
                    tframe_counter <= (others => '0');
                else
                    tframe_counter <= tframe_counter + 1;
                end if;
            end if;
        end if;
    end if;
end process;

-- Block Status
table_line   <= X"0000" & std_logic_vector(TABLE_LINE_o);
line_repeat <= std_logic_vector(LINE_REPEAT_o);
table_repeat  <= std_logic_vector(TABLE_REPEAT_o);

-- Gated Block Outputs.
outa_o <= out_val(0);
outb_o <= out_val(1);
outc_o <= out_val(2);
outd_o <= out_val(3);
oute_o <= out_val(4);
outf_o <= out_val(5);
active_o <= active;


end rtl;

