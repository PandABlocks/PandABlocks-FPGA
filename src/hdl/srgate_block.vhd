--------------------------------------------------------------------------------
--  File:       panda_srgate_block.vhd
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

entity panda_srgate_block is
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
    -- Output pulse
    out_o               : out std_logic
);
end panda_srgate_block;

architecture rtl of panda_srgate_block is

signal SET_VAL          : std_logic_vector(SBUSBW-1 downto 0) := (others => '1');
signal RST_VAL          : std_logic_vector(SBUSBW-1 downto 0) := (others => '1');
signal SET_EDGE         : std_logic := '0';
signal RST_EDGE         : std_logic := '0';
signal FORCE_SET        : std_logic := '0';
signal FORCE_RST        : std_logic := '0';

signal set              : std_logic := '0';
signal rst              : std_logic := '0';

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
            SET_VAL <= TO_SVECTOR(0, SBUSBW);
            RST_VAL <= TO_SVECTOR(0, SBUSBW);
            SET_EDGE <= '0';
            RST_EDGE <= '0';
            FORCE_SET <= '0';
            FORCE_RST <= '0';
        else
            -- Force strobe is single clock pulse
            FORCE_SET <= '0';
            FORCE_RST <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = SRGATE_SET) then
                    SET_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = SRGATE_RST) then
                    RST_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Parameters
                if (mem_addr = SRGATE_SET_EDGE) then
                    SET_EDGE <= mem_dat_i(0);
                end if;

                if (mem_addr = SRGATE_RST_EDGE) then
                    RST_EDGE <= mem_dat_i(0);
                end if;

                if (mem_addr = SRGATE_FORCE_SET) then
                    FORCE_SET <= mem_dat_i(0);
                end if;

                if (mem_addr = SRGATE_FORCE_RST) then
                    FORCE_RST <= mem_dat_i(0);
                end if;

            end if;
        end if;
    end if;
end process;

--
-- Core Input Port Assignments
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        set <= SBIT(sysbus_i, SET_VAL);
        rst <= SBIT(sysbus_i, RST_VAL);
    end if;
end process;


-- LUT Block Core Instantiation
panda_srgate : entity work.panda_srgate
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,

    set_i           => set,
    rst_i           => rst,
    out_o           => out_o,

    SET_EDGE        => SET_EDGE,
    RST_EDGE        => RST_EDGE,
    FORCE_SET       => FORCE_SET,
    FORCE_RST       => FORCE_RST
);

end rtl;

