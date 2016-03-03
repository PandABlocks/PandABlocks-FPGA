--------------------------------------------------------------------------------
--  File:       panda_sequencer_table.vhd
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

entity panda_sequencer_table is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    load_next_i         : in  std_logic;
    table_ready_o       : out std_logic;
    next_frame_o        : out seq_t;
    -- Block Parameters
    TABLE_START         : in  std_logic;
    TABLE_DATA          : in  std_logic_vector(31 downto 0);
    TABLE_WSTB          : in  std_logic;
    TABLE_LENGTH        : in  std_logic_vector(15 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic
);
end panda_sequencer_table;

architecture rtl of panda_sequencer_table is

constant AW                     : positive := 9;           -- log2(SEQ_LEN)

signal seq_dout                 : std32_array(3 downto 0);

signal seq_waddr                : unsigned(AW+1 downto 0) := (others => '0');
signal seq_raddr                : unsigned(AW-1 downto 0);
signal seq_wren                 : std_logic_vector(3 downto 0);
signal seq_di                   : std_logic_vector(31 downto 0);

signal table_ready              : std_logic := '0';

begin

table_ready_o <= table_ready;

--
-- Blocks _armed_ signal is controlled by start of table write and length strobes.
--
SEQ_ARMING : process(clk_i) begin
    if rising_edge(clk_i) then
        if (TABLE_LENGTH_WSTB = '1') then
            table_ready <= '1';
        elsif (TABLE_START = '1') then
            table_ready <= '0';
        end if;
    end if;
end process;

-- Sequencer TABLE interface
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

seq_wren(0) <= TABLE_WSTB when (seq_waddr(1 downto 0) = "00") else '0';
seq_wren(1) <= TABLE_WSTB when (seq_waddr(1 downto 0) = "01") else '0';
seq_wren(2) <= TABLE_WSTB when (seq_waddr(1 downto 0) = "10") else '0';
seq_wren(3) <= TABLE_WSTB when (seq_waddr(1 downto 0) = "11") else '0';

seq_di <= TABLE_DATA;

SEQ_TABLE_GEN : FOR I in 0 to 3 GENERATE

spbram : entity work.panda_spbram
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

-- Frame loading from memory is done sequencially in 4 words.

FRAME_CTRL : process(clk_i)
begin
    if rising_edge(clk_i) then
        --
        -- Sequencer frame load state machine, active after TABLE is populated.
        --
        if (reset_i = '1') then
            seq_raddr <= (others => '0');
            next_frame_o <= (repeats => (others => '0'), ph1_time => (others => '0'), ph2_time => (others => '0'), others => (others => '0'));
        else
            -- Increment read address for loading frames from the table.
            if (load_next_i = '1') then
                if (seq_raddr = unsigned(TABLE_LENGTH)-1) then
                    seq_raddr <= (others => '0');
                else
                    seq_raddr <= seq_raddr + 1;
                end if;
            end if;

            next_frame_o.repeats <= unsigned(seq_dout(0));

            next_frame_o.trig_mask <= seq_dout(1)(31 downto 28);
            next_frame_o.trig_cond <= seq_dout(1)(27 downto 24);
            next_frame_o.outp_ph1  <= seq_dout(1)(21 downto 16);
            next_frame_o.outp_ph2  <= seq_dout(1)(13 downto  8);

            next_frame_o.ph1_time <= unsigned(seq_dout(2));

            next_frame_o.ph2_time <= unsigned(seq_dout(3));

        end if;
    end if;
end process;

end rtl;

