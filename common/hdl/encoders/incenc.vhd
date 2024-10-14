library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity incenc is
port(
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;

    posn_i              : in  std_logic_vector(31 downto 0);
    enable_i            : in  std_logic;

    QPERIOD_i           : in  std_logic_vector(31 downto 0);
    QPERIOD_WSTB_i      : in  std_logic;
    QSTATE_o            : out std_logic_vector(31 downto 0);

    INCENC_BITS_i       : in  std_logic_vector(7 downto 0);
    LSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    MSB_DISCARD_i       : in  std_logic_vector(4 downto 0);
    INCENC_PROTOCOL_i   : in  std_logic_vector(2 downto 0);
    SETP_i              : in  std_logic_vector(31 downto 0);
    SETP_WSTB_i         : in  std_logic;
    RST_ON_Z_i          : in  std_logic_vector(31 downto 0);
    STATUS_o            : out std_logic_vector(31 downto 0);
    INCENC_HEALTH_o     : out std_logic_vector(31 downto 0);
    HOMED_o             : out std_logic_vector(31 downto 0);

    A_IN_i              : in  std_logic;
    B_IN_i              : in  std_logic;
    Z_IN_i              : in  std_logic;
    quad_a_o            : out std_logic;
    quad_b_o            : out std_logic;

    inc_posn_o          : out std_logic_vector(31 downto 0)
);
end entity;


architecture rtl of incenc is

signal A_IN                 : std_logic;
signal B_IN                 : std_logic;
signal Z_IN                 : std_logic;

signal inc_bits_not_used    : unsigned(4 downto 0);
signal posn_incr            : std_logic_vector(31 downto 0);
signal posn_inc             : std_logic_vector(31 downto 0);
signal linkup_incr          : std_logic;
signal linkup_incr_std32    : std_logic_vector(31 downto 0);
signal step                 : std_logic;
signal dir                  : std_logic;
signal homed_qdec           : std_logic_vector(31 downto 0);


begin

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
-- Position Data and STATUS readback multiplexer
--
--  Link status information is valid only for loopback configuration
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        case (INCENC_PROTOCOL_i) is
            when "000"  =>              -- Quadrature
                posn_inc <= posn_incr;
                STATUS_o(0) <= linkup_incr;
                INCENC_HEALTH_o(0) <= not(linkup_incr);
                INCENC_HEALTH_o(31 downto 1)<= (others=>'0');
                HOMED_o <= homed_qdec;

            when "001"  =>              -- Step/Direction
                posn_inc <= posn_incr;
                STATUS_o(0) <= linkup_incr;
                INCENC_HEALTH_o(0) <= not(linkup_incr);
                INCENC_HEALTH_o(31 downto 1)<= (others=>'0');
                HOMED_o <= homed_qdec;

            when others =>
                posn_inc <= posn_incr;
                STATUS_o(0) <= linkup_incr;
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

linkup_incr <= '1';
linkup_incr_std32 <= x"0000000"&"000"&linkup_incr;

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
    a_o             => quad_a_o,
    b_o             => quad_b_o,
    step_o          => step,
    dir_o           => dir
);

end rtl;
