library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

library unisim;
use unisim.vcomponents.all;

entity sfp_dls_eventr_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;

    -- From PS block
    fclk_clk0_ps_i      : in  std_logic;
    -- External SMA clock
    EXTCLK_P            : in  std_logic;
    EXTCLK_N            : in  std_logic;
    -- Clocked selected
    FCLK_CLK0_o         : out std_logic;

    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;

    -- SMA PLL locked
    sma_pll_locked_o    : out std_logic;
    -- sma and event receiver clock enables
    ext_clock_i         : in  std_logic_vector(1 downto 0);

    -- Bits out
    bit1_o              : out std_logic;
    bit2_o              : out std_logic;
    bit3_o              : out std_logic;
    bit4_o              : out std_logic;

    -- GTX I/O
    GTREFCLK_N          : in  std_logic;
    GTREFCLK_P          : in  std_logic;
    RXN_IN              : in  std_logic_vector(2 downto 0);
    RXP_IN              : in  std_logic_vector(2 downto 0);
    TXN_OUT             : out std_logic_vector(2 downto 0);
    TXP_OUT             : out std_logic_vector(2 downto 0)
);
end sfp_dls_eventr_top;

architecture rtl of sfp_dls_eventr_top is

--component ila_0
--
--    port (
--      clk     : in  std_logic;
--      probe0  : in  std_logic_vector(0 downto 0);
--      probe1  : in  std_logic_vector(0 downto 0);
--      probe2  : in  std_logic_vector(0 downto 0);
--      probe3  : in  std_logic_vector(0 downto 0);
--      probe4  : in  std_logic_vector(1 downto 0);
--      probe5  : in  std_logic_vector(1 downto 0);
--      probe6  : in  std_logic_vector(15 downto 0);
--      probe7  : in  std_logic_vector(0 downto 0);
--      probe8  : in  std_logic_vector(0 downto 0);
--      probe9  : in  std_logic_vector(0 downto 0);
--      probe10 : in  std_logic_vector(15 downto 0);
--      probe11 : in  std_logic_vector(1 downto 0);
--      probe12 : in  std_logic_vector(15 downto 0)
--    );
--
--end component;

signal rxn_i                 : std_logic;
signal rxp_i                 : std_logic;
signal txn_o                 : std_logic;
signal txp_o                 : std_logic;
signal mgt_ready_o           : std_logic;
signal event_clk             : std_logic;
signal rx_link_ok_o          : std_logic;
signal loss_lock_o           : std_logic;
signal rx_error_o            : std_logic;
signal rxcharisk             : std_logic_vector(1 downto 0);
signal rxdisperr             : std_logic_vector(1 downto 0);
signal rxdata                : std_logic_vector(15 downto 0);
signal LINKUP                : std_logic_vector(31 downto 0);
signal rxnotintable          : std_logic_vector(1 downto 0);
signal event_reset           : std_logic;
signal rxbyteisaligned_o     : std_logic;
signal rxbyterealign_o       : std_logic;
signal rxcommadet_o          : std_logic;
signal rxoutclk              : std_logic;
signal EVENT1_WSTB           : std_logic;
signal EVENT2_WSTB           : std_logic;
signal EVENT3_WSTB           : std_logic;
signal EVENT4_WSTB           : std_logic;
signal EVENT1                : std_logic_vector(31 downto 0);
signal EVENT2                : std_logic_vector(31 downto 0);
signal EVENT3                : std_logic_vector(31 downto 0);
signal EVENT4                : std_logic_vector(31 downto 0);
signal txdata_i              : std_logic_vector(15 downto 0);
signal txcharisk_i           : std_logic_vector(1 downto 0);
signal bit1,bit2,bit3,bit4   : std_logic;


-- ILA stuff
---signal mgt_ready_slv         : std_logic_vector(0 downto 0);
--signal rx_link_ok_slv        : std_logic_vector(0 downto 0);
--signal rxbyteisaligned_slv   : std_logic_vector(0 downto 0);
--signal rxbyterealign_slv     : std_logic_vector(0 downto 0);
--signal rxcommadet_slv        : std_logic_vector(0 downto 0);
--signal probe10_slv           : std_logic_vector(15 downto 0);
--signal probe12_slv           : std_logic_vector(15 downto 0);

signal err_cnt               : std_logic_vector(15 downto 0);

begin

bit1_o <= bit1;
bit2_o <= bit2;
bit3_o <= bit3;
bit4_o <= bit4;

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY_i     => RD_ADDR2ACK
);


-- MGT RX
rxn_i <= RXN_IN(0);
rxp_i <= RXP_IN(0);

-- MGT TX
TXN_OUT(0) <= txn_o;
TXP_OUT(0) <= txp_o;

-- Unused MGT TX's
TXN_OUT(1 downto 2) <= (others => '0');
TXP_OUT(1 downto 2) <= (others => '0');

-- Event Receiver clock buffer
rxoutclk_bufg : BUFG
port map(
    O => event_clk,
    I => rxoutclk
);


sfp_mmcm_clkmux_inst: entity work.sfp_mmcm_clkmux
generic map (no_ibufg    => 0)

port map(
    fclk_clk0_ps_i      => fclk_clk0_ps_i,
    EXTCLK_P            => EXTCLK_P,
    EXTCLK_N            => EXTCLK_N,
    rxoutclk_i          => rxoutclk,
    ext_clock_i         => ext_clock_i,
    sma_pll_locked_o    => sma_pll_locked_o,
    fclk_clk0_o         => fclk_clk0_o
);


sfp_transmitter_inst: entity work.sfp_transmitter
port map(
     event_clk_i    => event_clk,
     reset_i        => reset_i,
     rx_link_ok_i   => rx_link_ok_o,
     loss_lock_i    => loss_lock_o,
     rx_error_i     => rx_error_o,
     mgt_ready_i    => mgt_ready_o,
     rxdata_i       => rxdata,
     err_cnt_o      => err_cnt,
     txdata_o       => txdata_i,
     txcharisk_o    => txcharisk_i
);


sfp_receiver_inst: entity work.sfp_receiver
port map(
    clk_i           => clk_i,
    event_clk_i     => event_clk,
    reset_i         => reset_i,
    rxdisperr_i     => rxdisperr,
    rxcharisk_i     => rxcharisk,
    rxdata_i        => rxdata,
    rxnotintable_i  => rxnotintable,
    EVENT1          => EVENT1,
    EVENT1_WSTB     => EVENT1_WSTB,
    EVENT2          => EVENT2,
    EVENT2_WSTB     => EVENT2_WSTB,
    EVENT3          => EVENT3,
    EVENT3_WSTB     => EVENT3_WSTB,
    EVENT4          => EVENT4,
    EVENT4_WSTB     => EVENT4_WSTB,
    bit1_o          => bit1,
    bit2_o          => bit2,
    bit3_o          => bit3,
    bit4_o          => bit4,
    rx_link_ok_o    => rx_link_ok_o,
    loss_lock_o     => loss_lock_o,
    rx_error_o      => rx_error_o
);


sfpgtx_event_receiver_inst: entity work.sfp_event_receiver
port map(
    GTREFCLK_P         => GTREFCLK_P,
    GTREFCLK_N         => GTREFCLK_N,
    event_reset_i      => EVENT_RESET,
    event_clk_i        => event_clk,
    rxp_i              => rxp_i,
    rxn_i              => rxn_i,
    txp_o              => txp_o,
    txn_o              => txn_o,
    rx_link_ok_i       => rx_link_ok_o,
    rxbyteisaligned_o  => rxbyteisaligned_o,
    rxbyterealign_o    => rxbyterealign_o,
    rxcommadet_o       => rxcommadet_o,
    rxdata_o           => rxdata,
    rxoutclk_o         => rxoutclk,
    rxcharisk_o        => rxcharisk,
    rxdisperr_o        => rxdisperr,
    mgt_ready_o        => mgt_ready_o,
    rxnotintable_o     => rxnotintable,
    txdata_i           => txdata_i,
    txcharisk_i        => txcharisk_i
);


--mgt_ready_slv(0) <= mgt_ready_o;
--rx_link_ok_slv(0) <= rx_link_ok_o;
--rxbyteisaligned_slv(0) <= rxbyteisaligned_o;
--rxbyterealign_slv(0) <= rxbyterealign_o;
--rxcommadet_slv(0) <= rxcommadet_o;

--probe10_slv(3 downto 0) <= bit4 & bit3 & bit2 & bit1;
--probe10_slv(6 downto 4) <= (others => '0');
--probe10_slv(15 downto 7) <= EVENT1(8 downto 0);
--probe12_slv <= (others => '0');

--ila_inst : ila_0
--port map (
--      clk     => clk_i,
--      probe0  => mgt_ready_slv and rx_link_ok_slv,
--      probe1  => rx_link_ok_slv,
--      probe2  => mgt_ready_slv,
--      probe3  => "0",
--      probe4  => rxdisperr,
--      probe5  => rxnotintable,
--      probe6  => rxdata,
--      probe7  => rxbyteisaligned_slv,
--      probe8  => rxbyterealign_slv,
--      probe9  => rxcommadet_slv,
--      probe10 => probe10_slv,
--    probe11 => rxcharisk,
--      probe12 => probe12_slv
--);

-- MGT ready and link is up
LINKUP(0) <= mgt_ready_o and rx_link_ok_o;
---- Link is up
--LINKUP(1) <= rx_link_ok_o;
---- MGT ready
--LINKUP(2) <= mgt_ready_o;
-- Unused bits
LINKUP(31 downto 1 ) <= (others => '0');

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
sfp_ctrl : entity work.sfp_dls_eventr_ctrl
port map (
    -- Clock and Reset
    clk_i             => clk_i,
    reset_i           => reset_i,
    bit_bus_i         => (others => '0'),
    pos_bus_i         => (others => (others => '0')),

    LINKUP            => LINKUP,
    EVENT_RESET       => open,
    EVENT_RESET_WSTB  => EVENT_RESET,
    EVENT1            => EVENT1,
    EVENT1_WSTB       => EVENT1_WSTB,
    EVENT2            => EVENT2,
    EVENT2_WSTB       => EVENT2_WSTB,
    EVENT3            => EVENT3,
    EVENT3_WSTB       => EVENT3_WSTB,
    EVENT4            => EVENT4,
    EVENT4_WSTB       => EVENT4_WSTB,

    -- Memory Bus Interface
    read_strobe_i     => read_strobe_i,
    read_address_i    => read_address_i(BLK_AW-1 downto 0),
    read_data_o       => read_data_o,
    read_ack_o        => open,

    write_strobe_i    => write_strobe_i,
    write_address_i   => write_address_i(BLK_AW-1 downto 0),
    write_data_i      => write_data_i,
    write_ack_o       => open
);

end rtl;

