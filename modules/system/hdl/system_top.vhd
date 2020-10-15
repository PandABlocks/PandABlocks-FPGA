--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Zynq-to-Spartan6 Slow Control Interface top-level.
--                Interface is provided with dedicated SPI-like serial links.
--
--                This is a SPECIAL block, needs all _CS in order to detect
--                slow register access.
--
--                It also monitors all digital I/O status for LED management.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity system_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Digital I/O Interface
    ttlin_i             : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    ttlout_i            : in  std_logic_vector(TTLOUT_NUM-1 downto 0);
    inenc_conn_i        : in  std_logic_vector(ENC_NUM-1 downto 0);
    outenc_conn_i       : in  std_logic_vector(ENC_NUM-1 downto 0);
    pcap_act_i          : in  std_logic;
    -- Block Input and Outputs
    OUTENC_PROT_i       : in  std32_array(ENC_NUM-1 downto 0);
    OUTENC_PROT_WSTB_i  : in  std_logic_vector(ENC_NUM-1 downto 0);
    INENC_PROT_i        : in  std32_array(ENC_NUM-1 downto 0);
    INENC_PROT_WSTB_i   : in  std_logic_vector(ENC_NUM-1 downto 0);
    TTLIN_TERM_i        : in  std32_array(TTLIN_NUM-1 downto 0);
    TTLIN_TERM_WSTB_i   : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    SLOW_FPGA_VERSION   : out std_logic_vector(31 downto 0);
    DCARD_MODE_o        : out std32_array(ENC_NUM-1 downto 0);
    -- Serial Physical interface
    spi_sclk_o          : out std_logic;
    spi_dat_o           : out std_logic;
    spi_sclk_i          : in  std_logic;
    spi_dat_i           : in  std_logic;
    -- External Clock
    ext_clk_i           : in  std_logic;
    sma_pll_locked_i    : in  std_logic;
    ext_clock_o         : out std_logic_vector(1 downto 0);
    clk_sel_stat_i      : in  std_logic_vector(1 downto 0)

);
end system_top;

architecture rtl of system_top is

-- Gather various Temperature and Voltage readouts from Slow FPGA into
-- arrays.
signal TEMP_MON         : std32_array(4 downto 0);
signal VOLT_MON         : std32_array(7 downto 0);

signal slow_regs_tlp    : slow_packet;
signal slow_leds_tlp    : slow_packet;

signal cmd_ready_n      : std_logic;

signal VEC_PLL_LOCKED   : std_logic_vector(31 downto 0) := (others => '0');
signal VEC_EXT_CLOCK    : std_logic_vector(31 downto 0);
signal VEC_CLK_SEL_STAT : std_logic_vector(31 downto 0) := (others => '0');
signal write_ack        : std_logic;
signal test_clocks      : std_logic_vector(0 downto 0);
signal FREQ_VAL         : std32_array(0 downto 0);

signal DCARD_MODE       : std32_array(ENC_NUM-1 downto 0);


begin

-- Accept write data if FIFO is available
write_ack_o <= not cmd_ready_n or write_ack;

DCARD_MODE_o <= DCARD_MODE;

---------------------------------------------------------------------------
-- LED information for Digital IO goes through SlowFPGA
---------------------------------------------------------------------------
led_management_inst : entity work.led_management
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    ttlin_i             => ttlin_i,
    ttlout_i            => ttlout_i,
    inenc_conn_i        => inenc_conn_i,
    outenc_conn_i       => outenc_conn_i,
    pcap_act_i          => pcap_act_i,

    slow_tlp_o          => slow_leds_tlp
);

---------------------------------------------------------------------------
-- Construct TLP packets for slow FPGA registers
---------------------------------------------------------------------------
system_registers : entity work.system_registers
port map (
    clk_i   => clk_i,
    reset_i => reset_i,
    DCARD_MODE_i => DCARD_MODE,
    OUTENC_PROT_i => OUTENC_PROT_i,
    OUTENC_PROT_WSTB_i => OUTENC_PROT_WSTB_i,
    INENC_PROT_i => INENC_PROT_i,
    INENC_PROT_WSTB_i => INENC_PROT_WSTB_i,
    TTLIN_TERM_i => TTLIN_TERM_i,
    TTLIN_TERM_WSTB_i => TTLIN_TERM_WSTB_i,
    slow_tlp_o => slow_regs_tlp
);

---------------------------------------------------------------------------
-- Slow controller physical serial interface
---------------------------------------------------------------------------
system_interface : entity work.system_interface
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    spi_sclk_o          => spi_sclk_o,
    spi_dat_o           => spi_dat_o,
    spi_sclk_i          => spi_sclk_i,
    spi_dat_i           => spi_dat_i,

    registers_tlp_i     => slow_regs_tlp,
    leds_tlp_i          => slow_leds_tlp,
    cmd_ready_n_o       => cmd_ready_n,
    SLOW_FPGA_VERSION   => SLOW_FPGA_VERSION,
    DCARD_MODE          => DCARD_MODE,
    TEMP_MON            => TEMP_MON,
    VOLT_MON            => VOLT_MON
);

---------------------------------------------------------------------------
-- External Clock registers
---------------------------------------------------------------------------
VEC_PLL_LOCKED(0) <= sma_pll_locked_i;
ext_clock_o <= VEC_EXT_CLOCK(1 downto 0);
VEC_CLK_SEL_STAT(1 downto 0) <= clk_sel_stat_i;

--
--
---- Noticed that the write ack in the slow_ctrl isnt connected but the SMA
---- worked in the lab, this is because the ack is controlled by the fifo
---- full flag. So added this as i couldn't do it in the slow_cntrl block
---- as the write_ack is permanently set to a one and is autogenerated
ps_ack: process(clk_i)
begin
    if rising_edge(clk_i)then
        if ((write_strobe_i = '1') and
          (write_address_i = std_logic_vector(to_unsigned(SYSTEM_EXT_CLOCK_addr,write_address_i'length)))) then
            write_ack <= '1';
        else
            write_ack <= '0';
        end if;
    end if;
end process ps_ack;

test_clocks(0) <= ext_clk_i;

freq_counter_inst : entity work.freq_counter
generic map ( NUM => 1)
port map (
    refclk          => clk_i,
    reset           => reset_i,
    test_clocks     => test_clocks,
    freq_out        => FREQ_VAL
);

---------------------------------------------------------------------------
-- Status Read process from Slow Controller
---------------------------------------------------------------------------
system_ctrl_inst : entity work.system_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i            => (others => '0'),
    pos_bus_i            => (others => (others => '0')),
    -- Block Parameters
    TEMP_PSU            => TEMP_MON(0),
    TEMP_SFP            => TEMP_MON(1),
    TEMP_ENC_L          => TEMP_MON(2),
    TEMP_PICO           => TEMP_MON(3),
    TEMP_ENC_R          => TEMP_MON(4),
    ALIM_12V0           => VOLT_MON(0),
    PICO_5V0            => VOLT_MON(1),
    IO_5V0              => VOLT_MON(2),
    SFP_3V3             => VOLT_MON(3),
    FMC_15VN            => VOLT_MON(4),
    FMC_15VP            => VOLT_MON(5),
    ENC_24V             => VOLT_MON(6),
    FMC_12V             => VOLT_MON(7),
    PLL_LOCKED          => VEC_PLL_LOCKED,
    EXT_CLOCK           => VEC_EXT_CLOCK,
    EXT_CLOCK_WSTB      => open,
    EXT_CLOCK_FREQ      => FREQ_VAL(0),
    CLK_SEL_STAT        => VEC_CLK_SEL_STAT,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open
);

end rtl;

