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

entity pandabox2_top is
generic (
    AXI_ADDR_WIDTH      : integer := 32;
    AXI_DATA_WIDTH      : integer := 32;
    NUM_SFP             : natural := 4;
    NUM_FMC             : natural := 1;
    MAX_NUM_FMC_MGT     : natural := 0
);
port (
    -- Front Panel
    PANEL_F_RESET       : out std_logic;
    PANEL_F_OE          : out std_logic;
    PANEL_F_I           : in std_logic_vector(1 downto 0);
    PANEL_F_O           : out std_logic_vector(1 downto 0);
    PANEL_F_DI_P        : in std_logic_vector(1 downto 0);
    PANEL_F_DI_N        : in std_logic_vector(1 downto 0);
    PANEL_F_DO_P        : out std_logic_vector(1 downto 0);
    PANEL_F_DO_N        : out std_logic_vector(1 downto 0);
    PANEL_F_IO          : inout std_logic_vector(7 downto 0);
    LVDS_DIR            : out std_logic_vector(1 downto 0);
    LVDS_D              : out std_logic_vector(1 downto 0);
    LVDS_R              : in std_logic_vector(1 downto 0);
    -- FMC
    FMC_PRSNT_L         : in std_logic_vector(NUM_FMC-1 downto 0);
    FMC_LA_P            : inout std_uarray(NUM_FMC-1 downto 0)(33 downto 0)
                                                := (others => (others => 'Z'));
    FMC_LA_N            : inout std_uarray(NUM_FMC-1 downto 0)(33 downto 0)
                                                := (others => (others => 'Z'));
    FMC_CLK0_M2C_P      : inout std_logic_vector(NUM_FMC-1 downto 0)
                                                            := (others => 'Z');
    FMC_CLK0_M2C_N      : inout std_logic_vector(NUM_FMC-1 downto 0)
                                                            := (others => 'Z');
    FMC_CLK1_M2C_P      : in std_logic_vector(NUM_FMC-1 downto 0);
    FMC_CLK1_M2C_N      : in std_logic_vector(NUM_FMC-1 downto 0);
    -- Encoders
    AENC                : inout std_logic_vector(8 downto 1);
    B_CLKENC            : inout std_logic_vector(8 downto 1);
    Z_DATAENC           : inout std_logic_vector(8 downto 1);
    PANEL_R_CTRL        : inout std_logic_vector(7 downto 0);
    -- Extra IOs
    I2C_1_SCK           : inout std_logic;
    I2C_1_SDA           : inout std_logic;
    PROP_IO             : inout std_logic_vector(1 downto 0);
    PROP_IO_DIR         : out std_logic_vector(1 downto 0);
    PROP_IO_TERM        : out std_logic_vector(1 downto 0);
    -- SFP
    SFP_TX_P            : out std_logic_vector(NUM_SFP-1 downto 0)
                                                            := (others => 'Z');
    SFP_TX_N            : out std_logic_vector(NUM_SFP-1 downto 0)
                                                            := (others => 'Z');
    SFP_RX_P            : in std_logic_vector(NUM_SFP-1 downto 0);
    SFP_RX_N            : in std_logic_vector(NUM_SFP-1 downto 0);
    SFP_TX_DISABLE      : out std_logic_vector(NUM_SFP-1 downto 0) := (others => '0');
    SFP_RX_LOS          : in std_logic_vector(NUM_SFP-1 downto 0);
    MGT_REFCLK1_IN0_P   : in std_logic;
    MGT_REFCLK1_IN0_N   : in std_logic
);
end;

architecture rtl of pandabox2_top is

constant NUM_MGT            : natural := NUM_SFP + MAX_NUM_FMC_MGT;

-- PS Block
signal clk0                 : std_logic;
signal clk0_4x              : std_logic;
signal reset0               : std_logic;
signal P_RESET              : std_logic_vector(0 downto 0);
signal FCLK_CLK0            : std_logic;
signal CLK300               : std_logic;
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

signal IRQ                  : std_logic_vector(1 downto 0);

-- Configuration and Status Interface Block
signal read_strobe          : std_logic_vector(MOD_COUNT-1 downto 0);
signal read_address         : std_logic_vector(PAGE_AW-1 downto 0);
signal read_data            : std32_array(MOD_COUNT-1 downto 0);
signal read_ack             : std_logic_vector(MOD_COUNT-1 downto 0) := (others => '1');
signal write_strobe         : std_logic_vector(MOD_COUNT-1 downto 0);
signal write_address        : std_logic_vector(PAGE_AW-1 downto 0);
signal write_data           : std_logic_vector(31 downto 0);
signal write_ack            : std_logic_vector(MOD_COUNT-1 downto 0) := (others => '1');

-- I2C FPGA
signal SYS_I2C_MUX          : std_logic;
signal i2c_1_scl_i          : std_logic;
signal i2c_1_scl_o          : std_logic;
signal i2c_1_scl_t          : std_logic;
signal i2c_1_sda_i          : std_logic;
signal i2c_1_sda_o          : std_logic;
signal i2c_1_sda_t          : std_logic;

-- Top Level Signals
signal bit_bus              : bit_bus_t := (others => '0');
signal pos_bus              : pos_bus_t := (others => (others => '0'));

-- Discrete Block Outputs :
signal pcap_active          : std_logic_vector(0 downto 0);

signal rdma_req             : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
signal rdma_ack             : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
signal rdma_done            : std_logic;
signal rdma_addr            : std32_array(DMA_USERS_COUNT-1 downto 0);
signal rdma_len             : std8_array(DMA_USERS_COUNT-1 downto 0);
signal rdma_data            : std_logic_vector(31 downto 0);
signal rdma_valid           : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
signal rdma_irq             : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
signal rdma_done_irq        : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
signal dma_irq_events       : std_logic_vector(31 downto 0) := (others => '0');
signal MGT_MAC_ADDR_ARR     : std32_array(2*NUM_MGT-1 downto 0);
signal pll_locked           : std_logic;
signal calibration_ready    : std_logic;
signal panel_f_di           : std_logic_vector(TTLIN_NUM-1 downto 0);
signal si_val               : std_logic_vector(SI_NUM-1 downto 0);
signal ttlin_val            : std_logic_vector(TTLIN_NUM-1 downto 0);
signal lvdsin_val           : std_logic_vector(LVDSIO_NUM-1 downto 0);
signal panel_f_do           : std_logic_vector(TTLOUT_NUM-1 downto 0);
signal ttlio_inputs         : std_logic_vector(TTLIO_NUM-1 downto 0);
signal st_ttlio_inputs      : std_logic_vector(ST_TTLIO_NUM-1 downto 0);
signal aenc_inputs          : std_logic_vector(AENC_NUM-1 downto 0);
signal b_clkenc_inputs      : std_logic_vector(B_CLKENC_NUM-1 downto 0);
signal z_dataenc_inputs     : std_logic_vector(Z_DATAENC_NUM-1 downto 0);
signal panel_r_ctrl_inputs  : std_logic_vector(PANEL_R_CTRL_NUM-1 downto 0);
signal prop_io_inputs       : std_logic_vector(PROP_IO_NUM-1 downto 0);

-- FMC Block
signal FMC                  : FMC_ARR_REC(FMC_ARR(0 to NUM_FMC-1))
                                        := (FMC_ARR => (others => FMC_init));
-- SFP Block
attribute IO_BUFFER_TYPE : string;
attribute IO_BUFFER_TYPE of SFP_TX_P : signal is "none";
attribute IO_BUFFER_TYPE of SFP_TX_N : signal is "none";
signal SFP_MGT              : MGT_ARR_REC(MGT_ARR(0 to NUM_SFP-1))
                                        := (MGT_ARR => (others => MGT_init));
signal SFP_TS_SEC           : std32_array(NUM_SFP-1 downto 0);
signal SFP_TS_TICKS         : std32_array(NUM_SFP-1 downto 0);
signal TS_SEC               : std_logic_vector(31 downto 0) := (others => '0');
signal TS_TICKS             : std_logic_vector(31 downto 0) := (others => '0');
signal mgt_refclk1_in0      : std_logic;
begin

-- Internal clocks
clocking_inst : entity work.clocking port map(
    clk_i => FCLK_CLK0,
    clk300_i => CLK300,
    clk_o => clk0,
    clk_4x_o => clk0_4x,
    locked_o => pll_locked,
    calibration_ready_o => calibration_ready
);

-- Assemble FMC records
FMC_gen: for I in 0 to NUM_FMC-1 generate
    FMC.FMC_ARR(I).FMC_PRSNT <= '0' & not FMC_PRSNT_L(I);
    FMC.FMC_ARR(I).FMC_LA_P <= FMC_LA_P(I);
    FMC.FMC_ARR(I).FMC_LA_N <= FMC_LA_N(I);
    FMC.FMC_ARR(I).FMC_CLK0_M2C_P <= FMC_CLK0_M2C_P(I);
    FMC.FMC_ARR(I).FMC_CLK0_M2C_N <= FMC_CLK0_M2C_N(I);
    FMC.FMC_ARR(I).FMC_CLK1_M2C_P <= FMC_CLK1_M2C_P(I);
    FMC.FMC_ARR(I).FMC_CLK1_M2C_N <= FMC_CLK1_M2C_N(I);
end generate;

-- Assemble SFP records
SFP_MGT_gen: for I in 0 to NUM_SFP-1 generate
    SFP_MGT.MGT_ARR(I).SFP_LOS <= SFP_RX_LOS(I);
    SFP_MGT.MGT_ARR(I).GTREFCLK <= mgt_refclk1_in0;
    SFP_MGT.MGT_ARR(I).RXN_IN <= SFP_RX_N(I);
    SFP_MGT.MGT_ARR(I).RXP_IN <= SFP_RX_P(I);
    SFP_TX_N(I) <= SFP_MGT.MGT_ARR(I).TXN_OUT;
    SFP_TX_P(I) <= SFP_MGT.MGT_ARR(I).TXP_OUT;
    SFP_TS_SEC(I) <= SFP_MGT.MGT_ARR(I).TS_SEC;
    SFP_TS_TICKS(I) <= SFP_MGT.MGT_ARR(I).TS_TICKS;
    SFP_MGT.MGT_ARR(I).MAC_ADDR <= MGT_MAC_ADDR_ARR(2*I+1)(23 downto 0) & MGT_MAC_ADDR_ARR(2*I)(23 downto 0);
    SFP_MGT.MGT_ARR(I).MAC_ADDR_WS <= '0';
end generate;

mgt_clk_inst: IBUFDS_GTE4 port map (
    O => mgt_refclk1_in0,
    CEB => '0',
    I => MGT_REFCLK1_IN0_P,
    IB => MGT_REFCLK1_IN0_N
);

---------------------------------------------------------------------------
-- Panda Processor System Block design instantiation
---------------------------------------------------------------------------
ps : entity work.panda_ps
port map (
    PL_CLK                      => clk0,
    P_RESET                     => P_RESET,
    FCLK_CLK0                   => FCLK_CLK0,
    CLK300                      => CLK300,

    IRQ                         => IRQ,
    IIC_1_scl_i                 => i2c_1_scl_i,
    IIC_1_scl_o                 => i2c_1_scl_o,
    IIC_1_scl_t                 => i2c_1_scl_t,
    IIC_1_sda_i                 => i2c_1_sda_i,
    IIC_1_sda_o                 => i2c_1_sda_o,
    IIC_1_sda_t                 => i2c_1_sda_t,

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
reset0 <= P_RESET(0);

scl_iobuf: IOBUF port map (
    I => i2c_1_scl_o,
    IO => I2C_1_SCK,
    O => i2c_1_scl_i,
    T => i2c_1_scl_t
);

sda_iobuf: IOBUF port map (
    I => i2c_1_sda_o,
    IO => I2C_1_SDA,
    O => i2c_1_sda_i,
    T => i2c_1_sda_t
);

---------------------------------------------------------------------------
-- Control and Status Memory Interface
-- Base Address: 0xa0000000
---------------------------------------------------------------------------
axi_lite_slave_inst : entity work.axi_lite_slave
port map (
    clk_i                       => clk0,
    reset_i                     => reset0,

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
    clk_i               => clk0,
    reset_i             => reset0,
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
    pcap_irq_o          => IRQ(0)
);

---------------------------------------------------------------------------
-- TABLE DMA ENGINE
---------------------------------------------------------------------------
table_engine : entity work.table_read_engine generic map(
    SLAVES => DMA_USERS_COUNT
) port map (
    clk_i               => clk0,
    reset_i             => reset0,
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
dma_irq_events(DMA_USERS_COUNT-1 downto 0) <= rdma_irq;
dma_irq_events(DMA_USERS_COUNT+15 downto 16) <= rdma_done_irq;
IRQ(1) <= or dma_irq_events;

---------------------------------------------------------------------------
-- REG (System, Position Bus and Special Register Readbacks)
---------------------------------------------------------------------------
reg_inst : entity work.reg_top
generic map (
    NUM_MGT => NUM_MGT
)
port map (
    clk_i               => clk0,

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
    dma_irq_events_i    => dma_irq_events,
    SLOW_FPGA_VERSION   => (others => '0'),
    TS_SEC              => TS_SEC,
    TS_TICKS            => TS_TICKS,
    MGT_MAC_ADDR        => MGT_MAC_ADDR_ARR,
    MGT_MAC_ADDR_WSTB   => open
);

-- Bus assembly ----

-- BIT_BUS_SIZE and POS_BUS_SIZE declared in addr_defines.vhd

bit_bus(BIT_BUS_SIZE-1 downto 0 ) <=
    prop_io_inputs &
    panel_r_ctrl_inputs & z_dataenc_inputs & b_clkenc_inputs & aenc_inputs &
    lvdsin_val & st_ttlio_inputs & ttlio_inputs & ttlin_val & si_val &
    pcap_active;

system_zynqmp_top_inst : entity work.system_zynqmp_top
port map (
    clk_i               => clk0,
    sys_i2c_mux_o       => SYS_I2C_MUX,
    pll_locked_i        => pll_locked,
    calibration_ready_i => calibration_ready,
    read_strobe_i       => read_strobe(SYSTEM_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(SYSTEM_CS),
    read_ack_o          => read_ack(SYSTEM_CS),

    write_strobe_i      => write_strobe(SYSTEM_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(SYSTEM_CS)
);

softblocks_inst : entity work.soft_blocks port map(
    FCLK_CLK0 => clk0,
    FCLK_RESET0 => reset0,
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
    rdma_irq => rdma_irq,
    rdma_done_irq => rdma_done_irq,
    FMC => FMC,
    SFP => SFP_MGT
);

-- Digital I/O Blocks

-- IO Expansion reset is de-asserted (active low reset)
PANEL_F_RESET <= '1';
-- IO Expansion outputs are enabled (active low OE)
PANEL_F_OE <= '0';

si_inst : entity work.di_wrapper generic map (
    NUM => SI_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    pad_i => PANEL_F_I,

    -- Block I/O
    val_o => si_val,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(SI_CS),
    read_address_i => read_address,
    read_data_o => read_data(SI_CS),
    read_ack_o => read_ack(SI_CS),
    write_strobe_i => write_strobe(SI_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(SI_CS)
);

oc_inst : entity work.do_wrapper generic map (
    NUM => OC_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    pad_o => PANEL_F_O,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(OC_CS),
    read_address_i => read_address,
    read_data_o => read_data(OC_CS),
    read_ack_o => read_ack(OC_CS),
    write_strobe_i => write_strobe(OC_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(OC_CS)
);

ibufds_gen : for I in 0 to TTLIN_NUM-1 generate
    ibufds_inst : IBUFDS port map (
       I => PANEL_F_DI_P(I),
       IB => PANEL_F_DI_N(I),
       O => panel_f_di(I)
    );
end generate;

ttlin_inst : entity work.di_wrapper generic map (
    NUM => TTLIN_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    pad_i => PANEL_F_DI,

    -- Block I/O
    val_o => ttlin_val,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(TTLIN_CS),
    read_address_i => read_address,
    read_data_o => read_data(TTLIN_CS),
    read_ack_o => read_ack(TTLIN_CS),
    write_strobe_i => write_strobe(TTLIN_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(TTLIN_CS)
);

obufds_gen : for I in 0 to TTLOUT_NUM-1 generate
    obufds_inst : OBUFDS port map (
       O => PANEL_F_DO_P(I),
       OB => PANEL_F_DO_N(I),
       I => panel_f_do(I)
    );
end generate;

ttlout_inst : entity work.fdly_do_wrapper generic map (
    NUM => TTLOUT_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,
    clk_4x_i => (others => clk0_4x),
    calibration_ready_i => (others => calibration_ready),

    -- Pad
    pad_o => PANEL_F_DO,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(TTLOUT_CS),
    read_address_i => read_address,
    read_data_o => read_data(TTLOUT_CS),
    read_ack_o => read_ack(TTLOUT_CS),
    write_strobe_i => write_strobe(TTLOUT_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(TTLOUT_CS)
);

ttlio_inst : entity work.dio_wrapper generic map (
    NUM => TTLIO_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    io => PANEL_F_IO(3 downto 0),

    -- Block I/O
    in_val_o => ttlio_inputs,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(TTLIO_CS),
    read_address_i => read_address,
    read_data_o => read_data(TTLIO_CS),
    read_ack_o => read_ack(TTLIO_CS),
    write_strobe_i => write_strobe(TTLIO_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(TTLIO_CS)
);

st_ttlio_inst : entity work.st_dio_wrapper generic map (
    NUM => ST_TTLIO_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    io => PANEL_F_IO(7 downto 4),

    -- Block I/O
    in_val_o => st_ttlio_inputs,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(ST_TTLIO_CS),
    read_address_i => read_address,
    read_data_o => read_data(ST_TTLIO_CS),
    read_ack_o => read_ack(ST_TTLIO_CS),
    write_strobe_i => write_strobe(ST_TTLIO_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(ST_TTLIO_CS)
);

lvdsio_inst : entity work.ext_dio_wrapper generic map (
    NUM => LVDSIO_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    pad_o => LVDS_D,
    pad_i => LVDS_R,
    dir_o => LVDS_DIR,

    -- Block I/O
    in_val_o => lvdsin_val,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(LVDSIO_CS),
    read_address_i => read_address,
    read_data_o => read_data(LVDSIO_CS),
    read_ack_o => read_ack(LVDSIO_CS),
    write_strobe_i => write_strobe(LVDSIO_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(LVDSIO_CS)
);

aenc_inst : entity work.dio_wrapper generic map (
    NUM => AENC_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    io => AENC,

    -- Block I/O
    in_val_o => aenc_inputs,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(AENC_CS),
    read_address_i => read_address,
    read_data_o => read_data(AENC_CS),
    read_ack_o => read_ack(AENC_CS),
    write_strobe_i => write_strobe(AENC_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(AENC_CS)
);

b_clkenc_inst : entity work.dio_wrapper generic map (
    NUM => B_CLKENC_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    io => B_CLKENC,

    -- Block I/O
    in_val_o => b_clkenc_inputs,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(B_CLKENC_CS),
    read_address_i => read_address,
    read_data_o => read_data(B_CLKENC_CS),
    read_ack_o => read_ack(B_CLKENC_CS),
    write_strobe_i => write_strobe(B_CLKENC_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(B_CLKENC_CS)
);

z_dataenc_inst : entity work.dio_wrapper generic map (
    NUM => Z_DATAENC_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    io => Z_DATAENC,

    -- Block I/O
    in_val_o => z_dataenc_inputs,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(Z_DATAENC_CS),
    read_address_i => read_address,
    read_data_o => read_data(Z_DATAENC_CS),
    read_ack_o => read_ack(Z_DATAENC_CS),
    write_strobe_i => write_strobe(Z_DATAENC_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(Z_DATAENC_CS)
);

panel_r_ctrl_inst : entity work.dio_wrapper generic map (
    NUM => PANEL_R_CTRL_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    io => PANEL_R_CTRL,

    -- Block I/O
    in_val_o => panel_r_ctrl_inputs,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(PANEL_R_CTRL_CS),
    read_address_i => read_address,
    read_data_o => read_data(PANEL_R_CTRL_CS),
    read_ack_o => read_ack(PANEL_R_CTRL_CS),
    write_strobe_i => write_strobe(PANEL_R_CTRL_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(PANEL_R_CTRL_CS)
);

prop_io_inst: entity work.ext_st_dio_wrapper generic map (
    NUM => PROP_IO_NUM
) port map (
    clk_i => clk0,
    reset_i => reset0,

    -- Pad
    io => PROP_IO,
    dir_o => PROP_IO_DIR,
    term_o => PROP_IO_TERM,

    -- Block I/O
    in_val_o => prop_io_inputs,

    bit_bus_i => bit_bus,
    pos_bus_i => pos_bus,
    read_strobe_i => read_strobe(PROP_IO_CS),
    read_address_i => read_address,
    read_data_o => read_data(PROP_IO_CS),
    read_ack_o => read_ack(PROP_IO_CS),
    write_strobe_i => write_strobe(PROP_IO_CS),
    write_address_i => write_address,
    write_data_i => write_data,
    write_ack_o => write_ack(PROP_IO_CS)
);
end;
