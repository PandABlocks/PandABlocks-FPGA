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
use work.reg_defines.all; -- This includes the reg and DRV declarations as they
use work.version.all; -- are not treated as blocks and cannot be autogend

entity reg_top is
generic (
    NUM_MGT            : natural := 0
);
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
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    dma_irq_events_i    : in  std_logic_vector(31 downto 0);
    SLOW_FPGA_VERSION   : in  std_logic_vector(31 downto 0);
    TS_SEC              : in  std_logic_vector(31 downto 0);
    TS_TICKS            : in  std_logic_vector(31 downto 0);
    -- Output signals
    MGT_MAC_ADDR        : out std32_array(2*NUM_MGT -1 downto 0) := (others => (others => '1'));
    MGT_MAC_ADDR_WSTB   : out std_logic_vector(2*NUM_MGT downto 0) := (others => '0')
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
signal FPGA_CAPABILITIES    : std_logic_vector(31 downto 0);

signal read_address         : natural range 0 to (2**read_address_i'length - 1);
signal write_address        : natural range 0 to (2**write_address_i'length - 1);
signal read_ack             : std_logic;
signal table_dma_irq        : std_logic_vector(31 downto 0) := (others => '0');

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
    DELAY_i     => RD_ADDR2ACK
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
        if (NUM_MGT > 0 ) then
            MGT_MAC_ADDR_WSTB(0) <= '0';
            MGT_MAC_ADDR_WSTB(1) <= '0';
        end if;
        if (NUM_MGT > 1) then
            MGT_MAC_ADDR_WSTB(2) <= '0';
            MGT_MAC_ADDR_WSTB(3) <= '0';
        end if;
        if (NUM_MGT > 2 ) then
            MGT_MAC_ADDR_WSTB(4) <= '0';
            MGT_MAC_ADDR_WSTB(5) <= '0';
        end if;
        if (NUM_MGT > 3 ) then
            MGT_MAC_ADDR_WSTB(6) <= '0';
            MGT_MAC_ADDR_WSTB(7) <= '0';
        end if;
        if (write_strobe_i = '1') then
            -- System Bus Read Start
            if (write_address = REG_BIT_READ_RST) then
                BIT_READ_RST <= '1';
            end if;
            -- Position Bus Read Start
            if (write_address = REG_POS_READ_RST) then
                POS_READ_RST <= '1';
            end if;
            -- Write MGT MAC addresses
            if (NUM_MGT > 0) then
                if (write_address = REG_MAC_ADDRESS_BASE_0) then
                    MGT_MAC_ADDR(0) <= write_data_i;
                    MGT_MAC_ADDR_WSTB(0) <= '1';
                end if;
                if (write_address = REG_MAC_ADDRESS_BASE_1) then
                    MGT_MAC_ADDR(1) <= write_data_i;
                    MGT_MAC_ADDR_WSTB(1) <= '1';
                end if;
            end if;
            if (NUM_MGT > 1) then
                if (write_address = REG_MAC_ADDRESS_BASE_2) then
                    MGT_MAC_ADDR(2) <= write_data_i;
                    MGT_MAC_ADDR_WSTB(2) <= '1';
                end if;
                if (write_address = REG_MAC_ADDRESS_BASE_3) then
                    MGT_MAC_ADDR(3) <= write_data_i;
                    MGT_MAC_ADDR_WSTB(3) <= '1';
                end if;
            end if;
            if (NUM_MGT > 2) then
                if (write_address = REG_MAC_ADDRESS_BASE_4) then
                    MGT_MAC_ADDR(4) <= write_data_i;
                    MGT_MAC_ADDR_WSTB(4) <= '1';
                end if;
                if (write_address = REG_MAC_ADDRESS_BASE_5) then
                    MGT_MAC_ADDR(5) <= write_data_i;
                    MGT_MAC_ADDR_WSTB(5) <= '1';
                end if;
            end if;
            if (NUM_MGT > 3) then
                if (write_address = REG_MAC_ADDRESS_BASE_6) then
                    MGT_MAC_ADDR(6) <= write_data_i;
                    MGT_MAC_ADDR_WSTB(6) <= '1';
                end if;
                if (write_address = REG_MAC_ADDRESS_BASE_7) then
                    MGT_MAC_ADDR(7) <= write_data_i;
                    MGT_MAC_ADDR_WSTB(7) <= '1';
                end if;
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

-- Register of FPGA capabilities 
-- Bit0: presence of PCAP_STD_DEV functionality
FPGA_CAPABILITIES <= (0 => PCAP_STD_DEV_OPTION,
                      1 => FINE_DELAY_OPTION,
                      others => '0');
--------------------------------------------------------------------------
-- Status Register Read
--------------------------------------------------------------------------
REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        table_dma_irq <= table_dma_irq or dma_irq_events_i;
        if read_strobe_i = '1' then
            case (read_address) is
                when REG_FPGA_VERSION =>
                    read_data_o <= FPGA_VERSION;
                when REG_FPGA_BUILD =>
                    read_data_o <= FPGA_BUILD;
                when REG_USER_VERSION =>
                    read_data_o <= SLOW_FPGA_VERSION;
                when REG_BIT_READ_VALUE =>
                    read_data_o <= BIT_READ_VALUE;
                when REG_POS_READ_VALUE =>
                    read_data_o <= POS_READ_VALUE;
                when REG_POS_READ_CHANGES =>
                    read_data_o <= POS_READ_CHANGES;
                when REG_FPGA_CAPABILITIES =>
                    read_data_o <= FPGA_CAPABILITIES;
                when REG_PCAP_TS_SEC =>
                    read_data_o <= TS_SEC;
                when REG_PCAP_TS_TICKS =>
                    read_data_o <= TS_TICKS;
                when REG_TABLE_IRQ_STATUS =>
                    read_data_o <= table_dma_irq;
                    table_dma_irq <= dma_irq_events_i;
                when others =>
                    read_data_o <= (others => '0');
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

    BIT_READ_RST        => BIT_READ_RST,
    BIT_READ_RSTB       => BIT_READ_RSTB,
    BIT_READ_VALUE      => BIT_READ_VALUE,
    POS_READ_RST        => POS_READ_RST,
    POS_READ_RSTB       => POS_READ_RSTB,
    POS_READ_VALUE      => POS_READ_VALUE,
    POS_READ_CHANGES    => POS_READ_CHANGES,

    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i
);

end rtl;

