--------------------------------------------------------------------------------
--  File:       pcap_frame.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity pcap_frame is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;

    -- Block register
    FRAMING_MASK        : in  std_logic_vector(31 downto 0);
    FRAMING_ENABLE      : in  std_logic;
    FRAMING_MODE        : in  std_logic_vector(31 downto 0);

    -- Block input and outputs.
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    extbus_i            : in  extbus_t;
    enable_i            : in  std_logic;
    frame_i             : in  std_logic;
    capture_i           : in  std_logic;
    capture_o           : out std_logic;
    posn_o              : out std32_array(63 downto 0);
    error_o             : out std_logic
);
end pcap_frame;

architecture rtl of pcap_frame is

signal reset            : std_logic;

signal frame_prev       : std_logic;
signal capture_prev     : std_logic;
signal ongoing_capture  : std_logic;

signal frame_rise       : std_logic;
signal capture_rise     : std_logic;

signal timestamp        : unsigned(63 downto 0);
signal capture_ts       : unsigned(63 downto 0);
signal frame_ts         : unsigned(31 downto 0);
signal frame_length     : unsigned(31 downto 0);
signal capture_offset   : unsigned(31 downto 0);

signal capture_din      : std32_array(63 downto 0);

begin

-- Input registers.
process(clk_i) begin
    if rising_edge(clk_i) then
        frame_prev <= frame_i;
        capture_prev <= capture_i;
    end if;
end process;

-- Detect rise/falling edge of internal signals.
frame_rise <= frame_i and not frame_prev;
capture_rise <= capture_i and not capture_prev;

-- Disable block when it is not enabled.
reset <= reset_i and not enable_i;

-- Capture flag behaviour is based on FRAMING mode and enable.
-- Enable makes sure that capture pulse will not be generated
-- preventing triggering oncoming modules higher level.
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            capture_o <= '0';
        else
            if (FRAMING_ENABLE = '0') then
                capture_o <= capture_rise;
            else
                capture_o <= frame_rise and ongoing_capture;
            end if;
        end if;
    end if;
end process;

--
-- Capture and Frame managements:
--
-- A capture between two Frame inputs indicates a live frame
-- where data is captured at the end when in FRAMING mode.
--
-- When FRAMING_ENABLE = 1:
--
-- FRAME:    |     |     |     |      |      |      |      |
-- CAPTURE:     x           x            x             x
-- Output          |           |             |             |
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            ongoing_capture <= '0';
            error_o <= '0';
        else
            if (enable_i = '1') then
                -- If happens on the same clock, capture belongs the
                -- immediate frame.
                if (frame_rise = '1' and capture_rise = '1') then
                    ongoing_capture <= '1';
                -- Otherwise start a clear frame.
                elsif (frame_rise = '1') then
                    ongoing_capture <= '0';
                -- Flag that capture pulse received.
                elsif (capture_rise = '1') then
                    ongoing_capture <= '1';
                end if;
            else
                ongoing_capture <= '0';
            end if;

            -- Flag an error if more than one (1) capture pulse is received
            -- within a frame.
            error_o <= '0';

            if (FRAMING_ENABLE = '1' and ongoing_capture = '1') then
                error_o <= '1';
            end if;
        end if;
    end if;
end process;

--
-- There are three timestamp information is captured as: Start of Drame,
-- Framen Length and Capture Offset.
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            timestamp <= (others => '0');
            frame_ts <= (others => '0');
            capture_ts <= (others => '0');
            frame_length <= (others => '0');
            capture_offset <= (others => '0');
        else
            if (enable_i = '1') then
                timestamp <= timestamp + 1;
            else
                timestamp <= (others => '0');
            end if;

            -- Timestamp for capture pulse.
            -- Capture offset from frame start.
            if (capture_rise = '1') then
                capture_ts <= timestamp;
                capture_offset <= unsigned(timestamp(31 downto 0)) - frame_ts;
            end if;

            -- Frame length.
            if (frame_rise = '1') then
                frame_ts <= unsigned(timestamp(31 downto 0));
                frame_length <= unsigned(timestamp(31 downto 0)) - frame_ts;
            end if;
        end if;
    end if;
end process;

--
-- Instantiate Position Processing Blocks
--
PROC_OTHERS : FOR I IN 1 TO 31 GENERATE

pcap_posproc_encoder : entity work.pcap_posproc
port map (
    clk_i               => clk_i,
    reset_i             => reset,

    posn_i              => posbus_i(I),
    extn_i              => (others => '0'),

    frame_i             => frame_rise,
    capture_i           => capture_rise,
    posn_o              => posn_o(I),
    extn_o              => open,

    FRAMING_ENABLE      => FRAMING_ENABLE,
    FRAMING_MODE        => FRAMING_MODE(I)
);
END GENERATE;

-- Zero field
posn_o(0) <= posbus_i(0);

-- posn_o(35 downto 32) <= Encoder extention
posn_o(37) <= std_logic_vector(frame_length);
posn_o(38) <= std_logic_vector(capture_offset);
posn_o(39) <= sysbus_i(31 downto 0);
posn_o(40) <= sysbus_i(63 downto 32);
posn_o(41) <= sysbus_i(95 downto 64);
posn_o(42) <= sysbus_i(127 downto 96);
posn_o(62) <= std_logic_vector(capture_ts(31 downto  0));
posn_o(63) <= std_logic_vector(capture_ts(63 downto 32));

end rtl;

