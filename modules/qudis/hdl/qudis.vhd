----------------------------------------------------------------------------------
--
-- 3-Axis quDIS Interferometer decoder 
--
-- G.Francis, August 2024.
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;


entity qudis is
    Port ( 
    
        clk_i           : in  std_logic;
        reset_i         : in  std_logic;
        bit_bus_i        : in  bit_bus_t;
        pos_bus_i        : in  pos_bus_t;

        -- HSSL Hardware Interface
        hssl_clk_pins   : in std_logic_vector(3 downto 1);
        hssl_data_pins  : in std_logic_vector(3 downto 1);
        
        -- Output Positions
        pos_1_o         : out std_logic_vector(31 downto 0);
        pos_2_o         : out std_logic_vector(31 downto 0);
        pos_3_o         : out std_logic_vector(31 downto 0);

        -- Internal read interface
        read_strobe_i   : in  std_logic;
        read_address_i  : in  std_logic_vector(BLK_AW-1 downto 0);
        read_data_o     : out std_logic_vector(31 downto 0);
        read_ack_o      : out std_logic;

        -- Internal write interface
        write_strobe_i  : in  std_logic;
        write_address_i : in  std_logic_vector(BLK_AW-1 downto 0);
        write_data_i    : in  std_logic_vector(31 downto 0);
        write_ack_o     : out std_logic

	);
end qudis;


architecture arch_qudis of qudis is

signal hssl_positions       : std32_array(3 downto 1);
signal health_bits          : std_logic_vector(3 downto 1);
signal health               : std_logic_vector(31 downto 0);

begin


-- Generate the Decoders...
GEN_DECODERS:
for axis_num in 1 to 3 generate

   hssl_axis_decoder_inst : entity work.hssl_axis_decoder
   port map (
       clk_i        => clk_i,
       clk_bit_i    => hssl_clk_pins(axis_num),
       data_bit_i   => hssl_data_pins(axis_num),
       hssl_val_o   => hssl_positions(axis_num),
       health_bit_o => health_bits(axis_num)
   );
    
end generate GEN_DECODERS;


-- Output positions...
pos_1_o <= hssl_positions(1);
pos_2_o <= hssl_positions(2);
pos_3_o <= hssl_positions(3);


-- Health word (bits are 1 for good)...
health(0) <= not health_bits(1);
health(1) <= not health_bits(2);
health(2) <= not health_bits(3);
health(31 downto 3) <= ( others => '0' );



qudis_ctrl_inst : entity work.qudis_ctrl
    port map (
        -- Clock and Reset
        clk_i               => clk_i,
        reset_i             => reset_i,
        bit_bus_i           => bit_bus_i,
        pos_bus_i           => pos_bus_i,

        -- Block Parameters
        HEALTH              => health,

        -- Memory Bus Interface
        read_strobe_i       => read_strobe_i,
        read_address_i      => read_address_i,
        read_data_o         => read_data_o,
        read_ack_o          => read_ack_o,

        write_strobe_i      => write_strobe_i,
        write_address_i     => write_address_i,
        write_data_i        => write_data_i,
        write_ack_o         => write_ack_o
        );


end arch_qudis;
