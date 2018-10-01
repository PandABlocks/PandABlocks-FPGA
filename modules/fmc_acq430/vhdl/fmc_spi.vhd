---------------------------------------------------------------------------------
--! @file
--! @brief SPI Interface to the ADC1278s on the ACQ430FMC Board
--! @author   John McLean
--! @date     2nd December 2013
--! @details														\n
--! D-TACQ Solutions Ltd Copyright 2013-2017		        		\n
--!   																\n

-- Standard Libraries - numeric.std for all designs
library ieee;
use ieee.std_logic_1164.all;	--! Standard Logic Functions
use ieee.numeric_std.all;		--! Numeric Functions for Signed / Unsigned Arithmetic

-- If using Xilinx primitives need the Xilinx library
library UNISIM;
use UNISIM.VComponents.all;		--! Xilinx Primitives

--!  ADC I/O Logic
entity ACQ430FMC_SPI is
	Generic(
	g_FMC_SITE				: integer := 0
	);
    Port (
	clk_SPI					: in    std_logic;					    --! SPI Clock for the ADCs is either 512 or 256 times the desired sample rate
	SAMPLING_STALLED		: in    std_logic;					    --! Reset State Machines while the ADCs are stalled
	ADC_FSYNC				: in    std_logic;					    --! Frame Sync defining the first data strobe
	ADC_SDO					: in	std_logic;					    --! Serial input data from 4 ADCs
	ADC_DATA_COMPLETE		: out   std_logic;					    --! Data shift finishing
	ADC_DATAOUT				: out   std_logic_vector(31 downto 0);	--! ADC Data converted to parallel format
	ADC_DATA_VALID			: out   std_logic					    --! Data valid for the 4 ADC devices
    );
end ACQ430FMC_SPI;

--! ADC I/O Logic
architecture RTL of ACQ430FMC_SPI is

COMPONENT FMC_ACQ430_SAMPLE_RAM
  PORT (
    a    : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
    d    : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
    dpra : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
    clk  : IN  STD_LOGIC;
    we   : IN  STD_LOGIC;
    qspo : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    qdpo : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
 END COMPONENT;

type STATE_V_WRITE_MAP_RAM is (
				WRITE_IDLE,			-- Idle State everything off
				WRITE_STARTING,		-- First of the 8 ADC banks
				LATCH_A,			-- Latch bank A
				WRITE_FINISHING		-- Last Write from 8th ADC
				);


signal WRITE_STATE		: 	STATE_V_WRITE_MAP_RAM;	--! RAM Write State Machine
signal NEXT_WRITE_STATE	: 	STATE_V_WRITE_MAP_RAM;	--! RAM Read State	Machine

type STATE_V_READ_MAP_RAM is (
				READ_IDLE,							-- Idle State wait for Write Complete
				READ_RAM,							-- Read RAM
				READ_FINISHING						-- Complete and wait for next Write Complete
				);


signal READ_STATE		: 	STATE_V_READ_MAP_RAM;	--! Output State
signal NEXT_READ_STATE	: 	STATE_V_READ_MAP_RAM;	--! Output State


--! \page ACQ430_Design Design Description
--! \section CHANNEL_MAPPING_DESC Channel Mapping Detail
--! \details
 --! Channel Mapping Raw
--!  Physical	| Remapped	| Readout
--!  ---       | ---          | ---
--! 1		| 7			| A7
--! 2		| 8			| A8
--! 3		| 5			| A5
--! 4		| 6			| A6
--! 5		| 3			| A3
--! 6		| 4			| A4
--! 7		| 1			| A1
--! 8		| 2			| A2

--! \n
--! \n
--! ReadBack order to RAM Address
--! Read Out	|  RAM Address
--! ---       	| ---
--! A1		|  6
--! A2		|  7
--! A3		|  4
--! A4		|  5
--! A5		|  2
--! A6		|  3
--! A7		|  0
--! A8		|  1
--! \n
--! \n
-----------------------------------------------------------------------------------------------------------------------------------------

--! The ROM provides a mapping of Readback order to Connector Pin Channel Definition and also a Read to Bank for reduced channel
type CHANNEL_MAPPING is array ( 0 to 7) of std_logic_vector(4 downto 0);
  constant CHANNEL_LUT : CHANNEL_MAPPING := (
    0  => "00110",		-- Write Address 6
    1  => "00111",		-- Write Address 7
    2  => "00100",		-- Write Address 4
    3  => "00101",		-- Write Address 5
    4  => "00010",		-- Write Address 2
    5  => "00011",		-- Write Address 3
    6  => "00000",		-- Write Address 0
    7  => "00001"		-- Write Address 1
     );


constant SHIFT_AMOUNT       : unsigned(4 downto 0) := "10111";		   --! Shift 24 bits of data from the ADCs
constant CHANNEL_COUNT      : unsigned(2 downto 0) := "111";		   --! 8 channels per ADC


signal SHIFT_REGISTER       : std_logic_vector(23 downto 0);		   --! Shift Register
signal READ_REGISTER        : std_logic_vector(23 downto 0);		   --! Buffer Register

signal SHIFT_COUNTER        : unsigned(4 downto 0) := (others => '0'); --! Count the number of bits shifted
signal SHIFT_COMPL          : std_logic;							   --! Shift Complete write into FIFO
signal RUN_SHIFT            : std_logic;							   --! Shift Counter shifting
signal CHANNEL_COUNTER      : unsigned(2 downto 0);					   --! Count the number of channels loaded


signal CHANNEL_RAM_WR_ADDR 	: std_logic_vector(4 downto 0);			   --! Write Address to the RAM
signal CHANNEL_RAM_WR_COUNT : unsigned(2 downto 0) := (others => '0'); --! Write Count to the RAM
signal CHANNEL_RAM_WREN	 	: std_logic;							   --! Write Enable
signal CHANNEL_RAM_DIN		: std_logic_vector(23 downto 0);		   --! Write Data to the RAM
signal CHANNEL_RAM_RD_ADDR 	: std_logic_vector(4 downto 0);			   --! Read Address to the RAM
signal CHANNEL_RAM_RD_COUNT : unsigned(4 downto 0);					   --! Read Count to the RAM


attribute mark_debug : string;
attribute keep : string;


begin

--! Count the 8 channels in each ADC device then wait for a new ADC_FSYNC
GENERATE_CHANNEL_COUNT: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
	    if (SAMPLING_STALLED = '1') then
	    	RUN_SHIFT <= '0';
	    elsif ADC_FSYNC = '1' then -- Start on arrival of ADC_FSYNC
	    	RUN_SHIFT <= '1';
	    elsif CHANNEL_COUNTER = CHANNEL_COUNT and SHIFT_COMPL = '1' then -- Stop when 8 channels have counted
	    	RUN_SHIFT <= '0';
	    end if;
	    if (SAMPLING_STALLED = '1') then
	    	CHANNEL_COUNTER <= (others => '0');
	    elsif ADC_FSYNC = '1' then
	    	CHANNEL_COUNTER <= (others => '0');
	    elsif SHIFT_COMPL = '1' then
	    	CHANNEL_COUNTER <= CHANNEL_COUNTER + 1;
	    end if;
    end if;
end process GENERATE_CHANNEL_COUNT;


--! Count 24 bits shifted into the register MSB first
GENERATE_SHIFT_COUNT: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
	    if (SAMPLING_STALLED = '1') then
	    	SHIFT_COUNTER <= (others => '0');
	    elsif SHIFT_COUNTER = SHIFT_AMOUNT or  RUN_SHIFT = '0' then
	    	SHIFT_COUNTER <= (others => '0');
	    elsif RUN_SHIFT = '1' then
	    	SHIFT_COUNTER <= SHIFT_COUNTER + 1;
	    end if;
	    if SHIFT_COUNTER = SHIFT_AMOUNT then --direct counter decode - pipeline if timing is an issue but should be safe
	    	SHIFT_COMPL <= '1';
	    else
	    	SHIFT_COMPL <= '0';
    	end if;
    end if;
end process GENERATE_SHIFT_COUNT;


--! Shift Register Logic
THE_SHIFT_REGISTER: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
	    SHIFT_REGISTER <=  SHIFT_REGISTER(22 downto 0) & ADC_SDO; -- Shift left the shift register
    end if;
end process THE_SHIFT_REGISTER;


--! Clock the ADC buses onto the buffers and perform the 2's complement conversion
CLOCK_ADC_BUS: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
	    if SHIFT_COMPL = '1' then -- latch the result of the shift registers
	    	READ_REGISTER <= SHIFT_REGISTER;
	    end if;
    end if;
end process CLOCK_ADC_BUS;


--! This process describes the state update on each clock transition
STATE_TRANSITION: process (clk_SPI)
begin
    if Rising_edge(clk_SPI) then
	    if (SAMPLING_STALLED = '1') then
	    	WRITE_STATE <= WRITE_IDLE;
	    	READ_STATE <= READ_IDLE;
	    else
	    	WRITE_STATE  <= NEXT_WRITE_STATE;
	    	READ_STATE  <= NEXT_READ_STATE;
	    end if;
    end if;
end process STATE_TRANSITION;


WRITE_STATE_MACHINE: process (WRITE_STATE,SHIFT_COMPL,RUN_SHIFT)
begin
    NEXT_WRITE_STATE <= WRITE_STATE;
    case WRITE_STATE is
	
	    when WRITE_IDLE =>
	    	if RUN_SHIFT = '1' then	-- start on first of 8 block
	    		NEXT_WRITE_STATE <= WRITE_STARTING;
	    	end if;
	
	    when WRITE_STARTING =>
	    	if SHIFT_COMPL = '1' then -- Dependant on SHIFT_COMPL only
	    		NEXT_WRITE_STATE <= LATCH_A;
	    	end if;
	
	    when LATCH_A =>
	    	if RUN_SHIFT = '0' then	-- is this the 8th ADC
	    		NEXT_WRITE_STATE <= WRITE_FINISHING;
	    	else
	    		NEXT_WRITE_STATE <= WRITE_STARTING;
	    	end if;
	
	    when WRITE_FINISHING =>
	    	NEXT_WRITE_STATE <= WRITE_IDLE;
    end case;
end process WRITE_STATE_MACHINE;


-- Generate the controls to the RAM
--GEN_WRITE_ADDRESS: process(clk_SPI,WRITE_STATE,CHANNEL_RAM_WR_COUNT)
GEN_WRITE_ADDRESS: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
	    if WRITE_STATE = WRITE_IDLE then
	    	CHANNEL_RAM_WR_COUNT <= (others => '0');
	    elsif  WRITE_STATE = LATCH_A  then
	    	CHANNEL_RAM_WR_COUNT <= CHANNEL_RAM_WR_COUNT + 1;
	    end if;
	    if  WRITE_STATE = LATCH_A  then
	    	CHANNEL_RAM_WREN <= '1';
	    else
	    	CHANNEL_RAM_WREN <= '0';
	    end if;
	    if WRITE_STATE = LATCH_A then
	    	CHANNEL_RAM_DIN <= READ_REGISTER;
	    else
	    	CHANNEL_RAM_DIN <= READ_REGISTER; -- start and finish on A
	    end if;
	    CHANNEL_RAM_WR_ADDR <= 	CHANNEL_LUT(to_integer(CHANNEL_RAM_WR_COUNT)); -- magical channel munge lookup
    end if;
end process GEN_WRITE_ADDRESS;


THESAMPLE_RAM :  FMC_ACQ430_SAMPLE_RAM
port map(
	a	 =>	CHANNEL_RAM_WR_ADDR,
	d	 =>	CHANNEL_RAM_DIN,
	dpra =>	CHANNEL_RAM_RD_ADDR,
	clk	 =>	clk_SPI,
	we	 =>	CHANNEL_RAM_WREN,
	qdpo =>	ADC_DATAOUT(31 downto 8)
);


READ_STATE_MACHINE: process (READ_STATE,WRITE_STATE,CHANNEL_RAM_RD_COUNT)
begin
    NEXT_READ_STATE <= READ_STATE;
    case READ_STATE is
	
	    when READ_IDLE =>
	    	if WRITE_STATE = WRITE_FINISHING then				-- start on first of 8 block
	    		NEXT_READ_STATE <= READ_RAM;
	    	end if;
	
	    when READ_RAM =>
	    	if CHANNEL_RAM_RD_COUNT = "00111" then				-- 8 channels read
	    		NEXT_READ_STATE <= READ_FINISHING;
	    	end if;
	
	    when READ_FINISHING =>
			NEXT_READ_STATE <= READ_IDLE;
    end case;
end process READ_STATE_MACHINE;

-- Generate the controls to the RAM
GEN_READ_ADDRESS: process(clk_SPI,READ_STATE,CHANNEL_RAM_RD_COUNT)
begin
    if Rising_edge(clk_SPI) then
	    if READ_STATE = READ_IDLE then
	    	CHANNEL_RAM_RD_COUNT <= (others => '0');
	    elsif  READ_STATE = READ_RAM then
	    	CHANNEL_RAM_RD_COUNT <= CHANNEL_RAM_RD_COUNT + 1;		-- 1 clock read pipeline remember to check the RAM IP !!!!
	    end if;
	    if READ_STATE = READ_RAM then
	    	ADC_DATA_VALID <= '1';
    	else
    		ADC_DATA_VALID <= '0';
	    end if;
	    if READ_STATE = READ_FINISHING then
	    	ADC_DATA_COMPLETE <= '1';
	    else
	    	ADC_DATA_COMPLETE <= '0';
	    end if;
    end if;
    CHANNEL_RAM_RD_ADDR <= 	std_logic_vector(CHANNEL_RAM_RD_COUNT);
end process GEN_READ_ADDRESS;


ADC_DATAOUT(7 downto 0) <= std_logic_vector(to_unsigned(g_FMC_SITE,3)) & std_logic_vector(CHANNEL_RAM_RD_COUNT -1);


end RTL;
