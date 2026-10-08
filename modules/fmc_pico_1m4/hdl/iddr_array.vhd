-- Array of IDDR
--
-- Input DDR registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity iddr_array is
    generic (
        COUNT : natural := 1
    );
    port (
        clk_i : in std_ulogic;
        d_i : in std_ulogic_vector(COUNT-1 downto 0);
        q1_o : out std_ulogic_vector(COUNT-1 downto 0);
        q2_o : out std_ulogic_vector(COUNT-1 downto 0)
    );
end;

architecture arch of iddr_array is
begin
    iddr_array : for i in 0 to COUNT-1 generate
        iddr_inst : IDDR generic map (
            DDR_CLK_EDGE => "SAME_EDGE_PIPELINED",
            -- Setting this allows this definition to be shared between 7-series
            -- and ultrascale
            SRTYPE => "ASYNC"
        ) port map (
            S => '0',
            C => clk_i,
            CE => '1',
            D => d_i(i),
            Q1 => q1_o(i),
            Q2 => q2_o(i)
        );
    end generate;
end;
