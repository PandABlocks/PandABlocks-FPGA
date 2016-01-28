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
                if (mem_addr = PCOMP_ENABLE) then
                    ENABLE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Pulse start position
                if (mem_addr = PCOMP_POSN) then
                    POSN_VAL <= mem_dat_i(PBUSBW-1 downto 0);
                end if;

                -- Pulse start position
                if (mem_addr = PCOMP_START) then
                    START <= mem_dat_i;
                end if;

                -- Pulse step value
                if (mem_addr = PCOMP_STEP) then
                    STEP <= mem_dat_i;
                end if;

                -- Pulse width value
                if (mem_addr = PCOMP_WIDTH) then
                    WIDTH <= mem_dat_i;
                end if;

                -- Pulse count value
                if (mem_addr = PCOMP_NUMBER) then
                    NUM <= mem_dat_i;
                end if;

                -- PComp relative flag
                if (mem_addr = PCOMP_RELATIVE) then
                    RELATIVE <= mem_dat_i(0);
                end if;

                -- PComp direction flag
                if (mem_addr = PCOMP_DIR) then
                    DIR <= mem_dat_i(0);
                end if;

                -- PComp direction filter DeltaT flag
                if (mem_addr = PCOMP_FLTR_DELTAT) then
                    FLTR_DELTAT <= mem_dat_i;
                end if;

                -- PComp direction filter threshold flag
                if (mem_addr = PCOMP_FLTR_THOLD) then
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
begin
    if rising_edge(clk_i) then
        enable <= SBIT(sysbus_i, ENABLE_VAL);
        posn <= PFIELD(posbus_i, POSN_VAL);
    end if;
end process;

--
-- Position Compare IP
--
pcomp_inst : entity work.panda_pcomp
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    posn_i              => posn,

    START               => START,
    STEP                => STEP,
    WIDTH               => WIDTH,
    NUM                 => NUM,
    RELATIVE            => RELATIVE,
    DIR                 => DIR,
    FLTR_DELTAT         => FLTR_DELTAT,
    FLTR_THOLD          => FLTR_THOLD,

    act_o               => act_o,
    err_o               => open,
    pulse_o             => pulse_o
);

end rtl;

