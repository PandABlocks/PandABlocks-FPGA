library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity panda_top is
port (
    DDR_addr            : inout std_logic_vector ( 14 downto 0 );
    DDR_ba              : inout std_logic_vector ( 2 downto 0 );
    DDR_cas_n           : inout std_logic;
    DDR_ck_n            : inout std_logic;
    DDR_ck_p            : inout std_logic;
    DDR_cke             : inout std_logic;
    DDR_cs_n            : inout std_logic;
    DDR_dm              : inout std_logic_vector ( 3 downto 0 );
    DDR_dq              : inout std_logic_vector ( 31 downto 0 );
    DDR_dqs_n           : inout std_logic_vector ( 3 downto 0 );
    DDR_dqs_p           : inout std_logic_vector ( 3 downto 0 );
    DDR_odt             : inout std_logic;
    DDR_ras_n           : inout std_logic;
    DDR_reset_n         : inout std_logic;
    DDR_we_n            : inout std_logic;
    FIXED_IO_ddr_vrn    : inout std_logic;
    FIXED_IO_ddr_vrp    : inout std_logic;
    FIXED_IO_mio        : inout std_logic_vector ( 53 downto 0 );
    FIXED_IO_ps_clk     : inout std_logic;
    FIXED_IO_ps_porb    : inout std_logic;
    FIXED_IO_ps_srstb   : inout std_logic;

    leds                : out   std_logic_vector(1 downto 0)
);
end panda_top;

architecture rtl of panda_top is

component panda_ps is
port (
  DDR_cas_n         : inout std_logic;
  DDR_cke           : inout std_logic;
  DDR_ck_n          : inout std_logic;
  DDR_ck_p          : inout std_logic;
  DDR_cs_n          : inout std_logic;
  DDR_reset_n       : inout std_logic;
  DDR_odt           : inout std_logic;
  DDR_ras_n         : inout std_logic;
  DDR_we_n          : inout std_logic;
  DDR_ba            : inout std_logic_vector ( 2 downto 0 );
  DDR_addr          : inout std_logic_vector ( 14 downto 0 );
  DDR_dm            : inout std_logic_vector ( 3 downto 0 );
  DDR_dq            : inout std_logic_vector ( 31 downto 0 );
  DDR_dqs_n         : inout std_logic_vector ( 3 downto 0 );
  DDR_dqs_p         : inout std_logic_vector ( 3 downto 0 );
  FIXED_IO_mio      : inout std_logic_vector ( 53 downto 0 );
  FIXED_IO_ddr_vrn  : inout std_logic;
  FIXED_IO_ddr_vrp  : inout std_logic;
  FIXED_IO_ps_srstb : inout std_logic;
  FIXED_IO_ps_clk   : inout std_logic;
  FIXED_IO_ps_porb  : inout std_logic;
  M00_AXI_awaddr    : out std_logic_vector ( 31 downto 0 );
  M00_AXI_awprot    : out std_logic_vector ( 2 downto 0 );
  M00_AXI_awvalid   : out std_logic;
  M00_AXI_awready   : in std_logic;
  M00_AXI_wdata     : out std_logic_vector ( 31 downto 0 );
  M00_AXI_wstrb     : out std_logic_vector ( 3 downto 0 );
  M00_AXI_wvalid    : out std_logic;
  M00_AXI_wready    : in std_logic;
  M00_AXI_bresp     : in std_logic_vector ( 1 downto 0 );
  M00_AXI_bvalid    : in std_logic;
  M00_AXI_bready    : out std_logic;
  M00_AXI_araddr    : out std_logic_vector ( 31 downto 0 );
  M00_AXI_arprot    : out std_logic_vector ( 2 downto 0 );
  M00_AXI_arvalid   : out std_logic;
  M00_AXI_arready   : in std_logic;
  M00_AXI_rdata     : in std_logic_vector ( 31 downto 0 );
  M00_AXI_rresp     : in std_logic_vector ( 1 downto 0 );
  M00_AXI_rvalid    : in std_logic;
  M00_AXI_rready    : out std_logic;
  FCLK_RESET0_N     : out std_logic;
  FCLK_CLK0         : out std_logic;
  FCLK_LEDS         : out std_logic_vector(31 downto 0)
);
end component panda_ps;

-- Signal declarations
signal FCLK_CLK0        : std_logic;
signal FCLK_RESET0_N    : std_logic;
signal FCLK_LEDS        : std_logic_vector(31 downto 0);
signal M00_AXI_awaddr   : std_logic_vector ( 31 downto 0 );
signal M00_AXI_awprot   : std_logic_vector ( 2 downto 0 );
signal M00_AXI_awvalid  : std_logic;
signal M00_AXI_awready  : std_logic;
signal M00_AXI_wdata    : std_logic_vector ( 31 downto 0 );
signal M00_AXI_wstrb    : std_logic_vector ( 3 downto 0 );
signal M00_AXI_wvalid   : std_logic;
signal M00_AXI_wready   : std_logic;
signal M00_AXI_bresp    : std_logic_vector ( 1 downto 0 );
signal M00_AXI_bvalid   : std_logic;
signal M00_AXI_bready   : std_logic;
signal M00_AXI_araddr   : std_logic_vector ( 31 downto 0 );
signal M00_AXI_arprot   : std_logic_vector ( 2 downto 0 );
signal M00_AXI_arvalid  : std_logic;
signal M00_AXI_arready  : std_logic;
signal M00_AXI_rdata    : std_logic_vector ( 31 downto 0 );
signal M00_AXI_rresp    : std_logic_vector ( 1 downto 0 );
signal M00_AXI_rvalid   : std_logic;
signal M00_AXI_rready   : std_logic;

signal mem_cs           : std_logic_vector(15 downto 0);
signal mem_addr         : std_logic_vector(9 downto 0);
signal mem_idat         : std_logic_vector(31 downto 0);
signal mem_odat         : std_logic_vector(31 downto 0);
signal mem_wstb         : std_logic;
signal mem_rstb         : std_logic;

signal cs0_mem_wr       : std_logic;
signal mem_read_dat_0   : std_logic_vector(31 downto 0);

begin

leds <= FCLK_LEDS(26 downto 25);

panda_ps_i: component panda_ps
port map (
    FCLK_CLK0                   => FCLK_CLK0,
    FCLK_RESET0_N               => FCLK_RESET0_N,
    FCLK_LEDS                   => FCLK_LEDS,

    DDR_addr(14 downto 0)       => DDR_addr(14 downto 0),
    DDR_ba(2 downto 0)          => DDR_ba(2 downto 0),
    DDR_cas_n                   => DDR_cas_n,
    DDR_ck_n                    => DDR_ck_n,
    DDR_ck_p                    => DDR_ck_p,
    DDR_cke                     => DDR_cke,
    DDR_cs_n                    => DDR_cs_n,
    DDR_dm(3 downto 0)          => DDR_dm(3 downto 0),
    DDR_dq(31 downto 0)         => DDR_dq(31 downto 0),
    DDR_dqs_n(3 downto 0)       => DDR_dqs_n(3 downto 0),
    DDR_dqs_p(3 downto 0)       => DDR_dqs_p(3 downto 0),
    DDR_odt                     => DDR_odt,
    DDR_ras_n                   => DDR_ras_n,
    DDR_reset_n                 => DDR_reset_n,
    DDR_we_n                    => DDR_we_n,

    FIXED_IO_ddr_vrn            => FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp            => FIXED_IO_ddr_vrp,
    FIXED_IO_mio(53 downto 0)   => FIXED_IO_mio(53 downto 0),
    FIXED_IO_ps_clk             => FIXED_IO_ps_clk,
    FIXED_IO_ps_porb            => FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb           => FIXED_IO_ps_srstb,

    M00_AXI_araddr(31 downto 0) => M00_AXI_araddr(31 downto 0),
    M00_AXI_arprot(2 downto 0)  => M00_AXI_arprot(2 downto 0),
    M00_AXI_arready             => M00_AXI_arready,
    M00_AXI_arvalid             => M00_AXI_arvalid,
    M00_AXI_awaddr(31 downto 0) => M00_AXI_awaddr(31 downto 0),
    M00_AXI_awprot(2 downto 0)  => M00_AXI_awprot(2 downto 0),
    M00_AXI_awready             => M00_AXI_awready,
    M00_AXI_awvalid             => M00_AXI_awvalid,
    M00_AXI_bready              => M00_AXI_bready,
    M00_AXI_bresp(1 downto 0)   => M00_AXI_bresp(1 downto 0),
    M00_AXI_bvalid              => M00_AXI_bvalid,
    M00_AXI_rdata(31 downto 0)  => M00_AXI_rdata(31 downto 0),
    M00_AXI_rready              => M00_AXI_rready,
    M00_AXI_rresp(1 downto 0)   => M00_AXI_rresp(1 downto 0),
    M00_AXI_rvalid              => M00_AXI_rvalid,
    M00_AXI_wdata(31 downto 0)  => M00_AXI_wdata(31 downto 0),
    M00_AXI_wready              => M00_AXI_wready,
    M00_AXI_wstrb(3 downto 0)   => M00_AXI_wstrb(3 downto 0),
    M00_AXI_wvalid              => M00_AXI_wvalid
);

axi4_lite_memif_inst : entity work.axi4_lite_memif
port map (
    S_AXI_CLK                     => FCLK_CLK0,
    S_AXI_RST                     => '0',

    -- Slave Interface Write Address channel Ports
    S_AXI_AWADDR                  => M00_AXI_awaddr,
--    S_AXI_AWPROT                  => M00_AXI_awprot,
    S_AXI_AWVALID                 => M00_AXI_awvalid,
    S_AXI_AWREADY                 => M00_AXI_awready,

    -- Slave Interface Write Data channel Ports
    S_AXI_WDATA                   => M00_AXI_wdata,
    S_AXI_WSTRB                   => M00_AXI_wstrb,
    S_AXI_WVALID                  => M00_AXI_wvalid,
    S_AXI_WREADY                  => M00_AXI_wready,

    -- Slave Interface Write Response channel Ports
    S_AXI_BRESP                   => M00_AXI_bresp,
    S_AXI_BVALID                  => M00_AXI_bvalid,
    S_AXI_BREADY                  => M00_AXI_bready,

    -- Slave Interface Read Address channel Ports
    S_AXI_ARADDR                  => M00_AXI_araddr,
--    S_AXI_ARPROT                  => M00_AXI_arprot,
    S_AXI_ARVALID                 => M00_AXI_arvalid,
    S_AXI_ARREADY                 => M00_AXI_arready,

    -- Slave Interface Read Data channel Ports
    S_AXI_RDATA                   => M00_AXI_rdata,
    S_AXI_RRESP                   => M00_AXI_rresp,
    S_AXI_RVALID                  => M00_AXI_rvalid,
    S_AXI_RREADY                  => M00_AXI_rready,

    -- Bus Memory Interface
    mem_addr_o                    => mem_addr,
    mem_dat_i                     => mem_idat,
    mem_dat_o                     => mem_odat,
    mem_cs_o                      => mem_cs,
    mem_rstb_o                    => mem_rstb,
    mem_wstb_o                    => mem_wstb
);

--
-- A copy of user configuration data is always
-- mirrored in this buffer. On STORE command,
-- configuration data is written onto flash.
--

-- cs #0 is allocated to BRAM
cs0_mem_wr <= mem_wstb and mem_cs(0);

cs0_mem_inst : entity work.panda_spbram
generic map (
    AW          => 10,
    DW          => 32
)
port map (
    addra       => mem_addr(9 downto 0),
    addrb       => mem_addr(9 downto 0),
    clka        => FCLK_CLK0,
    clkb        => FCLK_CLK0,
    dina        => mem_odat,
    doutb       => mem_read_dat_0,
    wea         => cs0_mem_wr
);

mem_idat <= mem_read_dat_0;

end rtl;
