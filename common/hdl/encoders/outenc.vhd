library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.support.all;

entity outenc is
port(
     -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder inputs from Bitbus
    a_ext_i             : in  std_logic;
    b_ext_i             : in  std_logic;
    z_ext_i             : in  std_logic;

    data_ext_i          : in  std_logic;
    
    -- Encoder I/O Pads
    posn_i              : in  std_logic_vector(31 downto 0);
    enable_i            : in  std_logic;

    As0_pad_io          : inout std_logic;
    Bs0_pad_io          : inout std_logic;
    Zs0_pad_io          : inout std_logic;

    -- Block inputs 
    GENERATOR_ERROR_i   : in  std_logic;
    QPERIOD_i           : in  std_logic_vector(31 downto 0);
    QPERIOD_WSTB_i      : in  std_logic;
    QSTATE_o            : out std_logic_vector(31 downto 0);

    INENC_PROTOCOL_i    : in  std_logic_vector(2 downto 0);
    DCARD_MODE_i        : in  std_logic_vector(31 downto 0);
    OUTENC_PROTOCOL_i   : in  std_logic_vector(2 downto 0);
    OUTENC_ENCODING_i   : in  std_logic_vector(1 downto 0);
    OUTENC_BITS_i       : in  std_logic_vector(7 downto 0);
    OUTENC_HEALTH_o     : out std_logic_vector(31 downto 0);

);
end entity;

architecture rtl of outenc is

    constant c_ABZ_PASSTHROUGH  : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(4,3));
    constant c_DATA_PASSTHROUGH : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(5,3));
    constant c_BISS             : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(2,3));
    constant c_enDat            : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(3,3));
    
    signal quad_a               : std_logic;
    signal quad_b               : std_logic;
    signal sdat                 : std_logic;
    signal bdat                 : std_logic;
    signal health_biss_slave    : std_logic_vector(31 downto 0);
    
    signal posn                 : std_logic_vector(31 downto 0);
    
    signal outenc_ctrl          : std_logic_vector(2 downto 0);
    signal outenc_dir           : std_logic;
    
    signal As0_ipad, As0_opad   : std_logic;
    signal Bs0_ipad, Bs0_opad   : std_logic;
    signal Zs0_ipad, Zs0_opad   : std_logic;
    
    signal A_OUT                : std_logic;
    signal B_OUT                : std_logic;
    signal Z_OUT                : std_logic;
    signal DATA_OUT             : std_logic;
    
    signal CLK_IN               : std_logic;
    
    signal OUTENC_PROTOCOL      : std_logic_vector(2 downto 0);
    signal OUTENC_PROTOCOL_rb   : std_logic_vector(2 downto 0);
    signal INENC_PROTOCOL_rb    : std_logic_vector(2 downto 0);
    
    begin
    
    -- Unused Nets.
    outenc_dir <= '0';
    
    -----------------------------OUTENC---------------------------------------------
    --------------------------------------------------------------------------------
    
    
    -- When using the Monitor Daughter Card, only the Input Encoder protocol is used
    OUTENC_PROTOCOL <= 
        INENC_PROTOCOL_i when DCARD_MODE_i(3 downto 1) = DCARD_MONITOR
        else OUTENC_PROTOCOL_i;
    
    -- Assign outputs
    A_OUT <= a_ext_i when (OUTENC_PROTOCOL = c_ABZ_PASSTHROUGH) else quad_a;
    B_OUT <= b_ext_i when (OUTENC_PROTOCOL = c_ABZ_PASSTHROUGH) else quad_b;
    Z_OUT <= z_ext_i when (OUTENC_PROTOCOL = c_ABZ_PASSTHROUGH) else '0';
    DATA_OUT <= data_ext_i when (OUTENC_PROTOCOL = c_DATA_PASSTHROUGH) else 
                bdat when (OUTENC_PROTOCOL = c_BISS) else sdat;
    
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

OUTENC_PROTOCOL_rb <= DCARD_MODE_i(18 downto 16);

process(clk_i)
begin
    if rising_edge(clk_i) then
        if DCARD_MODE_i(3 downto 1) = DCARD_MONITOR then
            OUTENC_HEALTH_o <= std_logic_vector(to_unsigned(3,32));
        elsif OUTENC_PROTOCOL_rb /= OUTENC_PROTOCOL then
            OUTENC_HEALTH_o <= std_logic_vector(to_unsigned(4,32));
        else 
            case (OUTENC_PROTOCOL) is
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
    end if;
end process;

--------------------------------------------------------------------------
--  On-chip IOBUF controls based on protocol for OUTENC Blocks
--------------------------------------------------------------------------
OUTENC_IOBUF_CTRL : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            outenc_ctrl <= "000";
        else
            case (OUTENC_PROTOCOL) is
                when "000"  =>                        -- INC
                    outenc_ctrl <= "000";
                when "001"  =>                        -- SSI
                    outenc_ctrl <= "010";
                when "010"  =>                        -- BiSS
                    outenc_ctrl <= outenc_dir & "10";
                when "011"  =>                        -- EnDat
                    outenc_ctrl <= outenc_dir & "10";
                when "101" =>
                    outenc_ctrl <= "010";          -- DATA PassThrough
                when others =>
                    outenc_ctrl <= "000";           -- ABZ Passthrough
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

IOBUF_Bs0 : entity work.iobuf_registered port map (
    clock   => clk_i,
    I       => Bs0_opad,
    O       => Bs0_ipad,
    T       => outenc_ctrl(1),
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
As0_opad <= A_OUT when (OUTENC_PROTOCOL(1 downto 0) = "00") else DATA_OUT;
Bs0_opad <= B_OUT;
Zs0_opad <= Z_OUT when (OUTENC_PROTOCOL(1 downto 0) = "00") else not outenc_dir;


clkin_filt : entity work.delay_filter port map (
    clk_i   => clk_i,
    reset_i => reset_i,
    pulse_i => Bs0_ipad,
    filt_o  => CLK_IN
);
end rtl;