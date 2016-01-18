--------------------------------------------------------------------------------
--  File:       panda_pulse_block.vhd
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

entity panda_pulse_block is
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
    out_o               : out std_logic;
    perr_o              : out std_logic
);
end panda_pulse_block;

architecture rtl of panda_pulse_block is

signal INP_VAL      : std_logic_vector(SBUSBW-1 downto 0) := (others => '0');
signal RST_VAL      : std_logic_vector(SBUSBW-1 downto 0) := (others => '0');
signal DELAY        : std_logic_vector(47 downto 0) := (others => '0');
signal WIDTH        : std_logic_vector(47 downto 0) := (others => '0');
signal FORCE_RST    : std_logic := '0';
signal MISSED_CNT   : std_logic_vector(31 downto 0) := (others => '0');
signal ERR_OVERFLOW : std_logic := '0';
signal ERR_PERIOD   : std_logic := '0';
signal QUEUE        : std_logic_vector(10 downto 0);

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
            INP_VAL <= TO_SVECTOR(0, SBUSBW);
            RST_VAL <= TO_SVECTOR(0, SBUSBW);
            DELAY <= (others => '0');
            WIDTH <= (others => '0');
            FORCE_RST <= '0';
        else
            FORCE_RST <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr_i = PULSE_INP_VAL_ADDR) then
                    INP_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = PULSE_RST_VAL_ADDR) then
                    RST_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = PULSE_DELAY_L_ADDR) then
                    DELAY(31 downto 0)<= mem_dat_i;
                end if;

                if (mem_addr_i = PULSE_DELAY_H_ADDR) then
                    DELAY(47 downto 32)<= mem_dat_i(15 downto 0);
                end if;

                if (mem_addr_i = PULSE_WIDTH_L_ADDR) then
                    WIDTH(31 downto 0)<= mem_dat_i;
                end if;

                if (mem_addr_i = PULSE_WIDTH_H_ADDR) then
                    WIDTH(47 downto 32)<= mem_dat_i(15 downto 0);
                end if;

                if (mem_addr_i = PULSE_FORCE_RST_ADDR) then
                    FORCE_RST <= '1';
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
            case (mem_addr_i) is
                when PULSE_ERR_OVERFLOW_ADDR =>
                    mem_dat_o <= ZEROS(31) & ERR_OVERFLOW;
                when PULSE_ERR_PERIOD_ADDR =>
                    mem_dat_o <= ZEROS(31) & ERR_PERIOD;
                when PULSE_QUEUE_ADDR =>
                    mem_dat_o <= ZEROS(21) & QUEUE;
                when PULSE_MISSED_CNT_ADDR =>
                    mem_dat_o <= MISSED_CNT;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
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
panda_pulse : entity work.panda_pulse
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    inp_i               => inp,
    rst_i               => rst,
    out_o               => out_o,
    perr_o              => perr_o,

    DELAY               => DELAY,
    WIDTH               => WIDTH,
    FORCE_RST           => FORCE_RST,
    ERR_OVERFLOW        => ERR_OVERFLOW,
    ERR_PERIOD          => ERR_PERIOD,
    QUEUE               => QUEUE,
    MISSED_CNT          => MISSED_CNT
);

end rtl;

