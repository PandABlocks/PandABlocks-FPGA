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
use ieee.std_logic_misc.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;
use work.slow_defines.all;
use work.support.all;

entity system_registers is
generic (
    ENC_NUM : natural
);
port (
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    OUTENC_PROT_i       : in  std32_array(ENC_NUM-1 downto 0);
    OUTENC_PROT_WSTB_i  : in  std_logic_vector(ENC_NUM-1 downto 0);
    INENC_PROT_i        : in  std32_array(ENC_NUM-1 downto 0);
    INENC_PROT_WSTB_i   : in  std_logic_vector(ENC_NUM-1 downto 0);
    TTLIN_TERM_i        : in  std32_array(TTLIN_NUM-1 downto 0);
    TTLIN_TERM_WSTB_i   : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    slow_tlp_o          : out slow_packet
);
end system_registers;

architecture rtl of system_registers is

-- Input Encoder Address List
constant INPROT_ADDR_LIST   : page_array(ENC_NUM-1 downto 0) := (
                                TO_SVECTOR(INENC4_PROTOCOL, PAGE_AW),
                                TO_SVECTOR(INENC3_PROTOCOL, PAGE_AW),
                                TO_SVECTOR(INENC2_PROTOCOL, PAGE_AW),
                                TO_SVECTOR(INENC1_PROTOCOL, PAGE_AW)
                            );

-- Output Encoder Address List
constant OUTPROT_ADDR_LIST  : page_array(ENC_NUM-1 downto 0) := (
                                TO_SVECTOR(OUTENC4_PROTOCOL, PAGE_AW),
                                TO_SVECTOR(OUTENC3_PROTOCOL, PAGE_AW),
                                TO_SVECTOR(OUTENC2_PROTOCOL, PAGE_AW),
                                TO_SVECTOR(OUTENC1_PROTOCOL, PAGE_AW)
                            );

-- TTLIN TERM Address List
constant TTLTERM_ADDR_LIST  : page_array(TTLIN_NUM-1 downto 0) := (
                                TO_SVECTOR(TTLIN6_TERM, PAGE_AW),
                                TO_SVECTOR(TTLIN5_TERM, PAGE_AW),
                                TO_SVECTOR(TTLIN4_TERM, PAGE_AW),
                                TO_SVECTOR(TTLIN3_TERM, PAGE_AW),
                                TO_SVECTOR(TTLIN2_TERM, PAGE_AW),
                                TO_SVECTOR(TTLIN1_TERM, PAGE_AW)
                            );

begin

---------------------------------------------------------------------------
-- Catch user write access to Slow Registers, and generate a TLP to
-- Slow FPGA.
-- Driver makes sure not to issue a register write when the serial engine
-- is busy.
---------------------------------------------------------------------------
process(clk_i)
  variable inenc_ind    : natural;
  variable outenc_ind   : natural;
  variable ttlin_ind    : natural;
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slow_tlp_o.strobe <= '0';
            slow_tlp_o.address <= (others => '0');
            slow_tlp_o.data <= (others => '0');
        else
            -- INENC PROTOCOL Slow Registers
            if (or_reduce(INENC_PROT_WSTB_i) = '1') then
                inenc_ind := ONEHOT_INDEX(INENC_PROT_WSTB_i);
                slow_tlp_o.strobe <= '1';
                slow_tlp_o.data <= INENC_PROT_i(inenc_ind);
                slow_tlp_o.address <= INPROT_ADDR_LIST(inenc_ind);
            -- OUTENC PROTOCOL Slow Registers
            elsif (or_reduce(OUTENC_PROT_WSTB_i) = '1') then
                outenc_ind := ONEHOT_INDEX(OUTENC_PROT_WSTB_i);
                slow_tlp_o.strobe <= '1';
                slow_tlp_o.data <= OUTENC_PROT_i(outenc_ind);
                slow_tlp_o.address <= OUTPROT_ADDR_LIST(outenc_ind);
            -- TTLIN TERM Slow Registers
            elsif (or_reduce(TTLIN_TERM_WSTB_i) = '1') then
                ttlin_ind := ONEHOT_INDEX(TTLIN_TERM_WSTB_i);
                slow_tlp_o.strobe <= '1';
                slow_tlp_o.data <= TTLIN_TERM_i(ttlin_ind);
                slow_tlp_o.address <= TTLTERM_ADDR_LIST(ttlin_ind);
            else
                slow_tlp_o.strobe <= '0';
            end if;
        end if;
    end if;
end process;

end rtl;

