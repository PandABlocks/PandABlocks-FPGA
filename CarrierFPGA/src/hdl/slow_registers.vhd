--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : This module generates TLPs to Slow FPGA for configuration
--                register writes.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;
use work.slow_defines.all;

entity slow_registers is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic_vector(2**PAGE_NUM-1 downto 0);
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- Block Outputs
    slow_tlp_o          : out slow_packet
);
end slow_registers;

architecture rtl of slow_registers is

signal mem_addr : natural range 0 to (2**BLK_AW - 1);
signal blk_addr : natural range 0 to (2**(PAGE_AW-BLK_AW)-1);

begin

mem_addr <= to_integer(unsigned(mem_addr_i(BLK_AW-1 downto 0)));
blk_addr <= to_integer(unsigned(mem_addr_i(PAGE_AW-1 downto BLK_AW)));

---------------------------------------------------------------------------
-- Catch user write access to Slow Registers, and generate a TLP to
-- Slow FPGA.
---------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slow_tlp_o.strobe <= '0';
            slow_tlp_o.address <= (others => '0');
            slow_tlp_o.data <= (others => '0');
        else
            -- Single clock cycle strobe
            slow_tlp_o.strobe <= '0';
            if (mem_wstb_i = '1') then
                -- INENC PROTOCOL Slow Registers
                if (mem_cs_i(INENC_CS) = '1') then
                    if (mem_addr = INENC_PROTOCOL) then
                        slow_tlp_o.strobe <= '1';
                        slow_tlp_o.data <= mem_dat_i;
                        slow_tlp_o.address <= INPROT_ADDR_LIST(blk_addr);
                    end if;
                -- OUTENC PROTOCOL Slow Registers
                elsif (mem_cs_i(OUTENC_CS) = '1') then
                    if (mem_addr = OUTENC_PROTOCOL) then
                        slow_tlp_o.strobe <= '1';
                        slow_tlp_o.data <= mem_dat_i;
                        slow_tlp_o.address <= OUTPROT_ADDR_LIST(blk_addr);
                    end if;
                -- TTLIN TERM Slow Registers
                elsif (mem_cs_i(TTLIN_CS) = '1') then
                    if (mem_addr = TTLIN_TERM) then
                        slow_tlp_o.strobe <= '1';
                        slow_tlp_o.data <= mem_dat_i;
                        slow_tlp_o.address <= TTLTERM_ADDR_LIST(blk_addr);
                    end if;
                end if;
           end if;
        end if;
    end if;
end process;

end rtl;

