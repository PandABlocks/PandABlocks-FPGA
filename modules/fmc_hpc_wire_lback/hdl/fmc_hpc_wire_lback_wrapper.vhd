--------------------------------------------------------------------------------
--  	NAMC - 2020
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Arthur Mariano
--------------------------------------------------------------------------------
--
--  Description : FMC Loopback Design for transceiver : SFP1 wired with SFP2
--
--                This module must be used with techway FMC-SFP/SFP+_104
--                                
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity fmc_hpc_wire_lback_wrapper is
port (
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Standard FMC Block ports, do not add to or delete
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    FMC_i               : in    fmc_input_interface;
    FMC_io              : inout fmc_inout_interface;
    FMC_o               : out   fmc_output_interface

);
end fmc_hpc_wire_lback_wrapper;

architecture rtl of fmc_hpc_wire_lback_wrapper is

signal probe0               : std_logic_vector(31 downto 0);
signal clock_en             : std_logic;
signal test_clocks          : std_logic_vector(3 downto 0);
signal LINK_UP_1            : std_logic_vector(31 downto 0);
signal LINK_UP_2            : std_logic_vector(31 downto 0);
signal LINK_UP_3            : std_logic_vector(31 downto 0);
signal ERROR_COUNT_1        : std_logic_vector(31 downto 0);
signal ERROR_COUNT_2        : std_logic_vector(31 downto 0);
signal ERROR_COUNT_3        : std_logic_vector(31 downto 0);
signal FMC_HB20_P			: std_logic;
signal FMC_HB20_N			: std_logic;
signal FMC_HB21_P			: std_logic;
signal FMC_HB21_N			: std_logic;
signal I2C_SDA            	: std_logic;
signal I2C_SDA_OE           : std_logic;
signal I2C_SDA_IN           : std_logic;
signal I2C_SDA_OUT          : std_logic;
signal I2C_SDA_C           	: std_logic;
signal I2C_SDA_OE_C         : std_logic;
signal I2C_SDA_IN_C         : std_logic;
signal I2C_SDA_OUT_C        : std_logic;
signal TX_FAULT				: std_logic_vector(31 downto 0);
signal RX_LOS				: std_logic_vector(31 downto 0);
signal TX_DISABLE_1			: std_logic_vector(31 downto 0);
signal TX_DISABLE_1_WSTB    : std_logic;
signal TX_DISABLE_2			: std_logic_vector(31 downto 0);
signal TX_DISABLE_2_WSTB    : std_logic;
signal TX_DISABLE_3			: std_logic_vector(31 downto 0);
signal TX_DISABLE_3_WSTB    : std_logic;
signal SEL_RATE				: std_logic_vector(31 downto 0);
signal SEL_RATE_WSTB   	    : std_logic;
signal APPLY_SFP			: std_logic;
signal APPLY_FREQ     		: std_logic;
signal FREQUENCY_VALUE      : std_logic_vector(31 downto 0);
signal BUSY        			: std_logic_vector(31 downto 0); 
signal END_TRANSFER			: std_logic_vector(31 downto 0);
signal ERROR_STATUS			: std_logic_vector(31 downto 0);
signal FMC_CLK0_M2C         : std_logic;
signal FMC_CLK1_M2C         : std_logic;
signal FREQ_VAL             : std32_array(3 downto 0);
signal GTREFCLK             : std_logic;
signal FMC_PRSNT_DW         : std_logic_vector(31 downto 0);
signal MAC_LO           	: std_logic_vector(31 downto 0);
signal MAC_HI           	: std_logic_vector(31 downto 0);
signal SOFT_RESET           : std_logic;
signal LOOP_PERIOD_WSTB     : std_logic;
signal LOOP_PERIOD          : std_logic_vector(31 downto 0);
signal GTX2_Rx		   	    : std_logic_vector(15 downto 0);
signal GTX2_Tx				: std_logic_vector(15 downto 0);
signal GTX2_CHARISK_TX		: std_logic_vector(1 downto 0);
signal GTX2_CHARISK_RX		: std_logic_vector(1 downto 0);

attribute MARK_DEBUG        : string;
attribute MARK_DEBUG of probe0  : signal is "true";

component I2C_Status is
  port (
  -- Generic parameters, set by a constant or stable signal only
    G_I2C_FMC_BASE_ADRS     : in    STD_LOGIC_VECTOR(1 downto 0) := "00";     -- I2C base address of FMC card. This value is set by the DIP_Switch located on the FMC card. ON position => '1', OFF position => '0'
    G_MAIN_CLOCK_FREQUENCY  : in    INTEGER range 0 to 300000 := 125000;       -- Frequency in KHz of CLOCK input. This value allows to compute the time-out values
    
  -- Common signals
    RESET                   : in    STD_LOGIC;     -- Asynchronous reset, active high   
    CLOCK                   : in    STD_LOGIC;     -- Clock   
                            
  -- Common signals
    RX_LOS                  : out   STD_LOGIC_VECTOR(3 downto 0);     -- High when the input optical signal is lost, one bit by SFP
    TX_FAULT                : out   STD_LOGIC_VECTOR(3 downto 0);     -- High when a transmission Fault is detected on the SFP, one bit by SFP
                            
  -- I2C interface          
    I2C_SCL                 : out   STD_LOGIC;      -- I2C Clock
    I2C_SDA_IN              : in    STD_LOGIC;      -- I2C Data in
    I2C_SDA_OUT             : out   STD_LOGIC;      -- I2C Data out
    I2C_SDA_OE              : out   STD_LOGIC       -- I2C Data oe (set high to output otherwise output is Z)
	);
end component;

component I2C_Command is
  port (
  -- Generic parameters, set by a constant or stable signal only
    G_I2C_FMC_BASE_ADRS                   : in std_logic_vector(1 downto 0) := "00";      -- I2C base address of FMC card. This value is set by the DIP_Switch located on the FMC card. ON position => '1', OFF position => '0'
    G_MAIN_CLOCK_FREQUENCY                : in integer range 0 to 300000 := 125000;        -- Frequency in KHz of CLOCK input. This value allows to compute the time-out values
    G_DEFAULT_FREQUENCY_OSCILLATOR_10KHz  : in integer range 5000 to 28000 := 12500;      -- Default frequency of programmable oscillator modulo 10KHz. By default, the oscillator will be programmed with this frequency value
                                                                                          -- For instance: 10000 ==> 100000KHz. The value must in range 5000 to 28000
  -- Common signals
    RESET             : in  std_logic;     -- Asynchronous reset, active high 
    CLOCK             : in  std_logic;     -- Clock   
                            
  -- SFP Command part
    APPLY_SFP         : in  std_logic;     -- Set high during one clock cycle to apply the SFP commands (SEL_RATE & TX_DISABLE)
                      
    SEL_RATE          : in  std_logic;     -- Assign high to select the bandwidth of all SFP to 2.125Gb/s to 4.5Gb/s otherwise assign low to select a lower bandwidth
    TX_DISABLE        : in  std_logic_vector(3 downto 0);     -- Assign high to disable the transmission on each SFP individually
                      
  -- SFP Command part
    APPLY_FREQ        : in  std_logic;     -- Set high during one clock cycle to change the oscillator frequency
    FREQUENCY_VALUE   : in  std_logic_vector(14 downto 0);    -- Frequency value by step of 10KHz, frequency range from 5000(dec) (50MHz) to 28000(dec) (280MHz)
  
  -- Status
	BUSY              : out std_logic;      -- Assign high when the controller is busy
	END_TRANSFER      : out std_logic;      -- Assign high during one clock cycle when a complete access (Rd or Wr) has been performed
	ERROR_STATUS      : out std_logic_vector(1 downto 0);      -- Error code assigned during the END_TRANSFER. 0 => no Error, 1 => Access I2C error, 2 => EEPROM integrity error, 3 => FREQUENCY_VALUE is out of range
	                                  
  -- I2C interface          
    I2C_SCL           : out std_logic;      -- I2C Clock
    I2C_SDA_IN        : in  std_logic;      -- I2C Data in
    I2C_SDA_OUT       : out std_logic;      -- I2C Data out
    I2C_SDA_OE        : out std_logic       -- I2C Data oe (set high to output otherwise output is Z)
	);
end component;


begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY_i     => RD_ADDR2ACK
);

-- Multiplex read data out from multiple instantiations

-- Generate prescaled clock for internal counter
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => LOOP_PERIOD_WSTB,
    PERIOD      => LOOP_PERIOD,
    pulse_o     => clock_en
);

---------------------------------------------------------------------------
-- GTX Loopback Test
---------------------------------------------------------------------------
fmcgtx_exdes_i1 : entity work.fmcgtx_wrapper
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => FMC_i.GTREFCLK,
    GTREFCLK                    => GTREFCLK,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_1,
    ERROR_COUNT                 => ERROR_COUNT_1,
    RXP_IN                      => FMC_i.RXP_IN,
    RXN_IN                      => FMC_i.RXN_IN,
    TXP_OUT                     => FMC_o.TXP_OUT,
    TXN_OUT                     => FMC_o.TXN_OUT,
    RXDATA_OUT					=> open,
    TXDATA_IN                   => GTX2_Tx,
    RX_CHARISK_OUT				=> open,
    TX_CHARISK_IN				=> GTX2_CHARISK_TX
);
--fmcgtx_exdes_i2 : entity work.fmcgtx_exdes
fmcgtx_exdes_i2 : entity work.fmcgtx_wrapper
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => FMC_i.GTREFCLK,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_2,
    ERROR_COUNT                 => ERROR_COUNT_2,
    RXP_IN                      => FMC_i.RXP2_IN,
    RXN_IN                      => FMC_i.RXN2_IN,
    TXP_OUT                     => FMC_o.TXP2_OUT,
    TXN_OUT                     => FMC_o.TXN2_OUT,
    RXDATA_OUT					=> GTX2_Rx,
    TXDATA_IN                   => GTX2_Tx,
    RX_CHARISK_OUT				=> GTX2_CHARISK_RX,
    TX_CHARISK_IN				=> GTX2_CHARISK_TX
);
--fmcgtx_exdes_i3 : entity work.fmcgtx_exdes
fmcgtx_exdes_i3 : entity work.fmcgtx_wrapper
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => FMC_i.GTREFCLK,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_3,
    ERROR_COUNT                 => ERROR_COUNT_3,
    RXP_IN                      => FMC_i.RXP3_IN,
    RXN_IN                      => FMC_i.RXN3_IN,
    TXP_OUT                     => FMC_o.TXP3_OUT,
    TXN_OUT                     => FMC_o.TXN3_OUT,
    RXDATA_OUT					=> GTX2_Tx,
    TXDATA_IN					=> GTX2_Rx,
    RX_CHARISK_OUT				=> GTX2_CHARISK_TX,
    TX_CHARISK_IN				=> GTX2_CHARISK_RX
);
fmcgtx_exdes_i4 : entity work.fmcgtx_wrapper
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => FMC_i.GTREFCLK,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => open,
    ERROR_COUNT                 => open,
    RXP_IN                      => FMC_i.RXP4_IN,
    RXN_IN                      => FMC_i.RXN4_IN,
    TXP_OUT                     => FMC_o.TXP4_OUT,
    TXN_OUT                     => FMC_o.TXN4_OUT,
    RXDATA_OUT					=> open,
    TXDATA_IN					=> X"0000",
    RX_CHARISK_OUT				=> open,
    TX_CHARISK_IN				=> "00"
);

---------------------------------------------------------------------------
-- I2C STATUS
---------------------------------------------------------------------------
FMC_HB20_P <= FMC_io.FMC_HB_P(20); -- sda signal of i2c status bus
FMC_HB20_N <= FMC_io.FMC_HB_N(20); -- scl signal of i2c status bus

I2C_SDA		<= FMC_HB20_P;
I2C_SDA		<= I2C_SDA_OUT when (I2C_SDA_OE = '1') else 'Z';
I2C_SDA_IN 	<= I2C_SDA;
PULLUP_I2C_SDA: PULLUP port map (I2C_SDA);
--FMC_io.FMC_HB_P(21) 	<= I2C_SDA_OUT when (I2C_SDA_OE = '1') else 'Z';
--I2C_SDA_IN 				<= FMC_io.FMC_HB_P(21);
--PULLUP_I2C_SDA: PULLUP port map (FMC_io.FMC_HB_P(21));
 
i2c_stat: I2C_Status 
port map( 
 -- Generic parameters, set by a constant or stable signal only
   G_I2C_FMC_BASE_ADRS         => "00",            	--: std_logic_vector(1 downto 0)  := "00";      -- I2C base address of FMC card. This value is set by the DIP_Switch located on the FMC card. ON position => '1', OFF position => '0'
   G_MAIN_CLOCK_FREQUENCY      => 125000,          	--: integer range 1000 to 300000  := 200000;    -- Frequency in KHz of CLOCK input. This value allows to maintain the I2C frequency less than 100KHz
     
 -- Common signals
   RESET                       => reset_i,     		--: in  std_logic;                        -- Asynchronous reset, active high 
   CLOCK                       => clk_i,  			--: in  std_logic;                        -- Clock   
                           
 -- Common signals         
   RX_LOS                      => RX_LOS(3 downto 0),          	--: out std_logic_vector(3 downto 0);     -- High when the input optical signal is lost, one bit by SFP
   TX_FAULT                    => TX_FAULT(3 downto 0),        	--: out std_logic_vector(3 downto 0);     -- High when a transmission Fault is detected on the SFP, one bit by SFP
                                 
 -- I2C interface          
   I2C_SCL                    => FMC_HB20_N,        --: out std_logic;                        -- I2C Clock
   I2C_SDA_IN                 => I2C_SDA_IN,       	--: in  std_logic;                        -- I2C Data in
   I2C_SDA_OUT                => I2C_SDA_OUT,      	--: out std_logic;                        -- I2C Data out
   I2C_SDA_OE                 => I2C_SDA_OE        	--: out std_logic                         -- I2C Data oe (set high to output otherwise output is Z)
);
TX_FAULT(31 downto 4) <= ZEROS(28); 
RX_LOS(31 downto 4)   <= ZEROS(28);

---------------------------------------------------------------------------
-- I2C COMMAND
---------------------------------------------------------------------------
FMC_HB21_P <= FMC_io.FMC_HB_P(21); -- sda signal of i2c status bus
FMC_HB21_N <= FMC_io.FMC_HB_N(21); -- scl signal of i2c status bus

I2C_SDA_C		<= FMC_HB21_P;
I2C_SDA_C		<= I2C_SDA_OUT_C when (I2C_SDA_OE_C = '1') else 'Z';
I2C_SDA_IN_C	<= I2C_SDA_C;
PULLUP_I2C_SDA_C: PULLUP port map (I2C_SDA_C);
--FMC_io.FMC_HB_P(20) 	<= I2C_SDA_OUT_C when (I2C_SDA_OE_C = '1') else 'Z';
--I2C_SDA_IN_C			<= FMC_io.FMC_HB_P(20);
--PULLUP_I2C_SDA_C: PULLUP port map (FMC_io.FMC_HB_P(20));

i2c_comman: I2C_Command 
port map( 
  -- Generic parameters, set by a constant or stable signal only
    G_I2C_FMC_BASE_ADRS                   => "00",     --: std_logic_vector(1 downto 0) := "00";     -- I2C base address of FMC card. This value is set by the DIP_Switch located on the FMC card. ON position => '1', OFF position => '0'
    G_MAIN_CLOCK_FREQUENCY                => 125000,   --: integer range 0 to 300000 := 200000       -- Frequency in KHz of CLOCK input. This value allows to maintain the I2C frequency less than 100KHz
    G_DEFAULT_FREQUENCY_OSCILLATOR_10KHz  => 12500,               --: in integer range 5000 to 28000 := 12500;  -- Default frequency of programmable oscillator modulo 10KHz. By default, the oscillator will be programmed with this frequency value

  -- Common signals
    RESET             => reset_i,           	-- Asynchronous reset, active high 
    CLOCK             => clk_i,             	-- Clock   
								
  -- SFP Command part	
    APPLY_SFP         => APPLY_SFP,         	-- Set high during one clock cycle to apply the SFP commands (SEL_RATE & TX_DISABLE)
						
    SEL_RATE          => SEL_RATE(0),          	-- Assign high to select the bandwidth of all SFP to 2.125Gb/s to 4.5Gb/s otherwise assign low to select a lower bandwidth
    TX_DISABLE(0)     => TX_DISABLE_1(0),       -- [3:0] Assign high to disable the transmission on each SFP individually
	TX_DISABLE(1)     => TX_DISABLE_2(0), 
	TX_DISABLE(2)     => TX_DISABLE_3(0), 		
	TX_DISABLE(3) 	  => '1',					-- no SFP4 for FMC-SFP/SFP+_104
				 
  -- SFP Command part	
    APPLY_FREQ        => APPLY_FREQ,        	--: in  std_logic;                        -- Set high during one clock cycle to change the oscillator frequency
    FREQUENCY_VALUE   => FREQUENCY_VALUE(14 downto 0),   	--: in  std_logic_vector(14 downto 0);    -- Frequency value by step of 10KHz, frequency range from 5000(dec) (50MHz) to 28000(dec) (280MHz)
  
  -- Status
	BUSY              => BUSY(0),              	--: out std_logic;                        -- Assign high when the controller is busy
	END_TRANSFER      => END_TRANSFER(0),      	--: out std_logic;                        -- Assign high during one clock cycle when a complete access (Rd or Wr) has been performed
	ERROR_STATUS      => ERROR_STATUS(1 downto 0),      	--: out std_logic_vector(1 downto 0);     -- Error code assigned during the END_TRANSFER. 0 => no Error, 1 => Access I2C error, 2 => EEPROM integrity error, 3 => FREQUENCY_VALUE is out of range
	                                  
  -- I2C interface          
    I2C_SCL           => FMC_HB21_N,         	-- I2C Clock
    I2C_SDA_IN        => I2C_SDA_IN_C,        	-- I2C Data in
    I2C_SDA_OUT       => I2C_SDA_OUT_C,       	-- I2C Data out
    I2C_SDA_OE        => I2C_SDA_OE_C         	-- I2C Data oe (set high to output otherwise output is Z)
);
APPLY_SFP <= SEL_RATE_WSTB or TX_DISABLE_1_WSTB or TX_DISABLE_2_WSTB or TX_DISABLE_3_WSTB;
BUSY(31 downto 1) 			<= ZEROS(31);
END_TRANSFER(31 downto 1)	<= ZEROS(31);
ERROR_STATUS(31 downto 2)	<= ZEROS(30);



---------------------------------------------------------------------------
-- FMC Clocks Frequency Counter
---------------------------------------------------------------------------
test_clocks(0) <= GTREFCLK;
test_clocks(1) <= FMC_CLK0_M2C;
test_clocks(2) <= FMC_CLK1_M2C;
test_clocks(3) <= FMC_i.EXTCLK;

freq_counter_inst : entity work.freq_counter
generic map ( NUM => 4)
port map (
    refclk          => clk_i,
    reset           => reset_i,
    test_clocks     => test_clocks,
    freq_out        => FREQ_VAL
);

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
FMC_PRSNT_DW <= ZEROS(31) & FMC_i.FMC_PRSNT;

MAC_HI(23 downto 0) <= FMC_i.MAC_ADDR(47 downto 24);
MAC_LO(23 downto 0) <= FMC_i.MAC_ADDR(23 downto 0);

fmc_ctrl : entity work.fmc_hpc_wire_lback_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    -- Block Parameters
    FMC_PRSNT           => FMC_PRSNT_DW,
    LINK_UP_1           => LINK_UP_1,
    LINK_UP_2           => LINK_UP_2,
    LINK_UP_3           => LINK_UP_3,
    ERROR_COUNT_1       => ERROR_COUNT_1,
    ERROR_COUNT_2       => ERROR_COUNT_2,
    ERROR_COUNT_3       => ERROR_COUNT_3,
    TX_FAULT			=> TX_FAULT,
    RX_LOS				=> RX_LOS,
    TX_DISABLE_1		=> TX_DISABLE_1,
    TX_DISABLE_1_WSTB	=> TX_DISABLE_1_WSTB,
    TX_DISABLE_2		=> TX_DISABLE_2,
    TX_DISABLE_2_WSTB	=> TX_DISABLE_2_WSTB,
    TX_DISABLE_3		=> TX_DISABLE_3,
    TX_DISABLE_3_WSTB	=> TX_DISABLE_3_WSTB,
    SEL_RATE			=> SEL_RATE,
    SEL_RATE_WSTB	    => SEL_RATE_WSTB,    
    FREQUENCY_VALUE     => FREQUENCY_VALUE,
    FREQUENCY_VALUE_WSTB=> APPLY_FREQ,
    BUSY				=> BUSY,
    END_TRANSFER		=> END_TRANSFER,
    ERROR_STATUS		=> ERROR_STATUS,
    GTREFCLK            => FREQ_VAL(0),
    FMC_CLK0            => FREQ_VAL(1),
    FMC_CLK1            => FREQ_VAL(2),
    EXT_CLK             => FREQ_VAL(3),
	FMC_MAC_LO          => MAC_LO,
    FMC_MAC_HI          => MAC_HI,
    SOFT_RESET          => open,
    SOFT_RESET_WSTB     => SOFT_RESET,
    LOOP_PERIOD         => LOOP_PERIOD,
    LOOP_PERIOD_WSTB    => LOOP_PERIOD_WSTB,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data_o,
    read_ack_o          => open, 

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open
);

end rtl;

