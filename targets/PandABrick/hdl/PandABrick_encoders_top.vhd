library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.addr_defines.all;

entity pandabrick_encoders_top is
generic (
    ENC_NUM : natural
);
port (
    -- Clock and Reset
    clk_i                   : in  std_logic;
    reset_i                 : in  std_logic;
    -- Memory Bus Interface
    PMACENC_read_strobe_i   : in  std_logic;
    PMACENC_read_data_o     : out std_logic_vector(31 downto 0);
    PMACENC_read_ack_o      : out std_logic;

    PMACENC_write_strobe_i  : in  std_logic;
    PMACENC_write_ack_o     : out std_logic;

    INCENC_read_strobe_i    : in  std_logic;
    INCENC_read_data_o      : out std_logic_vector(31 downto 0);
    INCENC_read_ack_o       : out std_logic;

    INCENC_write_strobe_i   : in  std_logic;
    INCENC_write_ack_o      : out std_logic;

    ABSENC_read_strobe_i    : in  std_logic;
    ABSENC_read_data_o      : out std_logic_vector(31 downto 0);
    ABSENC_read_ack_o       : out std_logic;

    ABSENC_write_strobe_i   : in  std_logic;
    ABSENC_write_ack_o      : out std_logic;

    read_address_i          : in  std_logic_vector(PAGE_AW-1 downto 0);

    write_address_i         : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i            : in  std_logic_vector(31 downto 0);
    
    PMACENC_CONN_OUT_o      : out std_logic_vector(ENC_NUM-1 downto 0);
    INCENC_CONN_OUT_o       : out std_logic_vector(ENC_NUM-1 downto 0);
    ABSENC_CONN_OUT_o       : out std_logic_vector(ENC_NUM-1 downto 0);
    
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
    -- incenc_a_o              : out std_logic_vector(ENC_NUM-1 downto 0);
    -- incenc_b_o              : out std_logic_vector(ENC_NUM-1 downto 0);
    -- incenc_z_o              : out std_logic_vector(ENC_NUM-1 downto 0);
    absenc_data_o           : out std_logic_vector(ENC_NUM-1 downto 0);
    -- Block Input and Outputs
    bit_bus_i               : in  bit_bus_t;
    pos_bus_i               : in  pos_bus_t;
    -- DCARD_MODE_i            : in  std32_array(ENC_NUM-1 downto 0);
    posn_o                  : out std32_array(ENC_NUM-1 downto 0);
    abs_posn_o                  : out std32_array(ENC_NUM-1 downto 0);

    UVWT_o                  : out std_logic_vector(ENC_NUM-1 downto 0);

    PMACENC_PROTOCOL_o      : out std32_array(ENC_NUM-1 downto 0);
    PMACENC_PROTOCOL_WSTB_o : out std_logic_vector(ENC_NUM-1 downto 0);
    INCENC_PROTOCOL_o       : out std32_array(ENC_NUM-1 downto 0);
    INCENC_PROTOCOL_WSTB_o  : out std_logic_vector(ENC_NUM-1 downto 0);
    ABSENC_PROTOCOL_o       : out std32_array(ENC_NUM-1 downto 0);
    ABSENC_PROTOCOL_WSTB_o  : out std_logic_vector(ENC_NUM-1 downto 0)
);
end pandabrick_encoders_top;

architecture rtl of pandabrick_encoders_top is

signal PMACENC_read_strobe      : std_logic_vector(ENC_NUM-1 downto 0);
signal PMACENC_read_data        : std32_array(ENC_NUM-1 downto 0);
signal PMACENC_write_strobe     : std_logic_vector(ENC_NUM-1 downto 0);
signal PMACENC_read_ack         : std_logic_vector(ENC_NUM-1 downto 0);

signal INCENC_read_strobe       : std_logic_vector(ENC_NUM-1 downto 0);
signal INCENC_read_data         : std32_array(ENC_NUM-1 downto 0);
signal INCENC_write_strobe      : std_logic_vector(ENC_NUM-1 downto 0);
signal posn                     : std32_array(ENC_NUM-1 downto 0);
signal INCENC_read_ack          : std_logic_vector(ENC_NUM-1 downto 0);

signal ABSENC_read_strobe       : std_logic_vector(ENC_NUM-1 downto 0);
signal ABSENC_read_data         : std32_array(ENC_NUM-1 downto 0);
signal ABSENC_write_strobe      : std_logic_vector(ENC_NUM-1 downto 0);
signal abs_posn                 : std32_array(ENC_NUM-1 downto 0);
signal ABSENC_read_ack          : std_logic_vector(ENC_NUM-1 downto 0);

begin

-- Acknowledgement to AXI Lite interface
PMACENC_write_ack_o <= '1';
PMACENC_read_ack_o <= or_reduce(PMACENC_read_ack);

-- Multiplex read data out from multiple instantiations
PMACENC_read_data_o <= PMACENC_read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

-- Acknowledgement to AXI Lite interface
INCENC_write_ack_o <= '1';
INCENC_read_ack_o <= or_reduce(INCENC_read_ack);

-- Multiplex read data out from multiple instantiations
INCENC_read_data_o <= INCENC_read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

-- Acknowledgement to AXI Lite interface
ABSENC_write_ack_o <= '1';
ABSENC_read_ack_o <= or_reduce(ABSENC_read_ack);

-- Multiplex read data out from multiple instantiations
ABSENC_read_data_o <= ABSENC_read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));


-- Outputs
posn_o <= posn;
abs_posn_o <= abs_posn;

--
-- Instantiate ENCOUT Blocks :
--  There are ENC_NUM amount of encoders on the board
--
ENC_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

-- Sub-module address decoding
PMACENC_read_strobe(I) <= compute_block_strobe(read_address_i, I) and PMACENC_read_strobe_i;
PMACENC_write_strobe(I) <= compute_block_strobe(write_address_i, I) and PMACENC_write_strobe_i;

INCENC_read_strobe(I) <= compute_block_strobe(read_address_i, I) and INCENC_read_strobe_i;
INCENC_write_strobe(I) <= compute_block_strobe(write_address_i, I) and INCENC_write_strobe_i;

ABSENC_read_strobe(I) <= compute_block_strobe(read_address_i, I) and ABSENC_read_strobe_i;
ABSENC_write_strobe(I) <= compute_block_strobe(write_address_i, I) and ABSENC_write_strobe_i;

encoders_block_inst : entity work.pandabrick_encoders_block
port map (
    -- Clock and Reset
    clk_i                   => clk_i,
    reset_i                 => reset_i,
    -- Memory Bus Interface
    PMACENC_read_strobe_i   => PMACENC_read_strobe(I),
    PMACENC_read_data_o     => PMACENC_read_data(I),
    PMACENC_read_ack_o      => PMACENC_read_ack(I),

    PMACENC_write_strobe_i  => PMACENC_write_strobe(I),
    PMACENC_write_ack_o     => open,

    INCENC_read_strobe_i    => INCENC_read_strobe(I),
    INCENC_read_data_o      => INCENC_read_data(I),
    INCENC_read_ack_o       => INCENC_read_ack(I),

    INCENC_write_strobe_i   => INCENC_write_strobe(I),
    INCENC_write_ack_o      => open,

    ABSENC_read_strobe_i    => ABSENC_read_strobe(I),
    ABSENC_read_data_o      => ABSENC_read_data(I),
    ABSENC_read_ack_o       => ABSENC_read_ack(I),

    ABSENC_write_strobe_i   => ABSENC_write_strobe(I),
    ABSENC_write_ack_o      => open,

    read_address_i          => read_address_i(BLK_AW-1 downto 0),

    write_address_i         => write_address_i(BLK_AW-1 downto 0),
    write_data_i            => write_data_i,
    -- Encoder I/O Pads
    PMACENC_CONN_OUT_o      => PMACENC_CONN_OUT_o(I),
    INCENC_CONN_OUT_o       => INCENC_CONN_OUT_o(I),
    ABSENC_CONN_OUT_o       => ABSENC_CONN_OUT_o(I),

    clk_int_o               => clk_int_o(I),
    -- incenc_a_o              => incenc_a_o(I),
    -- incenc_b_o              => incenc_b_o(I),
    -- incenc_z_o              => incenc_z_o(I),
    absenc_data_o           => absenc_data_o(I),

    PMACENC_PROTOCOL_o      => PMACENC_PROTOCOL_o(I),
    PMACENC_PROTOCOL_WSTB_o => PMACENC_PROTOCOL_WSTB_o(I),
    INCENC_PROTOCOL_o       => INCENC_PROTOCOL_o(I),
    INCENC_PROTOCOL_WSTB_o  => INCENC_PROTOCOL_WSTB_o(I),
    ABSENC_PROTOCOL_o       => ABSENC_PROTOCOL_o(I),
    ABSENC_PROTOCOL_WSTB_o  => ABSENC_PROTOCOL_WSTB_o(I),

    UVWT_o                  => UVWT_o(I),

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
    -- DCARD_MODE_i            => DCARD_MODE_i(I),
    bit_bus_i               => bit_bus_i,
    pos_bus_i               => pos_bus_i,
    posn_o                  => posn(I),
    abs_posn_o              => abs_posn(I)
    );


END GENERATE;

end rtl;
