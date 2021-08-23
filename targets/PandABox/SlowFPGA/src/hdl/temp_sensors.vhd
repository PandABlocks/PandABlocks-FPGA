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

entity temp_sensors is
port (
    -- 50MHz system clock
    clk_i               : in    std_logic;
    reset_i             : in    std_logic;
    -- I2C Interface
    sda                 : inout std_logic;
    scl                 : inout std_logic;
    -- Status registers
    TEMP_MON            : out std32_array(4 downto 0)
);
end temp_sensors;

architecture rtl of temp_sensors is

type i2c_fsm_t is (INIT, READ_DATA, NEXT_SLAVE);

-- Array of Slave addresses
constant SLAVE_ARRAY    : std8_array(4 downto 0) := (
                            "01001100",
                            "01001011",
                            "01001010",
                            "01001001",
                            "01001000");

signal i2c_fsm          : i2c_fsm_t;
signal busy_prev        : std_logic;
signal i2c_ena          : std_logic;
signal i2c_addr         : std_logic_vector(6 downto 0);
signal i2c_rw           : std_logic;
signal i2c_data_wr      : std_logic_vector(7 downto 0);
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

signal slave_index      : natural range 0 to 4;

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
    data_wr     => i2c_data_wr,
    busy        => i2c_busy,
    data_rd     => i2c_data_rd,
    ack_error_o => i2c_ack_error,
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
            slave_index <= 0;
            busy_cnt := 0;
            busy_prev <= '1';
            i2c_rw <= '1';
            i2c_ena <= '0';
            i2c_addr <= (others => '0');
            i2c_data_wr <= X"00";
            data_rd <= (others => '0');
            TEMP_MON <= (others => (others => '0'));
        else
            busy_prev <= i2c_busy;

            case (i2c_fsm) is
                -- Wait for 1 sec to start
                when INIT =>
                    if (i2c_busy = '0' and i2c_start = '1') then
                        i2c_fsm <= READ_DATA;
                    end if;

                -- Pointer register defaults to temperature reg. So,
                -- directly Read i2 bytes from the current slave
                when READ_DATA =>
                    if (i2c_rise = '1') then
                        busy_cnt := busy_cnt + 1;
                    end if;

                    case busy_cnt is
                        -- Initiate the transaction by writing to
                        -- pointer register.
                        -- '0' is write, '1' is read
                        when 0 =>
                            i2c_ena <= '1';
                            i2c_addr <= SLAVE_ARRAY(slave_index)(6 downto 0);
                            i2c_rw <= '1';          -- read
                        when 1 =>
                            if (i2c_busy = '0') then
                                data_rd(15 downto 8) <= i2c_data_rd;
                            end if;
                        when 2 =>
                            i2c_ena <= '0';
                            if (i2c_busy = '0') then
                                data_rd(7 downto 0) <= i2c_data_rd;
                                busy_cnt := 0;
                                i2c_fsm <= NEXT_SLAVE;
                            end if;

                        when others => NULL;
                    end case;

                -- Latch read data and move to next slave
                when NEXT_SLAVE =>
                    if (i2c_start = '1') then
                        if (slave_index = 4) then
                            slave_index <= 0;
                        else
                            slave_index <= slave_index + 1;
                        end if;

                        i2c_fsm <= READ_DATA;
                    end if;

                    -- Latch and sign convert sensor data. It has 0.5C
                    -- resolution
                    TEMP_MON(slave_index) <=
                   std_logic_vector(resize(signed(data_rd(15 downto 8)), 32));

                when others => NULL;

            end case;
        end if;
    end if;
end process;

end rtl;
