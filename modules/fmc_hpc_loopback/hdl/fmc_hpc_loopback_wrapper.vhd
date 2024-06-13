--------------------------------------------------------------------------------
--      NAMC - 2020
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Arthur Mariano, Shu ZHANG
--------------------------------------------------------------------------------
--
--  Description : FMC High Pin Count Loopback Design exercised all LA lines and HA/HB lines and GTX[3:0].
--
--                This module must be used with Whizz Systems FMC Loopback card
--                where LA[16:0] are outputs, and loopbacked to LA[33:17] as
--                input / where HA[21:0] are outputs and loopbacked to HB[21:0] as input.
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

entity fmc_hpc_loopback_wrapper is
port (
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Standard FMC Block ports, do not add to or delete
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    FMC_i               : in  fmc_input_interface;
    FMC_io              : inout fmc_inout_interface;
    FMC_o               : out fmc_output_interface
);
end fmc_hpc_loopback_wrapper;

architecture rtl of fmc_hpc_loopback_wrapper is
signal probe0               : std_logic_vector(31 downto 0);
signal clock_en             : std_logic;
signal fmc_din_p            : std_logic_vector(16 downto 0);
signal fmc_din_n            : std_logic_vector(16 downto 0);
signal fmc_din_p_hpc        : std_logic_vector(21 downto 0);
signal fmc_din_n_hpc        : std_logic_vector(21 downto 0);
signal fmc_din_p_pad        : std_logic_vector(16 downto 0);
signal fmc_din_n_pad        : std_logic_vector(16 downto 0);
signal fmc_din_p_pad_hpc    : std_logic_vector(21 downto 0);
signal fmc_din_n_pad_hpc    : std_logic_vector(21 downto 0);
signal la_p_compare         : std_logic_vector(16 downto 0);
signal la_n_compare         : std_logic_vector(16 downto 0);
signal hab_p_compare        : std_logic_vector(21 downto 0);
signal hab_n_compare        : std_logic_vector(21 downto 0);
signal test_clocks          : std_logic_vector(3 downto 0);
signal LINK_UP              : std32_array(3 downto 0);
signal ERROR_COUNT          : std32_array(3 downto 0);

signal LA_P_ERROR           : std_logic_vector(31 downto 0);
signal LA_N_ERROR           : std_logic_vector(31 downto 0);
signal HAB_P_ERROR          : std_logic_vector(31 downto 0);
signal HAB_N_ERROR          : std_logic_vector(31 downto 0);
signal FMC_CLK0_M2C         : std_logic;
signal FMC_CLK1_M2C         : std_logic;
signal FREQ_VAL             : std32_array(3 downto 0);
signal GTREFCLK             : std_logic;
signal FMC_PRSNT_DW         : std_logic_vector(31 downto 0);
signal SOFT_RESET           : std_logic;
signal LOOP_PERIOD_WSTB     : std_logic;
signal LOOP_PERIOD          : std_logic_vector(31 downto 0);
signal HB_INIT              : std_logic_vector(31 downto 0);
signal HB_INIT_WSTB         : std_logic;

signal pbrs_data            : std_logic_vector(16 downto 0) := X"5AF3"&'1';
signal pbrs_data_prev       : std_logic_vector(16 downto 0);
signal pbrs_data_hpc        : std_logic_vector(21 downto 0) := X"FB8F2"&"01";
signal pbrs_data_prev_hpc   : std_logic_vector(21 downto 0);

attribute MARK_DEBUG        : string;
attribute MARK_DEBUG of probe0  : signal is "true";

attribute IOB               : string;
attribute IOB of pbrs_data  : signal is "true";
attribute IOB of fmc_din_p  : signal is "true";
attribute IOB of fmc_din_n  : signal is "true";

signal TXN                  : std_logic_vector(3 downto 0);
signal TXP                  : std_logic_vector(3 downto 0);

begin

txobuf: for i in 0 to 3 generate 
    txnobuf: obuf
    port map (
        I => TXN(i),
        O => FMC_o.TXN_OUT(i)
    );

    txpobuf : obuf
    port map (
        I => TXP(i),
        O => FMC_o.TXP_OUT(i)
    );
end generate txobuf;

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
FMC_io.FMC_LA_P(16 downto 0) <= pbrs_data;
FMC_io.FMC_LA_N(16 downto 0) <= pbrs_data;
FMC_io.FMC_HA_P(21 downto 0) <= pbrs_data_hpc;
FMC_io.FMC_HA_N(21 downto 0) <= pbrs_data_hpc;

-- Upper half is input
fmc_din_p_pad     <= FMC_io.FMC_LA_P(33 downto 17);
fmc_din_n_pad     <= FMC_io.FMC_LA_N(33 downto 17);
fmc_din_p_pad_hpc <= FMC_io.FMC_HB_P(21 downto 0);
fmc_din_n_pad_hpc <= FMC_io.FMC_HB_N(21 downto 0);

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
            pbrs_data(16 downto 0) <= pbrs_data(15 downto 0) & pbrs_data(16);
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
-- HA/HB Pins loopback Test
---------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Register and pack into IOB
        fmc_din_p_hpc <= fmc_din_p_pad_hpc;
        fmc_din_n_hpc <= fmc_din_n_pad_hpc;

        pbrs_data_prev_hpc   <= pbrs_data_hpc;
        hab_p_compare <= fmc_din_p_hpc xor pbrs_data_prev_hpc;
        hab_n_compare <= fmc_din_n_hpc xor pbrs_data_prev_hpc;
        
        -- Relax loopback timing for signal travelling out and back in.
        if (clock_en = '1') then
            -- Shift test pattern
            pbrs_data_hpc <= HB_INIT(21 downto 0);
            ---pbrs_data_hpc <= pbrs_data_hpc(20 downto 0) & pbrs_data_hpc(21);
            -- Comparator on LA lines individually, and set '1' for un-matching
            -- bits.
            
        end if;
    end if;
end process;

HAB_P_ERROR <= ZEROS(10) & hab_p_compare;
HAB_N_ERROR <= ZEROS(10) & hab_n_compare;

---------------------------------------------------------------------------
-- GTX Loopback Test
---------------------------------------------------------------------------
fmcgtx_exdes_i0: entity work.fmcgtx_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => FMC_i.GTREFCLK(0),
    GTREFCLK                    => GTREFCLK,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP(0),
    ERROR_COUNT                 => ERROR_COUNT(0),
    RXP_IN                      => FMC_i.RXP_IN(0),
    RXN_IN                      => FMC_i.RXN_IN(0),
    TXP_OUT                     => TXP(0),
    TXN_OUT                     => TXN(0)
);

fmcgtx_exdes_i1_3: for i in 1 to 3 generate
    fmcgtx_exdes: entity work.fmcgtx_exdes
    port map (
        Q0_CLK1_GTREFCLK_PAD_IN     => FMC_i.GTREFCLK(0),
        GTREFCLK                    => open,
        drpclk_in_i                 => clk_i,
        SOFT_RESET                  => SOFT_RESET,
        TRACK_DATA_OUT              => LINK_UP(i),
        ERROR_COUNT                 => ERROR_COUNT(i),
        RXP_IN                      => FMC_i.RXP_IN(i),
        RXN_IN                      => FMC_i.RXN_IN(i),
        TXP_OUT                     => TXP(i),
        TXN_OUT                     => TXN(i)
    );
end generate fmcgtx_exdes_i1_3;

---------------------------------------------------------------------------
-- FMC Mezzanine Clocks
---------------------------------------------------------------------------
ibufds_instq0_clk0_fmc: IBUFDS_GTE2
port map(
    O               =>      FMC_CLK0_M2C,
    ODIV2           =>      open,
    CEB             =>      '0',
    I               =>      FMC_io.FMC_CLK0_M2C_P,
    IB              =>      FMC_io.FMC_CLK0_M2C_N
);

ibufds_instq0_clk1_fmc: IBUFDS_GTE2
port map(
    O               =>      FMC_CLK1_M2C,
    ODIV2           =>      open,
    CEB             =>      '0',
    I               =>      FMC_i.FMC_CLK1_M2C_P,
    IB              =>      FMC_i.FMC_CLK1_M2C_N
);
---------------------------------------------------------------------------
-- FMC Clocks Frequency Counter
---------------------------------------------------------------------------
test_clocks(0) <= GTREFCLK; --125MHz
test_clocks(1) <= FMC_CLK0_M2C;
test_clocks(2) <= FMC_CLK1_M2C;
test_clocks(3) <= FMC_i.EXTCLK;

freq_counter_inst: entity work.freq_counter
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
FMC_PRSNT_DW <= ZEROS(31) & FMC_i.FMC_PRSNT;

fmc_ctrl: entity work.fmc_hpc_loopback_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i            => bit_bus_i,
    pos_bus_i            => pos_bus_i,
    -- Block Parameters
    FMC_PRSNT           => FMC_PRSNT_DW,
    LINK_UP_1           => LINK_UP(0),
    LINK_UP_2           => LINK_UP(1),
    LINK_UP_3           => LINK_UP(2),
    LINK_UP_4           => LINK_UP(3),
    ERROR_COUNT_1       => ERROR_COUNT(0),
    ERROR_COUNT_2       => ERROR_COUNT(1),
    ERROR_COUNT_3       => ERROR_COUNT(2),
    ERROR_COUNT_4       => ERROR_COUNT(3),
    LA_P_ERROR          => LA_P_ERROR,
    LA_N_ERROR          => LA_N_ERROR,
    HAB_P_ERROR         => HAB_P_ERROR,
    HAB_N_ERROR         => HAB_N_ERROR,
    GTREFCLK            => FREQ_VAL(0),
    FMC_CLK0            => FREQ_VAL(1),
    FMC_CLK1            => FREQ_VAL(2),
    EXT_CLK             => FREQ_VAL(3),
    SOFT_RESET          => open,
    SOFT_RESET_WSTB     => SOFT_RESET,
    LOOP_PERIOD         => LOOP_PERIOD,
    LOOP_PERIOD_WSTB    => LOOP_PERIOD_WSTB,
    HB_INIT             => HB_INIT,
    HB_INIT_WSTB        => HB_INIT_WSTB,
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

