--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Encoder position field processing.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.top_defines.all;

entity pcap_posproc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block input and outputs.
    posn_i              : in  std_logic_vector(31 downto 0);
    extn_i              : in  std_logic_vector(31 downto 0);
    frame_i             : in  std_logic;
    capture_i           : in  std_logic;
    posn_o              : out std_logic_vector(31 downto 0);
    extn_o              : out std_logic_vector(31 downto 0);
    -- Block register
    FRAMING_ENABLE      : in  std_logic;
    FRAMING_MASK        : in  std_logic;
    FRAMING_MODE        : in  std_logic
);
end pcap_posproc;

architecture rtl of pcap_posproc is

signal posin            : std_logic_vector(63 downto 0);
signal posin_capture    : std_logic_vector(63 downto 0);
signal posout           : std_logic_vector(63 downto 0);
signal posn_prev        : std_logic_vector(63 downto 0);
signal posn_delta       : signed(63 downto 0);
signal posn_sum         : signed(63 downto 0);

begin

-- Output assignments.
posn_o <= posout(31 downto 0);
extn_o <= posout(63 downto 32);

-- Combine into 64-bit values.
posin <= extn_i & posn_i;

-- Calculate Delta and Sum from Frame-to-Frame
posn_delta <= signed(posin) - signed(posn_prev);
posn_sum <= signed(posin) + signed(posn_prev);

--
-- Position output can be following based on FRAMING mode of operation.
--
-- Instantaneous value,
-- Difference between values at frame start and end.
-- Average of values at frame start and end.
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posin_capture <= (others => '0');
            posn_prev <= (others => '0');
            posout <= (others => '0');
        else
            -- Store instantaneous value of posn on capture pulse
            if (capture_i = '1') then
                posin_capture <= posin;
            end if;

            -- Output new POSN on frame input.
            if (FRAMING_ENABLE = '1') then
                if (frame_i = '1') then
                    posn_prev <= posin;

                    -- Send captured value in sync to frame pulse
                    if (FRAMING_MASK = '0') then
                        posout <= posin_capture;
                    -- Output Difference or Aberage Value
                    else
                        if (FRAMING_MODE = '0') then
                            posout <= std_logic_vector(posn_delta);
                        else
                            posout <= std_logic_vector(posn_sum srl 1);
                        end if;
                    end if;
                end if;
            -- Else output instantaneous value.
            else
                posout <= posin;
            end if;
        end if;
    end if;
end process;

end rtl;

