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

entity fmc_24v_in_top is
port (
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Standard FMC Block ports, do not add to or delete
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_i;
    -- Outputs to BitBus from FMC
    val1_o              : out std_logic;
    val2_o              : out std_logic;
    val3_o              : out std_logic;
    val4_o              : out std_logic;
    val5_o              : out std_logic;
    val6_o              : out std_logic;
    val7_o              : out std_logic;
    val8_o              : out std_logic;
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
end fmc_24v_in_top;

architecture rtl of fmc_24v_in_top is

signal FMC_CLK0_M2C     : std_logic;
signal FMC_CLK1_M2C     : std_logic;
signal FMC_PRSNT_DW     : std_logic_vector(31 downto 0);
signal IN_DB            : std_logic_vector(31 downto 0);
signal IN_FAULT         : std_logic_vector(31 downto 0);
signal IN_VTSEL         : std_logic_vector(31 downto 0);


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

fmc_ctrl : entity work.fmc_24v_in_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    -- Block Parameters
    FMC_PRSNT           => FMC_PRSNT_DW,
    IN_DB               => IN_DB,
    IN_FAULT            => IN_FAULT,
    IN_VTSEL            => IN_VTSEL,
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
fmc_24v_in_inst : entity work.fmc_24v_in
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    FMC_LA_P            => FMC_interface.FMC_LA_P,
    FMC_LA_N            => FMC_interface.FMC_LA_N,
    IN_VTSEL            => IN_VTSEL(0),
    IN_DB               => IN_DB(1 downto 0),
    IN_FAULT            => IN_FAULT,
    fmc_in_o            => fmc_in
);

---------------------------------------------------------------------------
-- Assign outputs
---------------------------------------------------------------------------
val1_o <= fmc_in(0);
val2_o <= fmc_in(1);
val3_o <= fmc_in(2);
val4_o <= fmc_in(3);
val5_o <= fmc_in(4);
val6_o <= fmc_in(5);
val7_o <= fmc_in(6);
val8_o <= fmc_in(7);

end rtl;

