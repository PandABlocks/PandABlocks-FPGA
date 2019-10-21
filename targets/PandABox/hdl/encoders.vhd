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
    A_OUT_o             : out std_logic;
    B_OUT_o             : out std_logic;
    Z_OUT_o             : out std_logic;
    DATA_OUT_o          : out std_logic;
    CLK_IN_i            : in  std_logic;

    A_IN_i              : in  std_logic;
    B_IN_i              : in  std_logic;
    Z_IN_i              : in  std_logic;
    CLK_OUT_o           : out std_logic;
    DATA_IN_i           : in  std_logic;
    --
    clk_out_ext_i       : in  std_logic;
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
    STATUS_o            : out std_logic_vector(31 downto 0);
    INENC_HEALTH_o      : out std_logic_vector(31 downto 0);
    HOMED_o             : out std_logic_vector(31 downto 0);
    -- Block Outputs
    posn_o              : out std_logic_vector(31 downto 0)
);
end entity;


architecture rtl of encoders is

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

begin
-----------------------------OUTENC---------------------------------------------

-- Assign outputs
A_OUT_o <= a_ext_i when (OUTENC_PROTOCOL_i = c_ABZ_PASSTHROUGH) else quad_a;
B_OUT_o <= b_ext_i when (OUTENC_PROTOCOL_i = c_ABZ_PASSTHROUGH) else quad_b;
Z_OUT_o <= z_ext_i when (OUTENC_PROTOCOL_i = c_ABZ_PASSTHROUGH) else '0';
DATA_OUT_o <= data_ext_i when (OUTENC_PROTOCOL_i = c_DATA_PASSTHROUGH) else
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
    BITS            => OUTENC_BITS_i,
    posn_i          => posn_i,
    ssi_sck_i       => CLK_IN_i,
    ssi_dat_o       => sdat
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
    biss_sck_i        => CLK_IN_i,
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

---------------------------------INENC------------------------------------------
--------------------------------------------------------------------------
-- Assign outputs
--------------------------------------------------------------------------

ps_select: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- BITS not begin used
        bits_not_used <= 31 - (unsigned(INENC_BITS_i(4 downto 0))-1);
        lp_test: for i in 31 downto 0 loop
           -- Discard bits not being used and MSB and LSB and append zeros on to top bits
           if (i > 31 - bits_not_used - unsigned(MSB_DISCARD_i) - unsigned(LSB_DISCARD_i)) then
               posn_o(i) <= '0';
           -- Add the LSB_DISCARD on to posn index count and start there
           else
               posn_o(i) <= posn(i + to_integer(unsigned(LSB_DISCARD_i)));
           end if;
        end loop lp_test;
    end if;
end process ps_select;

-- Loopbacks
CLK_OUT_o <=  clk_out_ext_i when (CLK_SRC_i = '1') else
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
    a_i             => A_IN_i,
    b_i             => B_IN_i,
    z_i             => Z_IN_i,
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
    ssi_dat_i       => DATA_IN_i,
    posn_o          => posn_ssi,
    posn_valid_o    => open
);

-- SSI Sniffer
ssi_sniffer_inst : entity work.ssi_sniffer
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => INENC_BITS_i,
    link_up_o       => linkup_ssi,
    error_o         => open,
    ssi_sck_i       => CLK_IN_i,
    ssi_dat_i       => DATA_IN_i,
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
    biss_dat_i      => DATA_IN_i,
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
    ssi_sck_i       => CLK_IN_i,
    ssi_dat_i       => DATA_IN_i,
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
end rtl;
