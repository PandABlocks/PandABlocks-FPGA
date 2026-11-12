-- Rising edge detector.

library ieee;
use ieee.std_logic_1164.all;

entity edge_detect is
    generic (
        REGISTER_EDGE : boolean := true;
        INITIAL_STATE : std_ulogic := '0';
        WIDTH : natural := 1
    );
    port (
        clk_i : in std_ulogic;
        data_i : in std_ulogic_vector;
        edge_o : out std_ulogic_vector
    );
end;

architecture arch of edge_detect is
    signal last_data : std_ulogic_vector(data_i'RANGE)
        := (others => INITIAL_STATE);
    signal edge : std_ulogic_vector(edge_o'RANGE);
    signal edge_out : std_ulogic_vector(edge_o'RANGE) := (others => '0');

begin
    edge <= data_i and not last_data;
    process (clk_i) begin
        if rising_edge(clk_i) then
            last_data <= data_i;
        end if;
    end process;

    gen_reg : if REGISTER_EDGE generate
        process (clk_i) begin
            if rising_edge(clk_i) then
                edge_out <= edge;
            end if;
        end process;
        edge_o <= edge_out;
    else generate
        edge_o <= edge;
    end generate;
end;
