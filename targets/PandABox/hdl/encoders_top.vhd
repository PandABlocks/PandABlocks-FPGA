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
    OUTENC_CONN_OUT_o       : out std_logic_vector(ENC_NUM-1 downto 0);
    INENC_CONN_OUT_o        : out std_logic_vector(ENC_NUM-1 downto 0);

    Am0_pad_io              : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bm0_pad_io              : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zm0_pad_io              : inout std_logic_vector(ENC_NUM-1 downto 0);
    As0_pad_io              : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bs0_pad_io              : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zs0_pad_io              : inout std_logic_vector(ENC_NUM-1 downto 0);

    -- Signals passed to internal bus
    clk_int_o               : out std_logic_vector(ENC_NUM-1 downto 0);
    inenc_a_o               : out std_logic_vector(ENC_NUM-1 downto 0);
    inenc_b_o               : out std_logic_vector(ENC_NUM-1 downto 0);
    inenc_z_o               : out std_logic_vector(ENC_NUM-1 downto 0);
    inenc_data_o            : out std_logic_vector(ENC_NUM-1 downto 0);
    -- Block Input and Outputs
    bit_bus_i               : in  bit_bus_t;
    pos_bus_i               : in  pos_bus_t;
    DCARD_MODE_i            : in  std32_array(ENC_NUM-1 downto 0);
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
                    slow_tlp_o.address <= OUTPROT_ADDR_LIST(OUTENC_blk_addr);
                    slow_tlp_o.data <= write_data_i;
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

INENC_read_strobe(I) <= compute_block_strobe(read_address_i, I) and INENC_read_strobe_i;
INENC_write_strobe(I) <= compute_block_strobe(write_address_i, I) and INENC_write_strobe_i;

encoders_block_inst : entity work.encoders_block
port map (
    -- Clock and Reset
    clk_i                   => clk_i,
    reset_i                 => reset_i,
    -- Memory Bus Interface
    OUTENC_read_strobe_i    => OUTENC_read_strobe(I),
    OUTENC_read_data_o      => OUTENC_read_data(I),
    OUTENC_read_ack_o       => OUTENC_read_ack(I),

    OUTENC_write_strobe_i   => OUTENC_write_strobe(I),
    OUTENC_write_ack_o      => open,

    INENC_read_strobe_i     => INENC_read_strobe(I),
    INENC_read_data_o       => INENC_read_data(I),
    INENC_read_ack_o        => INENC_read_ack(I),

    INENC_write_strobe_i    => INENC_write_strobe(I),
    INENC_write_ack_o       => open,

    read_address_i          => read_address_i(BLK_AW-1 downto 0),

    write_address_i         => write_address_i(BLK_AW-1 downto 0),
    write_data_i            => write_data_i,
    -- Encoder I/O Pads
    OUTENC_CONN_OUT_o       => OUTENC_CONN_OUT_o(I),
    INENC_CONN_OUT_o        => INENC_CONN_OUT_o(I),

    clk_int_o               => clk_int_o(I),
    inenc_a_o               => inenc_a_o(I),
    inenc_b_o               => inenc_b_o(I),
    inenc_z_o               => inenc_z_o(I),
    inenc_data_o            => inenc_data_o(I),

    Am0_pad_io              => Am0_pad_io(I), 
    Bm0_pad_io              => Bm0_pad_io(I),
    Zm0_pad_io              => Zm0_pad_io(I),
    As0_pad_io              => As0_pad_io(I),
    Bs0_pad_io              => Bs0_pad_io(I),
    Zs0_pad_io              => Zs0_pad_io(I), 
    -- Position Field interface
    DCARD_MODE_i            => DCARD_MODE_i(I),
    bit_bus_i               => bit_bus_i,
    pos_bus_i               => pos_bus_i,
    posn_o                  => posn(I)
    );


END GENERATE;

end rtl;
