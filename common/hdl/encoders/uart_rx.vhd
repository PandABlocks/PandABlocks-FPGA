--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- WEBSITE: https://github.com/jakubcabal/uart-for-fpga
--------------------------------------------------------------------------------
-- Modified for the Zygo ZMI serial interface: fixed 48 data bits per frame,
-- no parity, input synchroniser, false start rejection, stop bit check on
-- frame bit 49.
--------------------------------------------------------------------------------
-- The MIT License (MIT)
--
-- Copyright (c) 2015 Jakub Cabal
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_RX is
    Generic (
        CLK_DIV_VAL : integer := 16
    );
    Port (
        CLK          : in  std_logic; -- system clock
        RST          : in  std_logic; -- high active synchronous reset
        -- UART INTERFACE
        UART_CLK_EN  : in  std_logic; -- oversampling UART clock enable
        UART_RXD     : in  std_logic; -- serial receive data
        -- USER DATA OUTPUT INTERFACE
        DOUT         : out std_logic_vector(47 downto 0); -- frame bits 1..48
        DOUT_VLD     : out std_logic; -- frame received, stop bit ok (one clock cycle)
        FRAME_ERROR  : out std_logic  -- frame received, stop bit invalid (one clock cycle)
    );
end entity;

architecture RTL of UART_RX is

    -- Number of data bits between start and stop bit
    constant DATA_BITS        : integer := 48;

    signal rx_clk_en          : std_logic;
    signal rx_data            : std_logic_vector(DATA_BITS-1 downto 0);
    signal rx_bit_count       : unsigned(5 downto 0);
    signal rx_done            : std_logic;
    signal fsm_idle           : std_logic;
    signal fsm_databits       : std_logic;
    signal fsm_stopbit        : std_logic;
    signal rxd_meta           : std_logic := '1';
    signal rxd_sync           : std_logic := '1';

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of rxd_meta : signal is "TRUE";
    attribute ASYNC_REG of rxd_sync : signal is "TRUE";

    type state is (idle, startbit, databits, stopbit);
    signal fsm_pstate : state;
    signal fsm_nstate : state;

begin

    -- -------------------------------------------------------------------------
    -- INPUT SYNCHRONISER (UART_RXD is asynchronous to CLK)
    -- -------------------------------------------------------------------------

    rxd_sync_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            rxd_meta <= UART_RXD;
            rxd_sync <= rxd_meta;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RECEIVER CLOCK DIVIDER AND CLOCK ENABLE FLAG
    -- -------------------------------------------------------------------------

    rx_clk_divider_i : entity work.UART_CLK_DIV
    generic map(
        DIV_MAX_VAL  => CLK_DIV_VAL,
        DIV_MARK_POS => 1
    )
    port map (
        CLK      => CLK,
        RST      => RST,
        CLEAR    => fsm_idle,
        ENABLE   => UART_CLK_EN,
        DIV_MARK => rx_clk_en
    );

    -- -------------------------------------------------------------------------
    -- UART RECEIVER BIT COUNTER
    -- -------------------------------------------------------------------------

    uart_rx_bit_counter_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                rx_bit_count <= (others => '0');
            elsif (rx_clk_en = '1' AND fsm_databits = '1') then
                if (rx_bit_count = DATA_BITS-1) then
                    rx_bit_count <= (others => '0');
                else
                    rx_bit_count <= rx_bit_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RECEIVER DATA SHIFT REGISTER
    -- -------------------------------------------------------------------------

    uart_rx_data_shift_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (rx_clk_en = '1' AND fsm_databits = '1') then
                rx_data <= rxd_sync & rx_data(DATA_BITS-1 downto 1);
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RECEIVER OUTPUT REGISTER
    -- -------------------------------------------------------------------------

    -- Sampling point of the stop bit
    rx_done <= rx_clk_en and fsm_stopbit;

    uart_rx_output_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                DOUT_VLD     <= '0';
                FRAME_ERROR  <= '0';
            else
                DOUT_VLD     <= rx_done and rxd_sync;
                FRAME_ERROR  <= rx_done and not rxd_sync;
            end if;
            if (rx_done = '1') then
                DOUT <= rx_data;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RECEIVER FSM
    -- -------------------------------------------------------------------------

    -- PRESENT STATE REGISTER
    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                fsm_pstate <= idle;
            else
                fsm_pstate <= fsm_nstate;
            end if;
        end if;
    end process;

    -- NEXT STATE AND OUTPUTS LOGIC
    process (fsm_pstate, rxd_sync, rx_clk_en, rx_bit_count)
    begin
        case fsm_pstate is

            when idle =>
                fsm_stopbit  <= '0';
                fsm_databits <= '0';
                fsm_idle     <= '1';

                if (rxd_sync = '0') then
                    fsm_nstate <= startbit;
                else
                    fsm_nstate <= idle;
                end if;

            when startbit =>
                fsm_stopbit  <= '0';
                fsm_databits <= '0';
                fsm_idle     <= '0';

                -- Start bit must still be low in the middle of the bit,
                -- otherwise it was a glitch (false start)
                if (rx_clk_en = '1' AND rxd_sync = '0') then
                    fsm_nstate <= databits;
                elsif (rx_clk_en = '1') then
                    fsm_nstate <= idle;
                else
                    fsm_nstate <= startbit;
                end if;

            when databits =>
                fsm_stopbit  <= '0';
                fsm_databits <= '1';
                fsm_idle     <= '0';

                if ((rx_clk_en = '1') AND (rx_bit_count = DATA_BITS-1)) then
                    fsm_nstate <= stopbit;
                else
                    fsm_nstate <= databits;
                end if;

            when stopbit =>
                fsm_stopbit  <= '1';
                fsm_databits <= '0';
                fsm_idle     <= '0';

                if (rx_clk_en = '1') then
                    fsm_nstate <= idle;
                else
                    fsm_nstate <= stopbit;
                end if;

            when others =>
                fsm_stopbit  <= '0';
                fsm_databits <= '0';
                fsm_idle     <= '0';
                fsm_nstate   <= idle;

        end case;
    end process;

end architecture;
