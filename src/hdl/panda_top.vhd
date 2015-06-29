library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;

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
    Am0_pad_io          : inout std_logic;
    Bm0_pad_io          : inout std_logic;
    Zm0_pad_io          : inout std_logic;
    As0_pad_io          : inout std_logic;
    Bs0_pad_io          : inout std_logic;
    Zs0_pad_io          : inout std_logic;
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

signal M01_AXI_awaddr   : std_logic_vector ( 31 downto 0 );
signal M01_AXI_awprot   : std_logic_vector ( 2 downto 0 );
signal M01_AXI_awvalid  : std_logic;
signal M01_AXI_awready  : std_logic;
signal M01_AXI_wdata    : std_logic_vector ( 31 downto 0 );
signal M01_AXI_wstrb    : std_logic_vector ( 3 downto 0 );
signal M01_AXI_wvalid   : std_logic;
signal M01_AXI_wready   : std_logic;
signal M01_AXI_bresp    : std_logic_vector ( 1 downto 0 );
signal M01_AXI_bvalid   : std_logic;
signal M01_AXI_bready   : std_logic;
signal M01_AXI_araddr   : std_logic_vector ( 31 downto 0 );
signal M01_AXI_arprot   : std_logic_vector ( 2 downto 0 );
signal M01_AXI_arvalid  : std_logic;
signal M01_AXI_arready  : std_logic;
signal M01_AXI_rdata    : std_logic_vector ( 31 downto 0 );
signal M01_AXI_rresp    : std_logic_vector ( 1 downto 0 );
signal M01_AXI_rvalid   : std_logic;
signal M01_AXI_rready   : std_logic;

signal mem_cs           : std_logic_vector(2**MEM_CS_NUM-1 downto 0);
signal mem_addr         : std_logic_vector(MEM_AW-1 downto 0);
signal mem_idat         : std_logic_vector(31 downto 0);
signal mem_odat         : std_logic_vector(31 downto 0);
signal mem_wstb         : std_logic;
signal mem_rstb         : std_logic;

signal cs0_mem_wr       : std_logic;
signal mem_read_dat_0   : std_logic_vector(31 downto 0);

signal IRQ_F2P          : std_logic;

signal probe0           : std_logic_vector(63 downto 0);

signal enc0_ctrl_opad       : std_logic_vector(11 downto 0) := X"02F";
signal inenc_iobuf_ctrl     : std_logic_vector(2 downto 0);
signal outenc_iobuf_ctrl    : std_logic_vector(2 downto 0);

signal Am0_ipad, Am0_opad   : std_logic;
signal Bm0_ipad, Bm0_opad   : std_logic;
signal Zm0_ipad, Zm0_opad   : std_logic;

signal As0_ipad, As0_opad   : std_logic;
signal Bs0_ipad, Bs0_opad   : std_logic;
signal Zs0_ipad, Zs0_opad   : std_logic;

signal A_i, B_i, Z_i        : std_logic;
signal A_o, B_o, Z_o        : std_logic;
signal mclk_o               : std_logic;
signal mdat_i               : std_logic;
signal sclk_i               : std_logic;
signal sdat_o               : std_logic;
signal inenc_buf_ctrl       : std_logic_vector(5 downto 0);
signal outenc_buf_ctrl      : std_logic_vector(5 downto 0);
signal inenc_mode           : std_logic_vector(2 downto 0);
signal outenc_mode          : std_logic_vector(2 downto 0);

signal endat_mdir           : std_logic;
signal endat_sdir           : std_logic;
signal enc_dat              : std_logic_vector(23 downto 0);
signal enc_val              : std_logic;

signal ssimstr_reset        : std_logic;

constant ssi_clk_div        : std_logic_vector(15 downto 0) := X"0064";
constant smpl_shift         : std_logic_vector(3 downto 0)  := X"A";

attribute keep : string;
attribute keep of enc0_ctrl_opad        : signal is "true";
attribute keep of inenc_iobuf_ctrl      : signal is "true";
attribute keep of outenc_iobuf_ctrl     : signal is "true";

begin

--
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
    S_AXI_RST                   => '0',
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
    mem_dat_i                   => mem_idat,
    mem_dat_o                   => mem_odat,
    mem_cs_o                    => mem_cs,
    mem_rstb_o                  => mem_rstb,
    mem_wstb_o                  => mem_wstb
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
    AW          => MEM_AW,
    DW          => 32
)
port map (
    addra       => mem_addr,
    addrb       => mem_addr,
    clka        => FCLK_CLK0,
    clkb        => FCLK_CLK0,
    dina        => mem_odat,
    doutb       => mem_read_dat_0,
    wea         => cs0_mem_wr
);

mem_idat <= mem_read_dat_0;

--
-- Encoder Test Interface
--
register_read : process(FCLK_CLK0)
begin
    if rising_edge(FCLK_CLK0) then
        if (cs0_mem_wr = '1' and mem_addr = X"00") then
            inenc_mode <= mem_odat(2 downto 0);
            outenc_mode <= mem_odat(6 downto 4);
        end if;

        case (inenc_mode) is
            when "000"  =>
                inenc_iobuf_ctrl <= "111";
                inenc_buf_ctrl <= "000011";
            when "001"  =>
                inenc_iobuf_ctrl <= "101";
                inenc_buf_ctrl <= "001100";
            when "010"  =>
                inenc_iobuf_ctrl <= endat_mdir & "00";
                inenc_buf_ctrl <= "010100";
            when "011"  =>
                inenc_iobuf_ctrl <= endat_mdir & "00";
                inenc_buf_ctrl <= "011100";
            when others =>
        end case;

        case (outenc_mode) is
            when "000"  =>
                outenc_iobuf_ctrl <= "000";
                outenc_buf_ctrl <= "000111";
            when "001"  =>
                outenc_iobuf_ctrl <= "011";
                outenc_buf_ctrl <= "101000";
            when "010"  =>
                outenc_iobuf_ctrl <= endat_sdir & "10";
                outenc_buf_ctrl <= "010000";
            when "011"  =>
                outenc_iobuf_ctrl <= endat_sdir & "10";
                outenc_buf_ctrl <= "011000";
            when others =>
        end case;
    end if;
end process;

-- Master IOBUF instantiations
IOBUF_Am0 : IOBUF port map (
I=>Am0_opad, O=>Am0_ipad, T=>inenc_iobuf_ctrl(2), IO=>Am0_pad_io);

IOBUF_Bm0 : IOBUF port map (
I=>Bm0_opad, O=>Bm0_ipad, T=>inenc_iobuf_ctrl(1), IO=>Bm0_pad_io);

IOBUF_Zm0 : IOBUF port map (
I=>Zm0_opad, O=>Zm0_ipad, T=>inenc_iobuf_ctrl(0), IO=>Zm0_pad_io);

A_i <= Am0_ipad;
B_i <= Bm0_ipad;
Z_i <= Zm0_ipad;
Bm0_opad <= mclk_o;
mdat_i <= Am0_ipad;
Zm0_opad <= endat_mdir;

-- MASTER continuously reads from Absolute Encoder
-- at 1MHz (50MHz/SSI_CLK_DIV).
ssimstr_reset <= not outenc_mode(0);

zebra_ssimstr_inst : entity work.zebra_ssimstr
generic map (
    CHNUM           => 0,
    N               => 24,
    SSI_DEAD_PRD    => 25
)
port map (
    clk_i           => FCLK_CLK0,
    reset_i         => ssimstr_reset,
    ssi_clk_div     => ssi_clk_div,
    smpl_shift      => smpl_shift,
    ssi_sck_o       => mclk_o,
    ssi_dat_i       => mdat_i,
    enc_dat_o       => enc_dat,
    enc_val_o       => enc_val,
    enc_dbg_o       => open
);

zebra_ssislv_inst : entity work.zebra_ssislv
generic map (
    N               => 24
)
port map (
    clk_i           => FCLK_CLK0,
    reset_i         => ssimstr_reset,
    ssi_sck_i       => sclk_i,
    ssi_dat_o       => sdat_o,
    enc_dat_i       => enc_dat,
    enc_val_i       => enc_val,
    ssi_rd_sof      => open
);

-- Slave IOBUF instantiations
IOBUF_As0 : IOBUF port map (
I=>As0_opad, O=>As0_ipad, T=>outenc_iobuf_ctrl(2), IO=>As0_pad_io);

IOBUF_Bs0 : IOBUF port map (
I=>Bs0_opad, O=>Bs0_ipad, T=>outenc_iobuf_ctrl(1), IO=>Bs0_pad_io);

IOBUF_Zs0 : IOBUF port map (
I=>Zs0_opad, O=>Zs0_ipad, T=>outenc_iobuf_ctrl(0), IO=>Zs0_pad_io);

As0_opad <= A_o when (outenc_mode = "000") else sdat_o;
Bs0_opad <= B_o;
Zs0_opad <= Z_o when (outenc_mode = "000") else endat_sdir;
sclk_i <= Bs0_ipad;

process(FCLK_CLK0)
    variable counter    : unsigned(31 downto 0);
begin
    if rising_edge(FCLK_CLK0) then
        counter := counter + 1;
        A_o <= counter(4);
        B_o <= counter(5);
        Z_o <= counter(6);
--        mclk_o <= counter(7);
--        sdat_o <= counter(8);
    end if;
end process;

enc0_ctrl_opad(1 downto 0) <= inenc_buf_ctrl(1 downto 0);
enc0_ctrl_opad(3 downto 2) <= outenc_buf_ctrl(1 downto 0);
enc0_ctrl_opad(4) <= inenc_buf_ctrl(2);
enc0_ctrl_opad(5) <= outenc_buf_ctrl(2);
enc0_ctrl_opad(7 downto 6) <= inenc_buf_ctrl(4 downto 3);
enc0_ctrl_opad(9 downto 8) <= outenc_buf_ctrl(4 downto 3);
enc0_ctrl_opad(10) <= inenc_buf_ctrl(5);
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

probe0(0) <= A_i;
probe0(1) <= B_i;
probe0(2) <= Z_i;
probe0(14 downto 3) <= enc0_ctrl_opad;
probe0(18 downto 15)<= enc0_ctrl_pad_i;
probe0(19) <= sclk_i;
probe0(20) <= mdat_i;
probe0(23 downto 21) <= inenc_iobuf_ctrl;
probe0(26 downto 24) <= outenc_iobuf_ctrl;
probe0(27) <= enc_val;
probe0(51 downto 28) <= enc_dat;
probe0(63 downto 52) <= (others => '0');

end rtl;


--InEnc_inst : entity work.inenc
--port map (
--    clk_i       => FCLK_CLK0,
--
--    a_i         => Am0_ipad,
--    b_i         => Bm0_ipad,
--    z_i         => Zm0_ipad,
--    sclk_o      => Bm0_opad,
--    sdat_i      => Am0_ipad,
--    sdat_o      => Am0_opad
--    buf_ctrl_o  => inenc0_ctrl
--);
--
--OutEnc_inst : entity work.outenc
--port map (
--    clk_i       => FCLK_CLK0,
--
--    a_o         => As0_opad,
--    b_o         => Bs0_opad,
--    z_o         => Zs0_opad,
--    sclk_i      => Bs0_ipad,
--    sdat_i      => As0_ipad,
--    sdat_o      => As0_opad
--    sdat_en_i   => As0_enpad
--);


