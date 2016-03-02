--------------------------------------------------------------------------------
--  File:       panda_counter_ctrl.vhd
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
entity panda_counter_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    DIR       : out std_logic_vector(31 downto 0);
    DIR_WSTB  : out std_logic;
    START       : out std_logic_vector(31 downto 0);
    START_WSTB  : out std_logic;
    STEP       : out std_logic_vector(31 downto 0);
    STEP_WSTB  : out std_logic;
    ENABLE       : out std_logic_vector(31 downto 0);
    ENABLE_WSTB  : out std_logic;
    TRIG       : out std_logic_vector(31 downto 0);
    TRIG_WSTB  : out std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_counter_ctrl;
architecture rtl of panda_counter_ctrl is

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
            DIR <= (others => '0');
            DIR_WSTB <= '0';
            START <= (others => '0');
            START_WSTB <= '0';
            STEP <= (others => '0');
            STEP_WSTB <= '0';
            ENABLE <= (others => '0');
            ENABLE_WSTB <= '0';
            TRIG <= (others => '0');
            TRIG_WSTB <= '0';
        else
            DIR_WSTB <= '0';
            START_WSTB <= '0';
            STEP_WSTB <= '0';
            ENABLE_WSTB <= '0';
            TRIG_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = COUNTER_DIR) then
                    DIR <= mem_dat_i;
                    DIR_WSTB <= '1';
                end if;
                if (mem_addr = COUNTER_START) then
                    START <= mem_dat_i;
                    START_WSTB <= '1';
                end if;
                if (mem_addr = COUNTER_STEP) then
                    STEP <= mem_dat_i;
                    STEP_WSTB <= '1';
                end if;
                if (mem_addr = COUNTER_ENABLE) then
                    ENABLE <= mem_dat_i;
                    ENABLE_WSTB <= '1';
                end if;
                if (mem_addr = COUNTER_TRIG) then
                    TRIG <= mem_dat_i;
                    TRIG_WSTB <= '1';
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