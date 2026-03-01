--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Control register interface for LVDSOUT block.
--                User select System Bus bit to be assigned to output.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity lvdsout_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    clk_2x_i            : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Block inputs
    bit_bus_i           : in  bit_bus_t;
    -- Output pulse
    pad_o               : out std_logic
);
end lvdsout_block;

architecture rtl of lvdsout_block is

signal val              : std_logic;
signal pad_iob          : std_logic;
signal q_delay          : std_logic_vector(31 downto 0);
signal o_delay          : std_logic_vector(31 downto 0);
signal o_delay_wstb     : std_logic;

begin

-- Control System Interface
lvdsout_ctrl_inst : entity work.lvdsout_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => (others => (others => '0')),
    val_from_bus        => val,
    QUARTER_DELAY       => q_delay,
    FINE_DELAY          => o_delay,
    FINE_DELAY_WSTB     => o_delay_wstb,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o
);

FINE_DELAY_GEN1: if FINE_DELAY_OPTION = '1' generate
begin
    fd_inst : entity work.finedelay port map (
        clk_i => clk_i,
        clk_2x_i => clk_2x_i,
        q_delay_i => q_delay(1 downto 0),
        o_delay_i => o_delay(4 downto 0),
        o_delay_strobe_i => o_delay_wstb,
        signal_i => val,
        signal_o => pad_iob
    );
end generate;

NO_FINE_DELAY_GEN1: if FINE_DELAY_OPTION = '0' generate
begin
    pad_iob <= val;
end generate;

pad_o <= pad_iob;

end rtl;

