---------------------------------------------------------------------------------
--! @file
--! @brief ADC logic including Mode Dependent Sync Generation, ADC Start-up delay
--! @author   John McLean
--! @date     17th February 2016
--! @details                                                                   \n
--! D-TACQ Solutions Ltd Copyright 2014-2017                                   \n
--!                                                                            \n

-- Standard Libraries - numeric.std for all designs
library ieee;
use ieee.std_logic_1164.all;    --! Standard Logic Functions
use ieee.numeric_std.all;       --! Numeric Functions for Signed / Unsigned Arithmetic

-- If using Xilinx primitives need the Xilinx library
library UNISIM;
use UNISIM.VComponents.all;     --! Xilinx Primitives

--! Local Functions and Types
use work.ACQ430TYPES.all;       --! Local Types

--!  ADC logic including Mode Dependent Sync Generation, ADC Start-up delay and FIFO Write Logic
entity ACQ430FMC_FUNC is
    Generic(
    g_FMC_SITE              : integer := 0;
    g_SLAVE_MODE            : boolean := false
    );
    port (
    clk_SPI                 : in    std_logic;                     --! 100 MHz source clock to be used as SPI Clock for the ADCs
    ADC_ENABLE              : in    std_logic;                     --! Acquisition Enable
    ADC_RESET               : in    std_logic;                     --! General Asynchronous Reset Signal
    FIFO_ENABLE             : in    std_logic;                     --! FIFO Write Enable
    FIFO_RESET              : in    std_logic;                     --! FIFO Reset
    CONV_ACTIVE             : in    std_logic;                     --! Allow the Logic to store the converted data
    ADC_MODE                : in    std_logic_vector( 4 downto 0); --! ADC Mode Select
    HW_SYNC                 : in    std_logic;                     --! Index Sync from I/O Selector
    HW_SYNC_EN              : in    std_logic;                     --! Use External Sync
    GEN_SYNC_OUT            : out   std_logic;                     --! Internal Index Generator Output
    EXT_SYNC_OUT            : out   std_logic;                     --! Index Generator Output to the Sync Bus
    ADC_FSYNC_INT           : out   std_logic;                     --! ADC Frame Sync for start of Sample
    STARTUP_COMPLETE        : out   std_logic;                     --! Start up has reached the number of samples to initialise the ADCs
    ADC_DATAOUT             : out   std_logic_vector(31 downto 0); --! ADC Data converted to parallel format
    ADC_FIFOWRITE           : out   std_logic;                     --! ADC Data FIFO Write Output
-- Connections to the Physical ADCs
    SPI_CLOCK_ENABLE        : out    std_logic;                    --! ADC SPI Clock Enable
    ADC_SDO                 : in     std_logic;                    --! ADC SPI Data
    ADC_SYNC_n              : out    std_logic;                    --! ADC Inter-Device Synchronisation
    ADC_FSYNC               : out    std_logic                     --! ADC Frame Sync for start of Sample
    );
end ACQ430FMC_FUNC;


--!  ADC logic including SPI logic, ADC timing and mode select
architecture STRUCTURE of ACQ430FMC_FUNC is

signal INDEX_COUNTER            :unsigned( 8 downto 0) := (others => '0');  --! Number of cycles, 256 in High Speed and 512 in High Resolution

signal s_INTERNAL_INDEX         : std_logic;            --! Internally Generated Index pulse for FSYNC Generation
signal s_INDEX                  : std_logic;            --! Multiplexed Internal / External Index pulse for FSYNC Generation
signal s_INDEX_d1               : std_logic;            --! Pipelined Index for FSYNC Generation
signal s_INDEX_d2               : std_logic;            --! Pipelined Index for FSYNC Generation
signal s_INDEX_d3               : std_logic;            --! Pipelined Index for FSYNC Generation
signal s_INDEX_d4               : std_logic;            --! Pipelined Index for FSYNC Generation
signal s_ADC_FSYNC              : std_logic;            --! Index pulse for FSYNC Generation
signal s_SAMPLING_ON            : std_logic;            --! Gated Mode Sampling On/Off
signal s_SAMPLING_STALLED       : std_logic;            --! SRTM Stall Detected switch off sampling immediately.
signal s_SPI_CLOCK_ENABLE       : std_logic;            --! Switch On the SPI Clock to the ADCs  / Off during SRTM mode
signal s_SAMPLING_CHANGE_COUNT  : unsigned(7 downto 0); --! Count to pipeline the FIFO write on-off according to the group delay of the ADC
signal s_SAMPLING_GOING_ON      : std_logic;            --! Pipeline the FIFO write going On
signal s_SAMPLING_GOING_OFF     : std_logic;            --! Pipeline the FIFO write going Off
signal s_SAMPLING_ON_DELAYED    : std_logic := '0';     --! Pipeline delayed version of the FIFO write enable


signal SHIFT_IN_PROGRESS        : std_logic;            --! Data is being shifted
signal ADC_DATA_COMPLETE_SPI    : std_logic;            --! Data shift finishing
signal ADC_DATA_COMPLETE_ACCUM  : std_logic;            --! Data shift finishing
signal s_ADC_DATA_VALID_SPI     : std_logic;            --! Data valid for the 4 ADC devices from the SPI logic


type STATE_V is (
                IDLE,           --! Idle State everything off
                START,          --! ACQEN on - start Sync
                SYNC_THEM,      --! Reset the ADSs
                WAIT_TIMEOUT,   --! Wait the filter to clear
                WAIT_FSYNC,     --! Next FSYNC to start the data latch
                LATCH_DATA,     --! Write the FIFO
                -- FINISH_WRITE,--! Last Sample Written
                RE_SYNC         --! Conversion Complete - Check Controls and Loop
                );


signal STATE,NEXT_STATE:         STATE_V;

signal FSTATE               : std_logic;                                --! Only allow the FIFO Write to go on/off on a sample boundary
signal s_ADC_SYNC           : std_logic;                                --! SYNC pulse to the ADCs

signal STARTUP_COUNTER      : unsigned( 7 downto 0) :=(others => '0');  --! Throw away the first n samples after starting the ADCs to clear the digital filter
signal s_STARTUP_COMPLETE   : std_logic;                                --! Start up has reached the number of samples to initialise the ADCs

signal s_ADC_DATAOUT_SPI    : std_logic_vector(31 downto 0);            --! Serial-to-Parallel Data from the SPI logic
signal s_ADC_DATAOUT_ACCUM  : std_logic_vector(31 downto 0);            --! Serial-to-Parallel Data from the Accumulator

--------------------------------------------------------------------------------------
-- debug test using mark_debug
---------------------------------------------------------------------------------------
attribute mark_debug : string;
attribute keep : string;

begin

--------------------------------------------------------------------------------------------------------------------
--- Master Board Logic
--------------------------------------------------------------------------------------------------------------------

--! Generate the Timing for sample index
GEN_FSYNC_TIMING: process(clk_SPI)
begin
    if Rising_Edge(clk_SPI) then
        if ADC_RESET = '1' or ADC_ENABLE = '0' then -- Synchronous reset
            INDEX_COUNTER <= (others => '0');
            s_INTERNAL_INDEX <= '1';
        else
            if ADC_MODE(4) = '0' and INDEX_COUNTER = c_HIGH_SPEED_DIVIDE then -- Reset on High Speed count Value
                INDEX_COUNTER <= (others => '0');
                s_INTERNAL_INDEX <= '1';
            elsif ADC_MODE(4) = '1' and INDEX_COUNTER = c_HIGH_RES_DIVIDE then -- Reset on High Resolution Value
                INDEX_COUNTER <= (others => '0');
                s_INTERNAL_INDEX <= '1';
            else
                INDEX_COUNTER <= INDEX_COUNTER + 1; -- Index returns to zero next falling edge
                s_INTERNAL_INDEX <= '0';
            end if;
        end if;
    end if;
end process GEN_FSYNC_TIMING;


--------------------------------------------------------------------------------------------------------------------
---Common Logic
--------------------------------------------------------------------------------------------------------------------
--! This Process selects the Generated / HW FSYNC Source
INDEX_SELECTOR: process (clk_SPI)
begin
    if Rising_Edge(clk_SPI) then
        if HW_SYNC_EN = '1'  or g_SLAVE_MODE = true then
            s_INDEX <= HW_SYNC;
        else
            s_INDEX <= s_INTERNAL_INDEX;
        end if;
    end if;
end process INDEX_SELECTOR;

GEN_SYNC_OUT    <= s_INDEX;
EXT_SYNC_OUT    <= s_INTERNAL_INDEX;


--! Generate the s_ADC_FSYNC signal re-sync to the SPI clock to break the combinatorial chain
GENERATE_ADC_FSYNC: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        s_INDEX_d4 <= s_INDEX_d3;
        s_INDEX_d3 <= s_INDEX_d2;
        s_INDEX_d2 <= s_INDEX_d1;
        s_INDEX_d1 <= s_INDEX;
        if s_INDEX_d3 = '1' and s_INDEX_d1 = '0' and s_ADC_FSYNC = '0' then
            s_ADC_FSYNC <= '1';
        else
            s_ADC_FSYNC <= '0';
        end if;

        if ADC_ENABLE = '0' then
            s_SAMPLING_ON <= '0';
            s_SAMPLING_STALLED <= '0';
            s_SPI_CLOCK_ENABLE <= '0';
        else
            if s_INDEX_d4 = '0' and s_INDEX_d3 = '1' and s_INDEX_d2 = '0' and s_INDEX_d1 = '0' then -- Normal Mode /Gate On single SYNC pulse
                s_SAMPLING_ON <= '1';
            elsif s_INDEX_d4 = '0' and  s_INDEX_d3 = '1' and s_INDEX_d2 = '1' and s_INDEX_d1 = '0'  then -- Gate Off Mode double SYNC pulse
                s_SAMPLING_ON <= '0';
            end if;
            if s_INDEX_d4 = '0' and s_INDEX_d3 = '1' and s_INDEX_d2 = '1' and s_INDEX_d1 = '1' then -- Cycle Stall Mode - switch off Sampling Immediately
                s_SAMPLING_STALLED <= '1';
                s_SPI_CLOCK_ENABLE <= '0';
            elsif  s_INDEX_d3 = '1' and s_INDEX_d1 = '0'  then
                s_SAMPLING_STALLED <= '0';
                s_SPI_CLOCK_ENABLE <= '1';
            end if;
        end if;
    end if;
end process GENERATE_ADC_FSYNC;


--! Start-up counter to delay normal operation after a reset.
THE_STARTUP_COUNTER: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if (STARTUP_COUNTER = c_SYNC_TIME_MASTER and g_SLAVE_MODE = false) or (STARTUP_COUNTER = c_SYNC_TIME_SLAVE and g_SLAVE_MODE = true) then
            s_STARTUP_COMPLETE <= '1';
        elsif s_ADC_FSYNC = '1'  then
            STARTUP_COUNTER <= STARTUP_COUNTER + 1;
            s_STARTUP_COMPLETE <= '0';
        end if;
    end if;
end process THE_STARTUP_COUNTER;

STARTUP_COMPLETE <= s_STARTUP_COMPLETE;

FIFO_STATE: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if ADC_RESET = '1' then
            FSTATE <= '0';
        elsif (CONV_ACTIVE = '1') and (FIFO_ENABLE = '1') and (STATE = WAIT_FSYNC)  then
            FSTATE <= '1';
        elsif ((((FIFO_ENABLE = '0') or CONV_ACTIVE = '0') and (STATE = WAIT_FSYNC)))  or FIFO_RESET = '1' then
            FSTATE <= '0';
        end if;
    end if;
end process FIFO_STATE;


--! This process describes the state update on each clock transition
TRANSITION: process (clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if ADC_ENABLE = '0' or FIFO_RESET = '1' or ADC_RESET = '1' then
            STATE <= IDLE;
        else
            STATE  <= NEXT_STATE;
        end if;
    end if;
end process TRANSITION;


STATE_MACHINE: process (STATE,s_ADC_FSYNC,SHIFT_IN_PROGRESS,STARTUP_COUNTER,ADC_DATA_COMPLETE_ACCUM)
begin
    NEXT_STATE <= STATE;
    case STATE is
    
        when IDLE =>
            NEXT_STATE <= START;
    
        when START =>
            if s_ADC_FSYNC = '1' then
                NEXT_STATE <= SYNC_THEM;
            end if;
    
        when SYNC_THEM =>
            NEXT_STATE <= WAIT_TIMEOUT;
    
        when WAIT_TIMEOUT =>
            if s_STARTUP_COMPLETE = '1' then
                NEXT_STATE <= WAIT_FSYNC;
            end if;
    
        when WAIT_FSYNC =>
            if s_ADC_FSYNC = '1' and s_SAMPLING_STALLED = '0'  then
                NEXT_STATE <= LATCH_DATA;
            end if;

        when LATCH_DATA =>
            if ADC_DATA_COMPLETE_ACCUM = '1' then
                NEXT_STATE <= RE_SYNC;
            end if;
    
        when RE_SYNC =>
            NEXT_STATE <= WAIT_FSYNC;
    end case;
end process STATE_MACHINE;


--! Process to delay the Sampling On off by the Group delay of the ADS1278 ADC
DELAY_SAMPLING: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if ADC_ENABLE = '0' or s_SAMPLING_STALLED = '1'  then
            s_SAMPLING_CHANGE_COUNT <= (others => '0');
            s_SAMPLING_GOING_ON <= '0';
            s_SAMPLING_GOING_OFF <= '0';
            s_SAMPLING_ON_DELAYED <= '0';
        elsif s_SAMPLING_ON = '1' and  s_SAMPLING_GOING_ON = '0' and s_SAMPLING_ON_DELAYED = '0' and  s_SAMPLING_GOING_OFF = '0' then  -- Going On
            s_SAMPLING_CHANGE_COUNT <= (others => '0');
            s_SAMPLING_GOING_ON <= '1';
        elsif s_SAMPLING_GOING_ON = '1' then
            if (s_SAMPLING_CHANGE_COUNT = c_GROUP_DELAY_HI_RES and ADC_MODE(4) = '1') or (s_SAMPLING_CHANGE_COUNT = c_GROUP_DELAY_HI_SPEED and ADC_MODE(4) = '0') then
                s_SAMPLING_ON_DELAYED <= '1';
                s_SAMPLING_GOING_ON <= '0';
            elsif s_ADC_FSYNC = '1' then
                s_SAMPLING_CHANGE_COUNT <= s_SAMPLING_CHANGE_COUNT + 1;
            end if;
        elsif s_SAMPLING_ON = '0' and  s_SAMPLING_GOING_OFF = '0' and s_SAMPLING_ON_DELAYED = '1' and  s_SAMPLING_GOING_ON = '0' then  -- Going Off
            s_SAMPLING_CHANGE_COUNT <= (others => '0');
            s_SAMPLING_GOING_OFF <= '1';
        elsif s_SAMPLING_GOING_OFF = '1' then
            if (s_SAMPLING_CHANGE_COUNT = c_GROUP_DELAY_HI_RES and ADC_MODE(4) = '1') or (s_SAMPLING_CHANGE_COUNT = c_GROUP_DELAY_HI_SPEED and ADC_MODE(4) = '0') then
                s_SAMPLING_ON_DELAYED <= '0';
                s_SAMPLING_GOING_OFF <= '0';
            elsif s_ADC_FSYNC = '1' then
                s_SAMPLING_CHANGE_COUNT <= s_SAMPLING_CHANGE_COUNT + 1;
            end if;
        end if;
    end if;
end process DELAY_SAMPLING;

--! Process to control the FIFO write for both Embedded Signature and ADC data
WRITE_TO_FIFO: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        ADC_DATAOUT <= s_ADC_DATAOUT_SPI;

        if (FSTATE = '1') and ( STATE = LATCH_DATA and s_ADC_DATA_VALID_SPI = '1') and s_SAMPLING_ON_DELAYED = '1' then
            ADC_FIFOWRITE <= '1';
        else
            ADC_FIFOWRITE <= '0';
        end if;
    end if;
end process WRITE_TO_FIFO;

--! Output a SYNCn pulse immediately following a FSYNC on Start-up.
GENERATE_SYNC: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if STATE = SYNC_THEM then
            s_ADC_SYNC <= '1';
        else
            s_ADC_SYNC <= '0';
        end if;
    end if;
end process GENERATE_SYNC;


ADC_FSYNC_INT       <= s_ADC_FSYNC;
SPI_CLOCK_ENABLE    <= s_SPI_CLOCK_ENABLE;
ADC_SYNC_n          <= not s_ADC_SYNC;
ADC_FSYNC           <= s_ADC_FSYNC;


--! ADC SPI Logic
THE_ACQ430FMC_ADC: entity work.ACQ430FMC_SPI(RTL)
port map (
    clk_SPI             => clk_SPI,               -- SPI Clock for the ADCs is either 512 or 256 times the desired sample rate
    SAMPLING_STALLED    => s_SAMPLING_STALLED,    -- Reset State Machines while the ADCs are stalled
    ADC_FSYNC           => s_ADC_FSYNC,           -- Frame Sync defining the first data strobe
    ADC_SDO             => ADC_SDO,               -- Serial input data from 4 ADCs
    ADC_DATA_COMPLETE   => ADC_DATA_COMPLETE_SPI, -- Data shift finishing
    ADC_DATAOUT         => s_ADC_DATAOUT_SPI,     -- ADC Data converted to parallel format
    ADC_DATA_VALID      => s_ADC_DATA_VALID_SPI   -- Data valid for the 4 ADC devices
);

end STRUCTURE;
