--------------------------------------------------------------------------------
--  File:       panda_lut_block.vhd
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

entity panda_lut_block is
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
end panda_lut_block;

architecture rtl of panda_lut_block is

signal INPA_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal INPB_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal INPC_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal INPD_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal INPE_VAL         : std_logic_vector(SBUSBW-1 downto 0);
signal FUNC             : std_logic_vector(31 downto 0);

signal inpa             : std_logic;
signal inpb             : std_logic;
signal inpc             : std_logic;
signal inpd             : std_logic;
signal inpe             : std_logic;

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
            INPA_VAL <= TO_SVECTOR(0, SBUSBW);
            INPB_VAL <= TO_SVECTOR(0, SBUSBW);
            INPC_VAL <= TO_SVECTOR(0, SBUSBW);
            INPD_VAL <= TO_SVECTOR(0, SBUSBW);
            INPE_VAL <= TO_SVECTOR(0, SBUSBW);
            FUNC <= (others => '0');
        else
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = LUT_INPA) then
                    INPA_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = LUT_INPB) then
                    INPB_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = LUT_INPC) then
                    INPC_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = LUT_INPD) then
                    INPD_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                if (mem_addr = LUT_INPE) then
                    INPE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- LUT Function value
                if (mem_addr = LUT_FUNC) then
                    FUNC <= mem_dat_i;
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
        inpa <= SBIT(sysbus_i, INPA_VAL);
        inpb <= SBIT(sysbus_i, INPB_VAL);
        inpc <= SBIT(sysbus_i, INPC_VAL);
        inpd <= SBIT(sysbus_i, INPD_VAL);
        inpe <= SBIT(sysbus_i, INPE_VAL);
    end if;
end process;


-- LUT Block Core Instantiation
panda_lut : entity work.panda_lut
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,

    inpa_i      => inpa,
    inpb_i      => inpb,
    inpc_i      => inpc,
    inpd_i      => inpd,
    inpe_i      => inpe,
    out_o       => out_o,

    FUNC        => FUNC
);


end rtl;

