--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Sequencer table keeps frame configuration data in a flat RAM
--                Each frame configuration is 128-bits composed of 4x DWORDs
--                It is written sequentially in DWORDs, and read in 128-bits
--                      W[0] = repeats              W[0](15 downto 0)   = repeats
--                                                  W[0](19 downto 16)  = triggers
--                                                  W[0](20)            = OUTA1 (was PH1_OUTA)
--                                                  W[0](21)            = OUTB1 (was PH1_OUTB)
--                                                  W[0](22)            = OUTC1 (was PH1_OUTC)
--                                                  W[0](23)            = OUTD1 (was PH1_OUTD)
--                                                  W[0](24)            = OUTE1 (was PH1_OUTE)
--                                                  W[0](25)            = OUTF1 (was PH1_OUTF)
--                                                  W[0](26)            = OUTA2 (was PH2_OUTA)
--                                                  W[0](27)            = OUTB2 (was PH2_OUTB)
--                                                  W[0](28)            = OUTC2 (was PH2_OUTC)
--                                                  W[0](29)            = OUTD2 (was PH2_OUTD)
--                                                  W[0](30)            = OUTE2 (was PH2_OUTE)
--                                                  W[0](31)            = OUTF2 (was PH2_OUTF)
--

--                      W[1][31:28] = trig_mask     W[1]                = POSITION
--                      W[1][27:24] = trig_cond
--                      W[1][21:16] = outp_ph1
--                      W[1][13: 8] = outp_ph2
--                      W[2]        = ph1_time      W[2]                = TIME1 (was PH1_TIME)
--                      W[3]        = ph2_time      W[3]                = TIME2 (was PH2_TIME)`
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity sequencer_table is
generic (
    SEQ_LEN             : positive := 1024
);
port (
    -- Clock
    clk_i               : in  std_logic;
    -- Resets read address
    reset_raddr_i       : in  std_logic;
    -- Block Input and Outputs
    load_next_i         : in  std_logic;
    table_ready_o       : out std_logic;
    last_o              : out std_logic;
    frame_o             : out seq_t;
    -- Block Parameters
    TABLE_START         : in  std_logic;
    TABLE_DATA          : in  std_logic_vector(31 downto 0);
    TABLE_WSTB          : in  std_logic;
    TABLE_FRAMES        : in  std_logic_vector(15 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic
);
end sequencer_table;

architecture rtl of sequencer_table is

constant AW                     : positive := LOG2(SEQ_LEN);
constant c_zeros32              : std_logic_vector(31 downto 0) := X"00000000";

signal seq_dout                 : std32_array(3 downto 0);
signal seq_waddr                : unsigned(AW+1 downto 0) := (others => '0');
signal seq_raddr                : unsigned(AW-1 downto 0) := (others => '0');
signal seq_raddr_current        : unsigned(AW-1 downto 0) := (others => '0');
signal seq_raddr_next           : unsigned(AW-1 downto 0) := (others => '0');
signal seq_wren                 : std_logic_vector(3 downto 0);
signal seq_di                   : std_logic_vector(31 downto 0);
signal table_ready              : std_logic := '0';
signal table_frames_reg : std_logic_vector(15 downto 0) := (others => '0');
signal table_frames_now : std_logic_vector(15 downto 0) := (others => '0');

begin

table_ready_o <= table_ready;
table_frames_now <=
    TABLE_FRAMES when TABLE_LENGTH_WSTB = '1' and TABLE_FRAMES /= x"0000"
    else table_frames_reg;

--------------------------------------------------------------------------
-- Table configuration starts with applying are reset with a write to
-- TABLE_START register which in-validates table
-- This is followed by writing frame configuration data in DWORDs sequentially
-- Finally, a write to TABLE_LENGTH register validates the table
--------------------------------------------------------------------------
SEQ_ARMING : process(clk_i) begin
    if rising_edge(clk_i) then
        if (TABLE_LENGTH_WSTB = '1' and TABLE_FRAMES /= x"0000") then
            table_ready <= '1';
            table_frames_reg <= TABLE_FRAMES;
        elsif (TABLE_START = '1') then
            table_ready <= '0';
        end if;
    end if;
end process;

-- Auto increment table write address
FILL_SEQ_TABLE : process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Reset Sequencer Table Write Pointer
        if (TABLE_START = '1') then
            seq_waddr <= (others => '0');
        -- Increment Sequencer Table Write Pointer
        elsif (TABLE_WSTB = '1') then
            seq_waddr <= seq_waddr + 1;
        end if;
    end if;
end process;

-- Multiplex incoming DWORDs into the BRAM column
seq_wren(0) <= TABLE_WSTB when (seq_waddr(1 downto 0) = "00") else '0';
seq_wren(1) <= TABLE_WSTB when (seq_waddr(1 downto 0) = "01") else '0';
seq_wren(2) <= TABLE_WSTB when (seq_waddr(1 downto 0) = "10") else '0';
seq_wren(3) <= TABLE_WSTB when (seq_waddr(1 downto 0) = "11") else '0';

seq_di <= TABLE_DATA;

-- Sequencer table is composed of 4 BRAMs joined as columns
SEQ_TABLE_GEN : FOR I in 0 to 3 GENERATE

spbram_inst : entity work.spbram
generic map (
    AW          => AW,
    DW          => 32
)
port map (
    addra       => std_logic_vector(seq_waddr(AW+1 downto 2)),
    addrb       => std_logic_vector(seq_raddr),
    clka        => clk_i,
    clkb        => clk_i,
    dina        => seq_di,
    doutb       => seq_dout(I),
    wea         => seq_wren(I)
);

END GENERATE;


-- [0](15 downto 0)    Repeats
frame_o.repeats <= unsigned(seq_dout(0)(15 downto 0));
-- [0](19 downto 16)   Trigger
frame_o.trigger <= unsigned(seq_dout(0)(19 downto 16));
-- [0](25 downto 2)    Output 1
frame_o.out1 <= seq_dout(0)(25 downto 20);
-- [0](26 downto 31)   Output 2
frame_o.out2 <= seq_dout(0)(31 downto 26);
-- [1](31 downto 0)    Position (63 downto 32)
frame_o.position <= signed(seq_dout(1));
-- [2](31 downto 0)    Time1 (95 downto 64)
frame_o.time1 <= unsigned(seq_dout(2));
-- [3](31 downto 0)    Time2 (127 downto 64)
frame_o.time2 <= unsigned(seq_dout(3));


seq_raddr <= (others => '0') when reset_raddr_i = '1' or TABLE_START = '1' else
    seq_raddr_next when load_next_i = '1' else
    seq_raddr_current;

-- Calculate the next address in a clocked process so
-- we can use combinatorial logic above to minimize delays
FRAME_CTRL : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (seq_raddr = unsigned(table_frames_now) - 1) then
            seq_raddr_next <= (others => '0');
            last_o <= '1';
        else
            seq_raddr_next <= seq_raddr + 1;
            last_o <= '0';
        end if;
        seq_raddr_current <= seq_raddr;
    end if;
end process;

end rtl;

