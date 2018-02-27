--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : This module handles Framing and Capture pulse generation along
--                with ADC/Encoder position processing.
--
--                Output from this block is fed to Buffer block for capture.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity pcap_frame is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block register
    CAPTURE_EDGE        : in  std_logic_vector(1 downto 0);
    SHIFT_SUM           : in  std_logic_vector(5 downto 0);
    -- Block input and outputs.
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    gate_i              : in  std_logic;
    enable_i            : in  std_logic;
    capture_i           : in  std_logic;
    timestamp_i         : in  std_logic_vector(63 downto 0);

    capture_o           : out std_logic;
    mode_ts_bits        : out t_mode_ts_bits;
    error_o             : out std_logic
);
end pcap_frame;

architecture rtl of pcap_frame is

signal gate_prev        : std_logic;
signal capture_prev     : std_logic;
signal ongoing_capture  : std_logic;

signal capture_rise     : std_logic;
signal capture_fall     : std_logic;
signal first_frame      : std_logic;
signal capture          : std_logic;
signal gate_rise        : std_logic;
signal gate_fall        : std_logic;
signal start_i          : std_logic;
signal end_i            : std_logic;

signal timestamp        : unsigned(63 downto 0);
signal capture_ts       : unsigned(63 downto 0) := (others => '0');
signal frame_ts         : unsigned(63 downto 0) := (others => '0');
signal frame_length     : unsigned(63 downto 0) := (others => '0');
signal capture_offset   : unsigned(63 downto 0) := (others => '0');

signal ts_start         : std_logic_vector(63 downto 0);
signal ts_end           : std_logic_vector(63 downto 0);
signal ts_capture       : std_logic_vector(63 downto 0);

signal cnt_samples      : unsigned(39 downto 0);  -- 8 bit shift allow for 
signal samples          : std_logic_vector(31 downto 0);

signal extbus           : std32_array(31 downto 0);

signal value_o          : std32_array(31 downto 0);
signal diff_o           : std32_array(31 downto 0);
signal sum_l_o          : std32_array(31 downto 0);
signal sum_h_o          : std32_array(31 downto 0);
signal min_o            : std32_array(31 downto 0);
signal max_o            : std32_array(31 downto 0);


begin

--------------------------------------------------------------------------
-- Input registers, and
-- Detect rise/falling edge of internal signals.
--------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
        capture_prev <= capture_i;
        gate_prev <= gate_i;
    end if;
end process;

capture_rise <= capture_i and not capture_prev;
capture_fall <= not capture_i and capture_prev;
gate_rise <= gate_i and not gate_prev;
gate_fall <= not gate_i and gate_prev;

--------------------------------------------------------------------------
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
--------------------------------------------------------------------------
--capture <= capture_rise when (FRAMING_ENABLE = '0') else
capture <= capture_rise when (gate_i = '0') else
                gate_rise and ongoing_capture;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ongoing_capture <= '0';
            capture_o <= '0';
--            first_frame <= '0';
            error_o <= '0';
        else
            if capture_prev = '0' and capture_i = '1' then
                start_i <= '1';
            else
                start_i <= '0';
            end if;
            
            if capture_prev = '1' and capture_i = '0' then
                end_i <= '1';
            else
                end_i <= '0';
            end if;
                             
            -- Data processing in capture module has a latency of 1 tick so
            -- capture signal must be aligned
            capture_o <= capture;

            -- First frame arrived flag which is used to detect 'capture
            -- before frame pulse' error condition
            -- Resets on arming.
--            if (frame_rise = '1') then
--                first_frame <= '1';
--            end if;
--
--            -- If happens on the same clock, capture belongs the
--            -- immediate frame.
--            if (frame_rise = '1' and capture_rise = '1') then
--                ongoing_capture <= '1';
--            -- Otherwise start a clear frame.
--            elsif (frame_rise = '1') then
--                ongoing_capture <= '0';
--            -- Flag that capture pulse received.
--            elsif (capture_rise = '1') then
--                ongoing_capture <= '1';
--            end if;

            -- When Framing is enabled, there are two error conditions
            -- (1) Capture pulse arrives before frame, and
            -- (2) More than 1 capture pulses in a frame
            -- Error is latched until next pcap start (via reset port)

            -- Make sure that frame and capture are not on the same clock
----            if (first_frame = '0' and frame_rise = '0') then
----                error_o <= gate_i and capture_rise;
----            elsif (ongoing_capture = '1' and frame_rise = '0') then
----                error_o <= gate_i and capture_rise;
----            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- There are three timestamp information captured as: Start of Frame,
-- Frame Length and Capture Offset.
--------------------------------------------------------------------------
timestamp <= unsigned(timestamp_i);

process(clk_i) begin
    if rising_edge(clk_i) then
        -- Start of Frame timestamp and Frame Length in ticks
        if (capture_rise = '1') then
            frame_ts <= timestamp;
            frame_length <= timestamp - frame_ts;
            ts_start <= std_logic_vector(frame_ts);
        end if;

        -- End of frame timestamp 
        if (capture_fall = '1') then
            ts_end <= std_logic_vector(timestamp);
        end if;    

        -- Capture TIMESTAMP and capture offset from frame start            ############### TIMESTAMP ###############
        if (capture_rise = '1') then
            capture_ts <= timestamp;
            capture_offset <= timestamp - frame_ts;
            ts_capture <= std_logic_vector(capture_ts);
        end if;
        
        -- Count the number of samples 
        if (capture_i = '1') then
            cnt_samples <= cnt_samples +1;
        else
            cnt_samples <= (others => '0');
            samples <= std_logic_vector(cnt_samples(31+(to_integer(unsigned(SHIFT_SUM(2 downto 0)))) downto 0+(to_integer(unsigned(SHIFT_SUM(2 downto 0))))));
        end if;
        
    end if;
end process;

-------------------------------------------------------------------------- 
-- Instantiate cap_frame block
--------------------------------------------------------------------------
CAP_FRAME_GEN : for i in 31 downto 0 generate

cap_frame_inst : entity work.cap_frame
port map (
    clk_i        => clk_i,
    gate_i       => gate_i,   
    enable_i     => enable_i,
    capture_i    => capture_i,
    start_i      => start_i,
    end_i        => end_i,    
    value_i      => posbus_i(i),
    shift_i      => SHIFT_SUM,
    capture_edge => CAPTURE_EDGE,
    value_o      => value_o(i),   
    diff_o       => diff_o(i),   
    sum_l_o      => sum_l_o(i),
    sum_h_o      => sum_h_o(i),
    min_o        => min_o(i),
    max_o        => max_o(i)
    );
end generate;

-- Mode 0                       -- CAPTURE goes high no matter what the state of GATE                       RISING EDGE of CAPTURE
-- Mode 1                       -- Only counts the differences while GATE is high                           FALLING EDGE of GATE
-- Mode 2                       -- Sum of all the samples when GATE is high                                 FALLING EDGE of GATE
-- Mode 3                       -- Sum of all the samples when GATE is high                                 FALLING EDGE of GATE
-- Mode 4                       -- Produces the min of all values when GATE is high else zero if GATE low   FALLING EDGE of GATE
-- Mode 5                       -- Produces the max of all values when GATE is high else zero if GATE low   FALLING EDGE of GATE
-- Number of Samples            -- Indicates the number of clock GATE was high for                          FALLING EDGE of GATE
-- TimeStamp                    -- Capture the timestamp when CAPTURE goes high                             RISING EDGE of CAPTURE
-- TimeStamp START              -- Capture high at START                                                    RISING EDGE of CAPTURE                                              
-- TimeStamp END                -- Capture high and END                                                     RISING and FALLING EDGE of CAPTURE
-- Bits0,Bits1,Bits2 and Bits3  -- Enable & Capture                                                         RISING EDGE of CAPTURE

-- Triggering 
-- Triggering on rising is the default 
    
--------------------------------------------------------------------------
-- Assign 64x32-bits position fields for data capture
--------------------------------------------------------------------------

--Registered this 
ps_mode_ts_bits: process(clk_i)
begin
    if rising_edge(Clk_i) then
                
        -- Cature data 
        lp_mode_data: for i in 31 downto 0 loop
            mode_ts_bits.mode(i)(0) <= value_o(i);
            mode_ts_bits.mode(i)(1) <= diff_o(i);
            mode_ts_bits.mode(i)(2) <= sum_l_o(i);
            mode_ts_bits.mode(i)(3) <= sum_h_o(i);
            mode_ts_bits.mode(i)(4) <= min_o(i);
            mode_ts_bits.mode(i)(5) <= max_o(i);   
        end loop lp_mode_data;
        mode_ts_bits.ts(0) <= ts_start(31 downto 0);
        mode_ts_bits.ts(1) <= ts_start(63 downto 32);   
        mode_ts_bits.ts(2) <= ts_end(31 downto 0);
        mode_ts_bits.ts(3) <= ts_end(63 downto 32);
        mode_ts_bits.ts(4) <= ts_capture(31 downto 0);
        mode_ts_bits.ts(5) <= ts_capture(63 downto 32);
        mode_ts_bits.ts(6) <= samples;
        mode_ts_bits.bits(0) <= sysbus_i(31 downto 0);
        mode_ts_bits.bits(1) <= sysbus_i(63 downto 32);
        mode_ts_bits.bits(2) <= sysbus_i(95 downto 64);
        mode_ts_bits.bits(3) <= sysbus_i(127 downto 96);   
                
    end if;
end process ps_mode_ts_bits;                


end rtl;

