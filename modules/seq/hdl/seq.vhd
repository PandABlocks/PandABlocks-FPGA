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
    HEALTH              : out std_logic_vector(31 downto 0) := (others => '0');
    PRESCALE            : in  std_logic_vector(31 downto 0);
    REPEATS             : in  std_logic_vector(31 downto 0);
    -- Block Status
    TABLE_LINE          : out std_logic_vector(31 downto 0);
    LINE_REPEAT         : out std_logic_vector(31 downto 0);
    TABLE_REPEAT        : out std_logic_vector(31 downto 0);
    STATE               : out std_logic_vector(31 downto 0);
    -- DMA configuration
    TABLE_ADDRESS       : in  std_logic_vector(31 downto 0);
    TABLE_ADDRESS_WSTB  : in  std_logic;
    TABLE_LENGTH        : in  std_logic_vector(31 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic;
    -- DMA Engine Interface
    dma_req_o           : out std_logic;
    dma_ack_i           : in  std_logic;
    dma_done_i          : in  std_logic;
    dma_addr_o          : out std_logic_vector(31 downto 0);
    dma_len_o           : out std_logic_vector(7 downto 0);
    dma_data_i          : in  std_logic_vector(31 downto 0);
    dma_valid_i         : in  std_logic;
    dma_irq_o           : out std_logic;
    dma_done_irq_o      : out std_logic
);
end seq;

architecture rtl of seq is

----constant SEQ_FRAMES         : positive := 1024;
constant SEQ_FRAMES         : positive := 4096;

signal TABLE_FRAMES         : std_logic_vector(18 downto 0);

signal next_frame           : seq_t;
signal current_frame        : seq_t := ZERO_SEQ_FRAME;
signal load_next            : std_logic;

signal tframe_counter       : unsigned(31 downto 0);
signal LINE_REPEAT_OUT      : unsigned(31 downto 0) := (others => '0');
signal TABLE_LINE_OUT       : unsigned(18 downto 0) := (others => '0');
signal TABLE_REPEAT_OUT     : unsigned(31 downto 0) := (others => '0');

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

signal last_table_line      : std_logic := '0';
signal last_line_repeat     : std_logic := '0';
signal last_table_repeat    : std_logic := '0';

signal current_pos_en       : std_logic_vector(2 downto 0);
signal next_pos_en          : std_logic_vector(2 downto 0);

signal current_pos_inp      : std_logic;
signal next_pos_inp         : std_logic;

signal next_ts              : unsigned(31 downto 0);

signal start : std_logic := '0';
signal frame_valid : std_logic;
signal transfer_busy : std_logic;
signal frames_room : std_logic_vector(11 downto 0);
signal error_event : std_logic := '0';
signal underrun_event : std_logic := '0';
signal overrun_event : std_logic := '0';
signal abort_dma : std_logic := '0';
signal resetting_dma : std_logic := '0';
signal data_last : std_logic;
signal next_frame_last : std_logic;
signal current_frame_last : std_logic := '0';
signal streaming_mode : std_logic;
signal one_buffer_mode : std_logic;
signal wrapping_mode : std_logic;
signal wrapping_mode_reset : std_logic;

begin

-- Block inputs.
enable_val <= enable_i;

-- Input register and edge detection.
Registers : process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_val;
    end if;
end process;

enable_fall <= not enable_val and enable_prev;
enable_rise <= enable_val and not enable_prev;

--------------------------------------------------------------------------
-- Sequencer TABLE keeps frame configuration data
--------------------------------------------------------------------------
sequencer_ring_table : entity work.sequencer_ring_table generic map (
    SEQ_LEN => SEQ_FRAMES
) port map (
    clk_i => clk_i,
    reset_i => resetting_dma or wrapping_mode_reset,
    frame_ready_i => load_next,
    frame_valid_o => frame_valid,
    frame_o  => next_frame,
    frame_last_o => next_frame_last,
    available_o => frames_room,
    wrapping_mode_i => wrapping_mode,
    data_i  => dma_data_i,
    data_valid_i => dma_valid_i,
    data_last_i => data_last,
    -- we always have room because we push based on available space
    data_ready_o => open,
    nframes_o => open
);

error_event <= underrun_event or overrun_event;
underrun_event <= load_next and not frame_valid;
wrapping_mode <= to_std_logic(
    unsigned(TABLE_FRAMES) < SEQ_FRAMES and one_buffer_mode = '1' and
    resetting_dma = '0');

tre_client: entity work.table_read_engine_client port map (
    clk_i => clk_i,
    abort_i => abort_dma,
    address_i => TABLE_ADDRESS,
    length_i => TABLE_LENGTH,
    length_wstb_i => TABLE_LENGTH_WSTB,
    completed_o => open,
    available_i => x"0000" & "00" & frames_room & "00",
    overflow_error_o => overrun_event,
    busy_o => transfer_busy,
    resetting_o => resetting_dma,
    last_o => data_last,
    streaming_mode_o => streaming_mode,
    one_buffer_mode_o => one_buffer_mode,
    loop_one_buffer_i => not wrapping_mode,
    -- DMA Engine Interface
    dma_req_o => dma_req_o,
    dma_ack_i => dma_ack_i,
    dma_done_i => dma_done_i,
    dma_addr_o => dma_addr_o,
    dma_len_o => dma_len_o,
    dma_data_i => dma_data_i,
    dma_valid_i => dma_valid_i,
    dma_irq_o => dma_irq_o,
    dma_done_irq_o => dma_done_irq_o
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

-- combinatorial logic so we can load a new row in 1 clock tick
-- comments in SEQ_FSM shows where this logically sits
load_next <= '1' when
    (seq_sm = WAIT_ENABLE and enable_rise = '1')
    or (seq_sm = PHASE_2 and presc_ce = '1' and tframe_counter = next_ts - 1
        and last_line_repeat = '1' and last_table_repeat = '0') else '0';

SEQ_FSM : process(clk_i)
    procedure reset_repeat_count(val: integer) is
    begin
        TABLE_REPEAT_OUT <= to_unsigned(val, 32);
        TABLE_LINE_OUT <= to_unsigned(val, TABLE_LINE_OUT'length);
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
            current_frame_last <= next_frame_last;
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
    abort_dma <= '0';
    wrapping_mode_reset <= '0';
    if enable_fall or error_event then
        out_val <= (others => '0');
        active <= '0';
        if seq_sm /= UNREADY and seq_sm /= WAIT_ENABLE then
            if wrapping_mode and not error_event then
                seq_sm <= WAIT_ENABLE;
                wrapping_mode_reset <= '1';
            else
                seq_sm <= UNREADY;
                abort_dma <= '1';
            end if;
        end if;
        reset_repeat_count(0);
    else
        -- State Machine
        case seq_sm is
            when UNREADY =>
                out_val <= (others => '0');
                if frame_valid and not resetting_dma then
                    seq_sm <= WAIT_ENABLE;
                end if;

            when WAIT_ENABLE =>
                if not frame_valid then
                    seq_sm <= UNREADY;
                -- load_next fires here
                elsif enable_rise then
                    -- go to next state loading next frame and considering
                    -- triggers
                    goto_next_state(true, true);
                    reset_repeat_count(1);
                    active <= '1';
                end if;

            when WAIT_TRIGGER =>
                -- trigger met
                if current_trig_valid = '1' then
                    -- go to next state without loading next frame and skipping
                    -- triggers (as they are already evaluated)
                    goto_next_state(false, false);
                end if;

            when PHASE_1 =>
                --time 1 elapsed
                if presc_ce = '1' and tframe_counter = next_ts - 1 then
                    goto_phase_2(current_frame);
                end if;

            when PHASE_2 =>
                if presc_ce = '1' and tframe_counter = next_ts - 1 then
                    -- TABLE load started
                    -- Table Repeat is finished
                    -- = last_line_repeat, last_table_line, last_table_repeat
                    if last_table_repeat then
                        active <= '0';
                        out_val <= (others => '0');
                        seq_sm <= UNREADY when streaming_mode else WAIT_ENABLE;
                    elsif last_line_repeat then
                        LINE_REPEAT_OUT <= to_unsigned(1, 32);
                        if last_table_line then
                            TABLE_LINE_OUT <=
                                to_unsigned(1, TABLE_LINE_OUT'length);
                            if one_buffer_mode then
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
                seq_sm <= UNREADY;
        end case;
    end if;
end if;
end process;

-- Health keeping process
process (clk_i)
begin
    if rising_edge(clk_i) then
        if error_event = '1' and HEALTH(1 downto 0) = "00" then
            HEALTH(1 downto 0) <=  c_table_error_underrun when underrun_event else
                                   c_table_error_overrun when overrun_event else
                                   c_table_error_ok;
        elsif seq_sm = WAIT_ENABLE and enable_rise = '1' then
            HEALTH(1 downto 0) <= c_table_error_ok;
        end if;
    end if;
end process;

-- Repeats count equals the number of repeats (Last Table Repeat)
last_line_repeat <= '1' when
    (current_frame.repeats /= 0 and
     LINE_REPEAT_OUT = current_frame.repeats) else '0';
-- Number of frames memory depth (Last Line )
last_table_line <= last_line_repeat when
    (one_buffer_mode = '1' and TABLE_LINE_OUT = unsigned(TABLE_FRAMES)) or
     current_frame_last = '1' else '0';
TABLE_FRAMES <= TABLE_LENGTH(20 downto 2);
-- Last Table Repeat
last_table_repeat <= last_table_line when 
    (streaming_mode = '0' and REPEATS /= X"0000_0000" and
     TABLE_REPEAT_OUT = unsigned(REPEATS)) or streaming_mode = '1' else '0';

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
TABLE_LINE   <= std_logic_vector(resize(TABLE_LINE_OUT, TABLE_LINE'length));
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

