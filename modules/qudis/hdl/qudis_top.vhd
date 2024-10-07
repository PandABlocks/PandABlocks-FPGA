----------------------------------------------------------------------------------
--
-- 6-Axis quDIS Interferometer (two 3-Axis blocks) 
--
-- G.Francis, August 2024.
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;


entity qudis_top is
    generic (
        QUDIS_NUM : natural
    );
    Port ( 
    
        clk_i           : in  std_logic;
        reset_i         : in  std_logic;
        bit_bus_i       : in  bit_bus_t;
        pos_bus_i       : in  pos_bus_t;

        -- HSSL Hardware Interface
        hssl_clk_pins   : in std_logic_vector(6 downto 1);
        hssl_data_pins  : in std_logic_vector(6 downto 1);

        -- Output Positions
        pos_1_o         : out std_logic_vector(31 downto 0);
        pos_2_o         : out std_logic_vector(31 downto 0);
        pos_3_o         : out std_logic_vector(31 downto 0);
        pos_4_o         : out std_logic_vector(31 downto 0);
        pos_5_o         : out std_logic_vector(31 downto 0);
        pos_6_o         : out std_logic_vector(31 downto 0);

        -- Internal read interface
        read_strobe_i   : in  std_logic;
        read_address_i  : in  std_logic_vector(PAGE_AW-1 downto 0);
        read_data_o     : out std_logic_vector(31 downto 0);
        read_ack_o      : out std_logic;

        -- Internal write interface
        write_strobe_i  : in  std_logic;
        write_address_i : in  std_logic_vector(PAGE_AW-1 downto 0);
        write_data_i    : in  std_logic_vector(31 downto 0);
        write_ack_o     : out std_logic

	);
end qudis_top;

architecture arch_qudis_top of qudis_top is

    signal QUDIS_read_strobe    : std_logic_vector(QUDIS_NUM-1 downto 0);
    signal QUDIS_read_data      : std32_array(QUDIS_NUM-1 downto 0);
    signal QUDIS_write_strobe   : std_logic_vector(QUDIS_NUM-1 downto 0);
    signal QUDIS_read_ack       : std_logic_vector(QUDIS_NUM-1 downto 0);
    signal QUDIS_write_ack      : std_logic_vector(QUDIS_NUM-1 downto 0);

    signal pos_1                : std32_array(QUDIS_NUM-1 downto 0);
    signal pos_2                : std32_array(QUDIS_NUM-1 downto 0);
    signal pos_3                : std32_array(QUDIS_NUM-1 downto 0);

    type input_pins is array (1 downto 0) of std_logic_vector(3 downto 1);
    signal clk_pins             : input_pins;
    signal data_pins            : input_pins;

begin
    
    -- Acknowledgement to AXI Lite interface
    read_ack_o  <= or_reduce(QUDIS_read_ack);
    write_ack_o <= or_reduce(QUDIS_write_ack);
    
    -- Multiplex read data out from multiple instantiations
    read_data_o <= QUDIS_read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));
    
    -- Inputs
    clk_pins(0)  <= hssl_clk_pins(3 downto 1);
    data_pins(0) <= hssl_data_pins(3 downto 1);
    more_pins: if QUDIS_NUM=2 generate
        clk_pins(1)  <= hssl_clk_pins(6 downto 4);
        data_pins(1) <= hssl_data_pins(6 downto 4);
    end generate;

    -- Outputs
    pos_1_o  <= pos_1(0);
    pos_2_o  <= pos_2(0);
    pos_3_o  <= pos_3(0);

    one_qudis:
    if QUDIS_NUM=1 generate
        pos_4_o  <= (others => '0');
        pos_5_o  <= (others => '0');
        pos_6_o  <= (others => '0');
    end generate one_qudis;
    
    two_qudis:
    if QUDIS_NUM=2 generate
        pos_4_o  <= pos_1(1);
        pos_5_o  <= pos_2(1);
        pos_6_o  <= pos_3(1);
    end generate two_qudis;


    -- Generate 3-axis decoders
    QUDIS_GEN : FOR I IN 0 TO QUDIS_NUM-1 GENERATE

        -- Sub-module address decoding
        QUDIS_read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
        QUDIS_write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;


        -- 3-axis decoders
        quDIS_inst : entity work.qudis
        port map (
            clk_i           => clk_i,
            reset_i         => reset_i,
            bit_bus_i       => bit_bus_i,
            pos_bus_i       => pos_bus_i,

            hssl_clk_pins   => clk_pins(I),
            hssl_data_pins  => data_pins(I),

            pos_1_o         => pos_1(I),
            pos_2_o         => pos_2(I),
            pos_3_o         => pos_3(I),

            read_strobe_i   => QUDIS_read_strobe(I),
            read_address_i  => read_address_i(BLK_AW-1 downto 0),
            read_data_o     => QUDIS_read_data(I),
            read_ack_o      => QUDIS_read_ack(I),

            write_strobe_i  => QUDIS_write_strobe(I),
            write_address_i => (others => '0'),
            write_data_i    => (others => '0'),
            write_ack_o     => QUDIS_write_ack(I)
        );

    END GENERATE QUDIS_GEN;

end arch_qudis_top;