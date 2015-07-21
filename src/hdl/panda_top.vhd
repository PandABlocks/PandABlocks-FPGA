library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;
use work.type_defines.all;
use work.addr_defines.all;

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

    -- RS485 Channel 0 Encoder I/O
    Am0_pad_io          : inout std_logic_vector(INENC_NUM-1 downto 0);
    Bm0_pad_io          : inout std_logic_vector(INENC_NUM-1 downto 0);
    Zm0_pad_io          : inout std_logic_vector(INENC_NUM-1 downto 0);
    As0_pad_io          : inout std_logic_vector(INENC_NUM-1 downto 0);
    Bs0_pad_io          : inout std_logic_vector(INENC_NUM-1 downto 0);
    Zs0_pad_io          : inout std_logic_vector(INENC_NUM-1 downto 0);
    enc0_ctrl_pad_i     : in    std_logic_vector(3  downto 0);
    enc0_ctrl_pad_o     : out   std_logic_vector(11 downto 0);

    -- Status I/O
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
  IRQ_F2P           : in std_logic;
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
  M01_AXI_awaddr    : out std_logic_vector ( 31 downto 0 );
  M01_AXI_awprot    : out std_logic_vector ( 2 downto 0 );
  M01_AXI_awvalid   : out std_logic;
  M01_AXI_awready   : in std_logic;
  M01_AXI_wdata     : out std_logic_vector ( 31 downto 0 );
  M01_AXI_wstrb     : out std_logic_vector ( 3 downto 0 );
  M01_AXI_wvalid    : out std_logic;
  M01_AXI_wready    : in std_logic;
  M01_AXI_bresp     : in std_logic_vector ( 1 downto 0 );
  M01_AXI_bvalid    : in std_logic;
  M01_AXI_bready    : out std_logic;
  M01_AXI_araddr    : out std_logic_vector ( 31 downto 0 );
  M01_AXI_arprot    : out std_logic_vector ( 2 downto 0 );
  M01_AXI_arvalid   : out std_logic;
  M01_AXI_arready   : in std_logic;
  M01_AXI_rdata     : in std_logic_vector ( 31 downto 0 );
  M01_AXI_rresp     : in std_logic_vector ( 1 downto 0 );
  M01_AXI_rvalid    : in std_logic;
  M01_AXI_rready    : out std_logic;
  FCLK_RESET0_N     : out std_logic;
  FCLK_CLK0         : out std_logic;
  FCLK_LEDS         : out std_logic_vector(31 downto 0)
);
end component;

component ila_0
port (
    clk             : in  std_logic;
    probe0          : in  std_logic_vector(63 downto 0)
);
end component;

-- Signal declarations
signal FCLK_CLK0            : std_logic;
signal FCLK_RESET0_N        : std_logic;
signal FCLK_RESET0          : std_logic;
signal FCLK_LEDS            : std_logic_vector(31 downto 0);

signal M00_AXI_awaddr       : std_logic_vector ( 31 downto 0 );
signal M00_AXI_awprot       : std_logic_vector ( 2 downto 0 );
signal M00_AXI_awvalid      : std_logic;
signal M00_AXI_awready      : std_logic;
signal M00_AXI_wdata        : std_logic_vector ( 31 downto 0 );
signal M00_AXI_wstrb        : std_logic_vector ( 3 downto 0 );
signal M00_AXI_wvalid       : std_logic;
signal M00_AXI_wready       : std_logic;
signal M00_AXI_bresp        : std_logic_vector ( 1 downto 0 );
signal M00_AXI_bvalid       : std_logic;
signal M00_AXI_bready       : std_logic;
signal M00_AXI_araddr       : std_logic_vector ( 31 downto 0 );
signal M00_AXI_arprot       : std_logic_vector ( 2 downto 0 );
signal M00_AXI_arvalid      : std_logic;
signal M00_AXI_arready      : std_logic;
signal M00_AXI_rdata        : std_logic_vector ( 31 downto 0 );
signal M00_AXI_rresp        : std_logic_vector ( 1 downto 0 );
signal M00_AXI_rvalid       : std_logic;
signal M00_AXI_rready       : std_logic;

signal M01_AXI_awaddr       : std_logic_vector ( 31 downto 0 );
signal M01_AXI_awprot       : std_logic_vector ( 2 downto 0 );
signal M01_AXI_awvalid      : std_logic;
signal M01_AXI_awready      : std_logic;
signal M01_AXI_wdata        : std_logic_vector ( 31 downto 0 );
signal M01_AXI_wstrb        : std_logic_vector ( 3 downto 0 );
signal M01_AXI_wvalid       : std_logic;
signal M01_AXI_wready       : std_logic;
signal M01_AXI_bresp        : std_logic_vector ( 1 downto 0 );
signal M01_AXI_bvalid       : std_logic;
signal M01_AXI_bready       : std_logic;
signal M01_AXI_araddr       : std_logic_vector ( 31 downto 0 );
signal M01_AXI_arprot       : std_logic_vector ( 2 downto 0 );
signal M01_AXI_arvalid      : std_logic;
signal M01_AXI_arready      : std_logic;
signal M01_AXI_rdata        : std_logic_vector ( 31 downto 0 );
signal M01_AXI_rresp        : std_logic_vector ( 1 downto 0 );
signal M01_AXI_rvalid       : std_logic;
signal M01_AXI_rready       : std_logic;

signal mem_cs               : std_logic_vector(2**MEM_CS_NUM-1 downto 0);
signal mem_addr             : std_logic_vector(MEM_AW-1 downto 0);
signal mem_odat             : std_logic_vector(31 downto 0);
signal mem_wstb             : std_logic;
signal mem_rstb             : std_logic;
signal mem_read_data        : std32_array(2**MEM_CS_NUM-1 downto 0);

signal IRQ_F2P              : std_logic;

signal probe0               : std_logic_vector(63 downto 0);

signal encin_buf_ctrl       : std_logic_vector(5 downto 0);
signal outenc_buf_ctrl      : std_logic_vector(5 downto 0);
signal enc0_ctrl_opad       : std_logic_vector(11 downto 0);

signal As0_ipad, As0_opad   : std_logic;
signal Bs0_ipad, Bs0_opad   : std_logic;
signal Zs0_ipad, Zs0_opad   : std_logic;

signal A_o, B_o, Z_o        : std_logic;
signal mclk_o               : std_logic;
signal mdat_i               : std_logic;
signal sclk_i               : std_logic;
signal sdat_o               : std_logic;
signal encin_mode           : std_logic_vector(2 downto 0);
signal outenc_mode          : std_logic_vector(2 downto 0);
signal endat_mdir           : std_logic;
signal endat_sdir           : std_logic;

signal encin_posn           : std32_array(INENC_NUM-1 downto 0);

signal encout_posn          : std32_array(INENC_NUM-1 downto 0);
signal soft_posn            : std_logic_vector(31 downto 0) := (others =>'0');

begin

--
leds <= FCLK_LEDS(26 downto 25);

FCLK_RESET0 <= not FCLK_RESET0_N;

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
    IRQ_F2P                     => IRQ_F2P,

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
    M00_AXI_wvalid              => M00_AXI_wvalid,

    M01_AXI_araddr(31 downto 0) => M01_AXI_araddr(31 downto 0),
    M01_AXI_arprot(2 downto 0)  => M01_AXI_arprot(2 downto 0),
    M01_AXI_arready             => M01_AXI_arready,
    M01_AXI_arvalid             => M01_AXI_arvalid,
    M01_AXI_awaddr(31 downto 0) => M01_AXI_awaddr(31 downto 0),
    M01_AXI_awprot(2 downto 0)  => M01_AXI_awprot(2 downto 0),
    M01_AXI_awready             => M01_AXI_awready,
    M01_AXI_awvalid             => M01_AXI_awvalid,
    M01_AXI_bready              => M01_AXI_bready,
    M01_AXI_bresp(1 downto 0)   => M01_AXI_bresp(1 downto 0),
    M01_AXI_bvalid              => M01_AXI_bvalid,
    M01_AXI_rdata(31 downto 0)  => M01_AXI_rdata(31 downto 0),
    M01_AXI_rready              => M01_AXI_rready,
    M01_AXI_rresp(1 downto 0)   => M01_AXI_rresp(1 downto 0),
    M01_AXI_rvalid              => M01_AXI_rvalid,
    M01_AXI_wdata(31 downto 0)  => M01_AXI_wdata(31 downto 0),
    M01_AXI_wready              => M01_AXI_wready,
    M01_AXI_wstrb(3 downto 0)   => M01_AXI_wstrb(3 downto 0),
    M01_AXI_wvalid              => M01_AXI_wvalid

);

--0x43c10000
panda_pcap_inst : entity work.panda_pcap_v1_0
generic map (
    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_DATA_WIDTH        => 32,
    C_S00_AXI_ADDR_WIDTH        => 7
)
port map (
    irq                         => IRQ_F2P,

    s00_axi_aclk                => FCLK_CLK0,
    s00_axi_aresetn             => FCLK_RESET0_N,
    s00_axi_awaddr              => M01_AXI_awaddr(6 downto 0),
    s00_axi_awprot              => M01_AXI_awprot,
    s00_axi_awvalid             => M01_AXI_awvalid,
    s00_axi_awready             => M01_AXI_awready,
    s00_axi_wdata               => M01_AXI_wdata,
    s00_axi_wstrb               => M01_AXI_wstrb,
    s00_axi_wvalid              => M01_AXI_wvalid,
    s00_axi_wready              => M01_AXI_wready,
    s00_axi_bresp               => M01_AXI_bresp,
    s00_axi_bvalid              => M01_AXI_bvalid,
    s00_axi_bready              => M01_AXI_bready,
    s00_axi_araddr              => M01_AXI_araddr(6 downto 0),
    s00_axi_arprot              => M01_AXI_arprot,
    s00_axi_arvalid             => M01_AXI_arvalid,
    s00_axi_arready             => M01_AXI_arready,
    s00_axi_rdata               => M01_AXI_rdata,
    s00_axi_rresp               => M01_AXI_rresp,
    s00_axi_rvalid              => M01_AXI_rvalid,
    s00_axi_rready              => M01_AXI_rready
);

-- 0x43c00000
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

mem_read_data(0) <= X"12345678";
mem_read_data(1) <= X"11111111";
mem_read_data(2) <= X"22222222";

--
-- Encoder Test Interface
--
REGISTER_READ : process(FCLK_CLK0)
begin
    if rising_edge(FCLK_CLK0) then
        -- DCard Input Channel Buffer Ctrl
        -- Inc   : 0x03
        -- SSI   : 0x0C
        -- Endat : 0x14
        -- BiSS  : 0x1C
        if (mem_cs(0) = '1' and mem_wstb = '1' and mem_addr = X"00") then
            encin_buf_ctrl <= mem_odat(5 downto 0);
        end if;

        -- DCard Output Channel Buffer Ctrl
        -- Inc   : 0x07
        -- SSI   : 0x28
        -- Endat : 0x10
        -- BiSS  : 0x18
        -- DCard Output Channel Buffer Ctrl
        if (mem_cs(0) = '1' and mem_wstb = '1' and mem_addr = X"01") then
            outenc_buf_ctrl <= mem_odat(5 downto 0);
        end if;

        -- Soft Posn
        if (mem_cs(0) = '1' and mem_wstb = '1' and mem_addr = X"02") then
            soft_posn <= mem_odat;
        end if;

    end if;
end process;

ENCIN_INST : entity work.panda_encin_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(ENCIN_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => open,

    Am0_pad_io          => Am0_pad_io,
    Bm0_pad_io          => Bm0_pad_io,
    Zm0_pad_io          => Zm0_pad_io,

    posn_o              => encin_posn
);

ENCOUT_INST : entity work.panda_encout_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(ENCOUT_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(ENCOUT_CS),

    As0_pad_io          => As0_pad_io,
    Bs0_pad_io          => Bs0_pad_io,
    Zs0_pad_io          => Zs0_pad_io,

    posn_i              => encout_posn
);

encout_posn(0) <= soft_posn;

-- Daughter Card Buffer Control Signals
enc0_ctrl_opad(1 downto 0) <= encin_buf_ctrl(1 downto 0);
enc0_ctrl_opad(3 downto 2) <= outenc_buf_ctrl(1 downto 0);
enc0_ctrl_opad(4) <= encin_buf_ctrl(2);
enc0_ctrl_opad(5) <= outenc_buf_ctrl(2);
enc0_ctrl_opad(7 downto 6) <= encin_buf_ctrl(4 downto 3);
enc0_ctrl_opad(9 downto 8) <= outenc_buf_ctrl(4 downto 3);
enc0_ctrl_opad(10) <= encin_buf_ctrl(5);
enc0_ctrl_opad(11) <= outenc_buf_ctrl(5);

enc0_ctrl_pad_o <= enc0_ctrl_opad;

--
-- Chipscope
--
ila_0_inst : component ila_0
port map (
    clk         => FCLK_CLK0,
    probe0      => probe0
);

probe0(0) <= '0';
probe0(1) <= '0';
probe0(2) <= '0';
probe0(3) <= '0';
probe0(35 downto 4) <= encin_posn(0);
probe0(63 downto 36) <= (others => '0');

end rtl;
