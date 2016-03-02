--------------------------------------------------------------------------------
--  File:       panda_pulse_ctrl.vhd
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
entity panda_pulse_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    DELAY       : out std_logic_vector(63 downto 0);
    DELAY_WSTB  : out std_logic;
    WIDTH       : out std_logic_vector(63 downto 0);
    WIDTH_WSTB  : out std_logic;
    INP       : out std_logic_vector(31 downto 0);
    INP_WSTB  : out std_logic;
    ENABLE       : out std_logic_vector(31 downto 0);
    ENABLE_WSTB  : out std_logic;
    ERR_OVERFLOW       : in  std_logic_vector(31 downto 0);
    ERR_PERIOD       : in  std_logic_vector(31 downto 0);
    QUEUE       : in  std_logic_vector(31 downto 0);
    MISSED_CNT       : in  std_logic_vector(31 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_pulse_ctrl;
architecture rtl of panda_pulse_ctrl is

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
            DELAY <= (others => '0');
            DELAY_WSTB <= '0';
            WIDTH <= (others => '0');
            WIDTH_WSTB <= '0';
            INP <= (others => '0');
            INP_WSTB <= '0';
            ENABLE <= (others => '0');
            ENABLE_WSTB <= '0';
        else
            DELAY_WSTB <= '0';
            WIDTH_WSTB <= '0';
            INP_WSTB <= '0';
            ENABLE_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = PULSE_DELAY_L) then
                    DELAY(31 downto 0)<= mem_dat_i;
                end if;
                if (mem_addr = PULSE_DELAY_H) then
                    DELAY(63 downto 32)<= mem_dat_i;
                    DELAY_WSTB <= '1';
                end if;
                if (mem_addr = PULSE_WIDTH_L) then
                    WIDTH(31 downto 0)<= mem_dat_i;
                end if;
                if (mem_addr = PULSE_WIDTH_H) then
                    WIDTH(63 downto 32)<= mem_dat_i;
                    WIDTH_WSTB <= '1';
                end if;
                if (mem_addr = PULSE_INP) then
                    INP <= mem_dat_i;
                    INP_WSTB <= '1';
                end if;
                if (mem_addr = PULSE_ENABLE) then
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
                when PULSE_ERR_OVERFLOW =>
                    mem_dat_o <= ERR_OVERFLOW;
                when PULSE_ERR_PERIOD =>
                    mem_dat_o <= ERR_PERIOD;
                when PULSE_QUEUE =>
                    mem_dat_o <= QUEUE;
                when PULSE_MISSED_CNT =>
                    mem_dat_o <= MISSED_CNT;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;