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

entity system_registers is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    write_strobe_i      : in  std_logic_vector(MOD_COUNT-1 downto 0);
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    -- Block Outputs
    slow_tlp_o          : out slow_packet
);
end system_registers;

architecture rtl of system_registers is

signal write_address : natural range 0 to (2**BLK_AW - 1);
signal blk_addr : natural range 0 to (2**(PAGE_AW-BLK_AW)-1);

begin

write_address <= to_integer(unsigned(write_address_i(BLK_AW-1 downto 0)));
blk_addr <= to_integer(unsigned(write_address_i(PAGE_AW-1 downto BLK_AW)));

---------------------------------------------------------------------------
-- Catch user write access to Slow Registers, and generate a TLP to
-- Slow FPGA.
-- Driver makes sure not to issue a register write when the serial engine
-- is busy.
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
            -- INENC PROTOCOL Slow Registers
            if (write_strobe_i(INENC_CS) = '1') then
                if (write_address = INENC_PROTOCOL) then
                    slow_tlp_o.strobe <= '1';
                    slow_tlp_o.data <= write_data_i;
                    slow_tlp_o.address <= INPROT_ADDR_LIST(blk_addr);
                end if;
            -- OUTENC PROTOCOL Slow Registers
            elsif (write_strobe_i(OUTENC_CS) = '1') then
                if (write_address = OUTENC_PROTOCOL) then
                    slow_tlp_o.strobe <= '1';
                    slow_tlp_o.data <= write_data_i;
                    slow_tlp_o.address <= OUTPROT_ADDR_LIST(blk_addr);
                end if;
            -- TTLIN TERM Slow Registers
            elsif (write_strobe_i(TTLIN_CS) = '1') then
                if (write_address = TTLIN_TERM) then
                    slow_tlp_o.strobe <= '1';
                    slow_tlp_o.data <= write_data_i;
                    slow_tlp_o.address <= TTLTERM_ADDR_LIST(blk_addr);
                end if;
            end if;
        end if;
    end if;
end process;

end rtl;

