--------------------------------------------------------------------------------
--  File:       panda_axi_read_master.vhd
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

entity table_read_engine is
generic (
    SLAVES              : natural := 6
);
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Zynq HP1 Bus
    m_axi_araddr        : out STD_LOGIC_VECTOR (31 downto 0);
    m_axi_arburst       : out STD_LOGIC_VECTOR (1 downto 0);
    m_axi_arcache       : out STD_LOGIC_VECTOR (3 downto 0);
    m_axi_arid          : out STD_LOGIC_VECTOR (5 downto 0);
    m_axi_arlen         : out STD_LOGIC_VECTOR (7 downto 0);
    m_axi_arlock        : out STD_LOGIC_VECTOR (0 downto 0);
    m_axi_arprot        : out STD_LOGIC_VECTOR (2 downto 0);
    m_axi_arqos         : out STD_LOGIC_VECTOR (3 downto 0);
    m_axi_arready       : in  STD_LOGIC;
    m_axi_arregion      : out STD_LOGIC_VECTOR (3 downto 0);
    m_axi_arsize        : out STD_LOGIC_VECTOR (2 downto 0);
    m_axi_arvalid       : out STD_LOGIC;
    m_axi_rdata         : in  STD_LOGIC_VECTOR (31 downto 0);
    m_axi_rid           : in  STD_LOGIC_VECTOR (5 downto 0);
    m_axi_rlast         : in  STD_LOGIC;
    m_axi_rready        : out STD_LOGIC;
    m_axi_rresp         : in  STD_LOGIC_VECTOR (1 downto 0);
    m_axi_rvalid        : in  STD_LOGIC;
    -- Slaves' DMA Engine Interface
    dma_req_i           : in  std_logic_vector(SLAVES-1 downto 0);
    dma_ack_o           : out std_logic_vector(SLAVES-1 downto 0);
    dma_done_o          : out std_logic;
    dma_addr_i          : in  std32_array(SLAVES-1 downto 0);
    dma_len_i           : in  std8_array(SLAVES-1 downto 0);
    dma_data_o          : out std_logic_vector(31 downto 0);
    dma_valid_o         : out std_logic_vector(SLAVES-1 downto 0)
);
end table_read_engine;

architecture rtl of table_read_engine is

type state_t is (ARBITING, DO_DMA);
signal rdma_fsm         : state_t;

signal dma_start        : std_logic;
signal dma_done         : std_logic;
signal dma_addr         : std_logic_vector(31 downto 0);
signal dma_len          : std_logic_vector(7 downto 0);
signal dma_data         : std_logic_vector(31 downto 0);
signal dma_valid        : std_logic;
signal dma_error        : std_logic;

signal slave_index      : integer range 0 to SLAVES-1;

begin

-- Assign outputs
dma_data_o <= dma_data;
dma_done_o <= dma_done;

VALID_GEN: FOR I IN 0 to SLAVES-1 GENERATE
    dma_valid_o(I) <= dma_valid when (slave_index = I) else '0';
END GENERATE;

axi_read_master : entity work.axi_read_master
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Master Interface Read Address
    M_AXI_ARADDR        => m_axi_ARADDR,
    M_AXI_ARLEN         => m_axi_ARLEN,
    M_AXI_ARSIZE        => m_axi_ARSIZE,
    M_AXI_ARBURST       => m_axi_ARBURST,
    M_AXI_ARLOCK        => m_axi_ARLOCK,
    M_AXI_ARCACHE       => m_axi_ARCACHE,
    M_AXI_ARID          => m_axi_ARID,
    M_AXI_ARPROT        => m_axi_ARPROT,
    M_AXI_ARVALID       => m_axi_ARVALID,
    M_AXI_ARREADY       => m_axi_ARREADY,
    M_AXI_ARREGION      => m_axi_ARREGION,
    -- Master Interface Read Data
    M_AXI_RDATA         => m_axi_RDATA,
    M_AXI_RID           => m_axi_RID,
    M_AXI_RRESP         => m_axi_RRESP,
    M_AXI_RLAST         => m_axi_RLAST,
    M_AXI_RVALID        => m_axi_RVALID,
    M_AXI_RREADY        => m_axi_RREADY,
    -- Interface to data FIFO
    dma_addr_i          => dma_addr,
    dma_len_i           => dma_len,
    dma_start_i         => dma_start,
    dma_done_o          => dma_done,
    dma_data_o          => dma_data,
    dma_valid_o         => dma_valid,
    dma_error_o         => dma_error
);

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slave_index <= 0;
            dma_addr <= (others => '0');
            dma_len <= (others => '0');
            dma_ack_o <= (others => '0');
            dma_start <= '0';
        else
            case rdma_fsm is
                when ARBITING =>
                    if (dma_req_i(slave_index) = '1') then
                        dma_addr <= dma_addr_i(slave_index);
                        dma_len <= dma_len_i(slave_index);
                        -- Acknowledge slave and start DMA immediately.
                        dma_ack_o(slave_index) <= '1';
                        dma_start <= '1';
                        rdma_fsm <= DO_DMA;
                    else
                        if (slave_index = SLAVES - 1) then
                            slave_index <= 0;
                        else
                            slave_index <= slave_index + 1;
                        end if;
                    end if;

                when DO_DMA =>
                    dma_ack_o(slave_index) <= '0';
                    dma_start <= '0';
                    if (dma_done = '1') then
                        rdma_fsm <= ARBITING;
                        if (slave_index = SLAVES - 1) then
                            slave_index <= 0;
                        else
                            slave_index <= slave_index + 1;
                        end if;
                    end if;

                when others =>
            end case;
        end if;
    end if;
end process;

end rtl;
