--------------------------------------------------------------------------------
--  File:       panda_clocks_block.vhd
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

entity panda_clocks_block is
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
    clocks_a_o          : out std_logic;
    clocks_b_o          : out std_logic;
    clocks_c_o          : out std_logic;
    clocks_d_o          : out std_logic
);
end panda_clocks_block;

architecture rtl of panda_clocks_block is

signal CLOCKA_DIV       : std_logic_vector(31 downto 0) := (others => '0');
signal CLOCKB_DIV       : std_logic_vector(31 downto 0) := (others => '0');
signal CLOCKC_DIV       : std_logic_vector(31 downto 0) := (others => '0');
signal CLOCKD_DIV       : std_logic_vector(31 downto 0) := (others => '0');

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
            CLOCKA_DIV <= (others => '0');
            CLOCKB_DIV <= (others => '0');
            CLOCKC_DIV <= (others => '0');
            CLOCKD_DIV <= (others => '0');
        else
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = CLOCKS_A_PERIOD) then
                    CLOCKA_DIV <= mem_dat_i;
                end if;

                if (mem_addr = CLOCKS_B_PERIOD) then
                    CLOCKB_DIV <= mem_dat_i;
                end if;

                if (mem_addr = CLOCKS_C_PERIOD) then
                    CLOCKC_DIV <= mem_dat_i;
                end if;

                if (mem_addr = CLOCKS_D_PERIOD) then
                    CLOCKD_DIV <= mem_dat_i;
                end if;
            end if;
        end if;
    end if;
end process;

--
-- Block instantiation.
--
panda_clocks_inst  : entity work.panda_clocks
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    clocka_o            => clocks_a_o,
    clockb_o            => clocks_b_o,
    clockc_o            => clocks_c_o,
    clockd_o            => clocks_d_o,

    CLOCKA_DIV          => CLOCKA_DIV,
    CLOCKB_DIV          => CLOCKB_DIV,
    CLOCKC_DIV          => CLOCKC_DIV,
    CLOCKD_DIV          => CLOCKD_DIV
);

end rtl;

