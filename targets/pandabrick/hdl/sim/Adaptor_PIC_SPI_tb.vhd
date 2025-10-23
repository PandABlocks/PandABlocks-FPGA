library ieee;
use ieee.std_logic_1164.all;

library work;
use work.glbl;

entity Adaptor_PIC_SPI_tb is
end entity;

architecture loopback of Adaptor_PIC_SPI_tb is

component Adaptor_PIC_SPI is
port (
        i_clk     : in  std_logic;          -- 125MHz System (AXI) clock.
        o_PIC_SC  : out std_logic;          -- SPI Serial Clock
		o_PIC_CS  : out std_logic;          -- SPI Chip Select (low during transfer)
		o_PIC_DI  : out std_logic;          -- SPI PIC Data In (to PIC)
        i_PIC_DO  : in  std_logic;          -- SPI PIC Data Out (from PIC) 
        o_done    : out std_logic;          -- Transfer finished on Rising edge of this output.
        
        i_data    : in std_logic_vector(15 downto 0);   -- Data to send to the PIC.
        o_data    : out std_logic_vector(15 downto 0)   -- Data received from the PIC.
);
end component;

signal clk : std_logic := '0';
signal PIC_SC, PIC_CS, PIC_DI, PIC_DO : std_logic;
signal done : std_logic;
signal tx_data, rx_data : std_logic_vector(15 downto 0) := (others => '0'); -- data sent and recieved by the PIC
signal i_data, o_data : std_logic_vector(15 downto 0); --data sent and recieved by the FPGA
signal stop : boolean := false;
    
begin

PIC_SPI_inst: Adaptor_PIC_SPI
port map(
    i_clk       => clk,
    o_PIC_SC    => PIC_SC,
    o_PIC_CS    => PIC_CS,
    o_PIC_DI    => PIC_DI,
    i_PIC_DO    => PIC_DO,
    o_done      => done,
    i_data      => i_data,
    o_data      => o_data
);

clk_gen: process
begin
    while not stop loop
        clk <= not clk;
        wait for 4 ns;
    end loop;
    wait;
end process;

-- Stimulus below based on observed behaviour of DUT

stim_gen: process
begin
    PIC_DO <= '0';
    wait for 100 ns;
    i_data <= X"DEAD";
    tx_data <= X"BEEF";
    wait until falling_edge(PIC_CS);
    PIC_DO <= tx_data(tx_data'high);
    tx_data <= tx_data(tx_data'high-1 downto 0) & '0';
    while (done = '0') loop
        wait until falling_edge(PIC_SC) or rising_edge(PIC_SC) or rising_edge(PIC_CS);
        if falling_edge(PIC_SC) then
            rx_data <= rx_data(rx_data'high-1 downto 0) & PIC_DI;        
        end if;
        if rising_edge(PIC_SC) then
            PIC_DO <= tx_data(tx_data'high);
            tx_data <= tx_data(tx_data'high-1 downto 0) & '0';
        end if;
    end loop;
    wait for 100 ns;
    stop <= true;
    wait;
end process;

end loopback;

