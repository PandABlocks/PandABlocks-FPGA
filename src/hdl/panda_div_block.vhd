--------------------------------------------------------------------------------
--  File:       panda_div_block.vhd
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

entity panda_div_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    -- Output pulse
    outd_o              : out std_logic;
    outn_o              : out std_logic
);
end panda_div_block;

architecture rtl of panda_div_block is

signal INP_VAL      : std_logic_vector(SBUSBW-1 downto 0) := (others => '1');
signal RST_VAL      : std_logic_vector(SBUSBW-1 downto 0) := (others => '1');
signal FIRST_PULSE  : std_logic := '0';
signal DIVISOR      : std_logic_vector(31 downto 0) := (others => '0');
signal COUNT        : std_logic_vector(31 downto 0) := (others => '0');
signal FORCE_RST    : std_logic := '0';

signal inp          : std_logic := '0';
signal rst          : std_logic := '0';

begin

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            INP_VAL <= TO_SVECTOR(127, SBUSBW);
            RST_VAL <= TO_SVECTOR(126, SBUSBW);
            FIRST_PULSE <= '0';
            DIVISOR <= X"0000_0001";
            FORCE_RST <= '0';
        else
            FORCE_RST <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr_i = DIV_INP_VAL_ADDR) then
                    INP_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = DIV_RST_VAL_ADDR) then
                    RST_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = DIV_FIRST_PULSE_ADDR) then
                    FIRST_PULSE <= mem_dat_i(0);
                end if;

                if (mem_addr_i = DIV_DIVISOR_ADDR) then
                    DIVISOR <= mem_dat_i;
                end if;

                if (mem_addr_i = DIV_FORCE_RST_ADDR) then
                    FORCE_RST <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

-- There is only 1 status register to read so no need to waste
-- a case statement.
REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        mem_dat_o <= COUNT;
    end if;
end process;

--
-- Core Input Port Assignments
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        inp <= SBIT(sysbus_i, INP_VAL);
        rst <= SBIT(sysbus_i, RST_VAL);
    end if;
end process;


-- LUT Block Core Instantiation
panda_div : entity work.panda_div
port map (
    clk_i               => clk_i,

    inp_i               => inp,
    rst_i               => rst,
    outd_o              => outd_o,
    outn_o              => outn_o,

    FIRST_PULSE         => FIRST_PULSE,
    DIVISOR             => DIVISOR,
    FORCE_RST           => FORCE_RST,

    COUNT               => COUNT
);

end rtl;

