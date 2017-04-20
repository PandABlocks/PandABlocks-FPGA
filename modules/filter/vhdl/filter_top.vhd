--------------------------------------------------------------------------------
--  File:       pcomp.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity filter_top is
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
    posbus_i            : in  posbus_t;
    -- TTL I/O
    out_o               : out std32_array(FILTER_NUM-1 downto 0);  
    ready_o             : out std_logic_vector(FILTER_NUM-1 downto 0);
    err_o               : out std_logic_vector(FILTER_NUM-1 downto 0)         
    
 );
end filter_top;

architecture rtl of filter_top is

signal read_strobe      : std_logic_vector(FILTER_NUM-1 downto 0);
signal read_data        : std32_array(FILTER_NUM-1 downto 0);
signal write_strobe     : std_logic_vector(FILTER_NUM-1 downto 0);

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

FILTER_GEN : FOR I IN 0 TO (FILTER_NUM-1) GENERATE

-- Sub-module address decoding
read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;

filter_block : entity work.filter_block
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe(I),
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data(I),
    read_ack_o          => open,

    write_strobe_i      => write_strobe(I),
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,
    -- Block Inputs/Outputs
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    out_o               => out_o(I),  
    ready_o             => ready_o(I),
    err_o               => err_o(I)    

);

END GENERATE;

end rtl;


