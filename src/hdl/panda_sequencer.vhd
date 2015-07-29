--------------------------------------------------------------------------------
--  File:       panda_sequencer.vhd
--  Desc:       Position compare output pulse generator
--
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
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    -- Output pulse
    act_o               : out std_logic;
    pulse_o             : out std_logic_vector(5 downto 0)
);
end panda_sequencer;

architecture rtl of panda_sequencer is

constant SEQ_LEN    : positive := 512;

type seq_t is
record
    repeats     : unsigned(11 downto 0);
    trig_mask   : std_logic_vector(3 downto 0);
    trig_cond   : std_logic_vector(3 downto 0);
    outp_ph1    : std_logic_vector(5 downto 0);
    outp_ph2    : std_logic_vector(5 downto 0);
    ph1_time    : std_logic_vector(15 downto 0);
    ph2_time    : std_logic_vector(15 downto 0);
end record;

signal SEQ_ENABLE_VAL    : std_logic_vector(SBUSBW-1 downto 0);
signal SEQ_INP0_VAL      : std_logic_vector(SBUSBW-1 downto 0);
signal SEQ_INP1_VAL      : std_logic_vector(SBUSBW-1 downto 0);
signal SEQ_INP2_VAL      : std_logic_vector(SBUSBW-1 downto 0);
signal SEQ_INP3_VAL      : std_logic_vector(SBUSBW-1 downto 0);
signal SEQ_CLK_PRESC     : std_logic_vector(31 downto 0);
signal SEQ_TABLE_WORDS   : unsigned(15 downto 0);
signal SEQ_TABLE_REPEAT  : unsigned(15 downto 0);

signal seq_cur_frame    : seq_t := (repeats => (others => '0'), others => (others => '0'));
signal seq_dout         : std_logic_vector(63 downto 0);

signal seq_waddr        : integer range 0 to 2*SEQ_LEN-1 := 0;
signal seq_raddr        : integer range 0 to SEQ_LEN-1 := 0;
signal seq_wraddr       : std_logic_vector(9 downto 0);
signal seq_rdaddr       : std_logic_vector(8 downto 0);

signal tframe_counter   : unsigned(31 downto 0) := (others => '0');
signal repeat_count     : unsigned(11 downto 0);
signal frame_count      : unsigned(15 downto 0);
signal table_count      : unsigned(15 downto 0);

type state_t is (IDLE, LOAD_FRAME, WAIT_TRIG, PHASE_1, PHASE_2, IS_FINISHED, NEXT_FRAME);
signal seq_sm           : state_t;

signal seq_trig         : std_logic_vector(3 downto 0);
signal trig_val         : std_logic_vector(3 downto 0);
signal enable_val       : std_logic;
signal enable_prev      : std_logic;
signal enable_rise      : std_logic;

signal presc_reset      : std_logic := '0';
signal presc_ce         : std_logic := '0';
signal seq_wren         : std_logic := '0';
signal seq_rden         : std_logic;

begin

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            -- Disconnect trigger and inputs
            SEQ_ENABLE_VAL  <= TO_STD_VECTOR(127, SBUSBW);
            SEQ_INP0_VAL    <= TO_STD_VECTOR(127, SBUSBW);
            SEQ_INP1_VAL    <= TO_STD_VECTOR(127, SBUSBW);
            SEQ_INP2_VAL    <= TO_STD_VECTOR(127, SBUSBW);
            SEQ_INP3_VAL    <= TO_STD_VECTOR(127, SBUSBW);
            SEQ_CLK_PRESC   <= (others => '0');
            SEQ_TABLE_WORDS <= (others => '0');
            SEQ_TABLE_REPEAT <= (others => '0');
        else
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Pulse start position
                if (mem_addr_i = SEQ_ENABLE_VAL_ADDR) then
                    SEQ_ENABLE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_INP0_VAL_ADDR) then
                    SEQ_INP0_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_INP1_VAL_ADDR) then
                    SEQ_INP1_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_INP2_VAL_ADDR) then
                    SEQ_INP2_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_INP3_VAL_ADDR) then
                    SEQ_INP3_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_CLK_PRESC_ADDR) then
                    SEQ_CLK_PRESC <= mem_dat_i;
                end if;

                if (mem_addr_i = SEQ_TABLE_WORDS_ADDR) then
                    SEQ_TABLE_WORDS <= unsigned(mem_dat_i(15 downto 0));
                end if;

                if (mem_addr_i = SEQ_TABLE_REPEAT_ADDR) then
                    SEQ_TABLE_REPEAT <= unsigned(mem_dat_i(15 downto 0));
                end if;
            end if;
        end if;
    end if;
end process;

REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            mem_dat_o <= (others => '0');
        else
            case (mem_addr_i) is
                when SEQ_CUR_FRAME_ADDR =>
                    mem_dat_o <= ZEROS(16) & std_logic_vector(frame_count);
                when SEQ_CUR_FCYCLE_ADDR =>
                    mem_dat_o <= ZEROS(20) & std_logic_vector(repeat_count);
                when SEQ_CUR_TCYCLE_ADDR =>
                    mem_dat_o <= ZEROS(16) & std_logic_vector(table_count);
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

--
-- Design Bus Assignments
--
process(clk_i)
    variable t_counter  : unsigned(31 downto 0);
begin
    if rising_edge(clk_i) then
        enable_val <= SBIT(sysbus_i, SEQ_ENABLE_VAL);
        trig_val(0) <= SBIT(sysbus_i, SEQ_INP0_VAL);
        trig_val(1) <= SBIT(sysbus_i, SEQ_INP1_VAL);
        trig_val(2) <= SBIT(sysbus_i, SEQ_INP2_VAL);
        trig_val(3) <= SBIT(sysbus_i, SEQ_INP3_VAL);
    end if;
end process;

--
-- Control System Interface
--
FILL_SEQ_TABLE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (mem_cs_i = '1' and mem_wstb_i = '1') then
            -- Reset Sequencer Table Write Pointer
            if (mem_addr_i = SEQ_MEM_START_ADDR) then
                seq_waddr <= 0;
            -- Increment Sequencer Table Write Pointer
            elsif (mem_addr_i = SEQ_MEM_WSTB_ADDR) then
                seq_waddr <= seq_waddr + 1;
            end if;
        end if;
    end if;
end process;

seq_wren <= '1' when (mem_cs_i = '1' and mem_wstb_i = '1' and
                                mem_addr_i = SEQ_MEM_WSTB_ADDR) else '0';
seq_rdaddr <= TO_STD_VECTOR(seq_raddr, 9);
seq_wraddr <= TO_STD_VECTOR(seq_waddr, 10);
seq_rden <= not seq_wren;

SEQ_TABLE_INST : BRAM_SDP_MACRO
generic map (
    BRAM_SIZE   => "36Kb",
    DEVICE      => "7SERIES",
    WRITE_WIDTH => 32,
    READ_WIDTH  => 64
)
port map (
    DO          => seq_dout,
    DI          => mem_dat_i,
    RDADDR      => seq_rdaddr,
    RDCLK       => clk_i,
    RDEN        => seq_rden,
    REGCE       => '1',
    RST         => reset_i,
    WE          => "1111",
    WRADDR      => seq_wraddr,
    WRCLK       => clk_i,
    WREN        => seq_wren
);

-- Trigger match condition based on frame configuration
seq_trig <= not (seq_cur_frame.trig_cond xor trig_val) and
                                        not seq_cur_frame.trig_mask;

SEQ_FSM : process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_val;
        enable_rise <= enable_val and not enable_prev;

        -- Sequencer State Machine
        if (enable_val = '0') then
            seq_raddr <= 0;
            pulse_o <= (others => '0');
            act_o <= '0';
            repeat_count <= (others => '0');
            frame_count <= (others => '0');
            table_count <= (others => '0');
            act_o <= '0';
            seq_sm <= IDLE;
        else
            case seq_sm is
                -- Wait for rising edge of enable
                when IDLE =>
                    seq_raddr <= 0;
                    if (enable_rise = '1') then
                        seq_sm <= LOAD_FRAME;
                    end if;

                -- Load next frate
                when LOAD_FRAME =>
                    seq_cur_frame.repeats <= unsigned(seq_dout(11 downto 0));
                    seq_cur_frame.trig_mask <= seq_dout(15 downto 12);
                    seq_cur_frame.trig_cond <= seq_dout(19 downto 16);
                    seq_cur_frame.outp_ph1  <= seq_dout(25 downto 20);
                    seq_cur_frame.outp_ph2  <= seq_dout(31 downto 26);
                    seq_cur_frame.ph1_time  <= seq_dout(47 downto 32);
                    seq_cur_frame.ph2_time  <= seq_dout(63 downto 48);
                    seq_sm <= WAIT_TRIG;

                -- Wait for trigger match
                when WAIT_TRIG =>
                    if (seq_trig /= "0000") then
                        seq_sm <= PHASE_1;
                        act_o <= '1';
                    end if;

                -- Phase 1 period
                when PHASE_1 =>
                    pulse_o <= seq_cur_frame.outp_ph1;
                    if (presc_ce = '1' and tframe_counter =
                    unsigned(seq_cur_frame.ph1_time)-1) then
                        seq_sm <= PHASE_2;
                    end if;

                -- Phase 2 period
                when PHASE_2 =>
                    pulse_o <= seq_cur_frame.outp_ph2;
                    if (presc_ce = '1' and tframe_counter =
                    unsigned(seq_cur_frame.ph1_time) +
                    unsigned(seq_cur_frame.ph2_time) -1) then
                        seq_sm <= IS_FINISHED;
                    end if;

                when IS_FINISHED =>
                    act_o <= '0';
                    -- Frame Repeats either set to 0 or finished
                    if (seq_cur_frame.repeats /= 0 and repeat_count = seq_cur_frame.repeats-1) then
                        repeat_count <= (others => '0');
                        -- All Frames finished
                        if (frame_count = SEQ_TABLE_WORDS-1) then
                            frame_count <= (others => '0');
                            seq_raddr <= 0;
                            -- Table Repeats either set to 0 or finished
                            if (SEQ_TABLE_REPEAT /= 0 and table_count = SEQ_TABLE_REPEAT-1) then
                                table_count <= (others => '0');
                                seq_sm <= IDLE;
                            else
                                -- repeat table
                                seq_sm <= NEXT_FRAME;
                                table_count <= table_count + 1;
                            end if;
                        else
                            -- move to next frame
                            frame_count <= frame_count + 1;
                            seq_raddr <= seq_raddr + 1;
                            seq_sm <= NEXT_FRAME;
                        end if;
                    else
                        -- repeat frame
                        seq_sm <= WAIT_TRIG;
                        repeat_count <= repeat_count + 1;
                    end if;

                -- Consume one clock for next address to settle
                when NEXT_FRAME =>
                    seq_sm <= LOAD_FRAME;

                when others =>
            end case;
        end if;
    end if;
end process;

--
-- Prescalar CE counter :
--  On a trigger event, a reset is applied to synchronise CE pulses with the
--  trigger input.
presc_reset <= '1' when (seq_sm = WAIT_TRIG and seq_trig /= "0000") else '0';

presc_counter : process(clk_i)
    variable clk_cnt    : unsigned(31 downto 0) := (others => '0');
begin
    if rising_edge(clk_i) then
        if (presc_reset = '1') then
            presc_ce <= '0';
            clk_cnt := (0=>'1', others => '0');
        elsif (clk_cnt =  unsigned(SEQ_CLK_PRESC)-1) then
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

end rtl;

