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

type fsm_t is (WAIT_ENABLE, WAIT_DELTAP, WAIT_START, WAIT_WIDTH, WAIT_IN_ERROR);
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
signal posn_error           : std_logic;
signal pulse                : std_logic;

signal table_start          : signed(31 downto 0);
signal table_width          : signed(31 downto 0);
signal table_dir            : std_logic;
signal table_read           : std_logic;

signal puls_dir             : std_logic;
signal dp_pos_cross         : std_logic;
signal dp_neg_cross         : std_logic;
signal pos_cross            : std_logic;
signal neg_cross            : std_logic;
signal pos_error            : std_logic;
signal neg_error            : std_logic;

begin

-- Assign outputs.
out_o <= pulse and enable_i;

---------------------------------------------------------------------------
-- Register inputs and detect rise/fall edges required
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
-- Invert parameters' sign for based on encoder direction
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

-- Separate 64-bit table data input.
table_start <= signed(table_posn_i(63 downto 32));
table_width <= signed(table_posn_i(31 downto 0));
table_read_o <= enable_rise or table_read when (USE_TABLE = '1') else '0';

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
-- Generate deltaP and position compare crossing signals to be used in FSM
---------------------------------------------------------------------------
dp_pos_cross <= '1' when (puls_dir = '0' and posn <= current_crossing)
                        else '0';

dp_neg_cross <= '1' when (puls_dir = '1' and posn >= current_crossing)
                            else '0';

pos_cross <= '1' when (puls_dir = '0' and posn >= current_crossing) else '0';
neg_cross <= '1' when (puls_dir = '1' and posn <= current_crossing) else '0';

---------------------------------------------------------------------------
-- Error detection is currently only available in normal mode
-- Detect when position value crosses next_crossing point jumping the
-- current_crossing
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
            table_dir <= '0';
            table_read <= '0';
        else
            -- Extract table direction from Delta_P, first entry on the
            -- table.
            if (pcomp_fsm = WAIT_ENABLE and enable_rise = '1') then
                if (table_start < table_width) then
                    table_dir <= '0';
                else
                    table_dir <= '1';
                end if;
            end if;

            -- Read strobe for the next value in the table
            table_read <= '0';

            case pcomp_fsm is
                -- Wait for enable (rising edge) to start operation
                when WAIT_ENABLE =>
                    if (enable_rise = '1') then
                        -- Read first sample as absolute DeltaP
                        if (USE_TABLE = '1') then
                            current_crossing <= table_start;
                        else
                        -- Absolute deltaP crossing point
                            current_crossing <= puls_start - puls_deltap;
                            next_crossing <= puls_start;
                        end if;
                        act_o <= '1';
                        pcomp_fsm <= WAIT_DELTAP;
                    end if;

                -- Wait for DeltaP point crossing
                when WAIT_DELTAP =>
                    if (dp_pos_cross = '1' or dp_neg_cross = '1') then
                        pcomp_fsm <= WAIT_START;
                        if (USE_TABLE = '1') then
                            current_crossing <= table_start;
                            next_crossing <= table_start + table_width;
                        else
                            current_crossing <= puls_start;
                            next_crossing <= puls_start + puls_width;
                        end if;
                    end if;

                -- Wait for pulse start position, and assert pulse output.
                when WAIT_START =>
                    if (posn_error = '1' and USE_TABLE = '0') then
                        pcomp_fsm <= WAIT_IN_ERROR;
                    elsif (pos_cross = '1' or neg_cross = '1') then
                        pulse <= not pulse;
                        puls_counter <= puls_counter + 1;
                        pcomp_fsm <= WAIT_WIDTH;
                        table_read <= '1';
                        if (USE_TABLE = '1') then
                            current_crossing <= table_width;
                            next_crossing <= table_start + table_width;
                        else
                            current_crossing <= next_crossing;
                            next_crossing <= current_crossing + puls_step;
                        end if;
                    end if;

                -- Wait for pulse width position, and de-assert pulse output.
                when WAIT_WIDTH =>
                    if (posn_error = '1' and puls_step /= 0 and USE_TABLE = '0') then
                        pcomp_fsm <= WAIT_IN_ERROR;
                    elsif (pos_cross = '1' or neg_cross = '1') then
                        pulse <= not pulse;
                        if (USE_TABLE = '1') then
                            current_crossing <= table_start;
                        else
                            if (puls_step = 0) then
                                current_crossing <= puls_start - puls_deltap;
                                next_crossing <= puls_start;
                            else
                                current_crossing <= next_crossing;
                                next_crossing <= current_crossing + puls_step;
                            end if;
                        end if;

                        -- Make End-Of-Operation Decision:
                        -- Run forever until disabled.
                        if (unsigned(NUM) = 0) then
                            if (puls_step = 0) then
                                pcomp_fsm <= WAIT_DELTAP;
                            else
                                pcomp_fsm <= WAIT_START;
                            end if;
                        -- All pulses generated and stop operation.
                        elsif (puls_counter = unsigned(NUM)) then
                            pcomp_fsm <= WAIT_ENABLE;
                            puls_counter <= (others => '0');
                            act_o <= '0';
                        -- Pulses are not finished, so continue pcomp'ing.
                        else
                            -- Step = 0 is a special condition.
                            if (puls_step = 0 and USE_TABLE = '0') then
                                pcomp_fsm <= WAIT_DELTAP;
                            else
                                pcomp_fsm <= WAIT_START;
                            end if;
                        end if;
                    end if;
                -- Position jumped two comparison points flagging error.
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

