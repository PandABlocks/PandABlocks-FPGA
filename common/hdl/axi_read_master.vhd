--------------------------------------------------------------------------------
--  File:       axi_read_master.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity axi_read_master is
generic (
    AXI_BURST_WIDTH     : natural := 8;
    AXI_ADDR_WIDTH      : natural := 32;
    AXI_DATA_WIDTH      : natural := 32
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Master Interface Read Address
    M_AXI_ARADDR        : out std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    M_AXI_ARID          : out STD_LOGIC_VECTOR (5 downto 0);
    M_AXI_ARLEN         : out std_logic_vector(AXI_BURST_WIDTH-1 downto 0);
    M_AXI_ARSIZE        : out std_logic_vector(2 downto 0);
    M_AXI_ARBURST       : out std_logic_vector(1 downto 0);
    M_AXI_ARLOCK        : out std_logic_vector(0 downto 0);
    M_AXI_ARCACHE       : out std_logic_vector(3 downto 0);
    M_AXI_ARPROT        : out std_logic_vector(2 downto 0);
    M_AXI_ARVALID       : out std_logic;
    M_AXI_ARREADY       : in  std_logic;
    M_AXI_ARREGION      : out STD_LOGIC_VECTOR (3 downto 0);
    M_AXI_ARQOS         : out std_logic_vector(3 downto 0);
    -- Master Interface Read Data
    M_AXI_RDATA         : in  std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    M_AXI_RID           : in  std_logic_vector(5 downto 0);
    M_AXI_RRESP         : in  std_logic_vector(1 downto 0);
    M_AXI_RLAST         : in  std_logic;
    M_AXI_RVALID        : in  std_logic;
    M_AXI_RREADY        : out std_logic;
    -- Interface to data FIFO
    dma_addr_i          : in  std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    dma_len_i           : in  std_logic_vector(AXI_BURST_WIDTH-1 downto 0);
    dma_start_i         : in  std_logic;
    dma_done_o          : out std_logic;
    dma_data_o          : out std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    dma_valid_o         : out std_logic;
    dma_error_o         : out std_logic
);
end axi_read_master;

architecture rtl of axi_read_master is

signal arvalid          : std_logic;
signal rready           : std_logic;

begin

-- Burst LENgth is number of transaction beats, minus 1
M_AXI_ARLEN <= std_logic_vector(unsigned(dma_len_i)-1);

-- Size should be AXI_DATA_WIDTH, in 2^SIZE bytes
M_AXI_ARSIZE <= TO_SVECTOR(LOG2(AXI_DATA_WIDTH/8), 3);

-- INCR burst type is usually used, except for keyhole bursts
M_AXI_ARBURST <= "01";
M_AXI_ARLOCK <= "0";

-- Not Allocated, Modifiable and Bufferable
M_AXI_ARCACHE <= "0011";
M_AXI_ARPROT <= "000";
M_AXI_ARQOS <= "0000";

M_AXI_ARVALID <= arvalid;
M_AXI_RREADY <= rready;

M_AXI_ARREGION <= "0000";
M_AXI_ARID <= "000000";

-- Read Address Channel
-- The Read Address Channel (AW) provides a similar function to the
-- Write Address channel- to provide the tranfer qualifiers for the
-- burst.
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            arvalid <= '0';
            M_AXI_ARADDR <= (others => '0');
        else
            if (arvalid = '1' and M_AXI_ARREADY = '1') then
                arvalid <= '0';
                M_AXI_ARADDR <= (others => '0');
            elsif (dma_start_i = '1') then
                arvalid <= '1';
                M_AXI_ARADDR <= dma_addr_i;
            end if;
        end if;
    end if;
end process;

-- Read Data (and Response) Channel
-- The Read Data channel returns the results of the read request
-- Always able to accept more data, so no need to throttle the RREADY signal
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            rready <= '0';
        else
            rready <= '1';
        end if;
    end if;
end process;


dma_data_o <= M_AXI_RDATA;
dma_valid_o <= M_AXI_RVALID and rready;
dma_error_o <= rready and M_AXI_RVALID and M_AXI_RRESP(1);
dma_done_o <= M_AXI_RVALID and rready and M_AXI_RLAST;

end rtl;
