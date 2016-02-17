--------------------------------------------------------------------------------
--  File:       panda_sequencer_block.vhd
--  Desc:       Position compare output sequencer generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_sequencer_block is
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
    -- Output sequencer
    outa_o              : out std_logic;
    outb_o              : out std_logic;
    outc_o              : out std_logic;
    outd_o              : out std_logic;
    oute_o              : out std_logic;
    outf_o              : out std_logic;
    active_o            : out std_logic
);
end panda_sequencer_block;

architecture rtl of panda_sequencer_block is

signal GATE_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal INPA_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal INPB_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal INPC_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal INPD_VAL         : std_logic_vector(SBUSBW-1 downto 0);

signal PRESCALE         : std_logic_vector(31 downto 0);
signal SOFT_GATE        : std_logic;
signal TABLE_START      : std_logic;
signal TABLE_DATA       : std_logic_vector(31 downto 0);
signal TABLE_WSTB       : std_logic;
signal TABLE_CYCLE      : std_logic_vector(31 downto 0);
signal TABLE_LENGTH     : std_logic_vector(15 downto 0);
signal TABLE_LENGTH_WSTB: std_logic;
signal CUR_FRAME        : std_logic_vector(31 downto 0);
signal CUR_FCYCLE       : std_logic_vector(31 downto 0);
signal CUR_TCYCLE       : std_logic_vector(31 downto 0);

signal gate             : std_logic;
signal inpa             : std_logic;
signal inpb             : std_logic;
signal inpc             : std_logic;
signal inpd             : std_logic;

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
            GATE_VAL <= TO_SVECTOR(0, SBUSBW);
            INPA_VAL <= TO_SVECTOR(0, SBUSBW);
            INPB_VAL <= TO_SVECTOR(0, SBUSBW);
            INPC_VAL <= TO_SVECTOR(0, SBUSBW);
            INPD_VAL <= TO_SVECTOR(0, SBUSBW);
            PRESCALE <= (others => '0');
            SOFT_GATE <= '0';
            TABLE_START <= '0';
            TABLE_DATA <= (others => '0');
            TABLE_WSTB <= '0';
            TABLE_CYCLE <= (others => '0');
            TABLE_LENGTH <= (others => '0');
            TABLE_LENGTH_WSTB <= '0';
        else
            TABLE_START <= '0';
            TABLE_WSTB <= '0';
            TABLE_LENGTH_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = SEQ_GATE) then
                    GATE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = SEQ_INPA) then
                    INPA_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = SEQ_INPB) then
                    INPB_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = SEQ_INPC) then
                    INPC_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = SEQ_INPD) then
                    INPD_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = SEQ_SOFT_GATE) then
                    SOFT_GATE <= mem_dat_i(0);
                end if;

                if (mem_addr = SEQ_PRESCALE) then
                    PRESCALE <= mem_dat_i;
                end if;

                if (mem_addr = SEQ_TABLE_START) then
                    TABLE_START <= '1';
                end if;

                if (mem_addr = SEQ_TABLE_DATA) then
                    TABLE_DATA <= mem_dat_i;
                    TABLE_WSTB <= '1';
                end if;

                if (mem_addr = SEQ_TABLE_CYCLE) then
                    TABLE_CYCLE <= mem_dat_i;
                end if;

                if (mem_addr = SEQ_TABLE_LENGTH) then
                    TABLE_LENGTH <= mem_dat_i(15 downto 0);
                    TABLE_LENGTH_WSTB <= '1';
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

--
-- Core Input Port Assignments
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        gate <= SBIT(sysbus_i, GATE_VAL);
        inpa <= SBIT(sysbus_i, INPA_VAL);
        inpb <= SBIT(sysbus_i, INPB_VAL);
        inpc <= SBIT(sysbus_i, INPC_VAL);
        inpd <= SBIT(sysbus_i, INPD_VAL);
    end if;
end process;

-- LUT Block Core Instantiation
panda_sequencer : entity work.panda_sequencer
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    gate_i              => gate,
    inpa_i              => inpa,
    inpb_i              => inpb,
    inpc_i              => inpc,
    inpd_i              => inpd,
    outa_o              => outa_o,
    outb_o              => outb_o,
    outc_o              => outc_o,
    outd_o              => outd_o,
    oute_o              => oute_o,
    outf_o              => outf_o,
    active_o            => active_o,

    PRESCALE            => PRESCALE,
    SOFT_GATE           => SOFT_GATE,
    TABLE_START         => TABLE_START,
    TABLE_DATA          => TABLE_DATA,
    TABLE_WSTB          => TABLE_WSTB,
    TABLE_CYCLE         => TABLE_CYCLE,
    TABLE_LENGTH        => TABLE_LENGTH,
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB,

    CUR_FRAME           => CUR_FRAME,
    CUR_FCYCLE          => CUR_FCYCLE,
    CUR_TCYCLE          => CUR_TCYCLE
);

end rtl;

