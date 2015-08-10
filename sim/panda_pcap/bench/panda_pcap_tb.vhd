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

signal clk              : std_logic := '0';
signal reset_i          : std_logic := '1';
signal mem_cs           : std_logic := '0';
signal mem_wstb         : std_logic := '0';
signal mem_addr         : std_logic_vector(3 downto 0) := (others => '0');
signal mem_dat          : std_logic_vector(31 downto 0) := (others => '0');
signal sysbus_i         : sysbus_t := (others => '0');
signal posbus_i         : posbus_t := (others => (others => '0'));
signal act_i            : std_logic := '0';
signal pulse_i          : std_logic := '0';

signal S_AXI_HP0_arready : std_logic := '0';
signal S_AXI_HP0_awready : std_logic := '1';
signal S_AXI_HP0_bid : std_logic_vector(5 downto 0) := (others => '0');
signal S_AXI_HP0_bresp : std_logic_vector(1 downto 0) := (others => '0');
signal S_AXI_HP0_bvalid : std_logic := '1';
signal S_AXI_HP0_rdata : std_logic_vector(63 downto 0) := (others => '0');
signal S_AXI_HP0_rid : std_logic_vector(5 downto 0) := (others => '0');
signal S_AXI_HP0_rlast : std_logic := '0';
signal S_AXI_HP0_rresp : std_logic_vector(1 downto 0) := (others => '0');
signal S_AXI_HP0_rvalid : std_logic := '0';
signal S_AXI_HP0_wready : std_logic := '1';
signal S_AXI_HP0_araddr : std_logic_vector(31 downto 0);
signal S_AXI_HP0_arburst : std_logic_vector(1 downto 0);
signal S_AXI_HP0_arcache : std_logic_vector(3 downto 0);
signal S_AXI_HP0_arid : std_logic_vector(5 downto 0);
signal S_AXI_HP0_arlen : std_logic_vector(3 downto 0);
signal S_AXI_HP0_arlock : std_logic_vector(1 downto 0);
signal S_AXI_HP0_arprot : std_logic_vector(2 downto 0);
signal S_AXI_HP0_arqos : std_logic_vector(3 downto 0);
signal S_AXI_HP0_arsize : std_logic_vector(2 downto 0);
signal S_AXI_HP0_arvalid : std_logic;
signal S_AXI_HP0_awaddr : std_logic_vector(31 downto 0);
signal S_AXI_HP0_awburst : std_logic_vector(1 downto 0);
signal S_AXI_HP0_awcache : std_logic_vector(3 downto 0);
signal S_AXI_HP0_awid : std_logic_vector(5 downto 0);
signal S_AXI_HP0_awlen : std_logic_vector(3 downto 0);
signal S_AXI_HP0_awlock : std_logic_vector(1 downto 0);
signal S_AXI_HP0_awprot : std_logic_vector(2 downto 0);
signal S_AXI_HP0_awqos : std_logic_vector(3 downto 0);
signal S_AXI_HP0_awsize : std_logic_vector(2 downto 0);
signal S_AXI_HP0_awvalid : std_logic;
signal S_AXI_HP0_bready     : std_logic;
signal S_AXI_HP0_rready     : std_logic;
signal S_AXI_HP0_wdata      : std_logic_vector(63 downto 0);
signal S_AXI_HP0_wid        : std_logic_vector(5 downto 0);
signal S_AXI_HP0_wlast      : std_logic;
signal S_AXI_HP0_wstrb      : std_logic_vector(7 downto 0);
signal S_AXI_HP0_wvalid     : std_logic;
signal tb_ARESETn           : std_logic := '0';
signal tb_ACLK              : std_logic := '0';
signal FCLK_RESET0_N        : std_logic;
signal FCLK_CLK0            : std_logic;
signal IRQ_F2P              : std_logic_vector(3 downto 0) := "0000";

begin

tb_ARESETn <= '1' after 10 us;
tb_ACLK <= not tb_ACLK after 10 ns;
clk <= FCLK_CLK0;
reset_i <= '0' after 1 us;

uut: entity work.panda_pcap
PORT MAP (
    clk_i               => clk,
    reset_i             => reset_i,

    mem_cs_i            => mem_cs,
    mem_wstb_i          => mem_wstb,
    mem_addr_i          => mem_addr,
    mem_dat_i           => mem_dat,
    mem_dat_o           => open,

    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    act_i               => act_i,
    pulse_i             => pulse_i,

    axi_awaddr          => S_AXI_HP0_awaddr,
    axi_awburst         => S_AXI_HP0_awburst,
    axi_awcache         => S_AXI_HP0_awcache,
    axi_awid            => S_AXI_HP0_awid,
    axi_awlen           => S_AXI_HP0_awlen,
    axi_awlock          => S_AXI_HP0_awlock,
    axi_awprot          => S_AXI_HP0_awprot,
    axi_awqos           => S_AXI_HP0_awqos,
    axi_awready         => S_AXI_HP0_awready,
    axi_awsize          => S_AXI_HP0_awsize,
    axi_awvalid         => S_AXI_HP0_awvalid,
    axi_bid             => S_AXI_HP0_bid,
    axi_bready          => S_AXI_HP0_bready,
    axi_bresp           => S_AXI_HP0_bresp,
    axi_bvalid          => S_AXI_HP0_bvalid,
    axi_wdata           => S_AXI_HP0_wdata,
    axi_wid             => S_AXI_HP0_wid,
    axi_wlast           => S_AXI_HP0_wlast,
    axi_wready          => S_AXI_HP0_wready,
    axi_wstrb           => S_AXI_HP0_wstrb,
    axi_wvalid          => S_AXI_HP0_wvalid
);

zynq_ps : entity work.processing_system7_bfm_0
port map (
    S_AXI_HP0_ARREADY  => S_AXI_HP0_ARREADY,
    S_AXI_HP0_AWREADY  => S_AXI_HP0_AWREADY,
    S_AXI_HP0_BVALID   => S_AXI_HP0_BVALID,
    S_AXI_HP0_RLAST    => S_AXI_HP0_RLAST,
    S_AXI_HP0_RVALID   => S_AXI_HP0_RVALID,
    S_AXI_HP0_WREADY   => S_AXI_HP0_WREADY,
    S_AXI_HP0_BRESP    => S_AXI_HP0_BRESP,
    S_AXI_HP0_RRESP    => S_AXI_HP0_RRESP,
    S_AXI_HP0_BID      => S_AXI_HP0_BID,
    S_AXI_HP0_RID      => S_AXI_HP0_RID,
    S_AXI_HP0_RDATA    => S_AXI_HP0_RDATA,
    S_AXI_HP0_ACLK     => FCLK_CLK0,
    S_AXI_HP0_ARVALID  => S_AXI_HP0_ARVALID,
    S_AXI_HP0_AWVALID  => S_AXI_HP0_AWVALID,
    S_AXI_HP0_BREADY   => S_AXI_HP0_BREADY,
    S_AXI_HP0_RREADY   => S_AXI_HP0_RREADY,
    S_AXI_HP0_WLAST    => S_AXI_HP0_WLAST,
    S_AXI_HP0_WVALID   => S_AXI_HP0_WVALID,
    S_AXI_HP0_ARBURST  => S_AXI_HP0_ARBURST,
    S_AXI_HP0_ARLOCK   => S_AXI_HP0_ARLOCK,
    S_AXI_HP0_ARSIZE   => S_AXI_HP0_ARSIZE,
    S_AXI_HP0_AWBURST  => S_AXI_HP0_AWBURST,
    S_AXI_HP0_AWLOCK   => S_AXI_HP0_AWLOCK,
    S_AXI_HP0_AWSIZE   => S_AXI_HP0_AWSIZE,
    S_AXI_HP0_ARPROT   => S_AXI_HP0_ARPROT,
    S_AXI_HP0_AWPROT   => S_AXI_HP0_AWPROT,
    S_AXI_HP0_ARADDR   => S_AXI_HP0_ARADDR,
    S_AXI_HP0_AWADDR   => S_AXI_HP0_AWADDR,
    S_AXI_HP0_ARCACHE  => S_AXI_HP0_ARCACHE, 
    S_AXI_HP0_ARLEN    => S_AXI_HP0_ARLEN, 
    S_AXI_HP0_ARQOS    => S_AXI_HP0_ARQOS, 
    S_AXI_HP0_AWCACHE  => S_AXI_HP0_AWCACHE, 
    S_AXI_HP0_AWLEN    => S_AXI_HP0_AWLEN, 
    S_AXI_HP0_AWQOS    => S_AXI_HP0_AWQOS, 
    S_AXI_HP0_ARID     => S_AXI_HP0_ARID, 
    S_AXI_HP0_AWID     => S_AXI_HP0_AWID, 
    S_AXI_HP0_WID      => S_AXI_HP0_WID, 
    S_AXI_HP0_WDATA    => S_AXI_HP0_WDATA, 
    S_AXI_HP0_WSTRB    => S_AXI_HP0_WSTRB, 
    FCLK_CLK0          => FCLK_CLK0, 
    FCLK_CLK1          => open,
    FCLK_CLK2          => open,
    FCLK_CLK3          => open,
    FCLK_RESET0_N      => FCLK_RESET0_N,
    FCLK_RESET1_N      => open,
    FCLK_RESET2_N      => open,
    FCLK_RESET3_N      => open,
    PS_SRSTB           => tb_ARESETn,
    PS_CLK             => tb_ACLK   ,
    PS_PORB            => tb_ARESETn,
    IRQ_F2P            => IRQ_F2P
);

-- Stimulus process
stim_proc: process
begin
--    PROC_CLK_EAT(1250, clk);
--    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCAP_DMAADDR_ADDR, 4096);
--    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCAP_DBG_MODE_ADDR, 1);
--    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCAP_ARM_ADDR, 1);
--    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCAP_DMAADDR_ADDR, 8192);
--    PROC_CLK_EAT(125, clk);
--    BLK_WRITE(clk, mem_addr, mem_dat, mem_cs, mem_wstb, PCAP_DBG_ENA_ADDR, 1);
    wait;
end process;

END;
