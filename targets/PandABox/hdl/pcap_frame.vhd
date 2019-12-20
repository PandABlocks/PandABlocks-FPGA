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
    TRIG_EDGE           : in  std_logic_vector(1 downto 0);
    -- Block input and outputs.
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    enable_i            : in  std_logic;
    gate_i              : in  std_logic;
    trig_i              : in  std_logic;
    timestamp_i         : in  std_logic_vector(63 downto 0);
    -- Captured data
    trig_o              : out std_logic;
    mode_ts_bits_o      : out t_mode_ts_bits
);
end pcap_frame;

architecture rtl of pcap_frame is

signal gate_prev        : std_logic;
signal gate_rise        : std_logic;
signal gate_fall        : std_logic;
signal trig_dly         : std_logic;
signal timestamp        : unsigned(63 downto 0);

signal ts_start         : std_logic_vector(63 downto 0);
signal ts_start_dly     : std_logic_vector(63 downto 0);
signal ts_end           : std_logic_vector(63 downto 0);
signal ts_trig          : std_logic_vector(63 downto 0);

signal cnt_samples      : unsigned(39 downto 0);
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

signal trig_prev        : std_logic;
signal trig_rise        : std_logic;
signal trig_fall        : std_logic;
signal trig             : std_logic;
signal ts_start_enable  : std_logic;
signal ts_end_enable    : std_logic;


begin

-- Enable_i and Gate_i are level triggered
-- Enable marks the start and end of entire acquisition
-- Gate used to accept or reject samples within a single capture from the acquistion
-- Capture is edge triggered with an option to trigger on rising, falling or both

ps_prev: process(clk_i)
begin
    if rising_edge(clk_i) then
        trig_prev <= trig_i;
    end if;
end process ps_prev;


trig_rise <= not trig_prev and trig_i;
trig_fall <= trig_prev and not trig_i;

-- Handle the trigger
trig <= trig_rise when (trig_rise = '1' and (TRIG_EDGE = "00" or TRIG_EDGE = "10")) else
           trig_fall when (trig_fall = '1' and (TRIG_EDGE = "01" or TRIG_EDGE = "10")) else
           '0';


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
-- Delay the capture pulse for one clock because the record uses a
-- register process.
--------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            trig_dly <= '0';
            trig_o <= '0';
        -- Handle the delay in here as its is the delay of registering the
        -- results pass out on the mode_ts_bits record
        else
            trig_dly <= trig;
            trig_o <= trig;
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
        -- Capture the timestamp at the start of a capture frame
        if (enable_i = '0') then
            ts_start_enable <= '0';
        -- trig the timestamp this is the start of a frame
        elsif (ts_start_enable = '0' and gate_rise = '1') then
            ts_start_enable <= '1';
            ts_start <= std_logic_vector(timestamp);
        -- Capture the timestamp this is the start of a frame
        elsif (gate_i = '1' and trig = '1') then
            ts_start_enable <= '1';
            ts_start <= std_logic_vector(timestamp);
         -- This isn't a valid capture frame
        elsif (trig = '1' and gate_i = '0') then
            ts_start_enable <= '0';
            ts_start <= std_logic_vector(to_signed(-1,ts_start'length));
        end if;

        -- Capture the timestamp at the end of a capture frame
        if (enable_i = '0') then
            ts_end_enable <= '0';
        -- Capture the timestamp at the end of the frame
        elsif (gate_fall = '1') then
            if (trig = '0') then
                ts_end_enable <= '1';
            end if;
            ts_end <= std_logic_vector(timestamp);
        -- Capture the timestamp at the end of the frame
        elsif (trig = '1' and gate_i = '1') then
            ts_end_enable <= '0';
            ts_end  <= std_logic_vector(timestamp);
        -- This isn't a valid capture_frame
        elsif (trig = '1' and gate_i = '0') then
            ts_end_enable <= '0';
            if (ts_end_enable = '0') then
                ts_end <= std_logic_vector(to_signed(-1,ts_end'length));
            end if;
        end if;

        -- Capture TIMESTAMP
        if (trig = '1') then
            ts_trig <= std_logic_vector(timestamp);
        end if;

        -- Count the number of samples
        if (trig = '1' or enable_i = '0') then
            if (gate_i = '1') then
                cnt_samples <= to_unsigned(1,cnt_samples'length);
            else
                cnt_samples <= (others => '0');
            end if;
            samples <= std_logic_vector(cnt_samples(31+(to_integer(unsigned(SHIFT_SUM))) downto (to_integer(unsigned(SHIFT_SUM)))));
        elsif (gate_i = '1') then
            cnt_samples <= cnt_samples +1;
        end if;

        if (trig = '1') then
            bits0 <= bit_bus_i(31 downto 0);
            bits1 <= bit_bus_i(63 downto 32);
            bits2 <= bit_bus_i(95 downto 64);
            bits3 <= bit_bus_i(127 downto 96);
        end if;
    end if;
end process;


--------------------------------------------------------------------------
-- Instantiate pcap_frame_mode block
--------------------------------------------------------------------------
CAP_FRAME_GEN : for i in PBUSW-1 downto 0 generate

pcap_frame_mode_inst : entity work.pcap_frame_mode
port map (
    clk_i        => clk_i,
    enable_i     => enable_i,
    gate_i       => gate_i,
    trig_i       => trig,
    value_i      => pos_bus_i(i),
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
-- pos_bus (Bits0, Bits1, Bits3 and Bits 4)
--------------------------------------------------------------------------

--Register the mode_ts_bits buses
ps_mode_ts_bits: process(clk_i)
begin
    if rising_edge(Clk_i) then
        -- Capture the start timestamp
        ts_start_dly <= ts_start;
        if trig_dly = '1' then
            -- Cature mode data
            -- 32 bits * 6 Num of = 192 Total
            lp_mode_data: for i in PBUSW-1 downto 0 loop
                mode_ts_bits_o.mode(i)(0) <= value_o(i);
                mode_ts_bits_o.mode(i)(1) <= diff_o(i);
                mode_ts_bits_o.mode(i)(2) <= sum_l_o(i);
                mode_ts_bits_o.mode(i)(3) <= sum_h_o(i);
                mode_ts_bits_o.mode(i)(4) <= min_o(i);
                mode_ts_bits_o.mode(i)(5) <= max_o(i);
            end loop lp_mode_data;
            -- Capture TimeStamp data
            -- 32 bits * 7 Num of = 7 Total
            mode_ts_bits_o.ts(0) <= ts_start_dly(31 downto 0);
            mode_ts_bits_o.ts(1) <= ts_start_dly(63 downto 32);
            mode_ts_bits_o.ts(2) <= ts_end(31 downto 0);
            mode_ts_bits_o.ts(3) <= ts_end(63 downto 32);
            mode_ts_bits_o.ts(4) <= ts_trig(31 downto 0);
            mode_ts_bits_o.ts(5) <= ts_trig(63 downto 32);
            mode_ts_bits_o.ts(6) <= samples;
            -- Capture bit bus data
            -- 32 bits * 4 Num of = 4 Total
            mode_ts_bits_o.bits(0) <= bits0;
            mode_ts_bits_o.bits(1) <= bits1;
            mode_ts_bits_o.bits(2) <= bits2;
            mode_ts_bits_o.bits(3) <= bits3;
        end if;
    end if;
end process ps_mode_ts_bits;


end rtl;

