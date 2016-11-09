LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;


library work;
use work.top_defines.all;

ENTITY pcap_core_tb IS
END pcap_core_tb;

ARCHITECTURE behavior OF pcap_core_tb IS 

--Inputs
signal clk_i            : std_logic := '0';
signal reset_i          : std_logic := '1';
signal ARM              : std_logic := '0';
signal DISARM           : std_logic := '0';
signal START_WRITE      : std_logic := '0';
signal WRITE            : std_logic_vector(31 downto 0) := (others => '0');
signal WRITE_WSTB       : std_logic := '0';
signal FRAMING_MASK     : std_logic_vector(31 downto 0) := (others => '0');
signal FRAMING_ENABLE   : std_logic := '0';
signal FRAMING_MODE     : std_logic_vector(31 downto 0) := (others => '0');
signal FRAME_NUM        : std_logic_vector(31 downto 0) := (others => '0');
signal enable_i         : std_logic := '0';
signal capture_i        : std_logic := '0';
signal frame_i          : std_logic := '0';
signal data_val_i       : std_logic := '0';
signal dma_full_i       : std_logic := '0';
signal sysbus_i         : sysbus_t := (others => '0');
signal posbus_i         : posbus_t := (others => (others => '0'));

--Outputs
signal FRAME_COUNT      : std_logic_vector(31 downto 0);
signal ERR_STATUS       : std_logic_vector(31 downto 0);
signal pcap_dat_o       : std_logic_vector(31 downto 0);
signal pcap_dat_valid_o : std_logic;
signal pcap_done_o      : std_logic;
signal pcap_actv_o      : std_logic;
signal pcap_status_o    : std_logic_vector(2 downto 0);

signal adc_data         : unsigned(31 downto 0);

BEGIN

clk_i <= not clk_i after 4 ns;
reset_i <= '0' after 100 ns;

-- Instantiate the Unit Under Test (UUT)
uut: entity work.pcap_core
PORT MAP (
    clk_i               => clk_i,
    reset_i             => reset_i,
    ARM                 => ARM,
    DISARM              => DISARM,
    START_WRITE         => START_WRITE,
    WRITE               => WRITE,
    WRITE_WSTB          => WRITE_WSTB,
    FRAMING_MASK        => FRAMING_MASK,
    FRAMING_ENABLE      => FRAMING_ENABLE,
    FRAMING_MODE        => FRAMING_MODE,
    FRAME_NUM           => FRAME_NUM,
    FRAME_COUNT         => FRAME_COUNT,
    ERR_STATUS          => ERR_STATUS,
    enable_i            => enable_i,
    capture_i           => capture_i,
    frame_i             => frame_i,
    data_val_i          => data_val_i,
    dma_full_i          => dma_full_i,
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    pcap_dat_o          => pcap_dat_o,
    pcap_dat_valid_o    => pcap_dat_valid_o,
    pcap_done_o         => pcap_done_o,
    pcap_actv_o         => pcap_actv_o,
    pcap_status_o       => pcap_status_o
);

-- Configuraton Stimulus process
stim_config: process
begin
    -- hold reset state
    wait for 1000 ns;
    START_WRITE <= '1'; wait for 8 ns; START_WRITE <= '0';
    wait for 1000 ns;
    WRITE <= X"0000_0016";
    WRITE_WSTB <= '1'; wait for 8 ns; WRITE_WSTB <= '0';
    wait for 1000 ns;
    FRAMING_ENABLE <= '1';
    FRAMING_MASK(22) <= '1';
    wait for 2000 ns;
    ARM <= '1';wait for 8 ns; ARM <= '0';
    wait;
end process;

-- ADC Stimulus process
stim_adc: process
begin
    adc_data <= (others => '0');
    -- hold reset state
    wait for 1000 ns;
    adc_loop : loop
        adc_data <= adc_data + 1;
        data_val_i <= '1'; wait for 8 ns; data_val_i <= '0';
        wait for 1000 ns;
    end loop;
    wait;
end process;

posbus_i(22) <= std_logic_vector(adc_data);
posbus_i(23) <= std_logic_vector(adc_data);
posbus_i(24) <= std_logic_vector(adc_data);
posbus_i(25) <= std_logic_vector(adc_data);


END;
