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

signal GATE_VAL         : std_logic_vector(SBUSBW-1 downto 0) := (others => '1');
signal INPA_VAL         : std_logic_vector(SBUSBW-1 downto 0) := (others => '1');
signal INPB_VAL         : std_logic_vector(SBUSBW-1 downto 0) := (others => '1');
signal INPC_VAL         : std_logic_vector(SBUSBW-1 downto 0) := (others => '1');
signal INPD_VAL         : std_logic_vector(SBUSBW-1 downto 0) := (others => '1');

signal PRESCALE         : std_logic_vector(31 downto 0) := (others => '0');
signal SOFT_GATE        : std_logic := '0';
signal TABLE_RST        : std_logic := '0';
signal TABLE_DATA       : std_logic_vector(31 downto 0) := (others => '0');
signal TABLE_WSTB       : std_logic := '0';
signal TABLE_CYCLE      : std_logic_vector(31 downto 0) := (others => '0');
signal TABLE_LENGTH     : std_logic_vector(15 downto 0) := (others => '0');
signal CUR_FRAME        : std_logic_vector(31 downto 0) := (others => '0');
signal CUR_FCYCLES      : std_logic_vector(31 downto 0) := (others => '0');
signal CUR_TCYCLE       : std_logic_vector(31 downto 0) := (others => '0');

signal gate             : std_logic := '0';
signal inpa             : std_logic := '0';
signal inpb             : std_logic := '0';
signal inpc             : std_logic := '0';
signal inpd             : std_logic := '0';

begin

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
            TABLE_RST <= '0';
            TABLE_DATA <= (others => '0');
            TABLE_WSTB <= '0';
            TABLE_CYCLE <= (others => '0');
            TABLE_LENGTH <= (others => '0');
        else
            TABLE_RST <= '0';
            TABLE_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr_i = SEQ_GATE_VAL_ADDR) then
                    GATE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_INPA_VAL_ADDR) then
                    INPA_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_INPB_VAL_ADDR) then
                    INPB_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_INPC_VAL_ADDR) then
                    INPC_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_INPD_VAL_ADDR) then
                    INPD_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SEQ_SOFT_GATE_ADDR) then
                    SOFT_GATE <= mem_dat_i(0);
                end if;

                if (mem_addr_i = SEQ_PRESCALE_ADDR) then
                    PRESCALE <= mem_dat_i;
                end if;

                if (mem_addr_i = SEQ_TABLE_RST_ADDR) then
                    TABLE_RST <= '1';
                end if;

                if (mem_addr_i = SEQ_TABLE_DATA_ADDR) then
                    TABLE_DATA <= mem_dat_i;
                    TABLE_WSTB <= '1';
                end if;

                if (mem_addr_i = SEQ_TABLE_CYCLE_ADDR) then
                    TABLE_CYCLE <= mem_dat_i;
                end if;

                if (mem_addr_i = SEQ_TABLE_LENGTH_ADDR) then
                    TABLE_LENGTH <= mem_dat_i(15 downto 0);
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
            case (mem_addr_i) is
                when SEQ_CUR_FRAME_ADDR =>
                    mem_dat_o <= CUR_FRAME;
                when SEQ_CUR_FCYCLE_ADDR =>
                    mem_dat_o <= CUR_FCYCLES;
                when SEQ_CUR_TCYCLE_ADDR =>
                    mem_dat_o <= CUR_TCYCLE;
--                when SEQ_CUR_STATE_ADDR =>
--                    mem_dat_o <= CUR_STATE;
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
    TABLE_RST           => TABLE_RST,
    TABLE_DATA          => TABLE_DATA,
    TABLE_WSTB          => TABLE_WSTB,
    TABLE_CYCLE         => TABLE_CYCLE,
    TABLE_LENGTH        => TABLE_LENGTH,

    CUR_FRAME           => CUR_FRAME,
    CUR_FCYCLES         => CUR_FCYCLES,
    CUR_TCYCLE          => CUR_TCYCLE,
    CUR_STATE           => open
);

end rtl;

