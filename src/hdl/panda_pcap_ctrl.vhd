--------------------------------------------------------------------------------
--  File:       panda_pcap_ctrl.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_pcap_ctrl is
port (
    -- Clock and Reset.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface.
    mem_cs_i            : in  std_logic_vector(2**PAGE_NUM-1 downto 0);
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_0_o         : out std_logic_vector(31 downto 0);
    mem_dat_1_o         : out std_logic_vector(31 downto 0);
    -- Block Register Interface.
    ENABLE              : out std_logic_vector(SBUSBW-1 downto 0);
    FRAME               : out std_logic_vector(SBUSBW-1 downto 0);
    CAPTURE             : out std_logic_vector(SBUSBW-1 downto 0);
    ERR_STATUS          : in  std_logic_vector(31 downto 0);

    START_WRITE         : out std_logic;
    WRITE               : out std_logic_vector(31 downto 0);
    WRITE_WSTB          : out std_logic;
    FRAMING_MASK        : out std_logic_vector(31 downto 0);
    FRAMING_ENABLE      : out std_logic;
    FRAMING_MODE        : out std_logic_vector(31 downto 0);
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
end panda_pcap_ctrl;

architecture rtl of panda_pcap_ctrl is

signal mem_addr         : natural range 0 to (2**mem_addr_i'length - 1);

begin

-- Integer conversion for address.
mem_addr <= to_integer(unsigned(mem_addr_i));

--
-- Control System Register Interface
--
REG_PCAP_SPACE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ENABLE  <= TO_SVECTOR(0, SBUSBW);
            FRAME <= TO_SVECTOR(0, SBUSBW);
            CAPTURE <= TO_SVECTOR(0, SBUSBW);
        else
            if (mem_cs_i(PCAP_CS) = '1' and mem_wstb_i = '1') then
                -- Enable bitbus mux select.
                if (mem_addr = PCAP_ENABLE) then
                    ENABLE <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Frame bitbus mux select.
                if (mem_addr = PCAP_FRAME) then
                    FRAME <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Capture bitbus mux select.
                if (mem_addr = PCAP_CAPTURE) then
                    CAPTURE <= mem_dat_i(SBUSBW-1 downto 0);
                end if;
            end if;
        end if;
    end if;
end process;

REG_REG_SPACE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            START_WRITE <= '0';
            WRITE <= (others => '0');
            WRITE_WSTB <= '0';
            FRAMING_MASK <= (others => '0');
            FRAMING_ENABLE <= '0';
            FRAMING_MODE <= (others => '0');
            ARM <= '0';
            DISARM <= '0';
        else
            -- Single clock pulse
            START_WRITE <= '0';
            WRITE_WSTB <= '0';
            ARM <= '0';
            DISARM <= '0';

            if (mem_cs_i(REG_CS) = '1' and mem_wstb_i = '1') then
                -- Memory start reset.
                if (mem_addr = REG_PCAP_START_WRITE) then
                    START_WRITE <= '1';
                end if;

                -- Memory data and strobe.
                if (mem_addr = REG_PCAP_WRITE) then
                    WRITE <= mem_dat_i;
                    WRITE_WSTB <= '1';
                end if;

                -- Framing Mask.
                if (mem_addr = REG_PCAP_FRAMING_MASK) then
                    FRAMING_MASK <= mem_dat_i;
                end if;

                -- Global Framing Enable.
                if (mem_addr = REG_PCAP_FRAMING_ENABLE) then
                    FRAMING_ENABLE <= mem_dat_i(0);
                end if;

                -- Framing Mode
                if (mem_addr = REG_PCAP_FRAMING_MODE) then
                    FRAMING_MODE <= mem_dat_i;
                end if;

                -- DMA block Soft ARM
                if (mem_addr = REG_PCAP_ARM) then
                    ARM <= '1';
                end if;

                -- DMA Soft Disarm
                if (mem_addr = REG_PCAP_DISARM) then
                    DISARM <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

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

            if (mem_cs_i(DRV_CS) = '1' and mem_wstb_i = '1') then
                -- DMA Engine reset.
                if (mem_addr = DRV_PCAP_DMA_RESET) then
                    DMA_RESET <= '1';
                end if;

                -- DMA Engine Enable.
                if (mem_addr = DRV_PCAP_DMA_START) then
                    DMA_START <= '1';
                end if;

                -- DMA block address
                if (mem_addr = DRV_PCAP_DMA_ADDR) then
                    DMA_ADDR <= mem_dat_i;
                    DMA_ADDR_WSTB <= '1';
                end if;

                -- Host DMA Block memory size [in Bytes].
                if (mem_addr = DRV_PCAP_BLOCK_SIZE) then
                    BLOCK_SIZE <= mem_dat_i;
                end if;

                -- IRQ Timeout value
                if (mem_addr = DRV_PCAP_TIMEOUT) then
                    TIMEOUT <= mem_dat_i;
                    TIMEOUT_WSTB <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            mem_dat_0_o <= (others => '0');
            mem_dat_1_o <= (others => '0');
        else
            case (mem_addr) is
                when PCAP_ERR_STATUS =>
                    mem_dat_0_o <= ERR_STATUS;
                when others =>
                    mem_dat_0_o <= (others => '0');
            end case;

            case (mem_addr) is
                when DRV_PCAP_IRQ_STATUS =>
                    mem_dat_1_o <= IRQ_STATUS;
                when others =>
                    mem_dat_1_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;

