--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : REG block is a special block providing access to TOP level
--                status information.
--                This block is mapped onto a page on address space, but is
--                handled specially by tcp server.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.addr_defines.all;
use work.top_defines.all;
use work.panda_version.all;

entity reg_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_rstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Readback signals
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    cmd_ready_n_i       : in  std_logic;
    SLOW_FPGA_VERSION   : in  std_logic_vector(31 downto 0)
);
end reg_top;

architecture rtl of reg_top is

signal BIT_READ_RST         : std_logic;
signal BIT_READ_RSTB        : std_logic;
signal BIT_READ_VALUE       : std_logic_vector(31 downto 0);
signal POS_READ_RST         : std_logic;
signal POS_READ_RSTB        : std_logic;
signal POS_READ_VALUE       : std_logic_vector(31 downto 0);
signal POS_READ_CHANGES     : std_logic_vector(31 downto 0);

signal mem_addr         : natural range 0 to (2**mem_addr_i'length - 1);

begin

-- Integer conversion for address.
mem_addr <= to_integer(unsigned(mem_addr_i));

--------------------------------------------------------------------------
-- Control System Register Write Interface
--------------------------------------------------------------------------
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            BIT_READ_RST <= '0';
            POS_READ_RST <= '0';
        else
            BIT_READ_RST <= '0';
            POS_READ_RST <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- System Bus Read Start
                if (mem_addr = REG_BIT_READ_RST) then
                    BIT_READ_RST <= '1';
                end if;

                -- Position Bus Read Start
                if (mem_addr = REG_POS_READ_RST) then
                    POS_READ_RST <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

-- System Bus and Position bus fields are read sequentially, and read strobe
-- is used to increment the field index
BIT_READ_RSTB <= '1' when (mem_cs_i = '1' and mem_rstb_i = '1' and
                 mem_addr = REG_BIT_READ_VALUE) else '0';

POS_READ_RSTB <= '1' when (mem_cs_i = '1' and mem_rstb_i = '1' and
                 mem_addr = REG_POS_READ_VALUE) else '0';

--------------------------------------------------------------------------
-- Status Register Read
--------------------------------------------------------------------------
REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            mem_dat_o <= (others => '0');
        else
            case (mem_addr) is
                when REG_FPGA_VERSION =>
                    mem_dat_o <= FPGA_VERSION;
                when REG_FPGA_BUILD =>
                    mem_dat_o <= FPGA_VERSION;
                when REG_SLOW_VERSION =>
                    mem_dat_o <= SLOW_FPGA_VERSION;
                when REG_BIT_READ_VALUE =>
                    mem_dat_o <= BIT_READ_VALUE;
                when REG_POS_READ_VALUE =>
                    mem_dat_o <= POS_READ_VALUE;
                when REG_POS_READ_CHANGES =>
                    mem_dat_o <= POS_READ_CHANGES;
                when REG_SLOW_REGISTER_STATUS =>
                    mem_dat_o <= ZEROS(31) & cmd_ready_n_i;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Instantiate Special REG* block
--------------------------------------------------------------------------
reg_inst : entity work.reg
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    BIT_READ_RST        => BIT_READ_RST,
    BIT_READ_RSTB       => BIT_READ_RSTB,
    BIT_READ_VALUE      => BIT_READ_VALUE,
    POS_READ_RST        => POS_READ_RST,
    POS_READ_RSTB       => POS_READ_RSTB,
    POS_READ_VALUE      => POS_READ_VALUE,
    POS_READ_CHANGES    => POS_READ_CHANGES,

    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i
);

end rtl;

