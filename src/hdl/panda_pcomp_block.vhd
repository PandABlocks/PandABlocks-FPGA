--------------------------------------------------------------------------------
--  File:       panda_pcomp_block.vhd
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

entity panda_pcomp_block is
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
    posbus_i            : in  posbus_t;
    -- Output pulse
    act_o               : out std_logic;
    pulse_o             : out std_logic
);
end panda_pcomp_block;

architecture rtl of panda_pcomp_block is

type state_t is (IDLE, POS, NEG);

signal ENABLE_VAL       : std_logic_vector(SBUSBW-1 downto 0);
signal POSN_VAL         : std_logic_vector(PBUSBW-1 downto 0);
signal START            : std_logic_vector(31 downto 0);
signal STEP             : std_logic_vector(31 downto 0);
signal WIDTH            : std_logic_vector(31 downto 0);
signal NUM              : std_logic_vector(31 downto 0);
signal RELATIVE         : std_logic;
signal DIR              : std_logic;
signal FLTR_DELTAT      : std_logic_vector(31 downto 0);
signal FLTR_THOLD       : std_logic_vector(15 downto 0);

signal enable           : std_logic;
signal posn             : std_logic_vector(31 downto 0);

begin

mem_dat_o <= (others => '0');

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ENABLE_VAL <= TO_SVECTOR(0, SBUSBW);
            POSN_VAL <= (others => '0');
            DIR <= '0';
            START <= (others => '0');
            STEP <= (others => '0');
            WIDTH <= (others => '0');
            NUM <= (others => '0');
            RELATIVE <= '0';
            FLTR_DELTAT <= (others => '0');
            FLTR_THOLD <= (others => '0');
        else
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Pulse start position
                if (mem_addr_i = PCOMP_ENABLE_VAL_ADDR) then
                    ENABLE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Pulse start position
                if (mem_addr_i = PCOMP_POSN_VAL_ADDR) then
                    POSN_VAL <= mem_dat_i(PBUSBW-1 downto 0);
                end if;

                -- Pulse start position
                if (mem_addr_i = PCOMP_START_ADDR) then
                    START <= mem_dat_i;
                end if;

                -- Pulse step value
                if (mem_addr_i = PCOMP_STEP_ADDR) then
                    STEP <= mem_dat_i;
                end if;

                -- Pulse width value
                if (mem_addr_i = PCOMP_WIDTH_ADDR) then
                    WIDTH <= mem_dat_i;
                end if;

                -- Pulse count value
                if (mem_addr_i = PCOMP_NUM_ADDR) then
                    NUM <= mem_dat_i;
                end if;

                -- PComp relative flag
                if (mem_addr_i = PCOMP_RELATIVE_ADDR) then
                    RELATIVE <= mem_dat_i(0);
                end if;

                -- PComp direction flag
                if (mem_addr_i = PCOMP_DIR_ADDR) then
                    DIR <= mem_dat_i(0);
                end if;

                -- PComp direction filter DeltaT flag
                if (mem_addr_i = PCOMP_FLTR_DELTAT_ADDR) then
                    FLTR_DELTAT <= mem_dat_i;
                end if;

                -- PComp direction filter threshold flag
                if (mem_addr_i = PCOMP_FLTR_THOLD_ADDR) then
                    FLTR_THOLD <= mem_dat_i(15 downto 0);
                end if;

            end if;
        end if;
    end if;
end process;

--
-- Design Bus Assignments
--
process(clk_i)
    variable t_counter  : unsigned(31 downto 0);
begin
    if rising_edge(clk_i) then
        enable <= SBIT(sysbus_i, ENABLE_VAL);
        posn <= PFIELD(posbus_i, POSN_VAL);
    end if;
end process;

--
-- Position Compare IP
--
panda_pcomp_inst : entity work.panda_pcomp
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    posn_i              => posn,

    PCOMP_START         => START,
    PCOMP_STEP          => STEP,
    PCOMP_WIDTH         => WIDTH,
    PCOMP_NUM           => NUM,
    PCOMP_RELATIVE      => RELATIVE,
    PCOMP_DIR           => DIR,
    PCOMP_FLTR_DELTAT   => FLTR_DELTAT,
    PCOMP_FLTR_THOLD    => FLTR_THOLD,

    act_o               => act_o,
    pulse_o             => pulse_o
);

end rtl;

