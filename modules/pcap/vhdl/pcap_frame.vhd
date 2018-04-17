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
	CAPTURE_EDGE		: in  std_logic_vector(1 downto 0);
    -- Block input and outputs.
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    enable_i            : in  std_logic;
    gate_i              : in  std_logic;
    capture_i           : in  std_logic;
    timestamp_i         : in  std_logic_vector(63 downto 0);
	-- Captured data 
    capture_o           : out std_logic;
    mode_ts_bits        : out t_mode_ts_bits
);
end pcap_frame;

architecture rtl of pcap_frame is

signal gate_prev        : std_logic;
signal gate_rise        : std_logic;
signal gate_fall        : std_logic;
signal capture_dly      : std_logic;
signal timestamp        : unsigned(63 downto 0);

signal ts_start         : std_logic_vector(63 downto 0);
signal ts_start_dly		: std_logic_vector(63 downto 0);
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

signal capture_prev		: std_logic;
signal capture_rise		: std_logic;
signal capture_fall		: std_logic;
signal capture			: std_logic;
signal ts_start_enable	: std_logic;
signal ts_end_enable	: std_logic;


begin

-- Enable_i and Gate_i are level triggered 
-- Enable marks the start and end of entire acquisition
-- Gate used to accept or reject samples within a single capture from the acquistion
-- Capture is edge triggered with an option to trigger on rising, falling or both

ps_prev: process(clk_i)                                      
begin                                                               
    if rising_edge(clk_i) then                      
        capture_prev <= capture_i;                  
    end if;                                                         
end process ps_prev;                                                


capture_rise <= not capture_prev and capture_i;
capture_fall <= capture_prev and not capture_i;

-- Handle the trigger 
capture <= capture_rise when (capture_rise = '1' and (CAPTURE_EDGE = "00" or CAPTURE_EDGE = "10")) else
           capture_fall when (capture_fall = '1' and (CAPTURE_EDGE = "01" or CAPTURE_EDGE = "10")) else
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
            capture_dly <= '0';
            capture_o <= '0';
        -- Handle the delay in here as its is the delay of registering the 
        -- results pass out on the mode_ts_bits record     
        else                 
            capture_dly <= capture;   
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
        -- Capture the timestamp at the start of a capture frame
        if (enable_i = '0') then
			ts_start_enable <= '0';
			ts_start <= std_logic_vector(to_signed(-1,ts_start'length));
		-- Capture the timestamp this is the start of a frame		
		elsif (ts_start_enable = '0' and gate_rise = '1') then
			ts_start_enable <= '1';
			ts_start <= std_logic_vector(timestamp); 
		-- Capture the timestamp this is the start of a frame
		elsif (gate_i = '1' and capture = '1') then		
			ts_start_enable <= '1';			
			ts_start <= std_logic_vector(timestamp);
		-- End of a capture frame	
		elsif (capture = '1' and gate_i = '0') then			
			ts_start_enable <= '0';
			ts_start <= std_logic_vector(to_signed(-1,ts_start'length));
		end if;	
									
        -- Capture the timestamp at the end of a capture frame 
        if (enable_i = '0') then
			ts_end_enable <= '0';
            ts_end <= std_logic_vector(to_signed(-1,ts_end'length));
		-- Capture the timestamp at the end of the frame
		elsif (gate_fall = '1') then
			if (capture = '0') then
				ts_end_enable <= '1';
			end if;			
			ts_end <= std_logic_vector(timestamp);
		-- Capture the timestamp at the end of the frame	
		elsif (capture = '1' and gate_i = '1') then
			ts_end_enable <= '0';
			ts_end	<= std_logic_vector(timestamp);
		-- End of a capture frame
		elsif (capture = '1' and gate_i = '0') then
			ts_end_enable <= '0';			
			if (ts_end_enable = '0') then
				ts_end <= std_logic_vector(to_signed(-1,ts_end'length));
			end if;		
		end if;       

        -- Capture TIMESTAMP             
        if (enable_i = '0') then
            ts_capture <= (others => '0');
        elsif (capture = '1') then
            ts_capture <= std_logic_vector(timestamp);
        end if;
        
        -- Count the number of samples 			
        if (capture = '1' or enable_i = '0') then
			if (gate_i = '1' and enable_i = '1') then            
				cnt_samples <= to_unsigned(1,cnt_samples'length);	
			else
				cnt_samples <= (others => '0');
			end if;
            samples <= std_logic_vector(cnt_samples(31+(to_integer(unsigned(SHIFT_SUM))) downto (to_integer(unsigned(SHIFT_SUM)))));
        elsif (gate_i = '1') then
            cnt_samples <= cnt_samples +1;
        end if;    
         
        if (capture = '1') then
            bits0 <= sysbus_i(31 downto 0);
            bits1 <= sysbus_i(63 downto 32);
            bits2 <= sysbus_i(95 downto 64);
            bits3 <= sysbus_i(127 downto 96);                   
        end if;
    end if;
end process;


-------------------------------------------------------------------------- 
-- Instantiate pcap_frame_mode block
--------------------------------------------------------------------------
CAP_FRAME_GEN : for i in 31 downto 0 generate

pcap_frame_mode_inst : entity work.pcap_frame_mode
port map (
    clk_i        => clk_i,
    enable_i     => enable_i,   
    gate_i       => gate_i,   
    capture_i    => capture,
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
		-- Capture the start timestamp 
		ts_start_dly <= ts_start;
		if capture_dly = '1' then         
        	-- Cature mode data         
        	lp_mode_data: for i in 31 downto 0 loop
            	mode_ts_bits.mode(i)(0) <= value_o(i);
            	mode_ts_bits.mode(i)(1) <= diff_o(i);
            	mode_ts_bits.mode(i)(2) <= sum_l_o(i);
            	mode_ts_bits.mode(i)(3) <= sum_h_o(i);
            	mode_ts_bits.mode(i)(4) <= min_o(i);
            	mode_ts_bits.mode(i)(5) <= max_o(i);   
        	end loop lp_mode_data;
			-- Capture TimeStamp data
        	mode_ts_bits.ts(0) <= ts_start_dly(31 downto 0);
        	mode_ts_bits.ts(1) <= ts_start_dly(63 downto 32);   
        	mode_ts_bits.ts(2) <= ts_end(31 downto 0);
        	mode_ts_bits.ts(3) <= ts_end(63 downto 32);
        	mode_ts_bits.ts(4) <= ts_capture(31 downto 0);    
        	mode_ts_bits.ts(5) <= ts_capture(63 downto 32);
        	mode_ts_bits.ts(6) <= samples;
			-- Capture bit bus data
        	mode_ts_bits.bits(0) <= bits0;
        	mode_ts_bits.bits(1) <= bits1;
        	mode_ts_bits.bits(2) <= bits2;
        	mode_ts_bits.bits(3) <= bits3;                   
		end if;    
	end if;
end process ps_mode_ts_bits;                


end rtl;

