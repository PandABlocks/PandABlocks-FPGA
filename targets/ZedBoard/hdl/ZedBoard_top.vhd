--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : PandA Zynq Top-Level Design File
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all; -- NEEDED?

library work;
--use work.support.all;
use work.addr_defines.all; -- NEEDED?
use work.top_defines.all;  -- NEEDED?

entity ZedBoard_top is
generic (
    SIM                 : string  := "FALSE";
    AXI_ADDR_WIDTH      : integer := 32;
    AXI_DATA_WIDTH      : integer := 32;
    NUM_SFP             : natural := 3;
    NUM_FMC             : natural := 1
);
port (
    DDR_addr            : inout std_logic_vector (14 downto 0);
    DDR_ba              : inout std_logic_vector (2 downto 0);
    DDR_cas_n           : inout std_logic;
    DDR_ck_n            : inout std_logic;
    DDR_ck_p            : inout std_logic;
    DDR_cke             : inout std_logic;
    DDR_cs_n            : inout std_logic;
    DDR_dm              : inout std_logic_vector (3 downto 0);
    DDR_dq              : inout std_logic_vector (31 downto 0);
    DDR_dqs_n           : inout std_logic_vector (3 downto 0);
    DDR_dqs_p           : inout std_logic_vector (3 downto 0);
    DDR_odt             : inout std_logic;
    DDR_ras_n           : inout std_logic;
    DDR_reset_n         : inout std_logic;
    DDR_we_n            : inout std_logic;
    FIXED_IO_ddr_vrn    : inout std_logic;
    FIXED_IO_ddr_vrp    : inout std_logic;
    FIXED_IO_mio        : inout std_logic_vector (53 downto 0);
    FIXED_IO_ps_clk     : inout std_logic;
    FIXED_IO_ps_porb    : inout std_logic;
    FIXED_IO_ps_srstb   : inout std_logic;
    IIC_0_0_scl_io      : inout STD_LOGIC;
    IIC_0_0_sda_io      : inout STD_LOGIC;

	--Zedboard I/Os
	btnR : in std_logic;
	btnC : in std_logic;
	btnD : in std_logic;
	btnU : in std_logic;
	oled_sdin : out std_logic := 'Z';
	oled_sclk : out std_logic := 'Z';
	oled_dc : out std_logic := 'Z';
	oled_res : out std_logic := 'Z';
	oled_vbat : out std_logic := 'Z';
	oled_vdd : out std_logic := 'Z';
	led : out std_logic_vector(7 downto 0) := X"aa";
	SW : in std_logic_vector(7 downto 0); 

    FMC_PRSNT           : in    std_logic;
    FMC_LA_P            : inout std_logic_vector(33 downto 0) := (others => 'Z');
    FMC_LA_N            : inout std_logic_vector(33 downto 0) := (others => 'Z');
    FMC_CLK0_M2C_P      : inout std_logic := 'Z';
    FMC_CLK0_M2C_N      : inout std_logic := 'Z';
    FMC_CLK1_M2C_P      : in    std_logic;
    FMC_CLK1_M2C_N      : in    std_logic
);
end ZedBoard_top;

architecture rtl of ZedBoard_top is

-- Zynq PS Block
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
-- Daughter card control signals

signal pcap_active          : std_logic_vector(0 downto 0);

signal rdma_req             : std_logic_vector(5 downto 0);
signal rdma_ack             : std_logic_vector(5 downto 0);
signal rdma_done            : std_logic;
signal rdma_addr            : std32_array(5 downto 0);
signal rdma_len             : std8_array(5 downto 0);
signal rdma_data            : std_logic_vector(31 downto 0);
signal rdma_valid           : std_logic_vector(5 downto 0);

signal SLOW_FPGA_VERSION    : std_logic_vector(31 downto 0);

signal SFP_MAC_ADDR_ARR     : std32_array(2*NUM_SFP-1 downto 0);
signal FMC_MAC_ADDR_ARR     : std32_array(2*NUM_FMC-1 downto 0);

-- FMC Block
signal FMC_i  : FMC_input_interface;
signal FMC_io : FMC_inout_interface  := FMC_io_init;

component panda_ps is
  port (
    FCLK_CLK0 : out STD_LOGIC;
    FCLK_RESET0_N : out STD_LOGIC_VECTOR ( 0 to 0 );
    IRQ_F2P : in STD_LOGIC_VECTOR ( 0 to 0 );
    PL_CLK : in STD_LOGIC;
    S_AXI_HP1_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_arlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP1_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_arlock : in STD_LOGIC_VECTOR ( 0 to 0 );
    S_AXI_HP1_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_arvalid : in STD_LOGIC;
    S_AXI_HP1_arready : out STD_LOGIC;
    S_AXI_HP1_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_rlast : out STD_LOGIC;
    S_AXI_HP1_rvalid : out STD_LOGIC;
    S_AXI_HP1_rready : in STD_LOGIC;
    S_AXI_HP0_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_awlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_awlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_awvalid : in STD_LOGIC;
    S_AXI_HP0_awready : out STD_LOGIC;
    S_AXI_HP0_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_wlast : in STD_LOGIC;
    S_AXI_HP0_wvalid : in STD_LOGIC;
    S_AXI_HP0_wready : out STD_LOGIC;
    S_AXI_HP0_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_bvalid : out STD_LOGIC;
    S_AXI_HP0_bready : in STD_LOGIC;
    DDR_cas_n : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    IIC_0_0_sda_i : in STD_LOGIC;
    IIC_0_0_sda_o : out STD_LOGIC;
    IIC_0_0_sda_t : out STD_LOGIC;
    IIC_0_0_scl_i : in STD_LOGIC;
    IIC_0_0_scl_o : out STD_LOGIC;
    IIC_0_0_scl_t : out STD_LOGIC;
    M00_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_awvalid : out STD_LOGIC;
    M00_AXI_awready : in STD_LOGIC;
    M00_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M00_AXI_wvalid : out STD_LOGIC;
    M00_AXI_wready : in STD_LOGIC;
    M00_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_bvalid : in STD_LOGIC;
    M00_AXI_bready : out STD_LOGIC;
    M00_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_arvalid : out STD_LOGIC;
    M00_AXI_arready : in STD_LOGIC;
    M00_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_rvalid : in STD_LOGIC;
    M00_AXI_rready : out STD_LOGIC;
    S_AXI_HP1_arid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_arregion : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_rid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_awid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_bid : out STD_LOGIC_VECTOR ( 5 downto 0 )
  );
  end component panda_ps;
  
component IOBUF is
port (
    I : in STD_LOGIC;
    O : out STD_LOGIC;
    T : in STD_LOGIC;
    IO : inout STD_LOGIC
    );
end component IOBUF;

signal IIC_0_0_scl_i : STD_LOGIC;
signal IIC_0_0_scl_o : STD_LOGIC;
signal IIC_0_0_scl_t : STD_LOGIC;
signal IIC_0_0_sda_i : STD_LOGIC;
signal IIC_0_0_sda_o : STD_LOGIC;
signal IIC_0_0_sda_t : STD_LOGIC;

begin

-- Internal clocks and resets
FCLK_RESET0 <= not FCLK_RESET0_N(0);

FCLK_CLK0 <= FCLK_CLK0_PS;

IIC_0_0_scl_iobuf: component IOBUF
     port map (
      I => IIC_0_0_scl_o,
      IO => IIC_0_0_scl_io,
      O => IIC_0_0_scl_i,
      T => IIC_0_0_scl_t
    );
IIC_0_0_sda_iobuf: component IOBUF
     port map (
      I => IIC_0_0_sda_o,
      IO => IIC_0_0_sda_io,
      O => IIC_0_0_sda_i,
      T => IIC_0_0_sda_t
    );

---------------------------------------------------------------------------
-- Panda Processor System Block design instantiation
---------------------------------------------------------------------------
ps : component panda_ps
port map (
    FCLK_CLK0                   => FCLK_CLK0_PS,
    PL_CLK                      => FCLK_CLK0,
    FCLK_RESET0_N               => FCLK_RESET0_N,

    DDR_addr(14 downto 0)       => DDR_addr(14 downto 0),
    DDR_ba(2 downto 0)          => DDR_ba(2 downto 0),
    DDR_cas_n                   => DDR_cas_n,
    DDR_ck_n                    => DDR_ck_n,
    DDR_ck_p                    => DDR_ck_p,
    DDR_cke                     => DDR_cke,
    DDR_cs_n                    => DDR_cs_n,
    DDR_dm(3 downto 0)          => DDR_dm(3 downto 0),
    DDR_dq(31 downto 0)         => DDR_dq(31 downto 0),
    DDR_dqs_n(3 downto 0)       => DDR_dqs_n(3 downto 0),
    DDR_dqs_p(3 downto 0)       => DDR_dqs_p(3 downto 0),
    DDR_odt                     => DDR_odt,
    DDR_ras_n                   => DDR_ras_n,
    DDR_reset_n                 => DDR_reset_n,
    DDR_we_n                    => DDR_we_n,

    FIXED_IO_ddr_vrn            => FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp            => FIXED_IO_ddr_vrp,
    FIXED_IO_mio(53 downto 0)   => FIXED_IO_mio(53 downto 0),
    FIXED_IO_ps_clk             => FIXED_IO_ps_clk,
    FIXED_IO_ps_porb            => FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb           => FIXED_IO_ps_srstb,
    IRQ_F2P                     => IRQ_F2P,

    IIC_0_0_scl_i               => IIC_0_0_scl_i,
    IIC_0_0_scl_o               => IIC_0_0_scl_o,
    IIC_0_0_scl_t               => IIC_0_0_scl_t,
    IIC_0_0_sda_i               => IIC_0_0_sda_i,
    IIC_0_0_sda_o               => IIC_0_0_sda_o,
    IIC_0_0_sda_t               => IIC_0_0_sda_t,

    M00_AXI_araddr(31 downto 0) => M00_AXI_araddr(31 downto 0),
    M00_AXI_arprot(2 downto 0)  => M00_AXI_arprot(2 downto 0),
    M00_AXI_arready             => M00_AXI_arready,
    M00_AXI_arvalid             => M00_AXI_arvalid,
    M00_AXI_awaddr(31 downto 0) => M00_AXI_awaddr(31 downto 0),
    M00_AXI_awprot(2 downto 0)  => M00_AXI_awprot(2 downto 0),
    M00_AXI_awready             => M00_AXI_awready,
    M00_AXI_awvalid             => M00_AXI_awvalid,
    M00_AXI_bready              => M00_AXI_bready,
    M00_AXI_bresp(1 downto 0)   => M00_AXI_bresp(1 downto 0),
    M00_AXI_bvalid              => M00_AXI_bvalid,
    M00_AXI_rdata(31 downto 0)  => M00_AXI_rdata(31 downto 0),
    M00_AXI_rready              => M00_AXI_rready,
    M00_AXI_rresp(1 downto 0)   => M00_AXI_rresp(1 downto 0),
    M00_AXI_rvalid              => M00_AXI_rvalid,
    M00_AXI_wdata(31 downto 0)  => M00_AXI_wdata(31 downto 0),
    M00_AXI_wready              => M00_AXI_wready,
    M00_AXI_wstrb(3 downto 0)   => M00_AXI_wstrb(3 downto 0),
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
    S_AXI_HP1_arregion          => S_AXI_HP1_arregion,
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
-- Base Address: 0x43c00000
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
    --read_data_0_o       => open,
    --read_ack_0_o        => open,
    read_data_1_o       => read_data(DRV_CS),
    read_ack_1_o        => read_ack(DRV_CS),

    write_strobe_i      => write_strobe,
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_0_o       => write_ack(PCAP_CS),
    --write_ack_0_o       => open,
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
    SLOW_FPGA_VERSION   => SLOW_FPGA_VERSION,
    SFP_MAC_ADDR        => SFP_MAC_ADDR_ARR,
    SFP_MAC_ADDR_WSTB   => open,
    FMC_MAC_ADDR        => FMC_MAC_ADDR_ARR,
    FMC_MAC_ADDR_WSTB   => open
);





-- Bus assembly ----

-- BIT_BUS_SIZE and POS_BUS_SIZE declared in addr_defines.vhd

bit_bus(BIT_BUS_SIZE-1 downto 0 ) <= pcap_active;

-- Assemble FMC records
--FMC_i.EXTCLK <= EXTCLK;
FMC_i.FMC_PRSNT <= FMC_PRSNT;
FMC_io.FMC_LA_P <= FMC_LA_P;
FMC_io.FMC_LA_N <= FMC_LA_N;
FMC_io.FMC_CLK0_M2C_P <= FMC_CLK0_M2C_P;
FMC_io.FMC_CLK0_M2C_N <= FMC_CLK0_M2C_N;
FMC_i.FMC_CLK1_M2C_P <= FMC_CLK1_M2C_P;
FMC_i.FMC_CLK1_M2C_N <= FMC_CLK1_M2C_N;
FMC_i.MAC_ADDR <= FMC_MAC_ADDR_ARR(1)(23 downto 0) & FMC_MAC_ADDR_ARR(0)(23 downto 0);
FMC_i.MAC_ADDR_WS <= '0';


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
    FMC_i => FMC_i,
    FMC_io => FMC_io
);


zed_demo_inst : entity work.zedboard_demo_top
port map(
    clk_i => FCLK_CLK0,

    read_strobe_i       => read_strobe(ZEDBOARD_DEMO_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(ZEDBOARD_DEMO_CS),
    read_ack_o          => read_ack(ZEDBOARD_DEMO_CS),

    write_strobe_i      => write_strobe(ZEDBOARD_DEMO_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(ZEDBOARD_DEMO_CS),

	led => led,
	SW => SW
);
	
	

end rtl;

