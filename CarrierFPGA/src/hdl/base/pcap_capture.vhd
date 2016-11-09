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
    extn_i              : in  std_logic_vector(31 downto 0);
    frame_i             : in  std_logic;
    capture_i           : in  std_logic;
    data_val_i          : in  std_logic;
    posn_o              : out std_logic_vector(31 downto 0);
    extn_o              : out std_logic_vector(31 downto 0);
    -- Block register
    FRAMING_ENABLE      : in  std_logic;
    FRAMING_MASK        : in  std_logic;
    FRAMING_MODE        : in  std_logic
);
end pcap_capture;

architecture rtl of pcap_capture is

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

-- Calculate on-the-fly Difference from Frame-to-Frame
posn_delta <= signed(posin) - signed(posn_prev);

-- Sum incoming data Frame-to-Frame
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_sum <= (others => '0');
        else
            -- If data arrived on the same clock with frame
            if (frame_i = '1' and data_val_i = '1') then
                posn_sum <= signed(posin);
            -- Reset accumulator on frame input
            elsif (frame_i = '1' and data_val_i = '0') then
                posn_sum <= (others => '0');
            -- Accumulate incoming data
            elsif (data_val_i = '1') then
                posn_sum <= posn_sum + signed(posin);
            end if;
        end if;
    end if;
end process;



posn_sum <= signed(posin) + signed(posn_prev);

--------------------------------------------------------------------------
-- Position output can be following based on FRAMING mode of operation.
-- A capture between two Frame inputs indicates a live frame
-- where data is captured at the end when in FRAMING mode.
--------------------------------------------------------------------------
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

            -- Framing selected globally, so capture accordingly
            if (FRAMING_ENABLE = '1') then
                if (frame_i = '1') then
                    posn_prev <= posin;

                    -- Framing mode not selected, capture on trigger
                    if (FRAMING_MASK = '0') then
                        posout <= posin_capture;
                    else
                        -- Normal framing mode : Difference
                        if (FRAMING_MODE = '0') then
                            posout <= std_logic_vector(posn_delta);
                        -- Special framing mode : Average
                        else
                            posout <= std_logic_vector(posn_sum);
                        end if;
                    end if;
                end if;
            -- Framing not enabled capture instantaneously
            else
                posout <= posin;
            end if;
        end if;
    end if;
end process;

end rtl;

