--------------------------------------------------------------------------------
--  PandA Motion Project - 2018
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Paul Garrick
--------------------------------------------------------------------------------
--
--  Description : This module handles mode function i.e.
--                              : 1. Capture value captures the value of the pos_bus
--                              : 2. The lower 32 bits of the sum values of the pos_bus samples
--                              : 3. The upper 32 bits of the sum values of the pos_bus samples
--                              : 4. The minimum value on the pos_bus
--                              : 5. The maximum value on the pos_bus
--
--                Output from this block is fed to Buffer block for capture.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity pcap_frame_mode is
    port (clk_i         : in  std_logic;
          enable_i      : in  std_logic;
          gate_i        : in  std_logic;
          trig_i        : in  std_logic;
          value_i       : in  std_logic_vector(31 downto 0);
          shift_i       : in  std_logic_vector(5 downto 0);
          value_o       : out std_logic_vector(31 downto 0);
          diff_o        : out std_logic_vector(31 downto 0);
          sum_l_o       : out std_logic_vector(31 downto 0);
          sum_h_o       : out std_logic_vector(31 downto 0);
          min_o         : out std_logic_vector(31 downto 0);
          max_o         : out std_logic_vector(31 downto 0)
          );
end pcap_frame_mode;


architecture rtl of pcap_frame_mode is

constant c_thirty_one : natural := 31;
constant c_thirty_two : natural := 32;

signal start_val      : signed(31 downto 0);
signal min_val        : signed(31 downto 0);
signal max_val        : signed(31 downto 0);
signal sum_data       : signed(71 downto 0) := (others => '0');
signal diff_sum       : signed(31 downto 0) := (others => '0');

signal gate_prev      : std_logic;

begin

-- Mode 0 - Value
-- Mode 1 - Difference
-- Mode 2 - Sum Lo
-- Mode 3 - Sum Hi
-- Mode 4 - Min
-- Mode 5 - max


 -- Mode 0 - Value
 ps_output: process(clk_i)
 begin
    if rising_edge(clk_i) then
        if (trig_i = '1') then
            -- Mode 0 value
            value_o <= value_i;
        end if;
    end if;
 end process ps_output;



 -- Mode 1 Difference
 ps_diff: process(clk_i)
 begin
    if rising_edge(clk_i) then
        gate_prev <= gate_i;
        -- Latch the current value to start_val on rising gate or on capture
        if (gate_prev = '0' and gate_i = '1') or (trig_i = '1' and gate_i = '1') then
            start_val <= signed(value_i);
        end if;
        -- Zero diff_sum and set diff output on capture
        if (trig_i = '1') then
            if (gate_i = '1' or gate_prev = '1') then
                -- Diff output is current diff + diff_sum if capture and (falling or high gate)
                diff_o <= std_logic_vector(diff_sum + signed(value_i) - start_val);
            else
                diff_o <= std_logic_vector(diff_sum);
            end if;
            diff_sum <= (others => '0');
        -- Add in current diff to diff_sum if falling gate
        elsif (gate_prev = '1' and gate_i = '0') then
            diff_sum <= diff_sum + signed(value_i) - start_val;
        end if;
    end if;
 end process ps_diff;



 -- Mode 2 / 3, Sum Lo / Sum Hi
 ps_sum_val: process(clk_i)
 begin
    if rising_edge(clk_i) then
        -- Output the result
        if trig_i = '1' then
            -- Mode 2 Sum low data
            sum_l_o <= std_logic_vector(sum_data(c_thirty_one+(to_integer(unsigned(shift_i))) downto (to_integer(unsigned(shift_i)))));
            -- Mode 3 Sum High data
            sum_h_o <= std_logic_vector(sum_data(c_thirty_one+c_thirty_two+(to_integer(unsigned(shift_i))) downto c_thirty_two+(to_integer(unsigned(shift_i)))));
        end if;
        -- Clear sum
        if (enable_i = '0') then
            sum_data <= (others => '0');
        elsif (trig_i = '1' and gate_i = '0') then
            sum_data <= (others => '0');
        elsif (trig_i = '1' and gate_i = '1') then
            sum_data <= resize(signed(value_i),sum_data'length);
        -- Sum the received data whilst gate high
        elsif (gate_i = '1') then
            sum_data <= sum_data + signed(value_i);
        end if;
    end if;
 end process ps_sum_val;



 -- Mode 4 - Min
 -- Mode 5 - Max
 ps_min_max: process(clk_i)
 begin
    if rising_edge(clk_i) then
        -- Outpput th result
        if trig_i = '1' then
            min_o <= std_logic_vector(min_val);
            max_o <= std_logic_vector(max_val);
        end if;
        -- Clear min and max values
        if (enable_i = '0') then
            -- Maximum value
            min_val <= (min_val'high => '0', others => '1');
            -- Minimum value
            max_val <= (max_val'high => '1', others => '0');
        -- At the start capture the first value
        elsif (trig_i = '1' and gate_i = '1') then
            min_val <= signed(value_i);
            max_val <= signed(value_i);
        elsif (trig_i = '1' and gate_i = '0') then
            min_val <= (min_val'high => '0', others => '1');
            max_val <= (max_val'high => '1', others => '0');
        elsif (gate_i = '1') then
            -- Capture the minimum number
            if signed(value_i) < min_val then
                min_val <= signed(value_i);
            end if;
            -- Capture the maximum number
            if signed(value_i) > max_val then
                max_val <= signed(value_i);
            end if;
        end if;
    end if;
 end process ps_min_max;



end architecture rtl;
