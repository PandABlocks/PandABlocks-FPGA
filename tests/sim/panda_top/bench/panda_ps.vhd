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
    S_AXI_HP0_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP0_wlast : in STD_LOGIC;
    S_AXI_HP0_wready : out STD_LOGIC;
    S_AXI_HP0_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_wvalid : in STD_LOGIC;

    S_AXI_HP1_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP1_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_arid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_arlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP1_arlock : in STD_LOGIC_VECTOR ( 0 to 0 );
    S_AXI_HP1_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 ); 
    S_AXI_HP1_arready : out STD_LOGIC;
    S_AXI_HP1_arregion : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP1_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP1_arvalid : in STD_LOGIC;
    S_AXI_HP1_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_HP1_rid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP1_rlast : out STD_LOGIC;
    S_AXI_HP1_rready : in STD_LOGIC;
    S_AXI_HP1_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 ); 
    S_AXI_HP1_rvalid : out STD_LOGIC
  );
end panda_ps;

architecture rtl of panda_ps is

begin

end rtl;
