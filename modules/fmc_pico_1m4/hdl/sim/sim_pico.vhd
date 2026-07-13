-- Simulation for FMC-Pico-1M4 device

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

entity sim_pico is
    generic (
        DATA_BITS : natural := 20;
        -- Timings taken from FMC-Pico-1M4 User's Manual, mostly derived
        -- directly from the ADC specification
        T_CONV : time := 675 ns;        -- Conversion time      615..675
        T_BUSYLH : time := 39 ns;       -- CNV to BUSY          ..(25)..39
        T_DSDOBUSYL : time := 7.5 ns;   -- Busy to data valid   ..7.5
        -- We sweep the clock delay to probe synchroniser behaviour
        -- T_DLY : time := 28 ns;          -- SCK to SCK_RTRN      20..(16)..28
        T_DLY_min : time := 20 ns;
        T_DLY_max : time := 28 ns;
        -- The data window timings are more tricky and take into account some of
        -- the skew introduced by extra components on the FMC.  Note that
        -- these can all be derived from the datasheets for the relevant
        -- components:
        --  ADC LTC2378-20
        --      t_HSDO = 1 ns, t_DSDO = 8 ns
        --  Si8660 signal isolator (300V isolation)
        --      maximum channel skew t_PSK = 2.5 ns
        --  SN74AVC4T245RSVR level shifter
        --      unpredictable delay between 0.3 and 3.9 ns
        -- This last factor is *not* taken into account in the official data
        -- window timings below, and we are apparently relying on constrained
        -- component and temperature variation to keep us lucky.  Therefore it
        -- seems wise to design in a certain extra uncertainty factor.
        T_DSDO : time := 10.5 ns;       -- Data valid delay     ..10.5
        T_HSDO : time := -1.5 ns;       -- Data hold delay      -1.5..
        -- This is a doubt factor designed to be added to T_DSDO and T_HSDL to
        -- allow for uncertainty about extra sources of skew
        T_DOUBT : time := 0 ns
    );
    port (
        -- ADC Interface
        cnv_i : in std_ulogic;                  -- Start conversion on edge
        sck_i : in std_ulogic;                  -- Serial clock for result
        sck_rtrn_o : out std_ulogic;            -- Return clock data aligned
        sdo_o : out std_ulogic_vector(3 downto 0);  -- Data output from ADCs
        busy_cmn_o : out std_ulogic             -- Busy during conversion
    );
end;

architecture arch of sim_pico is
    signal counter : natural := 0;
    signal data_out : signed_array(3 downto 0)(DATA_BITS-1 downto 0);
    signal early_sck : std_ulogic := '1';
    signal delay : time := T_DLY_min;

begin
    sck_rtrn_o <= transport sck_i after delay;
    early_sck <= transport sck_i after delay + T_HSDO - T_DOUBT;

    process
        procedure capture_data is
        begin
            counter <= counter + 1;
            for n in data_out'RANGE loop
                if DATA_BITS > 4 then
                    data_out(n) <=
                        to_signed(counter, DATA_BITS-4) & to_signed(n, 4);
                else
                    data_out(n) <= to_signed(n, DATA_BITS);
                end if;
            end loop;
        end;

        procedure emit_sdo is
        begin
            for n in data_out'RANGE loop
                sdo_o(n) <= data_out(n)(DATA_BITS-1);
                data_out(n) <= data_out(n)(DATA_BITS-2 downto 0) & 'U';
            end loop;
        end;

    begin
        busy_cmn_o <= '0';

        loop
            -- Wait for conversion request, assert busy until conversion is
            -- complete, compute captured data, all with appropriate delays
            if not cnv_i then
                wait until cnv_i;
            end if;
            wait for T_BUSYLH;

            if delay < T_DLY_max then
                delay <= delay + 1 ns;
            else
                delay <= T_DLY_min;
            end if;

            busy_cmn_o <= '1';
            wait for T_CONV;
            busy_cmn_o <= '0';
            -- Capture complete
            capture_data;
            wait for T_DSDOBUSYL;

            -- Emit one bit at a time until new conversion requested
            emit_sdo;
            loop
                wait until cnv_i = '1' or rising_edge(early_sck);
                sdo_o <= (others => 'U');
                if cnv_i then
                    exit;
                else
                    wait for T_DSDO - T_HSDO + 2 * T_DOUBT;
                    emit_sdo;
                end if;
            end loop;
        end loop;
    end process;
end;
