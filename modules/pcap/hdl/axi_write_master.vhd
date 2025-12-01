--------------------------------------------------------------------------------
--  File:       axi_write_master.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity axi_write_master is
generic (
    AXI_BURST_WIDTH     : natural := 4;
    AXI_ADDR_WIDTH      : natural := 32;
    AXI_DATA_WIDTH      : natural := 32
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- AXI Transaction Parameters
    m_axi_burst_len     : in  std_logic_vector(AXI_BURST_WIDTH-1 downto 0);
    -- AXI HP Bus Write Only Interface
    m_axi_awready       : in  std_logic;
    m_axi_awregion      : out std_logic_vector(3 downto 0);
    m_axi_awaddr        : out std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
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
    m_axi_wdata         : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    m_axi_wvalid        : out std_logic;
    m_axi_wlast         : out std_logic;
    m_axi_wstrb         : out std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
    -- Interface to data FIFO
    dma_addr            : in  std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    dma_read            : out std_logic;
    dma_data            : in  std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    dma_start           : in  std_logic;
    dma_done            : out std_logic;
    dma_error           : out std_logic
);
end;

architecture rtl of axi_write_master is

signal axi_burst_len        : unsigned(AXI_BURST_WIDTH-1 downto 0);
signal awvalid              : std_logic := '0';
signal wvalid               : std_logic := '0';
signal wlast                : std_logic;
signal bready               : std_logic;
signal wnext                : std_logic;
signal aw_throttle          : std_logic := '0';
signal w_throttle           : std_logic := '0';
signal wlen_count           : unsigned(AXI_BURST_WIDTH-1 downto 0) := (others => '0');

begin

--
-- Write Address
--
m_axi_awregion <= "0000";
-- Single threaded
m_axi_awid <= "000000";
-- Burst Length is number of transaction beats, minus 1
axi_burst_len <= unsigned(m_axi_burst_len) - 1;
m_axi_awlen <= std_logic_vector(AXI_BURST_LEN(3 downto 0));
-- Size should be AXI_DATA_WIDTH, in 2^SIZE bytes
m_axi_awsize <= TO_SVECTOR(LOG2(AXI_DATA_WIDTH/8), 3);
-- INCR burst type is usually used, except for keyhole bursts
m_axi_awburst <= "01";
-- AXI3 atomic access encoding for Normal acces
m_axi_awlock <= "00";
-- Cacheable write-through, no allocate
m_axi_awcache <= "0010";
-- Protection encoding for 'Non-secure access'
m_axi_awprot <= "000";
-- Not participating in any QoS scheme
m_axi_awqos <= "0000";

m_axi_awvalid <= awvalid;

m_axi_awaddr <= dma_addr;

--
-- Write Data
--
m_axi_wdata <= dma_data;

-- All bursts are complete and aligned
m_axi_wstrb <= (others => '1');
m_axi_wlast <= wlast;
m_axi_wvalid <= wvalid;

--
-- Write Response
--
m_axi_bready <= bready;

--
-- The purpose of the write address channel is to request the address and
-- command information for the entire transaction.  It is a single beat
-- of data for each burst.
--
-- Only one address is issued per DMA request, and wait until data write is
-- completed.
--

write_addr_channel: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i then
            awvalid <= '0';
        -- If previously not valid and no throttling, start next transaction
        elsif not awvalid and not aw_throttle then
            awvalid <= '1';
        -- Once asserted, VALIDs cannot be deasserted, so AWVALID
        -- must wait until transaction is accepted before throttling.
        elsif m_axi_awready and awvalid then
            awvalid <= '0';
        end if;

        -- aw_throttle is used to issue one address per dma start
        -- for synchronisation with data channel
        if reset_i then
            aw_throttle <= '1';
        elsif dma_start then
            aw_throttle <= '0';
        elsif awvalid and m_axi_awready and not aw_throttle then
            aw_throttle <= '1';
        else
            aw_throttle <= aw_throttle;
        end if;
    end if;
end process;

-- The write data will continually try to push write data across the interface.
--
-- The amount of data accepted will depend on the AXI slave and the AXI
-- Interconnect settings, such as if there are FIFOs enabled in interconnect.
--
-- The simpliest but lowest performance would be to only issue one address write
-- and write data burst at a time.
--

-- Forward movement occurs when the channel is valid and ready
wnext <= m_axi_wready and wvalid;

write_data_channel: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i then
            wvalid <= '0';
        -- If previously not valid and not throttling, start next transaction
        elsif not wvalid and not w_throttle then
            wvalid <= '1';
        -- Once asserted, VALIDs cannot be deasserted, so WVALID
        -- must wait until burst is complete with WLAST
        elsif wnext and wlast then
            wvalid <= '0';
        end if;

        -- w_throttle is used to issue one data burst per dma start
        -- for synchronisation with addr channel
        if reset_i then
            w_throttle <= '1';
        elsif dma_start then
            w_throttle <= '0';
        elsif wvalid and m_axi_wready and not w_throttle then
            w_throttle <= '1';
        else
            w_throttle <= w_throttle;
        end if;
    end if;
end process;

-- WLAST generation on the MSB of a counter underflow
wlast <= '1' when wlen_count = axi_burst_len and wnext = '1' else '0';

-- Burst length counter. Uses extra counter register bit to indicate terminal
-- count to reduce decode logic
burst_length_count: process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i or wlast then
            wlen_count <= (others => '0');
        elsif wnext then
            wlen_count <= wlen_count + 1;
        end if;
    end if;
end process;

-- Always accept a write response from slave
bready <= '1';

dma_done <= m_axi_bvalid;

-- The BRESP is used indicate any errors from the interconnect or
-- slave for the entire write burst.
dma_error <= m_axi_bvalid and (m_axi_bresp(1) or m_axi_bresp(0));
dma_read <= wnext;

end;
