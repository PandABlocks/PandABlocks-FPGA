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
--      - TO DO: Average of values at frame start and end.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.operator.all;

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
    overflow_o          : out std_logic;
    -- Block register
    FRAMING_ENABLE      : in  std_logic;
    FRAMING_MASK        : in  std_logic;
    FRAMING_MODE        : in  std_logic
);
end pcap_capture;

architecture rtl of pcap_capture is

signal capture_mode     : std_logic_vector(2 downto 0);

signal posn_latch       : std_logic_vector(31 downto 0);
signal posn_prev        : std_logic_vector(31 downto 0);
signal posn_delta       : std_logic_vector(31 downto 0);

begin

--------------------------------------------------------------------------
-- Posn data capture processing is based on Mode of Operation
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_latch <= (others => '0');
            posn_prev <= (others => '0');
        else
            -- Latch posn on capture pulse
            if (capture_i = '1') then
                posn_latch <= posn_i;
            end if;

            -- Calculate frame-to-frame posn difference
            if (frame_i = '1') then
                posn_prev <= posn_i;
            end if;
        end if;
    end if;
end process;

-- On-the-fly frame-to-frame posn difference
posn_delta <= std_logic_vector(signed(posn_i) - signed(posn_prev));

--------------------------------------------------------------------------
-- Position output can be following based on FRAMING mode of operation.
-- A capture between two Frame inputs indicates a live frame
-- where data is captured at the end when in FRAMING mode.
--
-- capture_mode flags
-- 0 x x  : posn
-- 1 0 x  : posn_latch
-- 1 1 0  : posn_delta
-- 1 1 1  : posn_sum
--------------------------------------------------------------------------
capture_mode <= FRAMING_ENABLE & FRAMING_MASK & FRAMING_MODE;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_o <= (others => '0');
            extn_o <= (others => '0');
        else
            -- Multiplex output position data
            case capture_mode is
                when "000" => posn_o <= posn_i;
                              extn_o <= (others => '0');
                when "001" => posn_o <= posn_i;
                              extn_o <= (others => '0');
                when "010" => posn_o <= posn_i;
                              extn_o <= (others => '0');
                when "011" => posn_o <= posn_i;
                              extn_o <= (others => '0');
                when "100" => posn_o <= posn_latch;
                              extn_o <= (others => '0');
                when "101" => posn_o <= posn_latch;
                              extn_o <= (others => '0');
                when "110" => posn_o <= posn_delta;
                              extn_o <= (others => '0');
                when "111" => posn_o <= (others => '0');
                              extn_o <= (others => '0');
                when others =>
            end case;
        end if;
    end if;
end process;

end rtl;

