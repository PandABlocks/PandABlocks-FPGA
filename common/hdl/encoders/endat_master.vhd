--------------------------------------------------------------------------------
--  PandA Motion Project
--      Diamond Light Source, Oxford, UK
--------------------------------------------------------------------------------
--
--  Description : EnDat master, position read only.
--                Each frame sends the EnDat 2.1 mode command "encoder send
--                position value" (000111), which EnDat 2.2 encoders also
--                support, and receives the start bit, the error bit F1, the
--                position (LSB first) and the CRC-5 (MSB first).
--                Data changes after the rising edge of the clock.
--                With DELAY_COMP = 0 the cable delay is compensated
--                automatically: the bit timing is locked to the rising edge
--                of the start bit as seen by the master, and each bit is
--                sampled in its middle. This works for delays of any number
--                of clock periods.
--                A non zero DELAY_COMP overrides it, data is then sampled
--                DELAY_COMP+3 clk_i cycles after the falling edge of the
--                clock, so DELAY_COMP must be shorter than half CLK_PERIOD.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity endat_master is
generic (
    -- Maximum calculation time (tcal) before the start bit, in clk_i cycles
    TCAL_TIMEOUT    : natural := 125000     -- 1ms
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
    posn_valid_o : out std_logic;
    -- Whole clk_i cycles from the last rising edge of the clock to the start
    -- bit, modulo the clock period
    delay_o : out std_logic_vector(31 downto 0)
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

--MA ````\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/``\__/```````
--DA _________| M2  M1  M0 !M2 !M1 !M0 |              | S | F1 | POS 0..N |  CRC  |```tm```\__
--             <- master drives data -> <-  tcal   ->  <---- encoder drives data ---->

type state_t is (STATE_IDLE, STATE_LATCH, STATE_MODE, STATE_TCAL,
                 STATE_ERR, STATE_POSN, STATE_CRC, STATE_RESULT);

signal state : state_t;

signal frame_pulse : std_logic;
signal frame_pending : std_logic;

-- Serial clock generation
signal run : std_logic;
signal sck : std_logic;
signal sck_rise : std_logic;
signal sck_fall : std_logic;
signal half_period : unsigned(30 downto 0);
signal half_cnt : unsigned(30 downto 0);

-- Data sampling after the falling edge
signal sample_pend : std_logic;
signal sample_cnt : unsigned(15 downto 0);
signal sample_man : std_logic;

-- Data sampling locked to the start bit
signal dat_prev : std_logic;
signal armed : std_logic;
signal locked : std_logic;
signal first_bit : std_logic;
signal rise_tmr : unsigned(31 downto 0);
signal bit_tmr : unsigned(31 downto 0);
signal sample_auto : std_logic;

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
endat_dat_o <= mode_sr(5) and dat_oe;
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
-- Serial clock, idles high and toggles every half CLK_PERIOD while running
--------------------------------------------------------------------------
half_period <= unsigned(CLK_PERIOD(31 downto 1));

ps_clk: process(clk_i)
begin
    if rising_edge(clk_i) then
        sck_rise <= '0';
        sck_fall <= '0';
        if reset_i or not run then
            sck <= '1';
            half_cnt <= (others => '0');
        elsif half_cnt + 1 >= half_period then
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
-- Manual delay compensation, sample DELAY_COMP+3 cycles after falling edge
--------------------------------------------------------------------------
ps_sample: process(clk_i)
begin
    if rising_edge(clk_i) then
        sample_man <= '0';
        if reset_i or not run then
            sample_pend <= '0';
            sample_cnt <= (others => '0');
        elsif sck_fall then
            sample_pend <= '1';
            sample_cnt <= unsigned(DELAY_COMP);
        elsif sample_pend then
            if sample_cnt = 0 then
                sample_man <= '1';
                sample_pend <= '0';
            else
                sample_cnt <= sample_cnt - 1;
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Automatic delay compensation, the bit timer restarts on the rising edge of
-- the start bit and samples in the middle of each bit. It counts a whole
-- clock period (2*half_period) so it stays in step with the clock.
--------------------------------------------------------------------------
ps_auto: process(clk_i)
begin
    if rising_edge(clk_i) then
        sample_auto <= '0';
        dat_prev <= endat_dat_i;
        -- sck_rise lags the clock edge by one cycle
        rise_tmr <= to_unsigned(1, rise_tmr'length) when sck_rise
                    else rise_tmr + 1;
        if reset_i then
            delay_o <= (others => '0');
        end if;
        if reset_i or not run then
            armed <= '0';
            locked <= '0';
            first_bit <= '0';
            bit_tmr <= (others => '0');
        elsif locked then
            bit_tmr <= (others => '0') when bit_tmr + 1 >= (half_period & '0')
                       else bit_tmr + 1;
            if bit_tmr = half_period then
                sample_auto <= '1';
                first_bit <= '0';
                -- A glitch rather than the start bit, wait for another edge
                if first_bit and not endat_dat_i then
                    armed <= '0';
                    locked <= '0';
                end if;
            end if;
        elsif state = STATE_TCAL then
            -- Only arm once the encoder holds the line low, the last mode
            -- bit may still be on the line after the master releases it
            if not endat_dat_i then
                armed <= '1';
            elsif armed and not dat_prev then
                locked <= '1';
                first_bit <= '1';
                bit_tmr <= to_unsigned(1, bit_tmr'length);
                delay_o <= std_logic_vector(rise_tmr);
            end if;
        end if;
    end if;
end process;

sample <= sample_auto when unsigned(DELAY_COMP) = 0 else sample_man;

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
                -- BITS = 0 means not configured, no frames are sent
                when STATE_IDLE =>
                    run <= '0';
                    dat_oe <= '0';
                    if frame_pending and not endat_dat_i and (or BITS) then
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
                            state <= STATE_TCAL;
                        end if;
                    end if;

                -- Encoder holds the data line low until the start bit
                when STATE_TCAL =>
                    tcal_cnt <= tcal_cnt + 1;
                    if sample and endat_dat_i then
                        state <= STATE_ERR;
                    elsif tcal_cnt = TCAL_TIMEOUT - 1 then
                        run <= '0';
                        link_up_o <= '0';
                        health_o <= HEALTH_TIMEOUT;
                        state <= STATE_IDLE;
                    end if;

                -- Error bit F1
                when STATE_ERR =>
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
