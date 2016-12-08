--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Position fields processing block.
--  Block can output:
--      - Instantaneous value,
--      - Difference between values at frame start and end.
--      - Average of values at frame start and end.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pcap_capture is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block input and outputs.
    posn_i              : in  std_logic_vector(31 downto 0);
    frame_i             : in  std_logic;
    capture_i           : in  std_logic;
    posn_o              : out std_logic_vector(31 downto 0);
    extn_o              : out std_logic_vector(31 downto 0);
    -- Block register
    FRAMING_ENABLE      : in  std_logic;
    FRAMING_MASK        : in  std_logic;
    FRAMING_MODE        : in  std_logic
);
end pcap_capture;

architecture rtl of pcap_capture is

signal posn             : signed(63 downto 0);
signal posn_prev        : signed(63 downto 0);
signal posn_latch       : signed(63 downto 0);
signal posout           : signed(63 downto 0);
signal posn_delta       : signed(63 downto 0);
signal posn_accum       : signed(63 downto 0);
signal capture_mode     : std_logic_vector(2 downto 0);

begin

-- Output assignments.
posn_o <= std_logic_vector(posout(31 downto 0));
extn_o <= std_logic_vector(posout(63 downto 32));

-- Combine into 64-bit values.
posn <= resize(signed(posn_i), 64);

--------------------------------------------------------------------------
-- Posn data capture processing is based on Mode of Operation
--------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_accum <= (others => '0');
            posn_latch <= (others => '0');
            posn_prev <= (others => '0');
        else
            -- Latch posn on capture pulse
            if (capture_i = '1') then
                posn_latch <= posn;
            end if;

            -- Calculate frame-to-frame posn difference
            if (frame_i = '1') then
                posn_prev <= posn;
            end if;

            -- Accumulate frame-to-frame posn values on every tick
            -- Reset accumulator on frame pulse, and latch sum value
            if (frame_i = '1') then
                posn_accum <= posn;
            -- Accumulate incoming data
            else
                posn_accum <= posn_accum + posn;
            end if;
        end if;
    end if;
end process;

-- On-the-fly frame-to-frame posn difference
posn_delta <= posn - posn_prev;

--------------------------------------------------------------------------
-- Position output can be following based on FRAMING mode of operation.
-- A capture between two Frame inputs indicates a live frame
-- where data is captured at the end when in FRAMING mode.
--
-- capture_mode flags
-- 0 x x  : posn
-- 1 0 x  : posn_latch
-- 1 1 0  : posn_delta
-- 1 1 1  : posn_sun
--------------------------------------------------------------------------
capture_mode <= FRAMING_ENABLE & FRAMING_MASK & FRAMING_MODE;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posout <= (others => '0');
        else
            -- Multiplex output position data
            case capture_mode is
                when "000" => posout <= posn;
                when "001" => posout <= posn;
                when "010" => posout <= posn;
                when "011" => posout <= posn;
                when "100" => posout <= posn_latch;
                when "101" => posout <= posn_latch;
                when "110" => posout <= posn_delta;
                when "111" => posout <= posn_accum;
                when others => posout <= posn;
            end case;
        end if;
    end if;
end process;

end rtl;

