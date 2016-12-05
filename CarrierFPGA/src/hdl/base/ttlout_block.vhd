--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Control register interface for TTLOUT block.
--                User select System Bus bit to be assigned to output.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity ttlout_block is
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
    sysbus_i            : in  sysbus_t;
    -- Output pulse
    pad_o               : out std_logic
);
end ttlout_block;

architecture rtl of ttlout_block is

component FDRE is
port (
    Q   : out std_logic;
    C   : in  std_logic;
    CE  : in  std_logic;
    R   : in  std_logic;
    D   : in  std_logic
);
end component;

-- Pack registers into IOB
attribute iob               : string;
attribute iob of FDRE       : component is "TRUE";

signal opad                 : std_logic;

begin

---------------------------------------------------------------------------
-- Control System Interface
---------------------------------------------------------------------------
ttlout_ctrl_inst : entity work.ttlout_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    val_o               => opad,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o
);

---------------------------------------------------------------------------
-- Register output and Pack into IOB
---------------------------------------------------------------------------
ofd_inst : FDRE
port map (
    Q   => pad_o,
    C   => clk_i,
    CE  => '1',
    R   => '0',
    D   => opad
);

end rtl;
