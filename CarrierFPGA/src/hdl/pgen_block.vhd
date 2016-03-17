--------------------------------------------------------------------------------
--  File:       pgen_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity pgen_block is
port (
    -- Clock and Reset
    clk_i                   : in  std_logic;
    reset_i                 : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i                : in  std_logic;
    mem_wstb_i              : in  std_logic;
    mem_addr_i              : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i               : in  std_logic_vector(31 downto 0);
    mem_dat_o               : out std_logic_vector(31 downto 0);
    -- DMA Engine Interface
    dma_req_o               : out std_logic;
    dma_ack_i               : in  std_logic;
    dma_done_i              : in  std_logic;
    dma_addr_o              : out std_logic_vector(31 downto 0);
    dma_len_o               : out std_logic_vector(7 downto 0);
    dma_data_i              : in  std_logic_vector(31 downto 0);
    dma_valid_i             : in  std_logic;
    -- Block Input and Outputs
    sysbus_i                : in  sysbus_t;
    out_o                   : out std_logic_vector(31 downto 0)
);
end pgen_block;

architecture rtl of pgen_block is

signal ENABLE_VAL           : std_logic_vector(31 downto 0);
signal TRIG_VAL             : std_logic_vector(31 downto 0);
signal CYCLES               : std_logic_vector(31 downto 0);
signal TABLE_ADDR           : std_logic_vector(31 downto 0);
signal TABLE_LENGTH         : std_logic_vector(31 downto 0);
signal TABLE_LENGTH_WSTB    : std_logic;
signal TABLE_STATUS         : std_logic_vector(31 downto 0);

signal enable               : std_logic;
signal trig                 : std_logic;

begin

--
-- Control System Interface
--
pgen_ctrl : entity work.pgen_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    trig_o              => trig,
    enable_o            => enable,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_dat_o,

    -- Block Parameters
    CYCLES              => CYCLES,
    TABLE_ADDRESS       => TABLE_ADDR,
    TABLE_LENGTH        => TABLE_LENGTH,
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB,
    TABLE_STATUS        => TABLE_STATUS
);

-- LUT Block Core Instantiation
pgen : entity work.pgen
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    trig_i              => trig,
    out_o               => out_o,

    CYCLES              => CYCLES,
    TABLE_ADDR          => TABLE_ADDR,
    TABLE_LENGTH        => TABLE_LENGTH,
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB,
    STATUS              => TABLE_STATUS,

    dma_req_o           => dma_req_o,
    dma_ack_i           => dma_ack_i,
    dma_done_i          => dma_done_i,
    dma_addr_o          => dma_addr_o,
    dma_len_o           => dma_len_o,
    dma_data_i          => dma_data_i,
    dma_valid_i         => dma_valid_i
);

end rtl;

