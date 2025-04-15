-- This entity is used in DMA instances and it manages the DMA transfers,
-- it also detects when table_length is written to signal the start of a
-- DMA transfer if the module has started using the last table written. This
-- extra constraint is to make sure the module got is working with the right
-- length without spending significant memory resources.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity table_read_engine_client is
    port (
        clk_i : in  std_logic;
        abort_i : in  std_logic;
        address_i : in  std_logic_vector(31 downto 0);
        length_i : in  std_logic_vector(31 downto 0);
        length_wstb_i : in  std_logic;
        length_o : out std_logic_vector(31 downto 0);
        more_o : out std_logic;
        length_taken_i : in std_logic;
        length_zero_event_o : out std_logic;
        completed_o : out std_logic;
        available_beats_i : in std_logic_vector(31 downto 0);
        overflow_error_o : out std_logic;
        repeat_i : in std_logic_vector(31 downto 0);
        busy_o : out std_logic;
        -- DMA Engine Interface
        dma_req_o : out std_logic;
        dma_ack_i : in  std_logic;
        dma_done_i : in  std_logic;
        dma_addr_o : out std_logic_vector(31 downto 0);
        dma_len_o : out std_logic_vector(7 downto 0);
        dma_data_i : in std_logic_vector(31 downto 0);
        dma_valid_i : in std_logic;
        dma_irq_o : out std_logic;
        dma_done_irq_o : out std_logic
    );
end;

architecture rtl of table_read_engine_client is
    signal transfer_busy : std_logic;
    signal start : std_logic;
    signal completed : std_logic;
    signal completed_dly : std_logic;
    signal address : std_logic_vector(31 downto 0);
begin
    busy_o <= transfer_busy;
    completed_o <= completed;
    dma_done_irq_o <= completed and not completed_dly;

    regs: process (clk_i)
    begin
        if rising_edge(clk_i) then
            completed_dly <= completed;
        end if;
    end process;

    transfer_mgr: entity work.table_read_engine_client_transfer_manager port map(
        clk_i => clk_i,
        abort_i => abort_i,
        start_i => start,
        address_i => address,
        beats_i => "00000000000" & length_i(22 downto 2),
        available_i => available_beats_i,
        busy_o => transfer_busy,
        -- DMA Engine Interface
        dma_req_o => dma_req_o,
        dma_ack_i => dma_ack_i,
        dma_done_i => dma_done_i,
        dma_addr_o => dma_addr_o,
        dma_len_o => dma_len_o,
        dma_data_i => dma_data_i,
        dma_valid_i => dma_valid_i
    );

    length_mgr: entity work.table_read_engine_client_length_manager port map(
        clk_i => clk_i,
        abort_i => abort_i,
        address_i => address_i,
        length_i => length_i,
        length_wstb_i => length_wstb_i,
        address_o => address,
        length_o => length_o,
        more_o => more_o,
        length_taken_i => length_taken_i,
        length_zero_event_o => length_zero_event_o,
        completed_o => completed,
        overflow_error_o => overflow_error_o,
        repeat_i => repeat_i,
        became_ready_event_o => dma_irq_o,
        transfer_busy_i => transfer_busy,
        transfer_start_o => start
    );
end;
