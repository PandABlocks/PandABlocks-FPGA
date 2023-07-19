library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;
use work.support.all;

entity pandabrick_encoders is
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
    INENC_A_o           : out std_logic;
    INENC_B_o           : out std_logic;
    INENC_Z_o           : out std_logic;
    INENC_DATA_o        : out std_logic;
    --
    clk_out_ext_i       : in  std_logic;
    clk_int_o           : out std_logic;
    --
    pin_ENC_A_in        : in  std_logic;
    pin_ENC_B_in        : in  std_logic;
    pin_ENC_Z_in        : in  std_logic;
    pin_ENC_A_out       : out std_logic;
    pin_ENC_B_out       : out std_logic;
    pin_ENC_Z_out       : out std_logic;
	
    pin_PMAC_SCLK_RX    : in std_logic;
    pin_ENC_SDA_RX      : in std_logic;
    pin_PMAC_SDA_RX     : in std_logic; --dangling
    pin_ENC_SCLK_RX     : in std_logic; --dangling
	
    pin_ENC_SCLK_TX     : out std_logic;
    pin_ENC_SDA_TX      : out std_logic; --dangling
    pin_ENC_SDA_TX_EN   : out std_logic; --dangling
    pin_PMAC_SDA_TX     : out std_logic;
    pin_PMAC_SDA_TX_EN  : out std_logic;

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


architecture rtl of pandabrick_encoders is

constant c_ABZ_PASSTHROUGH  : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(4,3));
constant c_DATA_PASSTHROUGH : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(5,3));
constant c_BISS             : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(2,3));
constant c_enDat            : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(3,3));

signal quad_a               : std_logic;
signal quad_b               : std_logic;
signal sdat                 : std_logic;
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

signal Am0_ipad             : std_logic;
signal Bm0_ipad             : std_logic;
signal Zm0_ipad             : std_logic;
signal clkin_ipad           : std_logic;
signal datain_ipad          : std_logic;

signal As0_opad             : std_logic;
signal Bs0_opad             : std_logic;
signal Zs0_opad             : std_logic;

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

begin

-----------------------------OUTENC---------------------------------------------
--------------------------------------------------------------------------------
-- When using the monitor control card, only the B signal is used as this is 
-- used to generate the Clock inputted to the Inenc.

-- Assign outputs
A_OUT <= a_ext_i when (OUTENC_PROTOCOL_i = c_ABZ_PASSTHROUGH) else quad_a;
B_OUT <= b_ext_i when (OUTENC_PROTOCOL_i = c_ABZ_PASSTHROUGH) else quad_b;
Z_OUT <= z_ext_i when (OUTENC_PROTOCOL_i = c_ABZ_PASSTHROUGH) else '0';
DATA_OUT <= data_ext_i when (OUTENC_PROTOCOL_i = c_DATA_PASSTHROUGH) else 
            bdat when (OUTENC_PROTOCOL_i = c_BISS) else sdat;

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
ssi_slave_inst : entity work.ssi_slave
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    ENCODING        => OUTENC_ENCODING_i,
    BITS            => OUTENC_BITS_i,
    posn_i          => posn_i,
    ssi_sck_i       => CLK_IN,
    ssi_dat_o       => sdat
);

--
-- BISS SLAVE
--
biss_slave_inst : entity work.biss_slave
port map (
    clk_i             => clk_i,
    reset_i           => reset_i,
    ENCODING          => OUTENC_ENCODING_i,
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
               if ((INENC_ENCODING_i=c_UNSIGNED_BINARY_ENCODING) or (INENC_ENCODING_i=c_UNSIGNED_GRAY_ENCODING)) then
                   posn_o(i) <= '0';
               else
                   -- sign extension
                   posn_o(i) <= posn(31 - to_integer(bits_not_used + unsigned(MSB_DISCARD_i)));
               end if;
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
    ENCODING        => INENC_ENCODING_i,
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
    ENCODING        => INENC_ENCODING_i,
    BITS            => INENC_BITS_i,
    link_up_o       => linkup_ssi,
    error_o         => open,
    ssi_sck_i       => CLK_IN,
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
    ENCODING        => INENC_ENCODING_i,
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
    ENCODING        => INENC_ENCODING_i,
    BITS            => INENC_BITS_i,
    link_up_o       => linkup_biss_sniffer,
    health_o        => health_biss_sniffer,
    error_o         => open,
    ssi_sck_i       => CLK_IN,
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

            when "001"  =>              -- SSI & Loopback
                if (DCARD_MODE_i(3 downto 1) = DCARD_MONITOR) then
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

            when "010"  =>              -- BISS & Loopback
                if (DCARD_MODE_i(3 downto 1) = DCARD_MONITOR) then
                    posn <= posn_biss_sniffer;
                    STATUS_o(0) <= linkup_biss_sniffer;
                    INENC_HEALTH_o <= health_biss_sniffer;
                else  -- DCARD_CONTROL
                    posn <= posn_biss;
                    STATUS_o(0) <= linkup_biss_master;
                    INENC_HEALTH_o<=health_biss_master;
                end if;
                HOMED_o <= TO_SVECTOR(1,32);

            when others =>
                INENC_HEALTH_o <= TO_SVECTOR(5,32);
                posn <= (others => '0');
                STATUS_o <= (others => '0');
                HOMED_o <= TO_SVECTOR(1,32);
        end case;
    end if;
end process;

-------------------dcard_interface----------------------------------------------
--------------------------------------------------------------------------------

-- ensure this is packed in IOB?? Check synth settings + chip viewer!
REG_INPUTS: process(clk_i)
begin
    if rising_edge(clk_i) then
        Am0_ipad <= pin_ENC_A_in;
        Bm0_ipad <= pin_ENC_B_in;
        Zm0_ipad <= pin_ENC_Z_in;
        clkin_ipad <= pin_PMAC_SCLK_RX;
        datain_ipad <= pin_ENC_SDA_RX;
    end if;
end process;

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

datain_filt : entity work.delay_filter port map(
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => datain_ipad,
    filt_o  => DATA_IN
);

-- ensure this is packed in IOB?? Check synth settings + chip viewer!
REG_OUTPUTS: process(clk_i)
begin
    if rising_edge(clk_i) then
        pin_ENC_A_out <= As0_opad;
        pin_ENC_B_out <= Bs0_opad;
        pin_ENC_Z_out <= Zs0_opad;
        pin_ENC_SCLK_TX <= CLK_OUT;
        pin_PMAC_SDA_TX <= DATA_OUT;
    end if;
end process;

As0_opad <= A_OUT;
Bs0_opad <= B_OUT;
Zs0_opad <= Z_OUT;

INENC_A_o <= A_IN;
INENC_B_o <= B_IN;
INENC_Z_o <= Z_IN;
INENC_DATA_o <= DATA_IN;

clk_int_o <= CLK_IN;

pin_PMAC_SDA_TX_EN <= '1';

clkin_filt : entity work.delay_filter port map (
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => clkin_ipad,
    filt_o  => CLK_IN
);
end rtl;

