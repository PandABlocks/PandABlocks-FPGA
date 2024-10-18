library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity absenc is
port(
    clk_i                  : in  std_logic;
    reset_i                : in  std_logic;

    clk_out_ext_i          : in  std_logic;

    ABSENC_PROTOCOL_i      : in  std_logic_vector(2 downto 0);
    ABSENC_ENCODING_i      : in  std_logic_vector(1 downto 0);
    CLK_SRC_i              : in  std_logic;
    CLK_PERIOD_i           : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD_i         : in  std_logic_vector(31 downto 0);
    ABSENC_BITS_i          : in  std_logic_vector(7 downto 0);
    ABSENC_LSB_DISCARD_i   : in  std_logic_vector(4 downto 0);
    ABSENC_MSB_DISCARD_i   : in  std_logic_vector(4 downto 0);
    ABSENC_STATUS_o        : out std_logic_vector(31 downto 0);
    ABSENC_HEALTH_o        : out std_logic_vector(31 downto 0);
    ABSENC_HOMED_o         : out std_logic_vector(31 downto 0);
    ABSENC_ENABLED_i       : in std_logic_vector(31 downto 0);

    abs_posn_o             : out std_logic_vector(31 downto 0);

    PROTOCOL_FOR_ABSENC_i  : in  std_logic_vector(2 downto 0);
    PASSTHROUGH_i          : in std_logic;
    DATA_IN_i              : in std_logic;
    CLK_IN_i               : in std_logic;
    CLK_OUT_o              : out std_logic;
    clk_out_encoder_biss_o : out std_logic
);
end entity;


architecture rtl of absenc is

signal bits_not_used        : unsigned(4 downto 0);
signal posn_ssi             : std_logic_vector(31 downto 0);
signal posn_biss            : std_logic_vector(31 downto 0);
signal posn_ssi_sniffer     : std_logic_vector(31 downto 0);
signal posn_biss_sniffer    : std_logic_vector(31 downto 0);
signal posn                 : std_logic_vector(31 downto 0);

signal ABSENC_PROTOCOL      : std_logic_vector(2 downto 0) := "000";
signal linkup_ssi           : std_logic;
signal linkup_biss_sniffer  : std_logic;
signal health_biss_sniffer  : std_logic_vector(31 downto 0);
signal linkup_biss_master   : std_logic;
signal health_biss_master   : std_logic_vector(31 downto 0);
signal clk_out_encoder_ssi  : std_logic;

signal ssi_frame            : std_logic;
signal ssi_frame_master     : std_logic;
signal ssi_frame_sniffer    : std_logic;

begin

    abs_ps_select: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if (ABSENC_ENABLED_i = TO_SVECTOR(1,32)) then
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
                        abs_posn_o(i) <= posn(31 - to_integer(bits_not_used + unsigned(ABSENC_MSB_DISCARD_i)));
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
    -- Position Data and STATUS readback multiplexer
    --
    --  Link status information is valid only for loopback configuration
    --------------------------------------------------------------------------

    ABSENC_PROTOCOL <= ABSENC_PROTOCOL_i when (PASSTHROUGH_i = '1')
        else PROTOCOL_FOR_ABSENC_i;


    process(clk_i)
    begin
        if rising_edge(clk_i) then
            case (ABSENC_PROTOCOL) is
                when "000"  =>              -- SSI
                    if PASSTHROUGH_i = '1' then
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
                    if PASSTHROUGH_i = '1' then
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
                    ABSENC_STATUS_o <= (others => '0');
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
        ssi_dat_i       => DATA_IN_i,
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
        ssi_sck_i       => CLK_IN_i,
        ssi_dat_i       => DATA_IN_i,
        posn_o          => posn_ssi_sniffer,
        ssi_frame_o     => ssi_frame_sniffer
    );

    ssi_frame <= ssi_frame_sniffer when PASSTHROUGH_i = '1'
        else ssi_frame_master;

    -- Frame checker for SSI
    ssi_err_det_inst: entity work.ssi_error_detect
    port map (
        clk_i           => clk_i,
        serial_dat_i    => DATA_IN_i,
        ssi_frame_i     => ssi_frame,
        link_up_o       => linkup_ssi
    );

    -- Loopbacks
    CLK_OUT_o <=    clk_out_ext_i when (CLK_SRC_i = '1') else
        clk_out_encoder_biss_o when (CLK_SRC_i = '0' and ABSENC_PROTOCOL_i = "101") else
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
        biss_sck_o      => clk_out_encoder_biss_o,
        biss_dat_i      => DATA_IN_i,
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
        ssi_sck_i       => CLK_IN_i,
        ssi_dat_i       => DATA_IN_i,
        posn_o          => posn_biss_sniffer
    );

end rtl;
