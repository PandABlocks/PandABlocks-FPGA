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

entity fmc_24vio_wrapper is
port (
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Standard FMC Block ports, do not add to or delete
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Outputs to BitBus from FMC
    IN_val1_o              : out std_logic_vector(0 downto 0);
    IN_val2_o              : out std_logic_vector(0 downto 0);
    IN_val3_o              : out std_logic_vector(0 downto 0);
    IN_val4_o              : out std_logic_vector(0 downto 0);
    IN_val5_o              : out std_logic_vector(0 downto 0);
    IN_val6_o              : out std_logic_vector(0 downto 0);
    IN_val7_o              : out std_logic_vector(0 downto 0);
    IN_val8_o              : out std_logic_vector(0 downto 0);
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
end fmc_24vio_wrapper;

architecture rtl of fmc_24vio_wrapper is

signal IN_DB            : std_logic_vector(31 downto 0);
signal IN_FAULT         : std_logic_vector(31 downto 0);
signal IN_VTSEL         : std_logic_vector(31 downto 0);
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

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
FMC_PRSNT_DW <= ZEROS(31) & FMC.FMC_PRSNT;

fmc_ctrl : entity work.fmc_24vio_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    -- Block Parameters
    IN_FMC_PRSNT        => FMC_PRSNT_DW,
    IN_DB               => IN_DB,
    IN_FAULT            => IN_FAULT,
    IN_VTSEL            => IN_VTSEL,
    OUT_val1_from_bus   => fmc_out(0),
    OUT_val2_from_bus   => fmc_out(1),
    OUT_val3_from_bus   => fmc_out(2),
    OUT_val4_from_bus   => fmc_out(3),
    OUT_val5_from_bus   => fmc_out(4),
    OUT_val6_from_bus   => fmc_out(5),
    OUT_val7_from_bus   => fmc_out(6),
    OUT_val8_from_bus   => fmc_out(7),
    OUT_FMC_PRSNT       => FMC_PRSNT_DW,
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
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o
);

---------------------------------------------------------------------------
-- FMC Application Core
---------------------------------------------------------------------------
fmc_24vio_inst : entity work.fmc_24vio
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    FMC_LA_P            => FMC.FMC_LA_P,
    FMC_LA_N            => FMC.FMC_LA_N,
    OUT_PWR_ON          => OUT_PWR_ON(0),
    OUT_PUSHPL          => OUT_PUSHPL(0),
    OUT_FLTR            => OUT_FLTR(0),
    OUT_SRIAL           => OUT_SRIAL(0),
    OUT_FAULT           => OUT_FAULT,
    OUT_EN              => OUT_EN(0),
    OUT_CONFIG          => OUT_CONFIG(15 downto 0),
    OUT_STATUS          => OUT_STATUS,
    fmc_out_i           => fmc_out,
    IN_VTSEL            => IN_VTSEL(0),
    IN_DB               => IN_DB(1 downto 0),
    IN_FAULT            => IN_FAULT,
    fmc_in_o            => fmc_in
);

---------------------------------------------------------------------------
-- Assign outputs
---------------------------------------------------------------------------
IN_val1_o(0) <= fmc_in(0);
IN_val2_o(0) <= fmc_in(1);
IN_val3_o(0) <= fmc_in(2);
IN_val4_o(0) <= fmc_in(3);
IN_val5_o(0) <= fmc_in(4);
IN_val6_o(0) <= fmc_in(5);
IN_val7_o(0) <= fmc_in(6);
IN_val8_o(0) <= fmc_in(7);

end rtl;

