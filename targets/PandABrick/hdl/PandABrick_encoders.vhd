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
    -- INCENC_A_o          : out std_logic;
    -- INCENC_B_o          : out std_logic;
    -- INCENC_Z_o          : out std_logic;
    ABSENC_DATA_o       : out std_logic;
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
    PMACENC_PROTOCOL_i  : in  std_logic_vector(2 downto 0);
    PMACENC_ENCODING_i  : in  std_logic_vector(1 downto 0);
    PMACENC_BITS_i      : in  std_logic_vector(7 downto 0);
    QPERIOD_i           : in  std_logic_vector(31 downto 0);
    QPERIOD_WSTB_i      : in  std_logic;
    PMACENC_HEALTH_o    : out std_logic_vector(31 downto 0);
    QSTATE_o            : out std_logic_vector(31 downto 0);

    INCENC_PROTOCOL_i   : in  std_logic_vector(2 downto 0);
    INCENC_ENCODING_i   : in  std_logic_vector(1 downto 0);
    INCENC_BITS_i       : in  std_logic_vector(7 downto 0);
    LSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    MSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    SETP_i              : in  std_logic_vector(31 downto 0);
    SETP_WSTB_i         : in  std_logic;
    RST_ON_Z_i          : in  std_logic_vector(31 downto 0);
    STATUS_o            : out std_logic;
    INCENC_HEALTH_o     : out std_logic_vector(31 downto 0);
    HOMED_o             : out std_logic_vector(31 downto 0);

    ABSENC_PROTOCOL_i   : in  std_logic_vector(2 downto 0);
    ABSENC_ENCODING_i   : in  std_logic_vector(1 downto 0);
    CLK_SRC_i           : in  std_logic;
    CLK_PERIOD_i        : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD_i      : in  std_logic_vector(31 downto 0);
    ABSENC_BITS_i       : in  std_logic_vector(7 downto 0);
    ABSENC_LSB_DISCARD_i   : in  std_logic_vector(4 downto 0);
    ABSENC_MSB_DISCARD_i   : in  std_logic_vector(4 downto 0);
    ABSENC_STATUS_o        : out std_logic;
    ABSENC_HEALTH_o     : out std_logic_vector(31 downto 0);
    ABSENC_HOMED_o      : out std_logic_vector(31 downto 0);
    ABSENC_ENABLED_o    : out std_logic_vector(31 downto 0);

    UVWT_o              : out std_logic;

    -- Block Outputs
    abs_posn_o          : out std_logic_vector(31 downto 0);
    inc_posn_o          : out std_logic_vector(31 downto 0)
);
end entity;


architecture rtl of pandabrick_encoders is

-- constant c_ABZ_PASSTHROUGH  : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(4,3));
-- constant c_DATA_PASSTHROUGH : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(5,3));
constant c_BISS             : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(5,3));
-- constant c_enDat            : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(3,3));

signal quad_a               : std_logic;
signal quad_b               : std_logic;
signal sdat                 : std_logic;
signal bdat                 : std_logic;
signal Passthrough          : std_logic;
signal UVWT                 : std_logic;
signal health_biss_slave    : std_logic_vector(31 downto 0);
-- signal absenc_enable        : std_logic;

signal clk_out_encoder_ssi  : std_logic;
signal clk_out_encoder_biss : std_logic;
signal posn_incr            : std_logic_vector(31 downto 0);
signal posn_ssi             : std_logic_vector(31 downto 0);
signal posn_biss            : std_logic_vector(31 downto 0);
signal posn_ssi_sniffer     : std_logic_vector(31 downto 0);
signal posn_biss_sniffer    : std_logic_vector(31 downto 0);
signal posn                 : std_logic_vector(31 downto 0);
signal posn_inc             : std_logic_vector(31 downto 0);
signal posn_prev            : std_logic_vector(31 downto 0);
signal bits_not_used        : unsigned(4 downto 0);
signal inc_bits_not_used    : unsigned(4 downto 0);

signal step, dir            : std_logic;

signal homed_qdec           : std_logic_vector(31 downto 0);
signal linkup_incr          : std_logic;
signal linkup_ssi           : std_logic;
signal ssi_frame            : std_logic;
signal ssi_frame_sniffer    : std_logic;
signal ssi_frame_master     : std_logic;
signal linkup_biss_sniffer  : std_logic;
signal health_biss_sniffer  : std_logic_vector(31 downto 0);
signal linkup_biss_master   : std_logic;
signal health_biss_master   : std_logic_vector(31 downto 0);

signal ABSENC_PROTOCOL      : std_logic_vector(2 downto 0) := "000";
signal PROTOCOL_FOR_ABSENC  : std_logic_vector(2 downto 0) := "000";

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

-----------------------------INCENC---------------------------------------------
ps_select: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- BITS not begin used
        inc_bits_not_used <= 31 - (unsigned(INCENC_BITS_i(4 downto 0))-1);
        inc_lp_test: for i in 31 downto 0 loop
           -- Discard bits not being used and MSB and LSB and extend the sign.
           -- Note that we need the loop to manipulate the vector. Slicing with \
           -- variable indices is not synthesisable.
           if (i > 31 - inc_bits_not_used - unsigned(MSB_DISCARD_i) - unsigned(LSB_DISCARD_i)) then
                inc_posn_o(i) <= '0';
           else
               inc_posn_o(i) <= posn_inc(i + to_integer(unsigned(LSB_DISCARD_i)));
           end if;
        end loop inc_lp_test;
    end if;
end process ps_select;

--------------------------------------------------------------------------
-- INCENC Position Data and STATUS readback multiplexer
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        case (INCENC_PROTOCOL_i) is
            when "000"  =>              -- Quadrature
                posn_inc <= posn_incr;
                STATUS_o <= linkup_incr;
                INCENC_HEALTH_o(0) <= not(linkup_incr);
                INCENC_HEALTH_o(31 downto 1)<= (others=>'0');
                HOMED_o <= homed_qdec;

            when "001"  =>              -- Step/Direction
                posn_inc <= posn_incr;
                STATUS_o <= linkup_incr;
                INCENC_HEALTH_o(0) <= not(linkup_incr);
                INCENC_HEALTH_o(31 downto 1)<= (others=>'0');
                HOMED_o <= homed_qdec;
            
            when others => 
                posn_inc <= posn_incr;
                STATUS_o <= linkup_incr;
                INCENC_HEALTH_o(0) <= not(linkup_incr);
                INCENC_HEALTH_o(31 downto 1)<= (others=>'0');
                HOMED_o <= homed_qdec;
        end case;
    end if;
end process;
--------------------------------------------------------------------------
-- Incremental Encoder Instantiation :
--------------------------------------------------------------------------
qdec : entity work.qdec
port map (
    clk_i           => clk_i,
--  reset_i         => reset_i,
    LINKUP_INCR     => linkup_incr,
    a_i             => A_IN,
    b_i             => B_IN,
    z_i             => Z_IN,
    SETP            => SETP_i,
    SETP_WSTB       => SETP_WSTB_i,
    RST_ON_Z        => RST_ON_Z_i,
    HOMED           => homed_qdec,
    out_o           => posn_incr
);

linkup_incr <= '1';

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
    b_o             => quad_b,
    step_o          => step,
    dir_o           => dir
);

-----------------------------ABSENC---------------------------------------------

abs_ps_select: process(clk_i)
begin
    if rising_edge(clk_i) then
        if (ABSENC_ENABLED_o = TO_SVECTOR(1,32)) then
            -- BITS not begin used
            bits_not_used <= 31 - (unsigned(ABSENC_BITS_i(4 downto 0))-1);
            lp_test: for i in 31 downto 0 loop
            -- Discard bits not being used and MSB and LSB and extend the sign.
            -- Note that we need the loop to manipulate the vector. Slicing with \
            -- variable indices is not synthesisable.
            if (i > 31 - bits_not_used - unsigned(ABSENC_MSB_DISCARD_i) - unsigned(ABSENC_LSB_DISCARD_i)) then
                if ((ABSENC_ENCODING_i=c_UNSIGNED_BINARY_ENCODING) or (ABSENC_ENCODING_i=c_UNSIGNED_GRAY_ENCODING)) then
                    abs_posn_o(i) <= '0';
                else
                    -- sign extension
                    abs_posn_o(i) <= posn(31 - to_integer(bits_not_used + unsigned(MSB_DISCARD_i)));
                end if;
            -- Add the LSB_DISCARD on to posn index count and start there
            else
                abs_posn_o(i) <= posn(i + to_integer(unsigned(ABSENC_LSB_DISCARD_i)));
            end if;
            end loop lp_test;
        else
            abs_posn_o <= (others => '0');
        end if;
    end if;
end process abs_ps_select;

--------------------------------------------------------------------------
-- ABSENC Position Data and STATUS readback multiplexer
--------------------------------------------------------------------------

ABSENC_PROTOCOL <= ABSENC_PROTOCOL_i when (Passthrough = '1')
    else PROTOCOL_FOR_ABSENC;


process(clk_i)
begin
    if rising_edge(clk_i) then
        case (ABSENC_PROTOCOL) is
            when "000"  =>              -- SSI
                if Passthrough = '1' then
                    posn <= posn_ssi_sniffer;
                else  -- DCARD_CONTROL
                    posn <= posn_ssi;
                end if;
                ABSENC_STATUS_o(0) <= linkup_ssi;
                if (linkup_ssi = '0') then
                    ABSENC_HEALTH_o <= TO_SVECTOR(2,32);
                else
                    ABSENC_HEALTH_o <= (others=>'0');
                end if;
                ABSENC_HOMED_o <= TO_SVECTOR(1,32);


            when "001"  =>              -- BISS & Loopback
                -- if (DCARD_MODE_i(3 downto 1) = DCARD_MONITOR) then
                if Passthrough = '1' then
                    posn <= posn_biss_sniffer;
                    ABSENC_STATUS_o(0) <= linkup_biss_sniffer;
                    ABSENC_HEALTH_o <= health_biss_sniffer;
                else  -- DCARD_CONTROL
                    posn <= posn_biss;
                    ABSENC_STATUS_o(0) <= linkup_biss_master;
                    ABSENC_HEALTH_o<=health_biss_master;
                end if;
                ABSENC_HOMED_o <= TO_SVECTOR(1,32);

            when others =>
                ABSENC_HEALTH_o <= TO_SVECTOR(5,32);
                posn <= (others => '0');
                ABSENC_STATUS_o <= '0';
                ABSENC_HOMED_o <= TO_SVECTOR(1,32);
        end case;
    end if;
end process;

--------------------------------------------------------------------------
-- SSI Instantiations
--------------------------------------------------------------------------

-- SSI Master
ssi_master_inst : entity work.ssi_master
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    ENCODING        => ABSENC_ENCODING_i,
    BITS            => ABSENC_BITS_i,
    CLK_PERIOD      => CLK_PERIOD_i,
    FRAME_PERIOD    => FRAME_PERIOD_i,
    ssi_sck_o       => clk_out_encoder_ssi,
    ssi_dat_i       => DATA_IN,
    posn_o          => posn_ssi,
    posn_valid_o    => open,
    ssi_frame_o     => ssi_frame_master
);

-- SSI Sniffer
ssi_sniffer_inst : entity work.ssi_sniffer
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    ENCODING        => ABSENC_ENCODING_i,
    BITS            => ABSENC_BITS_i,
    error_o         => open,
    ssi_sck_i       => CLK_IN,
    ssi_dat_i       => DATA_IN,
    posn_o          => posn_ssi_sniffer,
    ssi_frame_o     => ssi_frame_sniffer
);

ssi_frame <= ssi_frame_sniffer when Passthrough = '1'
    else ssi_frame_master;

-- Frame checker for SSI
ssi_err_det_inst: entity work.ssi_error_detect
port map (
    clk_i           => clk_i,
    serial_dat_i    => DATA_IN,
    ssi_frame_i     => ssi_frame,
    link_up_o       => linkup_ssi
);

-- Loopbacks
CLK_OUT <=    clk_out_ext_i when (CLK_SRC_i = '1') else
    clk_out_encoder_biss when (CLK_SRC_i = '0' and ABSENC_PROTOCOL_i = "101") else
    clk_out_encoder_ssi;

--------------------------------------------------------------------------
-- BiSS Instantiations
--------------------------------------------------------------------------
-- BiSS Master
biss_master_inst : entity work.biss_master
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    ENCODING        => ABSENC_ENCODING_i,
    BITS            => ABSENC_BITS_i,
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
    ENCODING        => ABSENC_ENCODING_i,
    BITS            => ABSENC_BITS_i,
    link_up_o       => linkup_biss_sniffer,
    health_o        => health_biss_sniffer,
    error_o         => open,
    ssi_sck_i       => CLK_IN,
    ssi_dat_i       => DATA_IN,
    posn_o          => posn_biss_sniffer
);


-----------------------------PMACENC---------------------------------------------
-- When using the monitor control card, only the B signal is used as this is 
-- used to generate the Clock inputted to the Inenc.

-- Assign outputs
A_OUT <= a_ext_i when (Passthrough = '1') else quad_a;
B_OUT <= b_ext_i when (Passthrough = '1') else quad_b;
Z_OUT <= z_ext_i when (Passthrough = '1') else '0';
DATA_OUT <= data_ext_i when (Passthrough = '1') else 
            bdat when (PMACENC_PROTOCOL_i = c_BISS) else sdat;

--
-- SSI SLAVE
--
ssi_slave_inst : entity work.ssi_slave
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    ENCODING        => PMACENC_ENCODING_i,
    BITS            => PMACENC_BITS_i,
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
    ENCODING          => PMACENC_ENCODING_i,
    BITS              => PMACENC_BITS_i,
    enable_i          => enable_i,
    GENERATOR_ERROR   => GENERATOR_ERROR_i,
    health_o          => health_biss_slave,
    posn_i            => posn_i,
    biss_sck_i        => CLK_IN,
    biss_dat_o        => bdat
);

--------------------------------------------------------------------------
-- PMACENC status readback multiplexer
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        case (PMACENC_PROTOCOL_i) is
            when "000"  =>              -- Passthrough - UVWT
                PMACENC_HEALTH_o <= (others=>'0');
                ABSENC_ENABLED_o <= TO_SVECTOR(0,32);
                UVWT <= '1';
                Passthrough <= '1';
            when "001"  =>              -- Passthrough - Absolute
                PMACENC_HEALTH_o <= (others=>'0');
                ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                UVWT <= '0';
                Passthrough <= '1';

            when "010"  =>              -- Read - Step/Direction
                PMACENC_HEALTH_o <= (others=>'0');
                ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                UVWT <= '0';
                Passthrough <= '0';

            when "011"  =>              -- Generate - SSI
                PMACENC_HEALTH_o <= (others=>'0');
                ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                PROTOCOL_FOR_ABSENC <= "000";
                UVWT <= '0';
                Passthrough <= '0';

            when "100"  =>              -- Generate - enDat
                PMACENC_HEALTH_o <= std_logic_vector(to_unsigned(2,32)); --ENDAT not implemented
                ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                UVWT <= '0';
                Passthrough <= '0';

            when "101"  =>              -- Generate Biss
                PMACENC_HEALTH_o <= health_biss_slave;
                ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                PROTOCOL_FOR_ABSENC <= "001";
                UVWT <= '0';
                Passthrough <= '0';
                                
            when others =>
                PMACENC_HEALTH_o <= (others=>'0');
                ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                UVWT <= '0';
                Passthrough <= '0';

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

-- INCENC_A_o <= A_IN;
-- INCENC_B_o <= B_IN;
-- INCENC_Z_o <= Z_IN;

ABSENC_DATA_o <= DATA_IN;

clk_int_o <= CLK_IN;

pin_PMAC_SDA_TX_EN <= '0';

clkin_filt : entity work.delay_filter port map (
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => clkin_ipad,
    filt_o  => CLK_IN
);
end rtl;

