------------------------------------------------------------------------------------
--  NAMC - 2020
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Shu ZHANG & Arthur MARIANO
-----------------------------------------------------------------------------------
--
--  Description : eth_phy loop between FMC-SFP1 and FMC-SFP2, FMC-SFP3 and FMC-SFP4
--
------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity fmc_hpc_sfp_eth_loop_wrapper is
generic ( DEBUG : string := "FALSE" );
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- System Bus
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
    write_ack_o         : out std_logic := '1';
  
    -- FMC Interface
    FMC_i               : in  	FMC_input_interface;
    FMC_io              : inout FMC_inout_interface;
    FMC_o               : out 	FMC_output_interface
);
end fmc_hpc_sfp_eth_loop_wrapper;

architecture rtl of fmc_hpc_sfp_eth_loop_wrapper is

component eth_phy_to_phy
    Port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    SOFT_RESET          : in  std_logic;
    pma_reset_i         : in  std_logic;
    
    --- GTX I/O
    gtrefclk_i          : in  std_logic;
    eth_clk2phy_i       : in  Eth_clk2phy_interface;
    eth_phy2clk_o       : out Eth_phy2clk_interface;
    RXN_IN              : in  std_logic;
    RXP_IN              : in  std_logic;
    TXN_OUT             : out std_logic;
    TXP_OUT             : out std_logic;
    RESETDONE           : out std_logic;
    CPLLLOCK            : out std_logic;
    STATUS_VECTOR       : out std_logic_vector(15 downto 0);
    GMII_DATAIN_EN      : out std_logic;
    GMII_DATAIN_ER      : out std_logic;
   
    gtrefclk_2_i        : in  std_logic;
    eth_clk2phy_2_i     : in  Eth_clk2phy_interface;
    eth_phy2clk_2_o     : out Eth_phy2clk_interface;
    RXN2_IN             : in  std_logic;
    RXP2_IN             : in  std_logic;
    TXN2_OUT            : out std_logic;
    TXP2_OUT            : out std_logic;
    RESETDONE_2         : out std_logic;
    CPLLLOCK_2          : out std_logic;
    STATUS_VECTOR_2     : out std_logic_vector(15 downto 0);   
    GMII_DATAIN_EN_2    : out std_logic;
    GMII_DATAIN_ER_2    : out std_logic
    );
end component;

component eth_phy_clocking is
port (
      clk_i                   : in  std_logic; 
      pma_reset_i             : in  std_logic; 
      gtrefclk_i              : in  std_logic; -- Reference clock for MGT
      eth_phy_clk_i           : in  Eth_phy2clk_interface;
      eth_phy_clk_o           : out Eth_clk2phy_interface
);
end component;

component gig_ethernet_pcs_pma_0_resets
   port (
    reset                    : in  std_logic;                -- Asynchronous reset for entire core.
    independent_clock_bufg   : in  std_logic;                -- System clock
    pma_reset                : out std_logic                 -- Synchronous transcevier PMA reset
   );
end component;

component pulsecnt is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Input and Outputs
    SOFT_RESET_i        : in  std_logic;
    trig_i              : in  std_logic;
    carry_o             : out std_logic;
    cnt_o               : out std_logic_vector(31 downto 0)
);
end component;

component I2C_Status
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

component I2C_Command
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

signal pma_reset         	: std_logic;
signal FMC_gtrefclk          : std_logic;
signal FMC_eth_phy2clk       : Eth_phy2clk_interface;
signal FMC_eth_clk2phy       : Eth_clk2phy_interface;

signal SOFT_RESET        : std_logic;
signal SOFT_RESET_prev   : std_logic;
signal SOFT_RESET_rise   : std_logic;
signal soft_reset_cpt    : unsigned(31 downto 0);
signal SOFT_RESET_holded : std_logic;
signal FMC_HB20_P		 : std_logic;
signal FMC_HB20_N		 : std_logic;
signal FMC_HB21_P		 : std_logic;
signal FMC_HB21_N		 : std_logic;
signal TX_FAULT			 : std_logic_vector(31 downto 0);
signal RX_LOS			 : std_logic_vector(31 downto 0);
signal PHY_RESETDONE     : std_logic_vector(31 downto 0);
signal PHY_CPLLLOCK      : std_logic_vector(31 downto 0);
signal I2C_SDA_S       	 : std_logic;
signal I2C_SDA_OE_S      : std_logic;
signal I2C_SDA_IN_S      : std_logic;
signal I2C_SDA_OUT_S     : std_logic;
signal I2C_SDA_C         : std_logic;
signal I2C_SDA_OE_C      : std_logic;
signal I2C_SDA_IN_C      : std_logic;
signal I2C_SDA_OUT_C     : std_logic;
signal TX_DISABLE_1		 : std_logic_vector(31 downto 0);
signal TX_DISABLE_1_WSTB : std_logic;
signal TX_DISABLE_2		 : std_logic_vector(31 downto 0);
signal TX_DISABLE_2_WSTB : std_logic;
signal TX_DISABLE_3		 : std_logic_vector(31 downto 0);
signal TX_DISABLE_3_WSTB : std_logic;
signal SEL_RATE			 : std_logic_vector(31 downto 0);
signal SEL_RATE_WSTB   	 : std_logic;
signal APPLY_SFP		 : std_logic;
signal APPLY_FREQ     	 : std_logic;
signal FREQUENCY_VALUE   : std_logic_vector(31 downto 0);
signal I2C_BUSY        	 : std_logic_vector(31 downto 0);
signal I2C_END_TRANSFER	 : std_logic_vector(31 downto 0);
signal I2C_ERROR_STATUS	 : std_logic_vector(31 downto 0);

--------------
signal PHY_STATUS        : std32_array(3 downto 0);
signal DATA_1TO2_EN      : std_logic;
signal DATA_1TO2_ER      : std_logic;
signal DATA_1TO2_CNT     : std_logic_vector(31 downto 0);
signal DATA_1TO2_ER_CNT  : std_logic_vector(31 downto 0);

signal DATA_2TO1_EN      : std_logic;
signal DATA_2TO1_ER      : std_logic;
signal DATA_2TO1_CNT     : std_logic_vector(31 downto 0);
signal DATA_2TO1_ER_CNT  : std_logic_vector(31 downto 0);

signal DATA_3TO4_EN      : std_logic;
signal DATA_3TO4_ER      : std_logic;
signal DATA_3TO4_CNT     : std_logic_vector(31 downto 0);
signal DATA_3TO4_ER_CNT  : std_logic_vector(31 downto 0);

signal DATA_4TO3_EN      : std_logic;
signal DATA_4TO3_ER      : std_logic;
signal DATA_4TO3_CNT     : std_logic_vector(31 downto 0);
signal DATA_4TO3_ER_CNT  : std_logic_vector(31 downto 0);

begin

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY_i     => RD_ADDR2ACK
    );

FMC_gtrefclk<=FMC_i.GTREFCLK;

---------------------------------------------------------------------------
-- Ethernet phy to phy connexion 
---------------------------------------------------------------------------
eth_phy_to_phy_i : eth_phy_to_phy
    port map (
    clk_i               => clk_i,
    SOFT_RESET          => SOFT_RESET_holded,
    pma_reset_i         => pma_reset,
    
    -- GTX I/O
    gtrefclk_i          => FMC_gtrefclk,
    eth_clk2phy_i       => FMC_eth_clk2phy,
    eth_phy2clk_o       => FMC_eth_phy2clk,
    RXN_IN           	=> FMC_i.RXN_IN,
    RXP_IN           	=> FMC_i.RXP_IN,
    TXN_OUT          	=> FMC_o.TXN_OUT,
    TXP_OUT        		=> FMC_o.TXP_OUT,
    RESETDONE       	=> PHY_RESETDONE(0),
    CPLLLOCK        	=> PHY_CPLLLOCK(0),
    STATUS_VECTOR      	=> PHY_STATUS(0)(15 downto 0),
    GMII_DATAIN_EN   	=> DATA_2TO1_EN,
    GMII_DATAIN_ER   	=> DATA_2TO1_ER,
     
    gtrefclk_2_i        => FMC_gtrefclk,
    eth_clk2phy_2_i     => FMC_eth_clk2phy,
    eth_phy2clk_2_o     => open,
    RXN2_IN        		=> FMC_i.RXN2_IN,
    RXP2_IN        		=> FMC_i.RXP2_IN,
    TXN2_OUT       		=> FMC_o.TXN2_OUT,
    TXP2_OUT       		=> FMC_o.TXP2_OUT,
    RESETDONE_2     	=> PHY_RESETDONE(1),
    CPLLLOCK_2     		=> PHY_CPLLLOCK(1),
    STATUS_VECTOR_2    	=> PHY_STATUS(1)(15 downto 0),
    GMII_DATAIN_EN_2   	=> DATA_1TO2_EN,
    GMII_DATAIN_ER_2   	=> DATA_1TO2_ER
    );
    
eth_phy_to_phy_i2 : eth_phy_to_phy
    port map (
    clk_i               => clk_i,
    SOFT_RESET          => SOFT_RESET_holded,
    pma_reset_i         => pma_reset,
    
    -- GTX I/O
    gtrefclk_i          => FMC_gtrefclk,
    eth_clk2phy_i       => FMC_eth_clk2phy,
    eth_phy2clk_o       => open,
    RXN_IN           	=> FMC_i.RXN3_IN,
    RXP_IN           	=> FMC_i.RXP3_IN,
    TXN_OUT          	=> FMC_o.TXN3_OUT,
    TXP_OUT        		=> FMC_o.TXP3_OUT,
    RESETDONE       	=> PHY_RESETDONE(2),
    CPLLLOCK        	=> PHY_CPLLLOCK(2),
    STATUS_VECTOR      	=> PHY_STATUS(2)(15 downto 0),
    GMII_DATAIN_EN   	=> DATA_4TO3_EN,
    GMII_DATAIN_ER   	=> DATA_4TO3_ER,
    
    gtrefclk_2_i        => FMC_gtrefclk,
    eth_clk2phy_2_i     => FMC_eth_clk2phy,
    eth_phy2clk_2_o     => open,
    RXN2_IN        		=> FMC_i.RXN4_IN,
    RXP2_IN        		=> FMC_i.RXP4_IN,
    TXN2_OUT       		=> FMC_o.TXN4_OUT,
    TXP2_OUT       		=> FMC_o.TXP4_OUT,
    RESETDONE_2       	=> PHY_RESETDONE(3),
    CPLLLOCK_2        	=> PHY_CPLLLOCK(3),
    STATUS_VECTOR_2    	=> PHY_STATUS(3)(15 downto 0),
    GMII_DATAIN_EN_2   	=> DATA_3TO4_EN,
    GMII_DATAIN_ER_2   	=> DATA_3TO4_ER
    );

PHY_RESETDONE(31 downto 4) <= ZEROS(28);
PHY_CPLLLOCK(31 downto 4) <= ZEROS(28);

core_resets_i : gig_ethernet_pcs_pma_0_resets
  port map (
    reset                     => SOFT_RESET_holded,
    independent_clock_bufg    => clk_i,
    pma_reset                 => pma_reset
    );

eth_phy_clocking_i: eth_phy_clocking
port map (
    clk_i              => clk_i,
    pma_reset_i        => pma_reset,
    gtrefclk_i         => FMC_i.GTREFCLK,
    eth_phy_clk_i      => FMC_eth_phy2clk,
    eth_phy_clk_o      => FMC_eth_clk2phy
    
    );
    
frame1to2_cnt_i: pulsecnt
port map(
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Block Input and Outputs
    SOFT_RESET_i        => SOFT_RESET_holded,
    trig_i              => DATA_1TO2_EN,
    carry_o             => open,
    cnt_o               => DATA_1TO2_CNT
    );    
frame1to2_errcnt_i: pulsecnt
port map(
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Block Input and Outputs
    SOFT_RESET_i        => SOFT_RESET_holded,
    trig_i              => DATA_1TO2_ER,
    carry_o             => open,
    cnt_o               => DATA_1TO2_ER_CNT
    ); 

frame2to1_cnt_i: pulsecnt
port map(
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Block Input and Outputs
    SOFT_RESET_i        => SOFT_RESET_holded,
    trig_i              => DATA_2TO1_EN,
    carry_o             => open,
    cnt_o               => DATA_2TO1_CNT
    );    
frame2to1_errcnt_i: pulsecnt
port map(
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Block Input and Outputs
    SOFT_RESET_i        => SOFT_RESET_holded,
    trig_i              => DATA_2TO1_ER,
    carry_o             => open,
    cnt_o               => DATA_2TO1_ER_CNT
    );    

---------------------------------------------------------------------------
-- SOFT_RESET_holded Counter
---------------------------------------------------------------------------
process(clk_i)
constant SOFT_RESET_HOLDED_CLK_NUMBER : unsigned(soft_reset_cpt'high downto 0) := to_unsigned(100,soft_reset_cpt'length);
begin
if (falling_edge(clk_i)) then
 if (reset_i='1') then
    soft_reset_cpt<=SOFT_RESET_HOLDED_CLK_NUMBER;
    SOFT_RESET_prev<=SOFT_RESET;
    SOFT_RESET_holded<='1';
 else
   SOFT_RESET_prev<=SOFT_RESET;
   if soft_reset_cpt=to_unsigned(0,soft_reset_cpt'length) then
      SOFT_RESET_holded<='0';
      if SOFT_RESET_rise='1' then
         soft_reset_cpt<=SOFT_RESET_HOLDED_CLK_NUMBER;
      end if;
   else
      SOFT_RESET_holded<='1';
      soft_reset_cpt<=soft_reset_cpt-1;
   end if;
 end if;
end if;
end process;

SOFT_RESET_rise <= SOFT_RESET and not(SOFT_RESET_prev);
--SOFT_RESET_holded <= SOFT_RESET;

---------------------------------------------------------------------------
-- I2C STATUS
---------------------------------------------------------------------------
--FMC_HB20_P <= FMC_io.FMC_HB_P(20); -- sda signal of i2c status bus
--FMC_HB20_N <= FMC_io.FMC_HB_N(20); -- scl signal of i2c status bus
--
--I2C_SDA		<= FMC_HB20_P;
--I2C_SDA		<= I2C_SDA_OUT when (I2C_SDA_OE = '1') else 'Z';
--I2C_SDA_IN 	<= I2C_SDA;
--PULLUP_I2C_SDA: PULLUP port map (I2C_SDA);

FMC_io.FMC_HB_N(20) <= FMC_HB20_N;

FMC_io.FMC_HB_P(20) <= I2C_SDA_OUT_S when (I2C_SDA_OE_S = '1') else 'Z';
I2C_SDA_IN_S <= FMC_io.FMC_HB_P(20);
fmc_PULLUP_I2C_SDA_S: PULLUP port map (FMC_io.FMC_HB_P(20));

i2c_status_i: I2C_Status 
port map( 
 -- Generic parameters, set by a constant or stable signal only
   G_I2C_FMC_BASE_ADRS         => "00",            	    -- I2C base address of FMC card. This value is set by the DIP_Switch located on the FMC card. ON position => '1', OFF position => '0'
   G_MAIN_CLOCK_FREQUENCY      => 125000,          	    -- Frequency in KHz of CLOCK input. This value allows to maintain the I2C frequency less than 100KHz
													
 -- Common signals                                  
   RESET                       => reset_i,     		    -- Asynchronous reset, active high 
   CLOCK                       => clk_i,  			    -- Clock   
                           
 -- Common signals         
   RX_LOS                      => RX_LOS(3 downto 0),   -- High when the input optical signal is lost, one bit by SFP
   TX_FAULT                    => TX_FAULT(3 downto 0), -- High when a transmission Fault is detected on the SFP, one bit by SFP
                                 
 -- I2C interface          
   I2C_SCL                     => FMC_HB20_N,           -- I2C Clock
   I2C_SDA_IN                  => I2C_SDA_IN_S,         -- I2C Data in
   I2C_SDA_OUT                 => I2C_SDA_OUT_S,        -- I2C Data out
   I2C_SDA_OE                  => I2C_SDA_OE_S         	-- I2C Data oe (set high to output otherwise output is Z)
);
TX_FAULT(31 downto 4) <= ZEROS(28); 
RX_LOS(31 downto 4)   <= ZEROS(28);

---------------------------------------------------------------------------
-- I2C COMMAND
---------------------------------------------------------------------------
--FMC_HB21_P <= FMC_io.FMC_HB_P(21); -- sda signal of i2c status bus
--FMC_HB21_N <= FMC_io.FMC_HB_N(21); -- scl signal of i2c status bus
--
--I2C_SDA_C		<= FMC_HB21_P;
--I2C_SDA_C		<= I2C_SDA_OUT_C when (I2C_SDA_OE_C = '1') else 'Z';
--I2C_SDA_IN_C	<= I2C_SDA_C;
--PULLUP_I2C_SDA_C: PULLUP port map (I2C_SDA_C);

FMC_io.FMC_HB_N(21) <= FMC_HB21_N;

--FMC_I2C_SDA       <= FMC_HB21_P;
FMC_io.FMC_HB_P(21) <= I2C_SDA_OUT_C when (I2C_SDA_OE_C = '1') else 'Z';
I2C_SDA_IN_C <= FMC_io.FMC_HB_P(21);
fmc_PULLUP_I2C_SDA_C: PULLUP port map (FMC_io.FMC_HB_P(21));

i2c_command_i: I2C_Command 
port map( 
  -- Generic parameters, set by a constant or stable signal only
    G_I2C_FMC_BASE_ADRS                   => "00",      -- I2C base address of FMC card. This value is set by the DIP_Switch located on the FMC card. ON position => '1', OFF position => '0'
    G_MAIN_CLOCK_FREQUENCY                => 125000,    -- Frequency in KHz of CLOCK input. This value allows to maintain the I2C frequency less than 100KHz
    G_DEFAULT_FREQUENCY_OSCILLATOR_10KHz  => 12500,     -- Default frequency of programmable oscillator modulo 10KHz. By default, the oscillator will be programmed with this frequency value

  -- Common signals
    RESET             => reset_i,           	        -- Asynchronous reset, active high 
    CLOCK             => clk_i,             	        -- Clock   
												        
  -- SFP Command part	                                
    APPLY_SFP         => APPLY_SFP,         	        -- Set high during one clock cycle to apply the SFP commands (SEL_RATE & TX_DISABLE)
												        
    SEL_RATE          => SEL_RATE(0),          	        -- Assign high to select the bandwidth of all SFP to 2.125Gb/s to 4.5Gb/s otherwise assign low to select a lower bandwidth
    TX_DISABLE(0)     => TX_DISABLE_1(0),               -- [3:0] Assign high to disable the transmission on each SFP individually
	TX_DISABLE(1)     => TX_DISABLE_2(0),               
	TX_DISABLE(2)     => TX_DISABLE_3(0), 		        
	TX_DISABLE(3) 	  => '1',					        -- no SFP4 for FMC-SFP/SFP+_104
				 
  -- SFP Command part	
    APPLY_FREQ        => APPLY_FREQ,        	        -- Set high during one clock cycle to change the oscillator frequency
    FREQUENCY_VALUE   => FREQUENCY_VALUE(14 downto 0),  -- Frequency value by step of 10KHz, frequency range from 5000(dec) (50MHz) to 28000(dec) (280MHz)
  
  -- Status
	BUSY              => I2C_BUSY(0),              	    -- Assign high when the controller is busy
	END_TRANSFER      => I2C_END_TRANSFER(0),      	    -- Assign high during one clock cycle when a complete access (Rd or Wr) has been performed
	ERROR_STATUS      => I2C_ERROR_STATUS(1 downto 0),  -- Error code assigned during the END_TRANSFER. 0 => no Error, 1 => Access I2C error, 2 => EEPROM integrity error, 3 => FREQUENCY_VALUE is out of range
	                                  
  -- I2C interface          
    I2C_SCL           => FMC_HB21_N,         	        -- I2C Clock
    I2C_SDA_IN        => I2C_SDA_IN_C,        	        -- I2C Data in
    I2C_SDA_OUT       => I2C_SDA_OUT_C,       	        -- I2C Data out
    I2C_SDA_OE        => I2C_SDA_OE_C         	        -- I2C Data oe (set high to output otherwise output is Z)
);

APPLY_SFP <= SEL_RATE_WSTB or TX_DISABLE_1_WSTB or TX_DISABLE_2_WSTB or TX_DISABLE_3_WSTB;
I2C_BUSY(31 downto 1) 			<= ZEROS(31);
I2C_END_TRANSFER(31 downto 1)	<= ZEROS(31);
I2C_ERROR_STATUS(31 downto 2)	<= ZEROS(30);

SEL_RATE <= ZEROS(32);
APPLY_FREQ <= '0';
FREQUENCY_VALUE <= ZEROS(32);
---------------------------------------------------------------------------
-- SFP Control Interface
---------------------------------------------------------------------------
fmc_hpc_sfp_eth_loop_ctrl : entity work.fmc_hpc_sfp_eth_loop_ctrl
port map (
    -- Clock and Reset
    clk_i               	=> clk_i,
    reset_i             	=> reset_i,
    bit_bus_i           	=> bit_bus_i,
    pos_bus_i           	=> pos_bus_i,
    -- Block Parameters
    SOFT_RESET              => open,
    SOFT_RESET_WSTB         => SOFT_RESET,
    TX_FAULT				=> TX_FAULT,
    RX_LOS					=> RX_LOS,
    PHY_RESETDONE			=> PHY_RESETDONE,
    PHY_CPLLLOCK			=> PHY_CPLLLOCK,
    PHY1_STATUS				=> PHY_STATUS(0),
    PHY2_STATUS				=> PHY_STATUS(1),
    PHY3_STATUS				=> PHY_STATUS(2),
    PHY4_STATUS				=> PHY_STATUS(3),
    DATA_1TO2_CNT   		=> DATA_1TO2_CNT,   
    DATA_1TO2_ER_CNT		=> DATA_1TO2_ER_CNT,
    DATA_2TO1_CNT   		=> DATA_2TO1_CNT,   
    DATA_2TO1_ER_CNT		=> DATA_2TO1_ER_CNT,
    TX_DISABLE_1			=> TX_DISABLE_1,
    TX_DISABLE_1_WSTB		=> TX_DISABLE_1_WSTB,
    TX_DISABLE_2			=> TX_DISABLE_2,
    TX_DISABLE_2_WSTB		=> TX_DISABLE_2_WSTB,
    TX_DISABLE_3			=> TX_DISABLE_3,
    TX_DISABLE_3_WSTB		=> TX_DISABLE_3_WSTB,
    I2C_BUSY				=> I2C_BUSY,
    I2C_ERROR_STATUS		=> I2C_ERROR_STATUS,
    -- Memory Bus Interface
    read_strobe_i           => read_strobe_i,
    read_address_i          => read_address_i(BLK_AW-1 downto 0),
    read_data_o             => read_data_o,
    read_ack_o              => open,

    write_strobe_i          => write_strobe_i,
    write_address_i         => write_address_i(BLK_AW-1 downto 0),
    write_data_i            => write_data_i,
    write_ack_o             => open
);

end rtl;

