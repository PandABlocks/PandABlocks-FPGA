--------------------------------------------------------------------------------
--  File:       panda_pgen_ctrl.vhd
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
entity panda_pgen_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    CYCLES       : out std_logic_vector(31 downto 0);
    CYCLES_WSTB  : out std_logic;
    ENABLE       : out std_logic_vector(31 downto 0);
    ENABLE_WSTB  : out std_logic;
    TRIG       : out std_logic_vector(31 downto 0);
    TRIG_WSTB  : out std_logic;
    TABLE_ADDRESS       : out std_logic_vector(31 downto 0);
    TABLE_ADDRESS_WSTB  : out std_logic;
    TABLE_LENGTH       : out std_logic_vector(31 downto 0);
    TABLE_LENGTH_WSTB  : out std_logic;

    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_pgen_ctrl;
architecture rtl of panda_pgen_ctrl is

signal mem_addr : natural range 0 to (2**mem_addr_i'length - 1);

begin

mem_addr <= to_integer(unsigned(mem_addr_i));

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            CYCLES <= (others => '0');
            CYCLES_WSTB <= '0';
            ENABLE <= (others => '0');
            ENABLE_WSTB <= '0';
            TRIG <= (others => '0');
            TRIG_WSTB <= '0';
            TABLE_ADDRESS <= (others => '0');
            TABLE_ADDRESS_WSTB <= '0';
            TABLE_LENGTH <= (others => '0');
            TABLE_LENGTH_WSTB <= '0';
        else
            CYCLES_WSTB <= '0';
            ENABLE_WSTB <= '0';
            TRIG_WSTB <= '0';
            TABLE_ADDRESS_WSTB <= '0';
            TABLE_LENGTH_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = PGEN_CYCLES) then
                    CYCLES <= mem_dat_i;
                    CYCLES_WSTB <= '1';
                end if;
                if (mem_addr = PGEN_ENABLE) then
                    ENABLE <= mem_dat_i;
                    ENABLE_WSTB <= '1';
                end if;
                if (mem_addr = PGEN_TRIG) then
                    TRIG <= mem_dat_i;
                    TRIG_WSTB <= '1';
                end if;
                if (mem_addr = PGEN_TABLE_ADDRESS) then
                    TABLE_ADDRESS <= mem_dat_i;
                    TABLE_ADDRESS_WSTB <= '1';
                end if;
                if (mem_addr = PGEN_TABLE_LENGTH) then
                    TABLE_LENGTH <= mem_dat_i;
                    TABLE_LENGTH_WSTB <= '1';
                end if;

            end if;
        end if;
    end if;
end process;

--
-- Status Register Read
--
REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            mem_dat_o <= (others => '0');
        else
            case (mem_addr) is
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;