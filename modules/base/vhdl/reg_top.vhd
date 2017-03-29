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
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Readback signals
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
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

signal read_address         : natural range 0 to (2**read_address_i'length - 1);
signal write_address        : natural range 0 to (2**write_address_i'length - 1);
signal read_ack             : std_logic;

begin
-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';
read_ack_o <= read_ack;

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack,
    DELAY       => RD_ADDR2ACK
);

-- Integer conversion for address.
read_address <= to_integer(unsigned(read_address_i));
write_address <= to_integer(unsigned(write_address_i));

--------------------------------------------------------------------------
-- Control System Register Write Interface
--------------------------------------------------------------------------
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        BIT_READ_RST <= '0';
        POS_READ_RST <= '0';

        if (write_strobe_i = '1') then
            -- System Bus Read Start
            if (write_address = REG_BIT_READ_RST) then
                BIT_READ_RST <= '1';
            end if;

            -- Position Bus Read Start
            if (write_address = REG_POS_READ_RST) then
                POS_READ_RST <= '1';
            end if;
        end if;
    end if;
end process;

-- System Bus and Position bus fields are read sequentially, and read strobe
-- is used to increment the field index
BIT_READ_RSTB <= '1' when (read_ack = '1' and
                 read_address = REG_BIT_READ_VALUE) else '0';

POS_READ_RSTB <= '1' when (read_ack = '1' and
                 read_address = REG_POS_READ_VALUE) else '0';

--------------------------------------------------------------------------
-- Status Register Read
--------------------------------------------------------------------------
REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        case (read_address) is
            when REG_FPGA_VERSION =>
                read_data_o <= FPGA_VERSION;
            when REG_FPGA_BUILD =>
                read_data_o <= FPGA_VERSION;
            when REG_USER_VERSION =>
                read_data_o <= SLOW_FPGA_VERSION;
            when REG_BIT_READ_VALUE =>
                read_data_o <= BIT_READ_VALUE;
            when REG_POS_READ_VALUE =>
                read_data_o <= POS_READ_VALUE;
            when REG_POS_READ_CHANGES =>
                read_data_o <= POS_READ_CHANGES;
            when others =>
                read_data_o <= (others => '0');
        end case;
    end if;
end process;

--------------------------------------------------------------------------
-- Instantiate Special REG* block
--------------------------------------------------------------------------
reg_inst : entity work.reg
port map (
    clk_i               => clk_i,

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

