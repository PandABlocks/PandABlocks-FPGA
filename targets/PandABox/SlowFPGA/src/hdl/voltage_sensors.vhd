--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Read I2C temperature sensors in loop.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.slow_defines.all;
use work.support.all;

entity voltage_sensors is
port (
    -- 50MHz system clock
    clk_i               : in    std_logic;
    reset_i             : in    std_logic;
    -- I2C Interface
    sda                 : inout std_logic;
    scl                 : inout std_logic;
    -- Status registers
    VOLT_MON            : out std32_array(7 downto 0)
);
end voltage_sensors;

architecture rtl of voltage_sensors is

type i2c_fsm_t is (INIT, SET_ENABLE, SET_CONTROL, READ_DATA, NEXT_CHANNEL);

-- Array of Slave addresses
constant SLAVE_ADDR     : std_logic_vector(6 downto 0) := "1001100";
-- Enable register addr
constant ENABLE_ADDR    : unsigned(7 downto 0) := X"01";
-- Control register addr
constant CONTROL_ADDR   : unsigned(7 downto 0) := X"08";
-- V_N registers start address
constant READ_ADDR     : unsigned(7 downto 0) := X"0A";

signal i2c_fsm          : i2c_fsm_t;
signal busy_prev        : std_logic;
signal i2c_ena          : std_logic;
signal i2c_addr         : std_logic_vector(6 downto 0);
signal i2c_rw           : std_logic;
signal i2c_data_wr      : unsigned(7 downto 0);
signal i2c_busy         : std_logic;
signal i2c_data_rd      : std_logic_vector(7 downto 0);
signal i2c_ack_error    : std_logic;
signal i2c_rise         : std_logic;
signal data_rd          : std_logic_vector(15 downto 0);
signal i2c_start        : std_logic;
signal sda_din          : std_logic;
signal scl_din          : std_logic;
signal sda_t            : std_logic;
signal scl_t            : std_logic;
signal channel_index    : natural range 0 to 7;

begin

--------------------------------------------------------------------
-- 3-state I2C I/O Buffers
--------------------------------------------------------------------
iobuf_scl : iobuf
port map (
    I  => '0',
    O  => scl_din,
    IO => scl,
    T  => scl_t
);

iobuf_sda : iobuf
port map (
    I  => '0',
    O  => sda_din,
    IO => sda,
    T  => sda_t
);

-- Generate Internal  from system clock
start_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => TO_SVECTOR(50_000_000,32), -- 1sec
    pulse_o     => i2c_start
);

i2c_master_inst : entity work.i2c_master
generic map (
    input_clk   => 50_000_000,
    bus_clk     => 10_000
)
port map (
    clk         => clk_i,
    reset       => reset_i,
    ena         => i2c_ena,
    addr        => i2c_addr,
    rw          => i2c_rw,
    data_wr     => std_logic_vector(i2c_data_wr),
    busy        => i2c_busy,
    data_rd     => i2c_data_rd,
    ack_error_o   => i2c_ack_error,
    sda         => sda_din,
    scl         => scl_din,
    sda_t       => sda_t,
    scl_t       => scl_t
);

--------------------------------------------------------------------
-- Main read state machine loops through all SLAVES
--------------------------------------------------------------------
i2c_rise <= i2c_busy and not busy_prev;

process(clk_i)
    variable busy_cnt         : natural range 0 to 3;
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            i2c_fsm <= INIT;
            channel_index <= 0;
            busy_cnt := 0;
            busy_prev <= '1';
            i2c_rw <= '1';
            i2c_ena <= '0';
            i2c_addr <= (others => '0');
            i2c_data_wr <= X"00";
            data_rd <= (others => '0');
            VOLT_MON <= (others => (others => '0'));
        else
            busy_prev <= i2c_busy;

            case (i2c_fsm) is
                -- Wait for 1 sec to start
                when INIT =>
                    if (i2c_busy = '0' and i2c_start = '1') then
                        i2c_fsm <= SET_ENABLE;
                    end if;

                -- Enable all channels
                when SET_ENABLE =>
                    if (i2c_rise = '1') then
                        busy_cnt := busy_cnt + 1;
                    end if;

                    case busy_cnt is
                        -- Write command to send the register address
                        when 0 =>
                            i2c_ena <= '1';
                            i2c_addr <= SLAVE_ADDR;
                            i2c_rw <= '0';          -- write
                            i2c_data_wr <= ENABLE_ADDR;

                        -- Read command to read 2 consecutive bytes
                        when 1 =>
                            i2c_data_wr <= X"FF";   -- Enable all data
                        when 2 =>
                            i2c_ena <= '0';
                            if (i2c_busy = '0' and i2c_start = '1') then
                                busy_cnt := 0;
                                i2c_fsm <= SET_CONTROL;
                            end if;

                        when others => NULL;
                    end case;

                -- Set repeated conversion
                when SET_CONTROL =>
                    if (i2c_rise = '1') then
                        busy_cnt := busy_cnt + 1;
                    end if;

                    case busy_cnt is
                        -- Write command to send the register address
                        when 0 =>
                            i2c_ena <= '1';
                            i2c_addr <= SLAVE_ADDR;
                            i2c_rw <= '0';          -- write
                            i2c_data_wr <= CONTROL_ADDR;

                        -- Read command to read 2 consecutive bytes
                        when 1 =>
                            i2c_data_wr <= X"10";   -- Repeated capture
                        when 2 =>
                            i2c_ena <= '0';
                            if (i2c_busy = '0' and i2c_start = '1') then
                                busy_cnt := 0;
                                -- Latch register start address
                                i2c_data_wr <= READ_ADDR;
                                -- Move to read data loop
                                i2c_fsm <= READ_DATA;
                            end if;

                        when others => NULL;
                    end case;

                -- Pointer register defaults to temperature reg. So,
                -- directly Read i2 bytes from the current slave
                when READ_DATA =>
                    if (i2c_rise = '1') then
                        busy_cnt := busy_cnt + 1;
                    end if;

                    case busy_cnt is
                        -- Write command to send the register address
                        when 0 =>
                            i2c_ena <= '1';
                            i2c_addr <= SLAVE_ADDR;
                            i2c_rw <= '0';          -- write

                        -- Read command to read 2 consecutive bytes
                        when 1 =>
                            i2c_rw <= '1';          -- read

                        when 2 =>
                            if (i2c_busy = '0') then
                                data_rd(15 downto 8) <= i2c_data_rd;
                            end if;

                        when 3 =>
                            i2c_ena <= '0';
                            if (i2c_busy = '0') then
                                data_rd(7 downto 0) <= i2c_data_rd;
                                busy_cnt := 0;
                                i2c_fsm <= NEXT_CHANNEL;
                            end if;

                        when others => NULL;
                    end case;

                -- Latch read data and move to next slave
                when NEXT_CHANNEL =>
                    if (i2c_start = '1') then
                        -- Wrap up register address after the last
                        -- channel.
                        if (channel_index = 7) then
                            i2c_data_wr <= READ_ADDR;
                            channel_index <= 0;
                        else
                            i2c_data_wr <= i2c_data_wr + 2;
                            channel_index <= channel_index+ 1;
                        end if;

                        i2c_fsm <= READ_DATA;
                    end if;

                    -- Bits[14:0] is used for Volt
                    VOLT_MON(channel_index) <=
                   std_logic_vector(resize(signed(data_rd(14 downto 0)), 32));

                when others => NULL;

            end case;
        end if;
    end if;
end process;

end rtl;
