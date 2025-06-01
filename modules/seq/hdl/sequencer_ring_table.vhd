library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity sequencer_ring_table is
generic (
    SEQ_LEN : positive := 1024;
    -- DO NOT CHANGE THIS VALUE
    AW : positive := LOG2(SEQ_LEN)
);
port (
    -- Clock
    clk_i : in  std_logic;
    reset_i : in std_logic;
    -- Block Input and Outputs
    frame_o : out seq_t;
    frame_valid_o : out std_logic := '0';
    frame_ready_i : in std_logic;
    nframes_o : out std_logic_vector(AW-1 downto 0);
    frame_last_o : out std_logic;
    available_o : out std_logic_vector(AW-1 downto 0);
    wrapping_mode_i : in std_logic;
    -- input data
    data_i : in  std_logic_vector(31 downto 0);
    data_last_i : in std_logic;
    data_valid_i : in std_logic;
    data_ready_o : out std_logic := '0'
);
end;

architecture rtl of sequencer_ring_table is

constant AW_MASK : std_logic_vector(AW-1 downto 0) := (others => '1');
type mem_t is array(0 to SEQ_LEN-1) of std_logic_vector(127 downto 0);
signal mem : mem_t := (others => (others => '0'));
signal lasts : std_logic_vector(0 to SEQ_LEN-1) := (others => '0');
signal seq_dout : std_logic_vector(127 downto 0) := (others => '0');
signal data_sr : std_logic_vector(95 downto 0) := (others => '0');
signal waddr : unsigned(AW+1 downto 0) := (others => '0');
signal raddr : unsigned(AW-1 downto 0) := (others => '0');

begin

nframes_o <=
    std_logic_vector(waddr(AW+1 downto 2))
        when wrapping_mode_i else
    std_logic_vector(waddr(AW+1 downto 2) - raddr);
available_o <= nframes_o xor AW_MASK;

process (clk_i)
    variable wr_index : integer := 0;
    variable next_waddr : unsigned(AW+1 downto 0) := (others => '0');
    variable next_raddr : unsigned(AW-1 downto 0) := (others => '0');
    variable next_frame_valid : std_logic := '0';
begin
    if rising_edge(clk_i) then
        -- write memory part
        next_waddr := waddr;
        if reset_i and not wrapping_mode_i then
            next_waddr := (others => '0');
        elsif data_valid_i = '1' and data_ready_o = '1' then
            if waddr(1 downto 0) = "11" then
                wr_index := to_integer(waddr(AW+1 downto 2));
                mem(wr_index) <= data_i & data_sr;
                lasts(wr_index) <= data_last_i;
            end if;
            next_waddr := waddr + 1;
            data_sr <= data_i & data_sr(95 downto 32);
        end if;
        waddr <= next_waddr;
        -- read memory part
        next_raddr := raddr;
        if reset_i then
            next_raddr := (others => '0');
        elsif frame_ready_i = '1' and frame_valid_o = '1' then
            next_raddr := raddr + 1;
            if wrapping_mode_i = '1' and next_raddr = next_waddr(AW+1 downto 2) then
                next_raddr := (others => '0');
            end if;
        end if;
        raddr <= next_raddr;
        seq_dout <= mem(to_integer(next_raddr));
        frame_last_o <= lasts(to_integer(next_raddr));
        frame_valid_o <=
            to_std_logic(waddr(AW+1 downto 2) /= next_raddr and reset_i = '0')
                when wrapping_mode_i = '0' else
            to_std_logic(waddr(AW+1 downto 2) > 0);
        data_ready_o <= '1' when next_waddr(AW+1 downto 2) + 1 /= next_raddr else '0';
    end if;
end process;

frame_o.repeats <= unsigned(seq_dout(15 downto 0));
frame_o.trigger <= unsigned(seq_dout(19 downto 16));
frame_o.out1 <= seq_dout(25 downto 20);
frame_o.out2 <= seq_dout(31 downto 26);
frame_o.position <= signed(seq_dout(63 downto 32));
frame_o.time1 <= unsigned(seq_dout(95 downto 64));
frame_o.time2 <= unsigned(seq_dout(127 downto 96));

end;
