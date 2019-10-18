library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.slow_defines.all;
use work.addr_defines.all;

entity encoders_top is
port (
    -- Clock and Reset
    clk_i                   : in  std_logic;
    reset_i                 : in  std_logic;
    -- Memory Bus Interface
    OUTENC_read_strobe_i    : in  std_logic;
    OUTENC_read_data_o      : out std_logic_vector(31 downto 0);
    OUTENC_read_ack_o       : out std_logic;

    OUTENC_write_strobe_i   : in  std_logic;
    OUTENC_write_ack_o      : out std_logic;

    INENC_read_strobe_i     : in  std_logic;
    INENC_read_data_o       : out std_logic_vector(31 downto 0);
    INENC_read_ack_o        : out std_logic;

    INENC_write_strobe_i    : in  std_logic;
    INENC_write_ack_o       : out std_logic;

    read_address_i          : in  std_logic_vector(PAGE_AW-1 downto 0);

    write_address_i         : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i            : in  std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    A_OUT_o                 : out std_logic_vector(ENC_NUM-1 downto 0);
    B_OUT_o                 : out std_logic_vector(ENC_NUM-1 downto 0);
    Z_OUT_o                 : out std_logic_vector(ENC_NUM-1 downto 0);
    CLK_IN_i                : in  std_logic_vector(ENC_NUM-1 downto 0);
    DATA_OUT_o              : out std_logic_vector(ENC_NUM-1 downto 0);
    OUTENC_CONN_OUT_o       : out std_logic_vector(ENC_NUM-1 downto 0);

    A_IN_i                  : in  std_logic_vector(ENC_NUM-1 downto 0);
    B_IN_i                  : in  std_logic_vector(ENC_NUM-1 downto 0);
    Z_IN_i                  : in  std_logic_vector(ENC_NUM-1 downto 0);
    CLK_OUT_o               : out std_logic_vector(ENC_NUM-1 downto 0);
    DATA_IN_i               : in  std_logic_vector(ENC_NUM-1 downto 0);
    INENC_CONN_OUT_o        : out std_logic_vector(ENC_NUM-1 downto 0);

    -- Signals passed to internal bus
    clk_int_o               : out std_logic_vector(ENC_NUM-1 downto 0);
    a_int_o                 : out std_logic_vector(ENC_NUM-1 downto 0);
    b_int_o                 : out std_logic_vector(ENC_NUM-1 downto 0);
    z_int_o                 : out std_logic_vector(ENC_NUM-1 downto 0);
    data_int_o              : out std_logic_vector(ENC_NUM-1 downto 0);
    -- Block Input and Outputs
    bit_bus_i               : in  bit_bus_t;
    pos_bus_i               : in  pos_bus_t;
    DCARD_MODE_i            : in  std32_array(ENC_NUM-1 downto 0);
    OUTENC_PROTOCOL_o       : out std3_array(ENC_NUM-1 downto 0);
    INENC_PROTOCOL_o        : out std3_array(ENC_NUM-1 downto 0);
    posn_o                  : out std32_array(ENC_NUM-1 downto 0);

    slow_tlp_o              : out slow_packet

);
end encoders_top;

architecture rtl of encoders_top is

signal OUTENC_read_strobe       : std_logic_vector(ENC_NUM-1 downto 0);
signal OUTENC_read_data         : std32_array(ENC_NUM-1 downto 0);
signal OUTENC_write_strobe      : std_logic_vector(ENC_NUM-1 downto 0);
signal OUTENC_read_ack          : std_logic_vector(ENC_NUM-1 downto 0);
signal OUTENC_blk_addr          : natural range 0 to (2**(PAGE_AW-BLK_AW)-1);
signal OUTENC_write_address     : natural range 0 to (2**BLK_AW - 1);

signal INENC_read_strobe        : std_logic_vector(ENC_NUM-1 downto 0);
signal INENC_read_data          : std32_array(ENC_NUM-1 downto 0);
signal INENC_write_strobe       : std_logic_vector(ENC_NUM-1 downto 0);
signal posn                     : std32_array(ENC_NUM-1 downto 0);
signal INENC_read_ack           : std_logic_vector(ENC_NUM-1 downto 0);
signal INENC_blk_addr           : natural range 0 to (2**(PAGE_AW-BLK_AW)-1);
signal INENC_write_address      : natural range 0 to (2**BLK_AW - 1);

begin

-- Acknowledgement to AXI Lite interface
OUTENC_write_ack_o <= '1';
OUTENC_read_ack_o <= or_reduce(OUTENC_read_ack);


-- Multiplex read data out from multiple instantiations
OUTENC_read_data_o <= OUTENC_read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

-- Loopbacks onto system bus
clk_int_o <= CLK_IN_i;

-- Used for Slow output signal
OUTENC_write_address <= to_integer(unsigned(write_address_i(BLK_AW-1 downto 0)));
OUTENC_blk_addr <= to_integer(unsigned(write_address_i(PAGE_AW-1 downto BLK_AW)));

-- Acknowledgement to AXI Lite interface
INENC_write_ack_o <= '1';
INENC_read_ack_o <= or_reduce(INENC_read_ack);

-- Multiplex read data out from multiple instantiations
INENC_read_data_o <= INENC_read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

-- Used for Slow output signal
INENC_write_address <= to_integer(unsigned(write_address_i(BLK_AW-1 downto 0)));
INENC_blk_addr <= to_integer(unsigned(write_address_i(PAGE_AW-1 downto BLK_AW)));

-- Outputs
posn_o <= posn;

-- Loopbacks onto system bus
a_int_o <= A_IN_i;
b_int_o <= B_IN_i;
z_int_o <= Z_IN_i;
data_int_o <= DATA_IN_i;

-- slow registers

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slow_tlp_o.strobe <= 'Z';
            slow_tlp_o.address <= (others => 'Z');
            slow_tlp_o.data <= (others => 'Z');
        else
            -- Single clock cycle strobe
            slow_tlp_o.strobe <= 'Z';
            -- OUTENC PROTOCOL Slow Registers
            if (OUTENC_write_strobe_i = '1') then
                if (OUTENC_write_address = OUTENC_PROTOCOL_addr) then
                    slow_tlp_o.strobe <= '1';
                    slow_tlp_o.data <= write_data_i;
                    slow_tlp_o.address <= OUTPROT_ADDR_LIST(OUTENC_blk_addr);
                end if;
            elsif (INENC_write_strobe_i = '1') then
                if (INENC_write_address = INENC_PROTOCOL_addr) then
                    slow_tlp_o.strobe <= '1';
                    slow_tlp_o.data <= write_data_i;
                    slow_tlp_o.address <= INPROT_ADDR_LIST(INENC_blk_addr);
                end if;
            else
                slow_tlp_o.strobe <= 'Z';
                slow_tlp_o.address <= (others => 'Z');
                slow_tlp_o.data <= (others => 'Z');
            end if;
        end if;
    end if;
end process;

--
-- Instantiate ENCOUT Blocks :
--  There are ENC_NUM amount of encoders on the board
--
ENC_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

-- Sub-module address decoding
OUTENC_read_strobe(I) <= compute_block_strobe(read_address_i, I) and OUTENC_read_strobe_i;
OUTENC_write_strobe(I) <= compute_block_strobe(write_address_i, I) and OUTENC_write_strobe_i;

outenc_block_inst : entity work.outenc_block
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Bus Interface
    read_strobe_i       => OUTENC_read_strobe(I),
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => OUTENC_read_data(I),
    read_ack_o          => OUTENC_read_ack(I),

    write_strobe_i      => OUTENC_write_strobe(I),
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,
    -- Encoder I/O Pads
    A_OUT               => A_OUT_o(I),
    B_OUT               => B_OUT_o(I),
    Z_OUT               => Z_OUT_o(I),
    CLK_IN              => CLK_IN_i(I),
    DATA_OUT            => DATA_OUT_o(I),
    CONN_OUT            => OUTENC_CONN_OUT_o(I),
    -- Position Bus Input
    PROTOCOL            => OUTENC_PROTOCOL_o(I),
    DCARD_MODE          => DCARD_MODE_i(I),
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i
);

-- Sub-module address decoding
INENC_read_strobe(I) <= compute_block_strobe(read_address_i, I) and INENC_read_strobe_i;
INENC_write_strobe(I) <= compute_block_strobe(write_address_i, I) and INENC_write_strobe_i;

inenc_block_inst : entity work.inenc_block
port map (

    clk_i               => clk_i,
    reset_i             => reset_i,

    read_strobe_i       => INENC_read_strobe(I),
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => INENC_read_data(I),
    read_ack_o          => INENC_read_ack(I),

    write_strobe_i      => INENC_write_strobe(I),
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,

    A_IN                => A_IN_i(I),
    B_IN                => B_IN_i(I),
    Z_IN                => Z_IN_i(I),
    CLK_OUT             => CLK_OUT_o(I),
    DATA_IN             => DATA_IN_i(I),
    CLK_IN              => CLK_IN_i(I),
    CONN_OUT            => INENC_CONN_OUT_o(I),

    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    DCARD_MODE          => DCARD_MODE_i(I),
    PROTOCOL            => INENC_PROTOCOL_o(I),
    posn_o              => posn(I)
);


END GENERATE;

end rtl;
