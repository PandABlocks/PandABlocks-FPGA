library ieee;
use ieee.std_logic_1164.all;

entity temp_sensors_tb is
end entity temp_sensors_tb;

architecture rtl of temp_sensors_tb is

signal clk_i        : std_logic := '0';
signal reset_i      : std_logic := '1';
signal TEMP_PSU     : std_logic_vector(31 downto 0);
signal TEMP_SFP     : std_logic_vector(31 downto 0);
signal TEMP_ENC_L   : std_logic_vector(31 downto 0);
signal TEMP_PICO    : std_logic_vector(31 downto 0);
signal TEMP_ENC_R   : std_logic_vector(31 downto 0);
signal sda          : std_logic;
signal scl          : std_logic;

begin

clk_i <= not clk_i after 10 ns;
reset_i <= '0' after 1000 ns;

uut : entity work.temp_sensors
port map (
    clk_i          => clk_i,
    reset_i        => reset_i,
    sda            => sda,
    scl            => scl,
    TEMP_PSU       => TEMP_PSU,
    TEMP_SFP       => TEMP_SFP,
    TEMP_ENC_L     => TEMP_ENC_L,
    TEMP_PICO      => TEMP_PICO,
    TEMP_ENC_R     => TEMP_ENC_R
);

i2c_slave_model_inst0 : entity work.i2c_slave_model
generic map (
    I2C_ADR         => "1001000"
)
port map (
    scl            => scl,
    sda            => sda
);

--i2c_slave_model_inst1 : entity work.i2c_slave_model
--generic map (
--    I2C_ADR         => "1001001"
--)
--port map (
--    scl            => scl,
--    sda            => sda
--);

scl  <= 'H';
sda  <= 'H';

end rtl;

