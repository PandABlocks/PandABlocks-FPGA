library ieee;
use ieee.std_logic_1164.all;

use work.addr_defines.all;
use work.top_defines.all;
use work.operator.all;

entity testtarget_top is
generic (
    AXI_ADDR_WIDTH : integer := 32;
    AXI_DATA_WIDTH : integer := 32;
    NUM_SFP : natural := 0;
    NUM_FMC : natural := 0;
    MAX_NUM_FMC_MGT : natural := 0
);
port (
    reset_i : in std_logic;
    clk_i : in std_logic;
    irqs_o : out std_logic_vector(1 downto 0);
    -- Register interface
    s_reg_axil_awaddr : in std_logic_vector (31 downto 0);
    s_reg_axil_awvalid : in std_logic;
    s_reg_axil_awready : out std_logic;
    s_reg_axil_awprot : in std_logic_vector (2 downto 0);
    s_reg_axil_wdata : in std_logic_vector (31 downto 0);
    s_reg_axil_wstrb : in std_logic_vector (3 downto 0);
    s_reg_axil_wvalid : in std_logic;
    s_reg_axil_wready : out std_logic;
    s_reg_axil_bresp : out std_logic_vector (1 downto 0);
    s_reg_axil_bvalid : out std_logic;
    s_reg_axil_bready : in std_logic;
    s_reg_axil_araddr : in std_logic_vector (31 downto 0);
    s_reg_axil_arprot : in std_logic_vector (2 downto 0);
    s_reg_axil_arvalid : in std_logic;
    s_reg_axil_arready : out std_logic;
    s_reg_axil_rdata : out std_logic_vector (31 downto 0);
    s_reg_axil_rresp : out std_logic_vector (1 downto 0);
    s_reg_axil_rvalid : out std_logic;
    s_reg_axil_rready : in std_logic;
    -- pcap interface
    m_pcap_axi_awaddr : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    m_pcap_axi_awvalid : out std_logic;
    m_pcap_axi_awready : out std_logic;
    m_pcap_axi_awregion : out std_logic_vector(3 downto 0);
    m_pcap_axi_bid : out std_logic_vector(5 downto 0);
    m_pcap_axi_awburst : out std_logic_vector(1 downto 0);
    m_pcap_axi_awcache : out std_logic_vector(3 downto 0);
    m_pcap_axi_awid : out std_logic_vector(5 downto 0);
    m_pcap_axi_awlen : out std_logic_vector(3 downto 0);
    m_pcap_axi_awlock : out std_logic_vector(1 downto 0);
    m_pcap_axi_awprot : out std_logic_vector(2 downto 0);
    m_pcap_axi_awqos : out std_logic_vector(3 downto 0);
    m_pcap_axi_awsize : out std_logic_vector(2 downto 0);
    m_pcap_axi_wdata : out std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    m_pcap_axi_wstrb : out std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
    m_pcap_axi_wvalid : out std_logic;
    m_pcap_axi_wready : in std_logic;
    m_pcap_axi_wlast : out std_logic;
    m_pcap_axi_bresp : in std_logic_vector(1 downto 0);
    m_pcap_axi_bvalid : in std_logic;
    m_pcap_axi_bready : out std_logic;
    -- table read engine interface
    m_table_axi_araddr : out std_logic_vector(31 downto 0);
    m_table_axi_arvalid : out std_logic;
    m_table_axi_arready : in std_logic;
    m_table_axi_arburst : out std_logic_vector(1 downto 0);
    m_table_axi_arcache : out std_logic_vector(3 downto 0);
    m_table_axi_arid : out std_logic_vector(5 downto 0);
    m_table_axi_arlen : out std_logic_vector(7 downto 0);
    m_table_axi_arlock : out std_logic_vector(0 to 0);
    m_table_axi_arprot : out std_logic_vector(2 downto 0);
    m_table_axi_arqos : out std_logic_vector(3 downto 0);
    m_table_axi_arregion : out std_logic_vector(3 downto 0);
    m_table_axi_arsize : out std_logic_vector(2 downto 0);
    m_table_axi_rdata : out std_logic_vector(31 downto 0);
    m_table_axi_rvalid : in std_logic;
    m_table_axi_rready : out std_logic;
    m_table_axi_rid : out std_logic_vector(5 downto 0);
    m_table_axi_rlast : in std_logic;
    m_table_axi_rresp : in std_logic_vector(1 downto 0)
);
end;

architecture rtl of testtarget_top is
    constant NUM_MGT : natural := NUM_SFP + MAX_NUM_FMC_MGT;

    -- Configuration and Status Interface Block
    signal read_strobe : std_logic_vector(MOD_COUNT-1 downto 0);
    signal read_address : std_logic_vector(PAGE_AW-1 downto 0);
    signal read_data : std32_array(MOD_COUNT-1 downto 0);
    signal read_ack : std_logic_vector(MOD_COUNT-1 downto 0) := (others => '1');
    signal write_strobe : std_logic_vector(MOD_COUNT-1 downto 0);
    signal write_address : std_logic_vector(PAGE_AW-1 downto 0);
    signal write_data : std_logic_vector(31 downto 0);
    signal write_ack : std_logic_vector(MOD_COUNT-1 downto 0) := (others => '1');

    -- Top Level Signals
    signal bit_bus : bit_bus_t := (others => '0');
    signal pos_bus : pos_bus_t := (others => (others => '0'));
    signal pcap_active : std_logic_vector(0 downto 0);

    signal rdma_req : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
    signal rdma_ack : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
    signal rdma_done : std_logic;
    signal rdma_addr : std32_array(DMA_USERS_COUNT-1 downto 0);
    signal rdma_len : std8_array(DMA_USERS_COUNT-1 downto 0);
    signal rdma_data : std_logic_vector(31 downto 0);
    signal rdma_valid : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
    signal rdma_irq : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
    signal rdma_done_irq : std_logic_vector(DMA_USERS_COUNT-1 downto 0);
    signal dma_irq_events : std_logic_vector(31 downto 0) := (others => '0');

begin

    axi_lite_slave_inst : entity work.axi_lite_slave
    port map (
        clk_i => clk_i,
        reset_i => reset_i,

        araddr_i => s_reg_axil_araddr,
        arprot_i => s_reg_axil_arprot,
        arready_o => s_reg_axil_arready,
        arvalid_i => s_reg_axil_arvalid,

        rdata_o => s_reg_axil_rdata,
        rresp_o => s_reg_axil_rresp,
        rready_i => s_reg_axil_rready,
        rvalid_o => s_reg_axil_rvalid,

        awaddr_i => s_reg_axil_awaddr,
        awprot_i => s_reg_axil_awprot,
        awready_o => s_reg_axil_awready,
        awvalid_i => s_reg_axil_awvalid,

        wdata_i => s_reg_axil_wdata,
        wstrb_i => s_reg_axil_wstrb,
        wready_o => s_reg_axil_wready,
        wvalid_i => s_reg_axil_wvalid,

        bresp_o => s_reg_axil_bresp,
        bvalid_o => s_reg_axil_bvalid,
        bready_i => s_reg_axil_bready,

        read_strobe_o => read_strobe,
        read_address_o => read_address,
        read_data_i => read_data,
        read_ack_i => read_ack,

        write_strobe_o => write_strobe,
        write_address_o => write_address,
        write_data_o => write_data,
        write_ack_i => write_ack
    );

    pcap_inst : entity work.pcap_top
    port map (
        clk_i => clk_i,
        reset_i => reset_i,
        m_axi_awaddr => m_pcap_axi_awaddr,
        m_axi_awburst => m_pcap_axi_awburst,
        m_axi_awcache => m_pcap_axi_awcache,
        m_axi_awid => m_pcap_axi_awid,
        m_axi_awlen => m_pcap_axi_awlen,
        m_axi_awlock => m_pcap_axi_awlock,
        m_axi_awprot => m_pcap_axi_awprot,
        m_axi_awqos => m_pcap_axi_awqos,
        m_axi_awready => m_pcap_axi_awready,
        m_axi_awregion => m_pcap_axi_awregion,
        m_axi_awsize => m_pcap_axi_awsize,
        m_axi_awvalid => m_pcap_axi_awvalid,
        m_axi_bid => m_pcap_axi_bid,
        m_axi_bready => m_pcap_axi_bready,
        m_axi_bresp => m_pcap_axi_bresp,
        m_axi_bvalid => m_pcap_axi_bvalid,
        m_axi_wdata => m_pcap_axi_wdata,
        m_axi_wlast => m_pcap_axi_wlast,
        m_axi_wready => m_pcap_axi_wready,
        m_axi_wstrb => m_pcap_axi_wstrb,
        m_axi_wvalid => m_pcap_axi_wvalid,

        read_address_i => read_address,
        read_strobe_i => read_strobe,
        read_data_0_o => read_data(PCAP_CS),
        read_ack_0_o => read_ack(PCAP_CS),
        --read_data_0_o => open,
        --read_ack_0_o => open,
        read_data_1_o => read_data(DRV_CS),
        read_ack_1_o => read_ack(DRV_CS),

        write_strobe_i => write_strobe,
        write_address_i => write_address,
        write_data_i => write_data,
        write_ack_0_o => write_ack(PCAP_CS),
        --write_ack_0_o => open,
        write_ack_1_o => write_ack(DRV_CS),

        bit_bus_i => bit_bus,
        pos_bus_i => pos_bus,
        pcap_actv_o => pcap_active(0),
        pcap_irq_o => irqs_o(0)
    );

    ---------------------------------------------------------------------------
    -- TABLE DMA ENGINE
    ---------------------------------------------------------------------------
    table_engine : entity work.table_read_engine generic map(
        SLAVES => DMA_USERS_COUNT
   ) port map (
        clk_i => clk_i,
        reset_i => reset_i,
        -- Zynq HP1 Bus
        m_axi_araddr => m_table_axi_araddr,
        m_axi_arburst => m_table_axi_arburst,
        m_axi_arcache => m_table_axi_arcache,
        m_axi_arid => m_table_axi_arid,
        m_axi_arlen => m_table_axi_arlen,
        m_axi_arlock => m_table_axi_arlock,
        m_axi_arprot => m_table_axi_arprot,
        m_axi_arqos => m_table_axi_arqos,
        m_axi_arready => m_table_axi_arready,
        m_axi_arregion => m_table_axi_arregion,
        m_axi_arsize => m_table_axi_arsize,
        m_axi_arvalid => m_table_axi_arvalid,
        m_axi_rdata => m_table_axi_rdata,
        m_axi_rid => m_table_axi_rid,
        m_axi_rlast => m_table_axi_rlast,
        m_axi_rready => m_table_axi_rready,
        m_axi_rresp => m_table_axi_rresp,
        m_axi_rvalid => m_table_axi_rvalid,
        -- Slaves' DMA Engine Interface
        dma_req_i => rdma_req,
        dma_ack_o => rdma_ack,
        dma_done_o => rdma_done,
        dma_addr_i => rdma_addr,
        dma_len_i => rdma_len,
        dma_data_o => rdma_data,
        dma_valid_o => rdma_valid
    );

    dma_irq_events(DMA_USERS_COUNT-1 downto 0) <= rdma_irq;
    dma_irq_events(DMA_USERS_COUNT+15 downto 16) <= rdma_done_irq;
    irqs_o(1) <= vector_or(dma_irq_events);

    ---------------------------------------------------------------------------
    -- REG (System, Position Bus and Special Register Readbacks)
    ---------------------------------------------------------------------------
    reg_inst : entity work.reg_top
    generic map (
        -- shut up the simulator about length mismatches
        NUM_MGT => 4
    )
    port map (
        clk_i => clk_i,

        read_strobe_i => read_strobe(REG_CS),
        read_address_i => read_address,
        read_data_o => read_data(REG_CS),
        read_ack_o => read_ack(REG_CS),

        write_strobe_i => write_strobe(REG_CS),
        write_address_i => write_address,
        write_data_i => write_data,
        write_ack_o => write_ack(REG_CS),

        bit_bus_i => bit_bus,
        pos_bus_i => pos_bus,
        dma_irq_events_i => dma_irq_events,
        SLOW_FPGA_VERSION => (others => '0'),
        TS_SEC => (others => '0'),
        -- Dummy value to test register read
        TS_TICKS => x"11223344",
        MGT_MAC_ADDR => open,
        MGT_MAC_ADDR_WSTB => open
    );

    -- Bus assembly ----
    bit_bus(BIT_BUS_SIZE-1 downto 0) <= pcap_active;

    -- Soft Blocks ----
    softblocks_inst : entity work.soft_blocks
    port map(
        FCLK_CLK0 => clk_i,
        FCLK_RESET0 => reset_i,
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
        rdma_done_irq => rdma_done_irq
   );

end;
