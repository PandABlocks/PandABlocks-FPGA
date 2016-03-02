--------------------------------------------------------------------------------
--  File:       panda_pcomp_ctrl.vhd
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
entity panda_pcomp_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    START       : out std_logic_vector(31 downto 0);
    START_WSTB  : out std_logic;
    STEP       : out std_logic_vector(31 downto 0);
    STEP_WSTB  : out std_logic;
    WIDTH       : out std_logic_vector(31 downto 0);
    WIDTH_WSTB  : out std_logic;
    PNUM       : out std_logic_vector(31 downto 0);
    PNUM_WSTB  : out std_logic;
    RELATIVE       : out std_logic_vector(31 downto 0);
    RELATIVE_WSTB  : out std_logic;
    DIR       : out std_logic_vector(31 downto 0);
    DIR_WSTB  : out std_logic;
    DELTAP       : out std_logic_vector(31 downto 0);
    DELTAP_WSTB  : out std_logic;
    USE_TABLE       : out std_logic_vector(31 downto 0);
    USE_TABLE_WSTB  : out std_logic;
    ENABLE       : out std_logic_vector(31 downto 0);
    ENABLE_WSTB  : out std_logic;
    INP       : out std_logic_vector(31 downto 0);
    INP_WSTB  : out std_logic;
    ERROR       : in  std_logic_vector(31 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_pcomp_ctrl;
architecture rtl of panda_pcomp_ctrl is

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
            START <= (others => '0');
            START_WSTB <= '0';
            STEP <= (others => '0');
            STEP_WSTB <= '0';
            WIDTH <= (others => '0');
            WIDTH_WSTB <= '0';
            PNUM <= (others => '0');
            PNUM_WSTB <= '0';
            RELATIVE <= (others => '0');
            RELATIVE_WSTB <= '0';
            DIR <= (others => '0');
            DIR_WSTB <= '0';
            DELTAP <= (others => '0');
            DELTAP_WSTB <= '0';
            USE_TABLE <= (others => '0');
            USE_TABLE_WSTB <= '0';
            ENABLE <= (others => '0');
            ENABLE_WSTB <= '0';
            INP <= (others => '0');
            INP_WSTB <= '0';
        else
            START_WSTB <= '0';
            STEP_WSTB <= '0';
            WIDTH_WSTB <= '0';
            PNUM_WSTB <= '0';
            RELATIVE_WSTB <= '0';
            DIR_WSTB <= '0';
            DELTAP_WSTB <= '0';
            USE_TABLE_WSTB <= '0';
            ENABLE_WSTB <= '0';
            INP_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = PCOMP_START) then
                    START <= mem_dat_i;
                    START_WSTB <= '1';
                end if;
                if (mem_addr = PCOMP_STEP) then
                    STEP <= mem_dat_i;
                    STEP_WSTB <= '1';
                end if;
                if (mem_addr = PCOMP_WIDTH) then
                    WIDTH <= mem_dat_i;
                    WIDTH_WSTB <= '1';
                end if;
                if (mem_addr = PCOMP_PNUM) then
                    PNUM <= mem_dat_i;
                    PNUM_WSTB <= '1';
                end if;
                if (mem_addr = PCOMP_RELATIVE) then
                    RELATIVE <= mem_dat_i;
                    RELATIVE_WSTB <= '1';
                end if;
                if (mem_addr = PCOMP_DIR) then
                    DIR <= mem_dat_i;
                    DIR_WSTB <= '1';
                end if;
                if (mem_addr = PCOMP_DELTAP) then
                    DELTAP <= mem_dat_i;
                    DELTAP_WSTB <= '1';
                end if;
                if (mem_addr = PCOMP_USE_TABLE) then
                    USE_TABLE <= mem_dat_i;
                    USE_TABLE_WSTB <= '1';
                end if;
                if (mem_addr = PCOMP_ENABLE) then
                    ENABLE <= mem_dat_i;
                    ENABLE_WSTB <= '1';
                end if;
                if (mem_addr = PCOMP_INP) then
                    INP <= mem_dat_i;
                    INP_WSTB <= '1';
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
                when PCOMP_ERROR =>
                    mem_dat_o <= ERROR;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;