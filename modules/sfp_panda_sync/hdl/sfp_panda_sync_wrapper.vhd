library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.top_defines.all;
use work.interface_types.all;

library unisim;
use unisim.vcomponents.all;


entity sfp_panda_sync_wrapper is
    port (
        clk_i            : in  std_logic;
        reset_i          : in  std_logic;
        bit_bus_i        : in  bit_bus_t;
        pos_bus_i        : in  pos_bus_t;
        -- Data Out
        IN_BIT1_o         : out std_logic_vector(0 downto 0);
        IN_BIT2_o         : out std_logic_vector(0 downto 0);
        IN_BIT3_o         : out std_logic_vector(0 downto 0);
        IN_BIT4_o         : out std_logic_vector(0 downto 0);
        IN_BIT5_o         : out std_logic_vector(0 downto 0);
        IN_BIT6_o         : out std_logic_vector(0 downto 0);
        IN_BIT7_o         : out std_logic_vector(0 downto 0);
        IN_BIT8_o         : out std_logic_vector(0 downto 0);
        IN_POS1_o         : out std32_array(0 downto 0);
        IN_POS2_o         : out std32_array(0 downto 0);
        IN_POS3_o         : out std32_array(0 downto 0);
        IN_POS4_o         : out std32_array(0 downto 0);
        -- Memory Bus Interface
        -- Read 
        read_strobe_i    : in  std_logic;
        read_address_i   : in  std_logic_vector(PAGE_AW-1 downto 0);
        read_data_o      : out std_logic_vector(31 downto 0);
        read_ack_o       : out std_logic;
        -- Write
        write_strobe_i   : in  std_logic;
        write_address_i  : in  std_logic_vector(PAGE_AW-1 downto 0);
        write_data_i     : in  std_logic_vector(31 downto 0);
        write_ack_o      : out std_logic;

        MGT              : view MGT_Module
        );
end sfp_panda_sync_wrapper;


architecture rtl of sfp_panda_sync_wrapper is

signal rx_link_ok         : std_logic;
signal rxoutclk           : std_logic;
signal txoutclk           : std_logic;
signal rxdata             : std_logic_vector(31 downto 0); 
signal rxcharisk          : std_logic_vector(3 downto 0); 
signal rxdisperr          : std_logic_vector(3 downto 0); 
signal mgt_ready          : std_logic;
signal rxnotintable       : std_logic_vector(3 downto 0);
signal txdata             : std_logic_vector(31 downto 0);
signal txcharisk          : std_logic_vector(3 downto 0);
signal POSIN1             : std_logic_vector(31 downto 0); 
signal POSIN2             : std_logic_vector(31 downto 0);
signal POSIN3             : std_logic_vector(31 downto 0);  
signal POSIN4             : std_logic_vector(31 downto 0);  
signal BITIN              : std_logic_vector(7 downto 0);  
signal BITOUT1            : std_logic;  
signal BITOUT2            : std_logic;  
signal BITOUT3            : std_logic;  
signal BITOUT4            : std_logic;  
signal BITOUT5            : std_logic;  
signal BITOUT6            : std_logic;  
signal BITOUT7            : std_logic;  
signal BITOUT8            : std_logic;  
signal POSOUT1            : std_logic_vector(31 downto 0);
signal POSOUT2            : std_logic_vector(31 downto 0);
signal POSOUT3            : std_logic_vector(31 downto 0);
signal POSOUT4            : std_logic_vector(31 downto 0);
signal BITOUT             : std_logic_vector(7 downto 0);
signal LINKUP             : std_logic_vector(31 downto 0);
signal SYNC_RESET         : std_logic;
signal MGT_RESET          : std_logic;
signal TXN                : std_logic;
signal TXP                : std_logic;
signal health             : std_logic_vector(31 downto 0);
signal rx_error           : std_logic;
signal err_cnt            : std_logic_vector(31 downto 0);
signal err_cnt_smpld      : std_logic_vector(31 downto 0);
signal ctr_rst_sync       : std_logic;

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

MGT.MGT_REC_CLK <= rxoutclk;
MGT.LINK_UP <= LINKUP(0);

IN_BIT8_o(0) <= BITIN(7);
IN_BIT7_o(0) <= BITIN(6);
IN_BIT6_o(0) <= BITIN(5);
IN_BIT5_o(0) <= BITIN(4);
IN_BIT4_o(0) <= BITIN(3);
IN_BIT3_o(0) <= BITIN(2);
IN_BIT2_o(0) <= BITIN(1);
IN_BIT1_o(0) <= BITIN(0);

-- Transmitter 
-- The transmit side transmits regardless of the state of the receiver rx_link_ok signal 
-- txoutclk is the clock used for the TX side
sfp_panda_sync_transmitter_inst : entity work.sfp_panda_sync_transmit

    port map (
        sysclk_i          => clk_i,
        txoutclk_i        => txoutclk,
        txcharisk_o       => txcharisk,
        txdata_o          => txdata,
        POSOUT1_i         => POSOUT1,
        POSOUT2_i         => POSOUT2,
        POSOUT3_i         => POSOUT3,
        POSOUT4_i         => POSOUT4,
        BITOUT_i          => BITOUT
        );

-- Receiver
-- Will not start until the data has been aligned and first packet has been received
-- rxoutclk is the clock used for the RX side  
sfp_panda_sync_receiver_inst : entity work.sfp_panda_sync_receiver

    port map (
        sysclk_i          => clk_i,
        reset_i           => SYNC_RESET,
        rxoutclk_i        => rxoutclk,
        rxdisperr_i       => rxdisperr,
        rxcharisk_i       => rxcharisk,
        rxdata_i          => rxdata,
        rxnotintable_i    => rxnotintable,
        rx_link_ok_o      => rx_link_ok,
        rx_error_o        => rx_error,
        BITIN_o           => BITIN,
        POSIN1_o          => IN_POS1_o(0),
        POSIN2_o          => IN_POS2_o(0),
        POSIN3_o          => IN_POS3_o(0),
        POSIN4_o          => IN_POS4_o(0),
        health_o          => health
        );

-- Synchronise SYNC_RESET onto rxoutclk domain

rst_sync: entity work.pulse2pulse
port map(
    in_clk => clk_i,
    out_clk => rxoutclk,
    rst => '0',
    pulsein => SYNC_RESET,
    inbusy  => open,
    pulseout => ctr_rst_sync
);

-- RX error counter (on rx domain) and timed (latched) synchroniser to sysclk

err_ctr : process(rxoutclk)
    variable err_cnt_u :unsigned(31 downto 0);
begin
    if rising_edge(rxoutclk) then
        if ctr_rst_sync = '1' then
            err_cnt_u := (others => '0');
        elsif rx_error = '1' then
            err_cnt_u := err_cnt_u + 1;
        end if;
        err_cnt <= std_logic_vector(err_cnt_u);
    end if;
end process;

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

-- MGT interface
sfp_panda_sync_mgt_interface_inst : entity work.sfp_panda_sync_mgt_interface

    port map(
        GTREFCLK_i        => MGT.GTREFCLK,
        SYNC_RESET_i      => SYNC_RESET,
        MGT_RESET_i       => MGT_RESET,
        sysclk_i          => clk_i,
        rxp_i             => MGT.RXP_IN,
        rxn_i             => MGT.RXN_IN,
        txp_o             => TXP,
        txn_o             => TXN,
        rxdata_o          => rxdata,
        rxoutclk_o        => rxoutclk,            -- RX recovered clock
        rxcharisk_o       => rxcharisk,
        rxdisperr_o       => rxdisperr,
        mgt_ready_o       => mgt_ready,
        rxnotintable_o    => rxnotintable,
        txoutclk_o        => txoutclk,            -- TX reference clock
        txdata_i          => txdata,
        txcharisk_i       => txcharisk,
        rx_link_ok_i      => rx_link_ok
        );


-- Make a vector out of all the bits from the bit bus
BITOUT <= BITOUT8  & BITOUT7  & BITOUT6  & BITOUT5  & BITOUT4  & BITOUT3  & BITOUT2  & BITOUT1;

-- Link up and MGT ready
LINKUP(0) <= mgt_ready and rx_link_ok;
LINKUP(31 downto 1) <= (others => '0');

sfp_panda_sync_ctrl_inst : entity work.sfp_panda_sync_ctrl
    port map (
        -- Clock and Reset
        clk_i               => clk_i,
        reset_i             => reset_i,
        bit_bus_i           => bit_bus_i,
        pos_bus_i           => pos_bus_i,
        -- Block Parameters
        IN_LINKUP           => LINKUP,
        IN_SYNC_RESET       => open,
        IN_SYNC_RESET_wstb  => SYNC_RESET,
        IN_HEALTH           => health,
        IN_ERR_CNT          => err_cnt_smpld,
        OUT_MGT_RESET       => open,
        OUT_MGT_RESET_wstb  => MGT_RESET,
        OUT_BIT1_from_bus   => BITOUT1,
        OUT_BIT2_from_bus   => BITOUT2,
        OUT_BIT3_from_bus   => BITOUT3,
        OUT_BIT4_from_bus   => BITOUT4,
        OUT_BIT5_from_bus   => BITOUT5,
        OUT_BIT6_from_bus   => BITOUT6,
        OUT_BIT7_from_bus   => BITOUT7,
        OUT_BIT8_from_bus   => BITOUT8,
        OUT_POS1_from_bus   => POSOUT1,
        OUT_POS2_from_bus   => POSOUT2,
        OUT_POS3_from_bus   => POSOUT3,
        OUT_POS4_from_bus   => POSOUT4,
        -- Memory Bus Interface
        read_strobe_i       => read_strobe_i,
        read_address_i      => read_address_i(BLK_AW-1 downto 0),
        read_data_o         => read_data_o,
        read_ack_o          => read_ack_o,

        write_strobe_i      => write_strobe_i,
        write_address_i     => write_address_i(BLK_AW-1 downto 0),
        write_data_i        => write_data_i,
        write_ack_o         => write_ack_o
        );

end rtl;

