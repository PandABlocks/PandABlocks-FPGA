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
signal MISSED_CAPTURES  : unsigned(31 downto 0);
signal ERR_STATUS       : std_logic_vector(31 downto 0);

signal ARM              : std_logic;
signal DISARM           : std_logic;
signal START_WRITE      : std_logic;
signal WRITE            : std_logic_vector(31 downto 0);
signal WRITE_WSTB       : std_logic;
signal FRAMING_MASK     : std_logic_vector(31 downto 0);
signal FRAMING_ENABLE   : std_logic;
signal FRAMING_MODE     : std_logic_vector(31 downto 0);
signal DMAADDR          : std_logic_vector(31 downto 0);
signal DMAADDR_WSTB     : std_logic;
signal BLOCK_SIZE       : std_logic_vector(31 downto 0);
signal TIMEOUT          : std_logic_vector(31 downto 0);
signal IRQ_STATUS       : std_logic_vector(3 downto 0);
signal SMPL_COUNT       : std_logic_vector(31 downto 0);

signal enable           : std_logic;
signal enable_prev      : std_logic;
signal enable_fall      : std_logic;
signal capture          : std_logic;
signal capture_prev     : std_logic;
signal frame            : std_logic;

signal capture_pulse    : std_logic;
signal ongoing_capture  : std_logic;

signal capture_data     : std32_array(63 downto 0);
signal pcap_dat         : std_logic_vector(31 downto 0) := (others => '0');
signal pcap_wstb        : std_logic := '0';

signal INT_DISARM       : std_logic;

signal pcap_armed       : std_logic;
signal pcap_enabled     : std_logic;
signal pcap_disarmed    : std_logic_vector(1 downto 0);
signal pcap_fifo_rst    : std_logic := '0';

-- Mask BRAM signals
signal mask_length      : unsigned(5 downto 0);
signal mask_addra       : unsigned(5 downto 0);
signal mask_addrb       : unsigned(5 downto 0);
signal mask_doutb       : std_logic_vector(31 downto 0);

begin

-- Assign outputs.
pcap_actv_o <= pcap_armed;

-- Bitbus Assignments.
process(clk_i) begin
    if rising_edge(clk_i) then
        enable <= SBIT(sysbus_i, ENABLE_VAL);

        -- Mask all triggers with enable input.
        capture <= SBIT(sysbus_i, CAPTURE_VAL) and enable;
        frame <= SBIT(sysbus_i, FRAME_VAL) and enable;
    end if;
end process;

-- Detect rise/falling edge of internal signals.
enable_fall <= not enable and enable_prev;

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
    MISSED_CAPTURES         => std_logic_vector(MISSED_CAPTURES),
    ERR_STATUS              => ERR_STATUS,

    START_WRITE             => START_WRITE,
    WRITE                   => WRITE,
    WRITE_WSTB              => WRITE_WSTB,
    FRAMING_MASK            => FRAMING_MASK,
    FRAMING_ENABLE          => FRAMING_ENABLE,
    FRAMING_MODE            => FRAMING_MODE,
    ARM                     => ARM,
    DISARM                  => DISARM,

    DMAADDR                 => DMAADDR,
    DMAADDR_WSTB            => DMAADDR_WSTB,
    BLOCK_SIZE              => BLOCK_SIZE,
    TIMEOUT                 => TIMEOUT,
    IRQ_STATUS(3 downto 0)  => IRQ_STATUS,
    IRQ_STATUS(31 downto 4) => (others => '0'),
    SMPL_COUNT              => SMPL_COUNT
);

--
-- Position Capture Data Processing
--
pcap_dsp_inst : entity work.panda_pcap_dsp
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    posbus_i            => posbus_i,
    sysbus_i            => sysbus_i,
    extbus_i            => extbus_i,

    enable_i            => enable,
    frame_i             => frame,
    capture_i           => capture,
    capture_o           => capture_pulse,
    posn_o              => capture_data,

    FRAMING_MASK        => FRAMING_MASK,
    FRAMING_ENABLE      => FRAMING_ENABLE,
    FRAMING_MODE        => FRAMING_MODE
);

--
-- Pcap Mask Buffer
--
pcap_buffer : entity work.panda_pcap_buffer
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Configuration Registers
    START_WRITE         => START_WRITE,
    WRITE               => WRITE,
    WRITE_WSTB          => WRITE_WSTB,
    -- Block inputs
    fatpipe_i           => capture_data,
    capture_i           => capture_pulse,
    -- Output pulses
    pcap_dat_o          => pcap_dat,
    pcap_dat_valid_o    => pcap_wstb,
    ongoing_capture_o   => ongoing_capture
);

--
-- Position Capture Core IP instantiation
--
pcap_inst : entity work.panda_pcap
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    abort_i             => '0',
    pcap_dat_i          => pcap_dat,
    pcap_wstb_i         => pcap_wstb,
    irq_o               => pcap_irq_o,

    ARM                 => ARM,
    DISARM              => DISARM,
    DMAADDR             => DMAADDR,
    DMAADDR_WSTB        => DMAADDR_WSTB,
    TIMEOUT_VAL         => TIMEOUT,
    IRQ_STATUS          => IRQ_STATUS,
    SMPL_COUNT          => SMPL_COUNT,
    BLOCK_SIZE          => BLOCK_SIZE,

    m_axi_awready       => m_axi_awready,
    m_axi_awaddr        => m_axi_awaddr,
    m_axi_awvalid       => m_axi_awvalid,
    m_axi_awburst       => m_axi_awburst,
    m_axi_awcache       => m_axi_awcache,
    m_axi_awid          => m_axi_awid,
    m_axi_awlen         => m_axi_awlen,
    m_axi_awlock        => m_axi_awlock,
    m_axi_awprot        => m_axi_awprot,
    m_axi_awqos         => m_axi_awqos,
    m_axi_awsize        => m_axi_awsize,
    m_axi_bid           => m_axi_bid,
    m_axi_bready        => m_axi_bready,
    m_axi_bresp         => m_axi_bresp,
    m_axi_bvalid        => m_axi_bvalid,
    m_axi_wready        => m_axi_wready,
    m_axi_wdata         => m_axi_wdata,
    m_axi_wvalid        => m_axi_wvalid,
    m_axi_wlast         => m_axi_wlast,
    m_axi_wstrb         => m_axi_wstrb,
    m_axi_wid           => m_axi_wid
);


ERR_STATUS(31 downto 1) <= (others => '0');
ERR_STATUS(0) <= INT_DISARM;

end rtl;

