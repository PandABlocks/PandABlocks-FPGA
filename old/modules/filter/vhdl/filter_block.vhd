--------------------------------------------------------------------------------
--  File:       filter_block.vhd
--  Desc:       Performs the following funcions 
--                      1. The difference of two selected data samples
--                      2. Divider value of a number of samples 
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity filter_block is
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
    -- Outputs 
    out_o               : out std_logic_vector(31 downto 0);  
    ready_o             : out std_logic    
    
);
end filter_block;

architecture rtl of filter_block is

signal MODE     : std_logic_vector(31 downto 0);
signal ERR      : std_logic_vector(31 downto 0); 
signal trig     : std_logic; 
signal enable   : std_logic;
signal inp      : std_logic_vector(31 downto 0);

begin

--
-- Control System Interface
--
filter_ctrl : entity work.filter_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    MODE                => MODE,
    MODE_WSTB           => open,
    ERR                 => ERR,
    trig_o              => trig,
    enable_o            => enable,
    inp_o               => inp
    
);



-- LUT Block Core Instantiation
filter : entity work.filter
port map (
    clk_i           => clk_i,
    mode_i          => MODE(1 downto 0),
    trig_i          => trig,
    inp_i           => inp, 
    enable_i        => enable,
    out_o           => out_o,
    ready_o         => ready_o,
    err_o           => ERR(1 downto 0)  
);


end rtl;

