library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity ext_dio is
    port (
        clk_i : in  std_logic;
        -- IO pad
        pad_i : in std_logic;
        pad_o : out std_logic;
        dir_o : out std_logic;
        -- Block Input and Outputs
        in_val_o : out std_logic;
        out_val_i : in std_logic;
        -- Block Parameters
        OUT_DIR : in std_logic_vector(31 downto 0)
    );
end;

architecture rtl of ext_dio is
    signal iobuf_out : std_logic;
begin
    dir_o <= OUT_DIR(0);
    pad_o <= out_val_i;
    syncer : entity work.IDDR_sync_bit port map (
        clk_i => clk_i,
        bit_i => pad_i,
        bit_o => in_val_o
    );
end;
