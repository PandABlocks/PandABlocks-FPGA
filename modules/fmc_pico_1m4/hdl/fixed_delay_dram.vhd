-- Fixed delay in distributed memory, or in registers if KEEP_REG = "true"
--
-- If DELAY is zero then no delay is generated.

library ieee;
use ieee.std_logic_1164.all;

entity fixed_delay_dram is
    generic (
        DELAY : natural := 1;
        WIDTH  : natural := 1;
        INITIAL : std_ulogic := '0';
        KEEP_REG : string := "false"
    );
    port (
        clk_i : in std_ulogic;
        enable_i : in std_ulogic := '1';
        data_i : in std_ulogic_vector(WIDTH-1 downto 0);
        data_o : out std_ulogic_vector(WIDTH-1 downto 0)
    );
end;

architecture arch of fixed_delay_dram is
    type dlyline_t is array(0 to DELAY) of std_ulogic_vector(WIDTH-1 downto 0);
    signal dlyline : dlyline_t := (others => (others => INITIAL));

    attribute KEEP : string;
    attribute KEEP of dlyline : signal is KEEP_REG;

begin
    dlyline(0) <= data_i;

    -- This is annoying.  Vsim gets confused if we put this loop inside the
    -- process, and ends up complaining that dlyline(0) has multiple
    -- assignments.  However, using a generate loop like this seems to fix it.
    gen_loop : for i in 1 to DELAY generate
        process (clk_i) begin
            if rising_edge(clk_i) then
                if enable_i then
                    dlyline(i) <= dlyline(i - 1);
                end if;
            end if;
        end process;
    end generate;

    data_o <= dlyline(DELAY);
end;
