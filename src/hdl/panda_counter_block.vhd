--------------------------------------------------------------------------------
--  File:       panda_counter_block.vhd
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

entity panda_counter_block is
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
    count_o             : out std_logic_vector(31 downto 0);
    carry_o             : out std_logic
);
end panda_counter_block;

architecture rtl of panda_counter_block is

signal ENABLE_VAL       : std_logic_vector(SBUSBW-1 downto 0);
signal TRIGGER_VAL      : std_logic_vector(SBUSBW-1 downto 0);
signal DIR              : std_logic;
signal START            : std_logic_vector(31 downto 0);
signal START_LOAD       : std_logic;
signal STEP             : std_logic_vector(31 downto 0);

signal enable           : std_logic;
signal trigger          : std_logic;

signal mem_addr         : natural range 0 to (2**mem_addr_i'length - 1);

begin

-- Integer conversion for address.
mem_addr <= to_integer(unsigned(mem_addr_i));

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ENABLE_VAL <= TO_SVECTOR(0, SBUSBW);
            TRIGGER_VAL <= TO_SVECTOR(0, SBUSBW);
            START <= (others => '0');
            START_LOAD <= '0';
            DIR <= '0';
            STEP <= (others => '0');
        else
            START_LOAD <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Enable Control
                if (mem_addr = COUNTER_ENABLE) then
                    ENABLE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Trigger
                if (mem_addr = COUNTER_TRIGGER) then
                    TRIGGER_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Counter Direction
                if (mem_addr = COUNTER_DIR) then
                    DIR <= mem_dat_i(0);
                end if;

                -- Counter Start Value
                if (mem_addr = COUNTER_START) then
                    START <= mem_dat_i;
                    START_LOAD <= '1';
                end if;

                -- Counter Step Value
                if (mem_addr = COUNTER_STEP) then
                    STEP <= mem_dat_i;
                end if;
            end if;
        end if;
    end if;
end process;

--
-- Status Register Read
--
mem_dat_o <= (others => '0');

--
-- Core Input Port Assignments
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        enable <= SBIT(sysbus_i, ENABLE_VAL);
        trigger <= SBIT(sysbus_i, TRIGGER_VAL);
    end if;
end process;


-- LUT Block Core Instantiation
panda_counter : entity work.panda_counter
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    trigger_i           => trigger,
    carry_o             => carry_o,

    DIR                 => DIR,
    START               => START,
    START_LOAD          => START_LOAD,
    STEP                => STEP,

    COUNT               => count_o
);

end rtl;

