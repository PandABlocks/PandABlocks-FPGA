--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Long table based position generation module.
--                32-bit data in and out interface.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity pgen is
generic (
    AXI_BURST_LEN       : integer := 256;
    DW                  : natural := 32     -- Output Data Width
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    enable_i            : in  std_logic;
    trig_i              : in  std_logic;
    out_o               : out std_logic_vector(DW-1 downto 0);
    -- Block Parameters
    REPEATS             : in  std_logic_vector(31 downto 0);
    ACTIVE_o            : out std_logic;
    TABLE_ADDRESS       : in  std_logic_vector(31 downto 0);
    TABLE_ADDRESS_WSTB  : in  std_logic;
    TABLE_LENGTH        : in  std_logic_vector(31 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic;
    health              : out std_logic_vector(31 downto 0) := (others => '0');
    -- DMA Engine Interface
    dma_req_o           : out std_logic;
    dma_ack_i           : in  std_logic;
    dma_done_i          : in  std_logic;
    dma_addr_o          : out std_logic_vector(31 downto 0);
    dma_len_o           : out std_logic_vector(7 downto 0);
    dma_data_i          : in  std_logic_vector(31 downto 0);
    dma_valid_i         : in  std_logic
);
end pgen;

architecture rtl of pgen is

type state_t is (IDLE, WAIT_FIFO, DMA_REQ, DMA_READ, IS_FINISHED, FINISHED);
signal pgen_fsm         : state_t;
signal reset            : std_logic;
signal TABLE_WORDS      : unsigned(31 downto 0);

signal table_cycle      : unsigned(31 downto 0);
signal table_ready      : std_logic := '0';

signal fifo_reset       : std_logic;
signal fifo_rd_en       : std_logic;
signal fifo_dout        : std_logic_vector(DW-1 downto 0);
signal fifo_count       : integer range 0 to 1023;
signal fifo_full        : std_logic;
signal write_ready_o    : std_logic;
signal fifo_empty       : std_logic;
signal read_valid_o     : std_logic;
signal fifo_data_count  : std_logic_vector(10 downto 0);
signal fifo_available   : std_logic;

signal trig             : std_logic;
signal enable           : std_logic;
signal trig_pulse       : std_logic;
signal enable_fall      : std_logic;

signal count            : unsigned(31 downto 0);
signal dma_len          : unsigned(8 downto 0);
signal dma_addr         : unsigned(31 downto 0);

signal dma_underrun     : std_logic;
signal table_end        : std_logic;

signal active           : std_logic := '0';

signal out_buffer     : std_logic_vector(DW-1 downto 0);

begin

-- Assign outputs
dma_len_o <= std_logic_vector(dma_len(7 downto 0));
dma_addr_o <= std_logic_vector(dma_addr);
out_o <= out_buffer;

-- Reset for state machine
reset <= not table_ready or enable_fall;

dma_fifo_inst : entity work.fifo generic map(
    data_width => 32,
    fifo_bits  => 10
) port map (
    clk_i          => clk_i,
    reset_fifo_i   => fifo_reset,
    write_data_i   => dma_data_i,
    write_valid_i  => dma_valid_i,
    read_ready_i   => fifo_rd_en,
    read_data_o    => fifo_dout,
    write_ready_o  => write_ready_o,
    read_valid_o   => read_valid_o,
    std_logic_vector(fifo_depth_o)   => fifo_data_count
);

fifo_reset <= reset;
fifo_rd_en <= trig_pulse;
fifo_count <= to_integer(unsigned(fifo_data_count));
fifo_full <= not write_ready_o;
fifo_empty <= not read_valid_o;

-- There is space (>256 words) in the fifo, so perform data read from
-- host memory.
fifo_available <= '1' when (fifo_count < 768) else '0';

--
-- Input registers
--
process(clk_i) begin
    if rising_edge(clk_i) then
        trig <= trig_i;
        enable <= enable_i;
    end if;
end process;

process(clk_i) begin
    if trig_pulse = '1' then
        out_buffer <= fifo_dout;
    end if;
end process;

-- Trigger pulse pops data from fifo and tick data counter when block
-- is enabled and table is ready.
trig_pulse <= (trig_i and not trig) and active and table_ready;
enable_fall <= not enable_i and enable;

--
-- Table ready controls state machine reset. The table is un-validated once
-- LENGTH=0 written.
--
TABLE_WORDS <= unsigned(TABLE_LENGTH) srl 2;  -- Byte -> Dword

process(clk_i) begin
    if rising_edge(clk_i) then
        if (TABLE_LENGTH_WSTB = '1') then
            if (TABLE_WORDS = 0) then
                table_ready <= '0';
            elsif (TABLE_WORDS /= 0) then
                table_ready <= '1';
            end if;
        end if;
    end if;
end process;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            dma_req_o <= '0';
            count <= (others => '0');
            dma_addr <= (others => '0');
            dma_len <= (others => '0');
            table_cycle <= (others => '0');
            pgen_fsm <= IDLE;
        else
            case pgen_fsm is
                when IDLE =>
                    -- Wait following fifo reset by monitoring full flag.
                    if (fifo_full = '0') then
                        table_cycle <= table_cycle + 1;
                        count <= TABLE_WORDS;
                        dma_addr <= unsigned(TABLE_ADDRESS);
                        pgen_fsm <= WAIT_FIFO;
                    end if;

                -- Wait until enough space available in the fifo.
                when WAIT_FIFO =>
                    if (fifo_available = '1') then
                        dma_req_o <= '1';
                        pgen_fsm <= DMA_REQ;

                        -- Determine dma length in samples.
                        if (count < AXI_BURST_LEN) then
                            dma_len <= count(8 downto 0);
                        else
                            dma_len <= to_unsigned(AXI_BURST_LEN, dma_len'length);
                        end if;
                    end if;

                when DMA_REQ =>
                    if (dma_ack_i = '1') then
                        dma_req_o <= '0';
                        pgen_fsm <= DMA_READ;
                    end if;

                when DMA_READ =>
                    -- Wait until DMA completes, and keep track of total count.
                    if (dma_done_i = '1') then
                        count <= count - dma_len;
                        dma_addr <= dma_addr + dma_len * 4;
                        pgen_fsm <= IS_FINISHED;
                    end if;

                when IS_FINISHED =>
                    -- Is table finished?
                    if (count = 0) then
                        -- Are there more table REPEATS?
                        if (table_cycle = unsigned(REPEATS)) then
                            pgen_fsm <= FINISHED;
                        else
                            count <= TABLE_WORDS;
                            dma_addr <= unsigned(TABLE_ADDRESS);
                            pgen_fsm <= WAIT_FIFO;
                            table_cycle <= table_cycle + 1;
                        end if;
                    else
                        pgen_fsm <= WAIT_FIFO;
                    end if;

                -- Wait for re-enable to start over.
                when FINISHED =>
                    dma_req_o <= '0';
                    count <= (others => '0');
                    dma_addr <= (others => '0');
                    dma_len <= (others => '0');
            end case;
        end if;
    end if;
end process;

--
-- Error detection, and reporting.
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            dma_underrun <= '0';
            table_end <= '0';
            health <= (others => '0');
        else
            -- Detect Table End reached once in operation.
            if (pgen_fsm = FINISHED and fifo_empty = '1' and trig_pulse = '1') then
                table_end <= '1';
            end if;

            -- Detect DMA underrun, and stop operation.
            if (trig_pulse = '1' and fifo_empty = '1') then
                dma_underrun <= '1';
            end if;

            -- Assign HEALTH output as Enum.
            if (table_ready = '0') then
                health(1 downto 0) <= TO_SVECTOR(1,2);
            elsif (dma_underrun = '1') then
                health(1 downto 0) <= TO_SVECTOR(3,2);
            else
                health(1 downto 0) <= (others => '0');
            end if;

        end if;
    end if;
end process;

active <= enable and not fifo_empty;

ACTIVE_o <= active;

end rtl;

