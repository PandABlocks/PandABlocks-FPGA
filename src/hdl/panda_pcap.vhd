--------------------------------------------------------------------------------
--  File:       panda_pcap.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_pcap is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- AXI3 HP Bus Write Only Interface
    m_axi_awready       : in  std_logic;
    m_axi_awaddr        : out std_logic_vector(31 downto 0);
    m_axi_awvalid       : out std_logic;
    m_axi_awburst       : out std_logic_vector(1 downto 0);
    m_axi_awcache       : out std_logic_vector(3 downto 0);
    m_axi_awid          : out std_logic_vector(5 downto 0);
    m_axi_awlen         : out std_logic_vector(3 downto 0);
    m_axi_awlock        : out std_logic_vector(1 downto 0);
    m_axi_awprot        : out std_logic_vector(2 downto 0);
    m_axi_awqos         : out std_logic_vector(3 downto 0);
    m_axi_awsize        : out std_logic_vector(2 downto 0);
    m_axi_bid           : in  std_logic_vector(5 downto 0);
    m_axi_bready        : out std_logic;
    m_axi_bresp         : in  std_logic_vector(1 downto 0);
    m_axi_bvalid        : in  std_logic;
    m_axi_wready        : in  std_logic;
    m_axi_wdata         : out std_logic_vector(63 downto 0);
    m_axi_wvalid        : out std_logic;
    m_axi_wlast         : out std_logic;
    m_axi_wstrb         : out std_logic_vector(7 downto 0);
    m_axi_wid           : out std_logic_vector(5 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    pcap_irq_o          : out std_logic
-- Output pulse
);
end panda_pcap;

architecture rtl of panda_pcap is


component fifo_generator_0
port (
    rst             : in  std_logic;
    wr_clk          : in  std_logic;
    rd_clk          : in  std_logic;
    din             : in  std_logic_vector(31 DOWNTO 0);
    wr_en           : in  std_logic;
    rd_en           : in  std_logic;
    dout            : out std_logic_vector(63 DOWNTO 0);
    full            : out std_logic;
    empty           : out std_logic;
    rd_data_count   : out std_logic_vector(8 DOWNTO 0)
);
end component;

constant AXI_BURST_LEN      : integer := 16;
constant AXI_DATA_WIDTH     : integer := 64;

-- IRQ Status encoding
constant IRQ_IDLE           : std_logic_vector(3 downto 0) := "0000";
constant IRQ_LAST_TLP       : std_logic_vector(3 downto 0) := "0001";
constant IRQ_BLOCK_FINISHED : std_logic_vector(3 downto 0) := "0010";
constant IRQ_ADDR_ERROR     : std_logic_vector(3 downto 0) := "0100";
constant IRQ_USER_ABORT     : std_logic_vector(3 downto 0) := "1000";

type pcap_fsm_t is (WAIT_ARM, IDLE, ACTV, DO_DMA, IS_FINISHED, IRQ, ABORTED);
signal pcap_fsm             : pcap_fsm_t;

signal fifo_rst             : std_logic;
signal dma_start            : std_logic;
signal dma_done             : std_logic;
signal dma_irq              : std_logic;
signal dma_error            : std_logic;
signal irq_status           : std_logic_vector(3 downto 0);
signal tlp_count            : unsigned(31 downto 0);
signal last_tlp             : std_logic;
signal axi_awaddr_val       : unsigned(31 downto 0);
signal axi_wdata_val        : std_logic_vector(63 downto 0);
signal next_dmaaddr_valid   : std_logic;

signal PCAP_ENABLE_VAL      : std_logic_vector(SBUSBW-1 downto 0);
signal PCAP_TRIGGER_VAL     : std_logic_vector(SBUSBW-1 downto 0);
signal PCAP_TLP_COUNT       : std_logic_vector(31 downto 0);
signal PCAP_ARM             : std_logic;
signal PCAP_ABORT           : std_logic;
signal PCAP_DBG_MODE        : std_logic;
signal PCAP_DBG_ENA         : std_logic;
signal PCAP_DBG_PRESC       : integer range 0 to 7;
signal PCAP_DBG_DWORDS      : std_logic_vector(31 downto 0);
signal PCAP_DMAADDR_WSTB    : std_logic;
signal PCAP_DMAADDR         : std_logic_vector(31 downto 0);

signal dbg_enable           : std_logic;
signal dbg_counter          : unsigned(31 downto 0);
signal dbg_trig_counter     : unsigned(7 downto 0);
signal dbg_trigger_bit      : std_logic;
signal dbg_trigger          : std_logic;

signal enable_val           : std_logic;
signal trigger_val          : std_logic;

signal fifo_rd_data_count   : std_logic_vector(8 downto 0);
signal fifo_rd_en           : std_logic;
signal fifo_din             : std_logic_vector(31 downto 0);
signal fifo_dout            : std_logic_vector(63 downto 0);
signal fifo_count           : integer range 0 to 511;

begin

mem_dat_o <= (others => '0');

pcap_irq_o <= dma_irq;

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            PCAP_ENABLE_VAL  <= TO_STD_VECTOR(127, SBUSBW);
            PCAP_TRIGGER_VAL <= TO_STD_VECTOR(127, SBUSBW);
            PCAP_TLP_COUNT <= TO_STD_VECTOR(4, 32);
            PCAP_DMAADDR_WSTB <= '0';
            PCAP_DMAADDR <= (others => '0');
            PCAP_ARM <= '0';
            PCAP_ABORT <= '0';
            PCAP_DBG_MODE <= '0';
            PCAP_DBG_ENA <= '0';
            PCAP_DBG_PRESC  <= 5;
            PCAP_DBG_DWORDS <= TO_STD_VECTOR(1024, 32);
        else
            -- Single clock pulse
            PCAP_DBG_ENA <= '0';
            PCAP_ARM <= '0';
            PCAP_DMAADDR_WSTB <= '0';
            PCAP_ABORT <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Pulse start position
                if (mem_addr_i = PCAP_ENABLE_VAL_ADDR) then
                    PCAP_ENABLE_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- Pulse start position
                if (mem_addr_i = PCAP_TRIGGER_VAL_ADDR) then
                    PCAP_TRIGGER_VAL <= mem_dat_i(SBUSBW-1 downto 0);
                end if;

                -- DMA Block size in TLPs (each TLP is 128 Bytes)
                if (mem_addr_i = PCAP_DMA_BUFSIZE_ADDR) then
                    PCAP_TLP_COUNT <= mem_dat_i;
                end if;

                -- DMA block Soft ARM
                if (mem_addr_i = PCAP_ARM_ADDR) then
                    PCAP_ARM <= '1';
                end if;

                -- DMA block address
                if (mem_addr_i = PCAP_DMAADDR_ADDR) then
                    PCAP_DMAADDR <= mem_dat_i(31 downto 0);
                    PCAP_DMAADDR_WSTB <= '1';
                end if;

                -- DMA block Soft ARM
                if (mem_addr_i = PCAP_ABORT_ADDR) then
                    PCAP_ABORT <= '1';
                end if;

                -- DBG : Mode
                if (mem_addr_i = PCAP_DBG_MODE_ADDR) then
                    PCAP_DBG_MODE <= mem_dat_i(0);
                end if;

                -- DBG : Enable
                if (mem_addr_i = PCAP_DBG_ENA_ADDR) then
                    PCAP_DBG_ENA <= mem_dat_i(0);
                end if;

                -- DBG : Presc bit
                if (mem_addr_i = PCAP_DBG_DWORDS_ADDR) then
                    PCAP_DBG_PRESC <= to_integer(unsigned(mem_dat_i(4 downto 0)));
                end if;

                -- DBG : DWORD count
                if (mem_addr_i = PCAP_DBG_DWORDS_ADDR) then
                    PCAP_DBG_DWORDS <= mem_dat_i(31 downto 0);
                end if;

            end if;
        end if;
    end if;
end process;

--
-- DBG : Test incrementing data stream
--
DBG_CORE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            dbg_counter <= (others => '0');
            dbg_trig_counter <= (others => '0');
            dbg_trigger <= '0';
            dbg_enable <= '0';
        else
            if (PCAP_DBG_ENA = '1') then
                dbg_enable <= '1';
            elsif (dbg_counter = unsigned(PCAP_DBG_DWORDS)) then
                dbg_enable <= '0';
            end if;

            -- DBG incremental posn data
            if (dbg_enable = '0') then
                dbg_counter <= (others => '0');
            elsif (trigger_val = '1') then
                dbg_counter <= dbg_counter + 1;
            end if;

            -- DBG write trigger for required number of DWORDS
            if (dbg_enable = '0') then
                dbg_trig_counter <= (others => '0');
            else
                dbg_trig_counter <= dbg_trig_counter + 1;
            end if;

            -- DBG Prescaled trigger pulse
            dbg_trigger_bit <= dbg_trig_counter(PCAP_DBG_PRESC);
            dbg_trigger <= dbg_trig_counter(PCAP_DBG_PRESC) and not dbg_trigger_bit;
        end if;
    end if;
end process;

--
-- Design Bus Assignments
--
process(clk_i)
    variable t_counter  : unsigned(31 downto 0);
begin
    if rising_edge(clk_i) then
        if (PCAP_DBG_MODE = '1') then
            enable_val <= dbg_enable;
            trigger_val <= dbg_trigger;
            fifo_din <= std_logic_vector(dbg_counter);
        else
            enable_val <= SBIT(sysbus_i, PCAP_ENABLE_VAL);
            trigger_val <= SBIT(sysbus_i, PCAP_TRIGGER_VAL);
            fifo_din <= posbus_i(0);
        end if;
    end if;
end process;

--
-- 32bit-to-64-bit FIFO with 1K samples
--
PCAP_FIFO_INST : fifo_generator_0
port map (
    rst             => fifo_rst,
    wr_clk          => clk_i,
    rd_clk          => clk_i,
    din             => fifo_din,
    wr_en           => trigger_val,
    rd_en           => fifo_rd_en,
    dout            => fifo_dout,
    full            => open,
    empty           => open,
    rd_data_count   => fifo_rd_data_count
);

fifo_count <= to_integer(unsigned(fifo_rd_data_count));


--
-- PCAP Main State Machine
--
PCAP_STATE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            pcap_fsm <= WAIT_ARM;
            dma_irq <= '0';
            last_tlp <= '0';
            tlp_count <= (others => '0');
            dma_start <= '0';
            irq_status <= IRQ_IDLE;
            axi_awaddr_val <= (others => '0');
            fifo_rst <= '0';
            next_dmaaddr_valid <= '0';
        elsif (PCAP_ABORT = '1') then
            pcap_fsm <= ABORTED;
            dma_irq <= '1';
            irq_status <= IRQ_USER_ABORT;
        else
            if (PCAP_DMAADDR_WSTB = '1') then
                next_dmaaddr_valid <= '1';
            elsif (pcap_fsm = IS_FINISHED and
                tlp_count = unsigned(PCAP_TLP_COUNT) and
                    next_dmaaddr_valid = '1') then
                next_dmaaddr_valid <= '0';
            end if;

            case pcap_fsm is
                when WAIT_ARM =>
                    if (PCAP_ARM = '1') then
                        pcap_fsm <= IDLE;
                    end if;
                    axi_awaddr_val <= unsigned(PCAP_DMAADDR);

                when IDLE =>
                    last_tlp <= '0';
                    tlp_count <= (others => '0');
                    dma_start <= '0';
                    fifo_rst <= '1';
                    if (enable_val = '1') then
                        fifo_rst <= '0';
                        pcap_fsm <= ACTV;
                    end if;

                when ACTV =>
                    if (fifo_count > 16) then
                        last_tlp <= '0';
                        dma_start <= '1';
                        pcap_fsm <= DO_DMA;
                    elsif (enable_val = '0' and fifo_count <= 16) then
                        last_tlp <= '1';
                        dma_start <= '1';
                        pcap_fsm <= DO_DMA;
                    end if;

                when DO_DMA =>
                    dma_start <= '0';
                    if (dma_done = '1') then
                        tlp_count <= tlp_count + 1;
                        pcap_fsm <= IS_FINISHED;
                    end if;

                when IS_FINISHED =>
                    -- Is this last TLP to be transferred
                    if (last_tlp = '1') then
                        irq_status <= IRQ_LAST_TLP;
                        pcap_fsm <= IRQ;
                        dma_irq <= '1';
                    -- Is block finished
                    elsif (tlp_count = unsigned(PCAP_TLP_COUNT)) then
                        tlp_count <= (others => '0');
                        dma_irq <= '1';
                        if (next_dmaaddr_valid = '1') then
                            pcap_fsm <= IRQ;
                            irq_status <= IRQ_BLOCK_FINISHED;
                            axi_awaddr_val <= unsigned(PCAP_DMAADDR);
                        else
                            pcap_fsm <= ABORTED;
                            irq_status <= IRQ_ADDR_ERROR;
                        end if;
                    -- Continue
                    else
                        pcap_fsm <= ACTV;
                        axi_awaddr_val <= axi_awaddr_val + 128;
                    end if;

                when IRQ =>
                    dma_irq <= '0';
                    -- PCap finished
                    if (last_tlp = '1') then
                        pcap_fsm <= WAIT_ARM;
                    else
                        pcap_fsm <= ACTV;
                    end if;

                when ABORTED =>
                    dma_irq <= '0';

                when others =>

            end case;
        end if;
    end if;
end process;

--
-- AXI DMA Master Engine
--
axi_wdata_val(63 downto 32) <= fifo_dout(31 downto 0);
axi_wdata_val(31 downto 0) <= fifo_dout(63 downto 32);

dma_write_master : entity work.panda_axi3_write_master
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    m_axi_awready       => m_axi_awready,
    m_axi_awaddr        => m_axi_awaddr,
    m_axi_awvalid       => m_axi_awvalid,
    m_axi_awburst       => m_axi_awburst,
    m_axi_awcache       => m_axi_awcache,
    m_axi_awid          => m_axi_awid,
    m_axi_awlen         => m_axi_awlen,
    m_axi_awlock        => m_axi_awlock,
    m_axi_awprot        => m_axi_awprot,
    m_axi_awqos         => m_axi_awqos,
    m_axi_awsize        => m_axi_awsize,
    m_axi_bid           => m_axi_bid,
    m_axi_bready        => m_axi_bready,
    m_axi_bresp         => m_axi_bresp,
    m_axi_bvalid        => m_axi_bvalid,
    m_axi_wready        => m_axi_wready,
    m_axi_wdata         => m_axi_wdata,
    m_axi_wvalid        => m_axi_wvalid,
    m_axi_wlast         => m_axi_wlast,
    m_axi_wstrb         => m_axi_wstrb,
    m_axi_wid           => m_axi_wid,

    dma_addr            => std_logic_vector(axi_awaddr_val),
    dma_data            => axi_wdata_val,
    dma_read            => fifo_rd_en,
    dma_start           => dma_start,
    dma_done            => dma_done,
    dma_error           => dma_error
);

end rtl;

