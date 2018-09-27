--------------------------------------------------------------------------------
-- Blocks top-level interface
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;

entity soft_blocks is
generic (
    SIM             : string := "FALSE"
);
port (
    -- Global clock and reset from panda_ps
    FCLK_CLK0       : in    std_logic;
    FCLK_RESET0     : in    std_logic;
    -- Configuration and Status Interface Block
    read_strobe     : in    std_logic_vector(MOD_COUNT-1 downto 0);
    read_address    : in    std_logic_vector(PAGE_AW-1 downto 0);
    read_data       : out   std32_array(MOD_COUNT-1 downto 0);
    read_ack        : out   std_logic_vector(MOD_COUNT-1 downto 0) := (others => '1');
    write_strobe    : in    std_logic_vector(MOD_COUNT-1 downto 0);
    write_address   : in    std_logic_vector(PAGE_AW-1 downto 0);
    write_data      : in    std_logic_vector(31 downto 0);
    write_ack       : out   std_logic_vector(MOD_COUNT-1 downto 0) := (others => '1');
    -- Bus Outputs
    bit_bus         : inout sysbus_t;
    posbus          : inout posbus_t;
    -- PCOMP and PGEN Block
    rdma_req        : out   std_logic_vector(5 downto 0);
    rdma_ack        : in    std_logic_vector(5 downto 0);
    rdma_done       : in    std_logic;
    rdma_addr       : out   std32_array(5 downto 0);
    rdma_len        : out   std8_array(5 downto 0);
    rdma_data       : in    std_logic_vector(31 downto 0);
    rdma_valid      : in    std_logic_vector(5 downto 0);
    --
    FMC             : inout FMC_record;
    SFP1            : inout SFP_record;
    SFP2            : inout SFP_record;
    SFP3            : inout SFP_record
);
end soft_blocks;

architecture rtl of soft_blocks is

-- Definitions below need to be automatically populated by Jinja
-- Only for soft blocks though!
-- "NUM" paramters resolved here and inherited in blocks by generics

-- Functional Address Space Chip Selects

constant lut_CS : natural := 10;

-- Block instantiation

constant lut_NUM : natural := 8;

begin

--------------------------------------------------------------------------------
-- lut - Lookup table
--------------------------------------------------------------------------------
lut_inst : entity work.lut_wrapper
generic map (NUM => lut_NUM)
port map (

    reset_i             => FCLK_REST0,
    
    read_strobe_i       => read_strobe(lut_CS),
    read_address_i      => read_address,
    read_data_o         => read_data(lut_CS),
    read_ack_o          => read_ack(lut_CS),

    write_strobe_i      => write_strobe(lut_CS),
    write_address_i     => write_address,
    write_data_i        => write_data,
    write_ack_o         => write_ack(lut_CS),
    
    bit_bus_i           => bit_bus,
    
    OUT_o           => bit_bus (39 downto 32),
    
    clk_i               => FCLK_CLK0
);


end rtl;
