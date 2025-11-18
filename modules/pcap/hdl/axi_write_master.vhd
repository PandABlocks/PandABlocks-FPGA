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
    M_AXI_BURST_LEN     : in  std_logic_vector(AXI_BURST_WIDTH-1 downto 0);
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
end axi_write_master;

architecture rtl of axi_write_master is

signal AXI_BURST_LEN        : unsigned(AXI_BURST_WIDTH-1 downto 0);
signal awvalid              : std_logic := '0';
signal wvalid               : std_logic := '0';
signal wlast                : std_logic;
signal bready               : std_logic;
signal wnext                : std_logic;
signal aw_throttle          : std_logic;
signal w_throttle           : std_logic;
signal wlen_count           : unsigned(AXI_BURST_WIDTH-1 downto 0);

begin

--
-- Write Address
--
M_AXI_AWREGION <= "0000";
-- Single threaded
M_AXI_AWID <= "000000";
-- Burst Length is number of transaction beats, minus 1
AXI_BURST_LEN <= unsigned(M_AXI_BURST_LEN) - 1;
M_AXI_AWLEN <= std_logic_vector(AXI_BURST_LEN(3 downto 0));
-- Size should be AXI_DATA_WIDTH, in 2^SIZE bytes
M_AXI_AWSIZE <= TO_SVECTOR(LOG2(AXI_DATA_WIDTH/8), 3);
-- INCR burst type is usually used, except for keyhole bursts
M_AXI_AWBURST <= "01";
-- AXI3 atomic access encoding for Normal acces
M_AXI_AWLOCK <= "00";
-- Cacheable write-through, no allocate
M_AXI_AWCACHE <= "0010";
-- Protection encoding for 'Non-secure access'
M_AXI_AWPROT <= "000";
-- Not participating in any QoS scheme
M_AXI_AWQOS <= "0000";

M_AXI_AWVALID <= awvalid;

M_AXI_AWADDR <= dma_addr;

--
-- Write Data
--
M_AXI_WDATA <= dma_data;

-- All bursts are complete and aligned
M_AXI_WSTRB <= (others => '1');
M_AXI_WLAST <= wlast;
M_AXI_WVALID <= wvalid;

--
-- Write Response
--
M_AXI_BREADY <= bready;

--
-- The purpose of the write address channel is to request the address and
-- command information for the entire transaction.  It is a single beat
-- of data for each burst.
--
-- Only one address is issued per DMA request, and wait until data write is
-- completed.
--

WRITE_ADDR_CHANNEL: process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            awvalid <= '0';
        -- If previously not valid and no throttling, start next transaction
        elsif (awvalid = '0' and aw_throttle = '0') then
            awvalid <= '1';
        -- Once asserted, VALIDs cannot be deasserted, so AWVALID
        -- must wait until transaction is accepted before throttling.
        elsif (M_AXI_AWREADY = '1' and awvalid = '1') then
            awvalid <= '0';
        else
            awvalid <= awvalid;
        end if;

        -- aw_throttle is used to issue one address per dma start
        -- for synchronisation with data channel
        if (reset_i = '1') then
            aw_throttle <= '1';
        elsif (dma_start = '1') then
            aw_throttle <= '0';
        elsif (awvalid = '1' and M_AXI_AWREADY = '1' and aw_throttle = '0') then
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
wnext <= M_AXI_WREADY and wvalid;

WRITE_DATA_CHANNEL: process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            wvalid <= '0';
        -- If previously not valid and not throttling, start next transaction
        elsif (wvalid = '0' and w_throttle = '0') then
            wvalid <= '1';
        -- Once asserted, VALIDs cannot be deasserted, so WVALID
        -- must wait until burst is complete with WLAST
        elsif (wnext = '1' and wlast = '1') then
            wvalid <= '0';
        else
            wvalid <= wvalid;
        end if;

        -- w_throttle is used to issue one data burst per dma start
        -- for synchronisation with addr channel
        if (reset_i = '1') then
            w_throttle <= '1';
        elsif (dma_start = '1') then
            w_throttle <= '0';
        elsif (wvalid = '1' and M_AXI_WREADY = '1' and w_throttle = '0') then
            w_throttle <= '1';
        else
            w_throttle <= w_throttle;
        end if;
    end if;
end process;

-- WLAST generation on the MSB of a counter underflow
wlast <= '1' when (wlen_count = AXI_BURST_LEN and wnext = '1') else '0';

-- Burst length counter. Uses extra counter register bit to indicate terminal
-- count to reduce decode logic
BURST_LENGTH_COUNT: process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1' or wlast = '1') then
            wlen_count <= (others => '0');
        elsif (wnext = '1') then
            wlen_count <= wlen_count + 1;
        else
            wlen_count <= wlen_count;
        end if;
    end if;
end process;

-- Always accept a write response from slave
bready <= '1';

dma_done <= M_AXI_BVALID;

-- The BRESP is used indicate any errors from the interconnect or
-- slave for the entire write burst.
dma_error <= M_AXI_BVALID and (M_AXI_BRESP(1) or M_AXI_BRESP(0));
dma_read <= wnext;

end rtl;
