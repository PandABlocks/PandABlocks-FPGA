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
signal FORCE_RESET      : std_logic := '0';

signal set              : std_logic := '0';
signal rst              : std_logic := '0';

begin

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            SET_VAL <= TO_SVECTOR(127, SBUSBW);
            RST_VAL <= TO_SVECTOR(126, SBUSBW);
            SET_EDGE <= '1';
            RST_EDGE <= '1';
            FORCE_SET <= '0';
            FORCE_RESET <= '0';
        else
            -- Force strobe is single clock pulse
            FORCE_SET <= '0';
            FORCE_RESET <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr_i = SRGATE_SET_VAL_ADDR) then
                    SET_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr_i = SRGATE_RST_VAL_ADDR) then
                    RST_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Parameters
                if (mem_addr_i = SRGATE_SET_EDGE_ADDR) then
                    SET_EDGE <= mem_dat_i(0);
                end if;

                if (mem_addr_i = SRGATE_RST_EDGE_ADDR) then
                    RST_EDGE <= mem_dat_i(0);
                end if;

                if (mem_addr_i = SRGATE_FORCE_SET_ADDR) then
                    FORCE_SET <= mem_dat_i(0);
                end if;

                if (mem_addr_i = SRGATE_FORCE_RESET_ADDR) then
                    FORCE_RESET <= mem_dat_i(0);
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

    set_i           => set,
    rst_i           => rst,
    out_o           => out_o,

    SET_EDGE        => SET_EDGE,
    RESET_EDGE      => RST_EDGE,
    FORCE_SET       => FORCE_SET,
    FORCE_RESET     => FORCE_RESET
);

end rtl;

