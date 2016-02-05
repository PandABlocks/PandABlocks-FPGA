--------------------------------------------------------------------------------
--  File:       panda_slowctrl_block.vhd
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

entity panda_slowctrl_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Block Input and Outputs
    inenc_tlp_i         : in  slow_packet;
    outenc_tlp_i        : in  slow_packet;
    busy_o              : out std_logic;
    -- Serial Physical interface
    spi_sclk_i          : in  std_logic;
    spi_dat_i           : in  std_logic;
    spi_sclk_o          : out std_logic;
    spi_dat_o           : out std_logic
);
end panda_slowctrl_block;

architecture rtl of panda_slowctrl_block is

signal FPGA_VERSION     : std_logic_vector(31 downto 0);
signal ENC_CONN         : std_logic_vector(31 downto 0);

signal wr_req           : std_logic;
signal wr_dat           : std_logic_vector(31 downto 0);
signal wr_adr           : std_logic_vector(PAGE_AW-1 downto 0);
signal rd_adr           : std_logic_vector(PAGE_AW-1 downto 0);
signal rd_dat           : std_logic_vector(31 downto 0);
signal rd_val           : std_logic;

signal mem_addr         : natural range 0 to (2**mem_addr_i'length - 1);
signal rdadr_reg        : natural range 0 to (2**mem_addr_i'length - 1);

begin

rdadr_reg <= to_integer(unsigned(rd_adr));

-- Integer conversion for address.
mem_addr <= to_integer(unsigned(mem_addr_i));

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            wr_req <= '0';
            wr_adr <= (others => '0');
            wr_dat <= (others => '0');
        else
            wr_req <= '0';

            if (inenc_tlp_i.strobe = '1') then
                wr_req <= '1';
                wr_adr <= inenc_tlp_i.address;
                wr_dat <= inenc_tlp_i.data;
            elsif (outenc_tlp_i.strobe = '1') then
                wr_req <= '1';
                wr_adr <= outenc_tlp_i.address;
                wr_dat <= outenc_tlp_i.data;
            elsif (mem_cs_i = '1' and mem_wstb_i = '1') then
                wr_req <= '0';
                wr_adr <= std_logic_vector(to_unsigned(mem_addr, PAGE_AW));
                wr_dat <= mem_dat_i;
            end if;
        end if;
    end if;
end process;

--
-- Status Register Read
--
REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            mem_dat_o <= (others => '0');
        else
            case (mem_addr) is
                when SLOW_FPGA_VERSION =>
                    mem_dat_o <= FPGA_VERSION;
                when SLOW_ENC_CONN =>
                    mem_dat_o <= ENC_CONN;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

--
-- Serial interface core
--
slowctrl_inst : entity work.panda_slowctrl
generic map (
    AW              => PAGE_AW
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,

    wr_rst_i        => '0',
    wr_req_i        => wr_req,
    wr_dat_i        => wr_dat,
    wr_adr_i        => wr_adr,
    rd_adr_o        => rd_adr,
    rd_dat_o        => rd_dat,
    rd_val_o        => rd_val,
    busy_o          => busy_o,

    spi_sclk_o      => spi_sclk_o,
    spi_dat_o       => spi_dat_o,
    spi_sclk_i      => spi_sclk_i,
    spi_dat_i       => spi_dat_i
);

--
--
--
SLOW_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            FPGA_VERSION <= (others => '0');
            ENC_CONN <= (others => '0');
        else
            if (rd_val = '1' and rdadr_reg = SLOW_FPGA_VERSION) then
                FPGA_VERSION <= rd_dat;
            end if;

            if (rd_val = '1' and rdadr_reg = SLOW_ENC_CONN) then
                ENC_CONN <= rd_dat;
            end if;
        end if;
    end if;
end process;


end rtl;

