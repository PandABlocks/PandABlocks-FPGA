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
    OUTENC_BITS_i       : in  std_logic_vector(7 downto 0);
    QPERIOD_i           : in  std_logic_vector(31 downto 0);
    QPERIOD_WSTB_i      : in  std_logic;
    OUTENC_HEALTH_o     : out std_logic_vector(31 downto 0);
    QSTATE_o            : out std_logic_vector(31 downto 0);

    DCARD_MODE_i        : in  std_logic_vector(31 downto 0);
    INENC_PROTOCOL_i    : in  std_logic_vector(2 downto 0);
    CLK_SRC_i           : in  std_logic;
    CLK_PERIOD_i        : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD_i      : in  std_logic_vector(31 downto 0);
    INENC_BITS_i        : in  std_logic_vector(7 downto 0);
    LSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    MSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    SETP_i              : in  std_logic_vector(31 downto 0);
    SETP_WSTB_i         : in  std_logic;
    RST_ON_Z_i          : in  std_logic_vector(31 downto 0);
    DEBOUNCE_EN_i       : in  std_logic;
    DEBOUNCE_TIME_i     : in  std_logic_vector(6 downto 0);
    STATUS_o            : out std_logic_vector(31 downto 0);
    INENC_HEALTH_o      : out std_logic_vector(31 downto 0);
    HOMED_o             : out std_logic_vector(31 downto 0);
    -- Block Outputs
    posn_o              : out std_logic_vector(31 downto 0)
);
end entity;


architecture rtl of encoders is

COMPONENT ila_32x8K

PORT (
	clk : IN STD_LOGIC;
	probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END COMPONENT  ;

constant c_ABZ_PASSTHROUGH  : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(4,3));
constant c_DATA_PASSTHROUGH : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(5,3));
constant c_BISS             : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(2,3));
constant c_enDat            : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(3,3));
constant c_SSI_SPLITTER     : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(6,3));

signal quad_a               : std_logic;
signal quad_b               : std_logic;
signal ssi_slave1_dat       : std_logic;
signal ssi_slave2_dat       : std_logic;
signal ssi_slave1_clk       : std_logic;
signal ssi_slave2_clk       : std_logic;
signal bdat                 : std_logic;
signal health_biss_slave    : std_logic_vector(31 downto 0);

signal clk_out_encoder_ssi  : std_logic;
signal clk_out_encoder_biss : std_logic;
signal posn_incr            : std_logic_vector(31 downto 0);
signal posn_ssi             : std_logic_vector(31 downto 0);
signal posn_biss            : std_logic_vector(31 downto 0);
signal posn_ssi_sniffer     : std_logic_vector(31 downto 0);
signal posn_biss_sniffer    : std_logic_vector(31 downto 0);
signal posn                 : std_logic_vector(31 downto 0);
signal posn_prev            : std_logic_vector(31 downto 0);
signal bits_not_used        : unsigned(4 downto 0);

signal homed_qdec           : std_logic_vector(31 downto 0);
signal linkup_incr          : std_logic;
signal linkup_incr_std32    : std_logic_vector(31 downto 0);
signal linkup_ssi           : std_logic;
signal linkup_biss_sniffer  : std_logic;
signal health_biss_sniffer  : std_logic_vector(31 downto 0);
signal linkup_biss_master   : std_logic;
signal health_biss_master   : std_logic_vector(31 downto 0);

signal inenc_dir            : std_logic;
signal outenc_dir           : std_logic;
signal inenc_ctrl           : std_logic_vector(2 downto 0);
signal outenc_ctrl          : std_logic_vector(2 downto 0);

signal Am0_ipad, Am0_opad   : std_logic;
signal Bm0_ipad, Bm0_opad   : std_logic;
signal Zm0_ipad, Zm0_opad   : std_logic;

signal As0_ipad, As0_opad   : std_logic;
signal Bs0_ipad, Bs0_opad   : std_logic;
signal Zs0_ipad, Zs0_opad   : std_logic;

signal A_IN                 : std_logic;
signal B_IN                 : std_logic;
signal Z_IN                 : std_logic;
signal DATA_IN              : std_logic;

signal A_OUT                : std_logic;
signal B_OUT                : std_logic;
signal Z_OUT                : std_logic;
signal DATA_OUT             : std_logic;

signal CLK_OUT              : std_logic;

signal CLK_IN               : std_logic;

signal Bs0_T                : std_logic;
signal Bm0_T                : std_logic;

signal SnffrClk             : std_logic;

signal data_out_biss_master : std_logic;

signal outenc_data_in       : std_logic;

signal inenc_dir_biss       : std_logic;
signal outenc_dir_biss      : std_logic;

begin

-- Temporary assignments for bi-directional signal - also needs to be implemented for endat
inenc_dir_biss <= '0';
data_out_biss_master <= '0';
outenc_dir_biss <= '0';


-----------------------------OUTENC---------------------------------------------
--------------------------------------------------------------------------------
-- When using the monitor control card, only the B signal is used as this is 
-- used to generate the Clock inputted to the Inenc.

-- Assign outputs
A_OUT <= a_ext_i when (OUTENC_PROTOCOL_i = c_ABZ_PASSTHROUGH)
            else clk_out_encoder_ssi when (OUTENC_PROTOCOL_i = c_SSI_SPLITTER)
            else quad_a;
B_OUT <= b_ext_i when (OUTENC_PROTOCOL_i = c_ABZ_PASSTHROUGH) else 
            ssi_slave2_dat when (OUTENC_PROTOCOL_i = c_SSI_SPLITTER) else quad_b;
Z_OUT <= z_ext_i when (OUTENC_PROTOCOL_i = c_ABZ_PASSTHROUGH) else 
            ssi_slave1_dat when (OUTENC_PROTOCOL_i = c_SSI_SPLITTER) else '0';
DATA_OUT <= data_ext_i when (OUTENC_PROTOCOL_i = c_DATA_PASSTHROUGH) else 
            bdat when (OUTENC_PROTOCOL_i = c_BISS) else ssi_slave1_dat;
outenc_dir <= outenc_dir_biss when (OUTENC_PROTOCOL_i = c_BISS) else '0';
--
-- INCREMENTAL OUT
--
qenc_inst : entity work.qenc
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    QPERIOD         => QPERIOD_i,
    QPERIOD_WSTB    => QPERIOD_WSTB_i,
    QSTATE          => QSTATE_o,
    enable_i        => enable_i,
    posn_i          => posn_i,
    a_o             => quad_a,
    b_o             => quad_b
);

--
-- SSI SLAVE
--

ssi_slave1_clk <= Z_IN when (INENC_PROTOCOL_i = c_SSI_SPLITTER) else CLK_IN;
ssi_slave2_clk <= B_IN;

ssi_slave1_inst : entity work.ssi_slave  -- regular SSI slave instance, \
                                         -- or PMAC in SSI-Splitter mode
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => OUTENC_BITS_i,
    posn_i          => posn_i,
    ssi_sck_i       => ssi_slave1_clk,
    ssi_dat_o       => ssi_slave1_dat
);

ssi_slave2_inst : entity work.ssi_slave  -- for PLC in SSI-Splitter mode
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => OUTENC_BITS_i,
    posn_i          => posn_i,
    ssi_sck_i       => ssi_slave2_clk,
    ssi_dat_o       => ssi_slave2_dat
);

--
-- BISS SLAVE
--
biss_slave_inst : entity work.biss_slave
port map (
    clk_i             => clk_i,
    reset_i           => reset_i,
    BITS              => OUTENC_BITS_i,
    enable_i          => enable_i,
    GENERATOR_ERROR   => GENERATOR_ERROR_i,
    health_o          => health_biss_slave,
    posn_i            => posn_i,
    biss_sck_i        => CLK_IN,
    biss_dat_o        => bdat
);

--------------------------------------------------------------------------
-- Position Data and STATUS readback multiplexer
--
--  Link status information is valid only for loopback configuration
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        case (OUTENC_PROTOCOL_i) is
            when "000"  =>              -- INC
                OUTENC_HEALTH_o <= (others=>'0');

            when "001"  =>              -- SSI & Loopback
                OUTENC_HEALTH_o <= (others=>'0');

            when "010"  =>              -- BISS & Loopback
                OUTENC_HEALTH_o <= health_biss_slave;
                
            when c_enDat =>             -- enDat 
                OUTENC_HEALTH_o <= std_logic_vector(to_unsigned(2,32)); --ENDAT not implemented
                
            when others =>
                OUTENC_HEALTH_o <= (others=>'0');
                
        end case;
    end if;
end process;

---------------------------------INENC------------------------------------
--------------------------------------------------------------------------
-- Assign outputs
--------------------------------------------------------------------------

ps_select: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- BITS not begin used
        bits_not_used <= 31 - (unsigned(INENC_BITS_i(4 downto 0))-1);
        lp_test: for i in 31 downto 0 loop
           -- Discard bits not being used and MSB and LSB and extend the sign.
           -- Note that we need the loop to manipulate the vector. Slicing with \
           -- variable indices is not synthesisable.
           if (i > 31 - bits_not_used - unsigned(MSB_DISCARD_i) - unsigned(LSB_DISCARD_i)) then
               --posn_o(i) <= '0';
               -- sign extension
               posn_o(i) <= posn(31 - to_integer(bits_not_used + unsigned(MSB_DISCARD_i)));
           -- Add the LSB_DISCARD on to posn index count and start there
           else
               posn_o(i) <= posn(i + to_integer(unsigned(LSB_DISCARD_i)));
           end if;
        end loop lp_test;
    end if;
end process ps_select;

-- Loopbacks
CLK_OUT <=    clk_out_ext_i when (CLK_SRC_i = '1') else
              clk_out_encoder_biss when (CLK_SRC_i = '0' and INENC_PROTOCOL_i = "010") else
              clk_out_encoder_ssi;



--------------------------------------------------------------------------
-- Incremental Encoder Instantiation :
--------------------------------------------------------------------------
qdec : entity work.qdec
port map (
    clk_i           => clk_i,
--  reset_i         => reset_i,
    LINKUP_INCR     => linkup_incr_std32,
    a_i             => A_IN,
    b_i             => B_IN,
    z_i             => Z_IN,
    SETP            => SETP_i,
    SETP_WSTB       => SETP_WSTB_i,
    RST_ON_Z        => RST_ON_Z_i,
    HOMED           => homed_qdec,
    out_o           => posn_incr
);

linkup_incr <= not DCARD_MODE_i(0);
linkup_incr_std32 <= x"0000000"&"000"&linkup_incr;

--------------------------------------------------------------------------
-- SSI Instantiations
--------------------------------------------------------------------------

-- SSI Master
ssi_master_inst : entity work.ssi_master
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => INENC_BITS_i,
    CLK_PERIOD      => CLK_PERIOD_i,
    FRAME_PERIOD    => FRAME_PERIOD_i,
    ssi_sck_o       => clk_out_encoder_ssi,
    ssi_dat_i       => DATA_IN,
    posn_o          => posn_ssi,
    posn_valid_o    => open
);

-- SSI Sniffer
ssi_sniffer_inst : entity work.ssi_sniffer
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => INENC_BITS_i,
    DEBOUNCE_EN_i   => DEBOUNCE_EN_i,
    DEBOUNCE_TIME_i => DEBOUNCE_TIME_i,
    link_up_o       => linkup_ssi,
    error_o         => open,
    ssi_sck_i       => SnffrClk,
    ssi_dat_i       => DATA_IN,
    posn_o          => posn_ssi_sniffer
);

--------------------------------------------------------------------------
-- BiSS Instantiations
--------------------------------------------------------------------------
-- BiSS Master
biss_master_inst : entity work.biss_master
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => INENC_BITS_i,
    link_up_o       => linkup_biss_master,
    health_o        => health_biss_master,
    CLK_PERIOD      => CLK_PERIOD_i,
    FRAME_PERIOD    => FRAME_PERIOD_i,
    biss_sck_o      => clk_out_encoder_biss,
    biss_dat_i      => DATA_IN,
    posn_o          => posn_biss,
    posn_valid_o    => open
);

-- BiSS Sniffer
biss_sniffer_inst : entity work.biss_sniffer
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => INENC_BITS_i,
    link_up_o       => linkup_biss_sniffer,
    health_o        => health_biss_sniffer,
    error_o         => open,
    ssi_sck_i       => SnffrClk,
    ssi_dat_i       => DATA_IN,
    posn_o          => posn_biss_sniffer
);

--------------------------------------------------------------------------
-- Position Data and STATUS readback multiplexer
--
--  Link status information is valid only for loopback configuration
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        case (INENC_PROTOCOL_i) is
            when "000"  =>              -- INC
                posn <= posn_incr;
                STATUS_o(0) <= linkup_incr;
                INENC_HEALTH_o(0) <= not(linkup_incr);
                INENC_HEALTH_o(31 downto 1)<= (others=>'0');
                HOMED_o <= homed_qdec;
                Am0_opad <= '0';
            when "001"  =>              -- SSI & Loopback
                if (DCARD_MODE_i(3 downto 1) = DCARD_MONITOR)
                  OR (DCARD_MODE_i(3 downto 1) = DCARD_MON_CTRL) then
                    posn <= posn_ssi_sniffer;
                    STATUS_o(0) <= linkup_ssi;
                    if (linkup_ssi = '0') then
                        INENC_HEALTH_o <= TO_SVECTOR(2,32);
                    else
                        INENC_HEALTH_o <= (others => '0');
                    end if;
                else  -- DCARD_CONTROL
                    posn <= posn_ssi;
                    STATUS_o <= (others => '0');
                    INENC_HEALTH_o <= (others=>'0');
                end if;
                HOMED_o <= TO_SVECTOR(1,32);
                Am0_opad <= '0';

            when "010"  =>              -- BISS & Loopback
                if (DCARD_MODE_i(3 downto 1) = DCARD_MONITOR)
                  OR (DCARD_MODE_i(3 downto 1) = DCARD_MON_CTRL) then
                    posn <= posn_biss_sniffer;
                    STATUS_o(0) <= linkup_biss_sniffer;
                    INENC_HEALTH_o <= health_biss_sniffer;
                    inenc_dir <= '0';
                    Am0_opad <= '0';
                else  -- DCARD_CONTROL
                    posn <= posn_biss;
                    STATUS_o(0) <= linkup_biss_master;
                    INENC_HEALTH_o<=health_biss_master;
                    inenc_dir <= inenc_dir_biss;
                    Am0_opad <= data_out_biss_master;
                end if;
                HOMED_o <= TO_SVECTOR(1,32);

            when others =>
                INENC_HEALTH_o <= TO_SVECTOR(5,32);
                posn <= (others => '0');
                STATUS_o <= (others => '0');
                HOMED_o <= TO_SVECTOR(1,32);
                inenc_dir <= '0'; -- temporary signal awaiting enDat definitions
                Am0_opad <= '0';
        end case;
    end if;
end process;

-------------------dcard_interface----------------------------------------------
--------------------------------------------------------------------------------
INENC_IOBUF_CTRL : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            inenc_ctrl <= "111";
        else
            case (INENC_PROTOCOL_i) is
                when "000"  =>                              -- INC
                    inenc_ctrl <= "111";
                when "001"  =>                              -- SSI
                    inenc_ctrl <= "101";
                when "010"  =>                              -- BiSS-C
                    inenc_ctrl <= "101";
                when "011"  =>                              -- EnDat
                    inenc_ctrl <= NOT(inenc_dir) & "00";
                when others =>
                    inenc_ctrl <= "111";
            end case;
        end if;
    end if;
end process;

-- Physical IOBUF instantiations controlled with PROTOCOL
IOBUF_Am0 : entity work.iobuf_registered port map (
    clock   => clk_i,
    I       => Am0_opad,
    O       => Am0_ipad,
    T       => inenc_ctrl(2),
    IO      => Am0_pad_io
);

Bm0_T <= '1' when (DCARD_MODE_i(3 downto 1) = DCARD_MON_CTRL) else inenc_ctrl(1);

IOBUF_Bm0 : entity work.iobuf_registered port map (
    clock   => clk_i,
    I       => Bm0_opad,
    O       => Bm0_ipad,
    T       => Bm0_T,
    IO      => Bm0_pad_io
);

IOBUF_Zm0 : entity work.iobuf_registered port map (
    clock   => clk_i,
    I       => Zm0_opad,
    O       => Zm0_ipad,
    T       => inenc_ctrl(0),
    IO      => Zm0_pad_io
);

Bm0_opad <= CLK_OUT;
Zm0_opad <= inenc_dir;

a_filt : entity work.delay_filter port map(
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => Am0_ipad,
    filt_o  => A_IN
);

b_filt : entity work.delay_filter port map(
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => Bm0_ipad,
    filt_o  => B_IN
);

z_filt : entity work.delay_filter port map(
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => Zm0_ipad,
    filt_o  => Z_IN
);

DATA_IN <= A_IN;

--------------------------------------------------------------------------
--  On-chip IOBUF controls based on protocol for OUTENC Blocks
--------------------------------------------------------------------------
OUTENC_IOBUF_CTRL : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            outenc_ctrl <= "000";
        else
            case (OUTENC_PROTOCOL_i) is
                when "000"  =>                        -- INC
                    outenc_ctrl <= "000";
                when "001"  =>                        -- SSI
                    outenc_ctrl <= "011";
                when "010"  =>                        -- BiSS
                    outenc_ctrl <= NOT(outenc_dir) & "10";
                when "011"  =>                        -- EnDat
                    outenc_ctrl <= NOT(outenc_dir) & "10";
--                when "100"  =>                        -- Pass-Through
--                    outenc_ctrl <= "000";
                when "101" =>
                    outenc_ctrl <= "011";          -- DATA PassThrough
                when others =>
                    outenc_ctrl <= "000";
            end case;
        end if;
    end if;
end process;

IOBUF_As0 : entity work.iobuf_registered port map (
    clock   => clk_i,
    I       => As0_opad,
    O       => As0_ipad,
    T       => outenc_ctrl(2),
    IO      => As0_pad_io
);

-- When using a Monitor card the B signal will need to be enabled, for using the CLK
-- regardless of the protocol.
Bs0_T <= '1' when (DCARD_MODE_i(3 downto 1) = DCARD_MONITOR) else outenc_ctrl(1); 

IOBUF_Bs0 : entity work.iobuf_registered port map (
    clock   => clk_i,
    I       => Bs0_opad,
    O       => Bs0_ipad,
    T       => Bs0_T,
    IO      => Bs0_pad_io
);

IOBUF_Zs0 : entity work.iobuf_registered port map (
    clock   => clk_i,
    I       => Zs0_opad,
    O       => Zs0_ipad,
    T       => outenc_ctrl(0),
    IO      => Zs0_pad_io
);

-- A output is shared between incremental and absolute data lines.
As0_opad <= A_OUT when
    (OUTENC_PROTOCOL_i(1 downto 0) = "00" OR OUTENC_PROTOCOL_i = c_SSI_SPLITTER)
    else DATA_OUT;
Bs0_opad <= B_OUT;
Zs0_opad <= Z_OUT when 
    (OUTENC_PROTOCOL_i(1 downto 0) = "00" OR OUTENC_PROTOCOL_i = c_SSI_SPLITTER)
    else outenc_dir;

INENC_A_o <= A_IN;
INENC_B_o <= B_IN;
INENC_Z_o <= Z_IN;
INENC_DATA_o <= DATA_IN;

clk_int_o <= Z_IN when OUTENC_PROTOCOL_i = c_SSI_SPLITTER else SnffrClk;

clkin_filt : entity work.delay_filter port map (
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => Bs0_ipad,
    filt_o  => CLK_IN
);

outenc_din_filt : entity work.delay_filter port map (
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => As0_ipad,
    filt_o  => outenc_data_in
);

SnffrClk <= B_IN when DCARD_MODE_i(3 downto 1) = DCARD_MON_CTRL else CLK_IN;

ssi_ila : ila_32x8K
PORT MAP (
	clk => clk_i,
	probe0 => posn_ssi_sniffer,
    probe1(2 downto 0) => INENC_PROTOCOL_i,
    probe1(10 downto 3) => INENC_BITS_i,
    probe1(11) => linkup_ssi,
    probe1(12) => SnffrClk,
    probe1(13) => DATA_IN,
    probe1(31 downto 14) => (others => '0')
);


end rtl;

