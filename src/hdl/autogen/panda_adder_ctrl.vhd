--------------------------------------------------------------------------------
--  File:       panda_adder_ctrl.vhd
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
entity panda_adder_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    INPA       : out std_logic_vector(31 downto 0);
    INPA_WSTB  : out std_logic;
    INPB       : out std_logic_vector(31 downto 0);
    INPB_WSTB  : out std_logic;
    INPC       : out std_logic_vector(31 downto 0);
    INPC_WSTB  : out std_logic;
    INPD       : out std_logic_vector(31 downto 0);
    INPD_WSTB  : out std_logic;
    SCALE       : out std_logic_vector(31 downto 0);
    SCALE_WSTB  : out std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_adder_ctrl;
architecture rtl of panda_adder_ctrl is

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
            INPA <= (others => '0');
            INPA_WSTB <= '0';
            INPB <= (others => '0');
            INPB_WSTB <= '0';
            INPC <= (others => '0');
            INPC_WSTB <= '0';
            INPD <= (others => '0');
            INPD_WSTB <= '0';
            SCALE <= (others => '0');
            SCALE_WSTB <= '0';
        else
            INPA_WSTB <= '0';
            INPB_WSTB <= '0';
            INPC_WSTB <= '0';
            INPD_WSTB <= '0';
            SCALE_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = ADDER_INPA) then
                    INPA <= mem_dat_i;
                    INPA_WSTB <= '1';
                end if;
                if (mem_addr = ADDER_INPB) then
                    INPB <= mem_dat_i;
                    INPB_WSTB <= '1';
                end if;
                if (mem_addr = ADDER_INPC) then
                    INPC <= mem_dat_i;
                    INPC_WSTB <= '1';
                end if;
                if (mem_addr = ADDER_INPD) then
                    INPD <= mem_dat_i;
                    INPD_WSTB <= '1';
                end if;
                if (mem_addr = ADDER_SCALE) then
                    SCALE <= mem_dat_i;
                    SCALE_WSTB <= '1';
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