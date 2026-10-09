--------------------------------------------------------------------------------
--  PandA Motion Project
--      Diamond Light Source, Oxford, UK
--------------------------------------------------------------------------------
--
--  Description : EnDat master, position read only.
--                Each frame sends the EnDat 2.1 mode command "encoder send
--                position value" (000111), which EnDat 2.2 encoders also
--                support, and receives the start bit, the error bit F1, the
--                position (LSB first) and the CRC-5 (MSB first). After the
--                mode command the master waits for the encoder to pull the
--                data line low before looking for the start bit, as its own
--                last mode bit may still be on the line.
--                The encoder changes its data after the rising edge of the
--                clock. The master samples the data DELAY_COMP+3 clk_i cycles
--                after the falling edge of the clock to allow for the cable
--                delay, so DELAY_COMP+3 cycles must be shorter than half
--                CLK_PERIOD.
--                The clock stays low for START_DELAY clk_i cycles after the
--                first falling edge of a frame (t_ST in the EnDat
--                documentation), only the first rising edge is delayed and
--                the clock then runs with half CLK_PERIOD periods.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity endat_master is
generic (
    -- Maximum calculation time (tcal) before the start bit, in clk_i cycles
    TCAL_TIMEOUT    : natural := 125000;    -- 1ms
    -- Low time of the clock after the first falling edge of a frame (t_ST),
    -- in clk_i cycles, must be at least 1
    START_DELAY     : natural := 250        -- 2us
);
port (
    clk_i : in  std_logic;
    reset_i : in  std_logic;
    -- Block Parameters
    BITS : in  std_logic_vector(5 downto 0);
    CLK_PERIOD : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD : in  std_logic_vector(31 downto 0);
    DELAY_COMP : in  std_logic_vector(15 downto 0);
    link_up_o : out std_logic;
    health_o : out std_logic_vector(31 downto 0);
    -- Encoder lines
    endat_sck_o : out std_logic;
    endat_dat_i : in  std_logic;
    endat_dat_o : out std_logic;
    endat_dat_oe_o : out std_logic;
    -- Block Outputs
    posn_o : out std_logic_vector(31 downto 0);
    posn_valid_o : out std_logic
);
end;

architecture rtl of endat_master is

-- Encoder send position value
constant MODE_COMMAND : std_logic_vector(5 downto 0) := "000111";

-- Health codes, matching the INENC HEALTH enum
constant HEALTH_OK : std_logic_vector(31 downto 0) := to_svector(0, 32);
-- No start bit within TCAL_TIMEOUT, or data line still high from the
-- previous frame when the next frame is due
constant HEALTH_TIMEOUT : std_logic_vector(31 downto 0) := to_svector(2, 32);
-- Received CRC does not match the calculated one
constant HEALTH_CRC : std_logic_vector(31 downto 0) := to_svector(3, 32);
-- Encoder reported an error in F1
constant HEALTH_ERROR_BIT : std_logic_vector(31 downto 0) := to_svector(4, 32);

--MA ````\____/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/```````
--DA ___________| M2  M1  M0 !M2 !M1 !M0 |              | S | F1 | POS 0..N |  CRC  |```tm```\__
--     <-t_ST->  <- master drives data -> <-  tcal   ->  <---- encoder drives data ---->

type state_t is (STATE_IDLE, STATE_LATCH, STATE_MODE, STATE_TURNAROUND1,
                 STATE_TURNAROUND2, STATE_TCAL, STATE_ERRBIT, STATE_POSN,
                 STATE_CRC, STATE_RESULT);

signal state : state_t;

signal frame_pulse : std_logic;
signal frame_pending : std_logic;

-- Serial clock generation
signal run : std_logic;
signal sck : std_logic;
signal sck_rise : std_logic;
signal sck_fall : std_logic;
signal half_period : unsigned(30 downto 0);
signal configured : std_logic := '0';
signal half_cnt : unsigned(30 downto 0);
-- Set until the first rising edge of the frame, the first low period of the
-- clock lasts START_DELAY cycles instead of half CLK_PERIOD
signal start_gap : std_logic;

-- Data sampling after the falling edge
signal sample_pend : std_logic;
signal sample_cnt : unsigned(15 downto 0);
signal sample : std_logic;

-- BITS latched at the start of each frame
signal bits_lat : unsigned(5 downto 0);

signal bit_cnt : unsigned(7 downto 0);
signal mode_sr : std_logic_vector(5 downto 0);
signal dat_oe : std_logic;
signal tcal_cnt : natural range 0 to TCAL_TIMEOUT;
signal err_bit : std_logic;
signal posn_sr : std_logic_vector(31 downto 0);
signal crc_rx : std_logic_vector(4 downto 0);

signal crc_reset : std_logic;
signal crc_bit : std_logic;
signal crc_strb : std_logic;
signal crc_calc : std_logic_vector(4 downto 0);

begin

endat_sck_o <= sck;
endat_dat_o <= mode_sr(5);
endat_dat_oe_o <= dat_oe;

-- Generate Internal EnDat Frame from system clock
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => FRAME_PERIOD,
    pulse_o     => frame_pulse
);

--------------------------------------------------------------------------
-- Serial clock, idles high and toggles every half CLK_PERIOD while running,
-- except for the first low period of a frame which lasts START_DELAY (t_ST)
--------------------------------------------------------------------------
half_period <= unsigned(CLK_PERIOD(31 downto 1));

ps_clk: process(clk_i)
begin
    if rising_edge(clk_i) then
        sck_rise <= '0';
        sck_fall <= '0';
        configured <= (or half_period) and (or BITS);
        if reset_i or not run or not configured then
            sck <= '1';
            half_cnt <= (others => '0');
            start_gap <= '1';
        elsif start_gap and not sck then
            if half_cnt = START_DELAY - 1 then
                half_cnt <= (others => '0');
                sck <= '1';
                sck_rise <= '1';
                start_gap <= '0';
            else
                half_cnt <= half_cnt + 1;
            end if;
        elsif half_cnt = half_period - 1 then
            half_cnt <= (others => '0');
            sck <= not sck;
            sck_fall <= sck;
            sck_rise <= not sck;
        else
            half_cnt <= half_cnt + 1;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Data sampling, DELAY_COMP+3 cycles after the falling edge of the clock
--------------------------------------------------------------------------
ps_sample: process(clk_i)
begin
    if rising_edge(clk_i) then
        sample <= '0';
        if reset_i or not run then
            sample_pend <= '0';
            sample_cnt <= (others => '0');
        elsif sck_fall then
            sample_pend <= '1';
            sample_cnt <= unsigned(DELAY_COMP);
        elsif sample_pend then
            if sample_cnt = 0 then
                sample <= '1';
                sample_pend <= '0';
            else
                sample_cnt <= sample_cnt - 1;
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Frame state machine
--------------------------------------------------------------------------
ps_stat: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i then
            state <= STATE_IDLE;
            frame_pending <= '0';
            run <= '0';
            dat_oe <= '0';
            crc_reset <= '0';
            crc_strb <= '0';
            posn_valid_o <= '0';
            posn_o <= (others => '0');
            link_up_o <= '0';
            health_o <= HEALTH_TIMEOUT;
        else
            crc_reset <= '0';
            crc_strb <= '0';
            crc_bit <= endat_dat_i;
            posn_valid_o <= '0';

            -- A frame waits for the data line to go low at the end of the
            -- recovery time, if it is still waiting at the next frame pulse
            -- the encoder is not responding
            if frame_pulse then
                if frame_pending then
                    link_up_o <= '0';
                    health_o <= HEALTH_TIMEOUT;
                end if;
                frame_pending <= '1';
            end if;

            case state is
                when STATE_IDLE =>
                    run <= '0';
                    dat_oe <= '0';
                    if frame_pending and not endat_dat_i and configured then
                        frame_pending <= '0';
                        run <= '1';
                        crc_reset <= '1';
                        bit_cnt <= (others => '0');
                        posn_sr <= (others => '0');
                        bits_lat <= unsigned(BITS);
                        mode_sr <= MODE_COMMAND;
                        state <= STATE_LATCH;
                    end if;

                -- Two clock periods for the encoder to latch the position
                when STATE_LATCH =>
                    if sck_rise then
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = 1 then
                            bit_cnt <= (others => '0');
                            dat_oe <= '1';
                            state <= STATE_MODE;
                        end if;
                    end if;

                -- Mode command, MSB first, changed on each rising edge
                when STATE_MODE =>
                    if sck_rise then
                        bit_cnt <= bit_cnt + 1;
                        mode_sr <= mode_sr(4 downto 0) & '0';
                        if bit_cnt = 5 then
                            bit_cnt <= (others => '0');
                            dat_oe <= '0';
                            tcal_cnt <= 0;
                            state <= STATE_TURNAROUND1;
                        end if;
                    end if;

                when STATE_TURNAROUND1 =>
                    if sample then
                        state <= STATE_TURNAROUND2;
                    end if;

                -- The master has released the data line, wait until the
                -- encoder holds it low. The last mode bit may still be on
                -- the line and must not be taken for the start bit.
                when STATE_TURNAROUND2 =>
                    tcal_cnt <= tcal_cnt + 1;
                    if sample and not endat_dat_i then
                        state <= STATE_TCAL;
                    elsif tcal_cnt = TCAL_TIMEOUT - 1 then
                        run <= '0';
                        link_up_o <= '0';
                        health_o <= HEALTH_TIMEOUT;
                        state <= STATE_IDLE;
                    end if;

                -- Encoder holds the data line low until the start bit
                when STATE_TCAL =>
                    tcal_cnt <= tcal_cnt + 1;
                    if sample and endat_dat_i then
                        state <= STATE_ERRBIT;
                    elsif tcal_cnt = TCAL_TIMEOUT - 1 then
                        run <= '0';
                        link_up_o <= '0';
                        health_o <= HEALTH_TIMEOUT;
                        state <= STATE_IDLE;
                    end if;

                -- Error bit F1
                when STATE_ERRBIT =>
                    if sample then
                        crc_strb <= '1';
                        err_bit <= endat_dat_i;
                        state <= STATE_POSN;
                    end if;

                -- Position, LSB first, only the 32 LSBs are kept
                when STATE_POSN =>
                    if sample then
                        crc_strb <= '1';
                        if bit_cnt < 32 then
                            posn_sr(to_integer(bit_cnt(4 downto 0))) <= endat_dat_i;
                        end if;
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = bits_lat - 1 then
                            bit_cnt <= (others => '0');
                            state <= STATE_CRC;
                        end if;
                    end if;

                -- CRC, MSB first
                when STATE_CRC =>
                    if sample then
                        crc_rx <= crc_rx(3 downto 0) & endat_dat_i;
                        bit_cnt <= bit_cnt + 1;
                        if bit_cnt = 4 then
                            run <= '0';
                            state <= STATE_RESULT;
                        end if;
                    end if;

                when STATE_RESULT =>
                    if crc_rx /= crc_calc then
                        link_up_o <= '0';
                        health_o <= HEALTH_CRC;
                    elsif err_bit then
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
