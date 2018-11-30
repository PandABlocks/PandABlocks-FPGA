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

entity panda_carrier_top is
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

    -- RS485 Channel 0 Encoder I/O
    AM0_PAD_IO          : inout std_logic_vector(3 downto 0);
    BM0_PAD_IO          : inout std_logic_vector(3 downto 0);
    ZM0_PAD_IO          : inout std_logic_vector(3 downto 0);
    AS0_PAD_IO          : inout std_logic_vector(3 downto 0);
    BS0_PAD_IO          : inout std_logic_vector(3 downto 0);
    ZS0_PAD_IO          : inout std_logic_vector(3 downto 0);

    -- Discrete I/O
    TTLIN_PAD_I         : in    std_logic_vector(5 downto 0);
    TTLOUT_PAD_O        : out   std_logic_vector(9 downto 0);
    LVDSIN_PAD_I        : in    std_logic_vector(1 downto 0);
    LVDSOUT_PAD_O       : out   std_logic_vector(1 downto 0);

    -- On-board GTX Clock Resources
    GTXCLK0_P           : in    std_logic;
    GTXCLK0_N           : in    std_logic;
    GTXCLK1_P           : in    std_logic;
    GTXCLK1_N           : in    std_logic;

    -- SFPT GTX I/O and GTX
    SFP_TX_P            : out   std_logic_vector(2 downto 0);
    SFP_TX_N            : out   std_logic_vector(2 downto 0);
    SFP_RX_P            : in    std_logic_vector(2 downto 0);
    SFP_RX_N            : in    std_logic_vector(2 downto 0);
    SFP_TxDis           : out   std_logic_vector(1 downto 0) := "00";
    SFP_LOS             : in    std_logic_vector(1 downto 0);

    -- FMC Differential IO and GTX
    FMC_DP0_C2M_P       : out   std_logic;
    FMC_DP0_C2M_N       : out   std_logic;
    FMC_DP0_M2C_P       : in    std_logic;
    FMC_DP0_M2C_N       : in    std_logic;

    FMC_PRSNT           : in    std_logic;
    FMC_LA_P            : inout std_logic_vector(33 downto 0) := (others => 'Z');
    FMC_LA_N            : inout std_logic_vector(33 downto 0) := (others => 'Z');
    FMC_CLK0_M2C_P      : inout std_logic := 'Z';
    FMC_CLK0_M2C_N      : inout std_logic := 'Z';
    FMC_CLK1_M2C_P      : in    std_logic;
    FMC_CLK1_M2C_N      : in    std_logic;

    -- External Differential Clock (via front panel SMA)
    EXTCLK_P            : in    std_logic;
    EXTCLK_N            : in    std_logic;

    -- Slow Controller Serial interface
    SPI_SCLK_O          : out std_logic;
    SPI_DAT_O           : out std_logic;
    SPI_SCLK_I          : in  std_logic;
    SPI_DAT_I           : in  std_logic
);
end panda_carrier_top;

architecture rtl of panda_carrier_top is

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
signal bit_bus              : sysbus_t := (others => '0');
signal posbus               : posbus_t := (others => (others => '0'));

-- Daughter card control signals

-- Input Encoder
signal inenc_val            : std32_array(ENC_NUM-1 downto 0);
signal inenc_conn           : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_a              : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_b              : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_z              : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_data           : std_logic_vector(ENC_NUM-1 downto 0);

-- Output Encoder
signal outenc_clk           : std_logic_vector(ENC_NUM-1 downto 0);
signal outenc_conn          : std_logic_vector(ENC_NUM-1 downto 0);

-- Discrete Block Outputs :
signal ttlin_val            : std_logic_vector(TTLIN_NUM-1 downto 0);
signal ttlout_val           : std_logic_vector(TTLOUT_NUM-1 downto 0);
signal lvdsin_val           : std_logic_vector(LVDSIN_NUM-1 downto 0);

signal pcap_active          : std_logic_vector(0 downto 0);

signal rdma_req             : std_logic_vector(5 downto 0);
signal rdma_ack             : std_logic_vector(5 downto 0);
signal rdma_done            : std_logic;
signal rdma_addr            : std32_array(5 downto 0);
signal rdma_len             : std8_array(5 downto 0);
signal rdma_data            : std_logic_vector(31 downto 0);
signal rdma_valid           : std_logic_vector(5 downto 0);

signal A_IN                 : std_logic_vector(ENC_NUM-1 downto 0);
signal B_IN                 : std_logic_vector(ENC_NUM-1 downto 0);
signal Z_IN                 : std_logic_vector(ENC_NUM-1 downto 0);
signal CLK_OUT              : std_logic_vector(ENC_NUM-1 downto 0);
signal DATA_IN              : std_logic_vector(ENC_NUM-1 downto 0);
signal A_OUT                : std_logic_vector(ENC_NUM-1 downto 0);
signal B_OUT                : std_logic_vector(ENC_NUM-1 downto 0);
signal Z_OUT                : std_logic_vector(ENC_NUM-1 downto 0);
signal CLK_IN               : std_logic_vector(ENC_NUM-1 downto 0);
signal DATA_OUT             : std_logic_vector(ENC_NUM-1 downto 0);
signal OUTPROT              : std3_array(ENC_NUM-1 downto 0);
signal INPROT               : std3_array(ENC_NUM-1 downto 0);

signal SLOW_FPGA_VERSION    : std_logic_vector(31 downto 0);
signal DCARD_MODE           : std32_array(ENC_NUM-1 downto 0);

signal SFP_MAC_ADDR_ARR     : std32_array(2*NUM_SFP-1 downto 0);
signal FMC_MAC_ADDR_ARR     : std32_array(2*NUM_FMC-1 downto 0);

-- FMC Block
signal FMC : FMC_interface;
-- SFP Block
signal SFP1 : SFP_interface;
signal SFP2 : SFP_interface;
signal SFP3 : SFP_interface;

signal   q0_clk0_gtrefclk, q0_clk1_gtrefclk :   std_logic;
attribute syn_noclockbuf : boolean;
attribute syn_noclockbuf of q0_clk0_gtrefclk : signal is true;
attribute syn_noclockbuf of q0_clk1_gtrefclk : signal is true;


signal sma_pll_locked       : std_logic;
signal ext_clock            : std_logic_vector(1 downto 0);

-- Make schematics a bit more clear for analysis
--attribute keep              : string; -- GBC removed following three lines 14/09/18 
--attribute keep of sysbus    : signal is "true";
--attribute keep of posbus    : signal is "true";

begin

-- Internal clocks and resets
FCLK_RESET0 <= not FCLK_RESET0_N(0);

--------------------------------------------------------------------------
-- Instantiate differential clock buffers
--------------------------------------------------------------------------
IBUFGDS_EXT : IBUFGDS
generic map (
    DIFF_TERM   => FALSE,
    IOSTANDARD  => "LVDS_25"
)
port map (
    O           => FMC.EXTCLK,
    I           => EXTCLK_P,
    IB          => EXTCLK_N
);

--IBUFDS_GTE2
    ibufds_instq0_clk0 : IBUFDS_GTE2  
    port map
    (
        O               => 	q0_clk0_gtrefclk,
        ODIV2           =>    open,
        CEB             => 	'0',
        I               => 	GTXCLK0_P,
        IB              => 	GTXCLK0_N
    );

--IBUFDS_GTE2
    ibufds_instq0_clk1 : IBUFDS_GTE2  
    port map
    (
        O               => 	q0_clk1_gtrefclk,
        ODIV2           =>  open,
        CEB             => 	'0',
        I               => 	GTXCLK1_P,
        IB              => 	GTXCLK1_N
    );


---------------------------------------------------------------------------
-- Panda Processor System Block design instantiation
---------------------------------------------------------------------------
ps : entity work.panda_ps
port map (
    FCLK_CLK0                   => FCLK_CLK0,
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
-- TTL
---------------------------------------------------------------------------
ttlin_inst : entity work.ttlin_top
port map (
    clk_i               => FCLK_CLK0,
    pad_i               => TTLIN_PAD_I,
    val_o               => ttlin_val
);

ttlout_inst : entity work.ttlout_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    read_strobe_i       => read_strobe(TTLOUT_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(TTLOUT_CS),
    read_ack_o          => read_ack(TTLOUT_CS),

    write_strobe_i      => write_strobe(TTLOUT_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(TTLOUT_CS),

    sysbus_i            => bit_bus,
    val_o               => ttlout_val,
    pad_o               => TTLOUT_PAD_O
);

---------------------------------------------------------------------------
-- LVDS
---------------------------------------------------------------------------
lvdsin_inst : entity work.lvdsin_top
port map (
    clk_i               => FCLK_CLK0,
    pad_i               => LVDSIN_PAD_I,
    val_o               => lvdsin_val
);

lvdsout_inst : entity work.lvdsout_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    read_strobe_i       => read_strobe(LVDSOUT_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(LVDSOUT_CS),
    read_ack_o          => read_ack(LVDSOUT_CS),

    write_strobe_i      => write_strobe(LVDSOUT_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(LVDSOUT_CS),

    sysbus_i            => bit_bus,
    pad_o               => LVDSOUT_PAD_O
);



---------------------------------------------------------------------------
-- INENC (Encoder Inputs)
---------------------------------------------------------------------------
inenc_inst : entity work.inenc_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,
    -- Memory interface
    read_strobe_i       => read_strobe(INENC_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(INENC_CS),
    read_ack_o          => read_ack(INENC_CS),

    write_strobe_i      => write_strobe(INENC_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(INENC_CS),
    -- Physical IO Pads
    A_IN                => A_IN,
    B_IN                => B_IN,
    Z_IN                => Z_IN,
    CLK_OUT             => CLK_OUT,
    DATA_IN             => DATA_IN,
    CLK_IN              => CLK_IN,
    -- Signals passed to internal bus
    a_int_o             => inenc_a,
    b_int_o             => inenc_b,
    z_int_o             => inenc_z,
    data_int_o          => inenc_data,
    -- Block Outputs
    sysbus_i            => bit_bus,
    posbus_i            => posbus,
    CONN_OUT            => inenc_conn,
    DCARD_MODE          => DCARD_MODE,
    PROTOCOL            => INPROT,
    posn_o              => inenc_val
);


---------------------------------------------------------------------------
-- OUTENC (Encoder Inputs)
---------------------------------------------------------------------------
outenc_inst : entity work.outenc_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    read_strobe_i       => read_strobe(OUTENC_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(OUTENC_CS),
    read_ack_o          => read_ack(OUTENC_CS),

    write_strobe_i      => write_strobe(OUTENC_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(OUTENC_CS),
    -- Physical IO Pads
    A_OUT               => A_OUT,
    B_OUT               => B_OUT,
    Z_OUT               => Z_OUT,
    CLK_IN              => CLK_IN,
    DATA_OUT            => DATA_OUT,
    CONN_OUT            => outenc_conn,
    -- Signals passed to internal bus
    clk_int_o           => outenc_clk,
    --
    sysbus_i            => bit_bus,
    posbus_i            => posbus,
    DCARD_MODE          => DCARD_MODE,
    PROTOCOL            => OUTPROT
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

    sysbus_i            => bit_bus,
    posbus_i            => posbus,
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

    sysbus_i            => bit_bus,
    posbus_i            => posbus,
    SLOW_FPGA_VERSION   => SLOW_FPGA_VERSION,
    SFP_MAC_ADDR        => SFP_MAC_ADDR_ARR,
    SFP_MAC_ADDR_WSTB   => open,
    FMC_MAC_ADDR        => FMC_MAC_ADDR_ARR,
    FMC_MAC_ADDR_WSTB   => open
);

---------------------------------------------------------------------------
-- SYSTEM FPGA
---------------------------------------------------------------------------
system_inst : entity work.system_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe(SYSTEM_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(SYSTEM_CS),
    read_ack_o          => read_ack(SYSTEM_CS),
    write_strobe_i      => write_strobe,
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(SYSTEM_CS),
    -- Digital I/O Interface
    ttlin_i             => ttlin_val,
    ttlout_i            => ttlout_val,
    inenc_conn_i        => inenc_conn,
    outenc_conn_i       => outenc_conn,
    -- Block Input and Outputs
    SLOW_FPGA_VERSION   => SLOW_FPGA_VERSION,
    DCARD_MODE          => DCARD_MODE,
    -- Serial Physical interface
    spi_sclk_o          => SPI_SCLK_O,
    spi_dat_o           => SPI_DAT_O,
    spi_sclk_i          => SPI_SCLK_I,
    spi_dat_i           => SPI_DAT_I
    -- External clock
--    sma_pll_locked_i    => sma_pll_locked,
--    ext_clock_o         => ext_clock
);

---------------------------------------------------------------------------
-- On-Chip IOBUF Control for Daughter Card Interfacing
---------------------------------------------------------------------------
dcard_interface_inst : entity work.dcard_interface
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    Am0_pad_io          => AM0_PAD_IO,
    Bm0_pad_io          => BM0_PAD_IO,
    Zm0_pad_io          => ZM0_PAD_IO,
    As0_pad_io          => AS0_PAD_IO,
    Bs0_pad_io          => BS0_PAD_IO,
    Zs0_pad_io          => ZS0_PAD_IO,

    INPROT              => INPROT,
    OUTPROT             => OUTPROT,

    A_IN                => A_IN,
    B_IN                => B_IN,
    Z_IN                => Z_IN,
    A_OUT               => A_OUT,
    B_OUT               => B_OUT,
    Z_OUT               => Z_OUT,
    CLK_OUT             => CLK_OUT,
    DATA_IN             => DATA_IN,
    CLK_IN              => CLK_IN,
    DATA_OUT            => DATA_OUT
);

-- Bus assembly ----

-- BIT_BUS_SIZE and POS_BUS_SIZE declared in addr_defines.vhd

--bit_bus(BIT_BUS_SIZE-1 downto 0 ) <= pcap_active & outenc_clk & inenc_conn &
--                                   inenc_data & inenc_z & inenc_b & inenc_a &
--                                   lvdsin_val & ttlin_val;

--posbus(POS_BUS_SIZE-1 downto 0) <= inenc_val;

-- Assemble FMC record
FMC.FMC_PRSNT <= FMC_PRSNT;
FMC.FMC_LA_P <= FMC_LA_P;
FMC.FMC_LA_N <= FMC_LA_N;
FMC.FMC_CLK0_M2C_P <= FMC_CLK0_M2C_P;
FMC.FMC_CLK0_M2C_N <= FMC_CLK0_M2C_N;
FMC.FMC_CLK1_M2C_P <= FMC_CLK1_M2C_P;
FMC.FMC_CLK1_M2C_N <= FMC_CLK1_M2C_N;
FMC.GTREFCLK <= q0_clk1_gtrefclk;
FMC_DP0_C2M_P <= FMC.TXP_OUT;
FMC_DP0_C2M_N <= FMC.TXN_OUT;
FMC.RXP_IN <= FMC_DP0_M2C_P;
FMC.RXN_IN <= FMC_DP0_M2C_N;
--Commenting Below Line fixes non-responsive/system issue
FMC.MAC_ADDR <= FMC_MAC_ADDR_ARR(0)(23 downto 0) & FMC_MAC_ADDR_ARR(1)(23 downto 0);
FMC.MAC_ADDR_WS <= '0';

-- Assemble SFP records
-- NB: SFPs 1 and 3 are switched around to mirror front panel connections
SFP1.SFP_LOS <= '0';  -- NB: Hard-coded to '0' as not brought out onto pin!
SFP1.GTREFCLK <= q0_clk0_gtrefclk;
SFP1.RXN_IN <= SFP_RX_N(2);
SFP1.RXP_IN <= SFP_RX_P(2);
SFP_TX_N(2) <= SFP1.TXN_OUT;
SFP_TX_P(2) <= SFP1.TXP_OUT;
--Commenting Below Line fixes non-responsive/system issue
SFP1.MAC_ADDR <= SFP_MAC_ADDR_ARR(0)(23 downto 0) & SFP_MAC_ADDR_ARR(1)(23 downto 0);
SFP1.MAC_ADDR_WS <= '0';

SFP2.SFP_LOS <= SFP_LOS(1);
SFP2.GTREFCLK <= q0_clk0_gtrefclk;
SFP2.RXN_IN <= SFP_RX_N(1);
SFP2.RXP_IN <= SFP_RX_P(1);
SFP_TX_N(1) <= SFP2.TXN_OUT;
SFP_TX_P(1) <= SFP2.TXP_OUT;
--Commenting Below Line fixes non-responsive/system issue
SFP2.MAC_ADDR <= SFP_MAC_ADDR_ARR(2)(23 downto 0) & SFP_MAC_ADDR_ARR(3)(23 downto 0);
SFP2.MAC_ADDR_WS <= '0';

SFP3.SFP_LOS <= SFP_LOS(0);
SFP3.GTREFCLK <= q0_clk0_gtrefclk;
SFP3.RXN_IN <= SFP_RX_N(0);
SFP3.RXP_IN <= SFP_RX_P(0);
SFP_TX_N(0) <= SFP3.TXN_OUT;
SFP_TX_P(0) <= SFP3.TXP_OUT;
--Commenting Below Line fixes non-responsive/system issue
SFP3.MAC_ADDR <= SFP_MAC_ADDR_ARR(4)(23 downto 0) & SFP_MAC_ADDR_ARR(5)(23 downto 0);
SFP3.MAC_ADDR_WS <= '0';

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
    read_data => read_data,
    read_ack => read_ack,
    write_strobe => write_strobe,
    write_address => write_address,
    write_data => write_data,
    write_ack => write_ack,
    bit_bus => bit_bus,
    posbus => posbus,
    rdma_req => rdma_req,
    rdma_ack => rdma_ack,
    rdma_done => rdma_done,
    rdma_addr => rdma_addr,
    rdma_len => rdma_len,
    rdma_data => rdma_data,
    rdma_valid => rdma_valid,
    FMC => FMC,
    SFPA => SFP1,
    SFPB => SFP2,
    SFPC => SFP3
);

end rtl;

