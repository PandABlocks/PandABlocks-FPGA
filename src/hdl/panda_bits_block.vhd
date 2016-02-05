--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : BITS block register interface.
--                There are 4 configuration registers for each soft input.
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
    -- Block outputs
    zero_o              : out std_logic;
    one_o               : out std_logic;
    bits_a_o            : out std_logic;
    bits_b_o            : out std_logic;
    bits_c_o            : out std_logic;
    bits_d_o            : out std_logic
);
end panda_bits_block;

architecture rtl of panda_bits_block is

signal SOFTA_SET        : std_logic := '0';
signal SOFTB_SET        : std_logic := '0';
signal SOFTC_SET        : std_logic := '0';
signal SOFTD_SET        : std_logic := '0';

signal mem_addr         : natural range 0 to (2**mem_addr_i'length - 1);

begin

-- Integer conversion for address.
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
                if (mem_addr = BITS_A_SET) then
                    SOFTA_SET <= mem_dat_i(0);
                end if;

                if (mem_addr = BITS_B_SET) then
                    SOFTB_SET <= mem_dat_i(0);
                end if;

                if (mem_addr = BITS_C_SET) then
                    SOFTC_SET <= mem_dat_i(0);
                end if;

                if (mem_addr = BITS_D_SET) then
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
    reset_i             => reset_i,

    zero_o              => zero_o,
    one_o               => one_o,
    softa_o             => bits_a_o,
    softb_o             => bits_b_o,
    softc_o             => bits_c_o,
    softd_o             => bits_d_o,

    SOFTA_SET           => SOFTA_SET,
    SOFTB_SET           => SOFTB_SET,
    SOFTC_SET           => SOFTC_SET,
    SOFTD_SET           => SOFTD_SET
);

end rtl;

