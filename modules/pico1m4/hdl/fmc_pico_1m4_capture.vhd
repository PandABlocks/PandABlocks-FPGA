-- Data capture control
--
-- Strobe start_i to initiate conversion, valid_o will be strobed and data_o
-- will become valid after conversion and capture is complete.  busy_o will be
-- high during conversion and data capture, and during this time start_i will
-- be ignored.
--
-- Note that if the hardware is unresponsive then valid_o may never be asserted
-- and busy_o will remain high indefinitely.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

entity fmc_pico_1m4_capture is
    generic (
        DATA_BITS : natural := 20;
        -- Ratio between incoming clock and capture clock.
        CLOCK_DIVISOR : natural;
        -- Delay for sampling data.  This must be at least 1 to allow for
        -- negative data hold time (arising from clock/data skew from isolators
        -- and level converters on the FMC).
        CLOCK_DATA_DELAY : natural := 1
    );
    port (
        clk_i : in std_ulogic;

        -- ADC hardware interface
        cnv_o : out std_ulogic;
        sck_o : out std_ulogic;
        sck_rtrn_i : in std_ulogic;
        sdo_i : in std_ulogic_vector(0 to 3);
        busy_cmn_i : in std_ulogic;

        -- Capture control
        start_i : in std_ulogic;        -- Pulse to start conversion
        busy_o : out std_ulogic;        -- Data capture in progress

        -- Data returned
        valid_o : out std_ulogic;       -- Strobed on data ready out
        data_o : out signed_array(0 to 3)(DATA_BITS-1 downto 0)
    );
end;

architecture arch of fmc_pico_1m4_capture is
    constant TICK_COUNTER_BITS : natural := bits(CLOCK_DIVISOR - 1);
    signal tick_counter : unsigned(TICK_COUNTER_BITS-1 downto 0)
        := to_unsigned(CLOCK_DIVISOR - 1, TICK_COUNTER_BITS);
    constant HALF_TICK_COUNT : natural := CLOCK_DIVISOR / 2;

    constant CLOCK_COUNTER_BITS : natural := bits(DATA_BITS - 1);
    signal clock_counter : unsigned(CLOCK_COUNTER_BITS-1 downto 0)
        := to_unsigned(DATA_BITS - 1, CLOCK_COUNTER_BITS);
    signal capture_counter : unsigned(CLOCK_COUNTER_BITS-1 downto 0)
        := to_unsigned(DATA_BITS - 1, CLOCK_COUNTER_BITS);

    signal adc_busy : std_ulogic;
    signal clock_out : std_ulogic := '1';
    signal sck_rtrn : std_ulogic;

    signal sdo_in : std_ulogic_vector(0 to 3);
    signal sdo_in_delay : std_ulogic_vector(0 to 3);

    type adc_state_t is (IDLE, WAIT_BUSY, WAIT_READY, TRANSFER, WAIT_DONE);
    signal adc_state : adc_state_t := IDLE;

    signal capture_edge : std_ulogic;
    signal last_capture : std_ulogic;

begin
    -- Synchroniser for all inputs
    sync_busy : entity work.iddr_array generic map (
        COUNT => 6
    ) port map (
        clk_i => clk_i,
        d_i(3 downto 0) => sdo_i,
        d_i(4) => busy_cmn_i,
        d_i(5) => sck_rtrn_i,
        q1_o(3 downto 0) => sdo_in,
        q1_o(4) => adc_busy,
        q1_o(5) => sck_rtrn
    );

    -- Delay data to align with clock.  This needs to take the synchroniser
    -- delay into account as well as an extra tick
    data_delay : entity work.fixed_delay generic map (
        WIDTH => 4,
        DELAY => 1 + CLOCK_DATA_DELAY
    ) port map (
        clk_i => clk_i,
        data_i => sdo_in,
        data_o => sdo_in_delay
    );

    -- Detect rising edge of incoming clock
    edge_detect : entity work.edge_detect generic map (
        REGISTER_EDGE => false,
        INITIAL_STATE => '1'
    ) port map (
        clk_i => clk_i,
        data_i(0) => sck_rtrn,
        edge_o(0) => capture_edge
    );


    process (clk_i) begin
        if rising_edge(clk_i) then
            -- Simple state machine: wait for start, wait for busy high, wait
            -- for busy low, wait for transfer counter generation to complete,
            -- wait for data capture to complete.
            --   If there is no response from the hardware we can lock up in
            -- any of the WAIT_ states; this will need to be allowed for
            -- elsewhere.
            case adc_state is
                when IDLE =>
                    -- Wait for start command
                    if start_i then
                        adc_state <= WAIT_BUSY;
                    end if;
                when WAIT_BUSY =>
                    -- Wait for busy to go high
                    if adc_busy then
                        adc_state <= WAIT_READY;
                    end if;
                when WAIT_READY =>
                    -- Now wait for busy to go low
                    if not adc_busy then
                        adc_state <= TRANSFER;
                    end if;
                when TRANSFER =>
                    if tick_counter = 0 and clock_counter = 0 then
                        adc_state <= WAIT_DONE;
                    end if;
                when WAIT_DONE =>
                    -- Can't initiate next capture until transfer complete
                    if last_capture then
                        adc_state <= IDLE;
                    end if;
            end case;

            -- Generate data transfer clock during TRANSFER state
            if adc_state = TRANSFER then
                if tick_counter > 0 then
                    tick_counter <= tick_counter - 1;
                    if tick_counter = HALF_TICK_COUNT then
                        clock_out <= '0';
                    end if;
                else
                    tick_counter <=
                        to_unsigned(CLOCK_DIVISOR - 1, TICK_COUNTER_BITS);
                    clock_out <= '1';
                    if clock_counter > 0 then
                        clock_counter <= clock_counter - 1;
                    else
                        clock_counter <=
                            to_unsigned(DATA_BITS - 1, CLOCK_COUNTER_BITS);
                    end if;
                end if;
            end if;

            -- Capture incoming data on rising edge of sck_rtrn
            if capture_edge then
                for n in data_o'RANGE loop
                    data_o(n) <=
                        data_o(n)(DATA_BITS-2 downto 0) & sdo_in_delay(n);
                end loop;
                if capture_counter > 0 then
                    capture_counter <= capture_counter - 1;
                else
                    capture_counter <=
                        to_unsigned(DATA_BITS - 1, CLOCK_COUNTER_BITS);
                end if;
            end if;
            last_capture <= capture_edge and to_std_ulogic(capture_counter = 0);
        end if;
    end process;

    cnv_o <= to_std_ulogic(adc_state = WAIT_BUSY or adc_state = WAIT_READY);
    sck_o <= clock_out;
    busy_o <= to_std_ulogic(adc_state /= IDLE);
    valid_o <= last_capture;
end;
