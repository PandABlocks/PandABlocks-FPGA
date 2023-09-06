--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : PandABrick Top-Level Design File
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.addr_defines.all;
use work.top_defines.all;

entity PandABrick_top is
generic (
    SIM                 : string  := "FALSE";
    AXI_ADDR_WIDTH      : integer := 32;
    AXI_DATA_WIDTH      : integer := 32;
    NUM_SFP             : natural := 1;
    NUM_FMC             : natural := 0
);
port (

    -- SFP+ 
    mgtrefclk1_x0y1_p	           : in     std_logic;
    mgtrefclk1_x0y1_n	           : in     std_logic;

    ch0_gthrxn_in                  : in     std_logic;
    ch0_gthrxp_in                  : in     std_logic;
    ch0_gthtxn_out                 : out    std_logic;
    ch0_gthtxp_out                 : out    std_logic;
     
    -- Anios_0
    IO0_D0_P                       : inout  std_logic;
    IO0_D1_N                       : inout  std_logic;
    IO0_D2_P                       : inout  std_logic;
    IO0_D3_N                       : inout  std_logic;
    IO0_D4_P                       : inout  std_logic;
    IO0_D5_N                       : inout  std_logic;
    IO0_D6_P                       : inout  std_logic;
    IO0_D7_N                       : inout  std_logic;
    IO0_D8_P                       : inout  std_logic;
    IO0_D9_N                       : inout  std_logic;

    IO0_D20_P                      : in     std_logic;
    IO0_D21_N                      : in     std_logic;
    IO0_D22_P                      : out    std_logic;
    IO0_D23_N                      : out    std_logic;

    -- FMC
    FMC_LA02_N                     : in     std_logic;
    FMC_LA02_P                     : in     std_logic;
    FMC_LA03_N                     : in     std_logic;
    FMC_LA03_P                     : in     std_logic;
    FMC_LA04_N                     : in     std_logic;
    FMC_LA04_P                     : in     std_logic;
    FMC_LA05_N                     : out    std_logic;
    FMC_LA05_P                     : out    std_logic;
    FMC_LA06_N                     : in     std_logic;
    FMC_LA06_P                     : in     std_logic;
    FMC_LA07_N                     : out    std_logic;
    FMC_LA07_P                     : out    std_logic;
    FMC_LA08_N                     : out    std_logic;
    FMC_LA08_P                     : out    std_logic;
    FMC_LA09_N                     : in     std_logic;
    FMC_LA09_P                     : in     std_logic;
    FMC_LA10_N                     : out    std_logic;
    FMC_LA10_P                     : out    std_logic;
    FMC_LA11_N                     : in     std_logic;
    FMC_LA11_P                     : in     std_logic;
    FMC_LA12_N                     : in     std_logic;
    FMC_LA12_P                     : in     std_logic;
    FMC_LA13_N                     : out    std_logic;
    FMC_LA13_P                     : out    std_logic;
    FMC_LA14_N                     : out    std_logic;
    FMC_LA14_P                     : out    std_logic;
    FMC_LA15_N                     : out    std_logic;
    FMC_LA15_P                     : out    std_logic;
    FMC_LA16_N                     : out    std_logic;
    FMC_LA16_P                     : out    std_logic;
    FMC_LA19_N                     : in     std_logic;
    FMC_LA19_P                     : in     std_logic;
    FMC_LA20_N                     : in     std_logic;
    FMC_LA20_P                     : in     std_logic;
    FMC_LA21_N                     : out    std_logic;
    FMC_LA21_P                     : out    std_logic;
    FMC_LA22_N                     : in     std_logic;
    FMC_LA22_P                     : in     std_logic;
    FMC_LA23_N                     : in     std_logic;
    FMC_LA23_P                     : in     std_logic;
    FMC_LA24_N                     : in     std_logic;
    FMC_LA24_P                     : in     std_logic;
    FMC_LA25_N                     : out    std_logic;
    FMC_LA25_P                     : out    std_logic;
    FMC_LA26_N                     : out    std_logic;
    FMC_LA26_P                     : out    std_logic;
    FMC_LA27_N                     : out    std_logic;
    FMC_LA27_P                     : out    std_logic;
    FMC_LA28_N                     : in     std_logic;
    FMC_LA28_P                     : in     std_logic;
    FMC_LA29_N                     : in     std_logic;
    FMC_LA29_P                     : in     std_logic;
    FMC_LA30_N                     : out    std_logic;
    FMC_LA30_P                     : out    std_logic;
    FMC_LA31_N                     : out    std_logic;
    FMC_LA31_P                     : out    std_logic;
    FMC_LA32_N                     : out    std_logic;
    FMC_LA32_P                     : out    std_logic;
    FMC_LA33_N                     : out    std_logic;
    FMC_LA33_P                     : out    std_logic;

    FMC_CLK0_M2C_N                 : out    std_logic;
    FMC_CLK0_M2C_P                 : out    std_logic;
    FMC_CLK1_M2C_N                 : in     std_logic;
    FMC_CLK1_M2C_P                 : out    std_logic;

    -- IO3
    IO3_D0_P                       : in     std_logic;
    IO3_D1_N                       : in     std_logic;
    IO3_D2_P                       : in     std_logic;
    IO3_D3_N                       : in     std_logic;
    IO3_D4_P                       : in     std_logic;
    IO3_D5_N                       : in     std_logic;
    IO3_D6_P                       : in     std_logic;
    IO3_D7_N                       : in     std_logic;

    -- IO4
    IO4_D2_P                       : in     std_logic;
    IO4_D3_N                       : in     std_logic;
    IO4_D4_P                       : out    std_logic;
    IO4_D5_N                       : out    std_logic;
    IO4_D6_P                       : out    std_logic;
    IO4_D7_N                       : out    std_logic;
    
    -- LED
    LED1_N                         : out    std_logic
);
attribute IO_BUFFER_TYPE : string;
attribute IO_BUFFER_TYPE of ch0_gthtxP_out : signal is "none";
attribute IO_BUFFER_TYPE of ch0_gthtxn_out : signal is "none";
end PandABrick_top;

architecture rtl of PandABrick_top is

---------------------------------------------------------------------------------
-- Adaptor-Board PIC SPI Interface (relay driver and Quadrature LoS detector.)
---------------------------------------------------------------------------------

component Adaptor_PIC_SPI is
port (
        i_clk     : in  std_logic;          -- 125MHz System (AXI) clock.
        o_PIC_SC  : out std_logic;          -- SPI Serial Clock
		o_PIC_CS  : out std_logic;          -- SPI Chip Select (low during transfer)
		o_PIC_DI  : out std_logic;          -- SPI PIC Data In (to PIC)
        i_PIC_DO  : in  std_logic;          -- SPI PIC Data Out (from PIC) 
        o_done    : out std_logic;          -- Transfer finished on Rising edge of this output.
        
        i_data    : in std_logic_vector(15 downto 0);   -- Data to send to the PIC.
        o_data    : out std_logic_vector(15 downto 0)   -- Data received from the PIC.
);
end component;

---------------------------------------------------------------------------------------------------
-- signal declarations
---------------------------------------------------------------------------------------------------

-- PS Block
signal FCLK_CLK0            : std_logic;
signal FCLK_CLK0_PS         : std_logic;
signal FCLK_RESET0_N        : std_logic_vector(0 downto 0);
signal FCLK_RESET0          : std_logic;

signal M00_AXI_awaddr       : std_logic_vector ( 31 downto 0 );
signal M00_AXI_awprot       : std_logic_vector ( 2 downto 0 );
signal M00_AXI_awvalid      : std_logic;
signal M00_AXI_awready      : std_logic;
signal M00_AXI_wdata        : std_logic_vector ( 31 downto 0 );
signal M00_AXI_wstrb        : std_logic_vector ( 3 downto 0 );
signal M00_AXI_wvalid       : std_logic;
signal M00_AXI_wready       : std_logic;
signal M00_AXI_bresp        : std_logic_vector ( 1 downto 0 );
signal M00_AXI_bvalid       : std_logic;
signal M00_AXI_bready       : std_logic;
signal M00_AXI_araddr       : std_logic_vector ( 31 downto 0 );
signal M00_AXI_arprot       : std_logic_vector ( 2 downto 0 );
signal M00_AXI_arvalid      : std_logic;
signal M00_AXI_arready      : std_logic;
signal M00_AXI_rdata        : std_logic_vector ( 31 downto 0 );
signal M00_AXI_rresp        : std_logic_vector ( 1 downto 0 );
signal M00_AXI_rvalid       : std_logic;
signal M00_AXI_rready       : std_logic;

signal S_AXI_HP0_awready    : std_logic := '1';
signal S_AXI_HP0_awregion   : std_logic_vector(3 downto 0);
signal S_AXI_HP0_bid        : std_logic_vector(5 downto 0) := (others => '0');
signal S_AXI_HP0_bresp      : std_logic_vector(1 downto 0) := (others => '0');
signal S_AXI_HP0_bvalid     : std_logic := '1';
signal S_AXI_HP0_wready     : std_logic := '1';
signal S_AXI_HP0_awaddr     : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
signal S_AXI_HP0_awburst    : std_logic_vector(1 downto 0);
signal S_AXI_HP0_awcache    : std_logic_vector(3 downto 0);
signal S_AXI_HP0_awid       : std_logic_vector(5 downto 0);
signal S_AXI_HP0_awlen      : std_logic_vector(3 downto 0);
signal S_AXI_HP0_awlock     : std_logic_vector(1 downto 0);
signal S_AXI_HP0_awprot     : std_logic_vector(2 downto 0);
signal S_AXI_HP0_awqos      : std_logic_vector(3 downto 0);
signal S_AXI_HP0_awsize     : std_logic_vector(2 downto 0);
signal S_AXI_HP0_awvalid    : std_logic;
signal S_AXI_HP0_bready     : std_logic;
signal S_AXI_HP0_wdata      : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
signal S_AXI_HP0_wlast      : std_logic;
signal S_AXI_HP0_wstrb      : std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
signal S_AXI_HP0_wvalid     : std_logic;

signal S_AXI_HP1_araddr     : STD_LOGIC_VECTOR ( 31 downto 0 );
signal S_AXI_HP1_arburst    : STD_LOGIC_VECTOR ( 1 downto 0 );
signal S_AXI_HP1_arcache    : STD_LOGIC_VECTOR ( 3 downto 0 );
signal S_AXI_HP1_arid       : STD_LOGIC_VECTOR ( 5 downto 0 );
signal S_AXI_HP1_arlen      : STD_LOGIC_VECTOR ( 7 downto 0 );
signal S_AXI_HP1_arlock     : STD_LOGIC_VECTOR ( 0 to 0 );
signal S_AXI_HP1_arprot     : STD_LOGIC_VECTOR ( 2 downto 0 );
signal S_AXI_HP1_arqos      : STD_LOGIC_VECTOR ( 3 downto 0 );
signal S_AXI_HP1_arready    : STD_LOGIC;
signal S_AXI_HP1_arregion   : STD_LOGIC_VECTOR ( 3 downto 0 );
signal S_AXI_HP1_arsize     : STD_LOGIC_VECTOR ( 2 downto 0 );
signal S_AXI_HP1_arvalid    : STD_LOGIC;
signal S_AXI_HP1_rdata      : STD_LOGIC_VECTOR ( 31 downto 0 );
signal S_AXI_HP1_rid        : STD_LOGIC_VECTOR ( 5 downto 0 );
signal S_AXI_HP1_rlast      : STD_LOGIC;
signal S_AXI_HP1_rready     : STD_LOGIC;
signal S_AXI_HP1_rresp      : STD_LOGIC_VECTOR ( 1 downto 0 );
signal S_AXI_HP1_rvalid     : STD_LOGIC;

signal IRQ_F2P              : std_logic_vector(0 downto 0);

-- Configuration and Status Interface Block
signal read_strobe          : std_logic_vector(MOD_COUNT-1 downto 0);
signal read_address         : std_logic_vector(PAGE_AW-1 downto 0);
signal read_data            : std32_array(MOD_COUNT-1 downto 0);
signal read_ack             : std_logic_vector(MOD_COUNT-1 downto 0) := (others
                                                                       => '1');
signal write_strobe         : std_logic_vector(MOD_COUNT-1 downto 0);
signal write_address        : std_logic_vector(PAGE_AW-1 downto 0);
signal write_data           : std_logic_vector(31 downto 0);
signal write_ack            : std_logic_vector(MOD_COUNT-1 downto 0) := (others
                                                                       => '1');
-- Top Level Signals
signal bit_bus              : bit_bus_t := (others => '0');
signal pos_bus              : pos_bus_t := (others => (others => '0'));
  
-- PIC Microcontroller on Adaptor Board...
-- (IO expander for LD relays, mode (pass through) etc.) 
signal PIC_SPI_SC           : std_logic;
signal PIC_SPI_CS           : std_logic;
signal PIC_SPI_DI           : std_logic;
signal PIC_SPI_DO           : std_logic;

-- Line Driver Boards...      
signal LD_FPGA_IN_AXIS_1    : std_logic_vector(7 downto 0);
signal LD_FPGA_OUT_AXIS_1   : std_logic_vector(7 downto 0);
signal LD_FPGA_IN_AXIS_5    : std_logic_vector(7 downto 0);
signal LD_FPGA_OUT_AXIS_5   : std_logic_vector(7 downto 0);

signal LD_FPGA_IN_AXIS_2    : std_logic_vector(7 downto 0);
signal LD_FPGA_OUT_AXIS_2   : std_logic_vector(7 downto 0);
signal LD_FPGA_IN_AXIS_6    : std_logic_vector(7 downto 0);
signal LD_FPGA_OUT_AXIS_6   : std_logic_vector(7 downto 0);

--AUX IO SPI/TTL Board (Back Panel)  
signal AUX_IO_DATA          : std_logic_vector(5 downto 1);
signal AUX_IO_DIR           : std_logic_vector(5 downto 1);        
signal AUX_IO_TTL_IN        : std_logic_vector(1 downto 0);      
signal AUX_IO_TTL_OUT       : std_logic_vector(1 downto 0);

-- EQU inputs from PMAC 
signal EQU_IN               : std_logic_vector(8 downto 1);

-- Watchdog and Abort inputs from PMAC
signal PMAC_WATCHDOG        : std_logic;
signal PMAC_ABORT           : std_logic;

-- Front-panel LEDs
signal PS_LED_P             : std_logic_vector(1 downto 0);
signal PL_LED_P             : std_logic_vector(1 downto 0);
signal LedCount             : unsigned(23 downto 0);

-- IO signals (remapping for clarity and compatibility)
signal pins_ENC_A_in        : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_ENC_B_in        : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_ENC_Z_in        : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_ENC_A_out       : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_ENC_B_out       : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_ENC_Z_out       : std_logic_vector(ENC_NUM-1 downto 0);

signal pins_PMAC_SCLK_RX    : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_ENC_SDA_RX      : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_PMAC_SDA_RX     : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_ENC_SCLK_RX     : std_logic_vector(ENC_NUM-1 downto 0);

signal pins_ENC_SCLK_TX     : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_ENC_SDA_TX      : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_ENC_SDA_TX_EN   : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_PMAC_SDA_TX     : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_PMAC_SDA_TX_EN  : std_logic_vector(ENC_NUM-1 downto 0);

signal pins_U               : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_V               : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_W               : std_logic_vector(ENC_NUM-1 downto 0);
signal pins_T               : std_logic_vector(ENC_NUM-1 downto 0);

-- Input Encoder
signal inenc_val            : std32_array(ENC_NUM-1 downto 0);
signal inenc_conn           : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_a              : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_b              : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_z              : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_data           : std_logic_vector(ENC_NUM-1 downto 0);
signal INENC_PROTOCOL       : std32_array(ENC_NUM-1 downto 0);
signal INENC_PROTOCOL_WSTB  : std_logic_vector(ENC_NUM-1 downto 0);

-- Output Encoder
signal outenc_clk           : std_logic_vector(ENC_NUM-1 downto 0);
signal outenc_conn          : std_logic_vector(ENC_NUM-1 downto 0);
signal OUTENC_PROTOCOL      : std32_array(ENC_NUM-1 downto 0);
signal OUTENC_PROTOCOL_WSTB : std_logic_vector(ENC_NUM-1 downto 0);

signal pic_data_in          : std_logic_vector(15 downto 0);
signal pic_data_out         : std_logic_vector(15 downto 0);
signal pic_done             : std_logic := '0';

signal quad_LoS             : std_logic_vector(7 downto 0); --( <= pic_data_in[15:8] )
signal LD_jumpers           : std_logic_vector(7 downto 0); --( <= pic_data_in[7:0]  )
signal serial_pass          : std_logic_vector(7 downto 0);
signal uvwt                 : std_logic_vector(7 downto 0);


-- AUX IO Board signals
signal AuxDin1              : std_logic;
signal AuxDout1             : std_logic;
signal AuxDir1              : std_logic;

signal AuxDin2              : std_logic;
signal AuxDout2             : std_logic;
signal AuxDir2              : std_logic;

signal AuxDin3              : std_logic;
signal AuxDout3             : std_logic;
signal AuxDir3              : std_logic;

signal AuxDin4              : std_logic;
signal AuxDout4             : std_logic;
signal AuxDir4              : std_logic;

signal AuxDin5              : std_logic;
signal AuxDout5             : std_logic;
signal AuxDir5              : std_logic;

signal aux_clk_counter      : unsigned ( 15 downto 0 ) := x"0000";    

signal invAuxDir1           : std_logic;
signal invAuxDir2           : std_logic;
signal invAuxDir3           : std_logic;
signal invAuxDir4           : std_logic;
signal invAuxDir5           : std_logic;

-- SFP+ Clock
signal BUF_GTREFCLK1        : std_logic;

-- Discrete Block Outputs :
signal pcap_active          : std_logic_vector(0 downto 0);
signal ttlin_val            : std_logic_vector(TTLIN_NUM-1 downto 0);
signal ttlout_val           : std_logic_vector(TTLOUT_NUM-1 downto 0);

signal rdma_req             : std_logic_vector(5 downto 0);
signal rdma_ack             : std_logic_vector(5 downto 0);
signal rdma_done            : std_logic;
signal rdma_addr            : std32_array(5 downto 0);
signal rdma_len             : std8_array(5 downto 0);
signal rdma_data            : std_logic_vector(31 downto 0);
signal rdma_valid           : std_logic_vector(5 downto 0);

-- Hard-wiring DCARD_MODE to x"00000002" (CONTROL MODE)
-- This needs to be set by an appropiate block register and tied to corresponding relay setting
signal DCARD_MODE : std32_array(ENC_NUM-1 downto 0) := (others => (1 => '1', others => '0'));

-- SFP Block
signal SFP_MAC_ADDR_ARR     : std32_array(2*NUM_SFP-1 downto 0);
signal SFP_i                : SFP_input_interface;
signal SFP_o                : SFP_output_interface := SFP_o_init;

-- Test the Register Interface (provides dummy data)
signal TEST_VAL             : std_logic_vector(31 downto 0);

begin

-- Internal clocks and resets
FCLK_RESET0 <= not FCLK_RESET0_N(0);
FCLK_CLK0 <= FCLK_CLK0_PS;

---------------------------------------------------------------------------
-- Panda Processor System Block design instantiation
---------------------------------------------------------------------------
ps : entity work.panda_ps
port map (
    FCLK_CLK0                   => FCLK_CLK0_PS,
    PL_CLK                      => FCLK_CLK0,
    FCLK_RESET0_N               => FCLK_RESET0_N,

    IRQ_F2P                     => IRQ_F2P,

    M00_AXI_araddr              => M00_AXI_araddr,
    M00_AXI_arprot              => M00_AXI_arprot,
    M00_AXI_arready             => M00_AXI_arready,
    M00_AXI_arvalid             => M00_AXI_arvalid,
    M00_AXI_awaddr              => M00_AXI_awaddr,
    M00_AXI_awprot              => M00_AXI_awprot,
    M00_AXI_awready             => M00_AXI_awready,
    M00_AXI_awvalid             => M00_AXI_awvalid,
    M00_AXI_bready              => M00_AXI_bready,
    M00_AXI_bresp               => M00_AXI_bresp,
    M00_AXI_bvalid              => M00_AXI_bvalid,
    M00_AXI_rdata               => M00_AXI_rdata,
    M00_AXI_rready              => M00_AXI_rready,
    M00_AXI_rresp               => M00_AXI_rresp,
    M00_AXI_rvalid              => M00_AXI_rvalid,
    M00_AXI_wdata               => M00_AXI_wdata,
    M00_AXI_wready              => M00_AXI_wready,
    M00_AXI_wstrb               => M00_AXI_wstrb,
    M00_AXI_wvalid              => M00_AXI_wvalid,

    S_AXI_HP0_awaddr            => S_AXI_HP0_awaddr ,
    S_AXI_HP0_awburst           => S_AXI_HP0_awburst,
    S_AXI_HP0_awcache           => S_AXI_HP0_awcache,
    S_AXI_HP0_awid              => S_AXI_HP0_awid,
    S_AXI_HP0_awlen             => S_AXI_HP0_awlen,
    S_AXI_HP0_awlock            => S_AXI_HP0_awlock,
    S_AXI_HP0_awprot            => S_AXI_HP0_awprot,
    S_AXI_HP0_awqos             => S_AXI_HP0_awqos,
    S_AXI_HP0_awready           => S_AXI_HP0_awready,
    S_AXI_HP0_awsize            => S_AXI_HP0_awsize,
    S_AXI_HP0_awvalid           => S_AXI_HP0_awvalid,
    S_AXI_HP0_bid               => S_AXI_HP0_bid,
    S_AXI_HP0_bready            => S_AXI_HP0_bready,
    S_AXI_HP0_bresp             => S_AXI_HP0_bresp,
    S_AXI_HP0_bvalid            => S_AXI_HP0_bvalid,
    S_AXI_HP0_wdata             => S_AXI_HP0_wdata,
    S_AXI_HP0_wid               => (others => '0'),
    S_AXI_HP0_wlast             => S_AXI_HP0_wlast,
    S_AXI_HP0_wready            => S_AXI_HP0_wready,
    S_AXI_HP0_wstrb             => S_AXI_HP0_wstrb,
    S_AXI_HP0_wvalid            => S_AXI_HP0_wvalid,

    S_AXI_HP1_araddr            => S_AXI_HP1_araddr,
    S_AXI_HP1_arburst           => S_AXI_HP1_arburst,
    S_AXI_HP1_arcache           => S_AXI_HP1_arcache,
    S_AXI_HP1_arid              => S_AXI_HP1_arid,
    S_AXI_HP1_arlen             => S_AXI_HP1_arlen,
    S_AXI_HP1_arlock            => S_AXI_HP1_arlock,
    S_AXI_HP1_arprot            => S_AXI_HP1_arprot,
    S_AXI_HP1_arqos             => S_AXI_HP1_arqos,
    S_AXI_HP1_arready           => S_AXI_HP1_arready,
    S_AXI_HP1_arsize            => S_AXI_HP1_arsize,
    S_AXI_HP1_arvalid           => S_AXI_HP1_arvalid,
    S_AXI_HP1_rdata             => S_AXI_HP1_rdata,
    S_AXI_HP1_rid               => S_AXI_HP1_rid,
    S_AXI_HP1_rlast             => S_AXI_HP1_rlast,
    S_AXI_HP1_rready            => S_AXI_HP1_rready,
    S_AXI_HP1_rresp             => S_AXI_HP1_rresp,
    S_AXI_HP1_rvalid            => S_AXI_HP1_rvalid

);

---------------------------------------------------------------------------
-- Control and Status Memory Interface
-- Base Address: 0xa0000000
---------------------------------------------------------------------------
axi_lite_slave_inst : entity work.axi_lite_slave
port map (
    clk_i                       => FCLK_CLK0,
    reset_i                     => FCLK_RESET0,

    araddr_i                    => M00_AXI_araddr,
    arprot_i                    => M00_AXI_arprot,
    arready_o                   => M00_AXI_arready,
    arvalid_i                   => M00_AXI_arvalid,

    rdata_o                     => M00_AXI_rdata,
    rresp_o                     => M00_AXI_rresp,
    rready_i                    => M00_AXI_rready,
    rvalid_o                    => M00_AXI_rvalid,

    awaddr_i                    => M00_AXI_awaddr,
    awprot_i                    => M00_AXI_awprot,
    awready_o                   => M00_AXI_awready,
    awvalid_i                   => M00_AXI_awvalid,

    wdata_i                     => M00_AXI_wdata,
    wstrb_i                     => M00_AXI_wstrb,
    wready_o                    => M00_AXI_wready,
    wvalid_i                    => M00_AXI_wvalid,

    bresp_o                     => M00_AXI_bresp,
    bvalid_o                    => M00_AXI_bvalid,
    bready_i                    => M00_AXI_bready,

    read_strobe_o               => read_strobe,
    read_address_o              => read_address,
    read_data_i                 => read_data,
    read_ack_i                  => read_ack,

    write_strobe_o              => write_strobe,
    write_address_o             => write_address,
    write_data_o                => write_data,
    write_ack_i                 => write_ack
);

---------------------------------------------------------------------------
-- TTL
---------------------------------------------------------------------------

ttlin_inst : entity work.ttlin_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    pad_i               => AUX_IO_TTL_IN,
    val_o               => ttlin_val,

    read_strobe_i       => read_strobe(TTLIN_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(TTLIN_CS),
    read_ack_o          => read_ack(TTLIN_CS),

    write_strobe_i      => write_strobe(TTLIN_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(TTLIN_CS),

    bit_bus_i           => bit_bus,
    pos_bus_i           => pos_bus,
    TTLIN_TERM_o        => open,
    TTLIN_TERM_WSTB_o   => open
);

ttlout_inst : entity work.ttlout_top
port map (
    clk_i               => FCLK_CLK0,
    clk_2x_i            => '0',
    reset_i             => FCLK_RESET0,

    read_strobe_i       => read_strobe(TTLOUT_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(TTLOUT_CS),
    read_ack_o          => read_ack(TTLOUT_CS),

    write_strobe_i      => write_strobe(TTLOUT_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(TTLOUT_CS),

    bit_bus_i           => bit_bus,
    val_o               => ttlout_val,
    pad_o               => AUX_IO_TTL_OUT
);

---------------------------------------------------------------------------
-- POSITION CAPTURE
---------------------------------------------------------------------------
pcap_inst : entity work.pcap_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,
    m_axi_awaddr        => S_AXI_HP0_awaddr,
    m_axi_awburst       => S_AXI_HP0_awburst,
    m_axi_awcache       => S_AXI_HP0_awcache,
    m_axi_awid          => S_AXI_HP0_awid,
    m_axi_awlen         => S_AXI_HP0_awlen,
    m_axi_awlock        => S_AXI_HP0_awlock,
    m_axi_awprot        => S_AXI_HP0_awprot,
    m_axi_awqos         => S_AXI_HP0_awqos,
    m_axi_awready       => S_AXI_HP0_awready,
    m_axi_awregion      => S_AXI_HP0_awregion,
    m_axi_awsize        => S_AXI_HP0_awsize,
    m_axi_awvalid       => S_AXI_HP0_awvalid,
    m_axi_bid           => S_AXI_HP0_bid,
    m_axi_bready        => S_AXI_HP0_bready,
    m_axi_bresp         => S_AXI_HP0_bresp,
    m_axi_bvalid        => S_AXI_HP0_bvalid,
    m_axi_wdata         => S_AXI_HP0_wdata,
    m_axi_wlast         => S_AXI_HP0_wlast,
    m_axi_wready        => S_AXI_HP0_wready,
    m_axi_wstrb         => S_AXI_HP0_wstrb,
    m_axi_wvalid        => S_AXI_HP0_wvalid,

    read_address_i      => read_address,
    read_strobe_i       => read_strobe,
    read_data_0_o       => read_data(PCAP_CS),
    read_ack_0_o        => read_ack(PCAP_CS),
    read_data_1_o       => read_data(DRV_CS),
    read_ack_1_o        => read_ack(DRV_CS),

    write_strobe_i      => write_strobe,
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_0_o       => write_ack(PCAP_CS),
    write_ack_1_o       => write_ack(DRV_CS),

    bit_bus_i           => bit_bus,
    pos_bus_i           => pos_bus,
    pcap_actv_o         => pcap_active(0),
    pcap_irq_o          => IRQ_F2P(0)
);

---------------------------------------------------------------------------
-- TABLE DMA ENGINE
---------------------------------------------------------------------------
table_engine : entity work.table_read_engine
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,
    -- Zynq HP1 Bus
    m_axi_araddr        => S_AXI_HP1_araddr,
    m_axi_arburst       => S_AXI_HP1_arburst,
    m_axi_arcache       => S_AXI_HP1_arcache,
    m_axi_arid          => S_AXI_HP1_arid,
    m_axi_arlen         => S_AXI_HP1_arlen,
    m_axi_arlock        => S_AXI_HP1_arlock,
    m_axi_arprot        => S_AXI_HP1_arprot,
    m_axi_arqos         => S_AXI_HP1_arqos,
    m_axi_arready       => S_AXI_HP1_arready,
    m_axi_arregion      => S_AXI_HP1_arregion,
    m_axi_arsize        => S_AXI_HP1_arsize,
    m_axi_arvalid       => S_AXI_HP1_arvalid,
    m_axi_rdata         => S_AXI_HP1_rdata,
    m_axi_rid           => S_AXI_HP1_rid,
    m_axi_rlast         => S_AXI_HP1_rlast,
    m_axi_rready        => S_AXI_HP1_rready,
    m_axi_rresp         => S_AXI_HP1_rresp,
    m_axi_rvalid        => S_AXI_HP1_rvalid,

    -- Slaves' DMA Engine Interface
    dma_req_i           => rdma_req,
    dma_ack_o           => rdma_ack,
    dma_done_o          => rdma_done,
    dma_addr_i          => rdma_addr,
    dma_len_i           => rdma_len,
    dma_data_o          => rdma_data,
    dma_valid_o         => rdma_valid
);

---------------------------------------------------------------------------
-- REG (System, Position Bus and Special Register Readbacks)
---------------------------------------------------------------------------
reg_inst : entity work.reg_top
generic map (
    NUM_SFP => NUM_SFP,
    NUM_FMC => NUM_FMC)
port map (
    clk_i               => FCLK_CLK0,

    read_strobe_i       => read_strobe(REG_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(REG_CS),
    read_ack_o          => read_ack(REG_CS),

    write_strobe_i      => write_strobe(REG_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(REG_CS),

    bit_bus_i           => bit_bus,
    pos_bus_i           => pos_bus,
    SLOW_FPGA_VERSION   => (others => '0'),
    SFP_MAC_ADDR        => SFP_MAC_ADDR_ARR,
    SFP_MAC_ADDR_WSTB   => open,
    FMC_MAC_ADDR        => open,
    FMC_MAC_ADDR_WSTB   => open
);
  
-- ========== RIBBON CABLE PINOUTS ==========

-- AUX_IO (SPI/TTL) Board  (40 way ribbon to ST1 IO0)...
-- 
AUX_IO_DATA(1)   <= IO0_D0_P;
AUX_IO_DATA(2)   <= IO0_D2_P;
AUX_IO_DATA(3)   <= IO0_D4_P;
AUX_IO_DATA(4)   <= IO0_D6_P;
AUX_IO_DATA(5)   <= IO0_D9_N;
    
AUX_IO_DIR(1)    <= IO0_D1_N;
AUX_IO_DIR(2)    <= IO0_D3_N;
AUX_IO_DIR(3)    <= IO0_D5_N;
AUX_IO_DIR(4)    <= IO0_D7_N;
AUX_IO_DIR(5)    <= IO0_D8_P;
    
AUX_IO_TTL_IN(0)  <= IO0_D21_N;
AUX_IO_TTL_IN(1)  <= IO0_D20_P;
    
AUX_IO_TTL_OUT(0) <= IO0_D23_N;
AUX_IO_TTL_OUT(1) <= IO0_D22_P;


-- EQU Inputs from PMAC (12 way ribbon to ST1 IO3)...

EQU_IN(1)        <= IO3_D0_P;
EQU_IN(2)        <= IO3_D1_N;
EQU_IN(3)        <= IO3_D2_P;
EQU_IN(4)        <= IO3_D3_N;
EQU_IN(5)        <= IO3_D4_P;
EQU_IN(6)        <= IO3_D5_N;
EQU_IN(7)        <= IO3_D6_P;
EQU_IN(8)        <= IO3_D7_N;


-- Watchdog and Abort Inputs from PMAC (12 way ribbon to ST1 IO4)...

PMAC_WATCHDOG   <= IO4_D2_P;
PMAC_ABORT      <= IO4_D3_N;


-- ========== FMC Pinout ==========

-- PIC Microcontroller...
-- (IO expander for LD relays, mode (pass through etc) 

PIC_SPI_SC <= FMC_CLK0_M2C_P;
PIC_SPI_CS <= FMC_CLK0_M2C_N;
PIC_SPI_DI <= FMC_CLK1_M2C_P;
PIC_SPI_DO <= FMC_CLK1_M2C_N;


-- XU5... (has first two driver boards)

LD_FPGA_IN_AXIS_1(0) <= FMC_LA02_P; 
LD_FPGA_IN_AXIS_1(1) <= FMC_LA02_N;
LD_FPGA_IN_AXIS_1(2) <= FMC_LA03_P;
LD_FPGA_IN_AXIS_1(3) <= FMC_LA03_N;
LD_FPGA_IN_AXIS_1(4) <= FMC_LA06_P;
LD_FPGA_IN_AXIS_1(5) <= FMC_LA06_N;
LD_FPGA_IN_AXIS_1(6) <= FMC_LA04_P;
--(7)unused

FMC_LA05_P <= LD_FPGA_OUT_AXIS_1(0);
FMC_LA05_N <= LD_FPGA_OUT_AXIS_1(1);
FMC_LA10_P <= LD_FPGA_OUT_AXIS_1(2);
FMC_LA10_N <= LD_FPGA_OUT_AXIS_1(3);
FMC_LA08_P <= LD_FPGA_OUT_AXIS_1(4);
FMC_LA08_N <= LD_FPGA_OUT_AXIS_1(5);
FMC_LA07_P <= LD_FPGA_OUT_AXIS_1(6);
FMC_LA07_N <= LD_FPGA_OUT_AXIS_1(7);


LD_FPGA_IN_AXIS_5(0) <= FMC_LA04_N;
LD_FPGA_IN_AXIS_5(1) <= FMC_LA09_P;
LD_FPGA_IN_AXIS_5(2) <= FMC_LA09_N;
LD_FPGA_IN_AXIS_5(3) <= FMC_LA12_P;
LD_FPGA_IN_AXIS_5(4) <= FMC_LA12_N;
LD_FPGA_IN_AXIS_5(5) <= FMC_LA11_P;
LD_FPGA_IN_AXIS_5(6) <= FMC_LA11_N;
--(7)unused

FMC_LA14_P <= LD_FPGA_OUT_AXIS_5(0);
FMC_LA14_N <= LD_FPGA_OUT_AXIS_5(1);
FMC_LA13_P <= LD_FPGA_OUT_AXIS_5(2);
FMC_LA13_N <= LD_FPGA_OUT_AXIS_5(3);
FMC_LA16_P <= LD_FPGA_OUT_AXIS_5(4);
FMC_LA16_N <= LD_FPGA_OUT_AXIS_5(5);
FMC_LA15_P <= LD_FPGA_OUT_AXIS_5(6);
FMC_LA15_N <= LD_FPGA_OUT_AXIS_5(7);


LD_FPGA_IN_AXIS_2(0) <= FMC_LA20_P; 
LD_FPGA_IN_AXIS_2(1) <= FMC_LA20_N;
LD_FPGA_IN_AXIS_2(2) <= FMC_LA19_P;
LD_FPGA_IN_AXIS_2(3) <= FMC_LA19_N;
LD_FPGA_IN_AXIS_2(4) <= FMC_LA22_P;
LD_FPGA_IN_AXIS_2(5) <= FMC_LA22_N;
LD_FPGA_IN_AXIS_2(6) <= FMC_LA23_P;
--(7)unused

FMC_LA27_P <= LD_FPGA_OUT_AXIS_2(0);
FMC_LA27_N <= LD_FPGA_OUT_AXIS_2(1);
FMC_LA26_P <= LD_FPGA_OUT_AXIS_2(2);
FMC_LA26_N <= LD_FPGA_OUT_AXIS_2(3);
FMC_LA25_P <= LD_FPGA_OUT_AXIS_2(4);
FMC_LA25_N <= LD_FPGA_OUT_AXIS_2(5);
FMC_LA21_P <= LD_FPGA_OUT_AXIS_2(6);
FMC_LA21_N <= LD_FPGA_OUT_AXIS_2(7);

LD_FPGA_IN_AXIS_6(0) <= FMC_LA23_N;
LD_FPGA_IN_AXIS_6(1) <= FMC_LA29_P;
LD_FPGA_IN_AXIS_6(2) <= FMC_LA29_N;
LD_FPGA_IN_AXIS_6(3) <= FMC_LA24_P;
LD_FPGA_IN_AXIS_6(4) <= FMC_LA24_N;
LD_FPGA_IN_AXIS_6(5) <= FMC_LA28_P;
LD_FPGA_IN_AXIS_6(6) <= FMC_LA28_N;
--(7)unused

FMC_LA31_P <= LD_FPGA_OUT_AXIS_6(0);
FMC_LA31_N <= LD_FPGA_OUT_AXIS_6(1);
FMC_LA30_P <= LD_FPGA_OUT_AXIS_6(2);
FMC_LA30_N <= LD_FPGA_OUT_AXIS_6(3);
FMC_LA33_P <= LD_FPGA_OUT_AXIS_6(4);
FMC_LA33_N <= LD_FPGA_OUT_AXIS_6(5);
FMC_LA32_P <= LD_FPGA_OUT_AXIS_6(6);
FMC_LA32_N <= LD_FPGA_OUT_AXIS_6(7);
  
-- IO remapping, converts driver board io to grouped vectors.

--Axis 1 (INEC1)...

pins_ENC_A_in(0)      <= LD_FPGA_IN_AXIS_1(0);
pins_ENC_B_in(0)      <= LD_FPGA_IN_AXIS_1(1);
pins_ENC_Z_in(0)      <= LD_FPGA_IN_AXIS_1(2);

pins_PMAC_SCLK_RX(0)  <= LD_FPGA_IN_AXIS_1(3);
pins_ENC_SDA_RX(0)    <= LD_FPGA_IN_AXIS_1(4);
pins_PMAC_SDA_RX(0)   <= LD_FPGA_IN_AXIS_1(5);
pins_ENC_SCLK_RX(0)   <= LD_FPGA_IN_AXIS_1(6);

pins_U(0)             <= LD_FPGA_IN_AXIS_1(3);
pins_V(0)             <= LD_FPGA_IN_AXIS_1(4);
pins_W(0)             <= LD_FPGA_IN_AXIS_1(5);
pins_T(0)             <= LD_FPGA_IN_AXIS_1(6);

LD_FPGA_OUT_AXIS_1(0) <= pins_ENC_A_in(0);
LD_FPGA_OUT_AXIS_1(1) <= pins_ENC_B_in(0);
LD_FPGA_OUT_AXIS_1(2) <= pins_ENC_Z_in(0);

LD_FPGA_OUT_AXIS_1(3) <= pins_ENC_SCLK_TX(0);
LD_FPGA_OUT_AXIS_1(4) <= pins_ENC_SDA_TX(0);
LD_FPGA_OUT_AXIS_1(5) <= pins_ENC_SDA_TX_EN(0);
LD_FPGA_OUT_AXIS_1(6) <= pins_PMAC_SDA_TX(0);
LD_FPGA_OUT_AXIS_1(7) <= pins_PMAC_SDA_TX_EN(0);

--Axis 2 (INENC2)...

pins_ENC_A_in(1)      <= LD_FPGA_IN_AXIS_2(0);
pins_ENC_B_in(1)      <= LD_FPGA_IN_AXIS_2(1);
pins_ENC_Z_in(1)      <= LD_FPGA_IN_AXIS_2(2);

pins_PMAC_SCLK_RX(1)  <= LD_FPGA_IN_AXIS_2(3);
pins_ENC_SDA_RX(1)    <= LD_FPGA_IN_AXIS_2(4);
pins_PMAC_SDA_RX(1)   <= LD_FPGA_IN_AXIS_2(5);
pins_ENC_SCLK_RX(1)   <= LD_FPGA_IN_AXIS_2(6);

pins_U(1)             <= LD_FPGA_IN_AXIS_2(3);
pins_V(1)             <= LD_FPGA_IN_AXIS_2(4);
pins_W(1)             <= LD_FPGA_IN_AXIS_2(5);
pins_T(1)             <= LD_FPGA_IN_AXIS_2(6);

LD_FPGA_OUT_AXIS_2(0) <= pins_ENC_A_in(1);
LD_FPGA_OUT_AXIS_2(1) <= pins_ENC_B_in(1);
LD_FPGA_OUT_AXIS_2(2) <= pins_ENC_Z_in(1);

LD_FPGA_OUT_AXIS_2(3) <= pins_ENC_SCLK_TX(1);
LD_FPGA_OUT_AXIS_2(4) <= pins_ENC_SDA_TX(1);
LD_FPGA_OUT_AXIS_2(5) <= pins_ENC_SDA_TX_EN(1);
LD_FPGA_OUT_AXIS_2(6) <= pins_PMAC_SDA_TX(1);
LD_FPGA_OUT_AXIS_2(7) <= pins_PMAC_SDA_TX_EN(1);

--Axis 5 (INENC3)...

pins_ENC_A_in(2)      <= LD_FPGA_IN_AXIS_5(0);
pins_ENC_B_in(2)      <= LD_FPGA_IN_AXIS_5(1);
pins_ENC_Z_in(2)      <= LD_FPGA_IN_AXIS_5(2);

pins_PMAC_SCLK_RX(2)  <= LD_FPGA_IN_AXIS_5(3);
pins_ENC_SDA_RX(2)    <= LD_FPGA_IN_AXIS_5(4);
pins_PMAC_SDA_RX(2)   <= LD_FPGA_IN_AXIS_5(5);
pins_ENC_SCLK_RX(2)   <= LD_FPGA_IN_AXIS_5(6);

pins_U(2)             <= LD_FPGA_IN_AXIS_5(3);
pins_V(2)             <= LD_FPGA_IN_AXIS_5(4);
pins_W(2)             <= LD_FPGA_IN_AXIS_5(5);
pins_T(2)             <= LD_FPGA_IN_AXIS_5(6);

LD_FPGA_OUT_AXIS_5(0) <= pins_ENC_A_in(2);
LD_FPGA_OUT_AXIS_5(1) <= pins_ENC_B_in(2);
LD_FPGA_OUT_AXIS_5(2) <= pins_ENC_Z_in(2);

LD_FPGA_OUT_AXIS_5(3) <= pins_ENC_SCLK_TX(2);
LD_FPGA_OUT_AXIS_5(4) <= pins_ENC_SDA_TX(2);
LD_FPGA_OUT_AXIS_5(5) <= pins_ENC_SDA_TX_EN(2);
LD_FPGA_OUT_AXIS_5(6) <= pins_PMAC_SDA_TX(2);
LD_FPGA_OUT_AXIS_5(7) <= pins_PMAC_SDA_TX_EN(2);

 --Axis 6 (INENC4)...

pins_ENC_A_in(3)      <= LD_FPGA_IN_AXIS_6(0);
pins_ENC_B_in(3)      <= LD_FPGA_IN_AXIS_6(1);
pins_ENC_Z_in(3)      <= LD_FPGA_IN_AXIS_6(2);

pins_PMAC_SCLK_RX(3)  <= LD_FPGA_IN_AXIS_6(3);
pins_ENC_SDA_RX(3)    <= LD_FPGA_IN_AXIS_6(4);
pins_PMAC_SDA_RX(3)   <= LD_FPGA_IN_AXIS_6(5);
pins_ENC_SCLK_RX(3)   <= LD_FPGA_IN_AXIS_6(6);

pins_U(3)             <= LD_FPGA_IN_AXIS_6(3);
pins_V(3)             <= LD_FPGA_IN_AXIS_6(4);
pins_W(3)             <= LD_FPGA_IN_AXIS_6(5);
pins_T(3)             <= LD_FPGA_IN_AXIS_6(6);

LD_FPGA_OUT_AXIS_6(0) <= pins_ENC_A_in(3);
LD_FPGA_OUT_AXIS_6(1) <= pins_ENC_B_in(3);
LD_FPGA_OUT_AXIS_6(2) <= pins_ENC_Z_in(3);

LD_FPGA_OUT_AXIS_6(3) <= pins_ENC_SCLK_TX(3);
LD_FPGA_OUT_AXIS_6(4) <= pins_ENC_SDA_TX(3);
LD_FPGA_OUT_AXIS_6(5) <= pins_ENC_SDA_TX_EN(3);
LD_FPGA_OUT_AXIS_6(6) <= pins_PMAC_SDA_TX(3);
LD_FPGA_OUT_AXIS_6(7) <= pins_PMAC_SDA_TX_EN(3);

-----------------------------------------------------------------------------
---- ENCODERS (Encoder Inputs)
-----------------------------------------------------------------------------

encoders_top_inst : entity work.pandabrick_encoders_top
port map (
    -- Clock and Reset
    clk_i                   => FCLK_CLK0,
    reset_i                 => FCLK_RESET0,
    
    -- Memory Bus Interface
    OUTENC_read_strobe_i    => read_strobe(OUTENC_CS),
    OUTENC_read_data_o      => read_data(OUTENC_CS),
    OUTENC_read_ack_o       => read_ack(OUTENC_CS),

    OUTENC_write_strobe_i   => write_strobe(OUTENC_CS),
    OUTENC_write_ack_o      => write_ack(OUTENC_CS),

    INENC_read_strobe_i     => read_strobe(INENC_CS),
    INENC_read_data_o       => read_data(INENC_CS),
    INENC_read_ack_o        => read_ack(INENC_CS),
    INENC_write_strobe_i    => write_strobe(INENC_CS),
    INENC_write_ack_o       => write_ack(INENC_CS),
    read_address_i          => read_address,
    write_address_i         => write_address,
    write_data_i            => write_data,
    
    -- Encoder I/O Pads
    OUTENC_CONN_OUT_o       => outenc_conn,
    INENC_CONN_OUT_o        => inenc_conn,

    pins_ENC_A_in           => pins_ENC_A_in,
    pins_ENC_B_in           => pins_ENC_B_in,
    pins_ENC_Z_in           => pins_ENC_Z_in,
    pins_ENC_A_out          => pins_ENC_A_out,
    pins_ENC_B_out          => pins_ENC_B_out,
    pins_ENC_Z_out          => pins_ENC_Z_out,
    
    pins_PMAC_SCLK_RX       => pins_PMAC_SCLK_RX,
    pins_ENC_SDA_RX         => pins_ENC_SDA_RX,
    pins_PMAC_SDA_RX        => pins_PMAC_SDA_RX,
    pins_ENC_SCLK_RX        => pins_ENC_SCLK_RX,
    
    pins_ENC_SCLK_TX        => pins_ENC_SCLK_TX,
    pins_ENC_SDA_TX         => pins_ENC_SDA_TX,
    pins_ENC_SDA_TX_EN      => pins_ENC_SDA_TX_EN,
    pins_PMAC_SDA_TX        => pins_PMAC_SDA_TX,
	pins_PMAC_SDA_TX_EN     => pins_PMAC_SDA_TX_EN,
    

    -- Signals passed to internal bus
    clk_int_o               => outenc_clk,
    inenc_a_o               => inenc_a,
    inenc_b_o               => inenc_b,
    inenc_z_o               => inenc_z,
    inenc_data_o            => inenc_data,
    -- Block Input and Outputs
    bit_bus_i               => bit_bus,
    pos_bus_i               => pos_bus,
    DCARD_MODE_i            => DCARD_MODE,
    posn_o                  => inenc_val,

    OUTENC_PROTOCOL_o       => OUTENC_PROTOCOL,
    OUTENC_PROTOCOL_WSTB_o  => OUTENC_PROTOCOL_WSTB,
    INENC_PROTOCOL_o        => INENC_PROTOCOL,
    INENC_PROTOCOL_WSTB_o   => INENC_PROTOCOL_WSTB
);

-- Bus assembly ----

-- BIT_BUS_SIZE and POS_BUS_SIZE declared in addr_defines.vhd

bit_bus(BIT_BUS_SIZE-1 downto 0 ) <= pcap_active & outenc_clk & inenc_conn &
                                   inenc_data & inenc_z & inenc_b & inenc_a &
                                   ttlin_val;

pos_bus(POS_BUS_SIZE-1 downto 0) <= inenc_val;

---------------------------------------------------------------------------
-- Test the Register Interface (provides dummy data)
---------------------------------------------------------------------------

TEST_VAL <= (x"0000" & pic_data_in(15 downto 0));  --x"00000000", --TEST_VAL_IN,

test_regs_inst : entity work.test_regs
port map (
    clk_i         => FCLK_CLK0,
    test_val      => TEST_VAL,
    read_strobe   => read_strobe(PANDABRICK_TEST_CS),
    read_address  => read_address,
    read_data     => read_data(PANDABRICK_TEST_CS),
    read_ack      => read_ack(PANDABRICK_TEST_CS),

    write_strobe  => write_strobe(PANDABRICK_TEST_CS),
    write_address => write_address,
    write_data    => write_data,
    write_ack     => write_ack(PANDABRICK_TEST_CS)
);

---------------------------------------------------------------------------------
-- Adaptor-Board PIC SPI Interface (relay driver and Quadrature LoS detector.)
---------------------------------------------------------------------------------

-- Data to be passed to PIC...
uvwt         <= "00000000";
serial_pass  <= "11001100";
pic_data_out <= ( uvwt & serial_pass );


-- Data returned from PIC...
quad_LoS   <= pic_data_in(15 downto 8);
LD_jumpers <= pic_data_in(7 downto 0);


-----Instance of SPI controller -----

Adaptor_PIC_SPI_inst : Adaptor_PIC_SPI
port map (
    i_clk     => FCLK_CLK0,    -- 125MHz System (AXI) clock.
    o_PIC_SC  => PIC_SPI_SC,      -- SPI Serial Clock
    o_PIC_CS  => PIC_SPI_CS,      -- SPI Chip Select (low during transfer)
    o_PIC_DI  => PIC_SPI_DI,      -- SPI PIC Data In (to PIC)
    i_PIC_DO  => PIC_SPI_DO,      -- SPI PIC Data Out (from PIC) 
    o_done    => pic_done,        -- Transfer finished on Rising edge of this output.
    i_data    => pic_data_out,    -- Data to send to the PIC.
                                  --    UVWT read mode   - Axis 8-1 on i_data[15:8]  - '1' sets uvwt mode
                                  --    Serial Pass mode - Axis 8-1 on i_data[7:0]   - '1' sets pass-through mode
    o_data    => pic_data_in      -- Data received from the PIC.
                                  --    LoS        - Axis 8-1 on o_data[15:8]
                                  --    LD Jumpers - Axis 8-1 on o_data[7:0]         - '0' if jumper fitted        
);

        
-- ***** THERE IS NOWHERE TO PUT THE LoS INPUTS *****
-- (should be tied in to 'Health' as per BISS decoder?

-- Latch new SPI Data...
--process(pic_done)
--begin
--    if rising_edge(pic_done) then
--        --quad_LoS
--        --LD_jumpers
--    end if;
--end process;

---------------------------------------
--   SFP+ BUFFERING
---------------------------------------

-- REFCLOCK Differential Buffer...

IBUFDS_GTE4_inst : IBUFDS_GTE4
generic map (
    REFCLK_EN_TX_PATH => '0',
    REFCLK_HROW_CK_SEL => "00",
    REFCLK_ICNTL_RX => "00" -- Refer to Transceiver User Guide.
)
port map (
    O =>     BUF_GTREFCLK1,
    ODIV2 => open,
    CEB =>   '0',
    I =>     mgtrefclk1_x0y1_p,
    IB =>    mgtrefclk1_x0y1_n
);

-- SFP+ Data pind not buffered...
--  From UG576 - "These ports represent the pads. The locations of these ports must be constrained 
--                   (see Implementation, page 24) and brought to the top level of the design.

-------------------------------------------------------------------
----    Aux IO Board   (Quick Test)
-------------------------------------------------------------------

-- Bidirectional IO1...

IOBUF1_inst : IOBUF
port map (
    O  => AuxDin1,
    I  => AuxDout1,
    IO => AUX_IO_DATA(1),
    T  => invAuxDir1
);

OBUF1_inst : OBUF
port map (
    O => AUX_IO_DIR(1),
    I => AuxDir1
);


-- Bidirectional IO2...

IOBUF2_inst : IOBUF
port map (
    O  => AuxDin2,
    I  => AuxDout2,
    IO => AUX_IO_DATA(2),
    T  => invAuxDir2
);

OBUF2_inst : OBUF
port map (
    O => AUX_IO_DIR(2),
    I => AuxDir2
);

-- Bidirectional IO3...

IOBUF3_inst : IOBUF
port map (
    O  => AuxDin3,
    I  => AuxDout3,
    IO => AUX_IO_DATA(3),
    T  => invAuxDir3
);

OBUF3_inst : OBUF
port map (
    O => AUX_IO_DIR(3),
    I => AuxDir3
);

-- Bidirectional IO4...

IOBUF4_inst : IOBUF
port map (
    O  => AuxDin4,
    I  => AuxDout4,
    IO => AUX_IO_DATA(4),
    T  => invAuxDir4
);

OBUF4_inst : OBUF
port map (
    O => AUX_IO_DIR(4),
    I => AuxDir4
);

-- Bidirectional IO5...

IOBUF5_inst : IOBUF
port map (
    O  => AuxDin5,
    I  => AuxDout5,
    IO => AUX_IO_DATA(5),
    T  => invAuxDir5
);

OBUF5_inst : OBUF
port map (
    O => AUX_IO_DIR(5),
    I => AuxDir5
);

-- Run a counter...
process(FCLK_CLK0)
begin
    if rising_edge(FCLK_CLK0) then
        aux_clk_counter <= aux_clk_counter + 1;
    end if;
end process;

AuxDir1 <= '1'; -- first three lines set to output
AuxDir2 <= '1';
AuxDir3 <= '1';
AuxDout1 <= aux_clk_counter(15);    -- output a 3-bit count
AuxDout2 <= aux_clk_counter(14);
AuxDout3 <= aux_clk_counter(13);

AuxDir4 <= '0';      -- Data4 to input mode
AuxDir5 <= '1';      -- Data5 to output mode
AuxDout5 <= AuxDin4; -- Echo Data4 input to Data5 output.

invAuxDir1 <= not AuxDir1;
invAuxDir2 <= not AuxDir2;
invAuxDir3 <= not AuxDir3;
invAuxDir4 <= not AuxDir4;
invAuxDir5 <= not AuxDir5;

-- LED TEST

PL_LED_P(0) <= '1'; --aux_clk_counter(15);
PL_LED_P(1) <= '1'; --aux_clk_counter(14);

process (FCLK_CLK0)
begin
if rising_edge (FCLK_CLK0) then
  if FCLK_RESET0 = '1' then
    LedCount    <= (others => '0');
  else
    LedCount    <= LedCount + 1;
  end if;
end if;
end process;

-- ========== LEDs on XU5 Module ==========

Led1_N <= '0' when LedCount(LedCount'high) = '0' else 'Z';

-- ========== PS LEDs to Front Panel ==========

IO4_D4_P <= PS_LED_P(0);
IO4_D5_N <= PS_LED_P(1);

-- ========== PL LEDs to Front Panel ==========

IO4_D6_P <= PL_LED_P(0);
IO4_D7_N <= PL_LED_P(1);

-- Assemble SFP records
SFP_i.SFP_LOS <= '0';  -- NB: Hard-coded to '0' as not brought out onto pin!
SFP_i.GTREFCLK <= BUF_GTREFCLK1;
SFP_i.RXN_IN <= ch0_gthrxn_in;
SFP_i.RXP_IN <= ch0_gthrxp_in;
ch0_gthtxn_out <= SFP_o.TXN_OUT;
ch0_gthtxp_out <= SFP_o.TXP_OUT;
SFP_i.MAC_ADDR <= SFP_MAC_ADDR_ARR(1)(23 downto 0) & SFP_MAC_ADDR_ARR(0)(23 downto 0);
SFP_i.MAC_ADDR_WS <= '0';

---------------------------------------------------------------------------
-- PandABlocks_top Instantiation (autogenerated!!)
---------------------------------------------------------------------------

softblocks_inst : entity work.soft_blocks
generic map( SIM => SIM)
port map(
    FCLK_CLK0 => FCLK_CLK0,
    FCLK_RESET0 => FCLK_RESET0,
    read_strobe => read_strobe,
    read_address => read_address,
    read_data => read_data(MOD_COUNT-1 downto CARRIER_MOD_COUNT),
    read_ack => read_ack(MOD_COUNT-1 downto CARRIER_MOD_COUNT),
    write_strobe => write_strobe,
    write_address => write_address,
    write_data => write_data,
    write_ack => write_ack(MOD_COUNT-1 downto CARRIER_MOD_COUNT),
    bit_bus_i => bit_bus,
    bit_bus_o => bit_bus(BBUSW-1 downto BIT_BUS_SIZE),
    pos_bus_i => pos_bus,
    pos_bus_o => pos_bus(PBUSW-1 downto POS_BUS_SIZE),
    rdma_req => rdma_req,
    rdma_ack => rdma_ack,
    rdma_done => rdma_done,
    rdma_addr => rdma_addr,
    rdma_len => rdma_len,
    rdma_data => rdma_data,
    rdma_valid => rdma_valid,
    SFP_i => SFP_i,
    SFP_o => SFP_o
);

us_system_top_inst : entity work.us_system_top
port map (
    clk_i => FCLK_CLK0,
    read_strobe_i       => read_strobe(US_SYSTEM_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(US_SYSTEM_CS),
    read_ack_o          => read_ack(US_SYSTEM_CS),

    write_strobe_i      => write_strobe(US_SYSTEM_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(US_SYSTEM_CS)
);

end rtl;

