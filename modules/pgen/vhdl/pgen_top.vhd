library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.addr_defines.all;

entity pgen_top is
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
    -- DMA Engine Interface
    dma_req_o           : out std_logic_vector(PGEN_NUM-1 downto 0);
    dma_ack_i           : in  std_logic_vector(PGEN_NUM-1 downto 0);
    dma_done_i          : in  std_logic;
    dma_addr_o          : out std32_array(PGEN_NUM-1 downto 0);
    dma_len_o           : out std8_array(PGEN_NUM-1 downto 0);
    dma_data_i          : in  std_logic_vector(31 downto 0);
    dma_valid_i         : in  std_logic_vector(PGEN_NUM-1 downto 0);
    -- Block Input and Outputs
    sysbus_i            : in  sysbus_t;
    out_o               : out std32_array(PGEN_NUM-1 downto 0)
);
end pgen_top;

architecture rtl of pgen_top is

signal read_strobe      : std_logic_vector(PGEN_NUM-1 downto 0);
signal read_data        : std32_array(PGEN_NUM-1 downto 0);
signal read_ack         : std_logic_vector(PGEN_NUM-1 downto 0);

signal write_strobe     : std_logic_vector(PGEN_NUM-1 downto 0);
signal write_ack        : std_logic_vector(PGEN_NUM-1 downto 0);

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

-- Multiplex read data out from multiple instantiations
read_data_o <= read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

--
-- Instantiate PGEN Blocks :
--  There are PGEN_NUM amount of encoders on the board
--
PGEN_GEN : FOR I IN 0 TO PGEN_NUM-1 GENERATE

-- Sub-module address decoding
read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;

pgen_block_inst : entity work.pgen_block
port map (
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
    write_ack_o         => write_ack(I),

    dma_req_o           => dma_req_o(I),
    dma_ack_i           => dma_ack_i(I),
    dma_done_i          => dma_done_i,
    dma_addr_o          => dma_addr_o(I),
    dma_len_o           => dma_len_o(I),
    dma_data_i          => dma_data_i,
    dma_valid_i         => dma_valid_i(I),

    sysbus_i            => sysbus_i,
    out_o               => out_o(I)
);

END GENERATE;

end rtl;

