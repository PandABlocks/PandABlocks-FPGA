--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Interface to external TTL inputs.
--                TTL inputs are registered before assigned to System Bus.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.type_defines.all;
use work.addr_defines.all;
use work.slow_defines.all;

entity ttlin_top is
port (
    -- Clocks and Resets
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_rstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- TTL I/O
    pad_i               : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    val_o               : out std_logic_vector(TTLIN_NUM-1 downto 0);
    slow_tlp_o          : out slow_packet
);
end ttlin_top;

architecture rtl of ttlin_top is

--
-- Return slow controller address value.
--
function ASSIGN_ADDR (mem_addr_i : std_logic_vector) return std_logic_vector is
begin
    case mem_addr_i(PAGE_AW-1 downto BLK_AW) is
        when "0000"  =>
            return TO_SVECTOR(TTLIN1_TERM, PAGE_AW);
        when "0001"  =>
            return TO_SVECTOR(TTLIN2_TERM, PAGE_AW);
        when "0010"  =>
            return TO_SVECTOR(TTLIN3_TERM, PAGE_AW);
        when "0011"  =>
            return TO_SVECTOR(TTLIN4_TERM, PAGE_AW);
        when "0100"  =>
            return TO_SVECTOR(TTLIN5_TERM, PAGE_AW);
        when "0101"  =>
            return TO_SVECTOR(TTLIN6_TERM, PAGE_AW);
        when others =>
            return TO_SVECTOR(0, PAGE_AW);
    end case;
end ASSIGN_ADDR;

-- Total number of digital outputs
signal mem_blk_cs       : std_logic_vector(TTLIN_NUM-1 downto 0);

begin

--
-- TTLIN Block
--
TTLIN_GEN : FOR I IN 0 TO (TTLIN_NUM-1) GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, PAGE_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

ttlin_block : entity work.ttlin_block
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Bus Interface
    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    -- Block Inputs and Outputs
    pad_i               => pad_i(I),
    val_o               => val_o(I)
);

END GENERATE;

--
-- Issue a Write command to Slow Controller when a write is detected on
-- PROTOCOL register
--
SLOW_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slow_tlp_o.strobe <= '0';
            slow_tlp_o.address <= (others => '0');
            slow_tlp_o.data <= (others => '0');
        else
            -- Single clock cycle strobe
            slow_tlp_o.strobe <= '0';
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                if (mem_addr_i(BLK_AW-1 downto 0) = TO_SVECTOR(TTLIN_TERM, BLK_AW)) then
                    slow_tlp_o.strobe <= '1';
                    slow_tlp_o.data <= mem_dat_i;
                    slow_tlp_o.address <= ASSIGN_ADDR(mem_addr_i);
                end if;
           end if;
        end if;
    end if;
end process;



end rtl;


