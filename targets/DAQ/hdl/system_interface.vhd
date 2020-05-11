--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Zynq-to-Spartan6 Slow Control Interface core handles write
--                TLPs to Slow FPGA, and accepts status data from Slow FPGA.
--                Interface is provided with dedicated SPI-like serial links.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.slow_defines_daq.all;

entity system_interface is
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
    cmd_ready_n_o       : out std_logic;
    SLOW_FPGA_VERSION   : out std_logic_vector(31 downto 0);
    TEMP_MON            : out std32_array(2 downto 0);
    VOLT_MON            : out std32_array(7 downto 0)
);
end system_interface;

architecture rtl of system_interface is

component system_cmd_fifo
port (
    clk                 : in std_logic;
    rst                 : in std_logic;
    din                 : in std_logic_vector(41 DOWNTO 0);
    wr_en               : in std_logic;
    rd_en               : in std_logic;
    dout                : out std_logic_vector(41 DOWNTO 0);
    full                : out std_logic;
    empty               : out std_logic
);
end component;

signal wr_req           : std_logic;
signal wr_dat           : std_logic_vector(31 downto 0);
signal wr_adr           : std_logic_vector(PAGE_AW-1 downto 0);
signal rd_adr           : std_logic_vector(PAGE_AW-1 downto 0);
signal rd_dat           : std_logic_vector(31 downto 0);
signal rd_val           : std_logic;
signal busy             : std_logic;
signal read_addr        : natural range 0 to (2**rd_adr'length - 1);
signal cmd_din          : std_logic_vector(41 downto 0);
signal cmd_dout         : std_logic_vector(41 downto 0);
signal cmd_empty        : std_logic;
signal cmd_full         : std_logic;
signal cmd_rd_en        : std_logic;

begin

cmd_ready_n_o <= cmd_full;

---------------------------------------------------------------------------
-- Serial Interface core instantiation
---------------------------------------------------------------------------
serial_engine_inst : entity work.serial_engine
generic map (
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
    busy_o          => busy,

    spi_sclk_o      => spi_sclk_o,
    spi_dat_o       => spi_dat_o,
    spi_sclk_i      => spi_sclk_i,
    spi_dat_i       => spi_dat_i
);

---------------------------------------------------------------------------
-- There are multiple transmit sources coming across the design blocks.
-- Incoming commands to SlowFPGA from Arm are buffered and then priority
-- IF-ELSE is used for sending write commands
---------------------------------------------------------------------------

cmd_din <= registers_tlp_i.address & registers_tlp_i.data;

system_cmd_fifo_inst : system_cmd_fifo
port map (
    clk             => clk_i,
    rst             => reset_i,
    din             => cmd_din,
    wr_en           => registers_tlp_i.strobe,
    rd_en           => cmd_rd_en,
    dout            => cmd_dout,
    full            => cmd_full,
    empty           => cmd_empty
);

SENDER : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            wr_req <= '0';
            wr_adr <= (others => '0');
            wr_dat <= (others => '0');
            cmd_rd_en <= '0';
        else
            wr_req <= '0';
            cmd_rd_en <= '0';

            -- Zynq->SlowFPGA command has priority
            if (cmd_empty = '0' and busy = '0' and wr_req = '0') then
                wr_req <= '1';
                wr_adr <= cmd_dout(41 downto 32);
                wr_dat <= cmd_dout(31 downto 0);
                cmd_rd_en <= '1';
            -- Ignore led updates when busy
            elsif (leds_tlp_i.strobe = '1' and busy = '0' and wr_req = '0') then
                wr_req <= '1';
                wr_adr <= leds_tlp_i.address;
                wr_dat <= leds_tlp_i.data;
            end if;
        end if;
    end if;
end process;

---------------------------------------------------------------------------
-- Receive and store incoming status updates from Slow FPGA.
---------------------------------------------------------------------------
read_addr <= to_integer(unsigned(rd_adr));

RECEIVER : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            SLOW_FPGA_VERSION <= (others => '0');
            TEMP_MON <= (others => (others => '0'));
            VOLT_MON <= (others => (others => '0'));
        else
            if (rd_val = '1') then
                case read_addr is
                    when SLOW_VERSION =>
                        SLOW_FPGA_VERSION <= rd_dat;
                    -- Temperature monitor
                    when TEMP_PSU =>
                        TEMP_MON(0) <= rd_dat;
                    when TEMP_SFP =>
                        TEMP_MON(1) <= rd_dat;
                    when TEMP_PICO =>
                        TEMP_MON(2) <= rd_dat;
                    -- Voltage monitor
                    when ALIM_12V0  =>
                        VOLT_MON(0) <= rd_dat;
                    when PICO_5V0  =>
                        VOLT_MON(1) <= rd_dat;
                    when IO_5V0    =>
                        VOLT_MON(2) <= rd_dat;
                    when SFP_3V3   =>
                        VOLT_MON(3) <= rd_dat;
                    when FMC_15VN  =>
                        VOLT_MON(4) <= rd_dat;
                    when FMC_15VP  =>
                        VOLT_MON(5) <= rd_dat;
                    when ENC_24V   =>
                        VOLT_MON(6) <= rd_dat;
                    when FMC_12V   =>
                        VOLT_MON(7) <= rd_dat;
                    when others =>
                end case;
            end if;
        end if;
    end if;
end process;

end rtl;

