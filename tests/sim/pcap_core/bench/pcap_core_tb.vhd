LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;


library work;
use work.top_defines.all;

ENTITY pcap_core_tb IS
END pcap_core_tb;

ARCHITECTURE behavior OF pcap_core_tb IS 

--Inputs
signal clk_i            : std_logic := '1';
signal reset_i          : std_logic := '1';
signal ARM              : std_logic := '0';
signal DISARM           : std_logic := '0';
signal START_WRITE      : std_logic := '0';
signal WRITE            : std_logic_vector(31 downto 0) := (others => '0');
signal WRITE_WSTB       : std_logic := '0';
signal FRAMING_MASK     : std_logic_vector(31 downto 0) := (others => '0');
signal FRAMING_ENABLE   : std_logic := '0';
signal FRAMING_MODE     : std_logic_vector(31 downto 0) := (others => '0');
signal enable_i         : std_logic := '0';
signal capture_i        : std_logic := '0';
signal frame_i          : std_logic := '0';
signal data_val_i       : std_logic := '0';
signal dma_error_i      : std_logic := '0';
signal sysbus_i         : sysbus_t := (others => '0');
signal posbus_i         : posbus_t := (others => (others => '0'));

--Outputs
signal ERR_STATUS       : std_logic_vector(31 downto 0);
signal pcap_dat_o       : std_logic_vector(31 downto 0);
signal pcap_dat_valid_o : std_logic;
signal pcap_done_o      : std_logic;
signal pcap_actv_o      : std_logic;
signal pcap_status_o    : std_logic_vector(2 downto 0);

signal adc_data         : unsigned(31 downto 0);

BEGIN

clk_i <= not clk_i after 4 ns;

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
    MAX_FRAME           => "000",
    FRAMING_MASK        => FRAMING_MASK,
    FRAMING_ENABLE      => FRAMING_ENABLE,
    FRAMING_MODE        => FRAMING_MODE,
    ERR_STATUS          => ERR_STATUS,
    enable_i            => enable_i,
    capture_i           => capture_i,
    frame_i             => frame_i,
    dma_error_i         => dma_error_i,
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    pcap_dat_o          => pcap_dat_o,
    pcap_dat_valid_o    => pcap_dat_valid_o,
    pcap_done_o         => pcap_done_o,
    pcap_actv_o         => pcap_actv_o,
    pcap_status_o       => pcap_status_o
);

--------------------------------------------------------------------------
-- Configuraton
-- capture_mode flags
-- 0 x x  : posn
-- 1 0 x  : posn_latch
-- 1 1 0  : posn_delta
-- 1 1 1  : posn_sun
--------------------------------------------------------------------------
stim_config: process
begin
    adc_data <= (others => '0');
    reset_i <= '1';
    wait until (clk_i'event and clk_i = '1');
    wait for 80 ns; reset_i <= '0';
    --------------------------------------------------
    -- Initiliase and ARM
    -------------------------------------------------
    wait for 80 ns;
    START_WRITE <= '1'; wait for 8 ns; START_WRITE <= '0';
    wait for 80 ns;
    WRITE <= X"0000_0016";
    WRITE_WSTB <= '1'; wait for 8 ns; WRITE_WSTB <= '0';
    wait for 80 ns;
    WRITE <= X"0000_0020";
    WRITE_WSTB <= '1'; wait for 8 ns; WRITE_WSTB <= '0';
    wait for 1000 ns;
    FRAMING_ENABLE <= '1';
    FRAMING_MASK(22) <= '1';
    FRAMING_MODE(22) <= '1';
    wait for 1000 ns;
    enable_i <= '1';

    --------------------------------------------------
    -- ARM #1
    -------------------------------------------------
    wait for 10000 ns;
    ARM <= '1';wait for 8 ns; ARM <= '0';
    wait for 10000 ns;
    -- Frame and Capture
    wait for 10000 ns;
    for I in 0 to 9 loop
        frame_i <= '1'; wait for 8 ns; frame_i <= '0';
        -- adc_loop:
        for I in 0 to 99 loop
            adc_data <= adc_data + 1;
            data_val_i <= '1'; wait for 8 ns; data_val_i <= '0';
            wait for 80 ns;
        end loop;

        capture_i <= '1'; wait for 8 ns; capture_i <= '0';
        wait for 1000 ns;
    end loop;
    wait for 50000 ns;
    DISARM <= '1';wait for 8 ns; DISARM <= '0';
    --------------------------------------------------
    -- ARM #2
    -------------------------------------------------
    wait for 10000 ns;
    ARM <= '1';wait for 8 ns; ARM <= '0';
    wait for 10000 ns;
    -- Frame and Capture
    wait for 10000 ns;
    for I in 0 to 9 loop
        frame_i <= '1'; wait for 8 ns; frame_i <= '0';
        -- adc_loop:
        for I in 0 to 99 loop
            adc_data <= adc_data + 1;
            data_val_i <= '1'; wait for 8 ns; data_val_i <= '0';
            wait for 80 ns;
        end loop;

        capture_i <= '1'; wait for 8 ns; capture_i <= '0';
        wait for 1000 ns;
    end loop;
    wait for 10000 ns;
    enable_i <= '0';
    wait for 10000 ns;
    assert false report "Simulation Finished" severity failure;
end process;

posbus_i(22) <= std_logic_vector(adc_data);
posbus_i(23) <= std_logic_vector(adc_data);
posbus_i(24) <= std_logic_vector(adc_data);
posbus_i(25) <= std_logic_vector(adc_data);


END;
