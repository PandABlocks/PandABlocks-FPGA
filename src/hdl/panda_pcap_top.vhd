--------------------------------------------------------------------------------
--  File:       panda_pcap_top.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_pcap_top is
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
    m_axi_wid           : out std_logic_vector(5 downto 0);
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
    extbus_i            : in  extbus_t;
    -- Output pulses
    pcap_actv_o         : out std_logic;
    pcap_irq_o          : out std_logic
);
end panda_pcap_top;

architecture rtl of panda_pcap_top is

signal ENABLE_VAL       : std_logic_vector(SBUSBW-1 downto 0);
signal FRAME_VAL        : std_logic_vector(SBUSBW-1 downto 0);
signal CAPTURE_VAL      : std_logic_vector(SBUSBW-1 downto 0);
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
signal IRQ_STATUS       : std_logic_vector(31 downto 0);

signal enable           : std_logic;
signal capture          : std_logic;
signal frame            : std_logic;

signal capture_data     : std32_array(63 downto 0);
signal pcap_dat         : std_logic_vector(31 downto 0);
signal pcap_dat_valid   : std_logic;

signal dma_fifo_reset   : std_logic;
signal dma_fifo_ready   : std_logic;
signal pcap_status      : std_logic_vector(2 downto 0);
signal pcap_actv        : std_logic;

begin

pcap_actv_o <= pcap_actv;

-- Bitbus Assignments.
process(clk_i) begin
    if rising_edge(clk_i) then
        enable <= SBIT(sysbus_i, ENABLE_VAL);

        -- Mask all triggers with enable input.
        capture <= SBIT(sysbus_i, CAPTURE_VAL) and enable;
        frame <= SBIT(sysbus_i, FRAME_VAL) and enable;
    end if;
end process;

--
-- Block Control Register Interface.
--
pcap_ctrl_inst : entity work.panda_pcap_ctrl
port map (
    clk_i                   => clk_i,
    reset_i                 => reset_i,

    mem_cs_i                => mem_cs_i,
    mem_wstb_i              => mem_wstb_i,
    mem_addr_i              => mem_addr_i,
    mem_dat_i               => mem_dat_i,
    mem_dat_0_o             => mem_dat_0_o,
    mem_dat_1_o             => mem_dat_1_o,

    ENABLE                  => ENABLE_VAL,
    FRAME                   => FRAME_VAL,
    CAPTURE                 => CAPTURE_VAL,
    ERR_STATUS              => ERR_STATUS,

    START_WRITE             => START_WRITE,
    WRITE                   => WRITE,
    WRITE_WSTB              => WRITE_WSTB,
    FRAMING_MASK            => FRAMING_MASK,
    FRAMING_ENABLE          => FRAMING_ENABLE,
    FRAMING_MODE            => FRAMING_MODE,
    ARM                     => ARM,
    DISARM                  => DISARM,

    DMA_RESET               => DMA_RESET,
    DMA_START               => DMA_START,
    DMA_ADDR                => DMA_ADDR,
    DMA_ADDR_WSTB           => DMA_ADDR_WSTB,
    BLOCK_SIZE              => BLOCK_SIZE,
    TIMEOUT                 => TIMEOUT,
    IRQ_STATUS              => IRQ_STATUS
);

pcap_core : entity work.panda_pcap_core
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
    dma_fifo_ready_i        => dma_fifo_ready,
    sysbus_i                => sysbus_i,
    posbus_i                => posbus_i,
    extbus_i                => extbus_i,

    dma_fifo_reset_o        => dma_fifo_reset,
    pcap_dat_o              => pcap_dat,
    pcap_dat_valid_o        => pcap_dat_valid,
    pcap_actv_o             => pcap_actv,
    pcap_status_o           => pcap_status
);

--
-- Position Capture Core IP instantiation
--
pcap_dma_inst : entity work.panda_pcap_dma
port map (
    clk_i                   => clk_i,
    reset_i                 => reset_i,

    DMA_RESET               => DMA_RESET,
    DMA_INIT                => DMA_START,
    DMA_ADDR                => DMA_ADDR,
    DMA_ADDR_WSTB           => DMA_ADDR_WSTB,
    TIMEOUT                 => TIMEOUT,
    IRQ_STATUS              => IRQ_STATUS,
    BLOCK_SIZE              => BLOCK_SIZE,

    pcap_enabled_i          => pcap_actv,
    pcap_status_i           => pcap_status,
    dma_fifo_reset_i        => dma_fifo_reset,
    dma_fifo_ready_o        => dma_fifo_ready,
    pcap_dat_i              => pcap_dat,
    pcap_wstb_i             => pcap_dat_valid,
    irq_o                   => pcap_irq_o,

    m_axi_awready           => m_axi_awready,
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
    m_axi_wstrb             => m_axi_wstrb,
    m_axi_wid               => m_axi_wid
);

end rtl;

