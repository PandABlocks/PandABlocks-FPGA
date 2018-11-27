--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Interface to external LVDS outputs.
--                LVDS outputs are selected from internal System Bus.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.addr_defines.all;

entity lvdsout_top is
port (
    -- Clocks and Resets
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
    -- System Bus
    sysbus_i            : in  std_logic_vector(SBUSW-1 downto 0);
    -- LVDS I/O
    pad_o               : out std_logic_vector(LVDSOUT_NUM-1 downto 0)
);
end lvdsout_top;

architecture rtl of lvdsout_top is

signal read_strobe      : std_logic_vector(LVDSOUT_NUM-1 downto 0);
signal read_data        : std32_array(LVDSOUT_NUM-1 downto 0);
signal write_strobe     : std_logic_vector(LVDSOUT_NUM-1 downto 0);
signal read_ack         : std_logic_vector(LVDSOUT_NUM-1 downto 0);
begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';
read_ack_o <= or_reduce(read_ack);

--
-- LVDSOUT Block
--
LVDSOUT_GEN : FOR I IN 0 TO (LVDSOUT_NUM-1) GENERATE

-- Sub-module address decoding
read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;

lvdsout_block : entity work.lvdsout_block
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe(I),
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data(I),
    read_ack_o          => read_ack(I),

    write_strobe_i      => write_strobe(I),
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,
    -- Block inputs
    sysbus_i            => sysbus_i,
    -- Block outputs
    pad_o               => pad_o(I)
);

END GENERATE;

end rtl;


