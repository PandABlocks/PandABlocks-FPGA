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

entity fmc_loopback is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- LA I/O
    FMC_PRSNT           : in    std_logic;
    FMC_LA_P            : inout std_logic_vector(33 downto 0);
    FMC_LA_N            : inout std_logic_vector(33 downto 0);
    FMC_CLK0_M2C_P      : in    std_logic;
    FMC_CLK0_M2C_N      : in    std_logic;
    FMC_CLK1_M2C_P      : in    std_logic;
    FMC_CLK1_M2C_N      : in    std_logic;
    -- GTX I/O
    TXP_OUT             : out   std_logic;
    TXN_OUT             : out   std_logic;
    RXP_IN              : in    std_logic;
    RXN_IN              : in    std_logic;
    GTREFCLK_P          : in    std_logic;
    GTREFCLK_N          : in    std_logic
);
end fmc_loopback;

architecture rtl of fmc_loopback is

signal la_counter       : unsigned(16 downto 0) := (others => '0');
signal clock_en         : std_logic;
signal fmc_din_p        : std_logic_vector(16 downto 0);
signal fmc_din_n        : std_logic_vector(16 downto 0);
signal fmc_din_p_pad    : std_logic_vector(16 downto 0);
signal fmc_din_n_pad    : std_logic_vector(16 downto 0);
signal la_p_compare     : std_logic_vector(16 downto 0);
signal la_n_compare     : std_logic_vector(16 downto 0);
signal test_clocks      : std_logic_vector(3 downto 0);
signal LINK_UP          : std_logic_vector(31 downto 0);
signal ERROR_COUNT      : std_logic_vector(31 downto 0);
signal LA_P_ERROR       : std_logic_vector(31 downto 0);
signal LA_N_ERROR       : std_logic_vector(31 downto 0);
signal FMC_CLK0_M2C     : std_logic;
signal FMC_CLK1_M2C     : std_logic;
signal FREQ_VAL         : std32_array(3 downto 0);
signal GTREFCLK         : std_logic;
signal FMC_PRSNT_DW     : std_logic_vector(31 downto 0);

begin

-- Generate prescaled clock for internal counter
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => X"0000_0004",
    pulse_o     => clock_en
);

INOUT_PADS : FOR I IN 0 TO 16 GENERATE

-- LA[16:0] are outputs
iobuf_dop : iobuf
port map (
    I  => la_counter(I),
    O  => open,
    IO => FMC_LA_P(I),
    T  => '0'
);

iobuf_don : iobuf
port map (
    I  => la_counter(I),
    O  => open,
    IO => FMC_LA_N(I),
    T  => '0'
);

-- LA[33:17] are inputs
iobuf_dip : iobuf
port map (
    I  => '0',
    O  => fmc_din_p_pad(I),
    IO => FMC_LA_P(I + 17),
    T  => '1'
);

iobuf_din : iobuf
port map (
    I  => '0',
    O  => fmc_din_n_pad(I),
    IO => FMC_LA_N(I + 17),
    T  => '1'
);

END GENERATE;

---------------------------------------------------------------------------
-- LA Pins loopback Test
---------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Register and pack into IOB
        fmc_din_n <= fmc_din_n_pad;
        fmc_din_p <= fmc_din_p_pad;

        -- Relax loopback timing for signal travelling out and back in.
        if (clock_en = '1') then
            -- Free running counter when enabled.
            la_counter <= la_counter + 1;

            -- Comparator on LA lines individually, and set '1' for un-matching
            -- bits.
            la_p_compare <= fmc_din_p xor std_logic_vector(la_counter);
            la_n_compare <= fmc_din_n xor std_logic_vector(la_counter);
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
    Q0_CLK1_GTREFCLK_PAD_N_IN   => GTREFCLK_N,
    Q0_CLK1_GTREFCLK_PAD_P_IN   => GTREFCLK_P,
    GTREFCLK                    => GTREFCLK,
    drpclk_in_i                 => clk_i,
    TRACK_DATA_OUT              => LINK_UP,
    ERROR_COUNT                 => ERROR_COUNT,
    RXN_IN                      => RXN_IN,
    RXP_IN                      => RXP_IN,
    TXN_OUT                     => TXN_OUT,
    TXP_OUT                     => TXP_OUT
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
    I           => FMC_CLK0_M2C_P,
    IB          => FMC_CLK0_M2C_N
);

IBUFGDS_CLK1 : IBUFGDS
generic map (
    DIFF_TERM   => TRUE,
    IOSTANDARD  => "LVDS"
)
port map (
    O           => FMC_CLK1_M2C,
    I           => FMC_CLK1_M2C_P,
    IB          => FMC_CLK1_M2C_N
);

---------------------------------------------------------------------------
-- FMC Clocks Frequency Counter
---------------------------------------------------------------------------

test_clocks(0) <= GTREFCLK;
test_clocks(1) <= FMC_CLK0_M2C;
test_clocks(2) <= FMC_CLK1_M2C;
test_clocks(3) <= '0';

freq_counter_inst : entity work.freq_counter
port map (
    refclk          => clk_i,
    reset           => reset_i,
    test_clocks     => test_clocks,
    freq_out        => FREQ_VAL
);

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
FMC_PRSNT_DW <= ZEROS(31) & FMC_PRSNT;

fmc_ctrl : entity work.fmc_ctrl
port map (
    -- Clock and Reset
    clk_i                       => clk_i,
    reset_i                     => reset_i,
    sysbus_i                    => (others => '0'),
    posbus_i                    => (others => (others => '0')),
    -- Block Parameters
    FMC_PRSNT                   => FMC_PRSNT_DW,
    LINK_UP                     => LINK_UP,
    ERROR_COUNT                 => ERROR_COUNT,
    LA_P_ERROR                  => LA_P_ERROR,
    LA_N_ERROR                  => LA_N_ERROR,
    GTREFCLK                    => FREQ_VAL(0),
    FMC_CLK0                    => FREQ_VAL(1),
    FMC_CLK1                    => FREQ_VAL(2),
    -- Memory Bus Interface
    mem_cs_i                    => mem_cs_i,
    mem_wstb_i                  => mem_wstb_i,
    mem_addr_i                  => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i                   => mem_dat_i,
    mem_dat_o                   => mem_dat_o
);

end rtl;

