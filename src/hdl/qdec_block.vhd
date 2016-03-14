--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Control register interface for INENC block.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.type_defines.all;
use work.addr_defines.all;

entity qdec_block is
port (
    -- Clock and Reset.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface.
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- Block Input and Outputs
    sysbus_i            : in  sysbus_t;
    out_o               : out std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of qdec_block is

-- Block Configuration Registers
signal SETP             : std_logic_vector(31 downto 0);
signal SETP_WSTB        : std_logic;
signal RST_ON_Z         : std_logic_vector(31 downto 0);

signal a, b, z          : std_logic;

begin

--
-- Control System Interface
--
qdec_ctrl : entity work.qdec_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => open,

    a_o                 => a,
    b_o                 => b,
    z_o                 => z,

    SETP                => SETP,
    SETP_WSTB           => SETP_WSTB,
    RST_ON_Z            => RST_ON_Z,
    RST_ON_Z_WSTB       => open
);

qdec_inst : entity work.qdec
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    a_i             => a,
    b_i             => b,
    z_i             => z,
    setp_val_i      => SETP,
    setp_wstb_i     => SETP_WSTB,
    rst_z_i         => RST_ON_Z(0),
    out_o           => out_o
);

end rtl;
