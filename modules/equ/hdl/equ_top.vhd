library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity equ_top is
port (
    -- Clocks and Resets
    clk_i               : in  std_logic;
    -- EQU I/O
    equ_i               : in  std_logic_vector(EQU_NUM-1 downto 0);
    val_o               : out std_logic_vector(EQU_NUM-1 downto 0)
);
end equ_top;

architecture rtl of equ_top is

begin

-- Syncroniser for each input
EQU_GEN : FOR I IN 0 TO EQU_NUM-1 GENERATE

    syncer : entity work.IDDR_sync_bit
    port map (
        clk_i   => clk_i,
        bit_i   => equ_i(I),
        bit_o   => val_o(I)
    );

END GENERATE;

end rtl;
