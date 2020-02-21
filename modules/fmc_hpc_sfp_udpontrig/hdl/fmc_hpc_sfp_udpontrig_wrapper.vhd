--------------------------------------------------------------------------------
--  NAMC - 2020
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Shu ZHANG & Arthur MARIANO
--------------------------------------------------------------------------------
--
--  Description : UDP frame sends on trigger input top-level module. This block instantiates:
--
--                  * fmc_sfp_ctrl: Block control and status interface
--                  * SFP_UDP_Complete : UDP block using UDP_IP_Stack from opencores.org and eth MAC and PHY xilinx IP
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity fmc_hpc_sfp_udpontrig_wrapper is
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
    FMC_i               : in 	FMC_input_interface;
    FMC_io				: inout FMC_inout_interface;
    FMC_o               : out 	FMC_output_interface
);
end fmc_hpc_sfp_udpontrig_wrapper;

architecture rtl of fmc_hpc_sfp_udpontrig_wrapper is

component SFP_UDP_Complete
    generic (
    DEBUG               : string  := "FALSE";
    CLOCK_FREQ          : integer := 125000000;  -- freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT         : integer := 60;         -- ARP response timeout (s)
    ARP_MAX_PKT_TMO     : integer := 5;              -- wrong nwk pkts received before set error
    MAX_ARP_ENTRIES     : integer := 255         -- max entries in the ARP store
    );
    Port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    SOFT_RESET          : in  std_logic;
    -- Block inpout
    trig_i              : in std_logic;
    SFP_START_COUNT     : in std_logic;
    SFP_STOP_COUNT      : in std_logic;
    -- Block register readouts
    udp_txi_trigger_rise_count : out std_logic_vector(31 downto 0);
    count_udp_tx_RESULT_ERR    : out unsigned(31 downto 0);
    SFP_STATUS_COUNT           : out std_logic_vector(31 downto 0);
    -- Block Parameters
    OUR_MAC_ADDRESS 	: in std_logic_vector(47 downto 0);
    dest_udp_port 		: in std_logic_vector(15 downto 0);
    our_udp_port  		: in std_logic_vector(15 downto 0);
    dest_ip_address 	: in std_logic_vector(31 downto 0);
    our_ip_address  	: in std_logic_vector(31 downto 0);
    -- GTX I/O
    gtrefclk         	: in  std_logic;
    RXN_IN              : in  std_logic;
    RXP_IN              : in  std_logic;
    TXN_OUT             : out std_logic;
    TXP_OUT             : out std_logic
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

signal trig                       : std_logic;
signal udp_txi_trigger_rise_count : std_logic_vector(31 downto 0);
signal count_udp_tx_RESULT_ERR_i  : unsigned(31 downto 0);

signal SFP_LOS_VEC      : std_logic_vector(31 downto 0) := (others => '0');

signal SFP_STATUS_COUNT           : std_logic_vector(31 downto 0);
signal SFP_START_COUNT            : std_logic;
signal SFP_STOP_COUNT             : std_logic;

signal MAC_LO                  : std_logic_vector(31 downto 0) := (others => '0');
signal MAC_HI                  : std_logic_vector(31 downto 0) := (others => '0');

signal dest_udp_port32         : std_logic_vector(31 downto 0);
signal our_udp_port32          : std_logic_vector(31 downto 0);
signal dest_udp_port           : std_logic_vector(15 downto 0);
signal our_udp_port            : std_logic_vector(15 downto 0);

signal dest_ip_address_byte1 : std_logic_vector(31 downto 0);
signal dest_ip_address_byte2 : std_logic_vector(31 downto 0);
signal dest_ip_address_byte3 : std_logic_vector(31 downto 0);
signal dest_ip_address_byte4 : std_logic_vector(31 downto 0);
signal dest_ip_address       : std_logic_vector(31 downto 0);

signal our_ip_address_byte1  : std_logic_vector(31 downto 0);
signal our_ip_address_byte2  : std_logic_vector(31 downto 0);
signal our_ip_address_byte3  : std_logic_vector(31 downto 0);
signal our_ip_address_byte4  : std_logic_vector(31 downto 0);
signal our_ip_address        : std_logic_vector(31 downto 0);

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
signal I2C_SDA         	 : std_logic;
signal I2C_SDA_OE        : std_logic;
signal I2C_SDA_IN        : std_logic;
signal I2C_SDA_OUT       : std_logic;
signal I2C_SDA_C         : std_logic;
signal I2C_SDA_OE_C      : std_logic;
signal I2C_SDA_IN_C      : std_logic;
signal I2C_SDA_OUT_C     : std_logic;
signal TX_DISABLE_1		 : std_logic_vector(31 downto 0);
signal TX_DISABLE_1_WSTB : std_logic;
signal SEL_RATE			 : std_logic_vector(31 downto 0);
signal SEL_RATE_WSTB   	 : std_logic;
signal APPLY_SFP		 : std_logic;
signal APPLY_FREQ     	 : std_logic;
signal FREQUENCY_VALUE   : std_logic_vector(31 downto 0);
signal BUSY        		 : std_logic_vector(31 downto 0); 
signal END_TRANSFER		 : std_logic_vector(31 downto 0);
signal ERROR_STATUS		 : std_logic_vector(31 downto 0);

begin

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY_i     => RD_ADDR2ACK
    );

our_ip_address<=our_ip_address_byte1(7 downto 0)&our_ip_address_byte2(7 downto 0)&our_ip_address_byte3(7 downto 0)&our_ip_address_byte4(7 downto 0);
dest_ip_address<=dest_ip_address_byte1(7 downto 0)&dest_ip_address_byte2(7 downto 0)&dest_ip_address_byte3(7 downto 0)&dest_ip_address_byte4(7 downto 0);
our_udp_port<=dest_udp_port32(15 downto 0);
dest_udp_port<=dest_udp_port32(15 downto 0);



SFP_UDP_Complete_i : SFP_UDP_Complete
    generic map (
    DEBUG           	=> DEBUG,
    CLOCK_FREQ          => 125000000,   -- freq of data_in_clk -- needed to timout cntr
    ARP_TIMEOUT         => 60,          -- ARP response timeout (s)
    ARP_MAX_PKT_TMO     => 5,           -- wrong nwk pkts received before set error
    MAX_ARP_ENTRIES 	=> 255          -- max entries in the ARP store
    )
    port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    SOFT_RESET          => SOFT_RESET_holded,
    -- Block inpout
    trig_i              => trig,--Rising edge to send UDP user-defined frame
    SFP_START_COUNT     => SFP_START_COUNT,
    SFP_STOP_COUNT      => SFP_STOP_COUNT,
    -- Block register readouts
    udp_txi_trigger_rise_count=> udp_txi_trigger_rise_count,
    count_udp_tx_RESULT_ERR   => count_udp_tx_RESULT_ERR_i,
    SFP_STATUS_COUNT          => SFP_STATUS_COUNT,
    -- Block Parameters
    OUR_MAC_ADDRESS		=> FMC_i.MAC_ADDR,
    dest_udp_port  		=> dest_udp_port,
    our_udp_port   		=> our_udp_port,
    dest_ip_address		=> dest_ip_address,
    our_ip_address 		=> our_ip_address,
    -- GTX I/O
    gtrefclk       		=> FMC_i.GTREFCLK,
    RXN_IN         		=> FMC_i.RXN_IN,
    RXP_IN         		=> FMC_i.RXP_IN,
    TXN_OUT        		=> FMC_o.TXN_OUT,
    TXP_OUT        		=> FMC_o.TXP_OUT
    );

---------------------------------------------------------------------------
-- SFP Clocks Frequency Counter
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

SOFT_RESET_rise<=SOFT_RESET and not(SOFT_RESET_prev);

MAC_HI(23 downto 0) <= FMC_i.MAC_ADDR(47 downto 24);
MAC_LO(23 downto 0) <= FMC_i.MAC_ADDR(23 downto 0);

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
--SFP_LOS_VEC <= (0 => FMC_i.SFP_LOS, others => '0');

---------------------------------------------------------------------------
-- I2C COMMAND
---------------------------------------------------------------------------
FMC_HB21_P <= FMC_io.FMC_HB_P(21); -- sda signal of i2c status bus
FMC_HB21_N <= FMC_io.FMC_HB_N(21); -- scl signal of i2c status bus

I2C_SDA_C		<= FMC_HB21_P;
I2C_SDA_C		<= I2C_SDA_OUT_C when (I2C_SDA_OE_C = '1') else 'Z';
I2C_SDA_IN_C	<= I2C_SDA_C;
PULLUP_I2C_SDA_C: PULLUP port map (I2C_SDA_C);

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
	TX_DISABLE(1)     => '1', 
	TX_DISABLE(2)     => '1', 		
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
APPLY_SFP <= SEL_RATE_WSTB or TX_DISABLE_1_WSTB;
BUSY(31 downto 1) 			<= ZEROS(31);
END_TRANSFER(31 downto 1)	<= ZEROS(31);
ERROR_STATUS(31 downto 2)	<= ZEROS(30);

---------------------------------------------------------------------------
-- SFP Control Interface
---------------------------------------------------------------------------
fmc_ctrl : entity work.fmc_hpc_sfp_udpontrig_ctrl
port map (
    -- Clock and Reset
    clk_i                       => clk_i,
    reset_i                     => reset_i,
    bit_bus_i                   => bit_bus_i,
    pos_bus_i                   => pos_bus_i,
    -- Block inpout
    sfp_trig_from_bus          => trig,
    SFP_START_COUNT            => open,
    SFP_STOP_COUNT             => open,
    SFP_START_COUNT_WSTB       => SFP_START_COUNT,
    SFP_STOP_COUNT_WSTB        => SFP_STOP_COUNT,
    -- Block register readouts
    sfp_trig_rise_count        => udp_txi_trigger_rise_count,
    SFP_COUNT_UDPTX_ERR        => std_logic_vector(count_udp_tx_RESULT_ERR_i),
    sfp_status_count           => SFP_STATUS_COUNT,
    -- Block Parameters
    --SFP_LOS                    =>  SFP_LOS_VEC,
    TX_FAULT	   			   => TX_FAULT,
    RX_LOS		   			   => RX_LOS,
    TX_DISABLE_1			   => TX_DISABLE_1,
    TX_DISABLE_1_WSTB		   => TX_DISABLE_1_WSTB,
    SEL_RATE				   => SEL_RATE,
    SEL_RATE_WSTB	    	   => SEL_RATE_WSTB,    
    FREQUENCY_VALUE     	   => FREQUENCY_VALUE,
    FREQUENCY_VALUE_WSTB	   => APPLY_FREQ,
    BUSY					   => BUSY,
    END_TRANSFER			   => END_TRANSFER,
    ERROR_STATUS			   => ERROR_STATUS,
    SFP_MAC_LO                 => MAC_LO,
    SFP_MAC_HI                 => MAC_HI,
    SFP_DEST_UDP_PORT          => dest_udp_port32,
    SFP_OUR_UDP_PORT           => our_udp_port32,
    SFP_DEST_IP_AD_BYTE1       => dest_ip_address_byte1,
    SFP_DEST_IP_AD_BYTE2       => dest_ip_address_byte2,
    SFP_DEST_IP_AD_BYTE3       => dest_ip_address_byte3,
    SFP_DEST_IP_AD_BYTE4       => dest_ip_address_byte4,
    SFP_OUR_IP_AD_BYTE1        => our_ip_address_byte1,
    SFP_OUR_IP_AD_BYTE2        => our_ip_address_byte2,
    SFP_OUR_IP_AD_BYTE3        => our_ip_address_byte3,
    SFP_OUR_IP_AD_BYTE4        => our_ip_address_byte4,
    SOFT_RESET                 => open,
    SOFT_RESET_WSTB            => SOFT_RESET,
    -- Memory Bus Interface
    read_strobe_i              => read_strobe_i,
    read_address_i             => read_address_i(BLK_AW-1 downto 0),
    read_data_o                => read_data_o,
    read_ack_o                 => open,

    write_strobe_i             => write_strobe_i,
    write_address_i            => write_address_i(BLK_AW-1 downto 0),
    write_data_i               => write_data_i,
    write_ack_o                => open
);

end rtl;

