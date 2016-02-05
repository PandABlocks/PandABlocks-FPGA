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

library unisim;
use unisim.vcomponents.all;

entity panda_slowctrl is
generic (
    AW              : natural := 10;
    DW              : natural := 32
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Transaction interface
    wr_req_i        : in  std_logic;
    rd_req_i        : in  std_logic;
    wr_dat_i        : in  std_logic_vector(31 downto 0);
    rd_dat_o        : out std_logic_vector(31 downto 0);
    addr_i          : in  std_logic_vector(9 downto 0);
    busy_o          : out std_logic;
    -- Serial Physical interface
    spi_csn_o       : out std_logic;
    spi_sclk_o      : out std_logic;
    spi_dat_o       : out std_logic;
    spi_dat_i       : in  std_logic
);
end panda_slowctrl;

architecture rtl of panda_slowctrl is

type sh_states is (idle, address, data_io, data_valid);
signal sh_state                 : sh_states;

signal sclk_prebuf              : std_logic;
signal serial_clk               : std_logic;
signal sclk_ext                 : std_logic;

signal inst_val                 : std_logic;
signal spi_start                : std_logic;

signal rw_reg                   : std_logic;
signal addr_reg                 : std_logic_vector(AW-1 downto 0);
signal data_reg                 : std_logic_vector(DW-1 downto 0);
signal shift_reg                : std_logic_vector(AW+DW downto 0);

signal sh_counter               : natural range 0 to 31;
signal shifting                 : std_logic;
signal read_n_write             : std_logic;
signal ncs_int                  : std_logic;
signal sdi                      : std_logic;

signal read_byte_val            : std_logic;
signal data_read_val            : std_logic;
signal data_read                : std_logic_vector(DW-1 downto 0);

begin

-- Generate serial clock (max 20MHz)
process (clk_i)
    variable clk_div : unsigned(3 downto 0) := (others => '0');
begin
    if (rising_edge(clk_i)) then
        clk_div    := clk_div + 1;
        -- The slave samples the data on the rising edge of SCLK.
        -- therefore we make sure the external clock is slightly
        -- after the internal clock.
        sclk_prebuf <= clk_div(clk_div'length-1);
        sclk_ext    <= sclk_prebuf;
    end if;
end process;

bufg_sclk : BUFG
port map (
    i => sclk_prebuf,
    o => serial_clk
);

-- Shoot commands to the state machine
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        if (reset_i = '1') then
            inst_val <= '0';
            rw_reg   <= '0';
            addr_reg <= (others=> '0');
            data_reg <= (others=> '0');
        else
            -- Write instruction
            if (wr_req_i = '1') then
                inst_val <= '1';
                rw_reg <= '0';
                addr_reg <= addr_i;
                data_reg <= wr_dat_i;
            -- Read instruction
            elsif (rd_req_i = '1') then
                inst_val <= '1';
                rw_reg <= '1';
                addr_reg <= addr_i;
                data_reg <= data_reg;
            -- No instruction
            else
                inst_val <= '0';
                rw_reg <= rw_reg;
                addr_reg <= addr_reg;
                data_reg <= data_reg;
            end if;
        end if;
    end if;
end process;

-- Intruction pulse
pulse2pulse_inst0 : entity work.pulse2pulse
port map (
    rst      => reset_i,
    in_clk   => clk_i,
    out_clk  => serial_clk,
    pulsein  => inst_val,
    pulseout => spi_start,
    inbusy   => open
);

-- Serial interface state-machine
process (reset_i, serial_clk)
begin
    if (reset_i = '1') then
        sh_state     <= idle;
        sh_counter   <= 0;
        shifting     <= '0';
        read_n_write <= '0';
        ncs_int      <= '1';
    elsif (rising_edge(serial_clk)) then
        -- Main state machine
        case sh_state is
            when idle =>
                sh_counter <= shift_reg'length-data_reg'length-1;
                -- Accept every instruction
                if (spi_start = '1') then
                    shifting     <= '1';
                    read_n_write <= rw_reg;
                    ncs_int      <= '0';
                    sh_state     <= address;
                else
                    shifting     <= '0';
                    ncs_int      <= '1';
                end if;

            when address =>
                if (sh_counter = 0) then
                    sh_counter <= data_reg'length-1;
                    sh_state   <= data_io;
                else
                    sh_counter <= sh_counter - 1;
                end if;

            when data_io =>
                if (sh_counter = 0) then
                    sh_counter <= shift_reg'length-data_reg'length-1;
                    shifting   <= '0';
                    ncs_int    <= '1';
                    if (read_n_write = '1') then
                        sh_state <= data_valid;
                    else
                        sh_state <= idle;
                    end if;
                else
                    sh_counter <= sh_counter - 1;
                end if;
            when data_valid =>
                sh_state <= idle;
            when others =>
                sh_state <= idle;
        end case;
    end if;
end process;

-- Instruction & data shift register
process (reset_i, serial_clk)
begin
    if (reset_i = '1') then
        shift_reg      <= (others => '0');
        read_byte_val  <= '0';
        data_read      <= (others => '0');
    elsif (rising_edge(serial_clk)) then
        if (spi_start = '1') then
            shift_reg <= addr_reg & rw_reg & data_reg;
        elsif (shifting = '1') then
            shift_reg <= shift_reg(shift_reg'length - 2 downto 0) & sdi;
        end if;

        -- Data read from device
        if (sh_state = data_valid) then
            read_byte_val <= '1';
            data_read     <= shift_reg(DW-1 downto 0);
        else
            read_byte_val <= '0';
            data_read     <= data_read;
        end if;
    end if;
end process;

-- Transfer data valid pulse to other clock domain
pulse2pulse_inst1 : entity work.pulse2pulse
port map (
    rst      => reset_i,
    in_clk   => serial_clk,
    out_clk  => clk_i,
    pulsein  => read_byte_val,
    pulseout => data_read_val,
    inbusy   => open
);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            rd_dat_o <= (others => '0');
        else
            if (data_read_val = '1') then
                rd_dat_o <= data_read;
            end if;
        end if;
    end if;
end process;


-- Capture data in on rising edge SCLK
-- therefore freeze the signal on the falling edge of serial clock.
process (serial_clk)
begin
    if (falling_edge(serial_clk)) then
        sdi <= spi_dat_i;
    end if;
end process;

-- Serial interface busy
busy_o <= '0' when (sh_state = idle) else '1';

-- Connect entity
spi_csn_o   <= ncs_int;
spi_sclk_o  <= sclk_ext when ncs_int = '0' else '0';
spi_dat_o   <= shift_reg(shift_reg'length - 1);

end rtl;
