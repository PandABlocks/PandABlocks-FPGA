library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity pgen_ring_table is
generic (
    LEN : positive := 1024;
    -- DO NOT CHANGE THIS VALUE
    AW : positive := LOG2(LEN)
);
port (
    -- Clock
    clk_i : in  std_logic;
    reset_i : in std_logic;
    -- Block Input and Outputs
    rdata_o : out std_logic_vector(31 downto 0);
    rdata_valid_o : out std_logic := '0';
    rdata_ready_i : in std_logic;
    rdata_last_o : out std_logic;
    available_o : out std_logic_vector(AW-1 downto 0);
    wrapping_mode_i : in std_logic;
    -- input data
    wdata_i : in  std_logic_vector(31 downto 0);
    wdata_valid_i : in std_logic;
    wdata_ready_o : out std_logic := '0';
    wdata_last_i : in std_logic;
    ndatas_o : out std_logic_vector(AW-1 downto 0)
);
end;

architecture rtl of pgen_ring_table is

constant AW_MASK : std_logic_vector(AW-1 downto 0) := (others => '1');
type mem_t is array(0 to LEN-1) of std_logic_vector(31 downto 0);
signal mem : mem_t := (others => (others => '0'));
signal lasts : std_logic_vector(0 to LEN-1) := (others => '0');
signal waddr : unsigned(AW-1 downto 0) := (others => '0');
signal raddr : unsigned(AW-1 downto 0) := (others => '0');

begin

ndatas_o <= 
    std_logic_vector(waddr) when wrapping_mode_i else
    std_logic_vector(waddr - raddr);
available_o <= ndatas_o xor AW_MASK;

process (clk_i)
    variable wr_index : integer := 0;
    variable next_waddr : unsigned(AW-1 downto 0) := (others => '0');
    variable next_raddr : unsigned(AW-1 downto 0) := (others => '0');
    variable next_data_valid : std_logic := '0';
begin
    if rising_edge(clk_i) then
        -- write memory part
        next_waddr := waddr;
        if reset_i and not wrapping_mode_i then
            next_waddr := (others => '0');
        elsif wdata_valid_i = '1' and wdata_ready_o = '1' then
            wr_index := to_integer(waddr);
            mem(wr_index) <= wdata_i;
            lasts(wr_index) <= wdata_last_i;
            next_waddr := waddr + 1;
        end if;
        waddr <= next_waddr;
        -- read memory part
        next_raddr := raddr;
        if reset_i then
            next_raddr := (others => '0');
        elsif rdata_ready_i = '1' and rdata_valid_o = '1' then
            next_raddr := raddr + 1;
            if wrapping_mode_i = '1' and next_raddr = next_waddr then
                next_raddr := (others => '0');
            end if;
        end if;
        raddr <= next_raddr;
        rdata_o <= mem(to_integer(next_raddr));
        rdata_last_o <= lasts(to_integer(next_raddr));
        rdata_valid_o <=
            to_std_logic(waddr /= next_raddr and reset_i = '0')
                when wrapping_mode_i = '0' else
            to_std_logic(waddr > 0);
        wdata_ready_o <= '1' when next_waddr + 1 /= next_raddr else '0';
    end if;
end process;

end;
