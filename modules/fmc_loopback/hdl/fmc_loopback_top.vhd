--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : FMC Loopback Design exercised all LA lines and GTX on the LPC
--                connector.
--
--                This module must be used with Whizz Systems FMC Loopback card
--                where LA[16:0] are outputs, and loopbacked to LA[33:17] as 
--                inputs.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity fmc_loopback_top is
port (
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Standard FMC Block ports, do not add to or delete
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bitbus_i            : in  std_logic_vector(127 downto 0);
    posbus_i            : in  std32_array(31 downto 0);
    -- Generic Inputs to BitBus and PosBus from FMC and SFP
    fmc_inputs_o        : out std_logic_vector(15 downto 0) := (others=>'0');
    fmc_data_o          : out std32_array(15 downto 0) := (others => (others => '0'));
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    FMC_interface       : inout fmc_interface
);
end fmc_loopback_top;

architecture rtl of fmc_loopback_top is

signal probe0               : std_logic_vector(31 downto 0);
signal clock_en             : std_logic;
signal fmc_din_p            : std_logic_vector(16 downto 0);
signal fmc_din_n            : std_logic_vector(16 downto 0);
signal fmc_din_p_pad        : std_logic_vector(16 downto 0);
signal fmc_din_n_pad        : std_logic_vector(16 downto 0);
signal la_p_compare         : std_logic_vector(16 downto 0);
signal la_n_compare         : std_logic_vector(16 downto 0);
signal test_clocks          : std_logic_vector(3 downto 0);
signal LINK_UP              : std_logic_vector(31 downto 0);
signal ERROR_COUNT          : std_logic_vector(31 downto 0);
signal LA_P_ERROR           : std_logic_vector(31 downto 0);
signal LA_N_ERROR           : std_logic_vector(31 downto 0);
signal FMC_CLK0_M2C         : std_logic;
signal FMC_CLK1_M2C         : std_logic;
signal FREQ_VAL             : std32_array(3 downto 0);
signal GTREFCLK             : std_logic;
signal FMC_PRSNT_DW         : std_logic_vector(31 downto 0);
signal SOFT_RESET           : std_logic;
signal LOOP_PERIOD_WSTB     : std_logic;
signal LOOP_PERIOD          : std_logic_vector(31 downto 0);

signal pbrs_data            : std_logic_vector(16 downto 0) := X"5555"&'0';
signal pbrs_data_prev       : std_logic_vector(16 downto 0);

attribute MARK_DEBUG        : string;
attribute MARK_DEBUG of probe0  : signal is "true";

attribute IOB               : string;
attribute IOB of pbrs_data  : signal is "true";
attribute IOB of fmc_din_p  : signal is "true";
attribute IOB of fmc_din_n  : signal is "true";

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY       => RD_ADDR2ACK
);

-- Multiplex read data out from multiple instantiations

-- Generate prescaled clock for internal counter
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => LOOP_PERIOD_WSTB,
    PERIOD      => LOOP_PERIOD,
    pulse_o     => clock_en
);

-- Bottom half is output
FMC_interface.FMC_LA_P(16 downto 0) <= pbrs_data;
FMC_interface.FMC_LA_N(16 downto 0) <= pbrs_data;

-- Upper half is input
FMC_interface.FMC_LA_P(33 downto 17) <= (others => 'Z');
FMC_interface.FMC_LA_N(33 downto 17) <= (others => 'Z');
fmc_din_p_pad <= FMC_interface.FMC_LA_P(33 downto 17);
fmc_din_n_pad <= FMC_interface.FMC_LA_N(33 downto 17);


---------------------------------------------------------------------------
-- LA Pins loopback Test
---------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Register and pack into IOB
        fmc_din_p <= fmc_din_p_pad;
        fmc_din_n <= fmc_din_n_pad;

        pbrs_data_prev <= pbrs_data;

        -- Relax loopback timing for signal travelling out and back in.
        if (clock_en = '1') then
            -- Shift test pattern
            pbrs_data <= pbrs_data(15 downto 0) & pbrs_data(16);
            -- Comparator on LA lines individually, and set '1' for un-matching
            -- bits.
            la_p_compare <= fmc_din_p xor pbrs_data_prev;
            la_n_compare <= fmc_din_n xor pbrs_data_prev;
        end if;
    end if;
end process;

LA_P_ERROR <= ZEROS(15) & la_p_compare;
LA_N_ERROR <= ZEROS(15) & la_n_compare;

---------------------------------------------------------------------------
-- GTX Loopback Test
---------------------------------------------------------------------------
fmcgtx_exdes_i : entity work.fmcgtx_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN   => FMC_interface.GTREFCLK,
    GTREFCLK                    => GTREFCLK,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP,
    ERROR_COUNT                 => ERROR_COUNT,
    RXN_IN                      => FMC_interface.RXN_IN,
    RXP_IN                      => FMC_interface.RXP_IN,
    TXN_OUT                     => FMC_interface.TXN_OUT,
    TXP_OUT                     => FMC_interface.TXP_OUT
);

---------------------------------------------------------------------------
-- FMC Mezzanine Clocks
---------------------------------------------------------------------------
IBUFGDS_CLK0 : IBUFGDS
generic map (
    DIFF_TERM   => TRUE,
    IOSTANDARD  => "LVDS"
)
port map (
    O           => FMC_CLK0_M2C,
    I           => FMC_interface.FMC_CLK0_M2C_P,
    IB          => FMC_interface.FMC_CLK0_M2C_N
);

IBUFGDS_CLK1 : IBUFGDS
generic map (
    DIFF_TERM   => TRUE,
    IOSTANDARD  => "LVDS"
)
port map (
    O           => FMC_CLK1_M2C,
    I           => FMC_interface.FMC_CLK1_M2C_P,
    IB          => FMC_interface.FMC_CLK1_M2C_N
);

---------------------------------------------------------------------------
-- FMC Clocks Frequency Counter
---------------------------------------------------------------------------

test_clocks(0) <= GTREFCLK;
test_clocks(1) <= FMC_CLK0_M2C;
test_clocks(2) <= FMC_CLK1_M2C;
test_clocks(3) <= FMC_interface.EXTCLK;

freq_counter_inst : entity work.freq_counter
generic map ( NUM => 4)
port map (
    refclk          => clk_i,
    reset           => reset_i,
    test_clocks     => test_clocks,
    freq_out        => FREQ_VAL
);

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
FMC_PRSNT_DW <= ZEROS(31) & FMC_interface.FMC_PRSNT;

fmc_ctrl : entity work.fmc_loopback_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i            => (others => '0'),
    pos_bus_i            => (others => (others => '0')),
    -- Block Parameters
    FMC_PRSNT           => FMC_PRSNT_DW,
    LINK_UP             => LINK_UP,
    ERROR_COUNT         => ERROR_COUNT,
    LA_P_ERROR          => LA_P_ERROR,
    LA_N_ERROR          => LA_N_ERROR,
    GTREFCLK            => FREQ_VAL(0),
    FMC_CLK0            => FREQ_VAL(1),
    FMC_CLK1            => FREQ_VAL(2),
    EXT_CLK             => FREQ_VAL(3),
    SOFT_RESET          => open,
    SOFT_RESET_WSTB     => SOFT_RESET,
    LOOP_PERIOD         => LOOP_PERIOD,
    LOOP_PERIOD_WSTB    => LOOP_PERIOD_WSTB,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data_o,
    read_ack_o          => open,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open
);

end rtl;

