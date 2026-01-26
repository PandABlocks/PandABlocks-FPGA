-- Array of IOBUF
--
-- Singled ended tri-stateable IO buffers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity iobuf_array is
    generic (
        COUNT : natural := 1;
        IOSTANDARD : string := "DEFAULT"
    );
    port (
        i_i : in std_ulogic_vector(COUNT-1 downto 0);
        t_i : in std_ulogic_vector(COUNT-1 downto 0);
        o_o : out std_ulogic_vector(COUNT-1 downto 0);
        io_io : inout std_logic_vector(COUNT-1 downto 0)
    );
end;

architecture arch of iobuf_array is
begin
    iobuf_array : for i in 0 to COUNT-1 generate
        ibuf_inst : IOBUF generic map (
            IOSTANDARD => IOSTANDARD
        ) port map (
            T => t_i(i),
            I => i_i(i),
            O => o_o(i),
            IO => io_io(i)
        );
    end generate;
end;
