--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : PandA Zynqmp Top-Level Design File
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

use work.addr_defines.all;
use work.top_defines.all;
use work.interface_types.all;

entity xu5_st1_top is
generic (
    AXI_ADDR_WIDTH      : integer := 32;
    AXI_DATA_WIDTH      : integer := 32;
    NUM_SFP             : natural := 0;
    NUM_FMC             : natural := 1;
    MAX_NUM_FMC_MGT     : natural := 4
);
port (
    -- Discrete I/O
    TTLIN_PAD_I         : in    std_logic_vector(0 downto 0);
    TTLOUT_PAD_O        : out   std_logic_vector(0 downto 0);
    -- MGT REFCLKs 
    GTXCLK0_P           : in    std_logic;
    GTXCLK0_N           : in    std_logic;
    GTXCLK1_P           : in    std_logic;
    GTXCLK1_N           : in    std_logic;
    -- FMC
    FMC_DP_C2M_P        : out   std_logic_vector(MAX_NUM_FMC_MGT-1 downto 0)
                                                            := (others => 'Z');
    FMC_DP_C2M_N        : out   std_logic_vector(MAX_NUM_FMC_MGT-1 downto 0)
                                                            := (others => 'Z');
    FMC_DP_M2C_P        : in    std_logic_vector(MAX_NUM_FMC_MGT-1 downto 0);
    FMC_DP_M2C_N        : in    std_logic_vector(MAX_NUM_FMC_MGT-1 downto 0);
    FMC_LA_P            : inout std_uarray(NUM_FMC-1 downto 0)(33 downto 0)
                                                := (others => (others => 'Z'));
    FMC_LA_N            : inout std_uarray(NUM_FMC-1 downto 0)(33 downto 0)
                                                := (others => (others => 'Z'));
    FMC_CLK0_M2C_P      : inout std_logic_vector(NUM_FMC-1 downto 0)
                                                            := (others => 'Z');
    FMC_CLK0_M2C_N      : inout std_logic_vector(NUM_FMC-1 downto 0)
                                                            := (others => 'Z');
    FMC_CLK1_M2C_P      : in    std_logic_vector(NUM_FMC-1 downto 0);
    FMC_CLK1_M2C_N      : in    std_logic_vector(NUM_FMC-1 downto 0)
);
end xu5_st1_top;

architecture rtl of xu5_st1_top is

constant NUM_MGT            : natural := NUM_SFP + MAX_NUM_FMC_MGT;

-- PS Block
signal FCLK_CLK0            : std_logic;
signal FCLK_CLK0_PS         : std_logic;
signal FCLK_RESET0_N        : std_logic_vector(0 downto 0);
signal FCLK_RESET0          : std_logic;
signal EXTCLK               : std_logic := '1';
signal sma_pll_locked       : std_logic;
signal clk_src_sel          : std_logic_vector(1 downto 0);
signal clk_sel_stat         : std_logic_vector(1 downto 0);

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

-- Discrete Block Outputs :
signal pcap_active          : std_logic_vector(0 downto 0);

-- Discrete Block Outputs :
signal ttlin_val            : std_logic_vector(TTLIN_NUM-1 downto 0);
signal TTLIN_TERM           : std32_array(TTLIN_NUM-1 downto 0);
signal TTLIN_TERM_WSTB      : std_logic_vector(TTLIN_NUM-1 downto 0);

signal rdma_req             : std_logic_vector(5 downto 0);
signal rdma_ack             : std_logic_vector(5 downto 0);
signal rdma_done            : std_logic;
signal rdma_addr            : std32_array(5 downto 0);
signal rdma_len             : std8_array(5 downto 0);
signal rdma_data            : std_logic_vector(31 downto 0);
signal rdma_valid           : std_logic_vector(5 downto 0);

signal MGT_MAC_ADDR_ARR     : std32_array(2*NUM_MGT-1 downto 0);

-- FMC Block
signal FMC      : FMC_ARR_REC(FMC_ARR(0 to NUM_FMC-1))
                                        := (FMC_ARR => (others => FMC_init));

-- Additional MGT interfaces available using FMC
signal FMC_MGT  : MGT_ARR_REC(MGT_ARR(0 to MAX_NUM_FMC_MGT-1))
                                        := (MGT_ARR => (others => MGT_init));

signal   q0_clk0_gtrefclk, q0_clk1_gtrefclk :   std_logic;
attribute syn_noclockbuf : boolean;
attribute syn_noclockbuf of q0_clk0_gtrefclk : signal is true;
attribute syn_noclockbuf of q0_clk1_gtrefclk : signal is true;

attribute IO_BUFFER_TYPE : string;
attribute IO_BUFFER_TYPE of FMC_DP_C2M_N : signal is "none";
attribute IO_BUFFER_TYPE of FMC_DP_C2M_P : signal is "none";

begin

-- Internal clocks and resets
FCLK_RESET0 <= not FCLK_RESET0_N(0);
FCLK_CLK0 <= FCLK_CLK0_PS;

-- MGT REFCLOCK Differential Buffers

IBUFDS_GTE4_REFCLK0 : IBUFDS_GTE4
generic map (
    REFCLK_EN_TX_PATH => '0',
    REFCLK_HROW_CK_SEL => "00",
    REFCLK_ICNTL_RX => "00" -- Refer to Transceiver User Guide.
)
port map (
    O =>     q0_clk0_gtrefclk,
    ODIV2 => open,
    CEB =>   '0',
    I =>     GTXCLK0_P,
    IB =>    GTXCLK0_N
);

IBUFDS_GTE4_REFCLK1 : IBUFDS_GTE4
generic map (
    REFCLK_EN_TX_PATH => '0',
    REFCLK_HROW_CK_SEL => "00",
    REFCLK_ICNTL_RX => "00" -- Refer to Transceiver User Guide.
)
port map (
    O =>     q0_clk1_gtrefclk,
    ODIV2 => open,
    CEB =>   '0',
    I =>     GTXCLK1_P,
    IB =>    GTXCLK1_N
);

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

    pad_i               => TTLIN_PAD_I,
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
    TTLIN_TERM_o        => TTLIN_TERM,
    TTLIN_TERM_WSTB_o   => TTLIN_TERM_WSTB
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
    NUM_MGT => NUM_MGT
)
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
    TS_SEC              => (others => '0'),
    TS_TICKS            => (others => '0'),
    MGT_MAC_ADDR        => MGT_MAC_ADDR_ARR,
    MGT_MAC_ADDR_WSTB   => open
);

-- Bus assembly ----

-- BIT_BUS_SIZE and POS_BUS_SIZE declared in addr_defines.vhd

bit_bus(BIT_BUS_SIZE-1 downto 0 ) <= pcap_active & ttlin_val;

-- Assemble FMC records

FMC_gen: for I in 0 to NUM_FMC-1 generate
    FMC.FMC_ARR(I).FMC_LA_P <= FMC_LA_P(I);
    FMC.FMC_ARR(I).FMC_LA_N <= FMC_LA_N(I);
    FMC.FMC_ARR(I).FMC_CLK0_M2C_P <= FMC_CLK0_M2C_P(I);
    FMC.FMC_ARR(I).FMC_CLK0_M2C_N <= FMC_CLK0_M2C_N(I);
    FMC.FMC_ARR(I).FMC_CLK1_M2C_P <= FMC_CLK1_M2C_P(I);
    FMC.FMC_ARR(I).FMC_CLK1_M2C_N <= FMC_CLK1_M2C_N(I);
end generate;

-- Additonal FMC_MGT which is an option by using the MGT pins on the FMC.

FMC_MGT_gen: for I in 0 to MAX_NUM_FMC_MGT-1 generate
    FMC_MGT.MGT_ARR(I).SFP_LOS <= '0';
    FMC_MGT.MGT_ARR(I).GTREFCLK <= q0_clk1_gtrefclk;
    FMC_MGT.MGT_ARR(I).RXN_IN <= FMC_DP_M2C_N(I);
    FMC_MGT.MGT_ARR(I).RXP_IN <= FMC_DP_M2C_P(I);
    FMC_DP_C2M_N(I) <= FMC_MGT.MGT_ARR(I).TXN_OUT;
    FMC_DP_C2M_P(I) <= FMC_MGT.MGT_ARR(I).TXP_OUT;
    FMC_MGT.MGT_ARR(I).MAC_ADDR <= (others => '0');
    FMC_MGT.MGT_ARR(I).MAC_ADDR_WS <= '0';
end generate;
---------------------------------------------------------------------------
-- PandABlocks_top Instantiation (autogenerated!!)
---------------------------------------------------------------------------

softblocks_inst : entity work.soft_blocks
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
    FMC => FMC,
    FMC_MGT => FMC_MGT
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

