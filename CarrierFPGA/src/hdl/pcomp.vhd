--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Position compare output pulse generator.
--                Supports regular and table-based comparison.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity pcomp is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block inputs
    enable_i            : in  std_logic;
    posn_i              : in  std_logic_vector(31 downto 0);
    table_posn_i        : in  std_logic_vector(63 downto 0);
    table_read_o        : out std_logic;
    table_end_i         : in  std_logic;
    -- Block inputs
    START               : in  std_logic_vector(31 downto 0);
    STEP                : in  std_logic_vector(31 downto 0);
    WIDTH               : in  std_logic_vector(31 downto 0);
    NUM                 : in  std_logic_vector(31 downto 0);
    RELATIVE            : in  std_logic;
    DIR                 : in  std_logic;
    DELTAP              : in  std_logic_vector(31 downto 0);
    USE_TABLE           : in  std_logic;
    -- Output pulse
    act_o               : out std_logic;
    out_o               : out std_logic;
    err_o               : out std_logic_vector(31 downto 0)
);
end pcomp;

architecture rtl of pcomp is

type fsm_t is (WAIT_ENABLE, WAIT_INIT, WAIT_DELTAP, WAIT_START, WAIT_WIDTH, WAIT_IN_ERROR);
signal pcomp_fsm            : fsm_t;

signal enable_prev          : std_logic;
signal enable_rise          : std_logic;
signal enable_fall          : std_logic;
signal posn_latched         : signed(31 downto 0);
signal posn_relative        : signed(31 downto 0);
signal posn                 : signed(31 downto 0);
signal puls_start           : signed(31 downto 0);
signal puls_width           : signed(31 downto 0);
signal puls_step            : signed(31 downto 0);
signal puls_deltap          : signed(31 downto 0);
signal puls_counter         : unsigned(31 downto 0);
signal current_crossing     : signed(31 downto 0);
signal next_crossing        : signed(31 downto 0);
signal pulse                : std_logic;

signal table_start          : signed(31 downto 0);
signal table_width          : signed(31 downto 0);
signal table_dir            : std_logic;
signal table_read           : std_logic;

signal puls_dir             : std_logic;
signal dp_pos_cross         : std_logic;
signal dp_neg_cross         : std_logic;
signal deltap_cross         : std_logic;

signal pos_cross            : std_logic;
signal neg_cross            : std_logic;
signal posn_cross           : std_logic;

signal pos_error            : std_logic;
signal neg_error            : std_logic;
signal posn_error           : std_logic;

begin

-- Assign outputs.
out_o <= pulse and enable_i;

---------------------------------------------------------------------------
-- Register inputs and detect rising/falling edges
---------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        enable_prev <= enable_i;
    end if;
end process;

enable_rise <= enable_i and not enable_prev;
enable_fall <= not enable_i and enable_prev;

---------------------------------------------------------------------------
-- Invert parameters' sign based on encoder direction
---------------------------------------------------------------------------
puls_start <= signed(START) when (RELATIVE = '0') else
                     signed(START) when (DIR = '0') else
                        signed(not unsigned(START) + 1);

puls_width <= signed(WIDTH) when (DIR = '0') else
                    signed(not unsigned(WIDTH) + 1);
puls_step <= signed(STEP) when (DIR = '0') else
                    signed(not unsigned(STEP) + 1);
puls_deltap <= signed(DELTAP) when (DIR = '0') else
                    signed(not unsigned(DELTAP) + 1);

puls_dir <= DIR when (USE_TABLE = '0') else table_dir;

---------------------------------------------------------------------------
-- Latch position on the rising edge of enable_i input, and calculate
-- relative position
---------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
        if (enable_rise = '1') then
            posn_latched <= signed(posn_i);
        end if;
    end if;
end process;

posn_relative <= signed(posn_i) - posn_latched;
posn <= signed(posn_i) when (RELATIVE = '0') else posn_relative;

---------------------------------------------------------------------------
-- Generate deltaP and position compare crossing pulses to be used in FSM
---------------------------------------------------------------------------
dp_pos_cross <= '1' when (puls_dir = '0' and posn <= current_crossing)
                        else '0';

dp_neg_cross <= '1' when (puls_dir = '1' and posn >= current_crossing)
                            else '0';

deltap_cross <= dp_pos_cross or dp_neg_cross;

pos_cross <= '1' when (puls_dir = '0' and posn >= current_crossing) else '0';
neg_cross <= '1' when (puls_dir = '1' and posn <= current_crossing) else '0';
posn_cross <= pos_cross or neg_cross;

---------------------------------------------------------------------------
-- Table management
---------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1' or enable_fall = '1') then
            table_dir <= '0';
        else
            -- Extract direction from the first entry in the table
            if (pcomp_fsm = WAIT_ENABLE and enable_rise = '1') then
                if (table_start < table_width) then
                    table_dir <= '0';   -- positive
                else
                    table_dir <= '1';   -- negative
                end if;
            end if;
        end if;
    end if;
end process;

table_start <= signed(table_posn_i(63 downto 32));
table_width <= signed(table_posn_i(31 downto 0));

-- Table read (ack) strobe to table FIFO
table_read_o <= USE_TABLE when (pcomp_fsm = WAIT_ENABLE and enable_rise = '1') or
                         (pcomp_fsm = WAIT_DELTAP and deltap_cross = '1') or
                         (pcomp_fsm = WAIT_WIDTH  and posn_cross = '1')
                else '0';

---------------------------------------------------------------------------
-- Detect when position input jumps two comparison points in one step
---------------------------------------------------------------------------
pos_error <= '1' when (puls_dir = '0' and posn >= next_crossing) else '0';
neg_error <= '1' when (puls_dir = '1' and posn <= next_crossing) else '0';
posn_error <= pos_error or neg_error;

---------------------------------------------------------------------------
-- Pulse generator state machine
-- A window by DELTAP parameter is defined around the start position. The
-- encoder first needs to pass through START-DELTAP before START point.
---------------------------------------------------------------------------
outp_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Reset state machine on falling edge of enable signal.
        if (reset_i = '1' or enable_fall = '1') then
            pulse <= '0';
            puls_counter <= (others => '0');
            act_o <= '0';
            err_o <= (others => '0');
            pcomp_fsm <= WAIT_ENABLE;
            current_crossing <= (others => '0');
            next_crossing <= (others => '0');
        else
            case pcomp_fsm is
                -- Wait for enable (rising edge) to start operation
                when WAIT_ENABLE =>
                    if (enable_rise = '1') then
                        -- First sample is already available on FWFT FIFO, so
                        -- we can assign it immediately
                        if (USE_TABLE = '1') then
                            current_crossing <= table_start;
                        else
                        -- Absolute deltaP crossing point
                            current_crossing <= puls_start - puls_deltap;
                            next_crossing <= puls_start;
                        end if;
                        act_o <= '1';
                        pcomp_fsm <= WAIT_INIT;
                    end if;

                -- Wait one clock cycle for table read latency
                when WAIT_INIT =>
                    pcomp_fsm <= WAIT_DELTAP;

                -- Wait for DeltaP point crossing
                when WAIT_DELTAP =>
                    if (deltap_cross = '1') then
                        pcomp_fsm <= WAIT_START;
                        if (USE_TABLE = '1') then
                            current_crossing <= table_start;
                            next_crossing <= table_width;
                        else
                            current_crossing <= puls_start;
                            next_crossing <= puls_start + puls_width;
                        end if;
                    end if;

                -- Wait for pulse start position, and assert pulse output.
                when WAIT_START =>
                    if (posn_error = '1') then
                        pcomp_fsm <= WAIT_IN_ERROR;
                    elsif (posn_cross = '1') then
                        pulse <= not pulse;
                        puls_counter <= puls_counter + 1;
                        pcomp_fsm <= WAIT_WIDTH;
                        if (USE_TABLE = '1') then
                            current_crossing <= next_crossing;
                            next_crossing <= table_start;
                        else
                            current_crossing <= next_crossing;
                            next_crossing <= current_crossing + puls_step;
                        end if;
                    end if;

                -- Wait for pulse width position, and de-assert pulse output.
                when WAIT_WIDTH =>
                    if (posn_error = '1' and puls_step /= 0) then
                        pcomp_fsm <= WAIT_IN_ERROR;
                    elsif (posn_cross = '1') then
                        pulse <= not pulse;
                        if (USE_TABLE = '1') then
                            current_crossing <= next_crossing;
                            next_crossing <= table_width;
                        else
                            if (puls_step = 0) then
                                current_crossing <= puls_start - puls_deltap;
                                next_crossing <= puls_start;
                            else
                                current_crossing <= next_crossing;
                                next_crossing <= current_crossing + puls_step;
                            end if;
                        end if;

                        -- Make End-Of-Operation Decision coding is a bit repetitive,
                        -- but makes it easier to understand.
                        if (USE_TABLE = '0') then
                            -- Run continuously until disabled
                            if (unsigned(NUM) = 0) then
                                if (puls_step = 0) then
                                    pcomp_fsm <= WAIT_INIT;
                                else
                                    pcomp_fsm <= WAIT_START;
                                end if;
                            -- All pulses generated and stop operation.
                            elsif (puls_counter = unsigned(NUM)) then
                                pcomp_fsm <= WAIT_ENABLE;
                                puls_counter <= (others => '0');
                                act_o <= '0';
                            -- Finite pulses are not finished, so continue pcomp'ing.
                            else
                                if (puls_step = 0) then
                                    pcomp_fsm <= WAIT_INIT;
                                else
                                    pcomp_fsm <= WAIT_START;
                                end if;
                            end if;
                        else
                            -- Table finished (probably immature)
                            if (table_end_i = '1') then
                                pcomp_fsm <= WAIT_ENABLE;
                                puls_counter <= (others => '0');
                                act_o <= '0';
                            -- Run forever until disabled.
                            elsif (unsigned(NUM) = 0) then
                                pcomp_fsm <= WAIT_START;
                            -- All pulses generated and stop operation.
                            elsif (puls_counter = unsigned(NUM)) then
                                pcomp_fsm <= WAIT_ENABLE;
                                puls_counter <= (others => '0');
                                act_o <= '0';
                            -- Pulses are not finished, so continue pcomp'ing.
                            else
                                pcomp_fsm <= WAIT_START;
                            end if;
                        end if;
                    end if;
                -- Position jumped two comparison points in one go, flagging error.
                -- Wait until re-enable
                when WAIT_IN_ERROR =>
                    err_o(0) <= '1';
                    pulse <= '0';
                    puls_counter <= (others => '0');
                    act_o <= '0';
                    pcomp_fsm <= WAIT_IN_ERROR;

                when others =>
            end case;
        end if;
    end if;
end process;

end rtl;

