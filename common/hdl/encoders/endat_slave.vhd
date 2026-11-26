--------------------------------------------------------------------------------
--  PandA Motion Project
--      Diamond Light Source, Oxford, UK
--------------------------------------------------------------------------------
--
--  Description : EnDat slave, answers position requests from an external
--                master with the position on posn_i. Only the EnDat 2.1 mode
--                command "encoder send position value" (000111) is answered,
--                frames carrying any other command are ignored with the data
--                line released.
--                The position is latched on the first falling edge of the
--                clock. The mode bits are read on the falling edges, then the
--                slave takes the data line over (endat_dat_oe_o) on the next
--                rising edge, holds it low for TCAL_CLOCKS clock periods and
--                sends the start bit, the error bit F1 (at F1_ERROR_VALUE
--                when GENERATOR_ERROR is set, the other level otherwise),
--                BITS position bits LSB first and the CRC-5 MSB first,
--                changing the data after each rising edge. After the last
--                CRC bit the line is held high for the recovery time and
--                then driven low again: like an encoder the slave holds the
--                data line low while idle, so a master waiting for the line
--                to go low before a frame sees a ready encoder, and only
--                releases it from the first falling edge of the clock for
--                the master's mode command.
--                The clock period is measured at the start of each frame so
--                the end of an ignored frame, or a master stopping its clock
--                part way through an answer, is detected after two periods
--                without a clock edge.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity endat_slave is
generic (
    -- Clock periods the data line is held low before the start bit
    TCAL_CLOCKS     : natural := 2;
    -- Level of the error bit F1 meaning an error, low for Heidenhain
    -- encoders
    F1_ERROR_VALUE  : std_logic := '0';
    -- Recovery time tm the data line is held high after a frame, in clk_i
    -- cycles
    RECOVERY        : natural := 1250       -- 10us
);
port (
    clk_i : in  std_logic;
    reset_i : in  std_logic;
    -- Block Parameters
    BITS : in  std_logic_vector(5 downto 0);
    GENERATOR_ERROR : in  std_logic;
    health_o : out std_logic_vector(31 downto 0);
    -- Block Inputs
    posn_i : in  std_logic_vector(31 downto 0);
    -- Encoder lines
    endat_sck_i : in  std_logic;
    endat_dat_i : in  std_logic;
    endat_dat_o : out std_logic;
    endat_dat_oe_o : out std_logic
);
end;

architecture rtl of endat_slave is

-- Encoder send position value
constant MODE_COMMAND : std_logic_vector(5 downto 0) := "000111";

-- Health codes, matching the OUTENC HEALTH enum
constant HEALTH_OK : std_logic_vector(31 downto 0) := to_svector(0, 32);
-- No position frame answered yet, or the master stopped its clock before
-- the end of the answer
constant HEALTH_TIMEOUT : std_logic_vector(31 downto 0) := to_svector(2, 32);

--MA ````\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/```````
--DA _________| M2  M1  M0 !M2 !M1 !M0 |              | S | F1 | POS 0..N |  CRC  |```tm```\__
--   <-slave-> <- master drives data -> <-  tcal   ->  <---- slave drives data ---------------->

type state_t is (STATE_IDLE, STATE_LATCH, STATE_MODE, STATE_SKIP,
                 STATE_TURNAROUND, STATE_TCAL, STATE_ERRBIT, STATE_POSN,
                 STATE_CRC, STATE_RECOVERY);

signal state : state_t;

-- Registered inputs and clock edges
signal sck_q : std_logic;
signal sck_qq : std_logic;
signal dat_q : std_logic;
signal sck_fall : std_logic;
signal sck_rise : std_logic;

-- Clock period measurement and end of frame detection
signal fall_cnt : unsigned(31 downto 0);
signal period : unsigned(31 downto 0);
signal period_valid : std_logic;
signal clock_stopped : std_logic;

signal recovery_cnt : natural range 0 to RECOVERY;

-- BITS and position latched at the start of each frame
signal bits_lat : unsigned(5 downto 0);
signal posn_lat : std_logic_vector(31 downto 0);

signal bit_cnt : unsigned(7 downto 0);
signal mode_sr : std_logic_vector(5 downto 0);
signal f1 : std_logic;
signal dat : std_logic;
signal dat_oe : std_logic;

signal crc_reset : std_logic;
signal crc_bit : std_logic;
signal crc_strb : std_logic;
signal crc_calc : std_logic_vector(4 downto 0);

begin

endat_dat_o <= dat;
endat_dat_oe_o <= dat_oe;

-- Error bit F1
f1 <= F1_ERROR_VALUE when GENERATOR_ERROR = '1' else not F1_ERROR_VALUE;

--------------------------------------------------------------------------
-- Register the encoder lines, the mode bits are sampled on the falling edge
-- of the clock and the answer is changed after the rising edge
--------------------------------------------------------------------------
ps_sync: process(clk_i)
begin
    if rising_edge(clk_i) then
        sck_q <= endat_sck_i;
        sck_qq <= sck_q;
        dat_q <= endat_dat_i;
    end if;
end process;

sck_fall <= sck_qq and not sck_q;
sck_rise <= sck_q and not sck_qq;

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
    variable next_mode_sr : std_logic_vector(5 downto 0);
begin
    if rising_edge(clk_i) then
        if reset_i then
            state <= STATE_IDLE;
            period_valid <= '0';
            crc_reset <= '0';
            crc_strb <= '0';
            dat <= '0';
            dat_oe <= '0';
            health_o <= HEALTH_TIMEOUT;
        else
            crc_reset <= '0';
            crc_strb <= '0';

            case state is
                -- The line is held low while idle. The first falling edge
                -- of the clock starts a frame, latches the position and
                -- releases the line for the master's mode command.
                when STATE_IDLE =>
                    dat <= '0';
                    dat_oe <= (or BITS);
                    if sck_fall and (or BITS) then
                        dat_oe <= '0';
                        period_valid <= '0';
                        crc_reset <= '1';
                        bit_cnt <= (others => '0');
                        bits_lat <= unsigned(BITS);
                        posn_lat <= posn_i;
                        state <= STATE_LATCH;
                    end if;

                -- Second clock period, measures the clock period
                when STATE_LATCH =>
                    if sck_fall then
                        period <= fall_cnt;
                        period_valid <= '1';
                        state <= STATE_MODE;
                    end if;

                -- Mode command, MSB first, driven by the master
                when STATE_MODE =>
                    if sck_fall then
                        period <= fall_cnt;
                        next_mode_sr := mode_sr(4 downto 0) & dat_q;
                        mode_sr <= next_mode_sr;
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = 5 then
                            bit_cnt <= (others => '0');
                            if next_mode_sr = MODE_COMMAND then
                                state <= STATE_TURNAROUND;
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

                -- The master releases the data line on the rising edge after
                -- its last mode bit, take it over and hold it low
                when STATE_TURNAROUND =>
                    if sck_rise then
                        dat <= '0';
                        dat_oe <= '1';
                        state <= STATE_TCAL;
                    end if;

                -- Calculation time, then the start bit
                when STATE_TCAL =>
                    if sck_rise then
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = TCAL_CLOCKS - 1 then
                            bit_cnt <= (others => '0');
                            dat <= '1';
                            state <= STATE_ERRBIT;
                        end if;
                    end if;

                -- Error bit F1
                when STATE_ERRBIT =>
                    if sck_rise then
                        dat <= f1;
                        crc_bit <= f1;
                        crc_strb <= '1';
                        state <= STATE_POSN;
                    end if;

                -- Position, LSB first, bits above 32 are sent as zero
                when STATE_POSN =>
                    if sck_rise then
                        if bit_cnt < 32 then
                            dat <= posn_lat(to_integer(bit_cnt(4 downto 0)));
                            crc_bit <= posn_lat(to_integer(bit_cnt(4 downto 0)));
                        else
                            dat <= '0';
                            crc_bit <= '0';
                        end if;
                        crc_strb <= '1';
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = bits_lat - 1 then
                            bit_cnt <= (others => '0');
                            state <= STATE_CRC;
                        end if;
                    end if;

                -- CRC, MSB first, then the line goes high on the rising edge
                -- after the last CRC bit
                when STATE_CRC =>
                    if sck_rise then
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = 5 then
                            dat <= '1';
                            recovery_cnt <= 0;
                            health_o <= HEALTH_OK;
                            state <= STATE_RECOVERY;
                        else
                            dat <= crc_calc(4 - to_integer(bit_cnt(2 downto 0)));
                        end if;
                    end if;

                -- Recovery time tm, then the line goes low until the next
                -- frame
                when STATE_RECOVERY =>
                    recovery_cnt <= recovery_cnt + 1;
                    if recovery_cnt = RECOVERY - 1 then
                        dat <= '0';
                        state <= STATE_IDLE;
                    end if;
            end case;

            -- The master stopped its clock before the end of the frame,
            -- back to holding the line low
            if clock_stopped = '1' and state /= STATE_IDLE
                    and state /= STATE_SKIP and state /= STATE_RECOVERY then
                dat <= '0';
                dat_oe <= '1';
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
