library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;

entity panda_csr_if is
generic (
    AXI_AWIDTH          : integer := 32;
    AXI_DWIDTH          : integer := 32;
    MEM_CSWIDTH         : integer := 5 ;  -- Memory pages = 2**CSW
    MEM_AWIDTH          : integer := 8;   -- 2**AW Words per page
    MEM_DWIDTH          : integer := 32   -- Width of data bus
);
port (
    -- AXI4-Lite Clock and Reset
    S_AXI_CLK           : in std_logic;
    S_AXI_RST           : in std_logic;
    -- AXI4-Lite SLAVE SINGLE INTERFACE
    S_AXI_AWADDR        : in  std_logic_vector(AXI_AWIDTH-1 downto 0);
    S_AXI_AWVALID       : in  std_logic;
    S_AXI_AWREADY       : out std_logic;
    S_AXI_WDATA         : in  std_logic_vector(AXI_DWIDTH-1 downto 0);
    S_AXI_WSTRB         : in  std_logic_vector((AXI_DWIDTH/8)-1 downto 0);
    S_AXI_WVALID        : in  std_logic;
    S_AXI_WREADY        : out std_logic;
    S_AXI_BRESP         : out std_logic_vector(1 downto 0);
    S_AXI_BVALID        : out std_logic;
    S_AXI_BREADY        : in  std_logic;
    S_AXI_ARADDR        : in  std_logic_vector(AXI_AWIDTH-1 downto 0);
    S_AXI_ARVALID       : in  std_logic;
    S_AXI_ARREADY       : out std_logic;
    S_AXI_RDATA         : out std_logic_vector(AXI_DWIDTH-1 downto 0);
    S_AXI_RRESP         : out std_logic_vector(1 downto 0);
    S_AXI_RVALID        : out std_logic;
    S_AXI_RREADY        : in  std_logic;
    -- Memory Bus Interface Signals
    mem_cs_o            : out std_logic_vector(2**MEM_CSWIDTH-1 downto 0);
    mem_rstb_o          : out std_logic;
    mem_wstb_o          : out std_logic;
    mem_dat_o           : out std_logic_vector(MEM_DWIDTH-1 downto 0);
    mem_addr_o          : out std_logic_vector(MEM_AWIDTH-1 downto 0);
    mem_dat_i           : in  std32_array(2**MEM_CSWIDTH-1 downto 0)
);
end entity panda_csr_if;

architecture rtl of panda_csr_if is

-- Get ChipSelect vector
function CSGEN(
    data        : std_logic_vector;
    CSW         : integer;
    AW          : integer
) return std_logic_vector is
    variable result : std_logic_vector(2**CSW-1 downto 0) := (others => '0');
begin
    result(to_integer(unsigned(data(AW+CSW+1 downto AW+2)))) := '1';
    return result;
end;

-- Read Data multiplexer
function RD_DATA_MUX(
    data        : std32_array;
    addr        : std_logic_vector;
    CSW         : integer;
    AW          : integer
) return std_logic_vector is
begin
    return data(to_integer(unsigned(addr(AW+CSW+1 downto AW+2))));
end;


signal new_write_access     : std_logic := '0';
signal new_read_access      : std_logic := '0';
signal ongoing_write        : std_logic := '0';
signal ongoing_read         : std_logic := '0';
signal mem_read_data        : std_logic_vector(31 downto 0);
signal read_valid           : std_logic_vector(1 downto 0);

begin

-- Detect new transaction.
-- Only allow one access at a time
new_write_access <= not (ongoing_read or ongoing_write) and
                            S_AXI_AWVALID and S_AXI_WVALID;
new_read_access <= not (ongoing_read or ongoing_write) and
                            S_AXI_ARVALID and not new_write_access;

-- Acknowledge new transaction.
S_AXI_AWREADY <= new_write_access;
S_AXI_WREADY  <= new_write_access;
S_AXI_ARREADY <= new_read_access;

-- Store register address and write data
Reg: process (S_AXI_CLK) is
begin
    if rising_edge(S_AXI_CLK) then
        if (S_AXI_RST = '1') then
            mem_addr_o <= (others => '0');
            mem_dat_o <= (others => '0');
            mem_cs_o <= (others => '0');
        else
            mem_cs_o <= (others => '0');
            if (new_write_access = '1') then
                mem_addr_o <= S_AXI_AWADDR(MEM_AWIDTH-1+2 downto 2);
                mem_dat_o <= S_AXI_WDATA(MEM_DWIDTH-1 downto 0);
                mem_cs_o <= CSGEN(S_AXI_AWADDR, MEM_CSWIDTH, MEM_AWIDTH);
            elsif (new_read_access = '1') then
                mem_addr_o <= S_AXI_ARADDR(MEM_AWIDTH-1+2 downto 2);
                mem_cs_o <= CSGEN(S_AXI_ARADDR, MEM_CSWIDTH, MEM_AWIDTH);
            end if;
        end if;
    end if;
end process;

-- Handle write access.
WriteAccess: process (S_AXI_CLK) is
begin
    if rising_edge(S_AXI_CLK) then
        if (S_AXI_RST = '1') then
            ongoing_write <= '0';
        elsif (new_write_access = '1') then
            ongoing_write <= '1';
        elsif (ongoing_write = '1' and S_AXI_BREADY = '1') then
            ongoing_write <= '0';
        end if;
        mem_wstb_o <= new_write_access;
    end if;
end process WriteAccess;

S_AXI_BVALID <= ongoing_write;
S_AXI_BRESP  <= (others => '0');

-- Handle read access
ReadAccess: process (S_AXI_CLK) is
begin
    if rising_edge(S_AXI_CLK) then

        if (S_AXI_RST = '1') then
            ongoing_read   <= '0';
            read_valid <= "00";
        elsif (new_read_access = '1') then
            ongoing_read   <= '1';
            read_valid <= "00";
        elsif (ongoing_read = '1') then
            if (S_AXI_RREADY = '1' and read_valid = "00") then
                read_valid <= "01";
            elsif (S_AXI_RREADY = '1' and read_valid = "01") then
                read_valid <= "10";
            elsif (S_AXI_RREADY = '1' and read_valid = "10") then
                read_valid <= "00";
                ongoing_read <= '0';
            end if;
        end if;

        mem_rstb_o <= new_read_access;

    end if;
end process ReadAccess;

S_AXI_RVALID <= read_valid(1);
S_AXI_RRESP  <= (others => '0');

Not_All_Bits_Are_Used: if (MEM_DWIDTH < AXI_DWIDTH) generate
begin
    S_AXI_RDATA(AXI_DWIDTH-1 downto AXI_DWIDTH - MEM_DWIDTH)  <= (others=>'0');
end generate Not_All_Bits_Are_Used;

S_AXI_RDATA_DFF : for I in MEM_DWIDTH - 1 downto 0 generate
    begin
    S_AXI_RDATA_FDRE : FDRE
        port map (
          Q     => S_AXI_RDATA(I),
          C     => S_AXI_CLK,
          CE    => ongoing_read,
          D     => mem_read_data(I),
          R     => S_AXI_RST
      );
end generate S_AXI_RDATA_DFF;

-- Memory read data multiplexer
-- There are 2**CS pages
READ_DATA_MUX : process(mem_dat_i)
begin
    mem_read_data <= RD_DATA_MUX(mem_dat_i, S_AXI_ARADDR, MEM_CSWIDTH, MEM_AWIDTH);
end process;

end architecture rtl;
