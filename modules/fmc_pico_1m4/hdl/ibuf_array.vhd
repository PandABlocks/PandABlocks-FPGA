-- Array of IBUF
--
-- Singled ended input buffers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ibuf_array is
    generic (
        COUNT : natural := 1;
        IOSTANDARD : string := "DEFAULT"
    );
    port (
        i_i : in std_ulogic_vector(COUNT-1 downto 0);
        o_o : out std_ulogic_vector(COUNT-1 downto 0)
    );
end;

architecture arch of ibuf_array is
begin
    ibuf_array : for i in 0 to COUNT-1 generate
        ibuf_inst : IBUF generic map (
            IOSTANDARD => IOSTANDARD
        ) port map (
            I => i_i(i),
            O => o_o(i)
        );
    end generate;
end;
