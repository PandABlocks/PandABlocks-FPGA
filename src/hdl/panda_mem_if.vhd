----------------------------------------------------------------------------
--
-- AXI4-Lite Slave interface example
--
-- The purpose of this design is to provide a simple AXI4-Lite Slave interface.
--
-- The AXI4-Lite interface is a subset of the AXI4 interface intended for
-- communication with control registers in components.
-- The key features of the AXI4-Lite interface are:
--         >> all transactions are burst length of 1
--         >> all data accesses are the same size as the width of the data bus
--         >> support for data bus width of 32-bit or 64-bit
--
-- This design implements four 32-bit memory mapped registers. These registers
-- can be read and written by a AXI4-Lite master.
--
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity panda_mem_if is
generic (
    C_S_AXI_DATA_WIDTH  : integer := 32;    -- Data Bus Width
    C_S_AXI_ADDR_WIDTH  : integer := 32;    -- 2^ADDR Bytes Address Space
    C_S_IP_ADDR_WIDTH   : integer := 11     -- Local address / CS
);
port (
    -- System Signals
    ACLK            : in std_logic;
    ARESETN         : in std_logic;

    -- Slave Interface Write Address channel Ports
    S_AXI_AWADDR    : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWPROT    : in  std_logic_vector(2 downto 0);
    S_AXI_AWVALID   : in  std_logic;
    S_AXI_AWREADY   : out std_logic;

    -- Slave Interface Write Data channel Ports
    S_AXI_WDATA     : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1   downto 0);
    S_AXI_WSTRB     : in  std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
    S_AXI_WVALID    : in  std_logic;
    S_AXI_WREADY    : out std_logic;

    -- Slave Interface Write Response channel Ports
    S_AXI_BRESP     : out std_logic_vector(1 downto 0);
    S_AXI_BVALID    : out std_logic;
    S_AXI_BREADY    : in  std_logic;

    -- Slave Interface Read Address channel Ports
    S_AXI_ARADDR    : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT    : in  std_logic_vector(2 downto 0);
    S_AXI_ARVALID   : in  std_logic;
    S_AXI_ARREADY   : out std_logic;

    -- Slave Interface Read Data channel Ports
    S_AXI_RDATA     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP     : out std_logic_vector(1 downto 0);
    S_AXI_RVALID    : out std_logic;
    S_AXI_RREADY    : in  std_logic;

    -- Bus Memory Interface
    mem_addr_o      : out std_logic_vector(C_S_IP_ADDR_WIDTH-1 downto 0);
    mem_dat_i       : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    mem_dat_o       : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    mem_rstb_o      : out std_logic;
    mem_wstb_o      : out std_logic
);
end panda_mem_if;


architecture rtl of panda_mem_if is

----------------------------------------------------------------------------
-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
-- ADDR_LSB is used for addressing 32/64 bit registers/memories
-- ADDR_LSB = 2 for 32 bits (n downto 2)
-- ADDR_LSB = 3 for 64 bits (n downto 3)
constant ADDR_LSB : integer := integer(ceil(log2(real(C_S_AXI_DATA_WIDTH/8))));
constant ADDR_MSB : integer := C_S_AXI_ADDR_WIDTH;

----------------------------------------------------------------------------
-- Function called log2 that returns an integer which has the
-- value of the ceiling of the log base 2.
----------------------------------------------------------------------------
-- AXI4 Lite internal signals
signal axi_rresp        : std_logic_vector(1 downto 0);
signal axi_bresp        : std_logic_vector(1 downto 0);
signal axi_awready      : std_logic;
signal axi_wready       : std_logic;
signal axi_bvalid       : std_logic;
signal axi_rvalid       : std_logic;
signal write_address       : std_logic_vector(ADDR_MSB-1 downto 0);
signal read_address       : std_logic_vector(ADDR_MSB-1 downto 0);
signal axi_rdata        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
signal axi_arready_s1   : std_logic;
signal axi_arready_s2   : std_logic;
signal write_data        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

begin

S_AXI_AWREADY <= axi_awready;
S_AXI_WREADY  <= axi_wready;
S_AXI_BRESP   <= axi_bresp;
S_AXI_BVALID  <= axi_bvalid;
S_AXI_ARREADY <= axi_arready_s2;
S_AXI_RDATA   <= axi_rdata;
S_AXI_RVALID  <= axi_rvalid;
S_AXI_RRESP   <= axi_rresp;

----------------------------------------------------------------------------
-- WRITE Address and Data come together
-- Accept write address and data by asserting *wready lines for one ACLK
process(ACLK)
begin
    if rising_edge(ACLK) then
        if (ARESETN='0') then
            axi_awready <= '0';
            axi_wready <= '0';
        else
            if (axi_awready='0' and S_AXI_AWVALID='1' and S_AXI_WVALID='1') then
                axi_awready <= '1';
            else
                axi_awready <= '0';
            end if;

            if (axi_wready='0' and S_AXI_AWVALID='1' and S_AXI_WVALID='1') then
                axi_wready <= '1';
            else
                axi_wready <= '0';
            end if;
        end if;
    end if;
end process;

write_address <= S_AXI_AWADDR;
write_data <= S_AXI_WDATA;

----------------------------------------------------------------------------
-- Implement memory mapped register select and write logic generation
--
-- Write strobe is generated after  write data is accepted, when axi_wready
-- S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
mem_wstb_o <= '1' when (axi_wready='1' and S_AXI_WVALID='1' and axi_awready='1' and S_AXI_AWVALID = '1') else '0';

mem_dat_o <= write_data;

----------------------------------------------------------------------------
--  The write response and response valid signals are asserted by the slave
--  when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
--  This marks the acceptance of address and indicates the status of
--  write transaction.
process(ACLK)
begin
    if rising_edge(ACLK) then
        if (ARESETN='0') then
            axi_bvalid <= '0';
            axi_bresp <= "00";
        else
            if (axi_awready='1' and S_AXI_AWVALID='1' and axi_wready='1' and S_AXI_WVALID='1' and axi_bvalid='0') then
                -- indicates a valid write response is available
                axi_bvalid <= '1';
                axi_bresp  <= "00"; -- 'OKAY' response
            else
                if (S_AXI_BREADY='1' and axi_bvalid='1') then
                    --check if bready is asserted while bvalid is high)
                    --(there is a possibility that bready is always asserted high)
                    axi_bvalid <= '0';
                end if;
            end if;
        end if;
    end if;
end process;

----------------------------------------------------------------------------
--  axi_arready is asserted for one ACLK clock cycle when
--  S_AXI_ARVALID is asserted. axi_awready is
--  de-asserted when reset (active low) is asserted.
--  The read address is also latched when S_AXI_ARVALID is
--  asserted. read_address is reset to zero on reset assertion.
process(ACLK)
begin
    if rising_edge(ACLK) then
        if (ARESETN='0') then
            axi_arready_s1 <= '0';
            axi_arready_s2 <= '0';
        else
            if (axi_arready_s1='0' and axi_arready_s2='0' and S_AXI_ARVALID='1') then
                axi_arready_s1 <= '1';
            else
                axi_arready_s1 <= '0';
            end if;

            if (axi_arready_s2='0' and axi_arready_s1='1' and S_AXI_ARVALID='1') then
                axi_arready_s2 <= '1';
            else
                axi_arready_s2 <= '0';
            end if;

        end if;
    end if;
end process;

read_address  <= S_AXI_ARADDR;


----------------------------------------------------------------------------
--  axi_rvalid is asserted for one ACLK clock cycle when both
--  S_AXI_ARVALID and axi_arready are asserted. The slave registers
--  data are available on the axi_rdata bus at this instance. The
--  assertion of axi_rvalid marks the validity of read data on the
--  bus and axi_rresp indicates the status of read transaction.axi_rvalid
--  is deasserted on reset (active low). axi_rresp and axi_rdata are
--  cleared to zero on reset (active low).
process(ACLK)
begin
    if rising_edge(ACLK) then
        if (ARESETN='0') then
            axi_rvalid <= '0';
            axi_rresp  <= "00";
        else
            if (axi_arready_s2='1' and S_AXI_ARVALID='1' and axi_rvalid='0') then
                -- Valid read data is available at the read data bus
                axi_rvalid <= '1';
                axi_rresp  <= "00"; -- 'OKAY' response
            elsif (axi_rvalid='1' and S_AXI_RREADY='1') then
                -- Read data is accepted by the master
                axi_rvalid <= '0';
            end if;
        end if;
    end if;
end process;

----------------------------------------------------------------------------
-- Slave register read enable is asserted when valid address is available
-- and the slave is ready to accept the read address.
mem_rstb_o <= '1' when (axi_arready_s2='1' and S_AXI_ARVALID='1' and axi_rvalid='0') else '0';

axi_rdata <= mem_dat_i;

-- For AXI Lite interface, interconnect will duplicate the addresses on both
-- the read and write channel. so onlyone address is used for decoding as well
-- as passing it to IP.
mem_addr_o <= read_address(C_S_IP_ADDR_WIDTH+ADDR_LSB-1 downto ADDR_LSB) 
              when (S_AXI_ARVALID='1')
              else write_address(C_S_IP_ADDR_WIDTH+ADDR_LSB-1 downto ADDR_LSB);


end rtl;
