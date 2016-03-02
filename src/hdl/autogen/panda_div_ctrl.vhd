--------------------------------------------------------------------------------
--  File:       panda_div_ctrl.vhd
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
entity panda_div_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    DIVISOR       : out std_logic_vector(31 downto 0);
    DIVISOR_WSTB  : out std_logic;
    FIRST_PULSE       : out std_logic_vector(31 downto 0);
    FIRST_PULSE_WSTB  : out std_logic;
    INP       : out std_logic_vector(31 downto 0);
    INP_WSTB  : out std_logic;
    ENABLE       : out std_logic_vector(31 downto 0);
    ENABLE_WSTB  : out std_logic;
    COUNT       : in  std_logic_vector(31 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_div_ctrl;
architecture rtl of panda_div_ctrl is

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
            DIVISOR <= (others => '0');
            DIVISOR_WSTB <= '0';
            FIRST_PULSE <= (others => '0');
            FIRST_PULSE_WSTB <= '0';
            INP <= (others => '0');
            INP_WSTB <= '0';
            ENABLE <= (others => '0');
            ENABLE_WSTB <= '0';
        else
            DIVISOR_WSTB <= '0';
            FIRST_PULSE_WSTB <= '0';
            INP_WSTB <= '0';
            ENABLE_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = DIV_DIVISOR) then
                    DIVISOR <= mem_dat_i;
                    DIVISOR_WSTB <= '1';
                end if;
                if (mem_addr = DIV_FIRST_PULSE) then
                    FIRST_PULSE <= mem_dat_i;
                    FIRST_PULSE_WSTB <= '1';
                end if;
                if (mem_addr = DIV_INP) then
                    INP <= mem_dat_i;
                    INP_WSTB <= '1';
                end if;
                if (mem_addr = DIV_ENABLE) then
                    ENABLE <= mem_dat_i;
                    ENABLE_WSTB <= '1';
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
                when DIV_COUNT =>
                    mem_dat_o <= COUNT;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;
