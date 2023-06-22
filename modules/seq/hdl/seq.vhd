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
use work.sequencer_defines.all;


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
    HEALTH              : out std_logic_vector(31 downto 0);
    PRESCALE            : in  std_logic_vector(31 downto 0);
    TABLE_START         : in  std_logic_vector(31 downto 0);
    TABLE_START_WSTB    : in  std_logic;
    TABLE_DATA          : in  std_logic_vector(31 downto 0);
    TABLE_DATA_WSTB     : in  std_logic;
    REPEATS             : in  std_logic_vector(31 downto 0);
    TABLE_LENGTH        : in  std_logic_vector(31 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic;
    -- Block Status
    TABLE_LINE          : out std_logic_vector(31 downto 0);
    LINE_REPEAT         : out std_logic_vector(31 downto 0);
    TABLE_REPEAT        : out std_logic_vector(31 downto 0);
    CAN_WRITE_NEXT      : out std_logic_vector(31 downto 0);
    STATE               : out std_logic_vector(31 downto 0)
);
end seq;

architecture rtl of seq is

----constant SEQ_FRAMES         : positive := 1024;
constant SEQ_FRAMES         : positive := 4096;

signal TABLE_FRAMES         : std_logic_vector(15 downto 0);

signal next_frame           : seq_t;
signal current_frame        : seq_t;
signal can_write_next_val   : std_logic;
signal next_table_expected  : std_logic;
signal last_frame_in_table  : std_logic;
-- this is aligned to current frame
signal current_next_table_expected : std_logic := '0';
signal current_last_frame_in_table : std_logic := '0';
signal load_next            : std_logic;

signal tframe_counter       : unsigned(31 downto 0);
signal LINE_REPEAT_OUT      : unsigned(31 downto 0);
signal TABLE_LINE_OUT       : unsigned(15 downto 0);
signal TABLE_REPEAT_OUT     : unsigned(31 downto 0);

type state_t is (UNREADY, WAIT_ENABLE, PHASE_1, PHASE_2, WAIT_TRIGGER);
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
signal table_error          : std_logic;
signal table_error_prev     : std_logic;
signal table_error_rise     : std_logic;
signal table_error_type     : std_logic_vector(3 downto 0);
signal reset_tables         : std_logic := '0';
signal reset_error          : std_logic := '0';

signal last_table_line      : std_logic := '0';
signal last_line_repeat     : std_logic := '0';
signal last_table_repeat    : std_logic := '0';

signal current_pos_en       : std_logic_vector(2 downto 0);
signal next_pos_en          : std_logic_vector(2 downto 0);

signal current_pos_inp      : std_logic;
signal next_pos_inp         : std_logic;

signal enable_mem_reset     : std_logic;
signal next_ts              : unsigned(31 downto 0);
signal health_val           : std_logic_vector(31 downto 0) := (others => '0');
signal start_not_expected   : std_logic;
signal running              : std_logic;
signal sudden_next_table_event : std_logic;
signal sudden_next_table_event_dly : std_logic := '0';

begin

-- Block inputs.
enable_val <= enable_i;

CAN_WRITE_NEXT(0) <= can_write_next_val and next_table_expected;
CAN_WRITE_NEXT(31 downto 1) <= (others => '0');

delay : process(clk_i)
begin
    if rising_edge(clk_i) then
        sudden_next_table_event_dly <= sudden_next_table_event;
    end if;
end process;

-- Input register and edge detection.
Registers : process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_val;
        table_error_prev <= table_error;
    end if;
end process;

enable_fall <= not enable_val and enable_prev;
enable_rise <= enable_val and not enable_prev;
table_error_rise <= table_error and not table_error_prev;

-- Table length is written in terms of DWORDs, and a frame is composed
-- of 4x DWORDs
TABLE_FRAMES <= "00" & TABLE_LENGTH(15 downto 2);

--------------------------------------------------------------------------
-- Sequencer TABLE keeps frame configuration data
--------------------------------------------------------------------------
sequencer_table : entity work.sequencer_double_table
generic map (
    SEQ_LEN             => SEQ_FRAMES
) port map (
    clk_i               => clk_i,
    reset_tables_i      => reset_tables,
    reset_error_i       => reset_error,

    load_next_i         => load_next,
    table_ready_o       => table_ready,
    frame_o             => next_frame,
    last_o              => last_frame_in_table,
    can_write_next_o    => can_write_next_val,
    next_expected_o     => next_table_expected,
    error_o             => table_error,
    error_type_o        => table_error_type,

    TABLE_START         => TABLE_START_WSTB,
    TABLE_DATA          => TABLE_DATA,
    TABLE_WSTB          => TABLE_DATA_WSTB,
    TABLE_FRAMES        => TABLE_FRAMES,
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

STATE(2 downto 0)   <= c_state_idle when seq_sm = UNREADY else
                       c_state_wait_trigger when seq_sm = WAIT_TRIGGER else
                       c_state_phase1 when seq_sm = PHASE_1 else
                       c_state_phase2 when seq_sm = phase_2 else
                       c_state_wait_enable;
STATE(31 downto 3) <= (others => '0');

-- we only need the 4 least significant bits to report errors
HEALTH <= health_val;

enable_mem_reset <= '1' when (current_frame.time1 = x"00000000") else '0';


-- combinatorial logic so we can load a new row in 1 clock tick
-- comments in SEQ_FSM shows where this logically sits
load_next <= '1' when
    (seq_sm = WAIT_ENABLE and enable_rise = '1')
    or (seq_sm = PHASE_2 and presc_ce = '1' and tframe_counter = next_ts - 1
        and last_line_repeat = '1')
    or sudden_next_table_event_dly = '1' else '0';

reset_tables <= enable_fall;
reset_error <= table_error_rise;

start_not_expected <=  TABLE_START_WSTB and running and not can_write_next_val;

running <= to_std_logic(seq_sm /= UNREADY and seq_sm /= WAIT_ENABLE);
-- detects when we are reading a LAST table and suddenly the next table
-- gets written
sudden_next_table_event <=
    not current_next_table_expected and TABLE_LENGTH_WSTB and running;

SEQ_FSM : process(clk_i)
    procedure reset_repeat_count(val: integer) is
    begin
        TABLE_REPEAT_OUT <= to_unsigned(val, 32);
        TABLE_LINE_OUT <= to_unsigned(val, 16);
        LINE_REPEAT_OUT <= to_unsigned(val, 32);
    end procedure;

    procedure goto_phase_1(frame: seq_t) is
    begin
        next_ts <= frame.time1;
        out_val <= frame.out1;
        seq_sm <= PHASE_1;
    end procedure;

    procedure goto_phase_2(frame: seq_t) is
    begin
        if frame.time2 /= 0 then
            next_ts <= frame.time2;
        else
            next_ts <= to_unsigned(1, 32);
        end if;
        out_val <= frame.out2;
        seq_sm <= PHASE_2;
    end procedure;

    procedure goto_next_state(need_next_frame : boolean;
                              consider_triggers : boolean) is
        variable frame : seq_t;
        variable triggered : std_logic;
    begin
        if need_next_frame then
            frame := next_frame;
            triggered := next_trig_valid;
            current_frame <= next_frame;
            current_next_table_expected <= next_table_expected;
            current_last_frame_in_table <= last_frame_in_table;
        else
            frame := current_frame;
            triggered := current_trig_valid;
        end if;

        if triggered = '0' and consider_triggers then
            seq_sm <= WAIT_TRIGGER;
        elsif frame.time1 /= 0 then
            goto_phase_1(frame);
        else
            goto_phase_2(frame);
        end if;

    end procedure;

begin
if rising_edge(clk_i) then
    --
    -- Sequencer State Machine
    --

    if enable_fall = '1' then
        out_val <= (others => '0');
        active <= '0';
        if table_ready = '1' then
            seq_sm <= WAIT_ENABLE;
        else
            seq_sm <= UNREADY;
        end if;
    elsif table_error_rise = '1' then
        out_val <= (others => '0');
        active <= '0';
        seq_sm <= UNREADY;
        health_val(3 downto 0) <=  table_error_type;
    elsif start_not_expected = '1' then
        out_val <= (others => '0');
        active <= '0';
        seq_sm <= UNREADY;
        health_val(3 downto 0) <=  c_table_error_overrun;
        reset_repeat_count(0);
    elsif sudden_next_table_event_dly = '1' then
        -- go to next state loading next frame and considering triggers
        goto_next_state(true, true);
        reset_repeat_count(1);
    else
        -- State Machine
        case seq_sm is
            -- State 0
            when UNREADY =>
                out_val <= (others => '0');
                if table_ready = '1' then
                    seq_sm <= WAIT_ENABLE;
                end if;

                if TABLE_START_WSTB = '1' then
                    reset_repeat_count(0);
                end if;

            when WAIT_ENABLE =>
                if table_ready = '0' then
                    seq_sm <= UNREADY;
                elsif TABLE_START_WSTB = '1' and can_write_next_val = '0' then
                    reset_repeat_count(0);
                -- load_next fires here
                elsif enable_rise = '1' then
                    -- go to next state loading next frame and considering
                    -- triggers
                    goto_next_state(true, true);
                    reset_repeat_count(1);
                    health_val(3 downto 0) <= c_table_error_ok;
                    active <= '1';
                end if;

            -- State 2
            when WAIT_TRIGGER =>
                -- trigger met
                if current_trig_valid = '1' then
                    -- go to next state without loading next frame and skipping
                    -- triggers (as they are already evaluated)
                    goto_next_state(false, false);
                end if;

            -- State 3
            when PHASE_1 =>
                --time 1 elapsed
                if presc_ce = '1' and tframe_counter = next_ts - 1 then
                    goto_phase_2(current_frame);
                end if;

            -- State 4
            when PHASE_2 =>
                if presc_ce = '1' and tframe_counter = next_ts - 1 then
                    -- TABLE load started
                    -- Table Repeat is finished
                    -- = last_line_repeat, last_table_line, last_table_repeat
                    if last_table_repeat = '1' then
                        active <= '0';
                        out_val <= (others => '0');
                        seq_sm <= WAIT_ENABLE;
                    elsif last_line_repeat = '1' then
                        LINE_REPEAT_OUT <= to_unsigned(1,32);
                        if last_table_line = '1' then
                            TABLE_LINE_OUT <= to_unsigned(1,16);
                            if current_next_table_expected = '0' then
                                TABLE_REPEAT_OUT <= TABLE_REPEAT_OUT + 1;
                            end if;
                        else
                            TABLE_LINE_OUT <= TABLE_LINE_OUT + 1;
                        end if;
                        -- go to next state loading next frame and considering
                        -- triggers
                        goto_next_state(true, true);
                    else
                        LINE_REPEAT_OUT <= LINE_REPEAT_OUT + 1;
                        -- go to next state without loading next frame and
                        -- considering triggers
                        goto_next_state(false, true);
                    end if;
                end if;

            when others =>
                seq_sm <= WAIT_ENABLE;
        end case;
    end if;
end if;
end process;

-- Repeats count equals the number of repeats (Last Table Repeat)
last_line_repeat <= '1' when (current_frame.repeats /= 0 and LINE_REPEAT_OUT = current_frame.repeats) else '0';
-- Number of frames memory depth (Last Line )
last_table_line <= last_line_repeat when current_last_frame_in_table = '1' else '0';
-- Last Table Repeat
last_table_repeat <= last_table_line when
    (REPEATS /= X"0000_0000" and TABLE_REPEAT_OUT = unsigned(REPEATS)
     and current_next_table_expected = '0') else '0';

--------------------------------------------------------------------------
-- Prescaler:
--  On a trigger event, a reset is applied to synchronise CE pulses with the
--  trigger input.
--  clk_cnt := (0=>'1', others => '0');
--------------------------------------------------------------------------

presc_reset <= '1' when seq_sm = WAIT_TRIGGER
                     or seq_sm = WAIT_ENABLE
                     or seq_sm = UNREADY
                     or load_next = '1' else '0';

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
        if presc_reset = '1' then
            tframe_counter <= (others => '0');
        elsif presc_ce = '1' then
            if tframe_counter = next_ts - 1 then
                tframe_counter <= (others => '0');
            else
                tframe_counter <= tframe_counter + 1;
            end if;
        end if;
    end if;
end process;

-- Block Status
TABLE_LINE   <= X"0000" & std_logic_vector(TABLE_LINE_OUT);
LINE_REPEAT <= std_logic_vector(LINE_REPEAT_OUT);
TABLE_REPEAT  <= std_logic_vector(TABLE_REPEAT_OUT);

-- Gated Block Outputs.
outa_o <= out_val(0);
outb_o <= out_val(1);
outc_o <= out_val(2);
outd_o <= out_val(3);
oute_o <= out_val(4);
outf_o <= out_val(5);
active_o <= active;

end rtl;

