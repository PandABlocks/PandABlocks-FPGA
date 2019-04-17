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
use work.addr_defines.all;
use work.slow_defines.all;

entity ttlin_top is
port (
    -- Clocks and Resets
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    --Memory Bus Interface
    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
	write_data_i        : in  std_logic_vector(31 downto 0);
	--Memory interface
	slow_tlp_o          : out slow_packet;
    -- TTL I/O
    pad_i               : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    val_o               : out std_logic_vector(TTLIN_NUM-1 downto 0)
);
end ttlin_top;

architecture rtl of ttlin_top is

signal pad_iob          : std_logic_vector(pad_i'length-1 downto 0);
signal blk_addr         : natural range 0 to (2**(PAGE_AW-BLK_AW)-1);
signal write_address    : natural range 0 to (2**BLK_AW - 1);

begin

-- Used for Slow output signal
write_address <= to_integer(unsigned(write_address_i(BLK_AW-1 downto 0)));
blk_addr <= to_integer(unsigned(write_address_i(PAGE_AW-1 downto BLK_AW)));

-- slow registers

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slow_tlp_o.strobe <= 'Z';
            slow_tlp_o.address <= (others => 'Z');
            slow_tlp_o.data <= (others => 'Z');
        else
            -- Single clock cycle strobe
            slow_tlp_o.strobe <= 'Z';
            -- OUTENC PROTOCOL Slow Registers
            if (write_strobe_i = '1') then
                if (write_address = TTLIN_TERM_addr) then
                    slow_tlp_o.strobe <= '1';
                    slow_tlp_o.data <= write_data_i;
                    slow_tlp_o.address <= TTLTERM_ADDR_LIST(blk_addr);
                end if;
            else
                slow_tlp_o.strobe <= 'Z';
                slow_tlp_o.address <= (others => 'Z');
                slow_tlp_o.data <= (others => 'Z');
            end if;
        end if;
    end if;
end process;

-- Place into IOB
process(clk_i)
begin
    if rising_edge(clk_i) then
        pad_iob <= pad_i;
    end if;
end process;

-- Syncroniser for each input
SYNC : FOR I IN 0 TO TTLIN_NUM-1 GENERATE

    syncer : entity work.sync_bit
    port map (
        clk_i   => clk_i,
        bit_i   => pad_iob(I),
        bit_o   => val_o(I)
    );

END GENERATE;

end rtl;


