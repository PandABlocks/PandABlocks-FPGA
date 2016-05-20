--------------------------------------------------------------------------------
--  File:       slow_interface.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.slow_defines.all;

entity slow_interface is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Serial Physical interface
    spi_sclk_i          : in  std_logic;
    spi_dat_i           : in  std_logic;
    spi_sclk_o          : out std_logic;
    spi_dat_o           : out std_logic;
    -- Block Input and Outputs
    registers_tlp_i     : in  slow_packet;
    leds_tlp_i          : in  slow_packet;
    busy_o              : out std_logic;
    SLOW_FPGA_VERSION   : out std_logic_vector(31 downto 0);
    DCARD_MODE          : out std32_array(ENC_NUM-1 downto 0);
    TEMP_MON            : out std32_array(4 downto 0);
    VOLT_MON            : out std32_array(7 downto 0)
);
end slow_interface;

architecture rtl of slow_interface is

signal wr_req           : std_logic;
signal wr_dat           : std_logic_vector(31 downto 0);
signal wr_adr           : std_logic_vector(PAGE_AW-1 downto 0);
signal rd_adr           : std_logic_vector(PAGE_AW-1 downto 0);
signal rd_dat           : std_logic_vector(31 downto 0);
signal rd_val           : std_logic;

signal read_addr        : natural range 0 to (2**rd_adr'length - 1);

begin

--
-- Serial Interface core instantiation
--
slow_engine_inst : entity work.slow_engine
generic map (
    AW              => PAGE_AW,
    DW              => 32,
    SYS_PERIOD      => 8        -- 125MHz
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
-- There are multiple transmit sources coming across the design blocks.
-- Use priority IF-ELSE for accepting write command.
--
SENDER : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            wr_req <= '0';
            wr_adr <= (others => '0');
            wr_dat <= (others => '0');
        else
            wr_req <= '0';

            -- There are two sources wanting to send TLPs to Slow FPGA.
            if (registers_tlp_i.strobe = '1') then
                wr_req <= '1';
                wr_adr <= registers_tlp_i.address;
                wr_dat <= registers_tlp_i.data;
            elsif (leds_tlp_i.strobe = '1') then
                wr_req <= '1';
                wr_adr <= leds_tlp_i.address;
                wr_dat <= leds_tlp_i.data;
            end if;
        end if;
    end if;
end process;

--
-- Receive and store incoming status updates from Slow FPGA.
--
read_addr <= to_integer(unsigned(rd_adr));

RECEIVER : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            SLOW_FPGA_VERSION <= (others => '0');
            DCARD_MODE <= (others => (others => '0'));
            TEMP_MON <= (others => (others => '0'));
            VOLT_MON <= (others => (others => '0'));
        else
            if (rd_val = '1') then
                case read_addr is
                    when SLOW_VERSION =>
                        SLOW_FPGA_VERSION <= rd_dat;
                    when DCARD1_MODE =>
                        DCARD_MODE(0) <= rd_dat;
                    when DCARD2_MODE =>
                        DCARD_MODE(1) <= rd_dat;
                    when DCARD3_MODE =>
                        DCARD_MODE(2) <= rd_dat;
                    when DCARD4_MODE =>
                        DCARD_MODE(3) <= rd_dat;
                    when TEMP_PSU =>
                        TEMP_MON(0) <= rd_dat;
                    when TEMP_SFP =>
                        TEMP_MON(1) <= rd_dat;
                    when TEMP_ENC_L =>
                        TEMP_MON(2) <= rd_dat;
                    when TEMP_PICO =>
                        TEMP_MON(3) <= rd_dat;
                    when TEMP_ENC_R =>
                        TEMP_MON(4) <= rd_dat;
                    when FMC_12V   =>
                        VOLT_MON(0) <= rd_dat;
                    when ENC_24V   =>
                        VOLT_MON(1) <= rd_dat;
                    when FMC_15VP  =>
                        VOLT_MON(2) <= rd_dat;
                    when FMC_15VN  =>
                        VOLT_MON(3) <= rd_dat;
                    when SFP_3V3   =>
                        VOLT_MON(4) <= rd_dat;
                    when IO_5V0    =>
                        VOLT_MON(5) <= rd_dat;
                    when PICO_5V0  =>
                        VOLT_MON(6) <= rd_dat;
                    when ALIM_12V0  =>
                        VOLT_MON(7) <= rd_dat;
                    when others =>
                end case;
            end if;
        end if;
    end if;
end process;

end rtl;

