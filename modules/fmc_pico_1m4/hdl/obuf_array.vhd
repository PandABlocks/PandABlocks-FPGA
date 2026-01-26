-- Array of OBUF
--
-- Singled ended output buffers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity obuf_array is
    generic (
        COUNT : natural := 1;
        IOSTANDARD : string := "DEFAULT"
    );
    port (
        i_i : in std_ulogic_vector(COUNT-1 downto 0);
        o_o : out std_ulogic_vector(COUNT-1 downto 0)
    );
end;

architecture arch of obuf_array is
begin
    obuf_array : for i in 0 to COUNT-1 generate
        obuf_inst : OBUF generic map (
            IOSTANDARD => IOSTANDARD
        ) port map (
            I => i_i(i),
            O => o_o(i)
        );
    end generate;
end;
