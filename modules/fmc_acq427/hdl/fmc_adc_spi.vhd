---------------------------------------------------------------------------------
--! @file
--! @brief I/O Interface to the ACQ427FMC ADC Module
--! @author   John McLean
--! @date     21st May 2015
--! @details
--! D-TACQ Solutions Ltd Copyright 2013-18
--!

--! Standard Libraries - numeric.std for all designs
library ieee;
use ieee.std_logic_1164.all; -- Standard Logic Functions
use ieee.numeric_std.all;    -- Numeric Functions for Signed / Unsigned Arithmetic

--! Xilinx Primitive Library
library UNISIM;
use UNISIM.VComponents.all;  -- Xilinx Primitives


--! @brief I/O Interface to the ACQ42FMC Board for the ACQ400 System
entity ACQ427FMC_ADC_SPI is
    port (
    clk_SPI                 : in  std_logic;                    --! 100 MHz source clock to be used as SPI Clock for the ADCs
    RESET                   : in  std_logic;                    --! General Asynchronous Reset Signal
    ADC_ENABLE              : in  std_logic;                    --! Acquisition Enable to enable the ADC Conversion Logic
    ADC_RESOLUTION          : in  std_logic_vector(1 downto 0); --! Shift 24/20/18/16 bits of data from the ADCs
    DATA_SIZE               : in  std_logic;                    --! Pack data in 32/16 bits
    CONV_TIME               : in  std_logic_vector(7 downto 0); --! Number of clock ticks between convert and read back this is 540nS at 100MHz
    CONV_ACTIVE             : in  std_logic;                    --! Allow the Logic to store the converted data
    SAMPLE_COUNTER          : in  unsigned(31 downto 0);        --! Sample Count since Initial Trigger
    START_CONVERT           : in  std_logic;                    --! Clock Edge Detected
    CONVERSION_IN_PROGRESS  : out std_logic;                    --! Conversion In progress disable clock reception
    ADC_SPI_CLK             : out std_logic;                    --! ADC SPI Clock
    ADC_SDO                 : in  std_logic_vector(8 downto 1); --! ADC SPI Data
    ADC_DATAOUT             : out std_logic_vector(31 downto 0);--! ADC Data converted to parallel format
    ADC_DATA_VALID          : out std_logic                     --! Data valid for the 4 ADC devices
    );
end ACQ427FMC_ADC_SPI;


--! @brief I/O Interface to the ACQ42FMC Board for the ACQ400 System
architecture RTL of ACQ427FMC_ADC_SPI is

type STATE_V is (
                IDLE,           -- Idle State everything off
                PIPE_MUX1,      -- Pipeline the data into the Mux
                LATCH_A,        -- Latch bank A
                LATCH_B,        -- Latch bank B
                LATCH_C,        -- Latch bank C
                LATCH_D,        -- Latch bank D
                LATCH_E,        -- Latch bank E
                LATCH_F,        -- Latch bank F
                LATCH_G,        -- Latch bank G
                LATCH_H,        -- Latch bank H
                WAIT_RESTART    -- Wait till pipeline
                );

signal STATE,NEXT_STATE     : STATE_V;                                          --! Output Packing State Machine

type SHIFT_REGISTER_TYPE is array(8 downto 1) of std_logic_vector(23 downto 0); --! define array of 4 x n bit registers for 4 ADCs
type ADC_DATA_LATCH_TYPE is array(8 downto 1) of std_logic_vector(31 downto 0); --! define array of 4 32 bit registers for intermediate multiplexers for the ADC Data


signal SHIFT_REGISTERS  : SHIFT_REGISTER_TYPE;                                  --! Shift Registers

signal ADC_DATA_MUX     : ADC_DATA_LATCH_TYPE;                                  --! Intermediate multiplexers for the ADC Data


signal FIRST_SAMPLE         : std_logic := '0';                                 --! This is the first clock edge after enable
signal CONVERT_TIMER        : unsigned(7 downto 0)  := (others => '0');         --! Time to wait for the ADCs to convert before data readback
signal CONV_COMPLETE        : std_logic := '0';                                 --! ADC Conversion Complete
signal CONV_COMPLETE_d0     : std_logic := '0';                                 --! Pipelined ADC Conversion Complete
signal CONV_COMPLETE_d1     : std_logic := '0';                                 --! Pipelined ADC Conversion Complete
signal SHIFT_COUNTER        : unsigned(4 downto 0)  := (others => '0');         --! Count the number of bits shifted
signal SHIFT_LENGTH         : unsigned(4 downto 0)  := (others => '0');         --! Number of bits to shift
signal SHIFT_COMPL          : std_logic := '0';                                 --! Shift Complete write into FIFO
signal SHIFT_COMPL_d0       : std_logic := '0';                                 --! Shift Complete write into FIFO
signal SHIFT_COMPL_d1       : std_logic := '0';                                 --! Shift Complete write into FIFO extra pipeline for SERDES
signal SHIFT_COMPL_d2       : std_logic := '0';                                 --! Shift Complete write into FIFO extra pipeline for SERDES
signal SHIFT_COMPL_d3       : std_logic := '0';                                 --! Shift Complete write into FIFO extra pipeline for SERDES
signal s_ADC_SPI_CLK        : std_logic := '0';                                 --! ADC SPI Clock pipeline matched to the ADC
signal s_ADC_SPI_CLK_ADC    : std_logic := '0';                                 --! The ADC SPI Clock to the physical ADC - 1 clock pipeline in the I/O logic

signal s_ADC_DATA_VALID     : std_logic := '0';                                 --! Local copy Data valid for the ADC devices
signal s_ADC_DATAOUT        : std_logic_vector(31 downto 0) := (others => '0'); --! Local copy ADC Data converted to parallel format

--------------------------------------------------------------------------------------
-- debug test using mark_debug
---------------------------------------------------------------------------------------
attribute mark_debug : string;
attribute keep : string;
attribute dont_touch : string;


begin
--! Process to set the length of the shift based on selected resolution
SELECT_SHIFT: process(ADC_RESOLUTION)
begin
    case ADC_RESOLUTION is
        when "00" =>    SHIFT_LENGTH <= "01111"; -- 16 bit
        when "01" =>    SHIFT_LENGTH <= "10010"; -- 18 bit
        when "10" =>    SHIFT_LENGTH <= "10011"; -- 20 bit
        when "11" =>    SHIFT_LENGTH <= "10111"; -- 24 bit
        when others =>  SHIFT_LENGTH <= "01111"; -- 16 bit
    end case;
end process SELECT_SHIFT;


--! Simple Flag to determine the first sample after enable
FIRST_SAMPLE_SET: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if ADC_ENABLE = '0' or RESET = '1' then
            FIRST_SAMPLE <= '1';
        elsif START_CONVERT = '1' then
            FIRST_SAMPLE <= '0';
        end if;
    end if;
end process FIRST_SAMPLE_SET;

--! Control the conversion time-out.
WAIT_CONVERT_TIME: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if RESET = '1' then
            CONVERSION_IN_PROGRESS <= '0';
        elsif START_CONVERT = '1' then
            CONVERSION_IN_PROGRESS <= '1';
        elsif SHIFT_COMPL_d1 = '1' and SHIFT_COMPL_d2 = '0' then -- on rising edge of shift complete timed to the last shift on the ADC
            CONVERSION_IN_PROGRESS <= '0';
        end if;
        CONV_COMPLETE_d1 <= CONV_COMPLETE_d0;
        CONV_COMPLETE_d0 <= CONV_COMPLETE;
        if START_CONVERT = '1' or RESET = '1' then --kick off the timer when the ADC has been clocked
            CONVERT_TIMER <= (others => '0');
            CONV_COMPLETE <= '0';
        elsif CONVERT_TIMER = unsigned(CONV_TIME) then
            CONV_COMPLETE <= '1'; -- conversion time has elapsed
        else
            CONVERT_TIMER <= CONVERT_TIMER + 1;
            CONV_COMPLETE <= '0';
        end if;
    end if;
end process WAIT_CONVERT_TIME;

--! Count the bits shifted into the register MSB first
GENERATE_SHIFT_COUNT: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if  RESET = '1'  then
            SHIFT_COMPL_d3      <= '0';
            SHIFT_COMPL_d2  <= '0';
            SHIFT_COMPL_d1  <= '0';
            SHIFT_COMPL_d0  <= '0';
        else
            SHIFT_COMPL_d3  <= SHIFT_COMPL_d2;
            SHIFT_COMPL_d2  <= SHIFT_COMPL_d1;
            SHIFT_COMPL_d1  <= SHIFT_COMPL_d0;
            SHIFT_COMPL_d0  <= SHIFT_COMPL;
        end if;
        if CONV_COMPLETE_d0 = '0' or FIRST_SAMPLE = '1' or RESET = '1' then -- Hold in Reset until conversion time elapsed
            SHIFT_COUNTER <= (others => '0');
            SHIFT_COMPL <= '0';
        elsif SHIFT_COUNTER = SHIFT_LENGTH then -- Shift according to the resolution
            SHIFT_COMPL <= '1';
        elsif s_ADC_SPI_CLK = '0' then -- only shift on upcoming rising edges
            SHIFT_COUNTER <= SHIFT_COUNTER + 1;
        end if;
    end if;
end process GENERATE_SHIFT_COUNT;


--! Generate the ADC SPI Clock as a simple toggle divide by 2 starting on the correct phase
GEN_ADC_SPI_CLK: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        s_ADC_SPI_CLK <= s_ADC_SPI_CLK_ADC;
        if CONV_COMPLETE = '0' or SHIFT_COMPL = '1' or FIRST_SAMPLE = '1'  then
            s_ADC_SPI_CLK_ADC <= '0';
        else
            s_ADC_SPI_CLK_ADC <= not s_ADC_SPI_CLK_ADC;
        end if;
    end if;
end process GEN_ADC_SPI_CLK;

ADC_SPI_CLK <= s_ADC_SPI_CLK_ADC; -- ADC 1 Clock early for IOB Sync


--! Shift Register Logic
THE_SHIFT_REGISTERS: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        for i in 8 downto 1 loop
            if CONV_COMPLETE_d0 = '1' and SHIFT_COMPL_d2 = '0' and s_ADC_SPI_CLK = '0' then         -- On rising edge of clock when running
                case ADC_RESOLUTION is

                    when "00" =>        -- 16 bit ADCs
                        SHIFT_REGISTERS(i) <=  SHIFT_REGISTERS(i)(22 downto 8) & ADC_SDO(i) & "00000000";   -- Shift left the array of shift registers

                    when "01" =>        -- 18 bit ADCs
                        SHIFT_REGISTERS(i) <=  SHIFT_REGISTERS(i)(22 downto 6) & ADC_SDO(i) & "000000";     -- Shift left the array of shift registers

                    when "10" =>        -- 20 bit
                        SHIFT_REGISTERS(i) <=  SHIFT_REGISTERS(i)(22 downto 4) & ADC_SDO(i) & "0000";       -- Shift left the array of shift registers

                    when "11" =>        -- 24 bit
                        SHIFT_REGISTERS(i) <=  SHIFT_REGISTERS(i)(22 downto 0) & ADC_SDO(i) ;               -- Shift left the array of shift registers

                    when others =>      -- 16 bit
                        SHIFT_REGISTERS(i) <=  SHIFT_REGISTERS(i)(22 downto 8) & ADC_SDO(i) & "00000000";   -- Shift left the array of shift registers
                end case;
            end if;
        end loop;
    end if;
end process THE_SHIFT_REGISTERS;


PIPE_ADC_MUX_A: process(clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if DATA_SIZE = '1' then -- unpacked data
            for i in 8 downto 1 loop
                ADC_DATA_MUX(i)  <= SHIFT_REGISTERS(i) & x"00";
            end loop;
        else -- packed data
            for i in 4 downto 1 loop
                ADC_DATA_MUX(i) <= SHIFT_REGISTERS(2*i)(23 downto 8) & SHIFT_REGISTERS(2*i-1)(23 downto 8);
            end loop;
        end if;
    end if;
end process PIPE_ADC_MUX_A;


--! This process describes the state update on each clock transition
STATE_UPDATE: process (clk_SPI)
begin
    if Rising_edge(clk_SPI) then
        if RESET = '1' then
            STATE <= IDLE;
        else
            STATE  <= NEXT_STATE;
        end if;
    end if;
end process STATE_UPDATE;

--! This process describes the state transitions
STATE_MACHINE: process (STATE,SHIFT_COMPL_d2,SHIFT_COMPL_d3,DATA_SIZE,CONV_ACTIVE)
begin
    NEXT_STATE <= STATE;
    case STATE is

        when IDLE =>
            if  SHIFT_COMPL_d2 = '1' and SHIFT_COMPL_d3 = '0' and CONV_ACTIVE = '1'  then
                NEXT_STATE <= PIPE_MUX1;
            else
                NEXT_STATE <= IDLE ;
            end if;

        when PIPE_MUX1 =>
            NEXT_STATE <= LATCH_A;

        when LATCH_A =>
            NEXT_STATE <= LATCH_B;

        when LATCH_B =>
            NEXT_STATE <= LATCH_C;

        when LATCH_C =>
            NEXT_STATE <= LATCH_D;

        when LATCH_D =>
            if DATA_SIZE = '0' then -- finish packing when in packed mode
                NEXT_STATE <= WAIT_RESTART;
            else
                NEXT_STATE <= LATCH_E;
            end if;

        when LATCH_E =>
            NEXT_STATE <= LATCH_F;

        when LATCH_F =>
            NEXT_STATE <= LATCH_G;

        when LATCH_G =>
            NEXT_STATE <= LATCH_H;

        when LATCH_H =>
            NEXT_STATE <= WAIT_RESTART;

        when WAIT_RESTART =>
            if SHIFT_COMPL_d2 = '0' then
                NEXT_STATE <= IDLE;
            end if;

    end case;
end process STATE_MACHINE;

--! This process describes the state output decode
STATE_DECODE: process(STATE,ADC_DATA_MUX)
begin
    case STATE is
        when IDLE =>
            s_ADC_DATA_VALID <= '0';
            s_ADC_DATAOUT <= ADC_DATA_MUX(1);

        when PIPE_MUX1 =>
            s_ADC_DATA_VALID <= '0';
            s_ADC_DATAOUT <= ADC_DATA_MUX(1);

        when LATCH_A =>
            s_ADC_DATA_VALID <= '1';
            s_ADC_DATAOUT <=  ADC_DATA_MUX(1);

        when LATCH_B =>
            s_ADC_DATA_VALID <= '1';
            s_ADC_DATAOUT <=  ADC_DATA_MUX(2);

        when LATCH_C =>
            s_ADC_DATA_VALID <= '1';
            s_ADC_DATAOUT <=  ADC_DATA_MUX(3);

        when LATCH_D =>
            s_ADC_DATA_VALID <= '1';
            s_ADC_DATAOUT <=  ADC_DATA_MUX(4);

        when LATCH_E =>
            s_ADC_DATA_VALID <= '1';
            s_ADC_DATAOUT <=  ADC_DATA_MUX(5);

        when LATCH_F =>
            s_ADC_DATA_VALID <= '1';
            s_ADC_DATAOUT <=  ADC_DATA_MUX(6);

        when LATCH_G =>
            s_ADC_DATA_VALID <= '1';
            s_ADC_DATAOUT <=  ADC_DATA_MUX(7);

        when LATCH_H =>
            s_ADC_DATA_VALID <= '1';
            s_ADC_DATAOUT <=  ADC_DATA_MUX(8);

        when WAIT_RESTART =>
            s_ADC_DATA_VALID <= '0';
            s_ADC_DATAOUT <=  ADC_DATA_MUX(1);

    end case;
end process STATE_DECODE;


ADC_DATA_LATCH: process (clk_SPI)
begin
    if Rising_edge(clk_SPI) then -- 1 Clock Pipeline to ease Data Mux into the FIFO
        ADC_DATAOUT     <= s_ADC_DATAOUT;
        ADC_DATA_VALID      <= s_ADC_DATA_VALID;
    end if;
end process ADC_DATA_LATCH;

end RTL;
