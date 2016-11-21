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

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

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
    -- Block Outputs
    DCARD_MODE          : in  std32_array(ENC_NUM-1 downto 0);
    PROTOCOL            : out std3_array(ENC_NUM-1 downto 0);
    posn_o              : out std32_array(ENC_NUM-1 downto 0);
    posn_trans_o        : out std_logic_vector(ENC_NUM-1 downto 0)
);
end inenc_top;

architecture rtl of inenc_top is

signal read_strobe      : std_logic_vector(TTLOUT_NUM-1 downto 0);
signal read_data        : std32_array(TTLOUT_NUM-1 downto 0);
signal write_strobe     : std_logic_vector(TTLOUT_NUM-1 downto 0);
signal posn             : std32_array(ENC_NUM-1 downto 0);

component icon
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
end component;

component ila
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0));
end component;

signal CONTROL0 : STD_LOGIC_VECTOR(35 DOWNTO 0);
signal DATA     : STD_LOGIC_VECTOR(35 DOWNTO 0);
signal TRIG0    : STD_LOGIC_VECTOR(7 DOWNTO 0);

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY       => RD_ADDR2ACK
);

-- Multiplex read data out from multiple instantiations
read_data_o <= read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

-- Outputs
posn_o <= posn;

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
    read_ack_o          => open,

    write_strobe_i      => write_strobe(I),
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,

    a_i                 => A_IN(I),
    b_i                 => B_IN(I),
    z_i                 => Z_IN(I),
    clk_out_o           => CLK_OUT(I),
    data_in_i           => DATA_IN(I),
    clk_in_i            => CLK_IN(I),
    conn_o              => CONN_OUT(I),

    DCARD_MODE          => DCARD_MODE(I),
    PROTOCOL            => PROTOCOL(I),
    posn_o              => posn(I),
    posn_trans_o        => posn_trans_o(I)
);

END GENERATE;


--icon_name : icon
--  port map (
--    CONTROL0 => CONTROL0);
--
--ila_name : ila
--  port map (
--    CONTROL => CONTROL0,
--    CLK => clk_i,
--    DATA => DATA,
--    TRIG0 => TRIG0);
--
--
--TRIG0(0) <= CLK_IN(0);
--TRIG0(7 downto 1) <= (others => '0');
--
--DATA(31 downto 0) <= posn(0);
--DATA(32) <= CLK_IN(0);
--DATA(33) <= DATA_IN(0);
--DATA(35 downto 34) <= "00";

end rtl;

