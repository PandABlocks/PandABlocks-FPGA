library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.top_defines.all;
use work.support.all;

entity ts_mux is
generic (
    NUM_SFP : natural := 1
);
port (
    clk_i : in std_logic;
    ts_src_i : in std_logic_vector(LOG2(NUM_SFP) downto 0);
    latch_en_i : in std_logic;
    ts_sec_i : in std32_array(NUM_SFP-1 downto 0);
    ts_ticks_i : in std32_array(NUM_SFP-1 downto 0);
    ts_sec_o : out std_logic_vector(31 downto 0);
    ts_ticks_o : out std_logic_vector(31 downto 0)
);
end ts_mux;

architecture rtl of ts_mux is

begin

process(clk_i)
begin
    if rising_edge(clk_i) then
        if latch_en_i then
            if unsigned(ts_src_i) = 0 then
                ts_sec_o <= (others => '0');
                ts_ticks_o <= (others => '0');
            elsif unsigned(ts_src_i) <= NUM_SFP then
                ts_sec_o <= ts_sec_i(to_integer(unsigned(ts_src_i))-1);
                ts_ticks_o <= ts_ticks_i(to_integer(unsigned(ts_src_i))-1);
            else
                ts_sec_o <= (others => '0');
                ts_ticks_o <= (others => '0');
            end if;
        end if;
    end if;
end process;

end rtl;
    
