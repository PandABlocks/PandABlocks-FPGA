--------------------------------------------------------------------------------
--  File:       panda_qdec_ctrl.vhd
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
entity panda_qdec_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    RST_ON_Z       : out std_logic_vector(31 downto 0);
    RST_ON_Z_WSTB  : out std_logic;
    SETP       : out std_logic_vector(31 downto 0);
    SETP_WSTB  : out std_logic;
    A       : out std_logic_vector(31 downto 0);
    A_WSTB  : out std_logic;
    B       : out std_logic_vector(31 downto 0);
    B_WSTB  : out std_logic;
    Z       : out std_logic_vector(31 downto 0);
    Z_WSTB  : out std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_qdec_ctrl;
architecture rtl of panda_qdec_ctrl is

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
            RST_ON_Z <= (others => '0');
            RST_ON_Z_WSTB <= '0';
            SETP <= (others => '0');
            SETP_WSTB <= '0';
            A <= (others => '0');
            A_WSTB <= '0';
            B <= (others => '0');
            B_WSTB <= '0';
            Z <= (others => '0');
            Z_WSTB <= '0';
        else
            RST_ON_Z_WSTB <= '0';
            SETP_WSTB <= '0';
            A_WSTB <= '0';
            B_WSTB <= '0';
            Z_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = QDEC_RST_ON_Z) then
                    RST_ON_Z <= mem_dat_i;
                    RST_ON_Z_WSTB <= '1';
                end if;
                if (mem_addr = QDEC_SETP) then
                    SETP <= mem_dat_i;
                    SETP_WSTB <= '1';
                end if;
                if (mem_addr = QDEC_A) then
                    A <= mem_dat_i;
                    A_WSTB <= '1';
                end if;
                if (mem_addr = QDEC_B) then
                    B <= mem_dat_i;
                    B_WSTB <= '1';
                end if;
                if (mem_addr = QDEC_Z) then
                    Z <= mem_dat_i;
                    Z_WSTB <= '1';
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