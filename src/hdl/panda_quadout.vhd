--------------------------------------------------------------------------------
--  File:       panda_quadout.vhd
--  Desc:       HDL implementation of a Incremental Encoder Output module.
--              The module follows position input and 4x quadrature encodes when
--              enabled.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity panda_quadout is
port (
    -- Clock and reset signals
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    --Position data
    enable_i            : in  std_logic;
    QPERIOD             : in  std_logic_vector(15 downto 0);
    posn_i              : in  std_logic_vector(31 downto 0);
    QSTATE              : out std_logic_vector(31 downto 0);
    --Quadrature A,B and Z input
    a_o                 : out std_logic;
    b_o                 : out std_logic
);
end panda_quadout;

architecture rtl of panda_quadout is

signal qenc_clk_ce      : std_logic;
signal posn             : signed(31 downto 0);
signal posn_tracker     : signed(31 downto 0);
signal posn_tracking    : std_logic;
signal qenc_dir         : std_logic;
signal qenc_trans       : std_logic;
signal posn_tracker_en  : std_logic;
signal reset            : std_logic;
signal enable           : std_logic;
signal enable_rise      : std_logic;

begin

-- Status output
QSTATE <= (0 => posn_tracking, others => '0');

-- To make life easier...
posn <= signed(posn_i);

-- Internal reset.
reset <= reset_i;

-- Input Registers
process(clk_i) begin
    if rising_edge(clk_i) then
        enable <= enable_i;
    end if;
end process;

enable_rise <= enable_i and not enable;

--
-- Generate QENC clk defined by the prescalar
-- This is the rate that Quadrature outputs A&B will toggle
--
qenc_clk_gen : process(clk_i)
    variable clk_cnt    : unsigned(15 downto 0) := X"0000";
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            qenc_clk_ce <= '0';
            clk_cnt := (others => '0');
        else
            if (clk_cnt =  unsigned('0' & QPERIOD(15 downto 1))-1) then
                qenc_clk_ce <= '1';
                clk_cnt := (others => '0');
            else
                qenc_clk_ce <= '0';
                clk_cnt := clk_cnt + 1;
            end if;
        end if;
    end if;
end process;

--
-- An internal counter is used to follow current value of the output position.
-- Counter value is later compared to position input for tracking.
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_tracker <= (others => '0');
            posn_tracker_en <= '0';
        else
            -- Latch & Go
            if (enable_rise = '1') then
                posn_tracker <= posn;
                posn_tracker_en <= '1';
            -- On every transition, update internal counter
            elsif (qenc_trans = '1') then
                if (qenc_dir = '0') then
                    posn_tracker <= posn_tracker + 1;
                else
                    posn_tracker <= posn_tracker - 1;
                end if;
            end if;
        end if;
    end if;
end process;

--
-- Quadrature encoding is enabled until internal counter reaches to the position
-- input value.
-- Transition and Direction pulses are sent to the Quad Encoder block.
--
posn_encoding : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_tracking <= '0';
            qenc_dir <= '0';
        else
            -- Compare current position with tracking value, and
            -- enable/disable tracking based on user flag.
            if (posn /= posn_tracker) then
                posn_tracking <= posn_tracker_en;
            else
                posn_tracking <= '0';
            end if;

            -- Set up tracking direction to the encoder
            if (posn > posn_tracker) then
                qenc_dir <= '0';    -- positive direction
            else
                qenc_dir <= '1';    -- negative direction
            end if;
        end if;
    end if;
end process;

-- Quad transitions happen on user defined clock rate
qenc_trans <= posn_tracking and qenc_clk_ce;

-- Instantiate Quadrature Encoder
panda_qenc_inst : entity work.panda_qenc
port map (
    clk_i           => clk_i,
    reset_i         => reset,
    quad_trans_i    => qenc_trans,
    quad_dir_i      => qenc_dir,
    a_o             => a_o,
    b_o             => b_o
);

end rtl;
