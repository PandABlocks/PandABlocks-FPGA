--------------------------------------------------------------------------------
--  PandA Motion Project - 2018
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Paul Garrick
--------------------------------------------------------------------------------
--
--  Description : This module handles mode function i.e.
--                              : 0. Capture value captures the value of the pos_bus
--                              : 1. Capture difference of the pos_bus while gate was high
--                              : 2. The lower 32 bits of the sum values of the pos_bus samples
--                              : 3. The upper 32 bits of the sum values of the pos_bus samples
--                              : 4. The minimum value on the pos_bus
--                              : 5. The maximum value on the pos_bus
--                              : 6. Lower  32 bits of the Sum of squared values of the pos_bus samples
--                              : 7. Middle 32 bits of the Sum of squared values of the pos_bus samples
--                              : 8. Upper  32 bits of the Sum of squared values of the pos_bus samples
--
--
--
--  Output from this block is fed to Buffer block for capture.
--  Pipeline of the block : 2 x clk_i clock periods
--
--------------------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.top_defines.all;  -- need PCAP_STD_DEV_OPTION


entity pcap_frame_mode is
  port (clk_i         : in  std_logic;
        -- Block inputs
        enable_i      : in  std_logic;                    -- marks the start and end of an acquisition (level triggered)
        gate_i        : in  std_logic;                    -- accept or reject samples within a single capture (level triggered)
        trig_i        : in  std_logic;                    -- capture pulse (1 clk period)
        value_i       : in  std_logic_vector(31 downto 0);
        -- Block register
        SHIFT_SUM     : in  std_logic_vector(5 downto 0); -- parameter that do not change during a capture
        -- Captured data
        value_o       : out std_logic_vector(31 downto 0);
        diff_o        : out std_logic_vector(31 downto 0);
        sum_l_o       : out std_logic_vector(31 downto 0);
        sum_h_o       : out std_logic_vector(31 downto 0);
        min_o         : out std_logic_vector(31 downto 0);
        max_o         : out std_logic_vector(31 downto 0);
        sum_sq_0_o    : out std_logic_vector(31 downto 0);
        sum_sq_1_o    : out std_logic_vector(31 downto 0);
        sum_sq_2_o    : out std_logic_vector(31 downto 0);
        -- Captured data qualifier
        trig_o        : out std_logic                     -- trig_i delayed by 2 clk_i periods

  );
end pcap_frame_mode;


architecture rtl of pcap_frame_mode is

constant c_thirty_one : natural := 31;
constant c_thirty_two : natural := 32;

signal enable_r1      : std_logic;
signal gate_r1        : std_logic;
signal gate_r2        : std_logic;
signal trig_r1        : std_logic;

signal value_r1       : std_logic_vector(31 downto 0);
signal value_sq_r1    : unsigned(63 downto 0);  -- 32*32 --> 64

signal start_val      : signed(31 downto 0);
signal min_val        : signed(31 downto 0);
signal max_val        : signed(31 downto 0);
signal sum_data       : signed(71 downto 0) := (others => '0'); -- 32+32+8
signal sum_data_sq    : unsigned(103 downto 0); -- 64+32+8



begin



-- Mode 0 - Value
-- Mode 1 - Difference
-- Mode 2 - Sum Lo
-- Mode 3 - Sum Hi
-- Mode 4 - Min
-- Mode 5 - max
-- Mode 6 - Sum^2 Low
-- Mode 7 - Sum^2 Middle
-- Mode 8 - Sum^2 High


-- input pipeline registers
ps_inputs_reg: process(clk_i)
begin
    if rising_edge(clk_i) then
      -- 1st pipeline stage
      enable_r1     <= enable_i;
      gate_r1       <= gate_i;
      trig_r1       <= trig_i;
      value_r1      <= value_i;
      -- Compute input value squared on 64 bits
      value_sq_r1 <= unsigned(signed(value_i) * signed(value_i));

      -- 2nd pipeline stage
      gate_r2       <= gate_r1;

      -- data output qualifier
      trig_o        <= trig_r1;
  end if;
end process ps_inputs_reg;



-- Mode 0 - Value
ps_value : process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Output the result
        if (trig_r1 = '1') then
          value_o <= value_r1;
      end if;
    end if;
end process ps_value;



-- Mode 1 Difference
ps_diff: process(clk_i)
    variable diff_sum   : signed(31 downto 0) := (others => '0');
begin
    if rising_edge(clk_i) then
        -- Latch the current value to start_val on rising gate or on capture
        if (gate_r1 = '1' and gate_r2 = '0') or (trig_r1 = '1' and gate_r1 = '1') then
            start_val <= signed(value_r1);
        end if;

        -- Clear diff sum on disable
        if (enable_r1 = '0') then
            diff_sum := (others => '0');
        -- Add to the sum on falling gate or trigger with gate_prev
        elsif gate_r2 = '1' and (gate_r1 = '0' or trig_r1 = '1') then
            diff_sum := diff_sum + signed(value_r1) - start_val;
        end if;

        -- Output the result
        if (trig_r1 = '1') then
            diff_o <= std_logic_vector(diff_sum);
            diff_sum := (others => '0');
        end if;

    end if;
end process ps_diff;




-- Mode 2 / 3, Sum Lo / Sum Hi
ps_sum_val: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Output the result
        if trig_r1 = '1' then
            -- Mode 2 Sum low data
            sum_l_o <= std_logic_vector(sum_data(31+(to_integer(unsigned(SHIFT_SUM))) downto (to_integer(unsigned(SHIFT_SUM)))));
            -- Mode 3 Sum High data
            sum_h_o <= std_logic_vector(sum_data(63+(to_integer(unsigned(SHIFT_SUM))) downto 32+(to_integer(unsigned(SHIFT_SUM)))));
        end if;

        -- Clear sum on disable or trigger with no gate high
        if (enable_r1 = '0') or (trig_r1 = '1' and gate_r1 = '0') then
            sum_data <= (others => '0');
        -- Set sum to current value on trigger with gate high
        elsif (trig_r1 = '1' and gate_r1 = '1') then
            sum_data <= resize(signed(value_r1),sum_data'length);
        -- Sum the received data whilst gate high
        elsif (gate_r1 = '1') then
            sum_data <= sum_data + signed(value_r1);
        end if;
    end if;
end process ps_sum_val;


--------------------------------------------------------------------------------
-- Modes 6-7-8 : sum of squared input values
--------------------------------------------------------------------------------
-- case PCAP supports std_dev fpga_option
SUM_SQ_GEN_1 : if PCAP_STD_DEV_OPTION = '1' generate
begin

  -- Mode 6 / 7 / 8 : Sum^2 Low / Middle / High
  ps_sum_squared_val: process(clk_i)
  begin
    if rising_edge(clk_i) then

        -- Output the result
        if trig_r1 = '1' then
            -- Mode 6 Sum^2 byte 0
            sum_sq_0_o <= std_logic_vector(sum_data_sq(31+(to_integer(unsigned(SHIFT_SUM))) downto (to_integer(unsigned(SHIFT_SUM)))));
            -- Mode 7 Sum^2 byte 1
            sum_sq_1_o <= std_logic_vector(sum_data_sq(63+(to_integer(unsigned(SHIFT_SUM))) downto 32+(to_integer(unsigned(SHIFT_SUM)))));
            -- Mode 8 Sum^2 byte 2
            sum_sq_2_o <= std_logic_vector(sum_data_sq(95+(to_integer(unsigned(SHIFT_SUM))) downto 64+(to_integer(unsigned(SHIFT_SUM)))));
        end if;

        -- Clear sum on disable or trigger with no gate high
        if (enable_r1 = '0') or (trig_r1 = '1' and gate_r1 = '0') then
            sum_data_sq <= (others => '0');
        -- Set sum to current value on trigger with gate high
        elsif (trig_r1 = '1' and gate_r1 = '1') then
            sum_data_sq <= resize(value_sq_r1,sum_data_sq'length);
        -- Sum the received data whilst gate high
        elsif (gate_r1 = '1') then
            --sum_data_sq <= sum_data_sq + value_sq_r1;
            sum_data_sq <= sum_data_sq + resize(value_sq_r1,sum_data_sq'length);
        end if;
    end if;
  end process ps_sum_squared_val;
end generate;

-- case PCAP does not supports std_dev fpga_option
SUM_SQ_GEN_0 : if PCAP_STD_DEV_OPTION = '0' generate
begin
    sum_data_sq <= (others=>'0');
    sum_sq_0_o <= (others=>'0');
    sum_sq_1_o <= (others=>'0');
    sum_sq_2_o <= (others=>'0');
end generate;



-- Mode 4 - Min
-- Mode 5 - Max
ps_min_max: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Output the result
        if trig_r1 = '1' then
            min_o <= std_logic_vector(min_val);
            max_o <= std_logic_vector(max_val);
        end if;

        -- Clear min and max values on disable or trigger with no gate high
        if (enable_r1 = '0') or (trig_r1 = '1' and gate_r1 = '0') then
            min_val <= (min_val'high => '0', others => '1');
            max_val <= (max_val'high => '1', others => '0');
        -- Store current value on trigger with gate high
        elsif (trig_r1 = '1' and gate_r1 = '1') then
            min_val <= signed(value_r1);
            max_val <= signed(value_r1);
        elsif (gate_r1 = '1') then
            -- Capture the minimum number
            if signed(value_r1) < min_val then
                min_val <= signed(value_r1);
            end if;
            -- Capture the maximum number
            if signed(value_r1) > max_val then
                max_val <= signed(value_r1);
            end if;
        end if;
    end if;
end process ps_min_max;


end architecture rtl;
