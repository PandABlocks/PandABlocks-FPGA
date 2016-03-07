--------------------------------------------------------------------------------
--  File:       sequencer.vhd
--  Desc:       Programmable Sequencer.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
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
    inpa_i              : in  std_logic;
    inpb_i              : in  std_logic;
    inpc_i              : in  std_logic;
    inpd_i              : in  std_logic;
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
    TABLE_CYCLE         : in  std_logic_vector(31 downto 0);
    TABLE_LENGTH        : in  std_logic_vector(15 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic;
    -- Block Status
    CUR_FRAME           : out std_logic_vector(31 downto 0);
    CUR_FCYCLE          : out std_logic_vector(31 downto 0);
    CUR_TCYCLE          : out std_logic_vector(31 downto 0)
);
end sequencer;

architecture rtl of sequencer is

constant SEQ_LEN            : positive := 4 * 512;
constant SEQ_AW             : positive := 11;           -- log2(SEQ_LEN)

signal TABLE_FRAMES         : std_logic_vector(15 downto 0);

signal current_frame        : seq_t;
signal next_frame           : seq_t;
signal load_next            : std_logic;

signal tframe_counter       : unsigned(31 downto 0);
signal repeat_count         : unsigned(31 downto 0);
signal frame_count          : unsigned(15 downto 0);
signal table_count          : unsigned(31 downto 0);
signal frame_length         : unsigned(31 downto 0);

type state_t is (WAIT_TRIGGER, PHASE_1, PHASE_2);
signal seq_sm               : state_t;

signal inp_val              : std_logic_vector(3 downto 0);
signal out_val              : std_logic_vector(5 downto 0);
signal active               : std_logic := '0';
signal current_trig         : std_logic_vector(3 downto 0);
signal current_trig_valid   : std_logic;
signal next_trig            : std_logic_vector(3 downto 0);
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

signal ongoing_frame        : std_logic;

begin

-- Convert # of DWORDs to # of Frames.
TABLE_FRAMES <= "00" & TABLE_LENGTH(15 downto 2);

-- Block inputs.
inp_val <= inpd_i & inpc_i & inpb_i & inpa_i;
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

--
-- Sequencer TABLE interface
--
sequencer_table : entity work.sequencer_table
port map (
    clk_i               => clk_i,
    reset_i             => fsm_reset,

    load_next_i         => load_next,
    table_ready_o       => table_ready,
    next_frame_o        => next_frame,

    TABLE_START         => TABLE_START,
    TABLE_DATA          => TABLE_DATA,
    TABLE_WSTB          => TABLE_WSTB,
    TABLE_LENGTH        => TABLE_FRAMES,
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB
);

-- Current trigger match condition is used during the execution of a frame.
current_trig <= (current_frame.trig_cond xnor inp_val) or not current_frame.trig_mask;

current_trig_valid <= '1' when (current_frame.trig_mask /= "0000" and
                                current_trig = "1111") else '0';

-- Next trigger match condition is during a transition to the next frame so that 
-- there is no gap between frames.
next_trig <= (next_frame.trig_cond xnor inp_val) or not next_frame.trig_mask;

next_trig_valid <= '1' when (next_frame.trig_mask /= "0000" and
                                next_trig = "1111") else '0';

-- Reset condition for state machine.
fsm_reset <= '1' when (reset_i = '1' or TABLE_START = '1' or enable_fall = '1')
             else '0';

-- Total frame length
frame_length <= current_frame.ph1_time + current_frame.ph2_time;

SEQ_FSM : process(clk_i)
begin
if rising_edge(clk_i) then
    --
    -- Sequencer State Machine
    --
    load_next <= '0';

    -- Reset all registers and state machine.
    if (fsm_reset = '1') then
        seq_sm <= WAIT_TRIGGER;
        out_val <= (others => '0');
        active <= '0';
        repeat_count <= (others => '0');
        frame_count <= (others => '0');
        table_count <= (others => '0');
        ongoing_frame <= '0';
    -- Gate rise latches first frame, and set block active.
    elsif (enable_rise = '1') then
        current_frame <= next_frame;
        load_next <= '1';
        active <= '1';
        repeat_count <= repeat_count + 1;
        frame_count <= frame_count + 1;
        table_count <= table_count + 1;
        -- In case trigger happens at the same clock as well.
        if (current_trig_valid = '1') then
            seq_sm <= PHASE_1;
            ongoing_frame <= '1';
            out_val <= current_frame.outp_ph1;
        end if;
    -- Block is active, but table execution hasn't kicked off yet.
    elsif (current_trig_valid = '1' and active = '1' and ongoing_frame = '0') then
        seq_sm <= PHASE_1;
        ongoing_frame <= '1';
        out_val <= current_frame.outp_ph1;
    else
        -- Once it is active, stay in the state machine.
        if (ongoing_frame = '1') then

        case seq_sm is
            when WAIT_TRIGGER =>
                if (current_trig_valid = '1') then
                    seq_sm <= PHASE_1;
                    out_val <= current_frame.outp_ph1;
                    -- Last frame of the table.
                    if (last_frame = '1') then
                        frame_count <= to_unsigned(1,16);
                    else
                        frame_count <= frame_count + 1;
                    end if;
                    -- Last cycle of the frame.
                    if (last_fcycle = '1') then
                        repeat_count <= to_unsigned(1,32);
                    else
                        repeat_count <= repeat_count + 1;
                    end if;
                end if;

            -- Phase 1 period
            when PHASE_1 =>
                if (presc_ce = '1' and tframe_counter = current_frame.ph1_time-1) then
                    seq_sm <= PHASE_2;
                    out_val <= current_frame.outp_ph2;
                end if;

            -- Phase 2 period
            when PHASE_2 =>
                if (presc_ce = '1' and tframe_counter = frame_length - 1) then
                    -- Table Repeat is finished 
                    -- = last_fcycle, last_frame, last_tcycle
                    if (last_tcycle = '1') then
                        seq_sm <= WAIT_TRIGGER;
                        out_val <= (others => '0');
                        active <= '0';
                        ongoing_frame <= '0';
                    -- Last frame, but table cycle is not finished, so start
                    -- over.
                    elsif (last_frame = '1') then
                        table_count <= table_count + 1;
                        current_frame <= next_frame;
                        load_next <= '1';
                        if (next_trig_valid = '1') then
                            seq_sm <= PHASE_1;
                            out_val <= next_frame.outp_ph1;
                            repeat_count <= to_unsigned(1,32);
                            frame_count <= to_unsigned(1, 16);
                        else
                            seq_sm <= WAIT_TRIGGER;
                        end if;
                    -- Current Frame Repeat finished, move to next frame.
                    elsif (last_fcycle = '1') then
                        current_frame <= next_frame;
                        load_next <= '1';
                        if (next_trig_valid = '1') then
                            seq_sm <= PHASE_1;
                            out_val <= next_frame.outp_ph1;
                            frame_count <= frame_count + 1;
                            repeat_count <= to_unsigned(1,32);
                        else
                            seq_sm <= WAIT_TRIGGER;
                        end if;
                    -- Frame cycle ongoing.
                    else
                        if (current_trig_valid = '1') then
                            seq_sm <= PHASE_1;
                            out_val <= current_frame.outp_ph1;
                            repeat_count <= repeat_count + 1;
                        else
                            seq_sm <= WAIT_TRIGGER;
                        end if;
                    end if;
                end if;

            when others =>
        end case;
    end if;
    end if;
end if;
end process;

last_fcycle <= '1' when (current_frame.repeats /= 0 and repeat_count = current_frame.repeats) else '0';
last_frame <= last_fcycle when (frame_count = unsigned(TABLE_FRAMES)) else '0';

last_tcycle <= last_frame when (TABLE_CYCLE /= X"0000_0000" and table_count = unsigned(TABLE_CYCLE)) else '0';

--
-- Prescalar CE counter :
--  On a trigger event, a reset is applied to synchronise CE pulses with the
--  trigger input.
presc_reset <= '1' when (seq_sm = WAIT_TRIGGER and current_trig_valid = '1') else '0';

presc_counter : process(clk_i)
    variable clk_cnt    : unsigned(31 downto 0) := (others => '0');
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            presc_ce <= '0';
            --clk_cnt := (0=>'1', others => '0');
            clk_cnt := (others => '0');
        else
            if (presc_reset = '1') then
                presc_ce <= '0';
                --clk_cnt := (0=>'1', others => '0');
                clk_cnt := (others => '0');
            elsif (clk_cnt =  unsigned(PRESCALE)-1) then
                presc_ce <= '1';
                clk_cnt := (others => '0');
            else
                presc_ce <= '0';
                clk_cnt := clk_cnt + 1;
            end if;
        end if;
    end if;
end process;

--
-- Frame counter :
--  On a trigger event, a reset is applied to synchronise counter with the
--  trigger input. Counter stays synchronous during Phase 1 + Phase 2 states
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
CUR_FRAME   <= X"0000" & std_logic_vector(frame_count);
CUR_FCYCLE <= std_logic_vector(repeat_count);
CUR_TCYCLE  <= std_logic_vector(table_count);

-- Gated Block Outputs.
outa_o <= out_val(0);
outb_o <= out_val(1);
outc_o <= out_val(2);
outd_o <= out_val(3);
oute_o <= out_val(4);
outf_o <= out_val(5);
active_o <= active;


end rtl;

