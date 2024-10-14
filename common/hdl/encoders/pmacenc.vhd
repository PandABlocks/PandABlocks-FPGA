library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;

entity pmacenc is
port(
    clk_i                 : in  std_logic;
    reset_i               : in  std_logic;
    a_ext_i               : in  std_logic;
    b_ext_i               : in  std_logic;
    z_ext_i               : in  std_logic;
    data_ext_i            : in  std_logic;
    posn_i                : in  std_logic_vector(31 downto 0);
    enable_i              : in  std_logic;
    GENERATOR_ERROR_i     : in  std_logic;
    PMACENC_PROTOCOL_i    : in  std_logic_vector(2 downto 0);
    PMACENC_ENCODING_i    : in  std_logic_vector(1 downto 0);
    PMACENC_BITS_i        : in  std_logic_vector(7 downto 0);
    PMACENC_HEALTH_o      : out std_logic_vector(31 downto 0);
    ABSENC_ENABLED_o      : out std_logic_vector(31 downto 0);

    UVWT_o                : out std_logic;

    CLK_IN_i              : in std_logic;
    quad_a_i              : in std_logic;
    quad_b_i              : in std_logic;

    A_OUT_o               : out std_logic;
    B_OUT_o               : out std_logic;
    Z_OUT_o               : out std_logic;
    DATA_OUT_o            : out std_logic;
    PASSTHROUGH_o         : out std_logic;
    PROTOCOL_FOR_ABSENC_o : out std_logic_vector(2 downto 0) := "000"

);
end entity;


architecture rtl of pmacenc is

constant c_BISS             : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(5,3));

signal sdat                 : std_logic;
signal bdat                 : std_logic;
signal health_biss_slave    : std_logic_vector(31 downto 0);
begin

-- When using the monitor control card, only the B signal is used as this is
-- used to generate the Clock inputted to the Inenc.

-- Assign outputs
A_OUT_o <= a_ext_i when (PASSTHROUGH_o = '1') else quad_a_i;
    B_OUT_o <= b_ext_i when (PASSTHROUGH_o = '1') else quad_b_i;
    Z_OUT_o <= z_ext_i when (PASSTHROUGH_o = '1') else '0';
    DATA_OUT_o <= data_ext_i when (PASSTHROUGH_o = '1') else
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
        ENCODING          => PMACENC_ENCODING_i,
        BITS              => PMACENC_BITS_i,
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
            case (PMACENC_PROTOCOL_i) is
                when "000"  =>              -- PASSTHROUGH_o - UVWT_o
                    PMACENC_HEALTH_o <= (others=>'0');
                    ABSENC_ENABLED_o <= TO_SVECTOR(0,32);
                    UVWT_o <= '1';
                    PASSTHROUGH_o <= '1';
                when "001"  =>              -- PASSTHROUGH_o - Absolute
                    PMACENC_HEALTH_o <= (others=>'0');
                    ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                    UVWT_o <= '0';
                    PASSTHROUGH_o <= '1';

                when "010"  =>              -- Read - Step/Direction
                    PMACENC_HEALTH_o <= (others=>'0');
                    ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                    UVWT_o <= '0';
                    PASSTHROUGH_o <= '0';

                when "011"  =>              -- Generate - SSI
                    PMACENC_HEALTH_o <= (others=>'0');
                    ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                    PROTOCOL_FOR_ABSENC_o <= "000";
                    UVWT_o <= '0';
                    PASSTHROUGH_o <= '0';

                when "100"  =>              -- Generate - enDat
                    PMACENC_HEALTH_o <= std_logic_vector(to_unsigned(2,32)); --ENDAT not implemented
                    ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                    UVWT_o <= '0';
                    PASSTHROUGH_o <= '0';

                when "101"  =>              -- Generate Biss
                    PMACENC_HEALTH_o <= health_biss_slave;
                    ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                    PROTOCOL_FOR_ABSENC_o <= "001";
                    UVWT_o <= '0';
                    PASSTHROUGH_o <= '0';

                when others =>
                    PMACENC_HEALTH_o <= (others=>'0');
                    ABSENC_ENABLED_o <= TO_SVECTOR(1,32);
                    UVWT_o <= '0';
                    PASSTHROUGH_o <= '0';

            end case;
        end if;
    end process;

end rtl;
