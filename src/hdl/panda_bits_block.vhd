--------------------------------------------------------------------------------
--  File:       panda_bits_block.vhd
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

entity panda_bits_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Block outputs
    zero_o              : out std_logic;
    one_o               : out std_logic;
    soft_o              : out std_logic_vector(3 downto 0)
);
end panda_bits_block;

architecture rtl of panda_bits_block is

signal SOFTA_SET        : std_logic := '0';
signal SOFTB_SET        : std_logic := '0';
signal SOFTC_SET        : std_logic := '0';
signal SOFTD_SET        : std_logic := '0';

signal mem_addr         : integer range 0 to 2**BLK_AW-1;

begin

mem_addr <= to_integer(unsigned(mem_addr_i));

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
        else
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = BITS.SOFTA_SET) then
                    SOFTA_SET <= mem_dat_i(0);
                end if;

                if (mem_addr = BITS.SOFTB_SET) then
                    SOFTB_SET <= mem_dat_i(0);
                end if;

                if (mem_addr = BITS.SOFTC_SET) then
                    SOFTC_SET <= mem_dat_i(0);
                end if;

                if (mem_addr = BITS.SOFTD_SET) then
                    SOFTD_SET <= mem_dat_i(0);
                end if;
            end if;
        end if;
    end if;
end process;

--
-- Block instantiation.
--
panda_bits_inst  : entity work.panda_bits
port map (
    clk_i               => clk_i,
    zero_o              => zero_o,
    one_o               => one_o,
    softa_o             => soft_o(0),
    softb_o             => soft_o(1),
    softc_o             => soft_o(2),
    softd_o             => soft_o(3),
    SOFTA_SET           => SOFTA_SET,
    SOFTB_SET           => SOFTB_SET,
    SOFTC_SET           => SOFTC_SET,
    SOFTD_SET           => SOFTD_SET
);

end rtl;

