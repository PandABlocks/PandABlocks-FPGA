library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.top_defines.all;
use work.support.all;


entity encoders_tb is
end entity;


architecture rtl of encoders_tb is

signal clk              : std_logic := '0';
signal reset            : std_logic := '0';
signal posn_i           : std_logic_vector(31 downto 0);
signal enable           : std_logic;
signal INENC_A          : std_logic;
signal INENC_B          : std_logic;
signal INENC_Z          : std_logic;
signal INENC_DATA       : std_logic;
signal clk_int          : std_logic;
signal Am0_pad_io       : std_logic := '0';
signal Bm0_pad_io       : std_logic := '0';
signal Zm0_pad_io       : std_logic := '0';
signal As0_pad_io       : std_logic := '0';
signal Bs0_pad_io       : std_logic := '0';
signal Zs0_pad_io       : std_logic := '0';
signal GENERATOR_ERROR  : std_logic;
signal OUTENC_PROTOCOL  : std_logic_vector(2 downto 0);
signal OUTENC_BITS      : std_logic_vector(7 downto 0);
signal OUTENC_HEALTH    : std_logic_vector(31 downto 0);
signal QSTATE           : std_logic_vector(31 downto 0);
signal DCARD_MODE       : std_logic_vector(31 downto 0);
signal INENC_PROTOCOL   : std_logic_vector(2 downto 0);
signal CLK_SRC          : std_logic;
signal CLK_PERIOD       : std_logic_vector(31 downto 0);
signal FRAME_PERIOD     : std_logic_vector(31 downto 0);
signal INENC_BITS       : std_logic_vector(7 downto 0);
signal LSB_DISCARD      : std_logic_vector(4 downto 0);
signal MSB_DISCARD      : std_logic_vector(4 downto 0);
signal STATUS           : std_logic_vector(31 downto 0);
signal INENC_HEALTH     : std_logic_vector(31 downto 0);
signal HOMED            : std_logic_vector(31 downto 0);
signal posn_o           : std_logic_vector(31 downto 0);

signal m_link_up        : std_logic;
signal m_health         : std_logic_vector(31 downto 0);
signal ms_endat_sck     : std_logic;   ----
signal sm_endat_dat     : std_logic;   ----    
signal endat_dat        : std_logic;    
signal posn             : std_logic_vector(31 downto 0);
signal posn_valid       : std_logic;
signal endat_dato       : std_logic;
signal s_link_up        : std_logic;
signal s_health         : std_logic_vector(31 downto 0);
signal reset_i          : std_logic;

begin 

clk <= not clk after 4ns;


--Am0_pad_io <= '1'; -- DATA_IN
--Bm0_pad_io <= '1';
--Zm0_pad_io <= '1';
--As0_pad_io <= '1';
--Bs0_pad_io <= '1'; -- CLK_IN when 1 
--Zs0_pad_io <= '1';

posn_i <= x"12345678";
enable <= '1';

GENERATOR_ERROR <= '0';
OUTENC_PROTOCOL <= "011";
OUTENC_BITS <= x"20"; 

DCARD_MODE <= x"00000000";

INENC_PROTOCOL <= "011";
CLK_SRC <= '0';
CLK_PERIOD <= X"00000500";
FRAME_PERIOD <= X"00001000";

INENC_BITS <= x"20";
LSB_DISCARD <= "00000";
MSB_DISCARD <= "00000";



ps_reset: process
begin   
    reset_i <= '1';
    wait for 64 ns;
    reset_i <= '0';
    wait;    
end process ps_reset;




endat_master_inst: entity work.endat_master

generic map(g_endat2_1  => 1)

port map( 
    clk_i            => clk,
      reset_i        => reset_i,
      BITS           => INENC_BITS,
      link_up_o      => m_link_up,
      health_o       => m_health,
      CLK_PERIOD_i   => CLK_PERIOD,
      FRAME_PERIOD_i => FRAME_PERIOD,
      endat_sck_o    => ms_endat_sck,   ----
      endat_dat_i    => sm_endat_dat,   ----    
      endat_dat_o    => endat_dato,     
      posn_o         => posn,
      posn_valid_o   => posn_valid
      );

      
endat_slave_inst: entity work.endat_slave

generic map (g_endat2_1     => 1) 

port map( 
    clk_i               => clk,
    reset_i             => reset_i,
    BITS                => OUTENC_BITS,
    link_up_o           => s_link_up,   
    enable_i            => '1',
    GENERATOR_ERROR     => '0',
    health_o            => s_health,
---    posn_i              => X"A5A5A5A5",
    posn_i              => X"A5A5A5A5",
    endat_sck_i         => ms_endat_sck,
    endat_dat_o         => sm_endat_dat
    );


Bs0_pad_io <= ms_endat_sck;   

Am0_pad_io <= sm_endat_dat;  

encoders_inst : entity work.encoders
port map (
        clk_i             => clk,
        reset_i           => reset,
        a_ext_i           => '0',
        b_ext_i           => '1',
        z_ext_i           => '1',
        data_ext_i        => '0',
        posn_i            => posn_i,
        enable_i          => enable,
        INENC_A_o         => INENC_A,
        INENC_B_o         => INENC_B,
        INENC_Z_o         => INENC_Z,
        INENC_DATA_o      => INENC_DATA,
        clk_out_ext_i     => '0',
        clk_int_o         => clk_int,
        Am0_pad_io        => Am0_pad_io, -- DATA IN
        Bm0_pad_io        => Bm0_pad_io,
        Zm0_pad_io        => Zm0_pad_io,
        As0_pad_io        => As0_pad_io,
        Bs0_pad_io        => Bs0_pad_io, -- CLOCK IN
        Zs0_pad_io        => Zs0_pad_io,
        GENERATOR_ERROR_i => GENERATOR_ERROR,
        OUTENC_PROTOCOL_i => OUTENC_PROTOCOL,
        OUTENC_BITS_i     => OUTENC_BITS,
        QPERIOD_i         => x"00000000",
        QPERIOD_WSTB_i    => '0',
        OUTENC_HEALTH_o   => OUTENC_HEALTH,
        QSTATE_o          => QSTATE,
        DCARD_MODE_i      => DCARD_MODE,
        INENC_PROTOCOL_i  => INENC_PROTOCOL,
        CLK_SRC_i         => CLK_SRC,
        CLK_PERIOD_i      => CLK_PERIOD,
        FRAME_PERIOD_i    => FRAME_PERIOD,
        INENC_BITS_i      => INENC_BITS,
        LSB_DISCARD_i     => LSB_DISCARD,
        MSB_DISCARD_i     => MSB_DISCARD,
        SETP_i            => X"00000000",
        SETP_WSTB_i       => '0',
        RST_ON_Z_i        => X"00000000",
        STATUS_o          => STATUS,
        INENC_HEALTH_o    => INENC_HEALTH,
        HOMED_o           => HOMED,
        posn_o            => posn_o
       );


end rtl;
