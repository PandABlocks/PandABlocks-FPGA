--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Position Capture requires an additional register interface
--                to handle ARMing and DMA related control registers.
--------------------------------------------------------------------------------

-- *REGs and *DMA space needs custom control block

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.addr_defines.all;
use work.top_defines.all;
use work.reg_defines.all;
use work.panda_constants.all;

entity pcap_core_ctrl is
port (
    -- Clock and Reset.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface.
    read_strobe_i       : in  std_logic_vector(MOD_COUNT-1 downto 0);
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic_vector(MOD_COUNT-1 downto 0);
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Block Register Interface.
    START_WRITE         : out std_logic;
    WRITE               : out std_logic_vector(31 downto 0);
    WRITE_WSTB          : out std_logic;
    ARM                 : out std_logic;
    DISARM              : out std_logic;

    DMA_RESET           : out std_logic;
    DMA_START           : out std_logic;
    DMA_ADDR            : out std_logic_vector(31 downto 0);
    DMA_ADDR_WSTB       : out std_logic;
    BLOCK_SIZE          : out std_logic_vector(31 downto 0);
    TIMEOUT             : out std_logic_vector(31 downto 0);
    TIMEOUT_WSTB        : out std_logic;
    IRQ_STATUS          : in  std_logic_vector(31 downto 0)
);
end pcap_core_ctrl;

architecture rtl of pcap_core_ctrl is

signal write_address    : natural range 0 to (2**write_address_i'length - 1);
signal read_address     : natural range 0 to (2**read_address_i'length - 1);

begin

-- Integer conversion for address.
read_address <= to_integer(unsigned(read_address_i));
write_address <= to_integer(unsigned(write_address_i));

--------------------------------------------------------------------------
-- REG* Address Space interface
--------------------------------------------------------------------------
REG_REG_SPACE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            START_WRITE <= '0';
            WRITE <= (others => '0');
            WRITE_WSTB <= '0';
            ARM <= '0';
            DISARM <= '0';
        else
            -- Single clock pulse
            START_WRITE <= '0';
            WRITE_WSTB <= '0';
            ARM <= '0';
            DISARM <= '0';

            if (write_strobe_i(REG_CS) = '1') then
                -- Memory start reset.
                if (write_address = REG_PCAP_START_WRITE) then
                    START_WRITE <= '1';
                end if;

                -- Memory data and strobe.
                if (write_address = REG_PCAP_WRITE) then
                    WRITE <= write_data_i;
                    WRITE_WSTB <= '1';
                end if;

                -- DMA block Soft ARM
                if (write_address = REG_PCAP_ARM) then
                    ARM <= '1';
                end if;

                -- DMA Soft Disarm
                if (write_address = REG_PCAP_DISARM) then
                    DISARM <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- DRIVER Address Space interface
--------------------------------------------------------------------------
REG_DRV_SPACE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            DMA_RESET <= '0';
            DMA_START <= '0';
            DMA_ADDR <= (others => '0');
            DMA_ADDR_WSTB <= '0';
            BLOCK_SIZE <= TO_SVECTOR(0, 32);
            TIMEOUT <= TO_SVECTOR(0, 32);
            TIMEOUT_WSTB <= '0';
        else
            -- Single clock pulse
            DMA_RESET <= '0';
            DMA_START <= '0';
            DMA_ADDR_WSTB <= '0';
            TIMEOUT_WSTB <= '0';

            if (write_strobe_i(DRV_CS) = '1') then
                -- DMA Engine reset.
                if (write_address = DRV_PCAP_DMA_RESET) then
                    DMA_RESET <= '1';
                end if;

                -- DMA Engine Enable.
                if (write_address = DRV_PCAP_DMA_START) then
                    DMA_START <= '1';
                end if;

                -- DMA block address
                if (write_address = DRV_PCAP_DMA_ADDR) then
                    DMA_ADDR <= write_data_i;
                    DMA_ADDR_WSTB <= '1';
                end if;

                -- Host DMA Block memory size [in Bytes].
                if (write_address = DRV_PCAP_BLOCK_SIZE) then
                    BLOCK_SIZE <= write_data_i;
                end if;

                -- IRQ Timeout value
                if (write_address = DRV_PCAP_TIMEOUT) then
                    TIMEOUT <= write_data_i;
                    TIMEOUT_WSTB <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- DRIVER space register readback
--------------------------------------------------------------------------
REG_READ_DRV : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            read_data_o <= (others => '0');
        else
            case (read_address) is
                when DRV_PCAP_IRQ_STATUS =>
                    read_data_o <= IRQ_STATUS;
                when DRV_COMPAT_VERSION =>
                    read_data_o <= DRIVER_COMPAT_VERSION;
                when others =>
                    read_data_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;

