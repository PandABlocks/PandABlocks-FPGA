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
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    -- Output pulse
    act_o               : out std_logic;
    pulse_o             : out std_logic
);
end panda_pcomp;

architecture rtl of panda_pcomp is

type state_t is (IDLE, POS, NEG);

signal enable_val       : std_logic;
signal enabled          : std_logic;
signal enable_prev      : std_logic;
signal enable_rise      : std_logic;

signal state            : state_t;
signal start            : signed(31 downto 0);
signal width            : signed(31 downto 0);

signal posn_val         : std_logic_vector(31 downto 0);
signal posn             : signed(31 downto 0);
signal posn_prev        : signed(31 downto 0);
signal posn_latched     : signed(31 downto 0);

signal puls_start       : signed(31 downto 0);
signal puls_width       : signed(31 downto 0);
signal puls_step        : signed(31 downto 0);

signal puls_dir         : std_logic := '1';

signal PCOMP_ENABLE_VAL : std_logic_vector(SBUSBW-1 downto 0);
signal PCOMP_POSN_VAL   : std_logic_vector(PBUSBW-1 downto 0);
signal PCOMP_START      : std_logic_vector(31 downto 0);
signal PCOMP_STEP       : std_logic_vector(31 downto 0);
signal PCOMP_WIDTH      : std_logic_vector(31 downto 0);
signal PCOMP_COUNT      : std_logic_vector(31 downto 0);
signal PCOMP_RELATIVE   : std_logic;
signal PCOMP_DIR        : std_logic;
signal PCOMP_FLTR_DELTAT: std_logic_vector(31 downto 0);
signal PCOMP_FLTR_THOLD : std_logic_vector(15 downto 0);

signal puls_counter     : unsigned(31 downto 0);
signal posn_dir         : std_logic;
signal posn_trans       : std_logic;
signal fltr_counter     : signed(15 downto 0);

begin

mem_dat_o <= (others => '0');

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            PCOMP_START <= (others => '0');
            PCOMP_STEP <= (others => '0');
            PCOMP_WIDTH <= (others => '0');
            PCOMP_COUNT <= (others => '0');
            PCOMP_RELATIVE <= '0';
            PCOMP_FLTR_DELTAT <= (others => '0');
            PCOMP_FLTR_THOLD <= (others => '0');
            PCOMP_ENABLE_VAL <= TO_STD_VECTOR(127, SBUSBW);
            PCOMP_POSN_VAL <= (others => '0');
        else
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Pulse start position
                if (mem_addr_i = PCOMP_ENABLE_VAL_ADDR) then
                    PCOMP_ENABLE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Pulse start position
                if (mem_addr_i = PCOMP_POSN_VAL_ADDR) then
                    PCOMP_POSN_VAL <= mem_dat_i(PBUSBW-1 downto 0);
                end if;

                -- Pulse start position
                if (mem_addr_i = PCOMP_START_ADDR) then
                    PCOMP_START <= mem_dat_i;
                end if;

                -- Pulse step value
                if (mem_addr_i = PCOMP_STEP_ADDR) then
                    PCOMP_STEP <= mem_dat_i;
                end if;

                -- Pulse width value
                if (mem_addr_i = PCOMP_WIDTH_ADDR) then
                    PCOMP_WIDTH <= mem_dat_i;
                end if;

                -- Pulse width value
                if (mem_addr_i = PCOMP_COUNT_ADDR) then
                    PCOMP_COUNT <= mem_dat_i;
                end if;

                -- PComp relative flag
                if (mem_addr_i = PCOMP_RELATIVE_ADDR) then
                    PCOMP_RELATIVE <= mem_dat_i(0);
                end if;

                -- PComp direction flag
                if (mem_addr_i = PCOMP_DIR_ADDR) then
                    PCOMP_DIR <= mem_dat_i(0);
                end if;

                -- PComp direction filter DeltaT flag
                if (mem_addr_i = PCOMP_FLTR_DELTAT_ADDR) then
                    PCOMP_FLTR_DELTAT <= mem_dat_i;
                end if;

                -- PComp direction filter threshold flag
                if (mem_addr_i = PCOMP_FLTR_THOLD_ADDR) then
                    PCOMP_FLTR_THOLD <= mem_dat_i(15 downto 0);
                end if;

            end if;
        end if;
    end if;
end process;

--
-- Design Bus Assignments
--
process(clk_i)
    variable t_counter  : unsigned(31 downto 0);
begin
    if rising_edge(clk_i) then
        enable_val <= SBIT(sysbus_i, PCOMP_ENABLE_VAL);
        posn_val <= PFIELD(posbus_i, PCOMP_POSN_VAL);
    end if;
end process;

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
process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_val;
        enable_rise <= enable_val and not enable_prev;
    end if;
end process;

-- Module is enabled when user enables and encoder auto-direction matches.
enabled <= '1' when (enable_val = '1' and PCOMP_DIR = puls_dir) else '0';

--
-- Latch position on the rising edge of enable_val input, and calculate live
-- Pulse Start position based on RELATIVE flag and encoder direction signal.
--
detect_pos : process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Keep latched value for RELATIVE mode
        if (enable_rise = '1') then
            posn_latched <= signed(posn_val);
        end if;

        -- RELATIVE mode runs relative to rising edge of enable_val input
        if (PCOMP_RELATIVE = '1') then
            posn <= signed(posn_val) - posn_latched;
        else
            posn <= signed(posn_val);
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
            act_o <= '0';
        else
            case (state) is
                -- Wait for START at the gate beginning
                when IDLE =>
                    start <= (others => '0');
                    width <= (others => '0');
                    puls_counter <= (others => '0');
                    act_o <= '0';

                    if (posn = puls_start) then
                        start <= puls_start;
                        width <= puls_start + puls_width;
                        state <= POS;
                        act_o <= '1';
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
                    if (puls_counter = unsigned(PCOMP_COUNT)) then
                        state <= IDLE;
                        act_o <= '0';
                    elsif (posn = start) then
                        state <= POS;
                    end if;

                when others =>
            end case;
        end if;
    end if;
end process;

-- Assign output pulse when module is enabled.
pulse_o <= '1' when (state = IDLE and posn = puls_start and enabled = '1') else
        '1' when (state = POS and enabled = '1') else
        '0' when (state = NEG and enabled = '1') else '0';

end rtl;

