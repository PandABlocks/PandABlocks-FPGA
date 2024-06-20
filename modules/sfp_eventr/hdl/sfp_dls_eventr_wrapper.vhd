library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.interface_types.all;

library unisim;
use unisim.vcomponents.all;

entity sfp_dls_eventr_wrapper is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- System Bus
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Outputs to BitBus from FMC
    bit1_o              : out std_logic_vector(0 downto 0);
    bit2_o              : out std_logic_vector(0 downto 0);
    bit3_o              : out std_logic_vector(0 downto 0);
    bit4_o              : out std_logic_vector(0 downto 0);
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;

    MGT                 : view MGT_Module
);
end sfp_dls_eventr_wrapper;

architecture rtl of sfp_dls_eventr_wrapper is

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

signal mgt_ready_o           : std_logic;
signal rx_link_ok_o          : std_logic;
signal rx_link_ok_sync       : std_logic;
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
signal txoutclk              : std_logic;
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

signal unix_time             : std_logic_vector(31 downto 0);
signal unix_time_ticks       : std_logic_vector(31 downto 0);
signal err_cnt_smpld         : std_logic_vector(31 downto 0);

-- ILA stuff
---signal mgt_ready_slv         : std_logic_vector(0 downto 0);
--signal rx_link_ok_slv        : std_logic_vector(0 downto 0);
--signal rxbyteisaligned_slv   : std_logic_vector(0 downto 0);
--signal rxbyterealign_slv     : std_logic_vector(0 downto 0);
--signal rxcommadet_slv        : std_logic_vector(0 downto 0);
--signal probe10_slv           : std_logic_vector(15 downto 0);
--signal probe12_slv           : std_logic_vector(15 downto 0);

signal err_cnt              : std_logic_vector(31 downto 0);

signal TXN, TXP             : std_logic;

signal cpll_lock            : std_logic_vector(31 downto 0);

begin

txnobuf : obuf
port map (
    I => TXN,
    O => MGT.TXN_OUT
);

txpobuf : obuf
port map (
    I => TXP,
    O => MGT.TXP_OUT
);

-- Assign outputs

MGT.MGT_REC_CLK <= rxoutclk;
MGT.LINK_UP <= LINKUP(0);
MGT.TS_SEC <= unix_time;
MGT.TS_TICKS <= unix_time_ticks;

bit1_o(0) <= bit1;
bit2_o(0) <= bit2;
bit3_o(0) <= bit3;
bit4_o(0) <= bit4;

sfp_transmitter_inst: entity work.sfp_transmitter
port map(
     event_clk_i    => rxoutclk,
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
    sysclk_i        => clk_i,
    event_clk_i     => rxoutclk,
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
    rx_error_o      => rx_error_o,
    utime_o         => unix_time,
    utime_ticks_o   => unix_time_ticks
);


sfpgtx_event_receiver_inst: entity work.sfp_event_receiver
port map(
    GTREFCLK           => MGT.GTREFCLK,
    sysclk_i           => clk_i,
    event_reset_i      => EVENT_RESET,
    rxp_i              => MGT.RXP_IN,
    rxn_i              => MGT.RXN_IN,
    txp_o              => TXP,
    txn_o              => TXN,
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
    txoutclk_o         => txoutclk,
    txcharisk_i        => txcharisk_i,
    cpll_lock_o        => cpll_lock(0)
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

--synchronise rx_link_ok to clk_i
rx_link_sync : entity work.sync_bit
    port map(
     clk_i => clk_i,
     bit_i => rx_link_ok_o,
     bit_o => rx_link_ok_sync
);

-- MGT ready and link is up
LINKUP(0) <= mgt_ready_o and rx_link_ok_sync;
---- Link is up
--LINKUP(1) <= rx_link_ok_o;
---- MGT ready
--LINKUP(2) <= mgt_ready_o;
-- Unused bits
LINKUP(31 downto 1 ) <= (others => '0');

--- Latched samplers for CDC signals

err_latch : entity work.latched_sync
generic map (
    DWIDTH => 32,
    PERIOD => 125  -- 1 MHz for 125 MHz clock
)
port map (
    src_clk => rxoutclk,
    dest_clk => clk_i,
    data_i => err_cnt,
    data_o => err_cnt_smpld
);

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
sfp_ctrl : entity work.sfp_dls_eventr_ctrl
port map (
    -- Clock and Reset
    clk_i             => clk_i,
    reset_i           => reset_i,
    bit_bus_i         => bit_bus_i,
    pos_bus_i         => pos_bus_i,

    LINKUP            => LINKUP,
    UNIX_TIME         => unix_time,
    ERROR_COUNT       => err_cnt_smpld,
    EVENT_RESET       => open,
    EVENT_RESET_WSTB  => EVENT_RESET,
    CPLL_LOCK         => cpll_lock,
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
    read_ack_o        => read_ack_o,

    write_strobe_i    => write_strobe_i,
    write_address_i   => write_address_i(BLK_AW-1 downto 0),
    write_data_i      => write_data_i,
    write_ack_o       => write_ack_o
);

end rtl;

