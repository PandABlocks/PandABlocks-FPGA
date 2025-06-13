library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity table_read_engine_client_transfer_manager is
generic (
    AXI_BURST_LEN : integer := 256
);
port (
    clk_i : in  std_logic;
    abort_i : in std_logic;
    start_i : in std_logic;
    address_i : in std_logic_vector(31 downto 0);
    length_i : in std_logic_vector(31 downto 0);
    available_i : in std_logic_vector(31 downto 0);
    busy_o : out std_logic := '0';
    last_o : out std_logic := '0';
    -- DMA Engine Interface
    dma_req_o : out std_logic := '0';
    dma_ack_i : in  std_logic;
    dma_done_i : in  std_logic;
    dma_addr_o : out std_logic_vector(31 downto 0) := (others => '0');
    dma_len_o : out std_logic_vector(7 downto 0) := (others => '0');
    dma_data_i : in  std_logic_vector(31 downto 0);
    dma_valid_i : in  std_logic
);
end;

architecture rtl of table_read_engine_client_transfer_manager is
    type state_t is (DMA_IDLE, DMA_WAIT_ROOM, DMA_WAIT_ACK, DMA_READING);
    signal state : state_t := DMA_IDLE;
    signal dma_addr : unsigned(31 downto 0) := (others => '0');
    signal left : unsigned(31 downto 0) := (others => '0');
    signal dma_transfer : unsigned(8 downto 0) := (others => '0');
    signal abort : std_logic := '0';
    signal last_burst : std_logic := '0';
begin
    dma_len_o <= std_logic_vector(dma_transfer(7 downto 0));
    dma_addr_o <= std_logic_vector(dma_addr);
    busy_o <= '1' when state /= DMA_IDLE or start_i = '1' else '0';
    last_o <= dma_done_i and last_burst;

    latch_abort: process (clk_i)
    begin
        if rising_edge(clk_i) then
            if abort_i then
                abort <= '1';
            elsif state = DMA_IDLE then
                abort <= '0';
            end if;
        end if;
    end process;

    process (clk_i)
        variable next_left : unsigned(31 downto 0) := (others => '0');
        variable next_dma_transfer : unsigned(8 downto 0) := (others => '0');
    begin
        if rising_edge(clk_i) then
            case state is
                when DMA_IDLE =>
                    last_burst <= '0';
                    dma_addr <= unsigned(address_i);
                    left <= unsigned(length_i);
                    if start_i then
                        state <= DMA_WAIT_ROOM;
                    end if;
                when DMA_WAIT_ROOM =>
                    next_dma_transfer :=
                        to_unsigned(AXI_BURST_LEN, next_dma_transfer'length)
                            when left > AXI_BURST_LEN else
                        left(8 downto 0);
                    if abort then
                        state <= DMA_IDLE;
                    elsif unsigned(available_i) >= next_dma_transfer then
                        dma_req_o <= '1';
                        state <= DMA_WAIT_ACK;
                        dma_transfer <= next_dma_transfer;
                    end if;
                when DMA_WAIT_ACK =>
                    if dma_ack_i then
                        next_left := left - dma_transfer;
                        left <= next_left;
                        if next_left = 0 then
                            last_burst <= '1';
                        end if;
                        dma_req_o <= '0';
                        state <= DMA_READING;
                    end if;
                when DMA_READING =>
                    if dma_done_i then
                        dma_addr <= dma_addr + (dma_transfer & "00");
                        if left > 0 then
                            state <= DMA_WAIT_ROOM;
                        else
                            state <= DMA_IDLE;
                        end if;
                    end if;
                when others =>
                    state <= DMA_IDLE;
            end case;
        end if;
    end process;
end;
