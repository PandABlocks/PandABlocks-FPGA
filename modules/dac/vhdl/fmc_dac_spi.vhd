---------------------------------------------------------------------------------
--! @file
--! @brief I/O Interface to the ACQ427 DAC Module
--! @author   John McLean
--! @date     8th September 2013
--! @details                                                        \n
--! D-TACQ Solutions Ltd Copyright 2013-18                          \n
--!                                                                 \n
--!
--! Important Design consideration - the incoming State Clock is assumed to be 62.5 MHz. This allows the DACs to be updated at close to their
--! maximum updated rate and allows the system to update at a rate of > 1 MHz - max is 31.25/30 = 1.04 MHz. \n
--! The SPI logic consists of three state machines, The Reset Machine runs as a one shot, it pulses the reset pin on the DACs then
--! initiates a write to the Control Registers on the DACs to set the correct operational mode. \n
--! The two other machines are interlinked and govern the reading of the FIFO for the data and the loading of the data into the DACs. \n
--! They pipeline off each other, the FIFO fetch routine starts when enabled assuming the Reset Machine has completed. It reads the first sample from the
--! FIFO then waits for the Load Machine to complete the loading into the DACs. This allows the machine to pipeline the next FIFO read immediately upon completion
--! of the shift allowing the DAC update to happen in parallel maximising the update rate of the design. \n
--! \n\n
--! Control Register Settings
--! DB23 | DB22 | DB21 | DB20 | DB19 to DB11 | DB10      | DB9 | DB8 | DB7 | DB6 | DB5    | DB4     | DB3    | DB2  | DB1  | DB0      |
--! ---  |  --- |  --- | ---  |  ---         |  ---      | --- | --- | --- | --- | ---    | ---     | ---    | ---  | ---  | ---      |
--! R/W  |   0  |  1   |  0   |  Reserved    | Reserved  |  0  |  0  |  0  |  0  | SDODIS | Bin/2sC | DACTRI | OPGND| RBUF | Reserved |
--!  0   |   0  |  1   |  0   |  00000000    |    0      |  0  |  0  |  0  |  0  |   0    | 0       |   0    |  0   |  0   | Reserved |
--! \n\n
--! The field detail is as per the table below \n
--! Field   | Value  |  Description
--! ---     | ---    |  ---
--! SDODIS  | 0      | SDO enabled
--! Bin/2sC | 0      | 2's Complement Data
--! DACTRI  | 0      | DAC Tri-State off DAC operating Normally
--! OPGND   | 0      | Output Ground Clamp Removed
--! RBUF    | 0      | Gain of 2 config for Bi-polar operation


-- Standard Libraries - numeric.std for all designs
library ieee;
use ieee.std_logic_1164.all;    --! Standard Logic Functions
use ieee.numeric_std.all;       --! Numeric Functions for Signed / Unsigned Arithmetic

-- If using Xilinx primitives need the Xilinx library
library UNISIM;
use UNISIM.VComponents.all;     --! Xilinx Primitives

--! Local Functions and Types
use work.ACQ427TYPES.all;       --! Local Types

--! @brief I/O Interface to the AO420FMC Board
entity ACQ427FMC_DAC_SPI is
    port (
    clk_SPI             : in  std_logic;                     --! 66 MHz source clock to be used as the source for the SPI Clock for the DACs
    DAC_RESET           : in  std_logic;                     --! Reset the DACs to their Power on State
    DATA_SIZE           : in  std_logic;                     --! Pack data in 32/16 bits
    FIFO_AVAIL          : in  std_logic;                     --! Data Available in the FIFO
    DAC_ENABLE          : in  std_logic;                     --! Enable the DAC Sub-System
    CONV_ACTIVE         : in  std_logic;                     --! Enable and Triggered of the DAC Sub-System
    LOW_LATENCY         : in  std_logic;                     --! Low Latency do not wait for Sample Clock
    FIFO_DATAOUT        : in  std_logic_vector(31 downto 0); --! DAC Data From FIFO
    DAC_DATA_RD         : out std_logic;                     --! DAC Read Next Sample From FIFO
    DAC_CNV_CLK         : in  std_logic;                     --! DAC Convert Clock
    CONTROL_WRITE       : in  std_logic;                     --! Write Control Data
    CONTROL_WRITE_COMPL : out std_logic;                     --! Write Control Data Complete
    SPI_CONTROL_DATA    : in  std_logic_vector(23 downto 0); --! DAC Control Register Write Data
    CONTROL_READ        : in  std_logic;                     --! Read Control Data
    CONTROL_READ_COMPL  : out std_logic;                     --! Write Control Data Complete
    CONTROL_READBACK    : out std_logic_vector(23 downto 0); --! DAC Control Register ReadBack
-- I/Os to DACs
    DAC_SPI_CLK         : out std_logic;                     --! DAC SPI Clock
    DAC_SDI             : out std_logic_vector( 4 downto 1); --! DAC SPI Data In
    DAC_SDO             : in  std_logic_vector( 4 downto 1); --! DAC SPI Data Out
    DAC_SYNC_n          : out std_logic;                     --! DAC SPI SYNC
    DAC_LD_n            : out std_logic;                     --! DAC Load
    DAC_RST_n           : out std_logic                      --! DAC Reset
    );
end ACQ427FMC_DAC_SPI;

--! @brief I/O Interface to the AO420FMC Board for the ACQ400 System
architecture RTL of ACQ427FMC_DAC_SPI is

constant  c_CONTROL_REGISTER_SETUP  : std_logic_vector (23 downto 0)    := x"200000"; -- deprecated now programmable
constant  c_CONTROL_REGISTER_READ   : std_logic_vector (23 downto 0)    := x"a00000"; -- deprecated need to slow down clk_SPI to use read back

constant SHIFT_LENGTH               : unsigned (4 downto 0)             := "10111";

constant GAIN_VALUE                 : std_logic_vector (15 downto 0)    := x"7FFF";

type CONTROL_STATE_V is (
                CONTROL_IDLE,           -- Idle State Reset
                INIT_CNRL_READ,         -- Kick off the Control Register ReadBack               -- deprecated need to slow down clk_SPI to use read back
                WAIT_READ_CMD,          -- Wait for the Control Register Command to Complete    -- deprecated need to slow down clk_SPI to use read back
                INIT_CNRL_DATA,         -- Kick off the Control Data ReadBack                   -- deprecated need to slow down clk_SPI to use read back
                WAIT_CNTRL_READ,        -- Wait for the Control Register ReadBack to Complete   -- deprecated need to slow down clk_SPI to use read back
                WAIT_READ_END,          -- Wait for Request to Drop                             -- deprecated need to slow down clk_SPI to use read back
                INIT_CNRL_WRITE,        -- Kick off the Control Register Initialisation
                WAIT_CNTRL_WRITE,       -- Wait for the Control Register Write to Complete
                WAIT_WRITE_END          -- Wait for Request to Drop
                );

signal CONTROL_STATE,NEXT_CONTROL_STATE : CONTROL_STATE_V;  --! Reset State Machine

type FIFO_FETCH_STATE_V is (
                FETCH_IDLE,             -- Idle State Wait Start from Load Machine
                LOAD_A,                 -- Latch the First Value and Read the Next
                LOAD_B,                 -- Latch the Second Value and Read the Next Fork if Packed Data
                LOAD_C,                 -- Latch the Third Value and Read the Next
                LOAD_D,                 -- Latch the Fourth Value and Read the Next
                WAIT_SHIFT_START,       -- Wait for the DAC to Start to Load
                WAIT_SHIFT_END          -- Wait for the DAC to Finish Load
                );

signal FIFO_FETCH_STATE,NEXT_FIFO_FETCH_STATE   : FIFO_FETCH_STATE_V;   --! Fetch Samples from the FIFO

type DAC_LOAD_STATE_V is (
                LOAD_IDLE,              -- Idle State Wait for Data Available
                LOAD_DACS,              -- Shift the Next Value into the DACs
                WAIT_CLOCK_PHASE,       -- Check Clock is inactive before update
                WAIT_PIPE,              -- Puse 1 clock for I/O FF Push
                WAIT_UPDATE,            -- Wait for the Update Pulse
                UPDATE_COMPLETE,        -- DACS updated
                WAIT_SETTLE_1,          -- Wait for DACs to Settle
                WAIT_SETTLE_2           -- Wait for DACs to Settle
                );

signal DAC_LOAD_STATE,NEXT_DAC_LOAD_STATE   : DAC_LOAD_STATE_V; --! DAC Load State Machine


signal READY_FOR_DATA       : std_logic;                        --! Control Register is written now OK to process data


type SHIFT_REGISTER_TYPE is array(4 downto 1) of std_logic_vector(19 downto 0); --! define array of 4 x 20 bit registers for 4 DACs
signal SHIFT_REGISTERS      : SHIFT_REGISTER_TYPE;                              --! Shift Registers


signal DAC_DATA_A           : std_logic_vector(23 downto 0);                    --! Channel 1 Data
signal DAC_DATA_B           : std_logic_vector(23 downto 0);                    --! Channel 2 Data
signal DAC_DATA_C           : std_logic_vector(23 downto 0);                    --! Channel 3 Data
signal DAC_DATA_D           : std_logic_vector(23 downto 0);                    --! Channel 4 Data
signal s_DAC_DATA_A         : std_logic_vector(15 downto 0);                    --! Channel 1 Data Signal
signal s_DAC_DATA_B         : std_logic_vector(15 downto 0);                    --! Channel 2 Data Signal
signal s_DAC_DATA_C         : std_logic_vector(15 downto 0);                    --! Channel 3 Data Signal
signal s_DAC_DATA_D         : std_logic_vector(15 downto 0);                    --! Channel 4 Data Signal

signal CNV_CLK              : std_logic_vector(3 downto 0)  := "0000";          --! Shift Register for edge detection for Update Clock
signal START_CONVERT        : std_logic;                                        --! Clock Edge Detected
signal SHIFT_COUNTER        : unsigned(4 downto 0)          := "00000";         --! Count the number of bits shifted
signal INDEX                : integer                       := 0;               --! Index into the Data Registers from the SHIFT_COUNTER
signal RUN_SHIFTING         : std_logic                     := '0';             --! Shift Complete write into FIFO
signal SHIFTING_STARTED     : std_logic                     := '0';             --! Shift Complete write into FIFO
signal s_DAC_SPI_CLK        : std_logic;                                        --! Local copy of the ADC SPI Clock

signal CONTROL_READBACK_SR  : std_logic_vector(23 downto 0);                    --! Control Register Readback Shift register

--------------------------------------------------------------------------------------
-- debug test using mark_debug
---------------------------------------------------------------------------------------
attribute mark_debug : string;
attribute keep       : string;
attribute dont_touch : string;


begin

DAC_RST_n <= '0' when (DAC_RESET = '1') else '1';

--! This process describes the state update on each clock transition
process (clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if DAC_RESET = '1' then
            CONTROL_STATE       <= CONTROL_IDLE;
            DAC_LOAD_STATE  <= LOAD_IDLE;
            FIFO_FETCH_STATE    <= FETCH_IDLE;
        else
            CONTROL_STATE   <= NEXT_CONTROL_STATE;
            DAC_LOAD_STATE  <= NEXT_DAC_LOAD_STATE;
            FIFO_FETCH_STATE    <= NEXT_FIFO_FETCH_STATE;
        end if;
    end if;
end process ;


--! This process describes the state transitions of the Reset State machine
CONTROL_STATE_MACHINE: process (CONTROL_STATE,DAC_ENABLE,CONTROL_WRITE,CONTROL_READ,RUN_SHIFTING)
begin
    NEXT_CONTROL_STATE <= CONTROL_STATE;
    case CONTROL_STATE is
    
        when CONTROL_IDLE =>
            if  DAC_ENABLE = '0' and CONTROL_WRITE = '1' then                   -- Start the Sequence when software writes to the register
                NEXT_CONTROL_STATE <= INIT_CNRL_WRITE;
            elsif  DAC_ENABLE = '0' and CONTROL_READ = '1' then                 -- Start the Sequence when software writes to the register
                NEXT_CONTROL_STATE <= INIT_CNRL_READ;
            end if;

        when INIT_CNRL_READ =>
            NEXT_CONTROL_STATE <= WAIT_READ_CMD;
    
        when WAIT_READ_CMD =>
            if RUN_SHIFTING = '0' then
                NEXT_CONTROL_STATE <= INIT_CNRL_DATA;
            end if;
    
        when INIT_CNRL_DATA =>
            NEXT_CONTROL_STATE <= WAIT_CNTRL_READ;
    
        when WAIT_CNTRL_READ =>
            if RUN_SHIFTING = '0' then
                NEXT_CONTROL_STATE <= WAIT_READ_END;
            end if;
    
        when WAIT_READ_END =>
            if CONTROL_READ = '0' then
                NEXT_CONTROL_STATE <= CONTROL_IDLE;
            end if;

        when INIT_CNRL_WRITE =>
            NEXT_CONTROL_STATE <= WAIT_CNTRL_WRITE;
        
        when WAIT_CNTRL_WRITE =>
            if RUN_SHIFTING = '0' then
                NEXT_CONTROL_STATE <= WAIT_WRITE_END;
            end if;
    
        when WAIT_WRITE_END =>
            if  CONTROL_WRITE = '0' then
                NEXT_CONTROL_STATE <= CONTROL_IDLE;
            end if;
    end case;
end process CONTROL_STATE_MACHINE;

CONTROL_READ_COMPL <= '1' when CONTROL_STATE = WAIT_READ_END else '0';
CONTROL_WRITE_COMPL <= '1' when CONTROL_STATE = WAIT_WRITE_END else '0';


process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if DAC_RESET = '1' then
            READY_FOR_DATA <= '0';
        elsif CONTROL_STATE = WAIT_WRITE_END then
            READY_FOR_DATA <= '1';
        end if;
    end if;
end process;


--! This process describes the state transitions of the Reset State machine. Once started the machine always reads a full sample to avoid
--! Partial Sample FIFO reads
FIFO_FETCH_STATE_MACHINE: process (FIFO_FETCH_STATE,READY_FOR_DATA,DAC_ENABLE,FIFO_AVAIL,DATA_SIZE,RUN_SHIFTING,LOW_LATENCY)
begin
    NEXT_FIFO_FETCH_STATE <= FIFO_FETCH_STATE;
    case FIFO_FETCH_STATE is
        
        when FETCH_IDLE =>
            if  DAC_ENABLE = '1' and READY_FOR_DATA = '1'  and FIFO_AVAIL = '1'   then -- Start the Sequence when the sub-system is enabled and the control register has been written
                NEXT_FIFO_FETCH_STATE <= LOAD_A; --  and either there is data in the FIFO or ignore in waveform mode since under runs need to be detected
            end if;
    
        when LOAD_A =>
            NEXT_FIFO_FETCH_STATE <= LOAD_B;
    
        when LOAD_B =>
            if DATA_SIZE = '0'  then --  0 =   packed complete after 2 loads
                NEXT_FIFO_FETCH_STATE <= WAIT_SHIFT_START;
            else
                NEXT_FIFO_FETCH_STATE <= LOAD_C;
            end if;
    
        when LOAD_C =>
            NEXT_FIFO_FETCH_STATE <= LOAD_D;
    
        when LOAD_D =>
            NEXT_FIFO_FETCH_STATE <= WAIT_SHIFT_START;
    
        when WAIT_SHIFT_START => -- Wait for the Shift Registers to Start or halt if disabled
            if DAC_ENABLE = '0'  then
                NEXT_FIFO_FETCH_STATE <= FETCH_IDLE;
            elsif RUN_SHIFTING = '1' then
                NEXT_FIFO_FETCH_STATE <= WAIT_SHIFT_END;
            end if;
    
        when WAIT_SHIFT_END =>
            if DAC_ENABLE = '0' or RUN_SHIFTING = '0' then -- Wait for them to end then loop or halt if disabled
                NEXT_FIFO_FETCH_STATE <= FETCH_IDLE;
            end if;
    
    end case;
end process FIFO_FETCH_STATE_MACHINE;

DAC_DATA_RD <= '1' when NEXT_FIFO_FETCH_STATE = LOAD_A or NEXT_FIFO_FETCH_STATE = LOAD_B or NEXT_FIFO_FETCH_STATE = LOAD_C or NEXT_FIFO_FETCH_STATE = LOAD_D else '0';


--! Process to latch the data to be shifted into the DACs, either the Control Register data or the FIFO data depending on the Reset Machine
--! Also latch the FIFO data depending on packing
LOAD_DAC_REGS: process (clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if CONTROL_STATE = INIT_CNRL_READ or CONTROL_STATE =  WAIT_READ_CMD then -- Read the Control Register   phase 1
            DAC_DATA_A  <= c_CONTROL_REGISTER_READ;
            DAC_DATA_B  <= c_CONTROL_REGISTER_READ;
            DAC_DATA_C  <= c_CONTROL_REGISTER_READ;
            DAC_DATA_D  <= c_CONTROL_REGISTER_READ;
        elsif CONTROL_STATE = INIT_CNRL_DATA or CONTROL_STATE =  WAIT_CNTRL_READ then -- Read the Control Register  phase 2
            DAC_DATA_A  <= (others => '0');
            DAC_DATA_B  <= (others => '0');
            DAC_DATA_C  <= (others => '0');
            DAC_DATA_D  <= (others => '0');
        elsif CONTROL_STATE = INIT_CNRL_WRITE or CONTROL_STATE =  WAIT_CNTRL_WRITE then -- Write the  Control Register
            DAC_DATA_A  <= SPI_CONTROL_DATA;
            DAC_DATA_B  <= SPI_CONTROL_DATA;
            DAC_DATA_C  <= SPI_CONTROL_DATA;
            DAC_DATA_D  <= SPI_CONTROL_DATA;
        else

            if DATA_SIZE = '0'  then -- Packed Data Case
                if FIFO_FETCH_STATE = LOAD_A then
                    DAC_DATA_A <= "0001" & FIFO_DATAOUT(15 downto  0) & "0000";
                    DAC_DATA_B <= "0001" & FIFO_DATAOUT(31 downto 16) & "0000";
                elsif FIFO_FETCH_STATE = LOAD_B then
                    DAC_DATA_C <= "0001" & FIFO_DATAOUT(15 downto  0) & "0000";
                    DAC_DATA_D <= "0001" & FIFO_DATAOUT(31 downto 16) & "0000";
                end if;
            else
                if FIFO_FETCH_STATE = LOAD_A then
                    DAC_DATA_A <= "0001" & FIFO_DATAOUT(31 downto  12);
                elsif FIFO_FETCH_STATE = LOAD_B then
                    DAC_DATA_B <= "0001" & FIFO_DATAOUT(31 downto  12);
                elsif FIFO_FETCH_STATE = LOAD_C then
                    DAC_DATA_C <= "0001" & FIFO_DATAOUT(31 downto  12);
                elsif FIFO_FETCH_STATE = LOAD_D then
                    DAC_DATA_D <= "0001" & FIFO_DATAOUT(31 downto  12);
                end if;
            end if;
        end if;
    end if;
end process LOAD_DAC_REGS;


--! This process describes the state transitions of the Reset State machine. Once started the machine always reads a full sample to avoid
--! Partial Sample FIFO reads
DAC_LOAD_STATE_MACHINE: process (DAC_LOAD_STATE,FIFO_FETCH_STATE,RUN_SHIFTING,LOW_LATENCY,CNV_CLK,CONV_ACTIVE)
begin
    NEXT_DAC_LOAD_STATE <= DAC_LOAD_STATE;
    case DAC_LOAD_STATE is
    
        when LOAD_IDLE =>
            if  FIFO_FETCH_STATE = WAIT_SHIFT_START then -- Start the Sequence after the FIFO has been read
                NEXT_DAC_LOAD_STATE <= LOAD_DACS;
            end if;
    
        when LOAD_DACS =>
            if LOW_LATENCY = '1' then -- If low latency move to update as soon as complete
                if RUN_SHIFTING = '0'  then
                    NEXT_DAC_LOAD_STATE <= WAIT_PIPE;
                end if;
            elsif RUN_SHIFTING = '0' and (CNV_CLK = "0000" or LOW_LATENCY = '1') and CONV_ACTIVE = '1' then -- Only move to update if clock in the correct phase or in Low Latency  and the module is triggered
                NEXT_DAC_LOAD_STATE <= WAIT_PIPE;
            elsif RUN_SHIFTING = '0' then -- Wait for Clock if Clock was in the wrong phase
                NEXT_DAC_LOAD_STATE <= WAIT_CLOCK_PHASE;
            end if;
        
        when WAIT_CLOCK_PHASE =>
            if (CNV_CLK = "0000" or LOW_LATENCY = '1') and CONV_ACTIVE = '1'  then -- move to update if clock in the correct phase or in Low Latency  and the module is triggered
                NEXT_DAC_LOAD_STATE <= WAIT_PIPE;
            end if;
    
        when WAIT_PIPE =>
            NEXT_DAC_LOAD_STATE <= WAIT_UPDATE;
    
        when WAIT_UPDATE =>
            if LOW_LATENCY = '1' then
                NEXT_DAC_LOAD_STATE <= UPDATE_COMPLETE;
            elsif CNV_CLK(2) = '1' and CNV_CLK(3) = '0' then -- Wait for Rising edge of Sample Clock
                NEXT_DAC_LOAD_STATE <= UPDATE_COMPLETE;
            end if;
    
        when UPDATE_COMPLETE =>
            NEXT_DAC_LOAD_STATE <= WAIT_SETTLE_1;
    
        when WAIT_SETTLE_1 =>
            NEXT_DAC_LOAD_STATE <= WAIT_SETTLE_2;
    
        when WAIT_SETTLE_2 =>
            NEXT_DAC_LOAD_STATE <= LOAD_IDLE;
    
    end case;
end process DAC_LOAD_STATE_MACHINE;


--! Count the bits shifted into the DAC MSB first
GENERATE_SHIFT_COUNT: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if s_DAC_SPI_CLK = '0' then
            SHIFTING_STARTED <= RUN_SHIFTING;
        end if;
        if DAC_RESET = '1' then
            SHIFT_COUNTER <= SHIFT_LENGTH;
            RUN_SHIFTING <= '0';
        elsif CONTROL_STATE = INIT_CNRL_WRITE or CONTROL_STATE = INIT_CNRL_READ  or CONTROL_STATE = INIT_CNRL_DATA or (DAC_LOAD_STATE = LOAD_IDLE and NEXT_DAC_LOAD_STATE = LOAD_DACS) then     -- One shot Startup
            SHIFT_COUNTER <= SHIFT_LENGTH;
            RUN_SHIFTING <= '1';
        elsif SHIFT_COUNTER = 0 and s_DAC_SPI_CLK = '0' then        -- Stop at end
            RUN_SHIFTING <= '0';
        elsif s_DAC_SPI_CLK = '0' and SHIFTING_STARTED = '1' then   -- only shift on upcoming rising edges
            SHIFT_COUNTER <= SHIFT_COUNTER - 1;
        end if;
    end if;
end process GENERATE_SHIFT_COUNT;

DAC_SYNC_n <= not RUN_SHIFTING; -- Sync frames the shift exactly

DAC_DATA_MUX: process(DAC_DATA_A,DAC_DATA_B,DAC_DATA_C,DAC_DATA_D,SHIFT_COUNTER,INDEX)
begin
    INDEX <= to_integer(SHIFT_COUNTER);
    -- Twist data so data from FIFO corresponds correctly with LEMO outputs
    DAC_SDI(1) <=   DAC_DATA_D(INDEX);
    DAC_SDI(2) <=   DAC_DATA_C(INDEX);
    DAC_SDI(3) <=   DAC_DATA_B(INDEX);
    DAC_SDI(4) <=   DAC_DATA_A(INDEX);
end process DAC_DATA_MUX;


--! Generate the DAC SPI Clock as a simple toggle divide by 2 starting on the correct phase
GEN_DAC_SPI_CLK: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if DAC_RESET = '1' then
            s_DAC_SPI_CLK <= '0';
        elsif   RUN_SHIFTING = '1' and SHIFT_COUNTER /= "00000"  then -- Could start 1 tick earlier check
            s_DAC_SPI_CLK <= not s_DAC_SPI_CLK;
        else
            s_DAC_SPI_CLK <= '0';
        end if;
    end if;
end process GEN_DAC_SPI_CLK;

DAC_SPI_CLK <= s_DAC_SPI_CLK;


--! DAC Update Pulse
GEN_UPDATE_PULSE:  process(clk_SPI,LOW_LATENCY,DAC_LOAD_STATE,READY_FOR_DATA,DAC_CNV_CLK,CNV_CLK)
begin
    if LOW_LATENCY = '1' then
        if DAC_LOAD_STATE = WAIT_UPDATE or DAC_LOAD_STATE = UPDATE_COMPLETE  then
            DAC_LD_n <= '0';
        else
            DAC_LD_n <=  '1';
        end if;
    elsif DAC_LOAD_STATE = WAIT_UPDATE then
        if CNV_CLK(3) = '0' then
            DAC_LD_n <=  DAC_CNV_CLK; -- Runt clocks may cause DAC problems
        else
            DAC_LD_n <= '1';
        end if;
    else
        DAC_LD_n <= '1';
    end if;

    if Rising_edge(clk_SPI) then -- Clock Rising Edge Detector with de-bounce
        if READY_FOR_DATA = '0' then -- if starting up
            CNV_CLK <= (others => '1');  -- pre-load de-bounce with ones
        else
            CNV_CLK(0) <= DAC_CNV_CLK;
            CNV_CLK(1) <= CNV_CLK(0) and DAC_CNV_CLK; -- De-bounce for valid edge
            CNV_CLK(2) <= CNV_CLK(1) and CNV_CLK(0) and DAC_CNV_CLK; -- Double de-bounce
            CNV_CLK(3) <= CNV_CLK(2); -- Clean any metastability
        end if;
    end if;
end process;


--! Readback the Control Register
process(clk_SPI,CONTROL_READBACK_SR)
begin
    if Rising_Edge(clk_SPI) then
        if CONTROL_STATE = INIT_CNRL_DATA then
            CONTROL_READBACK_SR <= (others =>'0');
        elsif RUN_SHIFTING = '1'  and  CONTROL_STATE = WAIT_CNTRL_READ  then
            CONTROL_READBACK_SR <= CONTROL_READBACK_SR(22 downto 0) & DAC_SDO(3);
        end if;
    end if;
    CONTROL_READBACK <= CONTROL_READBACK_SR ;
end process;

end RTL;
