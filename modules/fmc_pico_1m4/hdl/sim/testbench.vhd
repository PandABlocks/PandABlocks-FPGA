library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.support.all;

entity testbench is
end testbench;


architecture arch of testbench is
    signal clk : std_ulogic := '0';

    procedure clk_wait(count : in natural := 1) is
        variable i : natural;
    begin
        for i in 0 to count-1 loop
            wait until rising_edge(clk);
        end loop;
    end procedure;

--     constant CLOCK_FREQUENCY : natural := 215;
    constant CLOCK_FREQUENCY : natural := 250;
    constant CLOCK_DIVISOR : natural := 5;
    constant DATA_BITS : natural := 20;

    signal start : std_ulogic;
    signal busy : std_ulogic;
    signal valid : std_ulogic;
    signal data : signed_array(0 to 3)(DATA_BITS-1 downto 0);
    signal range_control : std_ulogic_vector(0 to 3) := "0000";

    signal FMC_LA_P : std_logic_vector(0 to 33);
    signal FMC_LA_N : std_logic_vector(0 to 33);

begin
    clk <= not clk after 1000 ns / CLOCK_FREQUENCY / 2;

    fmc : entity work.fmc_pico_1m4_top generic map (
        CLOCK_DIVISOR => CLOCK_DIVISOR,
        DATA_BITS => DATA_BITS
    ) port map (
        clk_i => clk,

        start_i => start,
        busy_o => busy,
        valid_o => valid,
        data_o => data,
        range_i => range_control,

        FMC_LA_P => FMC_LA_P,
        FMC_LA_N => FMC_LA_N
    );


    -- Simulation of FMC
    sim_fmc : entity work.sim_pico generic map (
        DATA_BITS => DATA_BITS,
        -- Adding this much doubt on the clock data skew gives a worst hold time
        -- of -4.5 ns which is less than one clock tick at 215 MHz (4.65 ns) and
        -- so is compatible with the default CLOCK_DATA_DELAY of 1.  The default
        -- datasheet value of -1.5 ns seems a little optimistic in the face of
        -- possible device variation.
--         T_DOUBT => 3 ns
        T_DOUBT => 1.4 ns
    ) port map (
        cnv_i => FMC_LA_P(4),
        sck_i => FMC_LA_N(4),
        sck_rtrn_o => FMC_LA_P(8),
        sdo_o(0) => FMC_LA_N(11),
        sdo_o(1) => FMC_LA_P(11),
        sdo_o(2) => FMC_LA_N(7),
        sdo_o(3) => FMC_LA_P(7),
        busy_cmn_o => FMC_LA_N(8)
    );

    -- I2C not simulated, just pulled high
    FMC_LA_P(23) <= 'H';
    FMC_LA_N(23) <= 'H';


    -- Exercise device
    process begin
        start <= '0';
        clk_wait(5);

        -- Request capture as fast as we can
        loop
            start <= '1';
            clk_wait;
            start <= '0';
            wait until not busy;
            clk_wait;
        end loop;

        wait;
    end process;


    -- Print captured result
    process (clk)
        function check_ok(value : signed) return boolean is
        begin
            for n in value'RANGE loop
                case value(n) is
                    when '0' | '1' =>
                    when others =>
                        return false;
                end case;
            end loop;
            return true;
        end;

        variable linebuffer : line;
        variable ok : boolean;

    begin
        if rising_edge(clk) then
            if valid then
                write(linebuffer,
                    "@ " & to_string(now, unit => ns) &
                    " Captured: [ ");
                ok := true;
                for n in data'RANGE loop
                    write(linebuffer, to_hstring(data(n)) & " ");
                    ok := ok and check_ok(data(n));
                end loop;
                write(linebuffer, string'("]"));
                if not ok then
                    write(linebuffer, string'(" <<<"));
                end if;
                writeline(output, linebuffer);
            end if;
        end if;
    end process;
end;
