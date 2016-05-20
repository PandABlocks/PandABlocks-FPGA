--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Serial Interface core is used to handle communication between
--                Zynq and Slow Control FPGA.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.slow_defines.all;
use work.slow_version.all;

entity zynq_interface is
port (
    -- 50MHz system clock
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder Daughter Card Control and Status Registers
    INENC_PROTOCOL      : out std3_array(3 downto 0);
    OUTENC_PROTOCOL     : out std3_array(3 downto 0);
    OUTENC_CONN_O       : out std_logic_vector(3 downto 0);
    DCARD_MODE          : in  std4_array(3 downto 0);
    TEMP_MON            : in std32_array(4 downto 0);
    VOLT_MON            : in std32_array(7 downto 0);
    -- Front-Panel Control
    ttlin_term_o        : out std_logic_vector(5 downto 0);
    ttl_leds_o          : out std_logic_vector(15 downto 0);
    status_leds_o       : out std_logic_vector(3 downto 0);
    -- Serial Physical interface
    spi_sclk_i          : in  std_logic;
    spi_dat_i           : in  std_logic;
    spi_sclk_o          : out std_logic;
    spi_dat_o           : out std_logic
);
end zynq_interface;

architecture rtl of zynq_interface is

constant AW                 : natural := 10;
constant DW                 : natural := 32;
constant STATUS_NUM         : natural := 32;

signal STATUS_LIST          : std32_array(STATUS_NUM-1 downto 0) := (others => (others => '0'));

signal wr_req               : std_logic;
signal wr_dat               : std_logic_vector(DW-1 downto 0);
signal wr_adr               : std_logic_vector(AW-1 downto 0);
signal rd_adr               : std_logic_vector(AW-1 downto 0);
signal rd_dat               : std_logic_vector(DW-1 downto 0);
signal rd_val               : std_logic;
signal busy                 : std_logic;

signal wr_start             : std_logic;
signal register_index       : natural range 0 to STATUS_NUM-1;

begin

--
-- Serial Interface TX/RX Core IP
--
slow_engine_inst : entity work.slow_engine
generic map (
    AW              => AW,
    DW              => DW,
    SYS_PERIOD      => 10       -- 100MHz
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

    spi_sclk_i      => spi_sclk_i,
    spi_dat_i       => spi_dat_i,
    spi_sclk_o      => spi_sclk_o,
    spi_dat_o       => spi_dat_o
);

--
-- Receive Configuration Registers
--
enc_ctrl_inst : entity work.enc_ctrl
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    rx_addr_i       => rd_adr,
    rx_valid_i      => rd_val,
    rx_data_i       => rd_dat,
    INENC_PROTOCOL  => INENC_PROTOCOL,
    OUTENC_PROTOCOL => OUTENC_PROTOCOL
);

ttl_ctrl_inst : entity work.ttl_ctrl
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    rx_addr_i       => rd_adr,
    rx_valid_i      => rd_val,
    rx_data_i       => rd_dat,
    ttlin_term_o    => ttlin_term_o
);

leds_ctrl_inst : entity work.leds_ctrl
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    rx_addr_i       => rd_adr,
    rx_valid_i      => rd_val,
    rx_data_i       => rd_dat,
    ttl_leds_o      => ttl_leds_o,
    status_leds_o   => status_leds_o,
    outenc_conn_o   => OUTENC_CONN_O
);

--
-- Transmit Interface :
-- Continuously cycles and transmits the status registers, and transfer them
-- to the master at 1ms intervals.
--
send_trigger : entity work.prescaler
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    PERIOD          => TO_SVECTOR(5000, 32),
    pulse_o         => wr_start
);

-- Assemble Status Register List
STATUS_LIST(SLOW_VERSION) <= SlowFPGAVersion;
STATUS_LIST(DCARD1_MODE) <= ZEROS(28) & DCARD_MODE(0);
STATUS_LIST(DCARD2_MODE) <= ZEROS(28) & DCARD_MODE(1);
STATUS_LIST(DCARD3_MODE) <= ZEROS(28) & DCARD_MODE(2);
STATUS_LIST(DCARD4_MODE) <= ZEROS(28) & DCARD_MODE(3);
STATUS_LIST(TEMP_PSU)    <= TEMP_MON(0);
STATUS_LIST(TEMP_SFP)    <= TEMP_MON(1);
STATUS_LIST(TEMP_ENC_L)  <= TEMP_MON(2);
STATUS_LIST(TEMP_PICO)   <= TEMP_MON(3);
STATUS_LIST(TEMP_ENC_R)  <= TEMP_MON(4);
STATUS_LIST(ALIM_12V0)   <= VOLT_MON(0);
STATUS_LIST(PICO_5V0)    <= VOLT_MON(1);
STATUS_LIST(IO_5V0)      <= VOLT_MON(2);
STATUS_LIST(SFP_3V3)     <= VOLT_MON(3);
STATUS_LIST(FMC_15VN)    <= VOLT_MON(4);
STATUS_LIST(FMC_15VP)    <= VOLT_MON(5);
STATUS_LIST(ENC_24V)     <= VOLT_MON(6);
STATUS_LIST(FMC_12V)     <= VOLT_MON(7);

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            register_index <= 0;
            wr_req <= '0';
            wr_adr <= (others => '0');
            wr_dat <= (others => '0');
        else
            -- Cycle through registers contiuously.
            if (busy = '0' and wr_start = '1') then
                wr_req <= '1';
                wr_adr <= TO_SVECTOR(register_index, AW);
                wr_dat <= STATUS_LIST(register_index);
                -- Keep track of registers
                if (register_index = STATUS_NUM - 1) then
                    register_index <= 0;
                else
                    register_index <= register_index + 1;
                end if;
            else
                wr_req <= '0';
                wr_adr <= wr_adr;
                wr_dat <= wr_dat;
            end if;
        end if;
    end if;
end process;

end rtl;
