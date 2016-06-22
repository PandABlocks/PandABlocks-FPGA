LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

ENTITY panda_ssi_tb IS
END panda_ssi_tb;

ARCHITECTURE behavior OF panda_ssi_tb IS 

signal clk_i : std_logic := '1';
signal reset_i : std_logic := '1';
signal enc_bits_i : std_logic_vector(7 downto 0) := (others => '0');
signal sclk_presc_i : std_logic_vector(31 downto 0) := (others => '0');
signal enc_rate_i : std_logic_vector(31 downto 0) := (others => '0');
signal posn_o : std_logic_vector(31 downto 0);
signal posn_valid_o : std_logic;

signal posn             : natural := 1000;
signal position         : std_logic_vector(31 downto 0);

signal master_dati      : std_logic;
signal master_scko      : std_logic;
signal slave_dato       : std_logic;
signal slave_scki       : std_logic;
signal cable_connected  : std_logic;
BEGIN

clk_i <= not clk_i after 4 ns;
reset_i <= '0' after 1000 ns;

enc_bits_i   <= std_logic_vector(to_unsigned(24, 8));
sclk_presc_i <= std_logic_vector(to_unsigned(125, 32));
enc_rate_i   <= std_logic_vector(to_unsigned(12500, 32));

master : entity work.panda_ssimstr
PORT MAP (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enc_bits_i      => enc_bits_i,
    sclk_presc_i    => sclk_presc_i,
    enc_rate_i      => enc_rate_i,
    ssi_sck_o       => master_scko,
    ssi_dat_i       => master_dati,
    posn_o          => posn_o,
    posn_valid_o    => posn_valid_o
);

slave : entity work.panda_ssislv
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enc_bits_i      => enc_bits_i,
    ssi_sck_i       => slave_scki,
    ssi_dat_o       => slave_dato,
    posn_i          => position
);

process(clk_i) begin
    if rising_edge(clk_i) then
        position <= std_logic_vector(to_unsigned(posn, 32));

        if (posn_valid_o = '1') then
            posn <= posn + 1000;
        end if;
    end if;
end process;


-- Data is always connected since its is tied to clock.
master_dati <= slave_dato;
slave_scki <= master_scko when (cable_connected = '1') else '1';

process begin
    cable_connected <= '0';
    wait for 220 us;
    cable_connected <= '1';
    wait for 500 us;
    cable_connected <= '0';
    wait for 900 us;
    cable_connected <= '1';
    wait;
end process;

end;
