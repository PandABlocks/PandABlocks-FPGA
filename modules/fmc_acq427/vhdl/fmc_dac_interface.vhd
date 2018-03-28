---------------------------------------------------------------------------------------
--! @file
--! @brief    ACQ427FMC Module Address Decode and Control - PandA
--! @author   John McLean, Scott Robson
--! @date     10th May 2016
--! @details															\n
--! D-TACQ Solutions Ltd Copyright 2013-2018					 		 		\n
--!   																\n

--! Standard Libraries - numeric.std for all designs
library ieee;
use ieee.std_logic_1164.all;		--! Standard Logic Functions
use ieee.numeric_std.all;		--! Numeric Functions for Signed / Unsigned Arithmetic

--! If using Xilinx primitives need the Xilinx library
library UNISIM;
use UNISIM.VComponents.all;		--! Xilinx Primitives

--! Local Functions and Types
use work.ACQ427TYPES.all; 		--! Local Types

Entity ACQ427FMC_DAC_INTERFACE is
Port(
	clk_PANDA					: in		std_logic;							--! 125 MHz clock from Zynq core
-- Connections to PandA registers
	DAC_CLKDIV_REG				: in std_logic_vector(31 downto 0);
	DAC_FIFO_RESET_REG				: in std_logic_vector(31 downto 0);
	DAC_FIFO_ENABLE_REG			: in std_logic_vector(31 downto 0);
	DAC_RESET_REG				: in std_logic_vector(31 downto 0);
	DAC_ENABLE_REG				: in std_logic_vector(31 downto 0);
-- I/Os to DACs
	clk_DAC_IOB				: out   std_logic;								--! DAC SPI Clk for IOBs
	DAC_SPI_CLK				: out   std_logic;								--! DAC SPI Clock
	DAC_SDI					: out   std_logic_vector( 4 downto 1);				--! DAC SPI Data In
	DAC_SDO					: in    std_logic_vector( 4 downto 1);				--! DAC SPI Data Out
	DAC_SYNC_n				: out   std_logic;								--! DAC SPI SYNC
	DAC_LD_n					: out   std_logic;								--! DAC Load
	DAC_RST_n					: out   std_logic;								--! DAC Reset

	DAC_DATAIN				: in    std_logic_vector(127 downto 0)
	);
end ACQ427FMC_DAC_INTERFACE;


architecture RTL of ACQ427FMC_DAC_INTERFACE is

component fmc_acq427_dac_fifo IS
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    rd_data_count : out STD_LOGIC_VECTOR (5 downto 0 );
    wr_data_count : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
end component;

--*************************************************************************************************************************
-- PandA_clk Domain signals
--*************************************************************************************************************************

signal FIFO_DATAOUT					: std_logic_vector(31 downto 0)	:= (others => '0');		--! FIFO data to AXI_DATA_ENGINE
signal FIFO_FULL					: std_logic					:= '0';				--! FIFO FULL		signal:	to	REGISTERS
signal FIFO_EMPTY					: std_logic					:= '0';				--! FIFO EMPTY		signal:	to	REGISTERS
signal DACCLK_FIFO_EMPTY				: std_logic					:= '0';				--! FIFO FULL		signal on the IP is in the Write Clock Domain

signal FIFO_WR_DATA					: std_logic_vector(127 downto 0);						--! FIFO Write Data from AXI or SidePort
signal FIFO_WR_EN					: std_logic					:= '0';				--! FIFO Write control

signal DIV_CLK_d0					: std_logic					:= '0';				--! DIV_CLK De-bounced in the 66 MHz Domain
signal DIV_CLK_RISING				: std_logic					:= '0';				--! DIV_CLK Rising Edge in the 66 MHz Domain

signal DAC_FIFO_WR_COUNT				: std_logic_vector(3 downto 0)	:= (others => '0');		--! DAC FIFO WR Count


--*************************************************************************************************************************
-- DAC_clk Domain
--*************************************************************************************************************************

signal DAC_FIFO_ENABLE					: std_logic					:= '0';
signal DAC_FIFO_RESET					: std_logic					:= '0';
signal DAC_FIFO_RD_COUNT					: std_logic_vector(5 downto 0)	:= (others => '0');		--! DAC FIFO RD Count
signal DACCLK_FIFO_AVAIL					: std_logic;										--! There is a sample of data in the FIFO

signal DIV_CLK							: std_logic;										--! Divided Down Clock for Asynchronous Logic
signal DIV_CLK_SEL						: std_logic;										--! Select between Divided Down Clock and input clock for the special case of divide by 1

--signal HW_CLK_EN						: std_logic;										--! External Clock Enable
--signal HW_CLK							: std_logic;										--! External Clock

signal CONV_ACTIVE						: std_logic;										--! Conversion Active - Enabled

signal DAC_DATA_RD						: std_logic					:= '0';				--! FIFO Read from the DAC Logic
signal DAC_RESET						: std_logic					:= '0';				--! Reset the DAC logic
signal DAC_RESET_d0						: std_logic					:= '0';				--!
signal DAC_RESET_FALLING					: std_logic					:= '0';				--!
signal DAC_RESET_FALLING_d0				: std_logic					:= '0';				--!
signal DAC_RESET_FALLING_d1				: std_logic					:= '0';				--!
signal DAC_RESET_FALLING_d2				: std_logic					:= '0';				--!
signal DAC_RESET_FALLING_STRETCH			: std_logic					:= '0';				--!
signal CLK_SEL_DAC_RESET					: std_logic					:= '0';				--! Reset the DAC logic
signal DAC_ENABLE						: std_logic					:= '0';				--! Combination of ALG Enable and ICS_OE_CLK_s
signal DATA_SIZE						: std_logic;										--! Pack data in 32/16 bits
signal DAC_CLK_DIV						: std_logic_vector(15 downto 0)	:= (others => '0');		--! Clock Divider to generate DAC Sample Clock

signal CLOCK_EST_COUNTER					: unsigned(27 downto 0)			:= (others => '0');		--! Clock Speed Counter Counter
signal CLOCK_EST_COUNTER_LATCH			: std_logic_vector(27 downto 0)	:= (others => '0');		--! Clock Speed Counter Counter Latched
signal CLOCK_EST_THECLK_IN				: std_logic;										--! Clock Speed Counter Clock
signal CLOCK_EST_d0						: std_logic;										--! Clock Speed Estimator Clock debounced against the 100M Clock
signal CLOCK_EST_d1						: std_logic;										--! Clock Speed Estimator Clock debounced against the 100M Clock

signal SAMPLE_COUNTER					: unsigned(31 downto 0)			:= (others => '0');		--! Samples since Trigger Counter
signal SAMPLE_COUNTER_LATCH				: std_logic_vector(31 downto 0)	:= (others => '0');		--! Samples since Trigger Counter

signal clk_SPI							: std_logic;										--! SPI Clock to shifting logic

signal CONTROL_WRITE					: std_logic;										--! Write Control Data
signal CONTROL_WRITE_COMPL				: std_logic;										--! Write Control Data Complete
signal SPI_CONTROL_DATA					: std_logic_vector(23 downto 0);						--! DAC Control Register Write Data
signal CONTROL_READ						: std_logic;										--! Read Control Data
signal DACCLK_CONTROL_READ				: std_logic;										--! Read Control Data
signal CONTROL_READ_COMPL				: std_logic;										--! Write Control Data Complete
signal CONTROL_READBACK					: std_logic_vector(23 downto 0);						--! DAC Control Register ReadBack

signal s_CLK_GEN_CLK					: std_logic;										--! Generated Clock for the DACs
signal CLKDIV_COUNTER					: std_logic_vector  (15 downto 0);						--! Divide the Selected Clock for use as the Internal Sample Clock
signal CLKDIV_COUNTER_RESET				: std_logic;										--! Reset the Counter
signal DIVIDE2							: std_logic_vector  (15 downto 0);						--! Divide by 2 calculation to get close to 50/50 duty cycle

signal clk_62_5M						: std_logic;
signal clk_62_5M_raw					: std_logic;

signal DAC_INIT_COUNTER					:unsigned(10 downto 0);								--! Counter to space SPI DAC Init writes in time


type DAC_SPI_INIT_STATE_V is (
				IDLE,		-- Idle State
				WAIT0,		-- Wait for Write Complete
				CW1,			-- Write 1st Control Word to DACs
				WAIT1,		-- Wait for Write Complete
				CW2,			-- Write 2nd Control Word to DACs
				WAIT2,		-- Wait for Write Complete
				CW3			-- Write 3rd Control Word to DACs and stall until reset
				);

signal CONTROL_STATE,NEXT_CONTROL_STATE	: DAC_SPI_INIT_STATE_V;	--! DAC SPI Init State Machine


--------------------------------------------------------------------------------------
-- debug test using mark_debug
---------------------------------------------------------------------------------------
attribute mark_debug : string;
attribute keep : string;

--attribute mark_debug of DAC_FIFO_RESET 			: signal is "true";

begin

--*************************************************************************************************************************
-- Clock Domain Crossing  clk_PANDA and clk_62_5M
--*************************************************************************************************************************
Cross_Clock_Buffer_AXI : Process(clk_PANDA)
begin
	if Rising_Edge(clk_PANDA) then
		FIFO_EMPTY	<=	DACCLK_FIFO_EMPTY;
	end if;
end process Cross_Clock_Buffer_AXI;

--! DAC Buffer FIFO using Xilinx IP Module  to move between DAC Clock Domain and PandA Clock Domain		generate this based on the ADC one
--FAST_DAC_MEMORY : entity work.DAC_FIFO
FAST_DAC_MEMORY :  fmc_acq427_dac_fifo
	port map(
	rst				=>	DAC_FIFO_RESET,
	full					=>	FIFO_FULL,
	empty				=>	DACCLK_FIFO_EMPTY,
	wr_clk				=>	clk_PANDA,
	din					=>	FIFO_WR_DATA,
	wr_en				=>	FIFO_WR_EN,
	rd_clk				=>	clk_62_5M,
	rd_en				=>	DAC_DATA_RD  and DAC_FIFO_ENABLE,
	dout					=>	FIFO_DATAOUT,
	rd_data_count			=>	DAC_FIFO_RD_COUNT,
	wr_data_count			=>	DAC_FIFO_WR_COUNT
	);

PCAP_WRITE_FIFO : process(clk_PANDA)
begin
if rising_edge(clk_PANDA) then
	if unsigned(DAC_FIFO_WR_COUNT) < 1 then
		FIFO_WR_EN <= '1';
	else
		FIFO_WR_EN <= '0';
	end if;
end if;
end process;

FIFO_WR_DATA	<= DAC_DATAIN;


--! Process to adjust the High Tide count depending on Data Packing
SAMPLE_IN_DATA_FIFO: process(DATA_SIZE,DAC_FIFO_RD_COUNT,DACCLK_FIFO_EMPTY)
begin
if DATA_SIZE = '0' then				-- packed 2 counts per sample
	if unsigned(DAC_FIFO_RD_COUNT) > 1 and DACCLK_FIFO_EMPTY = '0' then
		DACCLK_FIFO_AVAIL <= '1';
	else
		DACCLK_FIFO_AVAIL <= '0';
	end if;
else								-- unpacked 4 counts per sample
	if unsigned(DAC_FIFO_RD_COUNT) > 3 and DACCLK_FIFO_EMPTY = '0' then
		DACCLK_FIFO_AVAIL <= '1';
	else
		DACCLK_FIFO_AVAIL <= '0';
	end if;
end if;
end process SAMPLE_IN_DATA_FIFO;


--! This process is used to cross from the PandA to the DAC Clock domains for register bits that are required in the other domain.
Cross_Clock_Buffer : Process(clk_62_5M)
begin

	if Rising_Edge(clk_62_5M) then
		DAC_CLK_DIV         <= DAC_CLKDIV_REG(15 downto 0);
		DAC_ENABLE          <= DAC_ENABLE_REG(0);
	end if;
end process;

-- Decode of Register Control bits
DAC_RESET           <= DAC_RESET_REG(0);
DAC_FIFO_ENABLE     <= DAC_FIFO_ENABLE_REG(0);
DAC_FIFO_RESET      <= DAC_FIFO_RESET_REG(0);

DATA_SIZE			<= '1'; --Always unpacked for DLS

-- Detect Rising Edge of RESET
RESET_RISING_DETECT : process(clk_PANDA)
begin
if rising_edge(clk_PANDA) then
	DAC_RESET_d0 <= DAC_RESET;
	if DAC_RESET = '0' and DAC_RESET_d0 = '1' then
		DAC_RESET_FALLING <= '1';
	else
		DAC_RESET_FALLING <= '0';
	end if;
	DAC_RESET_FALLING_d0 <= DAC_RESET_FALLING;
	DAC_RESET_FALLING_d1 <= DAC_RESET_FALLING_d0;
	DAC_RESET_FALLING_d2 <= DAC_RESET_FALLING_d1;
end if;
end process RESET_RISING_DETECT;

DAC_RESET_FALLING_STRETCH <= DAC_RESET_FALLING or DAC_RESET_FALLING_d0 or DAC_RESET_FALLING_d1 or DAC_RESET_FALLING_d2;


-- Deal with DAC SPI Initialisation in HW

--! This process describes the state update on each clock transition
process (clk_62_5M)
begin
if Rising_edge(clk_62_5M) then
	CONTROL_STATE  	<= NEXT_CONTROL_STATE;
end if;
end process ;

GENERATE_DAC_INIT_COUNT : process (clk_62_5M)
begin
if Rising_edge(clk_62_5M) then
	if CONTROL_STATE = WAIT0 or CONTROL_STATE = WAIT1 or CONTROL_STATE = WAIT2 then
		DAC_INIT_COUNTER <= DAC_INIT_COUNTER - 1;
	else
		DAC_INIT_COUNTER <= "11111111111";
	end if;
end if;
end process GENERATE_DAC_INIT_COUNT;

DAC_SPI_INIT_STATE_MACHINE: process (CONTROL_STATE,DAC_ENABLE,DAC_RESET,DAC_RESET_FALLING_STRETCH,CONTROL_WRITE_COMPL,DAC_INIT_COUNTER)
begin
NEXT_CONTROL_STATE <= CONTROL_STATE;
case CONTROL_STATE is
	when IDLE =>
		if  DAC_ENABLE = '0' and DAC_RESET_FALLING_STRETCH = '1' then		-- Start the Sequence when DACs come out of reset
			NEXT_CONTROL_STATE <= WAIT0;
		end if;
	when WAIT0 =>
		if DAC_INIT_COUNTER = 0 then
			NEXT_CONTROL_STATE <= CW1;
		end if;
	when CW1 =>
		if CONTROL_WRITE_COMPL = '1' then
			NEXT_CONTROL_STATE <= WAIT1;
		end if;
	when WAIT1 =>
		if DAC_INIT_COUNTER = 0 then
			NEXT_CONTROL_STATE <= CW2;
		end if;
	when CW2 =>
		if CONTROL_WRITE_COMPL = '1' then
			NEXT_CONTROL_STATE <= WAIT2;
		end if;
	when WAIT2 =>
		if DAC_INIT_COUNTER = 0 then
			NEXT_CONTROL_STATE <= CW3;
		end if;
	when CW3 =>
		if DAC_RESET = '1' then
			NEXT_CONTROL_STATE <= IDLE;
		end if;
	end case;
end process DAC_SPI_INIT_STATE_MACHINE;

DAC_SPI_INIT_OUTPUTS : process (clk_62_5M)
begin
if Rising_edge(clk_62_5M) then
	case CONTROL_STATE is
		when IDLE =>
			CONTROL_WRITE <= '0';
			SPI_CONTROL_DATA <= x"000000";
		when WAIT0 =>
			CONTROL_WRITE <= '0';
			SPI_CONTROL_DATA <= x"300000";
		when CW1 =>
			CONTROL_WRITE <= '1';
			SPI_CONTROL_DATA <= x"300000";
		when WAIT1 =>
			CONTROL_WRITE <= '0';
			SPI_CONTROL_DATA <= x"400002";
		when CW2 =>
			CONTROL_WRITE <= '1';
			SPI_CONTROL_DATA <= x"400002";
		when WAIT2 =>
			CONTROL_WRITE <= '0';
			SPI_CONTROL_DATA <= x"200000";
		when CW3 =>
			CONTROL_WRITE <= '1';
			SPI_CONTROL_DATA <= x"200000";
	end case;
end if;
end process DAC_SPI_INIT_OUTPUTS;


--*************************************************************************************************************************
-- clk_62_5M Domain
--*************************************************************************************************************************

--! Sync the DAC_RESET to the selected Clock
DAC_RESET_RESYNC: process(clk_62_5M,DAC_RESET)
begin
if Rising_edge(clk_62_5M) then
	CLK_SEL_DAC_RESET	<= DAC_RESET;
end if;
end process DAC_RESET_RESYNC;

-- OK a Key part here is that the Sync MUST be synchronous with the selected divider clock so in theory no need to sync it it's a don't care for the Internal Reset
CLKDIV_COUNTER_RESET <= '1' when CLK_SEL_DAC_RESET = '1' else '0';


--! This Process Described the Main Divider
MAINDIV: process (clk_62_5M,CLKDIV_COUNTER_RESET,DAC_CLK_DIV,CLKDIV_COUNTER,DIVIDE2)
begin
DIVIDE2 <=  std_logic_vector(unsigned('0' & DAC_CLK_DIV(15 downto 1)) + 1);
	if Rising_edge(clk_62_5M) then
		if CLKDIV_COUNTER_RESET = '1' then
			CLKDIV_COUNTER <= DAC_CLK_DIV;
		elsif CLKDIV_COUNTER = X"0001" then
			CLKDIV_COUNTER <= DAC_CLK_DIV;				-- Normal Reload
		else
			CLKDIV_COUNTER <= std_logic_vector(unsigned(CLKDIV_COUNTER) - 1);      -- Count Down
		end if;
	end if;
end process MAINDIV;

--! This Process describes the clock output
CLKOUTPUT: process (clk_62_5M,CLKDIV_COUNTER_RESET,s_CLK_GEN_CLK,CLKDIV_COUNTER,DIVIDE2)
begin
if Rising_edge(clk_62_5M) then
	if CLKDIV_COUNTER_RESET = '1' then
		s_CLK_GEN_CLK <= '0';
	elsif CLKDIV_COUNTER = DIVIDE2   then
		s_CLK_GEN_CLK <= '0';
	elsif CLKDIV_COUNTER = X"0001" then
		s_CLK_GEN_CLK <= '1';
	end if;
end if;
end process CLKOUTPUT;


--! This process controls the bypass should the divider be set to 0
BYPASS_DIVIDER: process(DAC_CLK_DIV,clk_62_5M,s_CLK_GEN_CLK)
begin
if DAC_CLK_DIV = x"0001" then
	DIV_CLK <= clk_62_5M;
	DIV_CLK_SEL <= '0';
else
	DIV_CLK <= s_CLK_GEN_CLK;
	DIV_CLK_SEL <= '1';

end if;
end process BYPASS_DIVIDER;

CLOCK_EST_THECLK_IN <= DIV_CLK;


-- Detect the rising edge of the Sample Clock to synchronise all counters too
CLK_DIV_RISING_EDGE: process(clk_62_5M,DIV_CLK_d0,DIV_CLK)
begin
if Rising_edge(clk_62_5M) then
	DIV_CLK_d0	<= DIV_CLK;
end if;
if DIV_CLK = '1' and DIV_CLK_d0 = '0' then
	DIV_CLK_RISING <= '1';
else
	DIV_CLK_RISING <= '0';
end if;
end process CLK_DIV_RISING_EDGE;


--! Set CONV_ACTIVE the main control for writing into the data FIFO
SET_CON_ACTIVE: process(clk_62_5M)
begin
if Rising_edge(clk_62_5M) then
	if DIV_CLK_RISING = '1' then
		if DAC_ENABLE = '1' then
			CONV_ACTIVE <= '1';
		else
			CONV_ACTIVE <= '0';
		end if;
	end if;
end if;
end process SET_CON_ACTIVE;

--! Simple Counter that allows the software to Estimate a Clock Frequency
THE_CLOCK_ESTIMATOR: process(clk_62_5M,CLOCK_EST_COUNTER)
begin
if Rising_edge(clk_62_5M) then
	CLOCK_EST_d1 <=  CLOCK_EST_d0;
	CLOCK_EST_d0 <=  CLOCK_EST_THECLK_IN;
	if CLOCK_EST_D0 = '1' and CLOCK_EST_D1 = '0' then
		CLOCK_EST_COUNTER <= CLOCK_EST_COUNTER + 1;
	end if;
end if;
end process THE_CLOCK_ESTIMATOR;


--! Simple Counter that counts the number of Samples acquired since CONV_ACTIVE
THE_SAMPLE_COUNTER: process(clk_62_5M,CONV_ACTIVE,SAMPLE_COUNTER)
begin
if Rising_edge(clk_62_5M) then
	if DIV_CLK_RISING = '1' then
		if CONV_ACTIVE = '0'  then
			SAMPLE_COUNTER <= (others => '0');
		else
			SAMPLE_COUNTER <= SAMPLE_COUNTER + 1;
		end if;
	end if;
end if;
end process THE_SAMPLE_COUNTER;


--************************************************************************************************************************
-- Clock Domain Crossing  clk_PANDA for read back
--*************************************************************************************************************************

--! De-bounce the counters against the PandA clock to ensure no meta-stable bits in the software read
DEBOUNCE_THE_COUNTER: process(clk_PANDA,CLOCK_EST_COUNTER,SAMPLE_COUNTER)
begin
if Rising_edge(clk_PANDA) then
	CLOCK_EST_COUNTER_LATCH <= std_logic_vector(CLOCK_EST_COUNTER);
	SAMPLE_COUNTER_LATCH <= std_logic_vector(SAMPLE_COUNTER);
end if;
end process DEBOUNCE_THE_COUNTER;

-- Half PandA clock to derive D-TACQ standard comparable logic clock rate. This is then halfed again at the SPI level to produce DAC SPI Clock
HALFPANDA_CLK : process (clk_PANDA)
begin
if Rising_edge(clk_PANDA) then
	clk_62_5M_raw <= not clk_62_5M_raw;
end if;
end process HALFPANDA_CLK;

SEL_CLK_SEL : BUFG
	port map (
		O 	=> clk_62_5M,
		I 	=> clk_62_5M_raw);

clk_DAC_IOB <= clk_62_5M;

--! DAC SPI Logic
THE_AO420FMC : entity work.ACQ427FMC_DAC_SPI(RTL)
	port map (
	clk_SPI				=> clk_62_5M,					--! 62.5 MHz source clock to be used as SPI Clock for the DACs
	DAC_RESET  			=> DAC_RESET,					--! Reset the DACs to their Power on State
	DATA_SIZE	 			=> DATA_SIZE,					--! Pack data in 32/16 bits
	FIFO_AVAIL 			=> DACCLK_FIFO_AVAIL,			--! Data Available in the FIFO
	DAC_ENABLE 			=> DAC_ENABLE,					--! Enable the DAC Sub-System
	CONV_ACTIVE 			=> CONV_ACTIVE,				--! Enable and Triggered of the DAC Sub-System
	LOW_LATENCY 			=> '0',						--! Low Latency do not wait for Sample Clock
	FIFO_DATAOUT 			=> FIFO_DATAOUT,				--! DAC Data From FIFO
	DAC_DATA_RD 			=> DAC_DATA_RD,				--! DAC Read Next Sample From FIFO
	DAC_CNV_CLK 			=> DIV_CLK,					--! DAC Convert Clock
	CONTROL_WRITE			=> CONTROL_WRITE,				--! Write Control Data
	CONTROL_WRITE_COMPL		=> CONTROL_WRITE_COMPL,			--! Write Control Data Complete
	SPI_CONTROL_DATA		=> SPI_CONTROL_DATA,			--! DAC Control Register Write Data
	CONTROL_READ			=> DACCLK_CONTROL_READ,			--! Read Control Data
	CONTROL_READ_COMPL		=> CONTROL_READ_COMPL,			--! Write Control Data Complete
	CONTROL_READBACK  		=> CONTROL_READBACK,			--! DAC Control Register ReadBack
-- I/Os to DACs
	DAC_SPI_CLK 			=> DAC_SPI_CLK,				--! DAC SPI Clock
	DAC_SDI 				=> DAC_SDI,					--! DAC SPI Data In
	DAC_SDO				=> DAC_SDO,					--! DAC SPI Data Out
	DAC_SYNC_n 			=> DAC_SYNC_n,					--! DAC SPI SYNC
	DAC_LD_n 				=> DAC_LD_n,					--! DAC Load
	DAC_RST_n	 			=> DAC_RST_n					--! DAC Reset
	);
end RTL;
