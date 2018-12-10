--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Instantiates Control and Status register interface, and
--                core squencer IP
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity sequencer_block is
port (
    -- Clock and Reset
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
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    -- Output sequencer
    outa_o              : out std_logic;
    outb_o              : out std_logic;
    outc_o              : out std_logic;
    outd_o              : out std_logic;
    oute_o              : out std_logic;
    outf_o              : out std_logic;
    active_o            : out std_logic
);
end sequencer_block;

architecture rtl of sequencer_block is

signal ENABLE_VAL        : std_logic_vector(31 downto 0);
signal INPA_VAL          : std_logic_vector(31 downto 0);
signal INPB_VAL          : std_logic_vector(31 downto 0);
signal INPC_VAL          : std_logic_vector(31 downto 0);
signal INPD_VAL          : std_logic_vector(31 downto 0);

signal PRESCALE          : std_logic_vector(31 downto 0);
signal TABLE_START       : std_logic;
signal TABLE_DATA        : std_logic_vector(31 downto 0);
signal TABLE_WSTB        : std_logic;
signal REPEATS           : std_logic_vector(31 downto 0);   
signal TABLE_LENGTH      : std_logic_vector(31 downto 0);
signal TABLE_LENGTH_WSTB : std_logic;
signal TABLE_LINE        : std_logic_vector(31 downto 0);
signal LINE_REPEAT       : std_logic_vector(31 downto 0);
signal TABLE_REPEAT      : std_logic_vector(31 downto 0);
signal STATE             : std_logic_vector(31 downto 0);
signal state_o           : std_logic_vector(2 downto 0);   

signal enable            : std_logic;
signal bita              : std_logic;
signal bitb              : std_logic;
signal bitc              : std_logic;
signal posa              : std_logic_vector(31 downto 0);
signal posb              : std_logic_vector(31 downto 0);
signal posc              : std_logic_vector(31 downto 0);

begin

STATE(2 downto 0) <= state_o;
STATE(31 downto 3) <= (others => '0');

--------------------------------------------------------------------------
-- Control System Interface
--------------------------------------------------------------------------
seq_ctrl : entity work.seq_ctrl
port map (
    clk_i               => clk_i,                           
    reset_i             => reset_i,                             
    sysbus_i            => sysbus_i,                        
    posbus_i            => posbus_i,     
    enable_o            => enable,                              
    bita_o              => bita,                            
    bitb_o              => bitb,                                
    bitc_o              => bitc,                            
    posa_o              => posa,                              
    posb_o              => posb,                            
    posc_o              => posc,                            

    read_strobe_i       => read_strobe_i,                   
    read_address_i      => read_address_i,                      
    read_data_o         => read_data_o,                     
    read_ack_o          => read_ack_o,                      

    write_strobe_i      => write_strobe_i,                  
    write_address_i     => write_address_i,                     
    write_data_i        => write_data_i,                        
    write_ack_o         => write_ack_o,                     

    PRESCALE            => PRESCALE,                        
    PRESCALE_WSTB       => open,
    REPEATS             => REPEATS,                     
    REPEATS_WSTB        => open,
    TABLE_LINE          => TABLE_LINE,                                           
    LINE_REPEAT         => LINE_REPEAT,                         
    TABLE_REPEAT        => TABLE_REPEAT,                    
    TABLE_START         => open,
    TABLE_START_WSTB    => TABLE_START,                     
    TABLE_DATA          => TABLE_DATA,                      
    TABLE_DATA_WSTB     => TABLE_WSTB,                      
    TABLE_LENGTH        => TABLE_LENGTH,                    
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB,               
    STATE               => STATE
);

--------------------------------------------------------------------------
-- Sequence Block Core Instantiation
--------------------------------------------------------------------------
sequencer : entity work.sequencer
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    enable_i            => enable,
    
    bita_i              => bita, 
    bitb_i              => bitb,
    bitc_i              => bitc,
    
    posa_i              => posa,
    posb_i              => posb,
    posc_i              => posc,    
    
    outa_o              => outa_o,
    outb_o              => outb_o,
    outc_o              => outc_o,
    outd_o              => outd_o,
    oute_o              => oute_o,
    outf_o              => outf_o,
    active_o            => active_o,

    PRESCALE            => PRESCALE,
    TABLE_START         => TABLE_START,
    TABLE_DATA          => TABLE_DATA,
    TABLE_WSTB          => TABLE_WSTB,
    REPEATS             => REPEATS,
    TABLE_LENGTH        => TABLE_LENGTH(15 downto 0),
    TABLE_LENGTH_WSTB   => TABLE_LENGTH_WSTB,

    table_line_o        => TABLE_LINE,
    line_repeat_o       => LINE_REPEAT,
    table_repeat_o      => TABLE_REPEAT,
    state_o             => state_o
);

end rtl;

