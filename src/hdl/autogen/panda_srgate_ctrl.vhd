--------------------------------------------------------------------------------
--  File:       panda_srgate_ctrl.vhd
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
entity panda_srgate_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    SET_EDGE       : out std_logic_vector(31 downto 0);
    SET_EDGE_WSTB  : out std_logic;
    RST_EDGE       : out std_logic_vector(31 downto 0);
    RST_EDGE_WSTB  : out std_logic;
    FORCE_SET       : out std_logic_vector(31 downto 0);
    FORCE_SET_WSTB  : out std_logic;
    FORCE_RST       : out std_logic_vector(31 downto 0);
    FORCE_RST_WSTB  : out std_logic;
    SET       : out std_logic_vector(31 downto 0);
    SET_WSTB  : out std_logic;
    RST       : out std_logic_vector(31 downto 0);
    RST_WSTB  : out std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_srgate_ctrl;
architecture rtl of panda_srgate_ctrl is

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
            SET_EDGE <= (others => '0');
            SET_EDGE_WSTB <= '0';
            RST_EDGE <= (others => '0');
            RST_EDGE_WSTB <= '0';
            FORCE_SET <= (others => '0');
            FORCE_SET_WSTB <= '0';
            FORCE_RST <= (others => '0');
            FORCE_RST_WSTB <= '0';
            SET <= (others => '0');
            SET_WSTB <= '0';
            RST <= (others => '0');
            RST_WSTB <= '0';
        else
            SET_EDGE_WSTB <= '0';
            RST_EDGE_WSTB <= '0';
            FORCE_SET_WSTB <= '0';
            FORCE_RST_WSTB <= '0';
            SET_WSTB <= '0';
            RST_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = SRGATE_SET_EDGE) then
                    SET_EDGE <= mem_dat_i;
                    SET_EDGE_WSTB <= '1';
                end if;
                if (mem_addr = SRGATE_RST_EDGE) then
                    RST_EDGE <= mem_dat_i;
                    RST_EDGE_WSTB <= '1';
                end if;
                if (mem_addr = SRGATE_FORCE_SET) then
                    FORCE_SET <= mem_dat_i;
                    FORCE_SET_WSTB <= '1';
                end if;
                if (mem_addr = SRGATE_FORCE_RST) then
                    FORCE_RST <= mem_dat_i;
                    FORCE_RST_WSTB <= '1';
                end if;
                if (mem_addr = SRGATE_SET) then
                    SET <= mem_dat_i;
                    SET_WSTB <= '1';
                end if;
                if (mem_addr = SRGATE_RST) then
                    RST <= mem_dat_i;
                    RST_WSTB <= '1';
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