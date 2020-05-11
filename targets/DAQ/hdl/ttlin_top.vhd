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
use work.slow_defines_daq.all;

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

signal blk_addr         : natural range 0 to (2**(PAGE_AW-BLK_AW)-1);
signal write_address    : natural range 0 to (2**BLK_AW - 1);

signal slow_tlp_o_strobe  : std_logic;                           
signal slow_tlp_o_address : std_logic_vector(PAGE_AW-1 downto 0);
signal slow_tlp_o_data    : std_logic_vector(31 downto 0);       


begin

-- Used for Slow output signal
write_address <= to_integer(unsigned(write_address_i(BLK_AW-1 downto 0)));
blk_addr <= to_integer(unsigned(write_address_i(PAGE_AW-1 downto BLK_AW)));

-- slow registers
slow_tlp_o.strobe <=slow_tlp_o_strobe;
slow_tlp_o.address<=slow_tlp_o_address;
slow_tlp_o.data   <=slow_tlp_o_data;


process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slow_tlp_o_strobe <= '0';
            slow_tlp_o_address <= (others => '0');
            slow_tlp_o_data <= (others => '0');
        else
            -- OUTENC PROTOCOL Slow Registers
            if (write_strobe_i = '1') then
                if (write_address = TTLIN_TERM_addr) then
                    if (blk_addr=TTLIN1_TERM) then
                       slow_tlp_o_strobe <= '1';
                       slow_tlp_o_data <= write_data_i;
                       slow_tlp_o_address <= std_logic_vector(to_unsigned(TTLIN1_TERM, PAGE_AW));
                    elsif (blk_addr=TTLIN2_TERM) then
                       slow_tlp_o_strobe <= '1';
                       slow_tlp_o_data <= write_data_i;
                       slow_tlp_o_address <= std_logic_vector(to_unsigned(TTLIN2_TERM, PAGE_AW));
                    else
                       slow_tlp_o_strobe <= '0';
                       slow_tlp_o_address <= (others => '0');
                       slow_tlp_o_data <= (others => '0');
                    end if;
                else
                    slow_tlp_o_strobe <= '0';
                    slow_tlp_o_address <= (others => '0');
                    slow_tlp_o_data <= (others => '0');
                end if;
            else
                slow_tlp_o_strobe <= '0';
                slow_tlp_o_address <= (others => '0');
                slow_tlp_o_data <= (others => '0');
            end if;
        end if;
    end if;
end process;

-- Syncroniser for each input
SYNC : FOR I IN 0 TO TTLIN_NUM-1 GENERATE

    syncer : entity work.IDDR_sync_bit
    port map (
        clk_i   => clk_i,
        bit_i   => pad_i(I),
        bit_o   => val_o(I)
    );

END GENERATE;

end rtl;


