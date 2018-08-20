--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Position compare control and core logic
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity pcomp_block is
port (
    -- Clock and Reset.
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Block Input and Outputs.
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    act_o               : out std_logic;
    out_o               : out std_logic;
    -- DMA Interface.
    dma_req_o           : out std_logic;
    dma_ack_i           : in  std_logic;
    dma_done_i          : in  std_logic;
    dma_addr_o          : out std_logic_vector(31 downto 0);
    dma_len_o           : out std_logic_vector(7 downto 0);
    dma_data_i          : in  std_logic_vector(31 downto 0);
    dma_valid_i         : in  std_logic
);
end pcomp_block;

architecture rtl of pcomp_block is


signal PRE_START            : std_logic_vector(31 downto 0);    
signal START                : std_logic_vector(31 downto 0);
signal STEP                 : std_logic_vector(31 downto 0);
signal WIDTH                : std_logic_vector(31 downto 0);
signal PULSES               : std_logic_vector(31 downto 0);
signal RELATIVE             : std_logic_vector(31 downto 0);
signal DIR                  : std_logic_vector(31 downto 0);
signal health_o             : std_logic_vector(1 downto 0);
signal state_o              : std_logic_vector(2 downto 0);
signal health               : std_logic_vector(31 downto 0);
signal state                : std_logic_vector(31 downto 0);    
signal produced_o           : std_logic_vector(31 downto 0);               

signal pcomp_act            : std_logic;
signal pcomp_out            : std_logic;

signal enable               : std_logic;
signal posn                 : std_logic_vector(31 downto 0);

begin

--
-- Control System Interface
--
pcomp_ctrl : entity work.pcomp_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    enable_o            => enable,
    inp_o               => posn,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    PRE_START           => PRE_START,
    PRE_START_WSTB      => open,
    START               => START,
    START_WSTB          => open,
    STEP                => STEP,
    STEP_WSTB           => open,
    WIDTH               => WIDTH,
    WIDTH_WSTB          => open,
    PULSES              => PULSES,
    PULSES_WSTB         => open,
    RELATIVE            => RELATIVE,
    RELATIVE_WSTB       => open,
    DIR                 => DIR,
    DIR_WSTB            => open,
    HEALTH              => health,
    PRODUCED            => produced_o,
    STATE               => state
);

health(31 downto 2) <= (others => '0');
health(1 downto 0) <= health_o; 

state(31 downto 3) <= (others => '0');
state(2 downto 0) <= state_o;

--
-- Position Compare IP
--
pcomp_inst : entity work.pcomp
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    posn_i              => posn,

    PRE_START           => PRE_START,
    START               => START,
    STEP                => STEP,
    WIDTH               => WIDTH,
    PULSES              => PULSES,
    RELATIVE            => RELATIVE(0),
    DIR                 => DIR(1 downto 0),
    health_o            => health_o,
    produced_o          => produced_o,
    state_o             => state_o,

    act_o               => pcomp_act,
    out_o               => pcomp_out
);

act_o <= pcomp_act;
out_o <= pcomp_out;

end rtl;

