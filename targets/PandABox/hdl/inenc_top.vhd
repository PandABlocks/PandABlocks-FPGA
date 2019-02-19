--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Top-level design instantiating 4 channels of INENC block.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.addr_defines.all;
use work.slow_defines.all;

entity inenc_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Encoder I/O Pads
    A_IN                : in  std_logic_vector(ENC_NUM-1 downto 0);
    B_IN                : in  std_logic_vector(ENC_NUM-1 downto 0);
    Z_IN                : in  std_logic_vector(ENC_NUM-1 downto 0);
    CLK_OUT             : out std_logic_vector(ENC_NUM-1 downto 0);
    DATA_IN             : in  std_logic_vector(ENC_NUM-1 downto 0);
    CLK_IN              : in  std_logic_vector(ENC_NUM-1 downto 0);
    CONN_OUT            : out std_logic_vector(ENC_NUM-1 downto 0);
    -- Signals passed to internal bus
    a_int_o             : out std_logic_vector(ENC_NUM-1 downto 0);
    b_int_o             : out std_logic_vector(ENC_NUM-1 downto 0);
    z_int_o             : out std_logic_vector(ENC_NUM-1 downto 0);
    data_int_o          : out std_logic_vector(ENC_NUM-1 downto 0);
    -- Block Input and Outputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    DCARD_MODE          : in  std32_array(ENC_NUM-1 downto 0);
    PROTOCOL            : out std3_array(ENC_NUM-1 downto 0);
    posn_o              : out std32_array(ENC_NUM-1 downto 0);
    slow_tlp_o          : out slow_packet
);
end inenc_top;

architecture rtl of inenc_top is

signal read_strobe      : std_logic_vector(ENC_NUM-1 downto 0);
signal read_data        : std32_array(ENC_NUM-1 downto 0);
signal write_strobe     : std_logic_vector(ENC_NUM-1 downto 0);
signal posn             : std32_array(ENC_NUM-1 downto 0);
signal read_ack         : std_logic_vector(ENC_NUM-1 downto 0);
signal blk_addr         : natural range 0 to (2**(PAGE_AW-BLK_AW)-1);
signal write_address    : natural range 0 to (2**BLK_AW - 1);

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';
read_ack_o <= or_reduce(read_ack);

-- Multiplex read data out from multiple instantiations
read_data_o <= read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

-- Used for Slow output signal
write_address <= to_integer(unsigned(write_address_i(BLK_AW-1 downto 0)));
blk_addr <= to_integer(unsigned(write_address_i(PAGE_AW-1 downto BLK_AW)));

-- Outputs
posn_o <= posn;

-- Loopbacks onto system bus
a_int_o <= A_IN;
b_int_o <= B_IN;
z_int_o <= Z_IN;
data_int_o <= DATA_IN;

-- Slow Registers

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
            -- INENC PROTOCOL Slow Registers
            if (write_strobe_i = '1') then
                if (write_address = INENC_PROTOCOL_addr) then
                    slow_tlp_o.strobe <= '1';
                    slow_tlp_o.data <= write_data_i;
                    slow_tlp_o.address <= INPROT_ADDR_LIST(blk_addr);
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
-- Instantiate INENC Blocks :
--  There are ENC_NUM amount of encoders on the board
--
INENC_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

-- Sub-module address decoding
read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;

inenc_block_inst : entity work.inenc_block
port map (

    clk_i               => clk_i,
    reset_i             => reset_i,

    read_strobe_i       => read_strobe(I),
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data(I),
    read_ack_o          => read_ack(I),

    write_strobe_i      => write_strobe(I),
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,

    A_IN                => A_IN(I),
    B_IN                => B_IN(I),
    Z_IN                => Z_IN(I),
    CLK_OUT             => CLK_OUT(I),
    DATA_IN             => DATA_IN(I),
    CLK_IN              => CLK_IN(I),
    CONN_OUT            => CONN_OUT(I),

    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    DCARD_MODE          => DCARD_MODE(I),
    PROTOCOL            => PROTOCOL(I),
    posn_o              => posn(I)
);

END GENERATE;

end rtl;
