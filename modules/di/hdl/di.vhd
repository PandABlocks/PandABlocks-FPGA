library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity di is
    port (
        clk_i : in  std_logic;
        -- IO pad
        pad_i : in std_logic;
        -- Block Input and Outputs
        val_o : out std_logic
    );
end;

architecture rtl of di is
begin
    syncer : entity work.IDDR_sync_bit port map (
        clk_i => clk_i,
        bit_i => pad_i,
        bit_o => val_o
    );
end;
