--------------------------------------------------------------------------------
--  File:       panda_sequencer.vhd
--  Desc:       Programmable Sequencer.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

Library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use unimacro.Vcomponents.all;

entity panda_sequencer is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    gate_i              : in  std_logic;
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
    SOFT_GATE           : in  std_logic;
    TABLE_RST           : in  std_logic;
    TABLE_DATA          : in  std_logic_vector(31 downto 0);
    TABLE_WSTB          : in  std_logic;
    TABLE_REPEAT        : in  std_logic_vector(31 downto 0);
    TABLE_LENGTH        : in  std_logic_vector(15 downto 0);
    -- Block Status
    CUR_FRAME           : out std_logic_vector(31 downto 0);
    CUR_FCYCLES         : out std_logic_vector(31 downto 0);
    CUR_TCYCLE          : out std_logic_vector(31 downto 0);
    CUR_STATE           : out std_logic_vector(31 downto 0)
);
end panda_sequencer;

architecture rtl of panda_sequencer is

constant SEQ_LEN    : positive := 4 * 512;
constant SEQ_AW     : positive := 11;           -- log2(SEQ_LEN)

type seq_t is
record
    repeats     : unsigned(31 downto 0);
    trig_mask   : std_logic_vector(3 downto 0);
    trig_cond   : std_logic_vector(3 downto 0);
    outp_ph1    : std_logic_vector(5 downto 0);
    outp_ph2    : std_logic_vector(5 downto 0);
    ph1_time    : unsigned(31 downto 0);
    ph2_time    : unsigned(31 downto 0);
end record;

signal TABLE_LENGTH_DWORD       : std_logic_vector(15 downto 0);

signal seq_cur_frame    : seq_t := (repeats => (others => '0'), ph1_time => (others => '0'), ph2_time => (others => '0'), others => (others => '0'));
signal seq_next_frame   : seq_t := (repeats => (others => '0'), ph1_time => (others => '0'), ph2_time => (others => '0'), others => (others => '0'));
signal seq_dout                 : std_logic_vector(31 downto 0);
signal seq_load_enable          : std_logic;
signal seq_load_enable_prev     : std_logic;
signal seq_load_init            : std_logic;
signal seq_load_done            : std_logic;

signal seq_waddr                : integer range 0 to SEQ_LEN-1 := 0;
signal seq_raddr                : integer range 0 to SEQ_LEN-1 := 0;
signal seq_wraddr               : std_logic_vector(SEQ_AW-1 downto 0);
signal seq_rdaddr               : std_logic_vector(SEQ_AW-1 downto 0);

signal tframe_counter           : unsigned(31 downto 0) := (others => '0');
signal repeat_count             : unsigned(31 downto 0) := (others => '0');
signal frame_count              : unsigned(15 downto 0) := (others => '0');
signal table_count              : unsigned(31 downto 0) := (others => '0');

type state_t is (INIT, ARMED, PHASE_1, PHASE_2, IS_FINISHED, FINISHED);
signal seq_sm                   : state_t;

signal seq_trig                 : std_logic_vector(3 downto 0);
signal seq_trig_prev            : std_logic_vector(3 downto 0);
signal seq_trig_pulse           : std_logic := '0';
signal inp_val                  : std_logic_vector(3 downto 0);
signal out_val                  : std_logic_vector(5 downto 0) := "000000";
signal active                   : std_logic := '0';

signal presc_reset              : std_logic := '0';
signal presc_ce                 : std_logic := '0';
signal seq_wren                 : std_logic := '0';
signal seq_di                   : std_logic_vector(31 downto 0);
signal gate_val                 : std_logic := '0';
signal gate_prev                : std_logic := '0';
signal gate_fall                : std_logic := '0';
signal gate_rise                : std_logic := '0';

signal last_frame_repeat        : std_logic := '0';
signal last_table_repeat        : std_logic := '0';

begin

-- Block inputs and outputs
inp_val <= inpd_i & inpc_i & inpb_i & inpa_i;
gate_val <= gate_i or SOFT_GATE;

outa_o <= out_val(0);
outb_o <= out_val(1);
outc_o <= out_val(2);
outd_o <= out_val(3);
oute_o <= out_val(4);
outf_o <= out_val(5);
active_o <= active;

-- Table length in terms of 128-bit Frames
TABLE_LENGTH_DWORD <= "00" & TABLE_LENGTH(15 downto 2);

--
-- Sequencer table interface
--
FILL_SEQ_TABLE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (TABLE_RST = '1') then
            seq_waddr <= 0;
        -- Increment Sequencer Table Write Pointer
        elsif (TABLE_WSTB = '1') then
            seq_waddr <= seq_waddr + 1;
        end if;
    end if;
end process;

seq_wren <= TABLE_WSTB;
seq_rdaddr <= TO_SVECTOR(seq_raddr, SEQ_AW);
seq_wraddr <= TO_SVECTOR(seq_waddr, SEQ_AW);
seq_di <= TABLE_DATA;

panda_spbram : entity work.panda_spbram
generic map (
    AW          => SEQ_AW,
    DW          => 32
)
port map (
    addra       => seq_wraddr,
    addrb       => seq_rdaddr,
    clka        => clk_i,
    clkb        => clk_i,
    dina        => seq_di,
    doutb       => seq_dout,
    wea         => seq_wren
);

-- Trigger match condition based on frame configuration
seq_trig <= not (seq_cur_frame.trig_cond xor inp_val) and
                                        not seq_cur_frame.trig_mask;

seq_trig_pulse <= '1' when (seq_trig_prev = "0000" and seq_trig /= "0000")
                        else '0';

--
--
--
gate_rise <= gate_val and not gate_prev;
gate_fall <= not gate_val and gate_prev;

SEQ_FSM : process(clk_i)
begin
    if rising_edge(clk_i) then
        seq_trig_prev <= seq_trig;
        gate_prev <= gate_val;
        --
        -- Sequencer frame load state machine
        --
        if (gate_val = '0') then
            seq_load_enable <= '0';
            seq_load_enable_prev <= '0';
            seq_load_done <= '0';
            seq_raddr <= 0;
        else
            -- *_init signal initialises loading next frame settings from the
            -- BRAM which takes 4 clock cycles.
            -- *_done flags end of loading to the state machine.
            if (seq_load_init = '1') then
                seq_load_enable <= '1';
            elsif (seq_rdaddr(1 downto 0) = "11") then
                seq_load_enable <= '0';
            end if;

            seq_load_done <= '0';

            if (seq_load_enable = '1') then
                if (seq_raddr = unsigned(TABLE_LENGTH)-1) then
                    seq_raddr <= 0;
                else
                    seq_raddr <= seq_raddr + 1;
                end if;
            end if;

            -- Next frame values are loaded by taking into account 1 clock cycle
            -- output latency of BRAM
            seq_load_enable_prev <= seq_load_enable;

            if (seq_load_enable_prev = '1') then
                case (seq_rdaddr(1 downto 0)) is
                    when "01" =>
                        seq_next_frame.repeats <= unsigned(seq_dout);
                    when "10" =>
                        seq_next_frame.trig_mask <= seq_dout(3 downto 0);
                        seq_next_frame.trig_cond <= seq_dout(7 downto 4);
                        seq_next_frame.outp_ph1  <= seq_dout(13 downto 8);
                        seq_next_frame.outp_ph2  <= seq_dout(19 downto 14);
                    when "11" =>
                        seq_next_frame.ph1_time <= unsigned(seq_dout);
                    when "00" =>
                        seq_next_frame.ph2_time <= unsigned(seq_dout);
                        seq_load_done <= '1';
                    when others =>
                end case;
            end if;
        end if;

        --
        -- Sequencer State Machine
        --
        if (gate_rise = '1') then
            seq_sm <= INIT;
            out_val <= (others => '0');
            active <= '0';
            repeat_count <= (others => '0');
            frame_count <= (others => '0');
            table_count <= (others => '0');
            active <= '1';
            seq_load_init <= '1';
        elsif (gate_fall = '1') then
            seq_sm <= FINISHED;
        else
            seq_load_init <= '0';

            case seq_sm is
                -- Initialise first frame setting
                when INIT =>
                    seq_load_init <= '0';
                    if (seq_load_done = '1') then
                        seq_cur_frame <= seq_next_frame;
                        seq_sm <= ARMED;
                    end if;

                -- Wait for trigger match
                when ARMED =>
                    if (seq_trig_pulse = '1') then
                        seq_sm <= PHASE_1;
                        if (last_frame_repeat = '1') then
                            seq_load_init <= '1';
                        end if;
                    end if;

                -- Phase 1 period
                when PHASE_1 =>
                    out_val <= seq_cur_frame.outp_ph1;
                    if (presc_ce = '1' and tframe_counter = seq_cur_frame.ph1_time-1) then
                        seq_sm <= PHASE_2;
                    end if;

                -- Phase 2 period
                when PHASE_2 =>
                    out_val <= seq_cur_frame.outp_ph2;
                    if (presc_ce = '1' and tframe_counter = seq_cur_frame.ph1_time + seq_cur_frame.ph2_time -1) then
                        seq_sm <= IS_FINISHED;
                    end if;

                when IS_FINISHED =>
                    -- Current Frame Repeat finished, so make a decision
                    if (last_frame_repeat = '1') then
                        repeat_count <= (others => '0');
                        -- All Frames finished in the table
                        if (frame_count = unsigned(TABLE_LENGTH_DWORD)-1) then
                            frame_count <= (others => '0');
                            -- Table Repeat is finished, so de-assert active
                            if (last_table_repeat = '1') then
                                table_count <= (others => '0');
                                seq_sm <= FINISHED;
                            -- Table Repeat not finished, so start over
                            else
                                seq_cur_frame <= seq_next_frame;
                                seq_sm <= ARMED;
                                table_count <= table_count + 1;
                            end if;
                        -- Frame Repeat not finished, so move to next frame
                        else
                            frame_count <= frame_count + 1;
                            seq_cur_frame <= seq_next_frame;
                            seq_sm <= ARMED;
                        end if;
                    -- Frame Repeat is not finished, so repeat the same frame
                    else
                        seq_sm <= ARMED;
                        repeat_count <= repeat_count + 1;
                    end if;

                when FINISHED =>
                    active <= '0';
                    seq_load_init <= '0';
                    out_val <= (others => '0');

                when others =>
            end case;
        end if;
    end if;
end process;

last_frame_repeat <= '1' when (seq_cur_frame.repeats /= 0 and repeat_count = seq_cur_frame.repeats-1)
                    else '0';

last_table_repeat <= '1' when (TABLE_REPEAT /= X"0000_0000" and table_count = unsigned(TABLE_REPEAT)-1)
                    else '0';

--
-- Prescalar CE counter :
--  On a trigger event, a reset is applied to synchronise CE pulses with the
--  trigger input.
presc_reset <= '1' when (seq_sm = ARMED and seq_trig_pulse = '1') else '0';

presc_counter : process(clk_i)
    variable clk_cnt    : unsigned(31 downto 0) := (others => '0');
begin
    if rising_edge(clk_i) then
        if (presc_reset = '1') then
            presc_ce <= '0';
            clk_cnt := (0=>'1', others => '0');
        elsif (clk_cnt =  unsigned(PRESCALE)-1) then
            presc_ce <= '1';
            clk_cnt := (others => '0');
        else
            presc_ce <= '0';
            clk_cnt := clk_cnt + 1;
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
        if (presc_reset = '1') then
            tframe_counter <= (others => '0');
        elsif (presc_ce = '1') then
            tframe_counter <= tframe_counter + 1;
        end if;
    end if;
end process;

-- Block Status
CUR_FRAME   <= X"0000" & std_logic_vector(frame_count);
CUR_FCYCLES <= std_logic_vector(repeat_count);
CUR_TCYCLE  <= std_logic_vector(table_count);
CUR_STATE <= std_logic_vector(to_unsigned(state_t'pos(seq_sm), 32));

end rtl;

