library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;
use work.support.all;

entity inenc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;

    posn_i              : in  std_logic_vector(31 downto 0);

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


    -- Find out if this is for inenc/outenc
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


architecture rtl of inenc is


signal clk_out_encoder_ssi  : std_logic;
signal clk_out_encoder_biss : std_logic;
signal posn_incr            : std_logic_vector(31 downto 0);
signal posn_ssi             : std_logic_vector(31 downto 0);
signal posn_biss            : std_logic_vector(31 downto 0);
signal posn_ssi_sniffer     : std_logic_vector(31 downto 0);
signal posn_biss_sniffer    : std_logic_vector(31 downto 0);
signal posn                 : std_logic_vector(31 downto 0);

signal posn_prev            : std_logic_vector(31 downto 0); -- Find out where it is used in the code

signal bits_not_used        : unsigned(4 downto 0);

signal homed_qdec           : std_logic_vector(31 downto 0);
signal linkup_incr          : std_logic;
signal linkup_incr_std32    : std_logic_vector(31 downto 0);
signal linkup_ssi           : std_logic;
signal ssi_frame            : std_logic;
signal ssi_frame_sniffer    : std_logic;
signal ssi_frame_master     : std_logic;
signal linkup_biss_sniffer  : std_logic;
signal health_biss_sniffer  : std_logic_vector(31 downto 0);
signal linkup_biss_master   : std_logic;
signal health_biss_master   : std_logic_vector(31 downto 0);

signal inenc_dir            : std_logic;
signal inenc_ctrl           : std_logic_vector(2 downto 0);

signal Am0_ipad, Am0_opad   : std_logic;
signal Bm0_ipad, Bm0_opad   : std_logic;
signal Zm0_ipad, Zm0_opad   : std_logic;

signal A_IN                 : std_logic;
signal B_IN                 : std_logic;
signal Z_IN                 : std_logic;
signal DATA_IN              : std_logic;

signal CLK_OUT              : std_logic;
signal CLK_IN               : std_logic;

signal INENC_PROTOCOL_rb    : std_logic_vector(2 downto 0);

begin

-- Unused Nets.
inenc_dir <= '1';
Am0_opad <= '0';

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
    posn_valid_o    => open,
    ssi_frame_o     => ssi_frame_master
);

-- SSI Sniffer
ssi_sniffer_inst : entity work.ssi_sniffer
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    ENCODING        => INENC_ENCODING_i,
    BITS            => INENC_BITS_i,
    error_o         => open,
    ssi_sck_i       => CLK_IN,
    ssi_dat_i       => DATA_IN,
    posn_o          => posn_ssi_sniffer,
    ssi_frame_o     => ssi_frame_sniffer
);

ssi_frame <= ssi_frame_sniffer when DCARD_MODE_i(3 downto 1) = DCARD_MONITOR
    else ssi_frame_master;

-- Frame checker for SSI
ssi_err_det_inst: entity work.ssi_error_detect
port map (
    clk_i           => clk_i,
    serial_dat_i    => DATA_IN,
    ssi_frame_i     => ssi_frame,
    link_up_o       => linkup_ssi
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

INENC_PROTOCOL_rb <= DCARD_MODE_i(10 downto 8);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if INENC_PROTOCOL_rb /= INENC_PROTOCOL_i then
            INENC_HEALTH_o <= TO_SVECTOR(6,32);
        else
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
                    else  -- DCARD_CONTROL
                        posn <= posn_ssi;
                    end if;
                    HOMED_o <= TO_SVECTOR(1,32);
                    STATUS_o(0) <= linkup_ssi;
                    if (linkup_ssi = '0') then
                        INENC_HEALTH_o <= TO_SVECTOR(2,32);
                    else
                        INENC_HEALTH_o <= (others => '0');
                    end if;

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
                    inenc_ctrl <= "100";
                when "010"  =>                              -- BiSS-C
                    inenc_ctrl <= inenc_dir & "00";
                when "011"  =>                              -- EnDat
                    inenc_ctrl <= inenc_dir & "00";
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

IOBUF_Bm0 : entity work.iobuf_registered port map (
    clock   => clk_i,
    I       => Bm0_opad,
    O       => Bm0_ipad,
    T       => inenc_ctrl(1),
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
Zm0_opad <= not inenc_dir;

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
    pulse_i => Am0_ipad,
    filt_o  => DATA_IN
);

-- A output is shared between incremental and absolute data lines.

INENC_A_o <= A_IN;
INENC_B_o <= B_IN;
INENC_Z_o <= Z_IN;
INENC_DATA_o <= DATA_IN;

clk_int_o <= CLK_IN;

end rtl;

