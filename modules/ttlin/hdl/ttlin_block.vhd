--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Control register interface for TTLIN block.
--                User select System Bus bit to be assigned to output.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.top_defines.all;

entity ttlin_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
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
    pos_bus_i           : in  pos_bus_t;
    pad_i               : in  std_logic;
    -- Block outputs
    TTLIN_TERM_o        : out std_logic_vector(31 downto 0);
    TTLIN_TERM_WSTB_o   : out std_logic;
    val_o               : out std_logic
);
end ttlin_block;

architecture rtl of ttlin_block is

begin

---------------------------------------------------------------------------
-- Control System Interface
---------------------------------------------------------------------------
ttlin_ctrl_inst : entity work.ttlin_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    TERM                => TTLIN_TERM_o,
    TERM_WSTB           => TTLIN_TERM_WSTB_o,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o
);

syncer : entity work.IDDR_sync_bit
port map (
    clk_i   => clk_i,
    bit_i   => pad_i,
    bit_o   => val_o
);

end rtl;

