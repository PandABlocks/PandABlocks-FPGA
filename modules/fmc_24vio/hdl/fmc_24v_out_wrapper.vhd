--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : FMC Top-Level Generic VHDL entity to support various FMC
--                modules.
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

entity fmc_24v_out_wrapper is
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
    FMC_interface       : inout fmc_interface
);
end fmc_24v_out_wrapper;

architecture rtl of fmc_24v_out_wrapper is

--signal FMC_CLK0_M2C     : std_logic;
--signal FMC_CLK1_M2C     : std_logic;
signal FMC_PRSNT_DW     : std_logic_vector(31 downto 0);
signal OUT_PWR_ON       : std_logic_vector(31 downto 0);
signal OUT_PUSHPL       : std_logic_vector(31 downto 0);
signal OUT_FLTR         : std_logic_vector(31 downto 0);
signal OUT_SRIAL        : std_logic_vector(31 downto 0);
signal OUT_FAULT        : std_logic_vector(31 downto 0);
signal OUT_EN           : std_logic_vector(31 downto 0);
signal OUT_CONFIG       : std_logic_vector(31 downto 0);
signal OUT_STATUS       : std_logic_vector(31 downto 0);

signal fmc_in           : std_logic_vector(7 downto 0);
signal fmc_out          : std_logic_vector(7 downto 0);

begin

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

---------------------------------------------------------------------------
-- FMC Mezzanine Clocks (unused within this block)
---------------------------------------------------------------------------
--IBUFGDS_CLK0 : IBUFGDS
--generic map (
--    DIFF_TERM   => TRUE,
--    IOSTANDARD  => "LVDS"
--)
--port map (
--    O           => FMC_CLK0_M2C,
--    I           => FMC_interface.FMC_CLK0_M2C_P,
--    IB          => FMC_interface.FMC_CLK0_M2C_N
--);

--IBUFGDS_CLK1 : IBUFGDS
--generic map (
--    DIFF_TERM   => TRUE,
--    IOSTANDARD  => "LVDS"
--)
--port map (
--    O           => FMC_CLK1_M2C,
--    I           => FMC_interface.FMC_CLK1_M2C_P,
--    IB          => FMC_interface.FMC_CLK1_M2C_N
--);


---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
FMC_PRSNT_DW <= ZEROS(31) & FMC_interface.FMC_PRSNT;

fmc_ctrl : entity work.fmc_24v_out_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    -- Block Parameters
    FMC_PRSNT           => FMC_PRSNT_DW,
    val1_from_bus       => fmc_out(0),
    val2_from_bus       => fmc_out(1),
    val3_from_bus       => fmc_out(2),
    val4_from_bus       => fmc_out(3),
    val5_from_bus       => fmc_out(4),
    val6_from_bus       => fmc_out(5),
    val7_from_bus       => fmc_out(6),
    val8_from_bus       => fmc_out(7),
    OUT_PWR_ON          => OUT_PWR_ON,
    OUT_PUSHPL          => OUT_PUSHPL,
    OUT_FLTR            => OUT_FLTR,
    OUT_SRIAL           => OUT_SRIAL,
    OUT_FAULT           => OUT_FAULT,
    OUT_EN              => OUT_EN,
    OUT_CONFIG          => OUT_CONFIG,
    OUT_STATUS          => OUT_STATUS,
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

---------------------------------------------------------------------------
-- FMC Application Core
---------------------------------------------------------------------------
fmc_24v_out_inst : entity work.fmc_24v_out
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    FMC_LA_P            => FMC_interface.FMC_LA_P,
    FMC_LA_N            => FMC_interface.FMC_LA_N,
    OUT_PWR_ON          => OUT_PWR_ON(0),
    OUT_PUSHPL          => OUT_PUSHPL(0),
    OUT_FLTR            => OUT_FLTR(0),
    OUT_SRIAL           => OUT_SRIAL(0),
    OUT_FAULT           => OUT_FAULT,
    OUT_EN              => OUT_EN(0),
    OUT_CONFIG          => OUT_CONFIG(15 downto 0),
    OUT_STATUS          => OUT_STATUS,
    fmc_out_i           => fmc_out
);

---------------------------------------------------------------------------
-- Assign outputs
---------------------------------------------------------------------------

end rtl;

