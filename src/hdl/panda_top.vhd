--------------------------------------------------------------------------------
--  File:       panda_top.vhd
--  Desc:       PandA top-level design
--
--------------------------------------------------------------------------------

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
generic (
    AXI_BURST_LEN       : integer := 16;
    AXI_ADDR_WIDTH      : integer := 32;
    AXI_DATA_WIDTH      : integer := 32
);
port (
    DDR_addr            : inout std_logic_vector (14 downto 0);
    DDR_ba              : inout std_logic_vector (2 downto 0);
    DDR_cas_n           : inout std_logic;
    DDR_ck_n            : inout std_logic;
    DDR_ck_p            : inout std_logic;
    DDR_cke             : inout std_logic;
    DDR_cs_n            : inout std_logic;
    DDR_dm              : inout std_logic_vector (3 downto 0);
    DDR_dq              : inout std_logic_vector (31 downto 0);
    DDR_dqs_n           : inout std_logic_vector (3 downto 0);
    DDR_dqs_p           : inout std_logic_vector (3 downto 0);
    DDR_odt             : inout std_logic;
    DDR_ras_n           : inout std_logic;
    DDR_reset_n         : inout std_logic;
    DDR_we_n            : inout std_logic;
    FIXED_IO_ddr_vrn    : inout std_logic;
    FIXED_IO_ddr_vrp    : inout std_logic;
    FIXED_IO_mio        : inout std_logic_vector (53 downto 0);
    FIXED_IO_ps_clk     : inout std_logic;
    FIXED_IO_ps_porb    : inout std_logic;
    FIXED_IO_ps_srstb   : inout std_logic;

    -- RS485 Channel 0 Encoder I/O
    Am0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    As0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    enc0_ctrl_pad_i     : in    std_logic_vector(3  downto 0);
    enc0_ctrl_pad_o     : out   std_logic_vector(11 downto 0);

    -- Discrete I/O
    ttlin_pad_i         : in    std_logic_vector(TTLIN_NUM-1 downto 0);
    ttlout_pad_o        : out   std_logic_vector(TTLOUT_NUM-1 downto 0);
    lvdsin_pad_i        : in    std_logic_vector(LVDSIN_NUM-1 downto 0);
    lvdsout_pad_o       : out   std_logic_vector(LVDSOUT_NUM-1 downto 0);

    -- Status I/O
    leds                : out   std_logic_vector(1 downto 0)
);
end panda_top;

architecture rtl of panda_top is

component panda_ps is
port (
  FCLK_CLK0 : out STD_LOGIC;
  FCLK_LEDS : out STD_LOGIC_VECTOR ( 31 downto 0 );
  FCLK_RESET0_N : out STD_LOGIC_VECTOR ( 0 to 0 );
  IRQ_F2P : in STD_LOGIC_VECTOR ( 0 to 0 );
  S_AXI_HP0_arready : out STD_LOGIC;
  S_AXI_HP0_awready : out STD_LOGIC;
  S_AXI_HP0_bvalid : out STD_LOGIC;
  S_AXI_HP0_rlast : out STD_LOGIC;
  S_AXI_HP0_rvalid : out STD_LOGIC;
  S_AXI_HP0_wready : out STD_LOGIC;
  S_AXI_HP0_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
  S_AXI_HP0_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
  S_AXI_HP0_bid : out STD_LOGIC_VECTOR ( 5 downto 0 );
  S_AXI_HP0_rid : out STD_LOGIC_VECTOR ( 5 downto 0 );
  S_AXI_HP0_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
  S_AXI_HP0_arvalid : in STD_LOGIC;
  S_AXI_HP0_awvalid : in STD_LOGIC;
  S_AXI_HP0_bready : in STD_LOGIC;
  S_AXI_HP0_rready : in STD_LOGIC;
  S_AXI_HP0_wlast : in STD_LOGIC;
  S_AXI_HP0_wvalid : in STD_LOGIC;
  S_AXI_HP0_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
  S_AXI_HP0_arlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
  S_AXI_HP0_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
  S_AXI_HP0_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
  S_AXI_HP0_awlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
  S_AXI_HP0_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
  S_AXI_HP0_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
  S_AXI_HP0_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
  S_AXI_HP0_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
  S_AXI_HP0_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
  S_AXI_HP0_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
  S_AXI_HP0_arlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
  S_AXI_HP0_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
  S_AXI_HP0_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
  S_AXI_HP0_awlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
  S_AXI_HP0_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
  S_AXI_HP0_arid : in STD_LOGIC_VECTOR ( 5 downto 0 );
  S_AXI_HP0_awid : in STD_LOGIC_VECTOR ( 5 downto 0 );
  S_AXI_HP0_wid : in STD_LOGIC_VECTOR ( 5 downto 0 );
  S_AXI_HP0_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  S_AXI_HP0_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
  M00_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
  M00_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
  M00_AXI_awvalid : out STD_LOGIC;
  M00_AXI_awready : in STD_LOGIC;
  M00_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
  M00_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
  M00_AXI_wvalid : out STD_LOGIC;
  M00_AXI_wready : in STD_LOGIC;
  M00_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
  M00_AXI_bvalid : in STD_LOGIC;
  M00_AXI_bready : out STD_LOGIC;
  M00_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
  M00_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
  M00_AXI_arvalid : out STD_LOGIC;
  M00_AXI_arready : in STD_LOGIC;
  M00_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
  M00_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
  M00_AXI_rvalid : in STD_LOGIC;
  M00_AXI_rready : out STD_LOGIC;
  DDR_cas_n : inout STD_LOGIC;
  DDR_cke : inout STD_LOGIC;
  DDR_ck_n : inout STD_LOGIC;
  DDR_ck_p : inout STD_LOGIC;
  DDR_cs_n : inout STD_LOGIC;
  DDR_reset_n : inout STD_LOGIC;
  DDR_odt : inout STD_LOGIC;
  DDR_ras_n : inout STD_LOGIC;
  DDR_we_n : inout STD_LOGIC;
  DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
  DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
  DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
  DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
  DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
  DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
  FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
  FIXED_IO_ddr_vrn : inout STD_LOGIC;
  FIXED_IO_ddr_vrp : inout STD_LOGIC;
  FIXED_IO_ps_srstb : inout STD_LOGIC;
  FIXED_IO_ps_clk : inout STD_LOGIC;
  FIXED_IO_ps_porb : inout STD_LOGIC
);
end component panda_ps;


component ila_0
port (
    clk             : in  std_logic;
    probe0          : in  std_logic_vector(63 downto 0)
);
end component;

signal probe0               : std_logic_vector(63 downto 0);

-- Signal declarations
signal FCLK_CLK0            : std_logic;
signal FCLK_RESET0_N        : std_logic_vector(0 downto 0);
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

signal mem_cs               : std_logic_vector(2**PAGE_NUM-1 downto 0);
signal mem_addr             : std_logic_vector(PAGE_AW-1 downto 0);
signal mem_odat             : std_logic_vector(31 downto 0);
signal mem_wstb             : std_logic;
signal mem_rstb             : std_logic;
signal mem_read_data        : std32_array(2**PAGE_NUM-1 downto 0) :=
                                (others => (others => '0'));
signal IRQ_F2P              : std_logic_vector(0 downto 0);

-- Design Level Busses :
signal sysbus               : sysbus_t := (others => '0');
signal posbus               : posbus_t := (others => (others => '0'));
signal extbus               : extbus_t := (others => (others => '0'));

-- Input Encoder
signal posn_inenc_low       : std32_array(ENC_NUM-1 downto 0);
signal posn_inenc_high      : std32_array(ENC_NUM-1 downto 0) := (others => (others => '0'));
signal inenc_a              : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_b              : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_z              : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_conn           : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_ctrl           : std4_array(ENC_NUM-1 downto 0);

-- Output Encoder
signal outenc_conn          : std_logic_vector(ENC_NUM-1 downto 0);

-- Discrete Block Outputs :
signal ttlin_val            : std_logic_vector(TTLIN_NUM-1 downto 0);
signal lvdsin_val           : std_logic_vector(LVDSIN_NUM-1 downto 0);
signal lut_val              : std_logic_vector(LUT_NUM-1 downto 0);
signal srgate_val           : std_logic_vector(SRGATE_NUM-1 downto 0);
signal div_outd             : std_logic_vector(DIV_NUM-1 downto 0);
signal div_outn             : std_logic_vector(DIV_NUM-1 downto 0);
signal pulse_out            : std_logic_vector(PULSE_NUM-1 downto 0);
signal pulse_perr           : std_logic_vector(PULSE_NUM-1 downto 0);
signal seq_outa             : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_outb             : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_outc             : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_outd             : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_oute             : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_outf             : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_act              : std_logic_vector(SEQ_NUM-1 downto 0);

signal counter_carry        : std_logic_vector(COUNTER_NUM-1 downto 0);
signal posn_counter         : std32_array(COUNTER_NUM-1 downto 0);

signal pcomp_act            : std_logic_vector(PCOMP_NUM-1 downto 0);
signal pcomp_pulse          : std_logic_vector(PCOMP_NUM-1 downto 0);

signal panda_spbram_wea     : std_logic := '0';
signal irq_enable           : std_logic := '0';

signal pcap_act             : std_logic;

signal zero                 : std_logic;
signal one                  : std_logic;
signal clocks               : std_logic_vector(3 downto 0);
signal soft                 : std_logic_vector(3 downto 0);

signal adc_low              : std32_array(7 downto 0) := (others => (others => '0'));
signal adc_high             : std32_array(7 downto 0) := (others => (others => '0'));

attribute keep              : string;
attribute keep of sysbus    : signal is "true";
attribute keep of posbus    : signal is "true";

begin

-- Physical diagnostics outputs
leds <= FCLK_LEDS(26 downto 25);

-- Internal clocks and resets
FCLK_RESET0 <= not FCLK_RESET0_N(0);

--
-- Panda Processor System Block design instantiation
--
--ps : entity work.panda_ps
ps : panda_ps
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

    S_AXI_HP0_araddr            => S_AXI_HP0_araddr ,
    S_AXI_HP0_arburst           => S_AXI_HP0_arburst,
    S_AXI_HP0_arcache           => S_AXI_HP0_arcache,
    S_AXI_HP0_arid              => S_AXI_HP0_arid   ,
    S_AXI_HP0_arlen             => S_AXI_HP0_arlen  ,
    S_AXI_HP0_arlock            => S_AXI_HP0_arlock ,
    S_AXI_HP0_arprot            => S_AXI_HP0_arprot ,
    S_AXI_HP0_arqos             => S_AXI_HP0_arqos  ,
    S_AXI_HP0_arready           => S_AXI_HP0_arready,
    S_AXI_HP0_arsize            => S_AXI_HP0_arsize ,
    S_AXI_HP0_arvalid           => S_AXI_HP0_arvalid,
    S_AXI_HP0_awaddr            => S_AXI_HP0_awaddr ,
    S_AXI_HP0_awburst           => S_AXI_HP0_awburst,
    S_AXI_HP0_awcache           => S_AXI_HP0_awcache,
    S_AXI_HP0_awid              => S_AXI_HP0_awid   ,
    S_AXI_HP0_awlen             => S_AXI_HP0_awlen  ,
    S_AXI_HP0_awlock            => S_AXI_HP0_awlock ,
    S_AXI_HP0_awprot            => S_AXI_HP0_awprot ,
    S_AXI_HP0_awqos             => S_AXI_HP0_awqos  ,
    S_AXI_HP0_awready           => S_AXI_HP0_awready,
    S_AXI_HP0_awsize            => S_AXI_HP0_awsize ,
    S_AXI_HP0_awvalid           => S_AXI_HP0_awvalid,
    S_AXI_HP0_bid               => S_AXI_HP0_bid    ,
    S_AXI_HP0_bready            => S_AXI_HP0_bready ,
    S_AXI_HP0_bresp             => S_AXI_HP0_bresp  ,
    S_AXI_HP0_bvalid            => S_AXI_HP0_bvalid ,
    S_AXI_HP0_rdata             => S_AXI_HP0_rdata  ,
    S_AXI_HP0_rid               => S_AXI_HP0_rid    ,
    S_AXI_HP0_rlast             => S_AXI_HP0_rlast  ,
    S_AXI_HP0_rready            => S_AXI_HP0_rready ,
    S_AXI_HP0_rresp             => S_AXI_HP0_rresp  ,
    S_AXI_HP0_rvalid            => S_AXI_HP0_rvalid ,
    S_AXI_HP0_wdata             => S_AXI_HP0_wdata  ,
    S_AXI_HP0_wid               => S_AXI_HP0_wid    ,
    S_AXI_HP0_wlast             => S_AXI_HP0_wlast  ,
    S_AXI_HP0_wready            => S_AXI_HP0_wready ,
    S_AXI_HP0_wstrb             => S_AXI_HP0_wstrb  ,
    S_AXI_HP0_wvalid            => S_AXI_HP0_wvalid
);

--
-- Control and Status Memory Interface
--
-- 0x43c00000
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

--
-- TTL
--
ttlin_inst : entity work.panda_ttlin_top
port map (
    clk_i               => FCLK_CLK0,
    pad_i               => ttlin_pad_i,
    val_o               => ttlin_val
);

ttlout_inst : entity work.panda_ttlout_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,
    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(TTL_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    sysbus_i            => sysbus,
    pad_o               => ttlout_pad_o
);

--
-- LVDS
--
lvdsin_inst : entity work.panda_lvdsin_top
port map (
    clk_i               => FCLK_CLK0,
    pad_i               => lvdsin_pad_i,
    val_o               => lvdsin_val
);

lvdsout_inst : entity work.panda_lvdsout_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,
    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(LVDS_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    sysbus_i            => sysbus,
    pad_o               => lvdsout_pad_o
);

--
-- 5-Input LUT
--
lut_inst : entity work.panda_lut_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,
    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(LUT_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    sysbus_i            => sysbus,
    out_o               => lut_val
);

--
-- 5-Input LUT
--
srgate_inst : entity work.panda_srgate_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(SRGATE_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,

    sysbus_i            => sysbus,

    out_o               => srgate_val
);

--
-- DIVIDER
--
div_inst : entity work.panda_div_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(DIV_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(DIV_CS),

    sysbus_i            => sysbus,

    outd_o              => div_outd,
    outn_o              => div_outn
);

--
-- PULSE GENERATOR
--
pulse_inst : entity work.panda_pulse_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(PULSE_CS),
    mem_wstb_i          => mem_wstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(PULSE_CS),

    sysbus_i            => sysbus,

    out_o               => pulse_out,
    perr_o              => pulse_perr
);

--
-- SEQEUENCER
--
seq_inst : entity work.panda_sequencer_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(SEQ_CS),
    mem_wstb_i          => mem_wstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(SEQ_CS),

    sysbus_i            => sysbus,

    outa_o              => seq_outa,
    outb_o              => seq_outb,
    outc_o              => seq_outc,
    outd_o              => seq_outd,
    oute_o              => seq_oute,
    outf_o              => seq_outf,
    active_o            => seq_act
);

--
-- INENC (Encoder Inputs)
--
inenc_ctrl(0) <= enc0_ctrl_pad_i;
inenc_ctrl(1) <= "0000";
inenc_ctrl(2) <= "0000";
inenc_ctrl(3) <= "0000";

inenc_inst : entity work.panda_inenc_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(INENC_CS),
    mem_wstb_i          => mem_wstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(INENC_CS),

    Am0_pad_io          => Am0_pad_io,
    Bm0_pad_io          => Bm0_pad_io,
    Zm0_pad_io          => Zm0_pad_io,

    ctrl_pad_i          => inenc_ctrl,

    a_o                 => inenc_a,
    b_o                 => inenc_b,
    z_o                 => inenc_z,
    conn_o              => inenc_conn,
    posn_o              => posn_inenc_low
);

--
-- OUTENC (Encoder Inputs)
--
outenc_inst : entity work.panda_outenc_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(OUTENC_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(OUTENC_CS),

    As0_pad_io          => As0_pad_io,
    Bs0_pad_io          => Bs0_pad_io,
    Zs0_pad_io          => Zs0_pad_io,
    conn_o              => outenc_conn,

    sysbus_i            => sysbus,
    posbus_i            => posbus
);

--
-- COUNTER/TIMER
--
counter_inst : entity work.panda_counter_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(COUNTER_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(COUNTER_CS),

    sysbus_i            => sysbus,
    -- Output pulse
    carry_o             => counter_carry,
    count_o             => posn_counter
);

--
-- POSITION COMPARE
--
pcomp_inst : entity work.panda_pcomp_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(PCOMP_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(PCOMP_CS),

    sysbus_i            => sysbus,
    posbus_i            => posbus,

    act_o               => pcomp_act,
    pulse_o             => pcomp_pulse
);

--
-- POSITION CAPTURE
--
pcap_inst : entity work.panda_pcap_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    m_axi_awaddr        => S_AXI_HP0_awaddr,
    m_axi_awburst       => S_AXI_HP0_awburst,
    m_axi_awcache       => S_AXI_HP0_awcache,
    m_axi_awid          => S_AXI_HP0_awid,
    m_axi_awlen         => S_AXI_HP0_awlen,
    m_axi_awlock        => S_AXI_HP0_awlock,
    m_axi_awprot        => S_AXI_HP0_awprot,
    m_axi_awqos         => S_AXI_HP0_awqos,
    m_axi_awready       => S_AXI_HP0_awready,
    m_axi_awsize        => S_AXI_HP0_awsize,
    m_axi_awvalid       => S_AXI_HP0_awvalid,
    m_axi_bid           => S_AXI_HP0_bid,
    m_axi_bready        => S_AXI_HP0_bready,
    m_axi_bresp         => S_AXI_HP0_bresp,
    m_axi_bvalid        => S_AXI_HP0_bvalid,
    m_axi_wdata         => S_AXI_HP0_wdata,
    m_axi_wid           => S_AXI_HP0_wid,
    m_axi_wlast         => S_AXI_HP0_wlast,
    m_axi_wready        => S_AXI_HP0_wready,
    m_axi_wstrb         => S_AXI_HP0_wstrb,
    m_axi_wvalid        => S_AXI_HP0_wvalid,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs,
    mem_wstb_i          => mem_wstb,
    mem_dat_i           => mem_odat,
    mem_dat_0_o         => mem_read_data(PCAP_CS),
    mem_dat_1_o         => mem_read_data(DRV_CS),

    sysbus_i            => sysbus,
    posbus_i            => posbus,
    extbus_i            => extbus,

    pcap_actv_o         => pcap_act,
    pcap_irq_o          => IRQ_F2P(0)
);

--
-- REG (System Bus Readback)
--
reg_inst : entity work.panda_reg
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(REG_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(REG_CS),

    sysbus_i            => sysbus
);

--
-- CLOCKS
--
clocks_inst : entity work.panda_clocks_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(CLOCKS_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(CLOCKS_CS),

    clocks_o            => clocks
);

--
-- BITS
--
bits_inst : entity work.panda_bits_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(BITS_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(BITS_CS),

    zero_o              => zero,
    one_o               => one,
    soft_o              => soft
);

--
-- SLOW CONTROLLER FPGA
--
slowctrl_inst : entity work.panda_slowctrl_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(SLOW_CS),
    mem_wstb_i          => mem_wstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(SLOW_CS),

    enc0_ctrl_o         => enc0_ctrl_pad_o
);

--
-- System Bus   : Assignments
--
sysbus(0)               <= zero;
sysbus(1)               <= one;
sysbus(7 downto 2)      <= ttlin_val;
sysbus(9 downto 8)      <= lvdsin_val;
sysbus(17 downto 10)    <= lut_val;
sysbus(21 downto 18)    <= srgate_val;
sysbus(25 downto 22)    <= div_outd;
sysbus(29 downto 26)    <= div_outn;
sysbus(33 downto 30)    <= pulse_out;
sysbus(37 downto 34)    <= pulse_perr;
sysbus(41 downto 38)    <= seq_outa;
sysbus(45 downto 42)    <= seq_outb;
sysbus(49 downto 46)    <= seq_outc;
sysbus(53 downto 50)    <= seq_outd;
sysbus(57 downto 54)    <= seq_oute;
sysbus(61 downto 58)    <= seq_outf;
sysbus(65 downto 62)    <= seq_act;
sysbus(69 downto 66)    <= inenc_a;
sysbus(73 downto 70)    <= inenc_b;
sysbus(77 downto 74)    <= inenc_z;
sysbus(81 downto 78)    <= inenc_conn;
sysbus(85 downto 82)    <= (others => '0'); --POSENC_A
sysbus(89 downto 86)    <= (others => '0'); --POSENC_B
sysbus(97 downto 90)    <= counter_carry;
sysbus(101 downto 98)   <= pcomp_act;
sysbus(105 downto 102)  <= pcomp_pulse;
sysbus(106)             <= pcap_act;
sysbus(117 downto 107)  <= (others => '0');
sysbus(121 downto 118)  <= soft;
sysbus(125 downto 122)  <= clocks;
sysbus(127 downto 126)  <= (others => '0');

--
-- Position Bus   : Assignments
--
posbus(0) <= (others => '0');
posbus(4 downto 1)   <= posn_inenc_low;
posbus(8 downto 5)   <= (others => (others => '0')); -- QDEC
posbus(10 downto 9)  <= (others => (others => '0')); -- ADDER
posbus(18 downto 11) <= posn_counter;
posbus(20 downto 19) <= (others => (others => '0')); -- PGEN
posbus(28 downto 21) <= adc_low;
posbus(31 downto 29) <= (others => (others => '0')); -- Not Used

--
-- Extended Bus   : Assignments
--
extbus(3 downto 0)  <= posn_inenc_high;
extbus(11 downto 4) <= adc_high;

end rtl;
