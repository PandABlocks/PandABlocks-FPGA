--Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2015.1 (lin64) Build 1215546 Mon Apr 27 19:07:21 MDT 2015
--Date        : Tue Aug 11 11:51:57 2015
--Host        : pc0071.cs.diamond.ac.uk running 64-bit Red Hat Enterprise Linux Workstation release 6.7 (Santiago)
--Command     : generate_target zynq_ps.bd
--Design      : zynq_ps
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity s00_couplers_imp_14T3546 is
  port (
    M_ACLK : in STD_LOGIC;
    M_ARESETN : in STD_LOGIC;
    M_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_arready : in STD_LOGIC;
    M_AXI_arvalid : out STD_LOGIC;
    M_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_awready : in STD_LOGIC;
    M_AXI_awvalid : out STD_LOGIC;
    M_AXI_bready : out STD_LOGIC;
    M_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_bvalid : in STD_LOGIC;
    M_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AXI_rready : out STD_LOGIC;
    M_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_rvalid : in STD_LOGIC;
    M_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AXI_wready : in STD_LOGIC;
    M_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_wvalid : out STD_LOGIC;
    S_ACLK : in STD_LOGIC;
    S_ARESETN : in STD_LOGIC;
    S_AXI_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_arid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    S_AXI_arlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_arlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_arready : out STD_LOGIC;
    S_AXI_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_arvalid : in STD_LOGIC;
    S_AXI_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_awid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    S_AXI_awlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_awlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_awready : out STD_LOGIC;
    S_AXI_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_awvalid : in STD_LOGIC;
    S_AXI_bid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    S_AXI_bready : in STD_LOGIC;
    S_AXI_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_bvalid : out STD_LOGIC;
    S_AXI_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_rid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    S_AXI_rlast : out STD_LOGIC;
    S_AXI_rready : in STD_LOGIC;
    S_AXI_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_rvalid : out STD_LOGIC;
    S_AXI_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_wid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    S_AXI_wlast : in STD_LOGIC;
    S_AXI_wready : out STD_LOGIC;
    S_AXI_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_wvalid : in STD_LOGIC
  );
end s00_couplers_imp_14T3546;

architecture STRUCTURE of s00_couplers_imp_14T3546 is
  component zynq_ps_auto_pc_0 is
  port (
    aclk : in STD_LOGIC;
    aresetn : in STD_LOGIC;
    s_axi_awid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    s_axi_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_awlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_awlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_awvalid : in STD_LOGIC;
    s_axi_awready : out STD_LOGIC;
    s_axi_wid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    s_axi_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_wlast : in STD_LOGIC;
    s_axi_wvalid : in STD_LOGIC;
    s_axi_wready : out STD_LOGIC;
    s_axi_bid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    s_axi_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_bvalid : out STD_LOGIC;
    s_axi_bready : in STD_LOGIC;
    s_axi_arid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    s_axi_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_arlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_arlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axi_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_arvalid : in STD_LOGIC;
    s_axi_arready : out STD_LOGIC;
    s_axi_rid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    s_axi_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_rlast : out STD_LOGIC;
    s_axi_rvalid : out STD_LOGIC;
    s_axi_rready : in STD_LOGIC;
    m_axi_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awvalid : out STD_LOGIC;
    m_axi_awready : in STD_LOGIC;
    m_axi_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_wvalid : out STD_LOGIC;
    m_axi_wready : in STD_LOGIC;
    m_axi_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_bvalid : in STD_LOGIC;
    m_axi_bready : out STD_LOGIC;
    m_axi_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arvalid : out STD_LOGIC;
    m_axi_arready : in STD_LOGIC;
    m_axi_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_rvalid : in STD_LOGIC;
    m_axi_rready : out STD_LOGIC
  );
  end component zynq_ps_auto_pc_0;
  signal S_ACLK_1 : STD_LOGIC;
  signal S_ARESETN_1 : STD_LOGIC;
  signal auto_pc_to_s00_couplers_ARADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal auto_pc_to_s00_couplers_ARPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal auto_pc_to_s00_couplers_ARREADY : STD_LOGIC;
  signal auto_pc_to_s00_couplers_ARVALID : STD_LOGIC;
  signal auto_pc_to_s00_couplers_AWADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal auto_pc_to_s00_couplers_AWPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal auto_pc_to_s00_couplers_AWREADY : STD_LOGIC;
  signal auto_pc_to_s00_couplers_AWVALID : STD_LOGIC;
  signal auto_pc_to_s00_couplers_BREADY : STD_LOGIC;
  signal auto_pc_to_s00_couplers_BRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal auto_pc_to_s00_couplers_BVALID : STD_LOGIC;
  signal auto_pc_to_s00_couplers_RDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal auto_pc_to_s00_couplers_RREADY : STD_LOGIC;
  signal auto_pc_to_s00_couplers_RRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal auto_pc_to_s00_couplers_RVALID : STD_LOGIC;
  signal auto_pc_to_s00_couplers_WDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal auto_pc_to_s00_couplers_WREADY : STD_LOGIC;
  signal auto_pc_to_s00_couplers_WSTRB : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal auto_pc_to_s00_couplers_WVALID : STD_LOGIC;
  signal s00_couplers_to_auto_pc_ARADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal s00_couplers_to_auto_pc_ARBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal s00_couplers_to_auto_pc_ARCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal s00_couplers_to_auto_pc_ARID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal s00_couplers_to_auto_pc_ARLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal s00_couplers_to_auto_pc_ARLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal s00_couplers_to_auto_pc_ARPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal s00_couplers_to_auto_pc_ARQOS : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal s00_couplers_to_auto_pc_ARREADY : STD_LOGIC;
  signal s00_couplers_to_auto_pc_ARSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal s00_couplers_to_auto_pc_ARVALID : STD_LOGIC;
  signal s00_couplers_to_auto_pc_AWADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal s00_couplers_to_auto_pc_AWBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal s00_couplers_to_auto_pc_AWCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal s00_couplers_to_auto_pc_AWID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal s00_couplers_to_auto_pc_AWLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal s00_couplers_to_auto_pc_AWLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal s00_couplers_to_auto_pc_AWPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal s00_couplers_to_auto_pc_AWQOS : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal s00_couplers_to_auto_pc_AWREADY : STD_LOGIC;
  signal s00_couplers_to_auto_pc_AWSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal s00_couplers_to_auto_pc_AWVALID : STD_LOGIC;
  signal s00_couplers_to_auto_pc_BID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal s00_couplers_to_auto_pc_BREADY : STD_LOGIC;
  signal s00_couplers_to_auto_pc_BRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal s00_couplers_to_auto_pc_BVALID : STD_LOGIC;
  signal s00_couplers_to_auto_pc_RDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal s00_couplers_to_auto_pc_RID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal s00_couplers_to_auto_pc_RLAST : STD_LOGIC;
  signal s00_couplers_to_auto_pc_RREADY : STD_LOGIC;
  signal s00_couplers_to_auto_pc_RRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal s00_couplers_to_auto_pc_RVALID : STD_LOGIC;
  signal s00_couplers_to_auto_pc_WDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal s00_couplers_to_auto_pc_WID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal s00_couplers_to_auto_pc_WLAST : STD_LOGIC;
  signal s00_couplers_to_auto_pc_WREADY : STD_LOGIC;
  signal s00_couplers_to_auto_pc_WSTRB : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal s00_couplers_to_auto_pc_WVALID : STD_LOGIC;
begin
  M_AXI_araddr(31 downto 0) <= auto_pc_to_s00_couplers_ARADDR(31 downto 0);
  M_AXI_arprot(2 downto 0) <= auto_pc_to_s00_couplers_ARPROT(2 downto 0);
  M_AXI_arvalid <= auto_pc_to_s00_couplers_ARVALID;
  M_AXI_awaddr(31 downto 0) <= auto_pc_to_s00_couplers_AWADDR(31 downto 0);
  M_AXI_awprot(2 downto 0) <= auto_pc_to_s00_couplers_AWPROT(2 downto 0);
  M_AXI_awvalid <= auto_pc_to_s00_couplers_AWVALID;
  M_AXI_bready <= auto_pc_to_s00_couplers_BREADY;
  M_AXI_rready <= auto_pc_to_s00_couplers_RREADY;
  M_AXI_wdata(31 downto 0) <= auto_pc_to_s00_couplers_WDATA(31 downto 0);
  M_AXI_wstrb(3 downto 0) <= auto_pc_to_s00_couplers_WSTRB(3 downto 0);
  M_AXI_wvalid <= auto_pc_to_s00_couplers_WVALID;
  S_ACLK_1 <= S_ACLK;
  S_ARESETN_1 <= S_ARESETN;
  S_AXI_arready <= s00_couplers_to_auto_pc_ARREADY;
  S_AXI_awready <= s00_couplers_to_auto_pc_AWREADY;
  S_AXI_bid(11 downto 0) <= s00_couplers_to_auto_pc_BID(11 downto 0);
  S_AXI_bresp(1 downto 0) <= s00_couplers_to_auto_pc_BRESP(1 downto 0);
  S_AXI_bvalid <= s00_couplers_to_auto_pc_BVALID;
  S_AXI_rdata(31 downto 0) <= s00_couplers_to_auto_pc_RDATA(31 downto 0);
  S_AXI_rid(11 downto 0) <= s00_couplers_to_auto_pc_RID(11 downto 0);
  S_AXI_rlast <= s00_couplers_to_auto_pc_RLAST;
  S_AXI_rresp(1 downto 0) <= s00_couplers_to_auto_pc_RRESP(1 downto 0);
  S_AXI_rvalid <= s00_couplers_to_auto_pc_RVALID;
  S_AXI_wready <= s00_couplers_to_auto_pc_WREADY;
  auto_pc_to_s00_couplers_ARREADY <= M_AXI_arready;
  auto_pc_to_s00_couplers_AWREADY <= M_AXI_awready;
  auto_pc_to_s00_couplers_BRESP(1 downto 0) <= M_AXI_bresp(1 downto 0);
  auto_pc_to_s00_couplers_BVALID <= M_AXI_bvalid;
  auto_pc_to_s00_couplers_RDATA(31 downto 0) <= M_AXI_rdata(31 downto 0);
  auto_pc_to_s00_couplers_RRESP(1 downto 0) <= M_AXI_rresp(1 downto 0);
  auto_pc_to_s00_couplers_RVALID <= M_AXI_rvalid;
  auto_pc_to_s00_couplers_WREADY <= M_AXI_wready;
  s00_couplers_to_auto_pc_ARADDR(31 downto 0) <= S_AXI_araddr(31 downto 0);
  s00_couplers_to_auto_pc_ARBURST(1 downto 0) <= S_AXI_arburst(1 downto 0);
  s00_couplers_to_auto_pc_ARCACHE(3 downto 0) <= S_AXI_arcache(3 downto 0);
  s00_couplers_to_auto_pc_ARID(11 downto 0) <= S_AXI_arid(11 downto 0);
  s00_couplers_to_auto_pc_ARLEN(3 downto 0) <= S_AXI_arlen(3 downto 0);
  s00_couplers_to_auto_pc_ARLOCK(1 downto 0) <= S_AXI_arlock(1 downto 0);
  s00_couplers_to_auto_pc_ARPROT(2 downto 0) <= S_AXI_arprot(2 downto 0);
  s00_couplers_to_auto_pc_ARQOS(3 downto 0) <= S_AXI_arqos(3 downto 0);
  s00_couplers_to_auto_pc_ARSIZE(2 downto 0) <= S_AXI_arsize(2 downto 0);
  s00_couplers_to_auto_pc_ARVALID <= S_AXI_arvalid;
  s00_couplers_to_auto_pc_AWADDR(31 downto 0) <= S_AXI_awaddr(31 downto 0);
  s00_couplers_to_auto_pc_AWBURST(1 downto 0) <= S_AXI_awburst(1 downto 0);
  s00_couplers_to_auto_pc_AWCACHE(3 downto 0) <= S_AXI_awcache(3 downto 0);
  s00_couplers_to_auto_pc_AWID(11 downto 0) <= S_AXI_awid(11 downto 0);
  s00_couplers_to_auto_pc_AWLEN(3 downto 0) <= S_AXI_awlen(3 downto 0);
  s00_couplers_to_auto_pc_AWLOCK(1 downto 0) <= S_AXI_awlock(1 downto 0);
  s00_couplers_to_auto_pc_AWPROT(2 downto 0) <= S_AXI_awprot(2 downto 0);
  s00_couplers_to_auto_pc_AWQOS(3 downto 0) <= S_AXI_awqos(3 downto 0);
  s00_couplers_to_auto_pc_AWSIZE(2 downto 0) <= S_AXI_awsize(2 downto 0);
  s00_couplers_to_auto_pc_AWVALID <= S_AXI_awvalid;
  s00_couplers_to_auto_pc_BREADY <= S_AXI_bready;
  s00_couplers_to_auto_pc_RREADY <= S_AXI_rready;
  s00_couplers_to_auto_pc_WDATA(31 downto 0) <= S_AXI_wdata(31 downto 0);
  s00_couplers_to_auto_pc_WID(11 downto 0) <= S_AXI_wid(11 downto 0);
  s00_couplers_to_auto_pc_WLAST <= S_AXI_wlast;
  s00_couplers_to_auto_pc_WSTRB(3 downto 0) <= S_AXI_wstrb(3 downto 0);
  s00_couplers_to_auto_pc_WVALID <= S_AXI_wvalid;
auto_pc: component zynq_ps_auto_pc_0
     port map (
      aclk => S_ACLK_1,
      aresetn => S_ARESETN_1,
      m_axi_araddr(31 downto 0) => auto_pc_to_s00_couplers_ARADDR(31 downto 0),
      m_axi_arprot(2 downto 0) => auto_pc_to_s00_couplers_ARPROT(2 downto 0),
      m_axi_arready => auto_pc_to_s00_couplers_ARREADY,
      m_axi_arvalid => auto_pc_to_s00_couplers_ARVALID,
      m_axi_awaddr(31 downto 0) => auto_pc_to_s00_couplers_AWADDR(31 downto 0),
      m_axi_awprot(2 downto 0) => auto_pc_to_s00_couplers_AWPROT(2 downto 0),
      m_axi_awready => auto_pc_to_s00_couplers_AWREADY,
      m_axi_awvalid => auto_pc_to_s00_couplers_AWVALID,
      m_axi_bready => auto_pc_to_s00_couplers_BREADY,
      m_axi_bresp(1 downto 0) => auto_pc_to_s00_couplers_BRESP(1 downto 0),
      m_axi_bvalid => auto_pc_to_s00_couplers_BVALID,
      m_axi_rdata(31 downto 0) => auto_pc_to_s00_couplers_RDATA(31 downto 0),
      m_axi_rready => auto_pc_to_s00_couplers_RREADY,
      m_axi_rresp(1 downto 0) => auto_pc_to_s00_couplers_RRESP(1 downto 0),
      m_axi_rvalid => auto_pc_to_s00_couplers_RVALID,
      m_axi_wdata(31 downto 0) => auto_pc_to_s00_couplers_WDATA(31 downto 0),
      m_axi_wready => auto_pc_to_s00_couplers_WREADY,
      m_axi_wstrb(3 downto 0) => auto_pc_to_s00_couplers_WSTRB(3 downto 0),
      m_axi_wvalid => auto_pc_to_s00_couplers_WVALID,
      s_axi_araddr(31 downto 0) => s00_couplers_to_auto_pc_ARADDR(31 downto 0),
      s_axi_arburst(1 downto 0) => s00_couplers_to_auto_pc_ARBURST(1 downto 0),
      s_axi_arcache(3 downto 0) => s00_couplers_to_auto_pc_ARCACHE(3 downto 0),
      s_axi_arid(11 downto 0) => s00_couplers_to_auto_pc_ARID(11 downto 0),
      s_axi_arlen(3 downto 0) => s00_couplers_to_auto_pc_ARLEN(3 downto 0),
      s_axi_arlock(1 downto 0) => s00_couplers_to_auto_pc_ARLOCK(1 downto 0),
      s_axi_arprot(2 downto 0) => s00_couplers_to_auto_pc_ARPROT(2 downto 0),
      s_axi_arqos(3 downto 0) => s00_couplers_to_auto_pc_ARQOS(3 downto 0),
      s_axi_arready => s00_couplers_to_auto_pc_ARREADY,
      s_axi_arsize(2 downto 0) => s00_couplers_to_auto_pc_ARSIZE(2 downto 0),
      s_axi_arvalid => s00_couplers_to_auto_pc_ARVALID,
      s_axi_awaddr(31 downto 0) => s00_couplers_to_auto_pc_AWADDR(31 downto 0),
      s_axi_awburst(1 downto 0) => s00_couplers_to_auto_pc_AWBURST(1 downto 0),
      s_axi_awcache(3 downto 0) => s00_couplers_to_auto_pc_AWCACHE(3 downto 0),
      s_axi_awid(11 downto 0) => s00_couplers_to_auto_pc_AWID(11 downto 0),
      s_axi_awlen(3 downto 0) => s00_couplers_to_auto_pc_AWLEN(3 downto 0),
      s_axi_awlock(1 downto 0) => s00_couplers_to_auto_pc_AWLOCK(1 downto 0),
      s_axi_awprot(2 downto 0) => s00_couplers_to_auto_pc_AWPROT(2 downto 0),
      s_axi_awqos(3 downto 0) => s00_couplers_to_auto_pc_AWQOS(3 downto 0),
      s_axi_awready => s00_couplers_to_auto_pc_AWREADY,
      s_axi_awsize(2 downto 0) => s00_couplers_to_auto_pc_AWSIZE(2 downto 0),
      s_axi_awvalid => s00_couplers_to_auto_pc_AWVALID,
      s_axi_bid(11 downto 0) => s00_couplers_to_auto_pc_BID(11 downto 0),
      s_axi_bready => s00_couplers_to_auto_pc_BREADY,
      s_axi_bresp(1 downto 0) => s00_couplers_to_auto_pc_BRESP(1 downto 0),
      s_axi_bvalid => s00_couplers_to_auto_pc_BVALID,
      s_axi_rdata(31 downto 0) => s00_couplers_to_auto_pc_RDATA(31 downto 0),
      s_axi_rid(11 downto 0) => s00_couplers_to_auto_pc_RID(11 downto 0),
      s_axi_rlast => s00_couplers_to_auto_pc_RLAST,
      s_axi_rready => s00_couplers_to_auto_pc_RREADY,
      s_axi_rresp(1 downto 0) => s00_couplers_to_auto_pc_RRESP(1 downto 0),
      s_axi_rvalid => s00_couplers_to_auto_pc_RVALID,
      s_axi_wdata(31 downto 0) => s00_couplers_to_auto_pc_WDATA(31 downto 0),
      s_axi_wid(11 downto 0) => s00_couplers_to_auto_pc_WID(11 downto 0),
      s_axi_wlast => s00_couplers_to_auto_pc_WLAST,
      s_axi_wready => s00_couplers_to_auto_pc_WREADY,
      s_axi_wstrb(3 downto 0) => s00_couplers_to_auto_pc_WSTRB(3 downto 0),
      s_axi_wvalid => s00_couplers_to_auto_pc_WVALID
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity zynq_ps_axi_0 is
  port (
    ACLK : in STD_LOGIC;
    ARESETN : in STD_LOGIC;
    M00_ACLK : in STD_LOGIC;
    M00_ARESETN : in STD_LOGIC;
    M00_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_arready : in STD_LOGIC;
    M00_AXI_arvalid : out STD_LOGIC;
    M00_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_awready : in STD_LOGIC;
    M00_AXI_awvalid : out STD_LOGIC;
    M00_AXI_bready : out STD_LOGIC;
    M00_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_bvalid : in STD_LOGIC;
    M00_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_rready : out STD_LOGIC;
    M00_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_rvalid : in STD_LOGIC;
    M00_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_wready : in STD_LOGIC;
    M00_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M00_AXI_wvalid : out STD_LOGIC;
    S00_ACLK : in STD_LOGIC;
    S00_ARESETN : in STD_LOGIC;
    S00_AXI_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_arid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    S00_AXI_arlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_arlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_arready : out STD_LOGIC;
    S00_AXI_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_arvalid : in STD_LOGIC;
    S00_AXI_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_awid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    S00_AXI_awlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_awlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_awready : out STD_LOGIC;
    S00_AXI_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S00_AXI_awvalid : in STD_LOGIC;
    S00_AXI_bid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    S00_AXI_bready : in STD_LOGIC;
    S00_AXI_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_bvalid : out STD_LOGIC;
    S00_AXI_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_rid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    S00_AXI_rlast : out STD_LOGIC;
    S00_AXI_rready : in STD_LOGIC;
    S00_AXI_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S00_AXI_rvalid : out STD_LOGIC;
    S00_AXI_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S00_AXI_wid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    S00_AXI_wlast : in STD_LOGIC;
    S00_AXI_wready : out STD_LOGIC;
    S00_AXI_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S00_AXI_wvalid : in STD_LOGIC
  );
end zynq_ps_axi_0;

architecture STRUCTURE of zynq_ps_axi_0 is
  signal S00_ACLK_1 : STD_LOGIC;
  signal S00_ARESETN_1 : STD_LOGIC;
  signal axi_ACLK_net : STD_LOGIC;
  signal axi_ARESETN_net : STD_LOGIC;
  signal axi_to_s00_couplers_ARADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axi_to_s00_couplers_ARBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axi_to_s00_couplers_ARCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal axi_to_s00_couplers_ARID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal axi_to_s00_couplers_ARLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal axi_to_s00_couplers_ARLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axi_to_s00_couplers_ARPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal axi_to_s00_couplers_ARQOS : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal axi_to_s00_couplers_ARREADY : STD_LOGIC;
  signal axi_to_s00_couplers_ARSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal axi_to_s00_couplers_ARVALID : STD_LOGIC;
  signal axi_to_s00_couplers_AWADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axi_to_s00_couplers_AWBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axi_to_s00_couplers_AWCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal axi_to_s00_couplers_AWID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal axi_to_s00_couplers_AWLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal axi_to_s00_couplers_AWLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axi_to_s00_couplers_AWPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal axi_to_s00_couplers_AWQOS : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal axi_to_s00_couplers_AWREADY : STD_LOGIC;
  signal axi_to_s00_couplers_AWSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal axi_to_s00_couplers_AWVALID : STD_LOGIC;
  signal axi_to_s00_couplers_BID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal axi_to_s00_couplers_BREADY : STD_LOGIC;
  signal axi_to_s00_couplers_BRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axi_to_s00_couplers_BVALID : STD_LOGIC;
  signal axi_to_s00_couplers_RDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axi_to_s00_couplers_RID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal axi_to_s00_couplers_RLAST : STD_LOGIC;
  signal axi_to_s00_couplers_RREADY : STD_LOGIC;
  signal axi_to_s00_couplers_RRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axi_to_s00_couplers_RVALID : STD_LOGIC;
  signal axi_to_s00_couplers_WDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axi_to_s00_couplers_WID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal axi_to_s00_couplers_WLAST : STD_LOGIC;
  signal axi_to_s00_couplers_WREADY : STD_LOGIC;
  signal axi_to_s00_couplers_WSTRB : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal axi_to_s00_couplers_WVALID : STD_LOGIC;
  signal s00_couplers_to_axi_ARADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal s00_couplers_to_axi_ARPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal s00_couplers_to_axi_ARREADY : STD_LOGIC;
  signal s00_couplers_to_axi_ARVALID : STD_LOGIC;
  signal s00_couplers_to_axi_AWADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal s00_couplers_to_axi_AWPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal s00_couplers_to_axi_AWREADY : STD_LOGIC;
  signal s00_couplers_to_axi_AWVALID : STD_LOGIC;
  signal s00_couplers_to_axi_BREADY : STD_LOGIC;
  signal s00_couplers_to_axi_BRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal s00_couplers_to_axi_BVALID : STD_LOGIC;
  signal s00_couplers_to_axi_RDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal s00_couplers_to_axi_RREADY : STD_LOGIC;
  signal s00_couplers_to_axi_RRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal s00_couplers_to_axi_RVALID : STD_LOGIC;
  signal s00_couplers_to_axi_WDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal s00_couplers_to_axi_WREADY : STD_LOGIC;
  signal s00_couplers_to_axi_WSTRB : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal s00_couplers_to_axi_WVALID : STD_LOGIC;
begin
  M00_AXI_araddr(31 downto 0) <= s00_couplers_to_axi_ARADDR(31 downto 0);
  M00_AXI_arprot(2 downto 0) <= s00_couplers_to_axi_ARPROT(2 downto 0);
  M00_AXI_arvalid <= s00_couplers_to_axi_ARVALID;
  M00_AXI_awaddr(31 downto 0) <= s00_couplers_to_axi_AWADDR(31 downto 0);
  M00_AXI_awprot(2 downto 0) <= s00_couplers_to_axi_AWPROT(2 downto 0);
  M00_AXI_awvalid <= s00_couplers_to_axi_AWVALID;
  M00_AXI_bready <= s00_couplers_to_axi_BREADY;
  M00_AXI_rready <= s00_couplers_to_axi_RREADY;
  M00_AXI_wdata(31 downto 0) <= s00_couplers_to_axi_WDATA(31 downto 0);
  M00_AXI_wstrb(3 downto 0) <= s00_couplers_to_axi_WSTRB(3 downto 0);
  M00_AXI_wvalid <= s00_couplers_to_axi_WVALID;
  S00_ACLK_1 <= S00_ACLK;
  S00_ARESETN_1 <= S00_ARESETN;
  S00_AXI_arready <= axi_to_s00_couplers_ARREADY;
  S00_AXI_awready <= axi_to_s00_couplers_AWREADY;
  S00_AXI_bid(11 downto 0) <= axi_to_s00_couplers_BID(11 downto 0);
  S00_AXI_bresp(1 downto 0) <= axi_to_s00_couplers_BRESP(1 downto 0);
  S00_AXI_bvalid <= axi_to_s00_couplers_BVALID;
  S00_AXI_rdata(31 downto 0) <= axi_to_s00_couplers_RDATA(31 downto 0);
  S00_AXI_rid(11 downto 0) <= axi_to_s00_couplers_RID(11 downto 0);
  S00_AXI_rlast <= axi_to_s00_couplers_RLAST;
  S00_AXI_rresp(1 downto 0) <= axi_to_s00_couplers_RRESP(1 downto 0);
  S00_AXI_rvalid <= axi_to_s00_couplers_RVALID;
  S00_AXI_wready <= axi_to_s00_couplers_WREADY;
  axi_ACLK_net <= M00_ACLK;
  axi_ARESETN_net <= M00_ARESETN;
  axi_to_s00_couplers_ARADDR(31 downto 0) <= S00_AXI_araddr(31 downto 0);
  axi_to_s00_couplers_ARBURST(1 downto 0) <= S00_AXI_arburst(1 downto 0);
  axi_to_s00_couplers_ARCACHE(3 downto 0) <= S00_AXI_arcache(3 downto 0);
  axi_to_s00_couplers_ARID(11 downto 0) <= S00_AXI_arid(11 downto 0);
  axi_to_s00_couplers_ARLEN(3 downto 0) <= S00_AXI_arlen(3 downto 0);
  axi_to_s00_couplers_ARLOCK(1 downto 0) <= S00_AXI_arlock(1 downto 0);
  axi_to_s00_couplers_ARPROT(2 downto 0) <= S00_AXI_arprot(2 downto 0);
  axi_to_s00_couplers_ARQOS(3 downto 0) <= S00_AXI_arqos(3 downto 0);
  axi_to_s00_couplers_ARSIZE(2 downto 0) <= S00_AXI_arsize(2 downto 0);
  axi_to_s00_couplers_ARVALID <= S00_AXI_arvalid;
  axi_to_s00_couplers_AWADDR(31 downto 0) <= S00_AXI_awaddr(31 downto 0);
  axi_to_s00_couplers_AWBURST(1 downto 0) <= S00_AXI_awburst(1 downto 0);
  axi_to_s00_couplers_AWCACHE(3 downto 0) <= S00_AXI_awcache(3 downto 0);
  axi_to_s00_couplers_AWID(11 downto 0) <= S00_AXI_awid(11 downto 0);
  axi_to_s00_couplers_AWLEN(3 downto 0) <= S00_AXI_awlen(3 downto 0);
  axi_to_s00_couplers_AWLOCK(1 downto 0) <= S00_AXI_awlock(1 downto 0);
  axi_to_s00_couplers_AWPROT(2 downto 0) <= S00_AXI_awprot(2 downto 0);
  axi_to_s00_couplers_AWQOS(3 downto 0) <= S00_AXI_awqos(3 downto 0);
  axi_to_s00_couplers_AWSIZE(2 downto 0) <= S00_AXI_awsize(2 downto 0);
  axi_to_s00_couplers_AWVALID <= S00_AXI_awvalid;
  axi_to_s00_couplers_BREADY <= S00_AXI_bready;
  axi_to_s00_couplers_RREADY <= S00_AXI_rready;
  axi_to_s00_couplers_WDATA(31 downto 0) <= S00_AXI_wdata(31 downto 0);
  axi_to_s00_couplers_WID(11 downto 0) <= S00_AXI_wid(11 downto 0);
  axi_to_s00_couplers_WLAST <= S00_AXI_wlast;
  axi_to_s00_couplers_WSTRB(3 downto 0) <= S00_AXI_wstrb(3 downto 0);
  axi_to_s00_couplers_WVALID <= S00_AXI_wvalid;
  s00_couplers_to_axi_ARREADY <= M00_AXI_arready;
  s00_couplers_to_axi_AWREADY <= M00_AXI_awready;
  s00_couplers_to_axi_BRESP(1 downto 0) <= M00_AXI_bresp(1 downto 0);
  s00_couplers_to_axi_BVALID <= M00_AXI_bvalid;
  s00_couplers_to_axi_RDATA(31 downto 0) <= M00_AXI_rdata(31 downto 0);
  s00_couplers_to_axi_RRESP(1 downto 0) <= M00_AXI_rresp(1 downto 0);
  s00_couplers_to_axi_RVALID <= M00_AXI_rvalid;
  s00_couplers_to_axi_WREADY <= M00_AXI_wready;
s00_couplers: entity work.s00_couplers_imp_14T3546
     port map (
      M_ACLK => axi_ACLK_net,
      M_ARESETN => axi_ARESETN_net,
      M_AXI_araddr(31 downto 0) => s00_couplers_to_axi_ARADDR(31 downto 0),
      M_AXI_arprot(2 downto 0) => s00_couplers_to_axi_ARPROT(2 downto 0),
      M_AXI_arready => s00_couplers_to_axi_ARREADY,
      M_AXI_arvalid => s00_couplers_to_axi_ARVALID,
      M_AXI_awaddr(31 downto 0) => s00_couplers_to_axi_AWADDR(31 downto 0),
      M_AXI_awprot(2 downto 0) => s00_couplers_to_axi_AWPROT(2 downto 0),
      M_AXI_awready => s00_couplers_to_axi_AWREADY,
      M_AXI_awvalid => s00_couplers_to_axi_AWVALID,
      M_AXI_bready => s00_couplers_to_axi_BREADY,
      M_AXI_bresp(1 downto 0) => s00_couplers_to_axi_BRESP(1 downto 0),
      M_AXI_bvalid => s00_couplers_to_axi_BVALID,
      M_AXI_rdata(31 downto 0) => s00_couplers_to_axi_RDATA(31 downto 0),
      M_AXI_rready => s00_couplers_to_axi_RREADY,
      M_AXI_rresp(1 downto 0) => s00_couplers_to_axi_RRESP(1 downto 0),
      M_AXI_rvalid => s00_couplers_to_axi_RVALID,
      M_AXI_wdata(31 downto 0) => s00_couplers_to_axi_WDATA(31 downto 0),
      M_AXI_wready => s00_couplers_to_axi_WREADY,
      M_AXI_wstrb(3 downto 0) => s00_couplers_to_axi_WSTRB(3 downto 0),
      M_AXI_wvalid => s00_couplers_to_axi_WVALID,
      S_ACLK => S00_ACLK_1,
      S_ARESETN => S00_ARESETN_1,
      S_AXI_araddr(31 downto 0) => axi_to_s00_couplers_ARADDR(31 downto 0),
      S_AXI_arburst(1 downto 0) => axi_to_s00_couplers_ARBURST(1 downto 0),
      S_AXI_arcache(3 downto 0) => axi_to_s00_couplers_ARCACHE(3 downto 0),
      S_AXI_arid(11 downto 0) => axi_to_s00_couplers_ARID(11 downto 0),
      S_AXI_arlen(3 downto 0) => axi_to_s00_couplers_ARLEN(3 downto 0),
      S_AXI_arlock(1 downto 0) => axi_to_s00_couplers_ARLOCK(1 downto 0),
      S_AXI_arprot(2 downto 0) => axi_to_s00_couplers_ARPROT(2 downto 0),
      S_AXI_arqos(3 downto 0) => axi_to_s00_couplers_ARQOS(3 downto 0),
      S_AXI_arready => axi_to_s00_couplers_ARREADY,
      S_AXI_arsize(2 downto 0) => axi_to_s00_couplers_ARSIZE(2 downto 0),
      S_AXI_arvalid => axi_to_s00_couplers_ARVALID,
      S_AXI_awaddr(31 downto 0) => axi_to_s00_couplers_AWADDR(31 downto 0),
      S_AXI_awburst(1 downto 0) => axi_to_s00_couplers_AWBURST(1 downto 0),
      S_AXI_awcache(3 downto 0) => axi_to_s00_couplers_AWCACHE(3 downto 0),
      S_AXI_awid(11 downto 0) => axi_to_s00_couplers_AWID(11 downto 0),
      S_AXI_awlen(3 downto 0) => axi_to_s00_couplers_AWLEN(3 downto 0),
      S_AXI_awlock(1 downto 0) => axi_to_s00_couplers_AWLOCK(1 downto 0),
      S_AXI_awprot(2 downto 0) => axi_to_s00_couplers_AWPROT(2 downto 0),
      S_AXI_awqos(3 downto 0) => axi_to_s00_couplers_AWQOS(3 downto 0),
      S_AXI_awready => axi_to_s00_couplers_AWREADY,
      S_AXI_awsize(2 downto 0) => axi_to_s00_couplers_AWSIZE(2 downto 0),
      S_AXI_awvalid => axi_to_s00_couplers_AWVALID,
      S_AXI_bid(11 downto 0) => axi_to_s00_couplers_BID(11 downto 0),
      S_AXI_bready => axi_to_s00_couplers_BREADY,
      S_AXI_bresp(1 downto 0) => axi_to_s00_couplers_BRESP(1 downto 0),
      S_AXI_bvalid => axi_to_s00_couplers_BVALID,
      S_AXI_rdata(31 downto 0) => axi_to_s00_couplers_RDATA(31 downto 0),
      S_AXI_rid(11 downto 0) => axi_to_s00_couplers_RID(11 downto 0),
      S_AXI_rlast => axi_to_s00_couplers_RLAST,
      S_AXI_rready => axi_to_s00_couplers_RREADY,
      S_AXI_rresp(1 downto 0) => axi_to_s00_couplers_RRESP(1 downto 0),
      S_AXI_rvalid => axi_to_s00_couplers_RVALID,
      S_AXI_wdata(31 downto 0) => axi_to_s00_couplers_WDATA(31 downto 0),
      S_AXI_wid(11 downto 0) => axi_to_s00_couplers_WID(11 downto 0),
      S_AXI_wlast => axi_to_s00_couplers_WLAST,
      S_AXI_wready => axi_to_s00_couplers_WREADY,
      S_AXI_wstrb(3 downto 0) => axi_to_s00_couplers_WSTRB(3 downto 0),
      S_AXI_wvalid => axi_to_s00_couplers_WVALID
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity zynq_ps is
  port (
    FCLK_CLK0 : out STD_LOGIC;
    FCLK_RESET0_N : in STD_LOGIC;
    IRQ_F2P : in STD_LOGIC_VECTOR ( 3 downto 0 );
    M00_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_arready : in STD_LOGIC;
    M00_AXI_arvalid : out STD_LOGIC;
    M00_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_awready : in STD_LOGIC;
    M00_AXI_awvalid : out STD_LOGIC;
    M00_AXI_bready : out STD_LOGIC;
    M00_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_bvalid : in STD_LOGIC;
    M00_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_rready : out STD_LOGIC;
    M00_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_rvalid : in STD_LOGIC;
    M00_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_wready : in STD_LOGIC;
    M00_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M00_AXI_wvalid : out STD_LOGIC;
    PS_CLK : in STD_LOGIC;
    PS_PORB : in STD_LOGIC;
    PS_SRSTB : in STD_LOGIC;
    S_AXI_HP0_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_arid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_arlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_arlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_arready : out STD_LOGIC;
    S_AXI_HP0_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_arvalid : in STD_LOGIC;
    S_AXI_HP0_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_awid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_awlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_awlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_awready : out STD_LOGIC;
    S_AXI_HP0_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_awvalid : in STD_LOGIC;
    S_AXI_HP0_bid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_bready : in STD_LOGIC;
    S_AXI_HP0_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_bvalid : out STD_LOGIC;
    S_AXI_HP0_rdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    S_AXI_HP0_rid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_rlast : out STD_LOGIC;
    S_AXI_HP0_rready : in STD_LOGIC;
    S_AXI_HP0_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_rvalid : out STD_LOGIC;
    S_AXI_HP0_wdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    S_AXI_HP0_wid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_wlast : in STD_LOGIC;
    S_AXI_HP0_wready : out STD_LOGIC;
    S_AXI_HP0_wstrb : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP0_wvalid : in STD_LOGIC
  );
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of zynq_ps : entity is "zynq_ps,IP_Integrator,{x_ipProduct=Vivado 2015.1,x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=zynq_ps,x_ipVersion=1.00.a,x_ipLanguage=VHDL,numBlks=5,numReposBlks=3,numNonXlnxBlks=0,numHierBlks=2,maxHierDepth=0,synth_mode=Global}";
  attribute HW_HANDOFF : string;
  attribute HW_HANDOFF of zynq_ps : entity is "zynq_ps.hwdef";
end zynq_ps;

architecture STRUCTURE of zynq_ps is
  component zynq_ps_ps_0 is
  port (
    M_AXI_GP0_ARVALID : out STD_LOGIC;
    M_AXI_GP0_AWVALID : out STD_LOGIC;
    M_AXI_GP0_BREADY : out STD_LOGIC;
    M_AXI_GP0_RREADY : out STD_LOGIC;
    M_AXI_GP0_WLAST : out STD_LOGIC;
    M_AXI_GP0_WVALID : out STD_LOGIC;
    M_AXI_GP0_ARID : out STD_LOGIC_VECTOR ( 11 downto 0 );
    M_AXI_GP0_AWID : out STD_LOGIC_VECTOR ( 11 downto 0 );
    M_AXI_GP0_WID : out STD_LOGIC_VECTOR ( 11 downto 0 );
    M_AXI_GP0_ARBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_GP0_ARLOCK : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_GP0_ARSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_GP0_AWBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_GP0_AWLOCK : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_GP0_AWSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_GP0_ARPROT : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_GP0_AWPROT : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_GP0_ARADDR : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AXI_GP0_AWADDR : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AXI_GP0_WDATA : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AXI_GP0_ARCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_GP0_ARLEN : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_GP0_ARQOS : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_GP0_AWCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_GP0_AWLEN : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_GP0_AWQOS : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_GP0_WSTRB : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_GP0_ACLK : in STD_LOGIC;
    M_AXI_GP0_ARREADY : in STD_LOGIC;
    M_AXI_GP0_AWREADY : in STD_LOGIC;
    M_AXI_GP0_BVALID : in STD_LOGIC;
    M_AXI_GP0_RLAST : in STD_LOGIC;
    M_AXI_GP0_RVALID : in STD_LOGIC;
    M_AXI_GP0_WREADY : in STD_LOGIC;
    M_AXI_GP0_BID : in STD_LOGIC_VECTOR ( 11 downto 0 );
    M_AXI_GP0_RID : in STD_LOGIC_VECTOR ( 11 downto 0 );
    M_AXI_GP0_BRESP : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_GP0_RRESP : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_GP0_RDATA : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_ARREADY : out STD_LOGIC;
    S_AXI_HP0_AWREADY : out STD_LOGIC;
    S_AXI_HP0_BVALID : out STD_LOGIC;
    S_AXI_HP0_RLAST : out STD_LOGIC;
    S_AXI_HP0_RVALID : out STD_LOGIC;
    S_AXI_HP0_WREADY : out STD_LOGIC;
    S_AXI_HP0_BRESP : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_RRESP : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_BID : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_RID : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_RDATA : out STD_LOGIC_VECTOR ( 63 downto 0 );
    S_AXI_HP0_ACLK : in STD_LOGIC;
    S_AXI_HP0_ARVALID : in STD_LOGIC;
    S_AXI_HP0_AWVALID : in STD_LOGIC;
    S_AXI_HP0_BREADY : in STD_LOGIC;
    S_AXI_HP0_RREADY : in STD_LOGIC;
    S_AXI_HP0_WLAST : in STD_LOGIC;
    S_AXI_HP0_WVALID : in STD_LOGIC;
    S_AXI_HP0_ARBURST : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_ARLOCK : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_ARSIZE : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_AWBURST : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_AWLOCK : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_AWSIZE : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_ARPROT : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_AWPROT : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_ARADDR : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_AWADDR : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_ARCACHE : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_ARLEN : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_ARQOS : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_AWCACHE : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_AWLEN : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_AWQOS : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_ARID : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_AWID : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_WID : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_WDATA : in STD_LOGIC_VECTOR ( 63 downto 0 );
    S_AXI_HP0_WSTRB : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP1_ARREADY : out STD_LOGIC;
    S_AXI_HP1_AWREADY : out STD_LOGIC;
    S_AXI_HP1_BVALID : out STD_LOGIC;
    S_AXI_HP1_RLAST : out STD_LOGIC;
    S_AXI_HP1_RVALID : out STD_LOGIC;
    S_AXI_HP1_WREADY : out STD_LOGIC;
    S_AXI_HP1_BRESP : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_RRESP : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_BID : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_RID : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_RDATA : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_ACLK : in STD_LOGIC;
    S_AXI_HP1_ARVALID : in STD_LOGIC;
    S_AXI_HP1_AWVALID : in STD_LOGIC;
    S_AXI_HP1_BREADY : in STD_LOGIC;
    S_AXI_HP1_RREADY : in STD_LOGIC;
    S_AXI_HP1_WLAST : in STD_LOGIC;
    S_AXI_HP1_WVALID : in STD_LOGIC;
    S_AXI_HP1_ARBURST : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_ARLOCK : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_ARSIZE : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_AWBURST : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_AWLOCK : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_AWSIZE : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_ARPROT : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_AWPROT : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_ARADDR : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_AWADDR : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_ARCACHE : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_ARLEN : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_ARQOS : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_AWCACHE : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_AWLEN : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_AWQOS : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_ARID : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_AWID : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_WID : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_WDATA : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_WSTRB : in STD_LOGIC_VECTOR ( 3 downto 0 );
    FCLK_CLK0 : out STD_LOGIC;
    FCLK_CLK1 : out STD_LOGIC;
    FCLK_CLK2 : out STD_LOGIC;
    FCLK_CLK3 : out STD_LOGIC;
    FCLK_RESET0_N : out STD_LOGIC;
    FCLK_RESET1_N : out STD_LOGIC;
    FCLK_RESET2_N : out STD_LOGIC;
    FCLK_RESET3_N : out STD_LOGIC;
    PS_SRSTB : in STD_LOGIC;
    PS_CLK : in STD_LOGIC;
    PS_PORB : in STD_LOGIC;
    IRQ_F2P : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component zynq_ps_ps_0;
  component zynq_ps_hp1_0 is
  port (
    m_axi_aclk : in STD_LOGIC;
    m_axi_aresetn : in STD_LOGIC;
    m_axi_wid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_awlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_awlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awvalid : out STD_LOGIC;
    m_axi_awready : in STD_LOGIC;
    m_axi_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_wlast : out STD_LOGIC;
    m_axi_wvalid : out STD_LOGIC;
    m_axi_wready : in STD_LOGIC;
    m_axi_bid : in STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_bvalid : in STD_LOGIC;
    m_axi_bready : out STD_LOGIC;
    m_axi_arid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_arlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_arlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arvalid : out STD_LOGIC;
    m_axi_arready : in STD_LOGIC;
    m_axi_rid : in STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axi_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_rlast : in STD_LOGIC;
    m_axi_rvalid : in STD_LOGIC;
    m_axi_rready : out STD_LOGIC
  );
  end component zynq_ps_hp1_0;
  signal FCLK_RESET0_N_1 : STD_LOGIC;
  signal GND_1 : STD_LOGIC;
  signal IRQ_F2P_1 : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal PS_CLK_1 : STD_LOGIC;
  signal PS_PORB_1 : STD_LOGIC;
  signal PS_SRSTB_1 : STD_LOGIC;
  signal S_AXI_HP0_1_ARADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal S_AXI_HP0_1_ARBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal S_AXI_HP0_1_ARCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal S_AXI_HP0_1_ARID : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal S_AXI_HP0_1_ARLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal S_AXI_HP0_1_ARLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal S_AXI_HP0_1_ARPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal S_AXI_HP0_1_ARQOS : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal S_AXI_HP0_1_ARREADY : STD_LOGIC;
  signal S_AXI_HP0_1_ARSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal S_AXI_HP0_1_ARVALID : STD_LOGIC;
  signal S_AXI_HP0_1_AWADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal S_AXI_HP0_1_AWBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal S_AXI_HP0_1_AWCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal S_AXI_HP0_1_AWID : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal S_AXI_HP0_1_AWLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal S_AXI_HP0_1_AWLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal S_AXI_HP0_1_AWPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal S_AXI_HP0_1_AWQOS : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal S_AXI_HP0_1_AWREADY : STD_LOGIC;
  signal S_AXI_HP0_1_AWSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal S_AXI_HP0_1_AWVALID : STD_LOGIC;
  signal S_AXI_HP0_1_BID : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal S_AXI_HP0_1_BREADY : STD_LOGIC;
  signal S_AXI_HP0_1_BRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal S_AXI_HP0_1_BVALID : STD_LOGIC;
  signal S_AXI_HP0_1_RDATA : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal S_AXI_HP0_1_RID : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal S_AXI_HP0_1_RLAST : STD_LOGIC;
  signal S_AXI_HP0_1_RREADY : STD_LOGIC;
  signal S_AXI_HP0_1_RRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal S_AXI_HP0_1_RVALID : STD_LOGIC;
  signal S_AXI_HP0_1_WDATA : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal S_AXI_HP0_1_WID : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal S_AXI_HP0_1_WLAST : STD_LOGIC;
  signal S_AXI_HP0_1_WREADY : STD_LOGIC;
  signal S_AXI_HP0_1_WSTRB : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal S_AXI_HP0_1_WVALID : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_ARADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axi_interconnect_0_M00_AXI_ARPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal axi_interconnect_0_M00_AXI_ARREADY : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_ARVALID : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_AWADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axi_interconnect_0_M00_AXI_AWPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal axi_interconnect_0_M00_AXI_AWREADY : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_AWVALID : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_BREADY : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_BRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axi_interconnect_0_M00_AXI_BVALID : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_RDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axi_interconnect_0_M00_AXI_RREADY : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_RRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal axi_interconnect_0_M00_AXI_RVALID : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_WDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal axi_interconnect_0_M00_AXI_WREADY : STD_LOGIC;
  signal axi_interconnect_0_M00_AXI_WSTRB : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal axi_interconnect_0_M00_AXI_WVALID : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_ARADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_ARBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_ARCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_ARID : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_ARLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_ARLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_ARPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_ARREADY : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_ARSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_ARVALID : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_AWADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_AWBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_AWCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_AWID : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_AWLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_AWLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_AWPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_AWREADY : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_AWSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_AWVALID : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_BID : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_BREADY : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_BRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_BVALID : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_RDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_RID : STD_LOGIC_VECTOR ( 5 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_RLAST : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_RREADY : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_RRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_RVALID : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_WDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_WID : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_WLAST : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_WREADY : STD_LOGIC;
  signal cdn_axi_bfm_0_M_AXI3_WSTRB : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal cdn_axi_bfm_0_M_AXI3_WVALID : STD_LOGIC;
  signal processing_system7_bfm_0_FCLK_CLK0 : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_ARADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_ARBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_ARCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_ARID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_ARLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_ARLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_ARPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_ARQOS : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_ARREADY : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_ARSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_ARVALID : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_AWADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_AWBURST : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_AWCACHE : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_AWID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_AWLEN : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_AWLOCK : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_AWPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_AWQOS : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_AWREADY : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_AWSIZE : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_AWVALID : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_BID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_BREADY : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_BRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_BVALID : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_RDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_RID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_RLAST : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_RREADY : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_RRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_RVALID : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_WDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_WID : STD_LOGIC_VECTOR ( 11 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_WLAST : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_WREADY : STD_LOGIC;
  signal processing_system7_bfm_0_M_AXI_GP0_WSTRB : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal processing_system7_bfm_0_M_AXI_GP0_WVALID : STD_LOGIC;
  signal NLW_ps_FCLK_CLK1_UNCONNECTED : STD_LOGIC;
  signal NLW_ps_FCLK_CLK2_UNCONNECTED : STD_LOGIC;
  signal NLW_ps_FCLK_CLK3_UNCONNECTED : STD_LOGIC;
  signal NLW_ps_FCLK_RESET0_N_UNCONNECTED : STD_LOGIC;
  signal NLW_ps_FCLK_RESET1_N_UNCONNECTED : STD_LOGIC;
  signal NLW_ps_FCLK_RESET2_N_UNCONNECTED : STD_LOGIC;
  signal NLW_ps_FCLK_RESET3_N_UNCONNECTED : STD_LOGIC;
begin
  FCLK_CLK0 <= processing_system7_bfm_0_FCLK_CLK0;
  FCLK_RESET0_N_1 <= FCLK_RESET0_N;
  IRQ_F2P_1(3 downto 0) <= IRQ_F2P(3 downto 0);
  M00_AXI_araddr(31 downto 0) <= axi_interconnect_0_M00_AXI_ARADDR(31 downto 0);
  M00_AXI_arprot(2 downto 0) <= axi_interconnect_0_M00_AXI_ARPROT(2 downto 0);
  M00_AXI_arvalid <= axi_interconnect_0_M00_AXI_ARVALID;
  M00_AXI_awaddr(31 downto 0) <= axi_interconnect_0_M00_AXI_AWADDR(31 downto 0);
  M00_AXI_awprot(2 downto 0) <= axi_interconnect_0_M00_AXI_AWPROT(2 downto 0);
  M00_AXI_awvalid <= axi_interconnect_0_M00_AXI_AWVALID;
  M00_AXI_bready <= axi_interconnect_0_M00_AXI_BREADY;
  M00_AXI_rready <= axi_interconnect_0_M00_AXI_RREADY;
  M00_AXI_wdata(31 downto 0) <= axi_interconnect_0_M00_AXI_WDATA(31 downto 0);
  M00_AXI_wstrb(3 downto 0) <= axi_interconnect_0_M00_AXI_WSTRB(3 downto 0);
  M00_AXI_wvalid <= axi_interconnect_0_M00_AXI_WVALID;
  PS_CLK_1 <= PS_CLK;
  PS_PORB_1 <= PS_PORB;
  PS_SRSTB_1 <= PS_SRSTB;
  S_AXI_HP0_1_ARADDR(31 downto 0) <= S_AXI_HP0_araddr(31 downto 0);
  S_AXI_HP0_1_ARBURST(1 downto 0) <= S_AXI_HP0_arburst(1 downto 0);
  S_AXI_HP0_1_ARCACHE(3 downto 0) <= S_AXI_HP0_arcache(3 downto 0);
  S_AXI_HP0_1_ARID(5 downto 0) <= S_AXI_HP0_arid(5 downto 0);
  S_AXI_HP0_1_ARLEN(3 downto 0) <= S_AXI_HP0_arlen(3 downto 0);
  S_AXI_HP0_1_ARLOCK(1 downto 0) <= S_AXI_HP0_arlock(1 downto 0);
  S_AXI_HP0_1_ARPROT(2 downto 0) <= S_AXI_HP0_arprot(2 downto 0);
  S_AXI_HP0_1_ARQOS(3 downto 0) <= S_AXI_HP0_arqos(3 downto 0);
  S_AXI_HP0_1_ARSIZE(2 downto 0) <= S_AXI_HP0_arsize(2 downto 0);
  S_AXI_HP0_1_ARVALID <= S_AXI_HP0_arvalid;
  S_AXI_HP0_1_AWADDR(31 downto 0) <= S_AXI_HP0_awaddr(31 downto 0);
  S_AXI_HP0_1_AWBURST(1 downto 0) <= S_AXI_HP0_awburst(1 downto 0);
  S_AXI_HP0_1_AWCACHE(3 downto 0) <= S_AXI_HP0_awcache(3 downto 0);
  S_AXI_HP0_1_AWID(5 downto 0) <= S_AXI_HP0_awid(5 downto 0);
  S_AXI_HP0_1_AWLEN(3 downto 0) <= S_AXI_HP0_awlen(3 downto 0);
  S_AXI_HP0_1_AWLOCK(1 downto 0) <= S_AXI_HP0_awlock(1 downto 0);
  S_AXI_HP0_1_AWPROT(2 downto 0) <= S_AXI_HP0_awprot(2 downto 0);
  S_AXI_HP0_1_AWQOS(3 downto 0) <= S_AXI_HP0_awqos(3 downto 0);
  S_AXI_HP0_1_AWSIZE(2 downto 0) <= S_AXI_HP0_awsize(2 downto 0);
  S_AXI_HP0_1_AWVALID <= S_AXI_HP0_awvalid;
  S_AXI_HP0_1_BREADY <= S_AXI_HP0_bready;
  S_AXI_HP0_1_RREADY <= S_AXI_HP0_rready;
  S_AXI_HP0_1_WDATA(63 downto 0) <= S_AXI_HP0_wdata(63 downto 0);
  S_AXI_HP0_1_WID(5 downto 0) <= S_AXI_HP0_wid(5 downto 0);
  S_AXI_HP0_1_WLAST <= S_AXI_HP0_wlast;
  S_AXI_HP0_1_WSTRB(7 downto 0) <= S_AXI_HP0_wstrb(7 downto 0);
  S_AXI_HP0_1_WVALID <= S_AXI_HP0_wvalid;
  S_AXI_HP0_arready <= S_AXI_HP0_1_ARREADY;
  S_AXI_HP0_awready <= S_AXI_HP0_1_AWREADY;
  S_AXI_HP0_bid(5 downto 0) <= S_AXI_HP0_1_BID(5 downto 0);
  S_AXI_HP0_bresp(1 downto 0) <= S_AXI_HP0_1_BRESP(1 downto 0);
  S_AXI_HP0_bvalid <= S_AXI_HP0_1_BVALID;
  S_AXI_HP0_rdata(63 downto 0) <= S_AXI_HP0_1_RDATA(63 downto 0);
  S_AXI_HP0_rid(5 downto 0) <= S_AXI_HP0_1_RID(5 downto 0);
  S_AXI_HP0_rlast <= S_AXI_HP0_1_RLAST;
  S_AXI_HP0_rresp(1 downto 0) <= S_AXI_HP0_1_RRESP(1 downto 0);
  S_AXI_HP0_rvalid <= S_AXI_HP0_1_RVALID;
  S_AXI_HP0_wready <= S_AXI_HP0_1_WREADY;
  axi_interconnect_0_M00_AXI_ARREADY <= M00_AXI_arready;
  axi_interconnect_0_M00_AXI_AWREADY <= M00_AXI_awready;
  axi_interconnect_0_M00_AXI_BRESP(1 downto 0) <= M00_AXI_bresp(1 downto 0);
  axi_interconnect_0_M00_AXI_BVALID <= M00_AXI_bvalid;
  axi_interconnect_0_M00_AXI_RDATA(31 downto 0) <= M00_AXI_rdata(31 downto 0);
  axi_interconnect_0_M00_AXI_RRESP(1 downto 0) <= M00_AXI_rresp(1 downto 0);
  axi_interconnect_0_M00_AXI_RVALID <= M00_AXI_rvalid;
  axi_interconnect_0_M00_AXI_WREADY <= M00_AXI_wready;
GND: unisim.vcomponents.GND
     port map (
      G => GND_1
    );
axi: entity work.zynq_ps_axi_0
     port map (
      ACLK => processing_system7_bfm_0_FCLK_CLK0,
      ARESETN => FCLK_RESET0_N_1,
      M00_ACLK => processing_system7_bfm_0_FCLK_CLK0,
      M00_ARESETN => FCLK_RESET0_N_1,
      M00_AXI_araddr(31 downto 0) => axi_interconnect_0_M00_AXI_ARADDR(31 downto 0),
      M00_AXI_arprot(2 downto 0) => axi_interconnect_0_M00_AXI_ARPROT(2 downto 0),
      M00_AXI_arready => axi_interconnect_0_M00_AXI_ARREADY,
      M00_AXI_arvalid => axi_interconnect_0_M00_AXI_ARVALID,
      M00_AXI_awaddr(31 downto 0) => axi_interconnect_0_M00_AXI_AWADDR(31 downto 0),
      M00_AXI_awprot(2 downto 0) => axi_interconnect_0_M00_AXI_AWPROT(2 downto 0),
      M00_AXI_awready => axi_interconnect_0_M00_AXI_AWREADY,
      M00_AXI_awvalid => axi_interconnect_0_M00_AXI_AWVALID,
      M00_AXI_bready => axi_interconnect_0_M00_AXI_BREADY,
      M00_AXI_bresp(1 downto 0) => axi_interconnect_0_M00_AXI_BRESP(1 downto 0),
      M00_AXI_bvalid => axi_interconnect_0_M00_AXI_BVALID,
      M00_AXI_rdata(31 downto 0) => axi_interconnect_0_M00_AXI_RDATA(31 downto 0),
      M00_AXI_rready => axi_interconnect_0_M00_AXI_RREADY,
      M00_AXI_rresp(1 downto 0) => axi_interconnect_0_M00_AXI_RRESP(1 downto 0),
      M00_AXI_rvalid => axi_interconnect_0_M00_AXI_RVALID,
      M00_AXI_wdata(31 downto 0) => axi_interconnect_0_M00_AXI_WDATA(31 downto 0),
      M00_AXI_wready => axi_interconnect_0_M00_AXI_WREADY,
      M00_AXI_wstrb(3 downto 0) => axi_interconnect_0_M00_AXI_WSTRB(3 downto 0),
      M00_AXI_wvalid => axi_interconnect_0_M00_AXI_WVALID,
      S00_ACLK => processing_system7_bfm_0_FCLK_CLK0,
      S00_ARESETN => FCLK_RESET0_N_1,
      S00_AXI_araddr(31 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARADDR(31 downto 0),
      S00_AXI_arburst(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARBURST(1 downto 0),
      S00_AXI_arcache(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARCACHE(3 downto 0),
      S00_AXI_arid(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARID(11 downto 0),
      S00_AXI_arlen(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARLEN(3 downto 0),
      S00_AXI_arlock(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARLOCK(1 downto 0),
      S00_AXI_arprot(2 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARPROT(2 downto 0),
      S00_AXI_arqos(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARQOS(3 downto 0),
      S00_AXI_arready => processing_system7_bfm_0_M_AXI_GP0_ARREADY,
      S00_AXI_arsize(2 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARSIZE(2 downto 0),
      S00_AXI_arvalid => processing_system7_bfm_0_M_AXI_GP0_ARVALID,
      S00_AXI_awaddr(31 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWADDR(31 downto 0),
      S00_AXI_awburst(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWBURST(1 downto 0),
      S00_AXI_awcache(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWCACHE(3 downto 0),
      S00_AXI_awid(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWID(11 downto 0),
      S00_AXI_awlen(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWLEN(3 downto 0),
      S00_AXI_awlock(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWLOCK(1 downto 0),
      S00_AXI_awprot(2 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWPROT(2 downto 0),
      S00_AXI_awqos(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWQOS(3 downto 0),
      S00_AXI_awready => processing_system7_bfm_0_M_AXI_GP0_AWREADY,
      S00_AXI_awsize(2 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWSIZE(2 downto 0),
      S00_AXI_awvalid => processing_system7_bfm_0_M_AXI_GP0_AWVALID,
      S00_AXI_bid(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_BID(11 downto 0),
      S00_AXI_bready => processing_system7_bfm_0_M_AXI_GP0_BREADY,
      S00_AXI_bresp(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_BRESP(1 downto 0),
      S00_AXI_bvalid => processing_system7_bfm_0_M_AXI_GP0_BVALID,
      S00_AXI_rdata(31 downto 0) => processing_system7_bfm_0_M_AXI_GP0_RDATA(31 downto 0),
      S00_AXI_rid(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_RID(11 downto 0),
      S00_AXI_rlast => processing_system7_bfm_0_M_AXI_GP0_RLAST,
      S00_AXI_rready => processing_system7_bfm_0_M_AXI_GP0_RREADY,
      S00_AXI_rresp(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_RRESP(1 downto 0),
      S00_AXI_rvalid => processing_system7_bfm_0_M_AXI_GP0_RVALID,
      S00_AXI_wdata(31 downto 0) => processing_system7_bfm_0_M_AXI_GP0_WDATA(31 downto 0),
      S00_AXI_wid(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_WID(11 downto 0),
      S00_AXI_wlast => processing_system7_bfm_0_M_AXI_GP0_WLAST,
      S00_AXI_wready => processing_system7_bfm_0_M_AXI_GP0_WREADY,
      S00_AXI_wstrb(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_WSTRB(3 downto 0),
      S00_AXI_wvalid => processing_system7_bfm_0_M_AXI_GP0_WVALID
    );
hp1: component zynq_ps_hp1_0
     port map (
      m_axi_aclk => processing_system7_bfm_0_FCLK_CLK0,
      m_axi_araddr(31 downto 0) => cdn_axi_bfm_0_M_AXI3_ARADDR(31 downto 0),
      m_axi_arburst(1 downto 0) => cdn_axi_bfm_0_M_AXI3_ARBURST(1 downto 0),
      m_axi_arcache(3 downto 0) => cdn_axi_bfm_0_M_AXI3_ARCACHE(3 downto 0),
      m_axi_aresetn => FCLK_RESET0_N_1,
      m_axi_arid(3 downto 0) => cdn_axi_bfm_0_M_AXI3_ARID(3 downto 0),
      m_axi_arlen(3 downto 0) => cdn_axi_bfm_0_M_AXI3_ARLEN(3 downto 0),
      m_axi_arlock(1 downto 0) => cdn_axi_bfm_0_M_AXI3_ARLOCK(1 downto 0),
      m_axi_arprot(2 downto 0) => cdn_axi_bfm_0_M_AXI3_ARPROT(2 downto 0),
      m_axi_arready => cdn_axi_bfm_0_M_AXI3_ARREADY,
      m_axi_arsize(2 downto 0) => cdn_axi_bfm_0_M_AXI3_ARSIZE(2 downto 0),
      m_axi_arvalid => cdn_axi_bfm_0_M_AXI3_ARVALID,
      m_axi_awaddr(31 downto 0) => cdn_axi_bfm_0_M_AXI3_AWADDR(31 downto 0),
      m_axi_awburst(1 downto 0) => cdn_axi_bfm_0_M_AXI3_AWBURST(1 downto 0),
      m_axi_awcache(3 downto 0) => cdn_axi_bfm_0_M_AXI3_AWCACHE(3 downto 0),
      m_axi_awid(3 downto 0) => cdn_axi_bfm_0_M_AXI3_AWID(3 downto 0),
      m_axi_awlen(3 downto 0) => cdn_axi_bfm_0_M_AXI3_AWLEN(3 downto 0),
      m_axi_awlock(1 downto 0) => cdn_axi_bfm_0_M_AXI3_AWLOCK(1 downto 0),
      m_axi_awprot(2 downto 0) => cdn_axi_bfm_0_M_AXI3_AWPROT(2 downto 0),
      m_axi_awready => cdn_axi_bfm_0_M_AXI3_AWREADY,
      m_axi_awsize(2 downto 0) => cdn_axi_bfm_0_M_AXI3_AWSIZE(2 downto 0),
      m_axi_awvalid => cdn_axi_bfm_0_M_AXI3_AWVALID,
      m_axi_bid(3 downto 0) => cdn_axi_bfm_0_M_AXI3_BID(3 downto 0),
      m_axi_bready => cdn_axi_bfm_0_M_AXI3_BREADY,
      m_axi_bresp(1 downto 0) => cdn_axi_bfm_0_M_AXI3_BRESP(1 downto 0),
      m_axi_bvalid => cdn_axi_bfm_0_M_AXI3_BVALID,
      m_axi_rdata(31 downto 0) => cdn_axi_bfm_0_M_AXI3_RDATA(31 downto 0),
      m_axi_rid(3 downto 0) => cdn_axi_bfm_0_M_AXI3_RID(3 downto 0),
      m_axi_rlast => cdn_axi_bfm_0_M_AXI3_RLAST,
      m_axi_rready => cdn_axi_bfm_0_M_AXI3_RREADY,
      m_axi_rresp(1 downto 0) => cdn_axi_bfm_0_M_AXI3_RRESP(1 downto 0),
      m_axi_rvalid => cdn_axi_bfm_0_M_AXI3_RVALID,
      m_axi_wdata(31 downto 0) => cdn_axi_bfm_0_M_AXI3_WDATA(31 downto 0),
      m_axi_wid(3 downto 0) => cdn_axi_bfm_0_M_AXI3_WID(3 downto 0),
      m_axi_wlast => cdn_axi_bfm_0_M_AXI3_WLAST,
      m_axi_wready => cdn_axi_bfm_0_M_AXI3_WREADY,
      m_axi_wstrb(3 downto 0) => cdn_axi_bfm_0_M_AXI3_WSTRB(3 downto 0),
      m_axi_wvalid => cdn_axi_bfm_0_M_AXI3_WVALID
    );
ps: component zynq_ps_ps_0
     port map (
      FCLK_CLK0 => processing_system7_bfm_0_FCLK_CLK0,
      FCLK_CLK1 => NLW_ps_FCLK_CLK1_UNCONNECTED,
      FCLK_CLK2 => NLW_ps_FCLK_CLK2_UNCONNECTED,
      FCLK_CLK3 => NLW_ps_FCLK_CLK3_UNCONNECTED,
      FCLK_RESET0_N => NLW_ps_FCLK_RESET0_N_UNCONNECTED,
      FCLK_RESET1_N => NLW_ps_FCLK_RESET1_N_UNCONNECTED,
      FCLK_RESET2_N => NLW_ps_FCLK_RESET2_N_UNCONNECTED,
      FCLK_RESET3_N => NLW_ps_FCLK_RESET3_N_UNCONNECTED,
      IRQ_F2P(3 downto 0) => IRQ_F2P_1(3 downto 0),
      M_AXI_GP0_ACLK => processing_system7_bfm_0_FCLK_CLK0,
      M_AXI_GP0_ARADDR(31 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARADDR(31 downto 0),
      M_AXI_GP0_ARBURST(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARBURST(1 downto 0),
      M_AXI_GP0_ARCACHE(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARCACHE(3 downto 0),
      M_AXI_GP0_ARID(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARID(11 downto 0),
      M_AXI_GP0_ARLEN(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARLEN(3 downto 0),
      M_AXI_GP0_ARLOCK(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARLOCK(1 downto 0),
      M_AXI_GP0_ARPROT(2 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARPROT(2 downto 0),
      M_AXI_GP0_ARQOS(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARQOS(3 downto 0),
      M_AXI_GP0_ARREADY => processing_system7_bfm_0_M_AXI_GP0_ARREADY,
      M_AXI_GP0_ARSIZE(2 downto 0) => processing_system7_bfm_0_M_AXI_GP0_ARSIZE(2 downto 0),
      M_AXI_GP0_ARVALID => processing_system7_bfm_0_M_AXI_GP0_ARVALID,
      M_AXI_GP0_AWADDR(31 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWADDR(31 downto 0),
      M_AXI_GP0_AWBURST(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWBURST(1 downto 0),
      M_AXI_GP0_AWCACHE(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWCACHE(3 downto 0),
      M_AXI_GP0_AWID(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWID(11 downto 0),
      M_AXI_GP0_AWLEN(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWLEN(3 downto 0),
      M_AXI_GP0_AWLOCK(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWLOCK(1 downto 0),
      M_AXI_GP0_AWPROT(2 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWPROT(2 downto 0),
      M_AXI_GP0_AWQOS(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWQOS(3 downto 0),
      M_AXI_GP0_AWREADY => processing_system7_bfm_0_M_AXI_GP0_AWREADY,
      M_AXI_GP0_AWSIZE(2 downto 0) => processing_system7_bfm_0_M_AXI_GP0_AWSIZE(2 downto 0),
      M_AXI_GP0_AWVALID => processing_system7_bfm_0_M_AXI_GP0_AWVALID,
      M_AXI_GP0_BID(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_BID(11 downto 0),
      M_AXI_GP0_BREADY => processing_system7_bfm_0_M_AXI_GP0_BREADY,
      M_AXI_GP0_BRESP(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_BRESP(1 downto 0),
      M_AXI_GP0_BVALID => processing_system7_bfm_0_M_AXI_GP0_BVALID,
      M_AXI_GP0_RDATA(31 downto 0) => processing_system7_bfm_0_M_AXI_GP0_RDATA(31 downto 0),
      M_AXI_GP0_RID(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_RID(11 downto 0),
      M_AXI_GP0_RLAST => processing_system7_bfm_0_M_AXI_GP0_RLAST,
      M_AXI_GP0_RREADY => processing_system7_bfm_0_M_AXI_GP0_RREADY,
      M_AXI_GP0_RRESP(1 downto 0) => processing_system7_bfm_0_M_AXI_GP0_RRESP(1 downto 0),
      M_AXI_GP0_RVALID => processing_system7_bfm_0_M_AXI_GP0_RVALID,
      M_AXI_GP0_WDATA(31 downto 0) => processing_system7_bfm_0_M_AXI_GP0_WDATA(31 downto 0),
      M_AXI_GP0_WID(11 downto 0) => processing_system7_bfm_0_M_AXI_GP0_WID(11 downto 0),
      M_AXI_GP0_WLAST => processing_system7_bfm_0_M_AXI_GP0_WLAST,
      M_AXI_GP0_WREADY => processing_system7_bfm_0_M_AXI_GP0_WREADY,
      M_AXI_GP0_WSTRB(3 downto 0) => processing_system7_bfm_0_M_AXI_GP0_WSTRB(3 downto 0),
      M_AXI_GP0_WVALID => processing_system7_bfm_0_M_AXI_GP0_WVALID,
      PS_CLK => PS_CLK_1,
      PS_PORB => PS_PORB_1,
      PS_SRSTB => PS_SRSTB_1,
      S_AXI_HP0_ACLK => processing_system7_bfm_0_FCLK_CLK0,
      S_AXI_HP0_ARADDR(31 downto 0) => S_AXI_HP0_1_ARADDR(31 downto 0),
      S_AXI_HP0_ARBURST(1 downto 0) => S_AXI_HP0_1_ARBURST(1 downto 0),
      S_AXI_HP0_ARCACHE(3 downto 0) => S_AXI_HP0_1_ARCACHE(3 downto 0),
      S_AXI_HP0_ARID(5 downto 0) => S_AXI_HP0_1_ARID(5 downto 0),
      S_AXI_HP0_ARLEN(3 downto 0) => S_AXI_HP0_1_ARLEN(3 downto 0),
      S_AXI_HP0_ARLOCK(1 downto 0) => S_AXI_HP0_1_ARLOCK(1 downto 0),
      S_AXI_HP0_ARPROT(2 downto 0) => S_AXI_HP0_1_ARPROT(2 downto 0),
      S_AXI_HP0_ARQOS(3 downto 0) => S_AXI_HP0_1_ARQOS(3 downto 0),
      S_AXI_HP0_ARREADY => S_AXI_HP0_1_ARREADY,
      S_AXI_HP0_ARSIZE(2 downto 0) => S_AXI_HP0_1_ARSIZE(2 downto 0),
      S_AXI_HP0_ARVALID => S_AXI_HP0_1_ARVALID,
      S_AXI_HP0_AWADDR(31 downto 0) => S_AXI_HP0_1_AWADDR(31 downto 0),
      S_AXI_HP0_AWBURST(1 downto 0) => S_AXI_HP0_1_AWBURST(1 downto 0),
      S_AXI_HP0_AWCACHE(3 downto 0) => S_AXI_HP0_1_AWCACHE(3 downto 0),
      S_AXI_HP0_AWID(5 downto 0) => S_AXI_HP0_1_AWID(5 downto 0),
      S_AXI_HP0_AWLEN(3 downto 0) => S_AXI_HP0_1_AWLEN(3 downto 0),
      S_AXI_HP0_AWLOCK(1 downto 0) => S_AXI_HP0_1_AWLOCK(1 downto 0),
      S_AXI_HP0_AWPROT(2 downto 0) => S_AXI_HP0_1_AWPROT(2 downto 0),
      S_AXI_HP0_AWQOS(3 downto 0) => S_AXI_HP0_1_AWQOS(3 downto 0),
      S_AXI_HP0_AWREADY => S_AXI_HP0_1_AWREADY,
      S_AXI_HP0_AWSIZE(2 downto 0) => S_AXI_HP0_1_AWSIZE(2 downto 0),
      S_AXI_HP0_AWVALID => S_AXI_HP0_1_AWVALID,
      S_AXI_HP0_BID(5 downto 0) => S_AXI_HP0_1_BID(5 downto 0),
      S_AXI_HP0_BREADY => S_AXI_HP0_1_BREADY,
      S_AXI_HP0_BRESP(1 downto 0) => S_AXI_HP0_1_BRESP(1 downto 0),
      S_AXI_HP0_BVALID => S_AXI_HP0_1_BVALID,
      S_AXI_HP0_RDATA(63 downto 0) => S_AXI_HP0_1_RDATA(63 downto 0),
      S_AXI_HP0_RID(5 downto 0) => S_AXI_HP0_1_RID(5 downto 0),
      S_AXI_HP0_RLAST => S_AXI_HP0_1_RLAST,
      S_AXI_HP0_RREADY => S_AXI_HP0_1_RREADY,
      S_AXI_HP0_RRESP(1 downto 0) => S_AXI_HP0_1_RRESP(1 downto 0),
      S_AXI_HP0_RVALID => S_AXI_HP0_1_RVALID,
      S_AXI_HP0_WDATA(63 downto 0) => S_AXI_HP0_1_WDATA(63 downto 0),
      S_AXI_HP0_WID(5 downto 0) => S_AXI_HP0_1_WID(5 downto 0),
      S_AXI_HP0_WLAST => S_AXI_HP0_1_WLAST,
      S_AXI_HP0_WREADY => S_AXI_HP0_1_WREADY,
      S_AXI_HP0_WSTRB(7 downto 0) => S_AXI_HP0_1_WSTRB(7 downto 0),
      S_AXI_HP0_WVALID => S_AXI_HP0_1_WVALID,
      S_AXI_HP1_ACLK => processing_system7_bfm_0_FCLK_CLK0,
      S_AXI_HP1_ARADDR(31 downto 0) => cdn_axi_bfm_0_M_AXI3_ARADDR(31 downto 0),
      S_AXI_HP1_ARBURST(1 downto 0) => cdn_axi_bfm_0_M_AXI3_ARBURST(1 downto 0),
      S_AXI_HP1_ARCACHE(3 downto 0) => cdn_axi_bfm_0_M_AXI3_ARCACHE(3 downto 0),
      S_AXI_HP1_ARID(5) => GND_1,
      S_AXI_HP1_ARID(4) => GND_1,
      S_AXI_HP1_ARID(3 downto 0) => cdn_axi_bfm_0_M_AXI3_ARID(3 downto 0),
      S_AXI_HP1_ARLEN(3 downto 0) => cdn_axi_bfm_0_M_AXI3_ARLEN(3 downto 0),
      S_AXI_HP1_ARLOCK(1 downto 0) => cdn_axi_bfm_0_M_AXI3_ARLOCK(1 downto 0),
      S_AXI_HP1_ARPROT(2 downto 0) => cdn_axi_bfm_0_M_AXI3_ARPROT(2 downto 0),
      S_AXI_HP1_ARQOS(3) => GND_1,
      S_AXI_HP1_ARQOS(2) => GND_1,
      S_AXI_HP1_ARQOS(1) => GND_1,
      S_AXI_HP1_ARQOS(0) => GND_1,
      S_AXI_HP1_ARREADY => cdn_axi_bfm_0_M_AXI3_ARREADY,
      S_AXI_HP1_ARSIZE(2 downto 0) => cdn_axi_bfm_0_M_AXI3_ARSIZE(2 downto 0),
      S_AXI_HP1_ARVALID => cdn_axi_bfm_0_M_AXI3_ARVALID,
      S_AXI_HP1_AWADDR(31 downto 0) => cdn_axi_bfm_0_M_AXI3_AWADDR(31 downto 0),
      S_AXI_HP1_AWBURST(1 downto 0) => cdn_axi_bfm_0_M_AXI3_AWBURST(1 downto 0),
      S_AXI_HP1_AWCACHE(3 downto 0) => cdn_axi_bfm_0_M_AXI3_AWCACHE(3 downto 0),
      S_AXI_HP1_AWID(5) => GND_1,
      S_AXI_HP1_AWID(4) => GND_1,
      S_AXI_HP1_AWID(3 downto 0) => cdn_axi_bfm_0_M_AXI3_AWID(3 downto 0),
      S_AXI_HP1_AWLEN(3 downto 0) => cdn_axi_bfm_0_M_AXI3_AWLEN(3 downto 0),
      S_AXI_HP1_AWLOCK(1 downto 0) => cdn_axi_bfm_0_M_AXI3_AWLOCK(1 downto 0),
      S_AXI_HP1_AWPROT(2 downto 0) => cdn_axi_bfm_0_M_AXI3_AWPROT(2 downto 0),
      S_AXI_HP1_AWQOS(3) => GND_1,
      S_AXI_HP1_AWQOS(2) => GND_1,
      S_AXI_HP1_AWQOS(1) => GND_1,
      S_AXI_HP1_AWQOS(0) => GND_1,
      S_AXI_HP1_AWREADY => cdn_axi_bfm_0_M_AXI3_AWREADY,
      S_AXI_HP1_AWSIZE(2 downto 0) => cdn_axi_bfm_0_M_AXI3_AWSIZE(2 downto 0),
      S_AXI_HP1_AWVALID => cdn_axi_bfm_0_M_AXI3_AWVALID,
      S_AXI_HP1_BID(5 downto 0) => cdn_axi_bfm_0_M_AXI3_BID(5 downto 0),
      S_AXI_HP1_BREADY => cdn_axi_bfm_0_M_AXI3_BREADY,
      S_AXI_HP1_BRESP(1 downto 0) => cdn_axi_bfm_0_M_AXI3_BRESP(1 downto 0),
      S_AXI_HP1_BVALID => cdn_axi_bfm_0_M_AXI3_BVALID,
      S_AXI_HP1_RDATA(31 downto 0) => cdn_axi_bfm_0_M_AXI3_RDATA(31 downto 0),
      S_AXI_HP1_RID(5 downto 0) => cdn_axi_bfm_0_M_AXI3_RID(5 downto 0),
      S_AXI_HP1_RLAST => cdn_axi_bfm_0_M_AXI3_RLAST,
      S_AXI_HP1_RREADY => cdn_axi_bfm_0_M_AXI3_RREADY,
      S_AXI_HP1_RRESP(1 downto 0) => cdn_axi_bfm_0_M_AXI3_RRESP(1 downto 0),
      S_AXI_HP1_RVALID => cdn_axi_bfm_0_M_AXI3_RVALID,
      S_AXI_HP1_WDATA(31 downto 0) => cdn_axi_bfm_0_M_AXI3_WDATA(31 downto 0),
      S_AXI_HP1_WID(5) => GND_1,
      S_AXI_HP1_WID(4) => GND_1,
      S_AXI_HP1_WID(3 downto 0) => cdn_axi_bfm_0_M_AXI3_WID(3 downto 0),
      S_AXI_HP1_WLAST => cdn_axi_bfm_0_M_AXI3_WLAST,
      S_AXI_HP1_WREADY => cdn_axi_bfm_0_M_AXI3_WREADY,
      S_AXI_HP1_WSTRB(3 downto 0) => cdn_axi_bfm_0_M_AXI3_WSTRB(3 downto 0),
      S_AXI_HP1_WVALID => cdn_axi_bfm_0_M_AXI3_WVALID
    );
end STRUCTURE;
