library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;
use work.support.all;

entity encoders is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder inputs from Bitbus
    a_ext_i             : in  std_logic;
    b_ext_i             : in  std_logic;
    z_ext_i             : in  std_logic;

    data_ext_i          : in  std_logic;
    posn_i              : in  std_logic_vector(31 downto 0);
    enable_i            : in  std_logic;
    -- Encoder I/O Pads
    INENC_A_o          : out std_logic;
    INENC_B_o          : out std_logic;
    INENC_Z_o          : out std_logic;
    INENC_DATA_o       : out std_logic;
    --
    clk_out_ext_i       : in  std_logic;
    clk_int_o           : out std_logic;
    --
    Am0_pad_io          : inout std_logic;
    Bm0_pad_io          : inout std_logic;
    Zm0_pad_io          : inout std_logic;
    As0_pad_io          : inout std_logic;
    Bs0_pad_io          : inout std_logic;
    Zs0_pad_io          : inout std_logic;

    -- Block parameters
    GENERATOR_ERROR_i   : in  std_logic;
    OUTENC_PROTOCOL_i   : in  std_logic_vector(2 downto 0);
    OUTENC_ENCODING_i   : in  std_logic_vector(1 downto 0);
    OUTENC_BITS_i       : in  std_logic_vector(7 downto 0);
    QPERIOD_i           : in  std_logic_vector(31 downto 0);
    QPERIOD_WSTB_i      : in  std_logic;
    OUTENC_HEALTH_o     : out std_logic_vector(31 downto 0);
    QSTATE_o            : out std_logic_vector(31 downto 0);

    DCARD_MODE_i        : in  std_logic_vector(31 downto 0);
    INENC_PROTOCOL_i    : in  std_logic_vector(2 downto 0);
    INENC_ENCODING_i    : in  std_logic_vector(1 downto 0);
    CLK_SRC_i           : in  std_logic;
    CLK_PERIOD_i        : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD_i      : in  std_logic_vector(31 downto 0);
    INENC_BITS_i        : in  std_logic_vector(7 downto 0);
    LSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    MSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    SETP_i              : in  std_logic_vector(31 downto 0);
    SETP_WSTB_i         : in  std_logic;
    RST_ON_Z_i          : in  std_logic_vector(31 downto 0);
    STATUS_o            : out std_logic_vector(31 downto 0);
    INENC_HEALTH_o      : out std_logic_vector(31 downto 0);
    HOMED_o             : out std_logic_vector(31 downto 0);
    -- Block Outputs
    posn_o              : out std_logic_vector(31 downto 0)
);
end entity;


architecture rtl of encoders is
begin

-----------------------------INENC---------------------------------------------
--------------------------------------------------------------------------------

inenc_inst : entity work.inenc(rtl)
port map(
    clk_i            => clk_i,
    reset_i          => reset_i,
    posn_i           => posn_i,
    INENC_A_o        => INENC_A_o,  
    INENC_B_o        => INENC_B_o,
    INENC_Z_o        => INENC_Z_o,  
    INENC_DATA_o     => INENC_DATA_o,  
    --
    clk_out_ext_i    => clk_out_ext_i,  
    clk_int_o        => clk_int_o,   
    --
    Am0_pad_io       => Am0_pad_io,   
    Bm0_pad_io       => Bm0_pad_io,   
    Zm0_pad_io       => Zm0_pad_io,   
    As0_pad_io       => As0_pad_io,   
    Bs0_pad_io       => Bs0_pad_io,   
    Zs0_pad_io       => Zs0_pad_io,

    DCARD_MODE_i     => DCARD_MODE_i,

    INENC_PROTOCOL_i => INENC_PROTOCOL_i,  
    INENC_ENCODING_i => INENC_ENCODING_i,  
    CLK_SRC_i        => CLK_SRC_i,  
    CLK_PERIOD_i     => CLK_PERIOD_i,  
    FRAME_PERIOD_i   => FRAME_PERIOD_i,  
    INENC_BITS_i     => INENC_BITS_i, 
    LSB_DISCARD_i    => LSB_DISCARD_i,   
    MSB_DISCARD_i    => MSB_DISCARD_i,   
    SETP_i           => SETP_i,   
    SETP_WSTB_i      => SETP_WSTB_i,   
    RST_ON_Z_i       => RST_ON_Z_i,
    STATUS_o         => STATUS_o,
    INENC_HEALTH_o   => INENC_HEALTH_o,
    HOMED_o          => HOMED_o,

    posn_o           => posn_o
);

---------------------------------OUTENC------------------------------------
--------------------------------------------------------------------------

outenc_inst : entity work.outenc(rtl)
port map(
    clk_i             => clk_i,
    reset_i           => reset_i,
    -- Encoder inputs from Bitbus
    a_ext_i           => a_ext_i,
    b_ext_i           => b_ext_i,    
    z_ext_i           => z_ext_i,    

    data_ext_i        => data_ext_i,     
    
    -- Encoder I/O Pads
    posn_i            => posn_i,   
    enable_i          => enable_i,  

    As0_pad_io        => As0_pad_io,   
    Bs0_pad_io        => Bs0_pad_io,   
    Zs0_pad_io        => Zs0_pad_io,     
    -- Block inputs 
    GENERATOR_ERROR_i => GENERATOR_ERROR_i,  
    QPERIOD_i         => QPERIOD_i,   
    QPERIOD_WSTB_i    => QPERIOD_WSTB_i,   
    QSTATE_o          => QSTATE_o,   

    INENC_PROTOCOL_i  => INENC_PROTOCOL_i,   
    DCARD_MODE_i      => DCARD_MODE_i,   
    OUTENC_PROTOCOL_i => OUTENC_PROTOCOL_i,
    OUTENC_ENCODING_i => OUTENC_ENCODING_i,
    OUTENC_BITS_i     => OUTENC_BITS_i,
    OUTENC_HEALTH_o   => OUTENC_HEALTH_o   
);

end rtl;
