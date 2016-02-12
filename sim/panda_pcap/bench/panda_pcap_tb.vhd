library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;
use work.test_interface.all;

ENTITY panda_pcap_tb IS
    port (
        ttlin_pad           : in std_logic_vector(5 downto 0)
    );
END panda_pcap_tb;

ARCHITECTURE behavior OF panda_pcap_tb IS

constant AXI_BURST_LEN      : integer := 16;
constant AXI_ADDR_WIDTH     : integer := 32;
constant AXI_DATA_WIDTH     : integer := 32;

signal mem_cs               : std_logic_vector(2**PAGE_NUM-1 downto 0);
signal mem_addr             : std_logic_vector(PAGE_AW-1 downto 0);
signal mem_odat             : std_logic_vector(31 downto 0);
signal mem_wstb             : std_logic;
signal mem_rstb             : std_logic;
signal mem_read_data        : std32_array(2**PAGE_NUM-1 downto 0);

signal sysbus               : sysbus_t := (others => '0');
signal posbus               : posbus_t := (others => (others => '0'));
signal extbus               : extbus_t := (others => (others => '0'));
signal act_i                : std_logic := '0';
signal pulse_i              : std_logic := '0';

signal S_AXI_HP0_arready    : std_logic := '0';
signal S_AXI_HP0_awready    : std_logic := '1';
signal S_AXI_HP0_bid        : std_logic_vector(5 downto 0) := (others => '0');
signal S_AXI_HP0_bresp      : std_logic_vector(1 downto 0) := (others => '0');
signal S_AXI_HP0_bvalid     : std_logic := '1';
signal S_AXI_HP0_rdata      : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
signal S_AXI_HP0_rid        : std_logic_vector(5 downto 0) := (others => '0');
signal S_AXI_HP0_rlast      : std_logic := '0';
signal S_AXI_HP0_rresp      : std_logic_vector(1 downto 0) := (others => '0');
signal S_AXI_HP0_rvalid     : std_logic := '0';
signal S_AXI_HP0_wready     : std_logic := '1';
signal S_AXI_HP0_araddr     : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
signal S_AXI_HP0_arburst    : std_logic_vector(1 downto 0);
signal S_AXI_HP0_arcache    : std_logic_vector(3 downto 0);
signal S_AXI_HP0_arid       : std_logic_vector(5 downto 0);
signal S_AXI_HP0_arlen      : std_logic_vector(3 downto 0);
signal S_AXI_HP0_arlock     : std_logic_vector(1 downto 0);
signal S_AXI_HP0_arprot     : std_logic_vector(2 downto 0);
signal S_AXI_HP0_arqos      : std_logic_vector(3 downto 0);
signal S_AXI_HP0_arsize     : std_logic_vector(2 downto 0);
signal S_AXI_HP0_arvalid    : std_logic;
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
signal S_AXI_HP0_rready     : std_logic;
signal S_AXI_HP0_wdata      : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
signal S_AXI_HP0_wid        : std_logic_vector(5 downto 0);
signal S_AXI_HP0_wlast      : std_logic;
signal S_AXI_HP0_wstrb      : std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
signal S_AXI_HP0_wvalid     : std_logic;

signal M00_AXI_awaddr       : std_logic_vector (31 downto 0);
signal M00_AXI_awprot       : std_logic_vector (2 downto 0);
signal M00_AXI_awvalid      : std_logic;
signal M00_AXI_awready      : std_logic;
signal M00_AXI_wdata        : std_logic_vector (31 downto 0 );
signal M00_AXI_wstrb        : std_logic_vector (3 downto 0 );
signal M00_AXI_wvalid       : std_logic;
signal M00_AXI_wready       : std_logic;
signal M00_AXI_bresp        : std_logic_vector (1 downto 0 );
signal M00_AXI_bvalid       : std_logic;
signal M00_AXI_bready       : std_logic;
signal M00_AXI_araddr       : std_logic_vector (31 downto 0 );
signal M00_AXI_arprot       : std_logic_vector (2 downto 0 );
signal M00_AXI_arvalid      : std_logic;
signal M00_AXI_arready      : std_logic;
signal M00_AXI_rdata        : std_logic_vector (31 downto 0 );
signal M00_AXI_rresp        : std_logic_vector (1 downto 0 );
signal M00_AXI_rvalid       : std_logic;
signal M00_AXI_rready       : std_logic;

signal tb_ARESETn           : std_logic := '0';
signal tb_RESETn            : std_logic := '0';
signal FCLK_CLK0            : std_logic;
signal IRQ_F2P              : std_logic_vector(3 downto 0) := "0000";
signal FCLK_RESET0          : std_logic;

signal data                 : unsigned(31 downto 0);

constant BLOCK_SIZE         : integer := 8192;

begin

tb_ARESETn <= '1' after 10 us;

process(FCLK_CLK0)
begin
    if rising_edge(FCLK_CLK0) then
        FCLK_RESET0 <= not tb_ARESETn;
        tb_RESETn <= tb_ARESETn;
    end if;
end process;

zynq : entity work.zynq_ps
port map (
    FCLK_CLK0               => FCLK_CLK0,
    FCLK_RESET0_N           => open,
    IRQ_F2P                 => IRQ_F2P,
    M00_AXI_araddr          => M00_AXI_araddr,
    M00_AXI_arprot          => M00_AXI_arprot,
    M00_AXI_arready         => M00_AXI_arready,
    M00_AXI_arvalid         => M00_AXI_arvalid,
    M00_AXI_awaddr          => M00_AXI_awaddr,
    M00_AXI_awprot          => M00_AXI_awprot,
    M00_AXI_awready         => M00_AXI_awready,
    M00_AXI_awvalid         => M00_AXI_awvalid,
    M00_AXI_bready          => M00_AXI_bready,
    M00_AXI_bresp           => M00_AXI_bresp,
    M00_AXI_bvalid          => M00_AXI_bvalid,
    M00_AXI_rdata           => M00_AXI_rdata,
    M00_AXI_rready          => M00_AXI_rready,
    M00_AXI_rresp           => M00_AXI_rresp,
    M00_AXI_rvalid          => M00_AXI_rvalid,
    M00_AXI_wdata           => M00_AXI_wdata,
    M00_AXI_wready          => M00_AXI_wready,
    M00_AXI_wstrb           => M00_AXI_wstrb,
    M00_AXI_wvalid          => M00_AXI_wvalid,

    S_AXI_HP0_araddr        => S_AXI_HP0_araddr ,
    S_AXI_HP0_arburst       => S_AXI_HP0_arburst,
    S_AXI_HP0_arcache       => S_AXI_HP0_arcache,
    S_AXI_HP0_arid          => S_AXI_HP0_arid   ,
    S_AXI_HP0_arlen         => S_AXI_HP0_arlen  ,
    S_AXI_HP0_arlock        => S_AXI_HP0_arlock ,
    S_AXI_HP0_arprot        => S_AXI_HP0_arprot ,
    S_AXI_HP0_arqos         => S_AXI_HP0_arqos  ,
    S_AXI_HP0_arready       => S_AXI_HP0_arready,
    S_AXI_HP0_arsize        => S_AXI_HP0_arsize ,
    S_AXI_HP0_arvalid       => S_AXI_HP0_arvalid,
    S_AXI_HP0_awaddr        => S_AXI_HP0_awaddr ,
    S_AXI_HP0_awburst       => S_AXI_HP0_awburst,
    S_AXI_HP0_awcache       => S_AXI_HP0_awcache,
    S_AXI_HP0_awid          => S_AXI_HP0_awid   ,
    S_AXI_HP0_awlen         => S_AXI_HP0_awlen  ,
    S_AXI_HP0_awlock        => S_AXI_HP0_awlock ,
    S_AXI_HP0_awprot        => S_AXI_HP0_awprot ,
    S_AXI_HP0_awqos         => S_AXI_HP0_awqos  ,
    S_AXI_HP0_awready       => S_AXI_HP0_awready,
    S_AXI_HP0_awsize        => S_AXI_HP0_awsize ,
    S_AXI_HP0_awvalid       => S_AXI_HP0_awvalid,
    S_AXI_HP0_bid           => S_AXI_HP0_bid    ,
    S_AXI_HP0_bready        => S_AXI_HP0_bready ,
    S_AXI_HP0_bresp         => S_AXI_HP0_bresp  ,
    S_AXI_HP0_bvalid        => S_AXI_HP0_bvalid ,
    S_AXI_HP0_rdata         => S_AXI_HP0_rdata  ,
    S_AXI_HP0_rid           => S_AXI_HP0_rid    ,
    S_AXI_HP0_rlast         => S_AXI_HP0_rlast  ,
    S_AXI_HP0_rready        => S_AXI_HP0_rready ,
    S_AXI_HP0_rresp         => S_AXI_HP0_rresp  ,
    S_AXI_HP0_rvalid        => S_AXI_HP0_rvalid ,
    S_AXI_HP0_wdata         => S_AXI_HP0_wdata  ,
    S_AXI_HP0_wid           => S_AXI_HP0_wid    ,
    S_AXI_HP0_wlast         => S_AXI_HP0_wlast  ,
    S_AXI_HP0_wready        => S_AXI_HP0_wready ,
    S_AXI_HP0_wstrb         => S_AXI_HP0_wstrb  ,
    S_AXI_HP0_wvalid        => S_AXI_HP0_wvalid ,

    PS_CLK                  => FCLK_CLK0,
    PS_PORB                 => tb_RESETn,
    PS_SRSTB                => tb_RESETn
);

panda_csr_if_inst : entity work.panda_csr_if
generic map (
    MEM_CSWIDTH                 => PAGE_NUM,
    MEM_AWIDTH                  => PAGE_AW
)
port map (
    S_AXI_CLK                   => FCLK_CLK0,
    S_AXI_RST                   => FCLK_RESET0,
    S_AXI_AWADDR                => M00_AXI_awaddr,
--    S_AXI_AWPROT                => M00_AXI_awprot,
    S_AXI_AWVALID               => M00_AXI_awvalid,
    S_AXI_AWREADY               => M00_AXI_awready,
    S_AXI_WDATA                 => M00_AXI_wdata,
    S_AXI_WSTRB                 => M00_AXI_wstrb,
    S_AXI_WVALID                => M00_AXI_wvalid,
    S_AXI_WREADY                => M00_AXI_wready,
    S_AXI_BRESP                 => M00_AXI_bresp,
    S_AXI_BVALID                => M00_AXI_bvalid,
    S_AXI_BREADY                => M00_AXI_bready,
    S_AXI_ARADDR                => M00_AXI_araddr,
--    S_AXI_ARPROT                => M00_AXI_arprot,
    S_AXI_ARVALID               => M00_AXI_arvalid,
    S_AXI_ARREADY               => M00_AXI_arready,
    S_AXI_RDATA                 => M00_AXI_rdata,
    S_AXI_RRESP                 => M00_AXI_rresp,
    S_AXI_RVALID                => M00_AXI_rvalid,
    S_AXI_RREADY                => M00_AXI_rready,
    -- Bus Memory Interface
    mem_addr_o                  => mem_addr,
    mem_dat_i                   => mem_read_data,
    mem_dat_o                   => mem_odat,
    mem_cs_o                    => mem_cs,
    mem_rstb_o                  => mem_rstb,
    mem_wstb_o                  => mem_wstb
);

uut: entity work.panda_pcap_top
PORT MAP (
    clk_i                       => FCLK_CLK0,
    reset_i                     => FCLK_RESET0,

    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs,
    mem_wstb_i => mem_wstb,
    mem_dat_i => mem_odat,
    mem_dat_0_o => mem_read_data(PCAP_CS),
    mem_dat_1_o => mem_read_data(DRV_CS),

    sysbus_i                    => sysbus,
    posbus_i                    => posbus,
    extbus_i                    => extbus,
    pcap_irq_o                  => IRQ_F2P(0),
    pcap_actv_o                 => open,

    m_axi_awaddr                => S_AXI_HP0_awaddr,
    m_axi_awburst               => S_AXI_HP0_awburst,
    m_axi_awcache               => S_AXI_HP0_awcache,
    m_axi_awid                  => S_AXI_HP0_awid,
    m_axi_awlen                 => S_AXI_HP0_awlen,
    m_axi_awlock                => S_AXI_HP0_awlock,
    m_axi_awprot                => S_AXI_HP0_awprot,
    m_axi_awqos                 => S_AXI_HP0_awqos,
    m_axi_awready               => S_AXI_HP0_awready,
    m_axi_awsize                => S_AXI_HP0_awsize,
    m_axi_awvalid               => S_AXI_HP0_awvalid,
    m_axi_bid                   => S_AXI_HP0_bid,
    m_axi_bready                => S_AXI_HP0_bready,
    m_axi_bresp                 => S_AXI_HP0_bresp,
    m_axi_bvalid                => S_AXI_HP0_bvalid,
    m_axi_wdata                 => S_AXI_HP0_wdata,
    m_axi_wid                   => S_AXI_HP0_wid,
    m_axi_wlast                 => S_AXI_HP0_wlast,
    m_axi_wready                => S_AXI_HP0_wready,
    m_axi_wstrb                 => S_AXI_HP0_wstrb,
    m_axi_wvalid                => S_AXI_HP0_wvalid
);

--
-- Sample data
--
sysbus(7 downto 2) <= ttlin_pad;

process(FCLK_CLK0)
begin
    if rising_edge(FCLK_CLK0) then
        if (ttlin_pad(0) = '0') then        -- Enable
            data <= (others => '0');
        elsif (ttlin_pad(2) = '1') then     -- Capture
            data <= data + 1;
        end if;
    end if;
end process;

posbus(12) <= std_logic_vector(data);
posbus(13) <= std_logic_vector(data(30 downto 0) & '0');
posbus(15) <= std_logic_vector(data(29 downto 0) & "00");

end;
