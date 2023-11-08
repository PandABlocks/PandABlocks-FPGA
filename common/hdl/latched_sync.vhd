library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

use work.support.all;

entity latched_sync is
generic ( 
    DWIDTH : natural := 32;
    PERIOD : natural := 1250000  -- 100 Hz for 125 MHz
);
port (
    src_clk     : in  std_logic;
    dest_clk    : in  std_logic;
    data_i      : in  std_logic_vector(DWIDTH-1 downto 0);
    data_o      : out std_logic_vector(DWIDTH-1 downto 0) := (others => '0')
);
end entity;

architecture rtl of latched_sync is

signal data_latch : std_logic_vector(DWIDTH-1 downto 0) := (others => '0');
signal sync_tog, sync_tog_a, sync_tog_b, sync_tog_c, sync_tog_edge : std_logic := '0';

attribute ASYNC_REG : string;
attribute ASYNC_REG of sync_tog_a, sync_tog_b : signal is "TRUE";

begin
    
src_latch: process(src_clk)
    variable ctr : unsigned(LOG2(PERIOD) downto 0) := (others => '0');
begin
    if rising_edge(src_clk) then
        if ctr = to_unsigned(PERIOD,LOG2(PERIOD)+1) then
            data_latch <= data_i;
            sync_tog <= not sync_tog;
            ctr := (others => '0');
        else
            ctr := ctr + 1;
        end if;
    end if;
end process src_latch;

sync_tog_edge <= sync_tog_c xor sync_tog_b;

dest_read: process(dest_clk)
begin
    if rising_edge(dest_clk) then
        sync_tog_c <= sync_tog_b;
        sync_tog_b <= sync_tog_a;
        sync_tog_a <= sync_tog;
        
        if sync_tog_edge = '1' then
            data_o <= data_latch;
        end if;
    end if;

end process dest_read;

end rtl;

