--------------------------------------------------------------------------------
--  File:       panda_pcomp.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_digio is
port (
    -- Clocks and Resets
    clk_i               : in  std_logic;
    reset_i          : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(MEM_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_rstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- TTL I/O
    ttlin_pad_i         : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    ttlin_o             : out std_logic_vector(TTLIN_NUM-1 downto 0);
    ttlout_pad_o        : out std_logic_vector(TTLOUT_NUM-1 downto 0);
    -- LVDS I/O
    lvdsin_pad_i        : in  std_logic_vector(LVDSIN_NUM-1 downto 0);
    lvdsin_o            : out std_logic_vector(LVDSIN_NUM-1 downto 0);
    lvdsout_pad_o       : out std_logic_vector(LVDSOUT_NUM-1 downto 0);
    -- System Bus
    sysbus_i            : in  std_logic_vector(SBUSW-1 downto 0)
);
end panda_digio;

architecture rtl of panda_digio is

-- Total number of digital outputs
constant DIGOUT_NUM     : positive := TTLOUT_NUM + LVDSOUT_NUM;

signal mem_blk_cs       : std_logic_vector(DIGOUT_NUM-1 downto 0);
signal pulse_out        : std_logic_vector(DIGOUT_NUM-1 downto 0);

begin

mem_dat_o <= (others => '0');

-- Register TTL and LVDS Inputs for top-level design use
process(clk_i)
begin
    if rising_edge(clk_i) then
        ttlin_o <= ttlin_pad_i;
        lvdsin_o <= lvdsin_pad_i;
    end if;
end process;

DIGOUT_GEN : FOR I IN 0 TO (DIGOUT_NUM-1) GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(MEM_AW-1 downto BLK_AW) = TO_STD_VECTOR(I, MEM_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

panda_digout_inst : entity work.panda_digout
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Bus Interface
    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    -- Block inputs
    sysbus_i            => sysbus_i,
    -- Block outputs
    pulse_o             => pulse_out(I)
);

END GENERATE;

-- Assign outputs
ttlout_pad_o <= pulse_out(TTLOUT_NUM-1 downto 0);
lvdsout_pad_o <= pulse_out(DIGOUT_NUM-1 downto TTLOUT_NUM);

end rtl;


