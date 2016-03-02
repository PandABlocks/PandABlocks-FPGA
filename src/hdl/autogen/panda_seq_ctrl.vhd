--------------------------------------------------------------------------------
--  File:       panda_seq_ctrl.vhd
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
entity panda_seq_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    PRESCALE       : out std_logic_vector(31 downto 0);
    PRESCALE_WSTB  : out std_logic;
    TABLE_CYCLE       : out std_logic_vector(31 downto 0);
    TABLE_CYCLE_WSTB  : out std_logic;
    ENABLE       : out std_logic_vector(31 downto 0);
    ENABLE_WSTB  : out std_logic;
    INPA       : out std_logic_vector(31 downto 0);
    INPA_WSTB  : out std_logic;
    INPB       : out std_logic_vector(31 downto 0);
    INPB_WSTB  : out std_logic;
    INPC       : out std_logic_vector(31 downto 0);
    INPC_WSTB  : out std_logic;
    INPD       : out std_logic_vector(31 downto 0);
    INPD_WSTB  : out std_logic;
    CUR_FRAME       : in  std_logic_vector(31 downto 0);
    CUR_FCYCLE       : in  std_logic_vector(31 downto 0);
    CUR_TCYCLE       : in  std_logic_vector(31 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_seq_ctrl;
architecture rtl of panda_seq_ctrl is

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
            PRESCALE <= (others => '0');
            PRESCALE_WSTB <= '0';
            TABLE_CYCLE <= (others => '0');
            TABLE_CYCLE_WSTB <= '0';
            ENABLE <= (others => '0');
            ENABLE_WSTB <= '0';
            INPA <= (others => '0');
            INPA_WSTB <= '0';
            INPB <= (others => '0');
            INPB_WSTB <= '0';
            INPC <= (others => '0');
            INPC_WSTB <= '0';
            INPD <= (others => '0');
            INPD_WSTB <= '0';
        else
            PRESCALE_WSTB <= '0';
            TABLE_CYCLE_WSTB <= '0';
            ENABLE_WSTB <= '0';
            INPA_WSTB <= '0';
            INPB_WSTB <= '0';
            INPC_WSTB <= '0';
            INPD_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = SEQ_PRESCALE) then
                    PRESCALE <= mem_dat_i;
                    PRESCALE_WSTB <= '1';
                end if;
                if (mem_addr = SEQ_TABLE_CYCLE) then
                    TABLE_CYCLE <= mem_dat_i;
                    TABLE_CYCLE_WSTB <= '1';
                end if;
                if (mem_addr = SEQ_ENABLE) then
                    ENABLE <= mem_dat_i;
                    ENABLE_WSTB <= '1';
                end if;
                if (mem_addr = SEQ_INPA) then
                    INPA <= mem_dat_i;
                    INPA_WSTB <= '1';
                end if;
                if (mem_addr = SEQ_INPB) then
                    INPB <= mem_dat_i;
                    INPB_WSTB <= '1';
                end if;
                if (mem_addr = SEQ_INPC) then
                    INPC <= mem_dat_i;
                    INPC_WSTB <= '1';
                end if;
                if (mem_addr = SEQ_INPD) then
                    INPD <= mem_dat_i;
                    INPD_WSTB <= '1';
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
                when SEQ_CUR_FRAME =>
                    mem_dat_o <= CUR_FRAME;
                when SEQ_CUR_FCYCLE =>
                    mem_dat_o <= CUR_FCYCLE;
                when SEQ_CUR_TCYCLE =>
                    mem_dat_o <= CUR_TCYCLE;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;