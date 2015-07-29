library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_sequencer_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(MEM_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_rstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    sysbus_i            : in  sysbus_t;
    -- Output pulse
    act_o               : out std_logic_vector(SEQ_NUM-1 downto 0);
    pulse_o             : out seq_puls_array(SEQ_NUM-1 downto 0)
);
end panda_sequencer_top;

architecture rtl of panda_sequencer_top is

signal mem_blk_cs           : std_logic_vector(SEQ_NUM-1 downto 0);
signal mem_read_data        : std32_array(2**(MEM_AW-BLK_AW)-1 downto 0);

begin

mem_dat_o <= mem_read_data(to_integer(unsigned(mem_addr_i(MEM_AW-1 downto BLK_AW))));

--
-- Instantiate SEQUENCER Blocks :
--  There are SEQ_NUM amount of encoders on the board
--
SEQUENCER_GEN : FOR I IN 0 TO SEQ_NUM-1 GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(MEM_AW-1 downto BLK_AW) = TO_STD_VECTOR(I, MEM_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

panda_sequencer_inst : entity work.panda_sequencer
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Interface
    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_read_data(I),
    -- Block inputs
    sysbus_i            => sysbus_i,
    -- Output pulse
    act_o               => act_o(I),
    pulse_o             => pulse_o(I)
);

END GENERATE;

end rtl;

