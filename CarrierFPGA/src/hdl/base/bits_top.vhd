--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Top-level for BITS block instantiations.
--                There is only 1 (one) BITS block in the design.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity bits_top is
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
    -- Output pulses
    zero_o              : out std_logic;
    one_o               : out std_logic;
    bits_a_o            : out std_logic;
    bits_b_o            : out std_logic;
    bits_c_o            : out std_logic;
    bits_d_o            : out std_logic
);
end bits_top;

architecture rtl of bits_top is

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY       => RD_ADDR2ACK
);

--
-- Instantiate BITS Blocks :
--  There are BITS_NUM amount of encoders on the board
--
bits_block : entity work.bits_block
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => open,
    read_ack_o          => open,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,

    zero_o              => zero_o,
    one_o               => one_o,

    bits_a_o            => bits_a_o,
    bits_b_o            => bits_b_o,
    bits_c_o            => bits_c_o,
    bits_d_o            => bits_d_o
);

end rtl;
