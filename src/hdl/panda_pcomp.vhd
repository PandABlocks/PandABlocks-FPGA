--------------------------------------------------------------------------------
--  File:       panda_pcomp.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_pcomp is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block inputs
    enable_i            : in  std_logic;
    posn_i              : in  std_logic_vector(31 downto 0);
    -- Block inputs
    START               : in  std_logic_vector(31 downto 0);
    STEP                : in  std_logic_vector(31 downto 0);
    WIDTH               : in  std_logic_vector(31 downto 0);
    NUM                 : in  std_logic_vector(31 downto 0);
    RELATIVE            : in  std_logic;
    DIR                 : in  std_logic;
    FLTR_DELTAT         : in  std_logic_vector(31 downto 0);
    FLTR_THOLD          : in  std_logic_vector(15 downto 0);
    -- Output pulse
    act_o               : out std_logic;
    err_o               : out std_logic_vector(31 downto 0);
    pulse_o             : out std_logic
);
end panda_pcomp;

architecture rtl of panda_pcomp is

type fsm_t is (WAIT_ENABLE, WAIT_START, WAIT_WIDTH, IS_FINISHED, ERR);
signal pcomp_fsm        : fsm_t;

signal enable_prev      : std_logic;
signal enable_rise      : std_logic;
signal enable_fall      : std_logic;

signal cur_start        : signed(31 downto 0);
signal cur_width        : signed(31 downto 0);

signal posn             : signed(31 downto 0);
signal posn_prev        : signed(31 downto 0);
signal last_posn        : signed(31 downto 0);
signal posn_latched     : signed(31 downto 0);

signal fltr_counter     : signed(15 downto 0);
signal posn_dir         : std_logic;
signal posn_trans       : std_logic;
signal puls_dir         : std_logic := '1';
signal dir_matched      : std_logic := '0';

signal puls_start       : signed(31 downto 0);
signal puls_width       : signed(31 downto 0);
signal puls_step        : signed(31 downto 0);
signal puls_counter     : unsigned(31 downto 0);

signal start_up         : std_logic;
signal start_down       : std_logic;
signal start_crossed    : std_logic;

signal width_up         : std_logic;
signal width_down       : std_logic;
signal width_crossed    : std_logic;

begin

--
-- Register inputs and detect rise/fall edges required
-- for the design.
process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_i;
    end if;
end process;

enable_rise <= enable_i and not enable_prev;
enable_fall <= not enable_i and enable_prev;

--
-- Direction flag detection
--
-- Accumulates direction ticks into an up/down counter for
-- user defined DeltaT, and compares against user defined
-- threshold value.
posn_trans <= '1' when (posn /= posn_prev) else '0';
posn_dir <= '0' when (posn >= posn_prev) else '1';

detect_dir : process(clk_i)
    variable t_counter  : unsigned(31 downto 0);
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            t_counter := (others => '0');
            fltr_counter <= (others => '0');
            puls_dir <= '0';
        else
            posn_prev <= posn;

            -- Reset counters on deltaT tick
            if (t_counter = unsigned(FLTR_DELTAT)) then
                t_counter := (others => '0');
                fltr_counter <= (others => '0');
                -- Detect direction
                -- '0' +
                -- '1' -
                if (abs(fltr_counter) > signed(FLTR_THOLD)) then
                    puls_dir <= fltr_counter(15);
                end if;
            -- Increment deltaT and keep track of direction ticks
            else
                t_counter := t_counter + 1;

                if (posn_trans = '1') then
                    if (posn_dir = '0') then
                        fltr_counter <= fltr_counter + 1;
                    else
                        fltr_counter <= fltr_counter - 1;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

--
-- Sign conversion for calculations based on encoder direction
--
puls_width <= signed('0'&WIDTH(30 downto 0)) when (DIR = '0') else
                signed(unsigned(not WIDTH) + 1);

puls_step <= signed('0'&STEP(30 downto 0)) when (DIR = '0') else
                signed(unsigned(not STEP) + 1);

puls_start <= signed(START);

--
-- Latch position on the rising edge of enable_i input, and calculate live
-- Pulse Start position based on RELATIVE flag and encoder direction signal.
--
detect_pos : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_latched <= (others => '0');
            posn <= (others => '0');
        else
            -- Keep latched value for RELATIVE mode
            if (enable_rise = '1') then
                posn_latched <= signed(posn_i);
            end if;

            -- RELATIVE mode runs relative to rising edge of enable_i input
            if (RELATIVE = '1') then
                posn <= signed(posn_i) - posn_latched;
            else
                posn <= signed(posn_i);
            end if;
        end if;
    end if;
end process;

--
-- Detects when START and WIDTH points are crossed over up or downwards.
--
-- This logic requires one encoder reading before and after the threshold.
-- Otherwise, it means that the encoder is moving slower than the motor, and
-- an error is flagged.
--
detect_crossing : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            start_up <= '0';
            start_down <= '0';
            width_up <= '0';
            width_down <= '0';
            last_posn <= (others => '0');
        else
            if (posn_trans = '1') then
                last_posn <= posn;
            end if;

            -- Detect that cur_start value is crossed up or down.
            if (last_posn < cur_start and cur_start <= posn) then
                start_up <= '1';
            elsif (last_posn > cur_start and cur_start >= posn) then
                start_down <= '1';
            else
                start_up <= '0';
                start_down <= '0';
            end if;

            -- Detect that cur_width value is crossed up or down.
            if (last_posn < cur_width and cur_width <= posn) then
                width_up <= '1';
            elsif (last_posn > cur_width and cur_width >= posn) then
                width_down <= '1';
            else
                width_up <= '0';
                width_down <= '0';
            end if;
         end if;
    end if;
end process;


-- Make sure that auto-detect Motor direction matches to desired
-- user selection.
dir_matched <= '1' when (DIR = puls_dir) else '0';

-- Generate crossing pulses only when moving in the right direction.
start_crossed <= (start_up or start_down) and dir_matched;
width_crossed <= (width_up or width_down) and dir_matched;

--
-- Pulse generator state machine
--
outp_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1' or enable_fall = '1') then
            pcomp_fsm <= WAIT_ENABLE;
            cur_start <= (others => '0');
            cur_width <= (others => '0');
            puls_counter <= (others => '0');
            act_o <= '0';
            err_o <= (others => '0');
        else
            case (pcomp_fsm) is
                -- Wait for enable rise to cur_start operation.
                when WAIT_ENABLE =>
                    cur_start <= (others => '0');
                    cur_width <= (others => '0');
                    puls_counter <= (others => '0');
                    cur_start <= puls_start;
                    cur_width <= puls_start + puls_width;

                    if (enable_rise = '1') then
                        pcomp_fsm <= WAIT_START;
                        act_o <= '1';
                    end if;

                -- Wait for cur_start crossing to assert the output pulse.
                when WAIT_START =>
                    if (width_crossed = '1') then
                        pcomp_fsm <= ERR;
                        err_o(0) <= '1';
                    elsif (start_crossed = '1') then
                        cur_start <= cur_start + puls_step;
                        pcomp_fsm <= WAIT_WIDTH;
                    end if;

                -- Wait for cur_width crossing to de-assert the output pulse.
                when WAIT_WIDTH =>
                    if (start_crossed = '1') then
                        pcomp_fsm <= ERR;
                        err_o(1) <= '1';
                    elsif (width_crossed = '1') then
                        cur_width <= cur_width + puls_step;
                        puls_counter <= puls_counter + 1;
                        pcomp_fsm <= IS_FINISHED;
                    end if;

                -- Check for finishing conditions.
                when IS_FINISHED =>
                    -- Run forever until disabled.
                    if (unsigned(NUM) = 0) then
                        pcomp_fsm <= WAIT_START;
                    -- Run for NPulses and stop.
                    elsif (puls_counter = unsigned(NUM)) then
                        pcomp_fsm <= WAIT_ENABLE;
                        act_o <= '0';
                    else
                        pcomp_fsm <= WAIT_START;
                    end if;

                when ERR =>
                    act_o <= '0';

                when others =>
            end case;
        end if;
    end if;
end process;

-- Assign output pulse when module is enabled.
pulse_o <=  '1' when (pcomp_fsm = WAIT_START and start_crossed = '1') else
            '1' when (pcomp_fsm = WAIT_WIDTH) else
            '0' when (pcomp_fsm = IS_FINISHED) else '0';

end rtl;

