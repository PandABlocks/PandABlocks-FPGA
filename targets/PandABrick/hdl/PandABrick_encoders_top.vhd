library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.addr_defines.all;

entity pandabrick_encoders_top is
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
    
    OUTENC_CONN_OUT_o       : out std_logic_vector(ENC_NUM-1 downto 0);
    INENC_CONN_OUT_o        : out std_logic_vector(ENC_NUM-1 downto 0);
    
    -- Encoder I/O Pads
    pins_ENC_A_in           : in  std_logic_vector(ENC_NUM-1 downto 0);
    pins_ENC_B_in           : in  std_logic_vector(ENC_NUM-1 downto 0);
    pins_ENC_Z_in           : in  std_logic_vector(ENC_NUM-1 downto 0);
    pins_ENC_A_out          : out std_logic_vector(ENC_NUM-1 downto 0);
    pins_ENC_B_out          : out std_logic_vector(ENC_NUM-1 downto 0);
    pins_ENC_Z_out          : out std_logic_vector(ENC_NUM-1 downto 0);
    
    pins_PMAC_SCLK_RX       : in std_logic_vector(ENC_NUM-1 downto 0);
    pins_ENC_SDA_RX         : in std_logic_vector(ENC_NUM-1 downto 0);
    pins_PMAC_SDA_RX        : in std_logic_vector(ENC_NUM-1 downto 0);
    pins_ENC_SCLK_RX        : in std_logic_vector(ENC_NUM-1 downto 0);
	
    pins_ENC_SCLK_TX        : out std_logic_vector(ENC_NUM-1 downto 0);
    pins_ENC_SDA_TX         : out std_logic_vector(ENC_NUM-1 downto 0);
    pins_ENC_SDA_TX_EN      : out std_logic_vector(ENC_NUM-1 downto 0);
    pins_PMAC_SDA_TX        : out std_logic_vector(ENC_NUM-1 downto 0);
    pins_PMAC_SDA_TX_EN     : out std_logic_vector(ENC_NUM-1 downto 0);
    

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

    OUTENC_PROTOCOL_o       : out std32_array(ENC_NUM-1 downto 0);
    OUTENC_PROTOCOL_WSTB_o  : out std_logic_vector(ENC_NUM-1 downto 0);
    INENC_PROTOCOL_o        : out std32_array(ENC_NUM-1 downto 0);
    INENC_PROTOCOL_WSTB_o   : out std_logic_vector(ENC_NUM-1 downto 0)
);
end pandabrick_encoders_top;

architecture rtl of pandabrick_encoders_top is

signal OUTENC_read_strobe       : std_logic_vector(ENC_NUM-1 downto 0);
signal OUTENC_read_data         : std32_array(ENC_NUM-1 downto 0);
signal OUTENC_write_strobe      : std_logic_vector(ENC_NUM-1 downto 0);
signal OUTENC_read_ack          : std_logic_vector(ENC_NUM-1 downto 0);

signal INENC_read_strobe        : std_logic_vector(ENC_NUM-1 downto 0);
signal INENC_read_data          : std32_array(ENC_NUM-1 downto 0);
signal INENC_write_strobe       : std_logic_vector(ENC_NUM-1 downto 0);
signal posn                     : std32_array(ENC_NUM-1 downto 0);
signal INENC_read_ack           : std_logic_vector(ENC_NUM-1 downto 0);

begin

-- Acknowledgement to AXI Lite interface
OUTENC_write_ack_o <= '1';
OUTENC_read_ack_o <= or_reduce(OUTENC_read_ack);

-- Multiplex read data out from multiple instantiations
OUTENC_read_data_o <= OUTENC_read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

-- Acknowledgement to AXI Lite interface
INENC_write_ack_o <= '1';
INENC_read_ack_o <= or_reduce(INENC_read_ack);

-- Multiplex read data out from multiple instantiations
INENC_read_data_o <= INENC_read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

-- Outputs
posn_o <= posn;

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

encoders_block_inst : entity work.pandabrick_encoders_block
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

    OUTENC_PROTOCOL_o       => OUTENC_PROTOCOL_o(I),
    OUTENC_PROTOCOL_WSTB_o  => OUTENC_PROTOCOL_WSTB_o(I),
    INENC_PROTOCOL_o        => INENC_PROTOCOL_o(I),
    INENC_PROTOCOL_WSTB_o   => INENC_PROTOCOL_WSTB_o(I),

    pin_ENC_A_in            => pins_ENC_A_in(I),
    pin_ENC_B_in            => pins_ENC_B_in(I),
    pin_ENC_Z_in            => pins_ENC_Z_in(I),
    pin_ENC_A_out           => pins_ENC_A_out(I),
    pin_ENC_B_out           => pins_ENC_B_out(I),
    pin_ENC_Z_out           => pins_ENC_Z_out(I),
    
    pin_PMAC_SCLK_RX        => pins_PMAC_SCLK_RX(I),
    pin_ENC_SDA_RX          => pins_ENC_SDA_RX(I),
    pin_PMAC_SDA_RX         => pins_PMAC_SDA_RX(I),
    pin_ENC_SCLK_RX         => pins_ENC_SCLK_RX(I),
	
    pin_ENC_SCLK_TX         => pins_ENC_SCLK_TX(I),
    pin_ENC_SDA_TX          => pins_ENC_SDA_TX(I),
    pin_ENC_SDA_TX_EN       => pins_ENC_SDA_TX_EN(I),
    pin_PMAC_SDA_TX         => pins_PMAC_SDA_TX(I),
    pin_PMAC_SDA_TX_EN      => pins_PMAC_SDA_TX_EN(I),
   

    -- Position Field interface
    DCARD_MODE_i            => DCARD_MODE_i(I),
    bit_bus_i               => bit_bus_i,
    pos_bus_i               => pos_bus_i,
    posn_o                  => posn(I)
    );


END GENERATE;

end rtl;
