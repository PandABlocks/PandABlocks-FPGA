---------------------------------------------------------------------------------------
--! @file
--! @brief    ACQ427FMC Module Address Decode and Control - PandA
--! @author   John McLean
--! @date     14th June 2017
--! @details
--! D-TACQ Solutions Ltd Copyright 2014-2018
--!

--! Standard Libraries - numeric.std for all designs
library ieee;
use ieee.std_logic_1164.all;    --! Standard Logic Functions
use ieee.numeric_std.all;       --! Numeric Functions for Signed / Unsigned Arithmetic

--! Xilinx Primitive Library
library UNISIM;
use UNISIM.VComponents.all;     -- Xilinx Primitives

--! Local Functions and Types
use work.ACQ427TYPES.all;       --! Local Types

--! ACQ427FMC Interface, Register Decode and Data FIFO
entity ACQ427FMC_ADC_INTERFACE is
port(
    clk_PANDA               : in  std_logic;                      --! ADC Clock for ADC Timing from the Zynq Core

    --EXT_CLOCK               : in  std_logic;                      --! External Clock - Tied Off -- GBC:20190321
    --FMC_IO_BUS              : out std_logic_vector(3 downto 0);   --! FMC IO Controls (FMC_LEMO_ROLE,CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR) --GBC:20190321 (unused)
-- Connections to PandA registers
    --ADC_CLK_SELECT_REG      : in  std_logic_vector(31 downto 0);  -- GBC:20190321
    ADC_CLKDIV_REG          : in  std_logic_vector(31 downto 0);
    ADC_FIFO_RESET_REG      : in  std_logic_vector(31 downto 0);
    ADC_FIFO_ENABLE_REG     : in  std_logic_vector(31 downto 0);
    ADC_RESET_REG           : in  std_logic_vector(31 downto 0);
    ADC_ENABLE_REG          : in  std_logic_vector(31 downto 0);
-- Connections to the Physical ADCs
    clk_ADC_IOB             : out std_logic;                      --! ADC SPI Clk for IOBs
    ADC_SDO                 : in  std_logic_vector(8 downto 1);   --! ADC SPI Data
    ADC_CNV                 : out std_logic;                      --! ADC Convert Control
    ADC_SPI_CLK             : out std_logic;                      --! ADC SPI Clock
    --ADC_A0                  : out std_logic_vector(4 downto 1);   --! AD8251 Gain Setting Address Bit 0 --GBC:20190321 (unused)
    --ADC_A1                  : out std_logic_vector(4 downto 1);   --! AD8251 Gain Setting Address Bit 1 --GBC:20190321 (unused)
    --
    ADC_DATAOUT             : out std_logic_vector(255 downto 0)  --! 8 Channels of ADC Dataout for connection to Position Bus
    );
end ACQ427FMC_ADC_INTERFACE;


architecture RTL of ACQ427FMC_ADC_INTERFACE is

component fmc_acq430_ch_fifo is
  Port (
    rst    : in STD_LOGIC;
    wr_clk : in STD_LOGIC;
    rd_clk : in STD_LOGIC;
    din    : in STD_LOGIC_VECTOR(31 downto 0);
    wr_en  : in STD_LOGIC;
    rd_en  : in STD_LOGIC;
    dout   : out STD_LOGIC_VECTOR(255 downto 0);
    full   : out STD_LOGIC;
    empty  : out STD_LOGIC;
    rd_data_count : out STD_LOGIC_VECTOR(4 downto 0)
  );
end component;

--*************************************************************************************************************************
-- AXI_clk Domain signals
--*************************************************************************************************************************

signal  FIFO_DATAOUT            : std_logic_vector(31 downto 0)  := (others => '0'); --! FIFO data to AXI_DATA_ENGINE
signal  FIFO_FULL               : std_logic                      := '0';             --! FIFO FULL      signal: to  REGISTERS
signal  FIFO_EMPTY              : std_logic                      := '0';             --! FIFO EMPTY     signal: to  REGISTERS
signal  FIFO_OVER               : std_logic                      := '0';             --! FIFO OVERFLOW  signal: to  REGISTERS
signal  FIFO_UNDER              : std_logic                      := '0';             --! FIFO UNDERFLOW signal: to  REGISTERS

signal  ADCCLK_FIFO_FULL        : std_logic                      := '0';             --! FIFO FULL      signal on the IP is in the Write Clock Domain

signal  FIFO_RD_EN              : std_logic                      := '0';             --! FIFO Read control

signal  ADC_CLK                 : std_logic_vector(3 downto 0)   := (others => '0'); --! Debounce array for ADC Convert Clock Edge detection
signal  ADC_CLK_CURRENT         : std_logic                      := '0';             --! Current Value of the ADC Clock
signal  ADC_CLK_CURRENT_d1      : std_logic                      := '0';             --! Current Value of the ADC Clock
signal  ADC_CLK_RISING          : std_logic                      := '0';             --! Rising Edge of the ADC Convert Clock

--Register Data
signal ADC_FIFO_COUNT_DATA      : std_logic_vector(4 downto 0)   := (others => '0'); --! ADC Sample Count Register Data
--signal ADC_GAINSEL_DATA         : std_logic_vector( 7 downto 0)  := (others => '0'); --! ADC Gain Control Setting Register --GBC:20190321

--*************************************************************************************************************************
-- ADC_clk Domain
--*************************************************************************************************************************

signal ADCCLK_CLKDIV_DATA       : std_logic_vector(15 downto 0)  := (others => '0'); --! ADC Control Register Data in the ADC Clock domain
--signal ADCCLK_GAINSEL_DATA      : std_logic_vector( 7 downto 0)  := (others => '0'); --! ADC Gain Control Setting Register  --GBC:20190321

signal ADC_FIFO_ENABLE          : std_logic                      := '0';
signal ADC_FIFO_RESET           : std_logic                      := '0';

signal FIFO_DATAIN              : std_logic_vector(31 downto 0)  := (others => '0');
signal FIFO_DATA_WRITE          : std_logic                      := '0';

signal clk_SEL                  : std_logic;                                         --! Clock Selected from Either EXT_SEL or the 100M Zynq Clock
signal DIV_CLK                  : std_logic;                                         --! Divided Down Clock for Asynchronous Logic
--signal DIV_CLK_SEL              : std_logic;                                         --! Select between Divided Down Clock and input clock for the special case of divide by 1 --GBC:20190321

signal HW_CLK_EN                : std_logic;                                         --! External Clock Enable

signal CONV_ACTIVE              : std_logic                      := '0';             --! Conversion Active - Enabled AND Triggered

signal ADC_RESET                : std_logic                      := '0';             --! Reset the ADC logic
signal CLK_SEL_ADC_RESET        : std_logic                      := '0';             --! Reset the ADC logic
signal ADC_ENABLE               : std_logic                      := '0';             --! Combination of ALG Enable and ICS_OE_CLK_s
signal DATA_SIZE                : std_logic                      := '1';             --! Pack data in 32/16 bits
signal ADC_RESOLUTION           : std_logic_vector( 1 downto 0)  := "01";            --! Shift 24/20/18/16 bits of data from the ADCs
signal ADC_CLK_DIV              : std_logic_vector(15 downto 0)  := (others => '0'); --! Clock Divider to generate ADC Sample Clock
signal ADC_CONV_TIME            : std_logic_vector( 7 downto 0)  := (others => '0'); --! Number of clock ticks between convert and read back this is 710nS at 50MHz
signal ADC_DOUT                 : std_logic_vector(31 downto 0)  := (others => '0'); --! ADC Data converted to parallel format
signal ADC_FIFOWRITE            : std_logic                      := '0';             --! Data valid for the ADC devices
-- signal ADC_GAINSEL             : std_logic_vector( 7 downto 0)  := (others => '0'); --! AD8251 Gain Select --GBC:20190321

signal s_ADC_CNV                : std_logic                      := '0';             --! ADC Convert Control
signal START_CONVERT            : std_logic                      := '0';             --! Clock Edge Detected
signal CONVERSION_IN_PROGRESS   : std_logic                      := '0';             --! Conversion In progress disable clock reception

signal ADC_DATA_VALID_SPI       : std_logic                      := '0';             --! Data valid for the ADC devices from the SPI logic
signal ADC_DATAOUT_SPI          : std_logic_vector(31 downto 0)  := (others => '0'); --! Serial-to-Parallel Data from the SPI logic

--signal CLOCK_EST_COUNTER        : unsigned(27 downto 0)          := (others => '0'); --! Clock Speed Estimator Counter --GBC:20190321
--signal CLOCK_EST_COUNTER_LATCH  : std_logic_vector(27 downto 0)  := (others => '0'); --! Clock Speed Estimator Counter Latched --GBC:20190321
--signal CLOCK_EST_THECLK_IN      : std_logic;                                         --! Clock Speed Estimator Clock --GBC:20190321
--signal CLOCK_EST_d0             : std_logic;                                         --! Clock Speed Estimator Clock debounced against the 100M Clock --GBC:20190321
--signal CLOCK_EST_d1             : std_logic;                                         --! Clock Speed Estimator Clock debounced against the 100M Clock --GBC:20190321
--signal CLOCK_EST_CLKSRC         : std_logic_vector(2 downto 0)   := (others => '0'); --! Clock Speed Estimator Clock Source selector --GBC:20190321
--signal CLR_CLOCK_EST_COUNTER    : std_logic;                                         --! Clear the Estimator on Base Timer Rollover --GBC:20190321
--signal CLOCK_EST_EXT_n          : std_logic;                                         --! Clock Estimator measuring Divider source or External Signal --GBC:20190321

--signal SAMPLE_CLOCK_COUNTER     : unsigned(15 downto 0)          := (others => '0'); --! Sample Clock Period Counter --GBC:20190321
--signal SAMPLE_CLOCK_MIN         : unsigned(15 downto 0)          := (others => '1'); --! Sample Clock Minimum Period Value --GBC:20190321
--signal SAMPLE_CLOCK_MAX         : unsigned(15 downto 0)          := (others => '0'); --! Sample Clock Maximum Period Value --GBC:20190321
--signal SAMPLE_CLOCK_SHOT_LENGTH : unsigned(31 downto 0)          := (others => '1'); --! Time to run the Sample Clock Min Max Logic --GBC:20190321

--signal SAMPLE_COUNTER           : unsigned(31 downto 0)          := (others => '0'); --! Samples since Trigger Counter --GBC:20190321
--signal SAMPLE_COUNTER_LATCH     : std_logic_vector(31 downto 0)  := (others => '0'); --! Samples since Trigger Counter --GBC:20190321


signal s_CLK_GEN_CLK            : std_logic                      := '0';             --! Generated Clock for the ADCs
signal CLKDIV_COUNTER           : std_logic_vector(15 downto 0)  := (others => '0'); --! Divide the Selected Clock for use as the Internal Sample Clock
signal CLKDIV_COUNTER_RESET     : std_logic;                                         --! Reset the Counter
--signal DIVIDE2                  : std_logic_vector(15 downto 0);                     --! Divide by 2 calculation to get close to 50/50 duty cycle --GBC:20190321

signal NUMBER_OF_CHANNELS       : std_logic_vector(4 downto 0)   := "00011";         --! Number of channels active

signal ADC_DATAOUT_PCAP         : std_logic_vector(255 downto 0) := (others => '0');

signal FAST_ADC_WR_EN           : std_logic;

--------------------------------------------------------------------------------------
-- debug test using mark_debug
---------------------------------------------------------------------------------------
--attribute mark_debug : string; --GBC:20190321
--attribute keep : string; --GBC:20190321

begin

-- Decode of Register Control bits
ADC_RESET           <= ADC_RESET_REG(0);
ADC_FIFO_ENABLE     <= ADC_FIFO_ENABLE_REG(0);
ADC_FIFO_RESET      <= ADC_FIFO_RESET_REG(0);
ADC_ENABLE          <= ADC_ENABLE_REG(0);
ADC_CLK_DIV         <= ADC_CLKDIV_REG(15 downto 0);

FAST_ADC_WR_EN      <= FIFO_DATA_WRITE and ADC_FIFO_ENABLE;

--! ADC Buffer FIFO using Xilinx IP Module  to move between ADC Clock Domain and AXI Clock Domain
FAST_ADC_MEMORY : fmc_acq430_ch_fifo
port map (
    rst         => ADC_FIFO_RESET,
    wr_clk      => clk_PANDA,
    rd_clk      => clk_PANDA,
    din         => FIFO_DATAIN,
    wr_en       => FAST_ADC_WR_EN,
    rd_en       => FIFO_RD_EN,
    dout        => ADC_DATAOUT_PCAP,
    full        => ADCCLK_FIFO_FULL,
    empty       => FIFO_EMPTY,
    rd_data_count => ADC_FIFO_COUNT_DATA
);

FIFO_DATAIN     <= ADC_DOUT;
FIFO_DATA_WRITE <= ADC_FIFOWRITE;
ADC_DATAOUT     <= ADC_DATAOUT_PCAP;

PCAP_READ_FIFO : process(clk_PANDA)
begin
    if rising_edge(clk_PANDA) then
        if ADC_FIFO_COUNT_DATA >= "00001" then
            FIFO_RD_EN <= '1';
        else
            FIFO_RD_EN <= '0';
        end if;
    end if;
end process;

--! This process is used to cross from the AXI to the ADC Clock domains for register bits that are required in the other domain.
Cross_Clock_Buffer : Process(clk_SEL)
begin
    if Rising_Edge(clk_SEL) then
        ADCCLK_CLKDIV_DATA  <=  ADC_CLK_DIV;
--        ADCCLK_GAINSEL_DATA <=  ADC_GAINSEL_DATA; --GBC:20190321
    end if;
end process;

-- Decode of Register Control bits
--ADC_GAINSEL   <= ADCCLK_GAINSEL_DATA; --GBC:20190321
ADC_CONV_TIME <= x"44";

--ADC_A1 <= ADC_GAINSEL(7) &  ADC_GAINSEL(5) & ADC_GAINSEL(3) & ADC_GAINSEL(1);           -- de-interleave the gain settings --GBC:20190321
--ADC_A0 <= ADC_GAINSEL(6) &  ADC_GAINSEL(4) & ADC_GAINSEL(2) & ADC_GAINSEL(0);                                              --GBC:20190321

--*************************************************************************************************************************
--clk_SEL Domain
--*************************************************************************************************************************


-- Commented out by GBC: 21/03/2019
--SEL_CLK_SEL : BUFGMUX
--    port map (O     => clk_SEL,
--            I0  => clk_PANDA,
--            I1  => EXT_CLOCK,
--            S   => ADC_CLK_SELECT_REG(0));

clk_SEL <= clk_PANDA;

--! Sync the ADC_RESET to the selected Clock
ADC_RESET_RESYNC: process(clk_SEL)
begin
    if Rising_edge(clk_SEL) then
        CLK_SEL_ADC_RESET   <= ADC_RESET;
    end if;
end process ADC_RESET_RESYNC;

CLKDIV_COUNTER_RESET <= CLK_SEL_ADC_RESET;

--! This Process Described the Main Divider
--MAINDIV: process (clk_SEL, ADCCLK_CLKDIV_DATA) --GBC:20190321
MAINDIV: process (clk_SEL)
begin
--    DIVIDE2 <=  std_logic_vector(unsigned('0' & ADCCLK_CLKDIV_DATA(15 downto 1)) + 1);
    if Rising_edge(clk_SEL) then
        if CLKDIV_COUNTER_RESET = '1' then
            CLKDIV_COUNTER <= ADCCLK_CLKDIV_DATA;
        elsif CLKDIV_COUNTER = X"0001" then
            CLKDIV_COUNTER <= ADCCLK_CLKDIV_DATA;               -- Normal Reload
        else
            CLKDIV_COUNTER <= std_logic_vector(unsigned(CLKDIV_COUNTER) - 1);      -- Count Down
        end if;
    end if;
end process MAINDIV;

--! This Process describes the clock output
CLKOUTPUT: process (clk_SEL)
    variable DIVIDE2 : std_logic_vector(15 downto 0);
begin
    if Rising_edge(clk_SEL) then
        DIVIDE2 :=  std_logic_vector(unsigned('0' & ADCCLK_CLKDIV_DATA(15 downto 1)) + 1);
        if CLKDIV_COUNTER_RESET = '1' then
            s_CLK_GEN_CLK <= '0';
        elsif CLKDIV_COUNTER = DIVIDE2   then
            s_CLK_GEN_CLK <= '0';
        elsif CLKDIV_COUNTER = X"0001" then
            s_CLK_GEN_CLK <= '1';
        end if;
    end if;
end process CLKOUTPUT;


--! This process controls the bypass should the divider be set to 1
BYPASS_DIVIDER: process(ADC_CLK_DIV,clk_SEL,s_CLK_GEN_CLK)
begin
    if ADC_CLK_DIV = x"0001" then
        DIV_CLK <= clk_SEL;
        --DIV_CLK_SEL <= '0'; --GBC:20190321 (unused)
    else
        DIV_CLK <= s_CLK_GEN_CLK;
        --DIV_CLK_SEL <= '1'; --GBC:20190321 (unused)
    end if;
end process BYPASS_DIVIDER;

--! Similar to previous Successive Approximation ADC based products the convert pulse needs to be a mixed Asynchronous / Synchronous Signal
--! It's rising edge needs to be set asynchronously by the sample clock then cleared after the logic has detected the edge. The clock reception
--! is also disabled until after the read back logic has completed to avoid illegal clocking
GEN_CONV_PULSE:  process(ADC_ENABLE,CONVERSION_IN_PROGRESS,ADC_CLK_CURRENT,DIV_CLK)
begin
    if CONVERSION_IN_PROGRESS = '0' and ADC_ENABLE = '1' then
        if ADC_CLK_CURRENT = '0' then
            s_ADC_CNV <= DIV_CLK;           -- Runt clocks may cause ADC problems
        else
            s_ADC_CNV <= '0';
        end if;
    else
        s_ADC_CNV <= '0';
    end if;
end process GEN_CONV_PULSE;

-- Debounce the Sample Clock to remove glitches. When in 100 MHz domain debounce 4, when in 66 MHz debounce 3
DEBOUNCE_SAMPLE_CLOCK: process(clk_PANDA)
begin
    if Rising_edge(clk_PANDA) then
        ADC_CLK(0) <= DIV_CLK;                                  -- debounce
        ADC_CLK(1) <= ADC_CLK(0);                               -- De-bounce 2
        ADC_CLK(2) <= ADC_CLK(1);                               -- De-bounce 3
        ADC_CLK(3) <= ADC_CLK(2);                               -- De-bounce 4
        if ADC_CLK_CURRENT = '0' and ADC_CLK = "1111"  then     -- Rising Edge
            ADC_CLK_CURRENT <= '1';
        elsif ADC_CLK_CURRENT = '1' and ADC_CLK = "0000"  then  -- Falling Edge
            ADC_CLK_CURRENT <= '0';
        end if;
    end if;
end process DEBOUNCE_SAMPLE_CLOCK;

ADC_CNV <= s_ADC_CNV;

--CLOCK_EST_THECLK_IN <= DIV_CLK;

-- Detect the rising edge of the Sample Clock to synchronise all counters too
ADC_CLK_RISING_EDGE: process(clk_PANDA,ADC_CLK_CURRENT_d1,ADC_CLK_CURRENT)
begin
    if Rising_edge(clk_PANDA) then
        ADC_CLK_CURRENT_d1 <= ADC_CLK_CURRENT;
    end if;
    if ADC_CLK_CURRENT = '1' and ADC_CLK_CURRENT_d1 = '0' then
        ADC_CLK_RISING <= '1';
    else
        ADC_CLK_RISING <= '0';
    end if;
end process ADC_CLK_RISING_EDGE;

START_CONVERT <= '1' when ADC_ENABLE = '1' and ADC_CLK_RISING = '1' and CONVERSION_IN_PROGRESS = '0' else '0' ;


SET_CON_ACTIVE: process(clk_PANDA)
begin
    if Rising_edge(clk_PANDA) then
        if ADC_ENABLE = '0' then        -- switch off when ACQ_ENABLE falls Trigger is don't care once on
            CONV_ACTIVE <= '0';
        elsif ADC_CLK_RISING = '1' then -- switch ON, on a clock edge
            CONV_ACTIVE <= '1';
        end if;
    end if;
end process SET_CON_ACTIVE;


--! Simple Counter that allows the software to Estimate a Clock Frequency
--THE_CLOCK_ESTIMATOR: process(clk_PANDA)
--begin
--    if Rising_edge(clk_PANDA) then
--        CLOCK_EST_d1 <=  CLOCK_EST_d0;
--        CLOCK_EST_d0 <=  CLOCK_EST_THECLK_IN;
--        if CLOCK_EST_D0 = '1' and CLOCK_EST_D1 = '0' then
--            CLOCK_EST_COUNTER <= CLOCK_EST_COUNTER + 1;
--        end if;
--    end if;
--end process THE_CLOCK_ESTIMATOR;

--! Simple Counter that counts the number of Samples acquired since CON_ACTIVE
--THE_SAMPLE_COUNTER: process(clk_PANDA)
--begin
--    if Rising_edge(clk_PANDA) then
--        if ADC_CLK_RISING = '1' then
--            if CONV_ACTIVE = '0'  then
--                SAMPLE_COUNTER <= (others => '0');
--            else
--                SAMPLE_COUNTER <= SAMPLE_COUNTER + 1;
--            end if;
--        end if;
--    end if;
--end process THE_SAMPLE_COUNTER;


--************************************************************************************************************************
-- Clock Domain Crossing  clk_AXI for read back
--*************************************************************************************************************************

--! De-bounce the counters against the AXI clock to ensure no meta-stable bits in the software read
--DEBOUNCE_THE_COUNTERS: process(clk_PANDA)
--begin
--    if Rising_edge(clk_PANDA) then
--        CLOCK_EST_COUNTER_LATCH <= std_logic_vector(CLOCK_EST_COUNTER);
--        SAMPLE_COUNTER_LATCH <= std_logic_vector(SAMPLE_COUNTER);
--    end if;
--end process DEBOUNCE_THE_COUNTERS;

clk_ADC_IOB     <=  clk_PANDA;

ADC_DOUT        <= ADC_DATAOUT_SPI;
ADC_FIFOWRITE   <= ADC_DATA_VALID_SPI;

--! ADC SPI Logic
THE_ACQ427FMC: entity work.ACQ427FMC_ADC_SPI(RTL)
    port map (
    clk_SPI             => clk_PANDA,                   -- 125 MHz source clock to be used as SPI Clock for the ADCs
    RESET               => ADC_RESET,                   -- ADC System Reset
    ADC_ENABLE          => ADC_ENABLE,                  -- Acquisition Enable to enable the ADC Conversion Logic
    ADC_RESOLUTION      => ADC_RESOLUTION,              -- Shift 24/20/18/16 bits of data from the ADCs
    DATA_SIZE           => DATA_SIZE,                   -- Pack data in 32/16 bits
    CONV_TIME           => ADC_CONV_TIME,               -- Number of clock ticks between convert and read back this is 540nS at 100MHz
    CONV_ACTIVE         => CONV_ACTIVE,                 -- Allow the Logic to store the converted data
--    SAMPLE_COUNTER      => SAMPLE_COUNTER,              -- Sample Count since Initial Trigger
    START_CONVERT       => START_CONVERT,               -- Clock Edge Detected
    CONVERSION_IN_PROGRESS  => CONVERSION_IN_PROGRESS,  -- Conversion In progress disable clock reception
    ADC_SPI_CLK         => ADC_SPI_CLK,                 -- ADC SPI Clock
    ADC_SDO             => ADC_SDO,                     -- ADC SPI Data
    ADC_DATAOUT         => ADC_DATAOUT_SPI,             -- ADC Data converted to parallel format
    ADC_DATA_VALID      => ADC_DATA_VALID_SPI           -- Data valid for the ADC devices
    );


end RTL;
