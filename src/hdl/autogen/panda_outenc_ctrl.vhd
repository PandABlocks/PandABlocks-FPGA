--------------------------------------------------------------------------------
--  File:       panda_outenc_ctrl.vhd
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
entity panda_outenc_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    PROTOCOL       : out std_logic_vector(31 downto 0);
    PROTOCOL_WSTB  : out std_logic;
    BITS       : out std_logic_vector(31 downto 0);
    BITS_WSTB  : out std_logic;
    QPERIOD       : out std_logic_vector(31 downto 0);
    QPERIOD_WSTB  : out std_logic;
    ENABLE       : out std_logic_vector(31 downto 0);
    ENABLE_WSTB  : out std_logic;
    A       : out std_logic_vector(31 downto 0);
    A_WSTB  : out std_logic;
    B       : out std_logic_vector(31 downto 0);
    B_WSTB  : out std_logic;
    Z       : out std_logic_vector(31 downto 0);
    Z_WSTB  : out std_logic;
    VAL       : out std_logic_vector(31 downto 0);
    VAL_WSTB  : out std_logic;
    CONN       : out std_logic_vector(31 downto 0);
    CONN_WSTB  : out std_logic;
    QSTATE       : in  std_logic_vector(31 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_outenc_ctrl;
architecture rtl of panda_outenc_ctrl is

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
            PROTOCOL <= (others => '0');
            PROTOCOL_WSTB <= '0';
            BITS <= (others => '0');
            BITS_WSTB <= '0';
            QPERIOD <= (others => '0');
            QPERIOD_WSTB <= '0';
            ENABLE <= (others => '0');
            ENABLE_WSTB <= '0';
            A <= (others => '0');
            A_WSTB <= '0';
            B <= (others => '0');
            B_WSTB <= '0';
            Z <= (others => '0');
            Z_WSTB <= '0';
            VAL <= (others => '0');
            VAL_WSTB <= '0';
            CONN <= (others => '0');
            CONN_WSTB <= '0';
        else
            PROTOCOL_WSTB <= '0';
            BITS_WSTB <= '0';
            QPERIOD_WSTB <= '0';
            ENABLE_WSTB <= '0';
            A_WSTB <= '0';
            B_WSTB <= '0';
            Z_WSTB <= '0';
            VAL_WSTB <= '0';
            CONN_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = OUTENC_PROTOCOL) then
                    PROTOCOL <= mem_dat_i;
                    PROTOCOL_WSTB <= '1';
                end if;
                if (mem_addr = OUTENC_BITS) then
                    BITS <= mem_dat_i;
                    BITS_WSTB <= '1';
                end if;
                if (mem_addr = OUTENC_QPERIOD) then
                    QPERIOD <= mem_dat_i;
                    QPERIOD_WSTB <= '1';
                end if;
                if (mem_addr = OUTENC_ENABLE) then
                    ENABLE <= mem_dat_i;
                    ENABLE_WSTB <= '1';
                end if;
                if (mem_addr = OUTENC_A) then
                    A <= mem_dat_i;
                    A_WSTB <= '1';
                end if;
                if (mem_addr = OUTENC_B) then
                    B <= mem_dat_i;
                    B_WSTB <= '1';
                end if;
                if (mem_addr = OUTENC_Z) then
                    Z <= mem_dat_i;
                    Z_WSTB <= '1';
                end if;
                if (mem_addr = OUTENC_VAL) then
                    VAL <= mem_dat_i;
                    VAL_WSTB <= '1';
                end if;
                if (mem_addr = OUTENC_CONN) then
                    CONN <= mem_dat_i;
                    CONN_WSTB <= '1';
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
                when OUTENC_QSTATE =>
                    mem_dat_o <= QSTATE;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;