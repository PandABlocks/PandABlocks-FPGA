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
    PCOMP_START         : in  std_logic_vector(31 downto 0);
    PCOMP_STEP          : in  std_logic_vector(31 downto 0);
    PCOMP_WIDTH         : in  std_logic_vector(31 downto 0);
    PCOMP_NUM           : in  std_logic_vector(31 downto 0);
    PCOMP_RELATIVE      : in  std_logic;
    PCOMP_DIR           : in  std_logic;
    PCOMP_FLTR_DELTAT   : in  std_logic_vector(31 downto 0);
    PCOMP_FLTR_THOLD    : in  std_logic_vector(15 downto 0);
    -- Output pulse
    act_o               : out std_logic;
    pulse_o             : out std_logic
);
end panda_pcomp;

architecture rtl of panda_pcomp is

type state_t is (IDLE, POS, NEG);

signal enabled          : std_logic;
signal enable_prev      : std_logic;
signal enable_rise      : std_logic;

signal state            : state_t;
signal start            : signed(31 downto 0);
signal width            : signed(31 downto 0);

signal posn             : signed(31 downto 0);
signal posn_prev        : signed(31 downto 0);
signal posn_latched     : signed(31 downto 0);

signal puls_start       : signed(31 downto 0);
signal puls_width       : signed(31 downto 0);
signal puls_step        : signed(31 downto 0);

signal puls_dir         : std_logic := '1';

signal puls_counter     : unsigned(31 downto 0);
signal posn_dir         : std_logic;
signal posn_trans       : std_logic;
signal fltr_counter     : signed(15 downto 0);

begin

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
            if (t_counter = unsigned(PCOMP_FLTR_DELTAT)) then
                t_counter := (others => '0');
                fltr_counter <= (others => '0');
                -- Detect direction
                -- '0' +
                -- '1' -
                if (abs(fltr_counter) > signed(PCOMP_FLTR_THOLD)) then
                    puls_dir <= fltr_counter(15);
                end if;
            -- Increment deltaT and keep track of direction ticks
            else
                t_counter := t_counter + 1;

                if (posn_trans = '1') then
                    if (posn_dir = '0') then
                        fltr_counter <= fltr_counter + 1;
                    else
                        fltr_counter <= fltr_counter -1;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

--
-- Sign conversion for calculations based on encoder direction
--
puls_width <= signed('0'&PCOMP_WIDTH(30 downto 0)) when (puls_dir = '0') else
                signed(unsigned(not PCOMP_WIDTH) + 1);

puls_step <= signed('0'&PCOMP_STEP(30 downto 0)) when (puls_dir = '0') else
                signed(unsigned(not PCOMP_STEP) + 1);

puls_start <= signed(PCOMP_START);

--
-- Enable input Start/Stop module's operation
--
enable_rise <= enable_i and not enable_prev;

process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_i;
    end if;
end process;

-- Module is enabled when user enables and encoder auto-direction matches.
enabled <= '1' when (enable_i = '1' and PCOMP_DIR = puls_dir) else '0';

--
-- Latch position on the rising edge of enable_i input, and calculate live
-- Pulse Start position based on RELATIVE flag and encoder direction signal.
--
detect_pos : process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Keep latched value for RELATIVE mode
        if (enable_rise = '1') then
            posn_latched <= signed(posn_i);
        end if;

        -- RELATIVE mode runs relative to rising edge of enable_i input
        if (PCOMP_RELATIVE = '1') then
            posn <= signed(posn_i) - posn_latched;
        else
            posn <= signed(posn_i);
        end if;
    end if;
end process;

outp_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Reset state machine on Enable
        if (enabled = '0') then
            state <= IDLE;
            start <= (others => '0');
            width <= (others => '0');
            puls_counter <= (others => '0');
        else
            case (state) is
                -- Wait for START at the gate beginning
                when IDLE =>
                    start <= (others => '0');
                    width <= (others => '0');
                    puls_counter <= (others => '0');

                    if (posn = puls_start) then
                        start <= puls_start;
                        width <= puls_start + puls_width;
                        state <= POS;
                    end if;

                -- Assert output pulse for WIDTH
                when POS =>
                    if (posn = width) then
                        state <= NEG;
                        start <= start + puls_step;
                        width <= width + puls_step;
                        puls_counter <= puls_counter + 1;
                    end if;

                -- De-assert output pulse and wait until next start
                when NEG =>
                    if (puls_counter = unsigned(PCOMP_NUM)) then
                        state <= IDLE;
                    elsif (posn = start) then
                        state <= POS;
                    end if;

                when others =>
            end case;
        end if;

        -- Block becomes active with enable_rise until either disabled
        -- or all pulses are generated.
        if (enable_i = '0') then
            act_o <= '0';
        else
            if (enable_rise = '1') then
                act_o <= '1';
            elsif (state = NEG and puls_counter = unsigned(PCOMP_NUM)) then
                act_o <= '0';
            end if;
        end if;

    end if;
end process;

-- Assign output pulse when module is enabled.
pulse_o <= '1' when (state = IDLE and posn = puls_start and enabled = '1') else
        '1' when (state = POS and enabled = '1') else
        '0' when (state = NEG and enabled = '1') else '0';

end rtl;

