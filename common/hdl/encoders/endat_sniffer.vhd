--------------------------------------------------------------------------------
--  PandA Motion Project
--      Diamond Light Source, Oxford, UK
--------------------------------------------------------------------------------
--
--  Description : EnDat sniffer, passively decodes the position from the clock
--                and data lines between an external master and an encoder.
--                Only the EnDat 2.1 mode command "encoder send position
--                value" (000111) is decoded, frames carrying any other
--                command are skipped. The data line is sampled on the
--                falling edges of the clock: the six mode bits, then once the
--                encoder has taken the line low the start bit, the error bit
--                F1, the position (LSB first) and the CRC-5 (MSB first).
--                The clock period is measured at the start of each frame and
--                the frame is over once the clock has been idle for two
--                periods, which also resynchronises the sniffer if it starts
--                in the middle of a frame.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity endat_sniffer is
generic (
    -- A position frame must complete within this many clk_i cycles of the
    -- previous one, otherwise the link is reported down once the sniffer is
    -- idle, a frame in progress is left to complete
    TIMEOUT : natural := 25000000;  -- 0.2s
    F1_IGNORED : boolean := false;  -- ignore the F1 error bit
    F1_ERROR_VALUE : std_logic := '0'
);
port (
    clk_i : in  std_logic;
    reset_i : in  std_logic;
    -- Block Parameters
    BITS : in  std_logic_vector(5 downto 0);
    link_up_o : out std_logic;
    health_o : out std_logic_vector(31 downto 0);
    -- Encoder lines
    endat_sck_i : in  std_logic;
    endat_dat_i : in  std_logic;
    -- Block Outputs
    posn_o : out std_logic_vector(31 downto 0);
    posn_valid_o : out std_logic
);
end;

architecture rtl of endat_sniffer is

-- Encoder send position value
constant MODE_COMMAND : std_logic_vector(5 downto 0) := "000111";

-- Health codes, matching the INENC HEALTH enum
constant HEALTH_OK : std_logic_vector(31 downto 0) := to_svector(0, 32);
-- No position frame completed within TIMEOUT, or the clock stopped before
-- the end of a position frame
constant HEALTH_TIMEOUT : std_logic_vector(31 downto 0) := to_svector(2, 32);
-- Received CRC does not match the calculated one
constant HEALTH_CRC : std_logic_vector(31 downto 0) := to_svector(3, 32);
-- Encoder reported an error in F1
constant HEALTH_ERROR_BIT : std_logic_vector(31 downto 0) := to_svector(4, 32);

--MA ````\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/```````
--DA _________| M2  M1  M0 !M2 !M1 !M0 |              | S | F1 | POS 0..N |  CRC  |```tm```\__
--             <- master drives data -> <-  tcal   ->  <---- encoder drives data ---->

type state_t is (STATE_IDLE, STATE_GAP, STATE_MODE, STATE_SKIP,
                 STATE_TURNAROUND1, STATE_TURNAROUND2, STATE_TCAL, STATE_ERRBIT,
                 STATE_POSN, STATE_CRC, STATE_RESULT);

signal state : state_t;

-- Registered inputs and falling edge of the clock
signal sck_d1 : std_logic;
signal sck_d2 : std_logic;
signal dat_d1 : std_logic;
signal sck_fall : std_logic;

-- Clock period measurement and end of frame detection
signal fall_cnt : unsigned(31 downto 0);
signal period : unsigned(31 downto 0);
signal period_valid : std_logic := '0';
signal clock_stopped : std_logic;

signal timeout_cnt : natural range 0 to TIMEOUT := 0;

-- BITS latched at the start of each frame
signal bits_lat : unsigned(5 downto 0);

signal bit_cnt : unsigned(7 downto 0);
signal mode_sr : std_logic_vector(5 downto 0);
signal err_bit : std_logic;
signal posn_sr : std_logic_vector(31 downto 0);
signal crc_rx : std_logic_vector(4 downto 0);

signal crc_reset : std_logic;
signal crc_bit : std_logic;
signal crc_strb : std_logic;
signal crc_calc : std_logic_vector(4 downto 0);
signal configured : std_logic := '0';

begin

--------------------------------------------------------------------------
-- Register the encoder lines, data is sampled on the falling edge of the
-- clock
--------------------------------------------------------------------------
ps_sync: process(clk_i)
begin
    if rising_edge(clk_i) then
        sck_d1 <= endat_sck_i;
        sck_d2 <= sck_d1;
        dat_d1 <= endat_dat_i;
        configured <= (or BITS);
    end if;
end process;

sck_fall <= sck_d2 and not sck_d1;

--------------------------------------------------------------------------
-- Cycles since the last falling edge of the clock, saturating. The clock
-- has stopped once this reaches twice the measured period.
--------------------------------------------------------------------------
ps_fall: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i or sck_fall then
            fall_cnt <= to_unsigned(1, fall_cnt'length);
        elsif not (and fall_cnt) then
            fall_cnt <= fall_cnt + 1;
        end if;
    end if;
end process;

clock_stopped <= period_valid when fall_cnt(31 downto 1) >= period else '0';

--------------------------------------------------------------------------
-- Frame state machine
--------------------------------------------------------------------------
ps_stat: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i then
            state <= STATE_IDLE;
            period_valid <= '0';
            timeout_cnt <= 0;
            crc_reset <= '0';
            crc_strb <= '0';
            posn_valid_o <= '0';
            posn_o <= (others => '0');
            link_up_o <= '0';
            health_o <= HEALTH_TIMEOUT;
        else
            crc_reset <= '0';
            crc_strb <= '0';
            crc_bit <= dat_d1;
            posn_valid_o <= '0';

            case state is
                -- The first falling edge of the clock starts a frame and
                -- latches the position
                when STATE_IDLE =>
                    period_valid <= '0';
                    if sck_fall and configured then
                        crc_reset <= '1';
                        bit_cnt <= (others => '0');
                        posn_sr <= (others => '0');
                        bits_lat <= unsigned(BITS);
                        state <= STATE_GAP;
                    end if;
                    if timeout_cnt = TIMEOUT - 1 then
                        link_up_o <= '0';
                        health_o <= HEALTH_TIMEOUT;
                    else
                        timeout_cnt <= timeout_cnt + 1;
                    end if;

                when STATE_GAP =>
                    if sck_fall then
                        period_valid <= '1';
                        period <= fall_cnt;
                        state <= STATE_MODE;
                    end if;

                -- Mode command, MSB first, driven by the master
                when STATE_MODE =>
                    if sck_fall then
                        period <= fall_cnt;
                        mode_sr <= mode_sr(4 downto 0) & dat_d1;
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = 5 then
                            bit_cnt <= (others => '0');
                            if (mode_sr(4 downto 0) & dat_d1) = MODE_COMMAND then
                                state <= STATE_TURNAROUND1;
                            else
                                state <= STATE_SKIP;
                            end if;
                        end if;
                    end if;

                -- Not a position request, wait for the end of the frame
                when STATE_SKIP =>
                    if clock_stopped then
                        state <= STATE_IDLE;
                    end if;

                when STATE_TURNAROUND1 =>
                    if sck_fall then
                        state <= STATE_TURNAROUND2;
                    end if;

                -- The master has released the data line, wait until the
                -- encoder holds it low. The last mode bit may still be on
                -- the line and must not be taken for the start bit.
                when STATE_TURNAROUND2 =>
                    if sck_fall and not dat_d1 then
                        state <= STATE_TCAL;
                    end if;

                -- Encoder holds the data line low until the start bit
                when STATE_TCAL =>
                    if sck_fall and dat_d1 then
                        state <= STATE_ERRBIT;
                    end if;

                -- Error bit F1
                when STATE_ERRBIT =>
                    if sck_fall then
                        crc_strb <= '1';
                        err_bit <= dat_d1;
                        state <= STATE_POSN;
                    end if;

                -- Position, LSB first, only the 32 LSBs are kept
                when STATE_POSN =>
                    if sck_fall then
                        crc_strb <= '1';
                        if bit_cnt < 32 then
                            posn_sr(to_integer(bit_cnt(4 downto 0))) <= dat_d1;
                        end if;
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = bits_lat - 1 then
                            bit_cnt <= (others => '0');
                            state <= STATE_CRC;
                        end if;
                    end if;

                -- CRC, MSB first
                when STATE_CRC =>
                    if sck_fall then
                        crc_rx <= crc_rx(3 downto 0) & dat_d1;
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = 4 then
                            state <= STATE_RESULT;
                        end if;
                    end if;

                when STATE_RESULT =>
                    timeout_cnt <= 0;
                    if crc_rx /= crc_calc then
                        link_up_o <= '0';
                        health_o <= HEALTH_CRC;
                    elsif (not F1_IGNORED) and err_bit = F1_ERROR_VALUE then
                        link_up_o <= '0';
                        health_o <= HEALTH_ERROR_BIT;
                    else
                        posn_o <= posn_sr;
                        posn_valid_o <= '1';
                        link_up_o <= '1';
                        health_o <= HEALTH_OK;
                    end if;
                    state <= STATE_IDLE;
            end case;

            -- The clock stopped before the end of a position frame
            if clock_stopped = '1'
                    and state /= STATE_IDLE
                    and state /= STATE_SKIP
                    and state /= STATE_RESULT then
                timeout_cnt <= 0;
                link_up_o <= '0';
                health_o <= HEALTH_TIMEOUT;
                state <= STATE_IDLE;
            end if;
        end if;
    end if;
end process;

endat_crc_inst : entity work.endat_crc
port map (
    clk_i           => clk_i,
    reset_i         => reset_i or crc_reset,
    bitval_i        => crc_bit,
    bitstrb_i       => crc_strb,
    crc_o           => crc_calc
);

end;
