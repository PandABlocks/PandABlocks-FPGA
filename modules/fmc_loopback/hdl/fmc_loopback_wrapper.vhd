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

entity fmc_loopback_wrapper is
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
    FMC                 : view FMC_Module
);
end fmc_loopback_wrapper;

architecture rtl of fmc_loopback_wrapper is

signal clock_en             : std_logic;
signal fmc_din_p            : std_logic_vector(16 downto 0);
signal fmc_din_n            : std_logic_vector(16 downto 0);
signal fmc_din_p_pad        : std_logic_vector(16 downto 0);
signal fmc_din_n_pad        : std_logic_vector(16 downto 0);
signal la_p_compare         : std_logic_vector(16 downto 0);
signal la_n_compare         : std_logic_vector(16 downto 0);
signal test_clocks          : std_logic_vector(1 downto 0);
signal LA_P_ERROR           : std_logic_vector(31 downto 0);
signal LA_N_ERROR           : std_logic_vector(31 downto 0);
signal FMC_CLK0_M2C         : std_logic;
signal FMC_CLK1_M2C         : std_logic;
signal FREQ_VAL             : std32_array(1 downto 0);
signal FMC_PRSNT_DW         : std_logic_vector(31 downto 0);
signal LOOP_PERIOD_WSTB     : std_logic;
signal LOOP_PERIOD          : std_logic_vector(31 downto 0);

signal pbrs_data            : std_logic_vector(16 downto 0) := X"5555"&'0';
signal pbrs_data_prev       : std_logic_vector(16 downto 0);

attribute IOB               : string;
attribute IOB of pbrs_data  : signal is "true";
attribute IOB of fmc_din_p  : signal is "true";
attribute IOB of fmc_din_n  : signal is "true";

begin

-- Generate prescaled clock for internal counter
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => LOOP_PERIOD_WSTB,
    PERIOD      => LOOP_PERIOD,
    pulse_o     => clock_en
);

-- Bottom half is output
FMC.FMC_LA_P(16 downto 0) <= pbrs_data;
FMC.FMC_LA_N(16 downto 0) <= pbrs_data;

-- Upper half is input
--FMC.FMC_LA_P(33 downto 17) <= (others => 'Z');
--FMC.FMC_LA_N(33 downto 17) <= (others => 'Z');
fmc_din_p_pad <= FMC.FMC_LA_P(33 downto 17);
fmc_din_n_pad <= FMC.FMC_LA_N(33 downto 17);


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
-- FMC Mezzanine Clocks
---------------------------------------------------------------------------
IBUFGDS_CLK0 : IBUFGDS
generic map (
    DIFF_TERM   => TRUE,
    IOSTANDARD  => "LVDS"
)
port map (
    O           => FMC_CLK0_M2C,
    I           => FMC.FMC_CLK0_M2C_P,
    IB          => FMC.FMC_CLK0_M2C_N
);

IBUFGDS_CLK1 : IBUFGDS
generic map (
    DIFF_TERM   => TRUE,
    IOSTANDARD  => "LVDS"
)
port map (
    O           => FMC_CLK1_M2C,
    I           => FMC.FMC_CLK1_M2C_P,
    IB          => FMC.FMC_CLK1_M2C_N
);

---------------------------------------------------------------------------
-- FMC Clocks Frequency Counter
---------------------------------------------------------------------------

test_clocks(0) <= FMC_CLK0_M2C;
test_clocks(1) <= FMC_CLK1_M2C;

freq_counter_inst : entity work.freq_counter
generic map ( NUM => 2)
port map (
    refclk          => clk_i,
    reset           => reset_i,
    test_clocks     => test_clocks,
    freq_out        => FREQ_VAL
);

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
FMC_PRSNT_DW <= ZEROS(31) & FMC.FMC_PRSNT;

fmc_ctrl : entity work.fmc_loopback_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i            => bit_bus_i,
    pos_bus_i            => pos_bus_i,
    -- Block Parameters
    FMC_PRSNT           => FMC_PRSNT_DW,
    LA_P_ERROR          => LA_P_ERROR,
    LA_N_ERROR          => LA_N_ERROR,
    FMC_CLK0            => FREQ_VAL(0),
    FMC_CLK1            => FREQ_VAL(1),
    LOOP_PERIOD         => LOOP_PERIOD,
    LOOP_PERIOD_WSTB    => LOOP_PERIOD_WSTB,
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

