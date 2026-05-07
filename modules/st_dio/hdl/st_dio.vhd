library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity st_dio is
    port (
        clk_i : in  std_logic;
        -- IO pad
        io : inout std_logic;
        -- Block Input and Outputs
        in_val_o : out std_logic;
        out_val_i : in std_logic;
        -- Block Parameters
        OUT_DIR_REG : in std_logic_vector(31 downto 0)
    );
end;

architecture rtl of st_dio is
    signal iobuf_out : std_logic;
begin
    iobuf_inst : IOBUF port map (
       I => out_val_i,
       O => iobuf_out,
       IO => io,
       T => not OUT_DIR_REG(0)
    );
    syncer : entity work.IDDR_sync_bit port map (
        clk_i => clk_i,
        bit_i => iobuf_out,
        bit_o => in_val_o
    );
end;
