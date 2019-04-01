---------------------------------------------------------------------------------------
--! @file
--! @brief    ACQ430FMC Module Address Decode and Control - PandA
--! @author   John McLean / Scott Robson
--! @date     29th August 2017
--! @details                                                                                                                            \n
--! D-TACQ Solutions Ltd Copyright 2014-2017                                                                    \n
--!                                                                                                                                         \n

--! Standard Libraries - numeric.std for all designs
library ieee;
use ieee.std_logic_1164.all; --! Standard Logic Functions
use ieee.numeric_std.all; --! Numeric Functions for Signed / Unsigned Arithmetic

--! Xilinx Primitive Library
library UNISIM;
use UNISIM.VComponents.all;     -- Xilinx Primitives

--! Local Functions and Types
use work.ACQ430TYPES.all; --! Local Types

--! ACQ430FMC Interface, Register Decode and Data FIFO
entity ACQ430FMC_INTERFACE is
port(
     clk_PANDA                  : in  std_logic;                                         --! ADC Clock for ADC Timing from the Zynq Core

     --EXT_CLOCK                  : in  std_logic;                                         --! External Clock - Tied Off --GBC:20190321
     FMC_IO_BUS                 : out std_logic_vector(4 downto 0);      --! FMC IO Controls (FMC_LEMO_ROLE,CLOCK_DAT,CLOCK_DIR,TRIG_DAT,TRIG_DIR)
-- Connections to PandA registers
     ADC_MODE_REG               : in std_logic_vector(31 downto 0);
     --CLK_SELECT_REG             : in std_logic_vector(31 downto 0); --GBC:20190321
     ADC_CLKDIV_REG             : in std_logic_vector(31 downto 0);
     FIFO_RESET_REG             : in std_logic_vector(31 downto 0);
     FIFO_ENABLE_REG    : in std_logic_vector(31 downto 0);
     ADC_RESET_REG              : in std_logic_vector(31 downto 0);
     ADC_ENABLE_REG             : in std_logic_vector(31 downto 0);
-- Connections to the Physical ADCs
     clk_SPI_OUT                : out std_logic;                                         --! ADC SPI Clk for IOBs
     SPI_CLOCK_ENABLE   : out std_logic;                                         --! ADC SPI Clock Enable
     ADC_SDO                    : in  std_logic;                                         --! ADC SPI Data
     ADC_SYNC_n                 : out std_logic;                                         --! ADC Inter-Device Synchronisation
     ADC_FSYNC                  : out std_logic;                                         --! ADC Frame Sync for start of Sample

     ADC_DATAOUT        : out std_logic_vector(255 downto 0) --! 8 Channels of ADC Dataout for connection to Position Bus
        );
end ACQ430FMC_INTERFACE;


architecture RTL of ACQ430FMC_INTERFACE is

component fmc_acq430_ch_fifo is
  Port (
    rst           : in  STD_LOGIC;
    wr_clk        : in  STD_LOGIC;
    rd_clk        : in  STD_LOGIC;
    din           : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    wr_en         : in  STD_LOGIC;
    rd_en         : in  STD_LOGIC;
    dout          : out STD_LOGIC_VECTOR ( 255 downto 0 );
    full          : out STD_LOGIC;
    empty         : out STD_LOGIC;
    rd_data_count : out STD_LOGIC_VECTOR ( 4 downto 0 )
  );
end component;

--*************************************************************************************************************************
-- AXI_clk Domain signals
--*************************************************************************************************************************

signal FIFO_EMPTY                   : std_logic                                     := '0';                              --! FIFO EMPTY         signal: to      REGISTERS
signal FIFO_RD_EN                   : std_logic                     := '0';              --! FIFO Read control

--Register Data
signal ADC_FIFO_COUNT_DATA          : std_logic_vector(4 downto 0)  := (others => '0');  --! ADC Sample Count Register Data
signal ADC_MODE_DATA                : std_logic_vector( 4 downto 0) := (others => '0');  --! ADC Mode Setting Register
signal ADC_TRANSIENT_LENGTH_DATA    : std_logic_vector(23 downto 0) := (others => '0');  --! ADC Transient Length Register

--*************************************************************************************************************************
-- ADC_clk Domain
--*************************************************************************************************************************

signal ADCCLK_MODE_DATA             : std_logic_vector( 4 downto 0) := (others => '0'); --! ADC Mode Control Setting Register

-- PandA Register Controlled Signals
signal ADC_FIFO_ENABLE              : std_logic                     := '0';
signal ADC_FIFO_RESET               : std_logic                     := '0';
signal ADC_RESET                    : std_logic                     := '0';             --! ADC Reset
signal ADC_ENABLE                                       : std_logic                                         := '0';                             --! Acquisition Enable
signal ADC_CLK_DIV                                      : std_logic_vector(15 downto 0);                                        --! Clock Divider to generate ADC Sample Clock

signal FIFO_DATAIN                  : std_logic_vector(31 downto 0) := (others => '0');
signal FIFO_DATA_WRITE              : std_logic                     := '0';

signal ADCCLK_FIFO_FULL             : std_logic                     := '0';             --! FIFO FULL       signal on the IP is in the Write Clock Domain

signal clk_SEL                      : std_logic;                                        --! Clock Selected from Either EXT_SEL or the 100M Zynq Clock
--signal DIV_CLK                      : std_logic;                                        --! Divided Down Clock for Asynchronous Logic --GBC:20190321
signal DIV_CLK_SEL                  : std_logic;                                        --! Select between Divided Down Clock and input clock for the special case of divide by 1
signal clk_DIV                      : std_logic;                                        --! Divided Down Clock for Synchronous Logic - If no divide this is clk_SEL

signal HW_SYNC_EN                   : std_logic                     := '0';             --! External Sync Enable
signal HW_SYNC_EN_MOD               : std_logic;                                        --! External Sync Enable
signal HW_SYNC                      : std_logic;                                        --! External Sync Signal

signal GEN_SYNC_OUT                 : std_logic;                                        --! Internally Generated Sync
signal EXT_SYNC_OUT                 : std_logic;                                        --! Index Generator Output to the Sync Bus
signal STARTUP_COMPLETE             : std_logic;                                        --! Start up has reached the number of samples to initialise the ADCs

signal TRIG_SYNC_DELAY              : std_logic                     := '0';             --! Trigger Delayed by the group delay
signal DELAY_COUNTER                : unsigned(7 downto 0)          := (others => '0'); --! Trigger/Event Delay Counter
signal DELAY_VALUE                  : unsigned(7 downto 0)          := (others => '0'); --! Trigger/Event Delay Value

signal CONV_ACTIVE                  : std_logic;                                        --! Conversion Active - Enabled AND Triggered

signal ADC_DOUT                                         : std_logic_vector(31 downto 0) := (others => '0');     --! ADC Data converted to parallel format
signal ADC_FIFOWRITE                            : std_logic                                         := '0';                             --! Data valid for the 4 ADC devices

--signal CLOCK_EST_COUNTER          : unsigned(27 downto 0)         := (others => '0');     --! Clock Speed Estimator Counter --GBC:20190321
--signal CLOCK_EST_COUNTER_LATCH    : std_logic_vector(27 downto 0) := (others => '0');     --! Clock Speed Estimator Counter --GBC:20190321
--signal CLOCK_EST_THECLK_IN        : std_logic;                                            --! Clock Speed Estimator Clock --GBC:20190321
--signal CLOCK_EST_d0               : std_logic;                                            --! Clock Speed Estimator Clock debounced against the 100M Clock --GBC:20190321
--signal CLOCK_EST_d1               : std_logic;                                            --! Clock Speed Estimator Clock debounced against the 100M Clock --GBC:20190321

--signal SAMPLE_CLOCK_COUNTER       : unsigned(31 downto 0)         := (others => '0');     --! Time Count in Sample Clocks since Initial Trigger --GBC:20190321
--signal SAMPLE_COUNTER             : unsigned(31 downto 0)         := (others => '0');     --! Sample Count since Initial Trigger --GBC:20190321
--signal SAMPLE_CLOCK_COUNTER_LATCH : std_logic_vector(31 downto 0) := (others => '0');     --! Time Count in Sample Clocks since Initial Trigger --GBC:20190321
--signal SAMPLE_COUNTER_LATCH       : std_logic_vector(31 downto 0) := (others => '0');     --! Sample Count since Initial Trigger --GBC:20190321

signal ADC_FSYNC_INT                            : std_logic;                                                                            --! local copy ADC Frame Sync for start of Sample

signal s_CLK_GEN_CLK                    : std_logic;                                                            --! Generated Clock for the ADCs
signal CLKDIV_COUNTER                   : std_logic_vector  (15 downto 0);                          --! Divide the Selected Clock for use as the Internal Sample Clock
signal CLKDIV_COUNTER_RESET             : std_logic;                                                            --! Reset the Counter
--signal DIVIDE2                                  : std_logic_vector  (15 downto 0);                          --! Divide by 2 calculation to get close to 50/50 duty cycle --GBC:20190321


--clk_SEL Clock Domain

type STATE_DIV_SYNC is (
                                DIV_IDLE,       --! Idle State everything off
                                DIV_ENABLE,     --! ADC_ENABLE
                                DIV_SYNC,       --! Reset the Divider
                                DIV_RUN         --! Run the Divider
                                );

signal DIV_STATE,NEXT_DIV_STATE : STATE_DIV_SYNC; --! State Machine variables

signal SAMPLE_SIZE                              : std_logic_vector(7 downto 0); --! Calculation Result of the number of LWords per Sample

signal ADC_DATAOUT_PCAP         : std_logic_vector(255 downto 0) := (others => '0');

--------------------------------------------------------------------------------------
-- debug test using mark_debug
---------------------------------------------------------------------------------------
--attribute mark_debug : string;
attribute keep : string;

-- For signals that are constrained need keep attribute as the synthesiser can change the name on us .....
attribute keep of clk_SEL                               : signal is "true";

begin


process (clk_PANDA) begin
    if rising_edge(clk_PANDA) then
        -- Decode of Register Control bits
        ADC_RESET        <= ADC_RESET_REG(0);
        ADC_FIFO_ENABLE  <= FIFO_ENABLE_REG(0);
        ADC_FIFO_RESET   <= FIFO_RESET_REG(0);
        ADC_ENABLE       <= ADC_ENABLE_REG(0);
        ADC_MODE_DATA(4) <= ADC_MODE_REG(0);
        ADC_CLK_DIV      <= ADC_CLKDIV_REG(15 downto 0);
    end if;
end process;


-- In the ACQ430 the Sample Size is fixed
SAMPLE_SIZE <= X"08";


--! ADC Buffer FIFO using Xilinx IP Module  to move between ADC Clock Domain and AXI Clock Domain
FAST_ADC_MEMORY : fmc_acq430_ch_fifo
port map (
    rst             => ADC_FIFO_RESET,
    wr_clk          => clk_DIV,
    rd_clk          => clk_PANDA,
    din             => FIFO_DATAIN,
    wr_en           => FIFO_DATA_WRITE and ADC_FIFO_ENABLE,
    rd_en           => FIFO_RD_EN,
    dout            => ADC_DATAOUT_PCAP,
    full            => ADCCLK_FIFO_FULL,
    empty           => FIFO_EMPTY,
    rd_data_count   => ADC_FIFO_COUNT_DATA
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
Cross_Clock_Buffer_ADC : Process(clk_SEL)
begin
    if Rising_Edge(clk_SEL) then
        ADCCLK_MODE_DATA              <=   ADC_MODE_DATA;
    end if;
end process Cross_Clock_Buffer_ADC;





--############################################################
--################## Begin Clocking Section ##################
-- commented GBC:20190321
--SEL_CLK_SEL : BUFGMUX
--        port map (O     => clk_SEL,
--                          I0    => clk_PANDA,
--                          I1    => EXT_CLOCK,
--                          S     => CLK_SELECT_REG(0));

clk_SEL <= clk_PANDA;


--! Update the States
DIV_STATE_UPDATE: process(clk_SEL)
begin
    if  Rising_edge(clk_SEL) then
            if ADC_RESET = '1' then     -- put the main control state here for ease of coding
                DIV_STATE <= DIV_IDLE;
            else
                DIV_STATE <= NEXT_DIV_STATE;
            end if;
    end if;
end process DIV_STATE_UPDATE;

--! State Machine to produce a since clock wide reset pulse on start-up or if in external sync from the first external sync pulse
--DIV_STATE_TRANSITION: process(DIV_STATE,NEXT_DIV_STATE,ADC_ENABLE,HW_SYNC,HW_SYNC_EN) --GBC:20190321
DIV_STATE_TRANSITION: process(DIV_STATE,HW_SYNC,HW_SYNC_EN)
begin
NEXT_DIV_STATE <= DIV_STATE;
    case DIV_STATE is
            when DIV_IDLE       =>
                --if ADC_ENABLE = '1' then
                        NEXT_DIV_STATE <= DIV_ENABLE;
                --end if;
                CLKDIV_COUNTER_RESET <= '0';

            when DIV_ENABLE     =>
                if ((HW_SYNC_EN = '0') or (HW_SYNC = '1' and HW_SYNC_EN = '1')) then
                        NEXT_DIV_STATE <= DIV_SYNC;
                end if;
                CLKDIV_COUNTER_RESET <= '0';

            when DIV_SYNC       =>
                NEXT_DIV_STATE <= DIV_RUN;
                CLKDIV_COUNTER_RESET <= '1';

            when DIV_RUN =>
                CLKDIV_COUNTER_RESET <= '0';
    end case;
end process DIV_STATE_TRANSITION;


HW_SYNC_EN_MOD <= HW_SYNC_EN;

--! This Process Described the Main Divider
--MAINDIV: process (clk_SEL,CLKDIV_COUNTER_RESET,ADC_CLK_DIV,CLKDIV_COUNTER,DIVIDE2) --GBC:20190321
MAINDIV: process (clk_SEL)
begin
--    DIVIDE2 <=  std_logic_vector(unsigned('0' & ADC_CLK_DIV(15 downto 1)) + 1); --GBC:20190321
        if Rising_edge(clk_SEL) then
                if CLKDIV_COUNTER_RESET = '1' then
                        CLKDIV_COUNTER <= ADC_CLK_DIV;
                elsif CLKDIV_COUNTER = X"0001" then
                        CLKDIV_COUNTER <= ADC_CLK_DIV; -- Normal Reload
                else
                        CLKDIV_COUNTER <= std_logic_vector(unsigned(CLKDIV_COUNTER) - 1); -- Count Down
                end if;
        end if;
end process MAINDIV;

--! This Process describes the clock output
CLKOUTPUT: process (clk_SEL)
    variable DIVIDE2 : std_logic_vector(15 downto 0);
begin
    if Rising_edge(clk_SEL) then
        DIVIDE2 :=  std_logic_vector(unsigned('0' & ADC_CLK_DIV(15 downto 1)) + 1);
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
-- BYPASS_DIVIDER: process(ADC_CLK_DIV,clk_SEL,s_CLK_GEN_CLK) --GBC:20190321
BYPASS_DIVIDER: process(ADC_CLK_DIV)
begin
    if ADC_CLK_DIV = x"0001" then
--            DIV_CLK <= clk_SEL; --GBC:20190321
            DIV_CLK_SEL <= '0';
    else
--            DIV_CLK <= s_CLK_GEN_CLK; --GBC:20190321
            DIV_CLK_SEL <= '1';
    end if;
end process BYPASS_DIVIDER;


SET_DELAY_VALUE: process(clk_DIV)
begin
    if Rising_edge(clk_DIV) then
            if ADCCLK_MODE_DATA(4) = '1' then                   -- Hi Res mode
                    if CONV_ACTIVE = '1' then
                            DELAY_VALUE <= c_GROUP_DELAY_HI_RES;
                    else
                            DELAY_VALUE <= c_TRIGGER_DELAY_HI_RES;
                    end if;
            else                                                                        -- Hi Speed Mode
                    if CONV_ACTIVE = '1' then
                            DELAY_VALUE <= c_GROUP_DELAY_HI_SPEED;
                    else
                            DELAY_VALUE <= c_TRIGGER_DELAY_HI_SPEED;
                    end if;
            end if;
    end if;
end process SET_DELAY_VALUE;

--! Delay Triggers and Events by the group delay of the ADS1278
DELAY_TRIGGER_AND_EVENTS: process(clk_DIV)
begin
    if Rising_edge(clk_DIV) then
            if ADC_ENABLE = '0' then
                    DELAY_COUNTER       <= (others => '0');
            else
                    if GEN_SYNC_OUT  = '1'  then
                            DELAY_COUNTER <= DELAY_COUNTER + 1;
                    end if;
            end if;

            if ADC_ENABLE = '0' then
                    TRIG_SYNC_DELAY     <= '0';
            elsif DELAY_COUNTER = DELAY_VALUE then
                    TRIG_SYNC_DELAY     <= '1';
            else
                    TRIG_SYNC_DELAY     <= '0';
            end if;
    end if;
end process DELAY_TRIGGER_AND_EVENTS;


SEL_CLK_DIV : BUFGMUX
        port map (O     => clk_DIV,
                          I0    => clk_SEL,
                          I1    => s_CLK_GEN_CLK,
                          S     => DIV_CLK_SEL);


--CLOCK_EST_THECLK_IN <= DIV_CLK; --GBC:20190321


--################## End Clocking Section ##################
--##########################################################


SET_CON_ACTIVE: process(clk_DIV)
begin
    if Rising_edge(clk_DIV) then
--          if  HW_TRIG_EN = '0' and not g_SLAVE_MODE then      -- If internal trigger then start with enable unless a slave
--                  CONV_ACTIVE <= ADC_ENABLE;
--          elsif ADC_ENABLE = '0' then                                         -- Only switch of when ACQ_ENABLE is on Trigger is don't care once on
            if ADC_ENABLE = '0' then                                            -- Only switch of when ACQ_ENABLE is on Trigger is don't care once on
                    CONV_ACTIVE <= '0';
--          elsif ADC_ENABLE = '1' and TRIG_SYNC_OUT = '1' then -- Only Start when active and trigger detected
            elsif ADC_ENABLE = '1' and TRIG_SYNC_DELAY = '1' then -- Only Start when active and trigger detected
                    CONV_ACTIVE <= '1';
            end if;
    end if;
end process SET_CON_ACTIVE;
--GBC:20190321
--! Simple Counter that allows the software to Estimate a Clock Frequency
--THE_CLOCK_ESTIMATOR: process(clk_PANDA)
--begin
--    if Rising_edge(clk_PANDA) then
--            CLOCK_EST_d1 <=  CLOCK_EST_d0;
--            CLOCK_EST_d0 <=  CLOCK_EST_THECLK_IN;
--            if CLOCK_EST_D0 = '1' and CLOCK_EST_D1 = '0' then
--                CLOCK_EST_COUNTER <= CLOCK_EST_COUNTER + 1;
--            end if;
--    end if;
--end process THE_CLOCK_ESTIMATOR;


--! Simple Counter that counts the number of Samples acquired since CON_ACTIVE
--THE_SAMPLE_CLOCK_COUNTERS: process(clk_DIV)
--begin
--    if Rising_edge(clk_DIV) then
--            if CONV_ACTIVE = '0'  then
--                    SAMPLE_CLOCK_COUNTER <= (others => '0');
--                    SAMPLE_COUNTER <= (others => '0');
--            elsif ADC_FSYNC_INT /= '0' then
--                    SAMPLE_CLOCK_COUNTER <= SAMPLE_CLOCK_COUNTER + 1;
--                    SAMPLE_COUNTER <= SAMPLE_COUNTER + 1;
--            end if;
--    end if;
--end process THE_SAMPLE_CLOCK_COUNTERS;



--************************************************************************************************************************
-- Clock Domain Crossing  back to clk_PANDA
--*************************************************************************************************************************
--DEBOUNCE_THE_COUNTER: process(clk_PANDA,CLOCK_EST_COUNTER,SAMPLE_CLOCK_COUNTER)
--begin
--    if Rising_edge(clk_PANDA) then
--            CLOCK_EST_COUNTER_LATCH <= std_logic_vector(CLOCK_EST_COUNTER);
--            SAMPLE_CLOCK_COUNTER_LATCH <= std_logic_vector(SAMPLE_CLOCK_COUNTER);
--            SAMPLE_COUNTER_LATCH <= std_logic_vector(SAMPLE_COUNTER);
--    end if;
--end process DEBOUNCE_THE_COUNTER;


clk_SPI_OUT <= clk_DIV;

--! ADC logic including SPI logic, ADC timing
ADC_LOGIC : entity work.ACQ430FMC_FUNC
port map(
     clk_SPI                    => clk_DIV,
        ADC_ENABLE                      => ADC_ENABLE,
        ADC_RESET                       => ADC_RESET,
        FIFO_ENABLE                     => ADC_FIFO_ENABLE,
        FIFO_RESET                      => ADC_FIFO_RESET,
        CONV_ACTIVE                     => CONV_ACTIVE,
        ADC_MODE                        => ADCCLK_MODE_DATA,
        HW_SYNC                         => HW_SYNC,
        HW_SYNC_EN                      => HW_SYNC_EN_MOD,
        GEN_SYNC_OUT            => GEN_SYNC_OUT,
        EXT_SYNC_OUT            => EXT_SYNC_OUT,
        ADC_FSYNC_INT           => ADC_FSYNC_INT,
        STARTUP_COMPLETE        => STARTUP_COMPLETE,
        ADC_DATAOUT                     => ADC_DOUT,
        ADC_FIFOWRITE           => ADC_FIFOWRITE,

        SPI_CLOCK_ENABLE        => SPI_CLOCK_ENABLE,
        ADC_SDO                         => ADC_SDO,
        ADC_SYNC_n                      => ADC_SYNC_n,
        ADC_FSYNC                       => ADC_FSYNC
);


end RTL;
