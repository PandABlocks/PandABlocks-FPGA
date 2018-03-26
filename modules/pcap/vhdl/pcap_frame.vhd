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
    SHIFT_SUM           : in  std_logic_vector(5 downto 0);
    -- Block input and outputs.
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    enable_i            : in  std_logic;
    gate_i              : in  std_logic;
    capture_i           : in  std_logic;
    timestamp_i         : in  std_logic_vector(63 downto 0);

    capture_o           : out std_logic;
    mode_ts_bits        : out t_mode_ts_bits
--    error_o             : out std_logic
);
end pcap_frame;

architecture rtl of pcap_frame is

signal gate_prev        : std_logic;
signal capture          : std_logic;
signal gate_rise        : std_logic;
signal gate_fall        : std_logic;

signal timestamp        : unsigned(63 downto 0);

signal ts_start         : std_logic_vector(63 downto 0);
signal ts_end           : std_logic_vector(63 downto 0);
signal ts_capture       : std_logic_vector(63 downto 0);

signal cnt_samples      : unsigned(39 downto 0);  -- 8 bit shift allow for 
signal samples          : std_logic_vector(31 downto 0);

signal value_o          : std32_array(31 downto 0);
signal diff_o           : std32_array(31 downto 0);
signal sum_l_o          : std32_array(31 downto 0);
signal sum_h_o          : std32_array(31 downto 0);
signal min_o            : std32_array(31 downto 0);
signal max_o            : std32_array(31 downto 0);
signal bits0            : std_logic_vector(31 downto 0);
signal bits1            : std_logic_vector(31 downto 0);
signal bits2            : std_logic_vector(31 downto 0);
signal bits3            : std_logic_vector(31 downto 0);


begin

-- Enable_i and Gate_i are level triggered 
-- Enable marks the start and end of entire acquisition
-- Gate used to accept or reject samples within a single capture from the acquistion
-- Capture is edge triggered with an option to trigger on rising, falling or both

--------------------------------------------------------------------------
-- Detect rise/falling edge of internal signals.
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        gate_prev <= gate_i;
    end if;
end process;   


gate_rise <= not gate_prev and gate_i;
gate_fall <= gate_prev and not gate_i;

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
capture <= capture_i when (gate_i = '0') else
                gate_rise;
--                gate_rise and ongoing_capture;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
--            ongoing_capture <= '0';
            capture_o <= '0';
        else                             
            -- Data processing in capture module has a latency of 1 tick so
            -- capture signal must be aligned
            capture_o <= capture;
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
        -- Capture the timestamp at the start
        if (enable_i = '0') then
            ts_start <= (others => '0');
        elsif (gate_rise = '1') then
            ts_start <= std_logic_vector(timestamp);
        end if;

        -- Capture the timestamp at the end 
        if (enable_i = '0') then
            ts_end <= (others => '0');
        elsif (gate_fall = '1') then
            ts_end <= std_logic_vector(timestamp);
        end if;    

        -- Capture TIMESTAMP             
        if (enable_i = '0') then
            ts_capture <= (others => '0');
        elsif (capture_i = '1') then
            ts_capture <= std_logic_vector(timestamp);
        end if;
        
        -- Count the number of samples 
        if (capture_i = '1' or enable_i = '0') then
            cnt_samples <= (others => '0');
            samples <= std_logic_vector(cnt_samples(31+(to_integer(unsigned(SHIFT_SUM(2 downto 0)))) downto (to_integer(unsigned(SHIFT_SUM(2 downto 0))))));
        elsif (gate_i = '1') then
            cnt_samples <= cnt_samples +1;
        end if;    
         
        if (capture_i = '1') then
            bits0 <= sysbus_i(31 downto 0);
            bits1 <= sysbus_i(63 downto 32);
            bits2 <= sysbus_i(95 downto 64);
            bits3 <= sysbus_i(127 downto 96);                   
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
    enable_i     => enable_i,   
    gate_i       => gate_i,   
    capture_i    => capture_i,
    value_i      => posbus_i(i),
    shift_i      => SHIFT_SUM,
    value_o      => value_o(i),   
    diff_o       => diff_o(i),   
    sum_l_o      => sum_l_o(i),
    sum_h_o      => sum_h_o(i),
    min_o        => min_o(i),
    max_o        => max_o(i)
    );
end generate;
    
--------------------------------------------------------------------------
-- Assign 32x6 = 192 mode bus (Mode 0, Mode 1, Mode 2, Mode 3, Mode 4 and Mode 5 
-- TimeStamp lsb Start 
-- TimeStamp msb Start
-- TimeStamp lsb End 
-- TimeStamp msb End
-- TimeStamp lsb
-- TimeStamp msb
-- Number of Samples
-- posbus (Bits0, Bits1, Bits3 and Bits 4)
--------------------------------------------------------------------------

--Register the mode_ts_bits buses  
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
        mode_ts_bits.bits(0) <= bits0;
        mode_ts_bits.bits(1) <= bits1;
        mode_ts_bits.bits(2) <= bits2;
        mode_ts_bits.bits(3) <= bits3;                   
    end if;
end process ps_mode_ts_bits;                


end rtl;

