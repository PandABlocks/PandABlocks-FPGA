library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;
use work.test_interface.all;

ENTITY panda_pcap_tb IS
END panda_pcap_tb;

ARCHITECTURE behavior OF panda_pcap_tb IS

constant AXI_BURST_LEN      : integer := 16;
constant AXI_ADDR_WIDTH     : integer := 32;
constant AXI_DATA_WIDTH     : integer := 32;

signal mem_cs               : std_logic_vector(2**MEM_CS_NUM-1 downto 0);
signal mem_addr             : std_logic_vector(MEM_AW-1 downto 0);
signal mem_odat             : std_logic_vector(31 downto 0);
signal mem_wstb             : std_logic;
signal mem_rstb             : std_logic;
signal mem_read_data        : std32_array(2**MEM_CS_NUM-1 downto 0);

signal sysbus_i             : sysbus_t := (others => '0');
signal posbus_i             : posbus_t := (others => (others => '0'));
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
signal tb_ACLK              : std_logic := '0';
signal FCLK_RESET0_N        : std_logic := '0';
signal FCLK_CLK0            : std_logic;
signal IRQ_F2P              : std_logic_vector(3 downto 0) := "0000";
signal FCLK_RESET0          : std_logic;

begin

tb_ARESETn <= '1' after 10 us;
tb_ACLK <= not tb_ACLK after 10 ns;

process(FCLK_CLK0)
begin
    if rising_edge(FCLK_CLK0) then
        FCLK_RESET0_N <= tb_ARESETn;
        FCLK_RESET0 <= not FCLK_RESET0_N;
    end if;
end process;

zynq : entity work.zynq_ps
port map (
    S_AXI_HP0_ARREADY           => S_AXI_HP0_ARREADY,
    S_AXI_HP0_AWREADY           => S_AXI_HP0_AWREADY,
    S_AXI_HP0_BVALID            => S_AXI_HP0_BVALID,
    S_AXI_HP0_RLAST             => S_AXI_HP0_RLAST,
    S_AXI_HP0_RVALID            => S_AXI_HP0_RVALID,
    S_AXI_HP0_WREADY            => S_AXI_HP0_WREADY,
    S_AXI_HP0_BRESP             => S_AXI_HP0_BRESP,
    S_AXI_HP0_RRESP             => S_AXI_HP0_RRESP,
    S_AXI_HP0_BID               => S_AXI_HP0_BID,
    S_AXI_HP0_RID               => S_AXI_HP0_RID,
    S_AXI_HP0_RDATA             => S_AXI_HP0_RDATA,
    S_AXI_HP0_ARVALID           => S_AXI_HP0_ARVALID,
    S_AXI_HP0_AWVALID           => S_AXI_HP0_AWVALID,
    S_AXI_HP0_BREADY            => S_AXI_HP0_BREADY,
    S_AXI_HP0_RREADY            => S_AXI_HP0_RREADY,
    S_AXI_HP0_WLAST             => S_AXI_HP0_WLAST,
    S_AXI_HP0_WVALID            => S_AXI_HP0_WVALID,
    S_AXI_HP0_ARBURST           => S_AXI_HP0_ARBURST,
    S_AXI_HP0_ARLOCK            => S_AXI_HP0_ARLOCK,
    S_AXI_HP0_ARSIZE            => S_AXI_HP0_ARSIZE,
    S_AXI_HP0_AWBURST           => S_AXI_HP0_AWBURST,
    S_AXI_HP0_AWLOCK            => S_AXI_HP0_AWLOCK,
    S_AXI_HP0_AWSIZE            => S_AXI_HP0_AWSIZE,
    S_AXI_HP0_ARPROT            => S_AXI_HP0_ARPROT,
    S_AXI_HP0_AWPROT            => S_AXI_HP0_AWPROT,
    S_AXI_HP0_ARADDR            => S_AXI_HP0_ARADDR,
    S_AXI_HP0_AWADDR            => S_AXI_HP0_AWADDR,
    S_AXI_HP0_ARCACHE           => S_AXI_HP0_ARCACHE, 
    S_AXI_HP0_ARLEN             => S_AXI_HP0_ARLEN, 
    S_AXI_HP0_ARQOS             => S_AXI_HP0_ARQOS, 
    S_AXI_HP0_AWCACHE           => S_AXI_HP0_AWCACHE, 
    S_AXI_HP0_AWLEN             => S_AXI_HP0_AWLEN, 
    S_AXI_HP0_AWQOS             => S_AXI_HP0_AWQOS, 
    S_AXI_HP0_ARID              => S_AXI_HP0_ARID, 
    S_AXI_HP0_AWID              => S_AXI_HP0_AWID, 
    S_AXI_HP0_WID               => S_AXI_HP0_WID, 
    S_AXI_HP0_WDATA             => S_AXI_HP0_WDATA, 
    S_AXI_HP0_WSTRB             => S_AXI_HP0_WSTRB, 

    FCLK_CLK0                   => FCLK_CLK0,
    FCLK_RESET0_N               => FCLK_RESET0_N,
    PS_SRSTB                    => tb_ARESETn,
    PS_CLK                      => tb_ACLK   ,
    PS_PORB                     => tb_ARESETn,
    IRQ_F2P                     => IRQ_F2P,

    M00_AXI_AWADDR              => M00_AXI_awaddr,
    M00_AXI_AWPROT              => M00_AXI_awprot,
    M00_AXI_AWVALID             => M00_AXI_awvalid,
    M00_AXI_AWREADY             => M00_AXI_awready,
    M00_AXI_WDATA               => M00_AXI_wdata,
    M00_AXI_WSTRB               => M00_AXI_wstrb,
    M00_AXI_WVALID              => M00_AXI_wvalid,
    M00_AXI_WREADY              => M00_AXI_wready,
    M00_AXI_BRESP               => M00_AXI_bresp,
    M00_AXI_BVALID              => M00_AXI_bvalid,
    M00_AXI_BREADY              => M00_AXI_bready,
    M00_AXI_ARADDR              => M00_AXI_araddr,
    M00_AXI_ARPROT              => M00_AXI_arprot,
    M00_AXI_ARVALID             => M00_AXI_arvalid,
    M00_AXI_ARREADY             => M00_AXI_arready,
    M00_AXI_RDATA               => M00_AXI_rdata,
    M00_AXI_RRESP               => M00_AXI_rresp,
    M00_AXI_RVALID              => M00_AXI_rvalid,
    M00_AXI_RREADY              => M00_AXI_rready
);

panda_csr_if_inst : entity work.panda_csr_if
generic map (
    MEM_CSWIDTH                 => MEM_CS_NUM,
    MEM_AWIDTH                  => MEM_AW
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

uut: entity work.panda_pcap
PORT MAP (
    clk_i                       => FCLK_CLK0,
    reset_i                     => FCLK_RESET0,

    mem_cs_i                    => mem_cs(0),
    mem_wstb_i                  => mem_wstb,
    mem_addr_i                  => mem_addr(7 downto 0),
    mem_dat_i                   => mem_odat,
    mem_dat_o                   => open,

    sysbus_i                    => sysbus_i,
    posbus_i                    => posbus_i,
    pcap_irq_o                  => IRQ_F2P(0),

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

end;
