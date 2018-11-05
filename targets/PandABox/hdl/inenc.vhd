--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Interface to external RS485 Encoder Input Channels.
--                The blocks support various standards which is controlled by
--                PROTOCOL register input.
--
--                To save I/O pins, the design multiplexed 3-pins to implement
--                all supported protocols.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity inenc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder I/O Pads
    A_IN                : in  std_logic;
    B_IN                : in  std_logic;
    Z_IN                : in  std_logic;
    CLK_OUT             : out std_logic;
    DATA_IN             : in  std_logic;
    CLK_IN              : in  std_logic;
    --
    clk_out_ext_i       : in  std_logic;
    -- Block Parameters
    DCARD_MODE          : in  std_logic_vector(31 downto 0);
    PROTOCOL            : in  std_logic_vector(2 downto 0);
    CLK_SRC             : in  std_logic;
    CLK_PERIOD          : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD        : in  std_logic_vector(31 downto 0);
    BITS                : in  std_logic_vector(7 downto 0);
    LSB_DISCARD         : in  std_logic_vector(4 downto 0);
    MSB_DISCARD         : in  std_logic_vector(4 downto 0);    
    SETP                : in  std_logic_vector(31 downto 0);
    SETP_WSTB           : in  std_logic;
    RST_ON_Z            : in  std_logic;
    STATUS              : out std_logic_vector(31 downto 0);
    -- Block Outputs
    posn_o              : out std_logic_vector(31 downto 0)
);
end entity;

architecture rtl of inenc is

signal clk_out_encoder      : std_logic;
signal posn_incr            : std_logic_vector(31 downto 0);
signal posn_ssi             : std_logic_vector(31 downto 0);
signal posn_ssi_sniffer     : std_logic_vector(31 downto 0);
signal posn_biss_sniffer    : std_logic_vector(31 downto 0);
signal posn                 : std_logic_vector(31 downto 0);
signal posn_prev            : std_logic_vector(31 downto 0);
signal bits_not_used        : unsigned(4 downto 0); 

signal linkup_incr          : std_logic;
signal linkup_ssi           : std_logic;
signal linkup_biss          : std_logic;

begin

--------------------------------------------------------------------------
-- Assign outputs
--------------------------------------------------------------------------

ps_select: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- BITS not begin used 
        bits_not_used <= 31 - (unsigned(BITS(4 downto 0))-1);
        lp_test: for i in 31 downto 0 loop
           -- Discard bits not being used and MSB and LSB and append zeros on to top bits 
           if (i > 31 - bits_not_used - unsigned(MSB_DISCARD) - unsigned(LSB_DISCARD)) then
               posn_o(i) <= '0';
           -- Add the LSB_DISCARD on to posn index count and start there
           else           
               posn_o(i) <= posn(i + to_integer(unsigned(LSB_DISCARD)));
           end if;
        end loop lp_test;            
    end if;
end process ps_select;        

-- Loopbacks
CLK_OUT <=  clk_out_ext_i when (CLK_SRC = '1') else clk_out_encoder;

--------------------------------------------------------------------------
-- Incremental Encoder Instantiation :
--------------------------------------------------------------------------
qdec : entity work.qdec
port map (
    clk_i           => clk_i,
--  reset_i         => reset_i,
    a_i             => A_IN,
    b_i             => B_IN,
    z_i             => Z_IN,
    SETP            => SETP,
    SETP_WSTB       => SETP_WSTB,
    RST_ON_Z        => RST_ON_Z,
    out_o           => posn_incr
);

linkup_incr <= not DCARD_MODE(0);

--------------------------------------------------------------------------
-- SSI Instantiations
--------------------------------------------------------------------------

-- SSI Master
ssi_master_inst : entity work.ssi_master
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    CLK_PERIOD      => CLK_PERIOD,
    FRAME_PERIOD    => FRAME_PERIOD,
    ssi_sck_o       => clk_out_encoder,
    ssi_dat_i       => DATA_IN,
    posn_o          => posn_ssi,
    posn_valid_o    => open
);

-- SSI Sniffer
ssi_sniffer_inst : entity work.ssi_sniffer
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    link_up_o       => linkup_ssi,
    error_o         => open,
    ssi_sck_i       => CLK_IN,
    ssi_dat_i       => DATA_IN,
    posn_o          => posn_ssi_sniffer
);

--------------------------------------------------------------------------
-- BiSS Instantiations
--------------------------------------------------------------------------

-- BiSS Sniffer
biss_sniffer_inst : entity work.biss_sniffer
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    link_up_o       => linkup_biss,
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
        case (PROTOCOL) is
            when "000"  =>              -- INC
                posn <= posn_incr;
                STATUS(0) <= linkup_incr;

            when "001"  =>              -- SSI & Loopback
                if (DCARD_MODE(3 downto 1) = DCARD_LOOPBACK) then
                    posn <= posn_ssi_sniffer;
                    STATUS(0) <= linkup_ssi;
                else
                    posn <= posn_ssi;
                    STATUS <= (others => '0');
                end if;

            when "010"  =>              -- BISS & Loopback
                if (DCARD_MODE(3 downto 1) = DCARD_LOOPBACK) then
                    posn <= posn_biss_sniffer;
                    STATUS(0) <= linkup_biss;
                else
                    posn <= (others => '0');
                    STATUS <= (others => '0');
                end if;

            when others =>
                posn <= (others => '0');
                STATUS <= (others => '0');
        end case;
    end if;
end process;

end rtl;
