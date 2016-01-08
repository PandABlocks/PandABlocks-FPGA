library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity panda_ps is
  port (
    DDR_addr            : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba              : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n           : inout STD_LOGIC;
    DDR_ck_n            : inout STD_LOGIC;
    DDR_ck_p            : inout STD_LOGIC;
    DDR_cke             : inout STD_LOGIC;
    DDR_cs_n            : inout STD_LOGIC;
    DDR_dm              : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq              : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n           : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p           : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt             : inout STD_LOGIC;
    DDR_ras_n           : inout STD_LOGIC;
    DDR_reset_n         : inout STD_LOGIC;
    DDR_we_n            : inout STD_LOGIC;
    FCLK_CLK0           : out STD_LOGIC;
    FCLK_LEDS           : out STD_LOGIC_VECTOR ( 31 downto 0 );
    FCLK_RESET0_N       : out STD_LOGIC_VECTOR ( 0 to 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    IRQ_F2P : in STD_LOGIC_VECTOR ( 0 to 0 );
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
    S_AXI_HP0_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_rid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_rlast : out STD_LOGIC;
    S_AXI_HP0_rready : in STD_LOGIC;
    S_AXI_HP0_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_rvalid : out STD_LOGIC;
    S_AXI_HP0_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_wid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_wlast : in STD_LOGIC;
    S_AXI_HP0_wready : out STD_LOGIC;
    S_AXI_HP0_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_wvalid : in STD_LOGIC
  );
end panda_ps;

architecture rtl of panda_ps is

signal irq_f2p_signal   : std_logic_vector(3 downto 0);
signal FCLK             : std_logic;
signal tb_ARESETn       : std_logic := '0';
signal tb_RESETn        : std_logic := '0';

begin
FCLK_CLK0 <= FCLK;
FCLK_LEDS <= (others => '0');

irq_f2p_signal(0) <= IRQ_F2P(0);

FCLK_RESET0_N(0) <= tb_ARESETn;

process(FCLK)
begin
    if rising_edge(FCLK) then
        tb_RESETn <= tb_ARESETn;
    end if;
end process;

ps : entity work.zynq_ps
port map (
    FCLK_CLK0           => FCLK,
    FCLK_RESET0_N       => open,
    IRQ_F2P             => irq_f2p_signal,
    M00_AXI_araddr      => M00_AXI_araddr,
    M00_AXI_arprot      => M00_AXI_arprot,
    M00_AXI_arready     => M00_AXI_arready,
    M00_AXI_arvalid     => M00_AXI_arvalid,
    M00_AXI_awaddr      => M00_AXI_awaddr,
    M00_AXI_awprot      => M00_AXI_awprot,
    M00_AXI_awready     => M00_AXI_awready,
    M00_AXI_awvalid     => M00_AXI_awvalid,
    M00_AXI_bready      => M00_AXI_bready,
    M00_AXI_bresp       => M00_AXI_bresp,
    M00_AXI_bvalid      => M00_AXI_bvalid,
    M00_AXI_rdata       => M00_AXI_rdata,
    M00_AXI_rready      => M00_AXI_rready,
    M00_AXI_rresp       => M00_AXI_rresp,
    M00_AXI_rvalid      => M00_AXI_rvalid,
    M00_AXI_wdata       => M00_AXI_wdata,
    M00_AXI_wready      => M00_AXI_wready,
    M00_AXI_wstrb       => M00_AXI_wstrb,
    M00_AXI_wvalid      => M00_AXI_wvalid,

    S_AXI_HP0_araddr    => S_AXI_HP0_araddr , 
    S_AXI_HP0_arburst   => S_AXI_HP0_arburst, 
    S_AXI_HP0_arcache   => S_AXI_HP0_arcache, 
    S_AXI_HP0_arid      => S_AXI_HP0_arid   , 
    S_AXI_HP0_arlen     => S_AXI_HP0_arlen  , 
    S_AXI_HP0_arlock    => S_AXI_HP0_arlock , 
    S_AXI_HP0_arprot    => S_AXI_HP0_arprot , 
    S_AXI_HP0_arqos     => S_AXI_HP0_arqos  , 
    S_AXI_HP0_arready   => S_AXI_HP0_arready, 
    S_AXI_HP0_arsize    => S_AXI_HP0_arsize , 
    S_AXI_HP0_arvalid   => S_AXI_HP0_arvalid, 
    S_AXI_HP0_awaddr    => S_AXI_HP0_awaddr , 
    S_AXI_HP0_awburst   => S_AXI_HP0_awburst, 
    S_AXI_HP0_awcache   => S_AXI_HP0_awcache, 
    S_AXI_HP0_awid      => S_AXI_HP0_awid   , 
    S_AXI_HP0_awlen     => S_AXI_HP0_awlen  , 
    S_AXI_HP0_awlock    => S_AXI_HP0_awlock , 
    S_AXI_HP0_awprot    => S_AXI_HP0_awprot , 
    S_AXI_HP0_awqos     => S_AXI_HP0_awqos  , 
    S_AXI_HP0_awready   => S_AXI_HP0_awready, 
    S_AXI_HP0_awsize    => S_AXI_HP0_awsize , 
    S_AXI_HP0_awvalid   => S_AXI_HP0_awvalid, 
    S_AXI_HP0_bid       => S_AXI_HP0_bid    , 
    S_AXI_HP0_bready    => S_AXI_HP0_bready , 
    S_AXI_HP0_bresp     => S_AXI_HP0_bresp  , 
    S_AXI_HP0_bvalid    => S_AXI_HP0_bvalid , 
    S_AXI_HP0_rdata     => S_AXI_HP0_rdata  , 
    S_AXI_HP0_rid       => S_AXI_HP0_rid    , 
    S_AXI_HP0_rlast     => S_AXI_HP0_rlast  , 
    S_AXI_HP0_rready    => S_AXI_HP0_rready , 
    S_AXI_HP0_rresp     => S_AXI_HP0_rresp  , 
    S_AXI_HP0_rvalid    => S_AXI_HP0_rvalid , 
    S_AXI_HP0_wdata     => S_AXI_HP0_wdata  , 
    S_AXI_HP0_wid       => S_AXI_HP0_wid    , 
    S_AXI_HP0_wlast     => S_AXI_HP0_wlast  , 
    S_AXI_HP0_wready    => S_AXI_HP0_wready , 
    S_AXI_HP0_wstrb     => S_AXI_HP0_wstrb  , 
    S_AXI_HP0_wvalid    => S_AXI_HP0_wvalid , 

    PS_CLK              => FCLK,
    PS_PORB             => tb_RESETn,
    PS_SRSTB            => tb_RESETn
);

tb_ARESETn <= '1' after 1 us;

end rtl;
