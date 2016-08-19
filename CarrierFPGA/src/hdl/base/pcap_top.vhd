--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Position Capture top-level module. This block instantiates:
--
--                  * pcap_ctrl: Block control and status interface
--                  * pcap_core_ctrl: DMA and ARM register control interface
--                  * pcap_core: Core position capture module
--                  * pcap_dma: DMA engine
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.addr_defines.all;
use work.top_defines.all;

entity pcap_top is
generic (
    AXI_BURST_LEN       : integer := 16;
    AXI_ADDR_WIDTH      : integer := 32;
    AXI_DATA_WIDTH      : integer := 32
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- AXI3 HP Bus Write Only Interface
    m_axi_awready       : in  std_logic;
    m_axi_awregion      : out std_logic_vector(3 downto 0);
    m_axi_awaddr        : out std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    m_axi_awvalid       : out std_logic;
    m_axi_awburst       : out std_logic_vector(1 downto 0);
    m_axi_awcache       : out std_logic_vector(3 downto 0);
    m_axi_awid          : out std_logic_vector(5 downto 0);
    m_axi_awlen         : out std_logic_vector(3 downto 0);
    m_axi_awlock        : out std_logic_vector(1 downto 0);
    m_axi_awprot        : out std_logic_vector(2 downto 0);
    m_axi_awqos         : out std_logic_vector(3 downto 0);
    m_axi_awsize        : out std_logic_vector(2 downto 0);
    m_axi_bid           : in  std_logic_vector(5 downto 0);
    m_axi_bready        : out std_logic;
    m_axi_bresp         : in  std_logic_vector(1 downto 0);
    m_axi_bvalid        : in  std_logic;
    m_axi_wready        : in  std_logic;
    m_axi_wdata         : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    m_axi_wvalid        : out std_logic;
    m_axi_wlast         : out std_logic;
    m_axi_wstrb         : out std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic_vector(2**PAGE_NUM-1 downto 0);
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_0_o         : out std_logic_vector(31 downto 0);
    mem_dat_1_o         : out std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    -- Output pulses
    pcap_actv_o         : out std_logic;
    pcap_irq_o          : out std_logic
);
end pcap_top;

architecture rtl of pcap_top is

signal ERR_STATUS       : std_logic_vector(31 downto 0);

signal ARM              : std_logic;
signal DISARM           : std_logic;
signal START_WRITE      : std_logic;
signal WRITE            : std_logic_vector(31 downto 0);
signal WRITE_WSTB       : std_logic;
signal FRAMING_MASK     : std_logic_vector(31 downto 0);
signal FRAMING_ENABLE   : std_logic;
signal FRAMING_MODE     : std_logic_vector(31 downto 0);
signal DMA_RESET        : std_logic;
signal DMA_START        : std_logic;
signal DMA_ADDR         : std_logic_vector(31 downto 0);
signal DMA_ADDR_WSTB    : std_logic;
signal BLOCK_SIZE       : std_logic_vector(31 downto 0);
signal TIMEOUT          : std_logic_vector(31 downto 0);
signal TIMEOUT_WSTB     : std_logic;
signal IRQ_STATUS       : std_logic_vector(31 downto 0);

signal capture_data     : std32_array(63 downto 0);
signal pcap_dat         : std_logic_vector(31 downto 0);
signal pcap_dat_valid   : std_logic;

signal dma_full         : std_logic;
signal pcap_status      : std_logic_vector(2 downto 0);
signal pcap_active      : std_logic;
signal pcap_done        : std_logic;

signal enable           : std_logic;
signal capture          : std_logic;
signal frame            : std_logic;
signal sysbus_dly       : sysbus_t;
signal posbus_dly       : posbus_t;

begin

pcap_actv_o <= pcap_active;

--------------------------------------------------------------------------
-- Pcap Block control interface
--------------------------------------------------------------------------
pcap_ctrl_inst : entity work.pcap_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    enable_o            => enable,
    capture_o           => capture,
    frame_o             => frame,

    ERR_STATUS          => ERR_STATUS,

    mem_cs_i            => mem_cs_i(PCAP_CS),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_dat_0_o
);

--------------------------------------------------------------------------
-- *REGs and *DMA space needs custom control block
--------------------------------------------------------------------------
pcap_core_ctrl_inst : entity work.pcap_core_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_dat_1_o,

    START_WRITE         => START_WRITE,
    WRITE               => WRITE,
    WRITE_WSTB          => WRITE_WSTB,
    FRAMING_MASK        => FRAMING_MASK,
    FRAMING_ENABLE      => FRAMING_ENABLE,
    FRAMING_MODE        => FRAMING_MODE,
    ARM                 => ARM,
    DISARM              => DISARM,

    DMA_RESET           => DMA_RESET,
    DMA_START           => DMA_START,
    DMA_ADDR            => DMA_ADDR,
    DMA_ADDR_WSTB       => DMA_ADDR_WSTB,
    BLOCK_SIZE          => BLOCK_SIZE,
    TIMEOUT             => TIMEOUT,
    TIMEOUT_WSTB        => TIMEOUT_WSTB,
    IRQ_STATUS          => IRQ_STATUS
);

--------------------------------------------------------------------------
-- Delay lines for System and Position Bus fields for capture
--------------------------------------------------------------------------
pcap_delay_inst : entity work.pcap_delay
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,

    sysbus_o            => sysbus_dly,
    posbus_o            => posbus_dly,

    mem_cs_i            => mem_cs_i(REG_CS),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i
);

--------------------------------------------------------------------------
-- Position Capture Core IP instantiation
--------------------------------------------------------------------------
pcap_core : entity work.pcap_core
port map (
    clk_i                   => clk_i,
    reset_i                 => reset_i,

    START_WRITE             => START_WRITE,
    WRITE                   => WRITE,
    WRITE_WSTB              => WRITE_WSTB,
    FRAMING_MASK            => FRAMING_MASK,
    FRAMING_ENABLE          => FRAMING_ENABLE,
    FRAMING_MODE            => FRAMING_MODE,
    ARM                     => ARM,
    DISARM                  => DISARM,
    ERR_STATUS              => ERR_STATUS,

    enable_i                => enable,
    capture_i               => capture,
    frame_i                 => frame,
    dma_full_i              => dma_full,
    sysbus_i                => sysbus_dly,
    posbus_i                => posbus_dly,

    pcap_dat_o              => pcap_dat,
    pcap_dat_valid_o        => pcap_dat_valid,
    pcap_done_o             => pcap_done,
    pcap_actv_o             => pcap_active,
    pcap_status_o           => pcap_status
);

--------------------------------------------------------------------------
-- Position Capture DMA Engine
--------------------------------------------------------------------------
pcap_dma_inst : entity work.pcap_dma
port map (
    clk_i                   => clk_i,
    reset_i                 => reset_i,

    DMA_RESET               => DMA_RESET,
    DMA_INIT                => DMA_START,
    DMA_ADDR                => DMA_ADDR,
    DMA_ADDR_WSTB           => DMA_ADDR_WSTB,
    TIMEOUT                 => TIMEOUT,
    TIMEOUT_WSTB            => TIMEOUT_WSTB,
    IRQ_STATUS              => IRQ_STATUS,
    BLOCK_SIZE              => BLOCK_SIZE,

    pcap_done_i             => pcap_done,
    pcap_status_i           => pcap_status,
    dma_full_o              => dma_full,
    pcap_dat_i              => pcap_dat,
    pcap_wstb_i             => pcap_dat_valid,
    irq_o                   => pcap_irq_o,

    m_axi_awready           => m_axi_awready,
    m_axi_awregion          => m_axi_awregion,
    m_axi_awaddr            => m_axi_awaddr,
    m_axi_awvalid           => m_axi_awvalid,
    m_axi_awburst           => m_axi_awburst,
    m_axi_awcache           => m_axi_awcache,
    m_axi_awid              => m_axi_awid,
    m_axi_awlen             => m_axi_awlen,
    m_axi_awlock            => m_axi_awlock,
    m_axi_awprot            => m_axi_awprot,
    m_axi_awqos             => m_axi_awqos,
    m_axi_awsize            => m_axi_awsize,
    m_axi_bid               => m_axi_bid,
    m_axi_bready            => m_axi_bready,
    m_axi_bresp             => m_axi_bresp,
    m_axi_bvalid            => m_axi_bvalid,
    m_axi_wready            => m_axi_wready,
    m_axi_wdata             => m_axi_wdata,
    m_axi_wvalid            => m_axi_wvalid,
    m_axi_wlast             => m_axi_wlast,
    m_axi_wstrb             => m_axi_wstrb
);

end rtl;

